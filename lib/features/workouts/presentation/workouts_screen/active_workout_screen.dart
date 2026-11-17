import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import 'package:bldr_fitness/models/exercise_model.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/routes/app_routes.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/resolve_club_access.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/exercise_display_name.dart';
import 'package:bldr_fitness/features/achievements/domain/usecases/achievement_usecases.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart'
    as uc;
import 'package:bldr_fitness/features/integrations/data/live_activity_service.dart';
import 'package:bldr_fitness/features/integrations/data/health_kit_service.dart';
import 'package:bldr_fitness/features/integrations/data/watch_service.dart';
import 'package:bldr_fitness/features/integrations/data/widget_data_service.dart';
import 'package:bldr_fitness/services/exercise_db_service.dart';
import 'package:bldr_fitness/services/exercise_db_rapid_service.dart';
import 'package:bldr_fitness/services/notification_service.dart';
import 'package:bldr_fitness/services/popup_service.dart';
import 'package:bldr_fitness/services/user_service.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/widgets/muscle_visualizer_widget.dart';
import 'package:bldr_fitness/widgets/notification_permission_modal.dart';
import 'package:bldr_fitness/widgets/review_modal.dart';
import 'package:bldr_fitness/shared/providers/workout_session_provider.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/workout_session_logic.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/paused_workout_summary.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/workout_summary_screen.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final String workoutId;
  final String workoutName;

  const ActiveWorkoutScreen({
    Key? key,
    required this.workoutId,
    required this.workoutName,
  }) : super(key: key);

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ── services ──────────────────────────────────────────────────────────────
  final _exerciseDbService = ExerciseDbService();

  // ── state ──────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _exercises = []; // grouped by exercise
  int _currentExerciseIdx = 0;
  int _currentSetNumber = 1;
  bool _loading = true;
  String? _loadError;
  bool _isPrefetching = false;
  bool _isPro = false;
  bool _finishing = false; // guard: prevents _finishWorkout from running twice
  final _confirmationGuard = WorkoutSetConfirmationGuard();
  String? _confirmingSetId;
  late String _effectiveWorkoutName;
  bool _isFinishing = false; // true quando navegando para WorkoutSummaryScreen
  bool _pausing = false;

  // ExerciseDB cache: exercise_db_id → ExerciseDetail
  final Map<String, ExerciseDetail> _exDbCache = {};

  double _weight = 0;
  int _reps = 0;

  // Timer
  Timer? _timer;
  int _elapsedSeconds = 0;
  late DateTime _startTime;

  // Rest timer
  bool _resting = false;
  int _restSecondsLeft = 0;
  int _restTotalSeconds = 90;
  Timer? _restTimer;
  DateTime? _restEndTime;

  // Animation for today's dot pulse
  late AnimationController _pulseCtrl;

  // Deep link confirm-set subscription
  StreamSubscription<void>? _confirmSetSub;

  // Apple Watch action subscription
  StreamSubscription<Map<String, dynamic>>? _watchSub;

  // HealthKit
  double _currentBpm = 0;
  StreamSubscription<double>? _hrSubscription;

  // ── init ──────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _effectiveWorkoutName = widget.workoutName;
    WidgetsBinding.instance.addObserver(this);
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WorkoutSessionProvider>().markActive(widget.workoutId);
      }
    });
    _loadWorkout();
    _loadSubscription();
    LiveActivityService.init();
    _confirmSetSub = LiveActivityService.onConfirmSet.listen((_) {
      if (mounted) _confirmSet();
    });
    _watchSub = getIt<WatchService>().watchActions.listen((message) {
      if (!mounted) return;
      switch (message['acao'] as String?) {
        case 'concluir_serie':
          _confirmSet();
        case 'finalizar_treino':
          _finishWorkout();
      }
    });
  }

  Future<void> _loadSubscription() async {
    try {
      final access = (await getIt<ResolveClubAccess>()()).valueOrNull ?? false;
      if (mounted) {
        setState(() => _isPro = access);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _restTimer?.cancel();
    _pulseCtrl.dispose();
    _confirmSetSub?.cancel();
    _watchSub?.cancel();
    _hrSubscription?.cancel();
    getIt<HealthKitService>().stopHeartRateMonitoring();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isFinishing) return;
    if (state == AppLifecycleState.resumed && mounted) {
      unawaited(_reconcileNativeRestAction());
      setState(() {
        _elapsedSeconds =
            DateTime.now().difference(_startTime).inSeconds.clamp(0, 86400);
        if (_resting && _restEndTime != null) {
          final left = _restEndTime!.difference(DateTime.now()).inSeconds;
          _restSecondsLeft = left > 0 ? left : 0;
          if (left <= 0) {
            _resting = false;
            getIt<NotificationService>().cancelRestNotification();
            unawaited(_updateLiveActivity(isResting: false));
          }
        }
      });
    }
  }

  Future<void> _reconcileNativeRestAction() async {
    final action = await LiveActivityService.consumeNativeRestAction();
    if (action == null || !mounted || _isFinishing) return;
    if (action.action == 'skip') {
      _restTimer?.cancel();
      await getIt<NotificationService>().cancelRestNotification();
      setState(() {
        _resting = false;
        _restSecondsLeft = 0;
      });
      await _updateLiveActivity(isResting: false);
      return;
    }
    if (action.action == 'add' && action.endTimestamp > 0) {
      final end = DateTime.fromMillisecondsSinceEpoch(
        (action.endTimestamp * 1000).round(),
      );
      final left = end.difference(DateTime.now()).inSeconds;
      if (left <= 0) return;
      _startRestTimer(left);
      setState(() {
        _restEndTime = end;
        _restTotalSeconds =
            action.totalSeconds > 0 ? action.totalSeconds : _restTotalSeconds;
      });
      await _updateLiveActivity(
        isResting: true,
        restTotalSeconds: _restTotalSeconds,
        restEndTime: end,
      );
    }
  }

  // ── timer ─────────────────────────────────────────────────────────────────

  void _startTimer() {
    _startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsedSeconds = DateTime.now().difference(_startTime).inSeconds;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── data ──────────────────────────────────────────────────────────────────

  /// Converte a entidade de série para o map que o build ainda consome
  /// (transitório — remover quando o build for tipado).
  Map<String, dynamic> _setToUiMap(WorkoutSet s) => {
        'id': s.id,
        'set_number': s.setNumber,
        'order_index': s.orderIndex,
        'reps': s.reps,
        'weight_kg': s.weightKg,
        'rest_seconds': s.restSeconds,
        'exercise_id': s.exerciseId,
        'exercise_db_id': s.exerciseDbId,
        'completed_at': s.completedAt?.toIso8601String(),
        'is_skipped': s.isSkipped,
      };

  Future<void> _loadWorkout() async {
    try {
      final detailsResult =
          await getIt<uc.GetWorkoutDetails>()(widget.workoutId);
      var session = detailsResult.valueOrNull;
      if (session == null || !mounted) {
        if (mounted) {
          setState(() {
            _loading = false;
            _loadError = detailsResult.failureOrNull?.message ??
                'Não foi possível carregar esta sessão.';
          });
        }
        return;
      }

      debugPrint('[HAVOK] session id: ${session.id}');
      debugPrint('[HAVOK] session.templateId: ${session.templateId}');
      debugPrint('[HAVOK] session sets count: ${session.sets.length}');

      // Fallback PASSO 3: sets podem estar vazios se o INSERT silenciou
      // (ex: RLS retorna 204 sem erro). Tenta criar agora e recarrega.
      if (session.sets.isEmpty && session.templateId != null) {
        debugPrint(
            '[HAVOK] sets vazios + templateId presente → chamando EnsureWorkoutSets');
        await getIt<uc.EnsureWorkoutSets>()(session.id!, session.templateId!);
        final reloaded =
            (await getIt<uc.GetWorkoutDetails>()(widget.workoutId)).valueOrNull;
        if (reloaded != null) session = reloaded;
        debugPrint(
            '[HAVOK] após EnsureWorkoutSets → sets count: ${session.sets.length}');
      } else if (session.sets.isEmpty && session.templateId == null) {
        debugPrint(
            '[HAVOK] ⚠️ sets vazios E templateId NULL → fallback não vai disparar');
      }

      // Group sets by exercise (using order_index as primary sort key).
      // For ExerciseDB-only exercises (no row in internal `exercises` table),
      // exercise_id is null — use exercise_db_id from the set as the group key.
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final s in session.sets) {
        final exMap = <String, dynamic>{
          if (s.exercise != null) ...{
            'id': s.exercise!.id,
            'name': s.exercise!.name,
            'primary_muscle_group': s.exercise!.primaryMuscleGroup,
            'instructions': s.exercise!.instructions,
            'exercise_db_id': s.exercise!.exerciseDbId,
          },
        };

        // Propagate exercise_db_id from the set row into exMap when the join
        // returned nothing (custom workout created from the ExerciseDB picker).
        if (s.exerciseDbId != null && exMap['exercise_db_id'] == null) {
          exMap['exercise_db_id'] = s.exerciseDbId;
        }

        // Exercício de nome livre (HAVOK, sem match na biblioteca —
        // BACKLOG_FUNCIONAL.md B5): sem id nem exercise_db_id, o nome não
        // aparece no exMap acima porque s.exercise é null. Propaga aqui.
        if (s.freeName != null && exMap['name'] == null) {
          exMap['name'] = s.freeName;
        }

        // Stable group key: prefer internal exercise id, fall back to db id,
        // depois nome livre — nunca colapsa em '' quando há freeName (B5).
        final exId = s.exercise?.id ??
            s.exerciseId ??
            s.exerciseDbId ??
            s.freeName ??
            '';
        grouped
            .putIfAbsent(exId, () => [])
            .add({..._setToUiMap(s), 'exercise': exMap});
      }

      // Sort grouped exercises by first set's order_index
      final exList = grouped.values.toList()
        ..sort((a, b) {
          final ai = (a.first['order_index'] as int?) ?? 0;
          final bi = (b.first['order_index'] as int?) ?? 0;
          return ai.compareTo(bi);
        });

      if (!mounted) return;

      final builtExercises = exList.map((sets) {
        final ex = (sets.first['exercise'] as Map).cast<String, dynamic>();
        return {
          'exercise': ex,
          'sets': sets,
          'totalSets': sets.length,
        };
      }).toList();

      if (builtExercises.isEmpty) {
        setState(() {
          _loading = false;
          _loadError = 'Esta sessão não possui exercícios disponíveis.';
        });
        return;
      }

      final resume = findWorkoutResumePosition(builtExercises);

      // Calibrate elapsed time from the DB started_at so resuming a paused
      // workout shows the real accumulated duration, not a reset counter.
      final startedAt = session.startedAt;
      final templateName = session.templateName?.trim();
      final sessionName = session.name.trim();

      setState(() {
        _exercises = builtExercises;
        _currentExerciseIdx = resume.exerciseIndex;
        _currentSetNumber = resume.setNumber;
        _reps = resume.reps;
        _weight = resume.weightKg;
        _effectiveWorkoutName = templateName?.isNotEmpty == true
            ? templateName!
            : sessionName.isNotEmpty
                ? sessionName
                : widget.workoutName;
        if (startedAt != null) {
          _startTime = startedAt;
          _elapsedSeconds =
              DateTime.now().difference(startedAt).inSeconds.clamp(0, 86400);
        }
        _loading = false;
        _isPrefetching = true;
      });

      if (!resume.hasPendingSet) {
        await _finishWorkout();
        return;
      }

      _sendToWatch();
      _startHealthKit();
      await _startLiveActivity();

      // Prefetch ExerciseDB details — collect ids from exercise map (may have
      // been populated above from the set's own exercise_db_id column).
      final dbIds = builtExercises
          .map((e) =>
              ((e['exercise'] as Map<String, dynamic>)['exercise_db_id']
                  as String?) ??
              '')
          .where((id) => id.isNotEmpty)
          .toList();

      if (dbIds.isNotEmpty) {
        // Use the warm in-memory catalog from ExerciseDbRapidService so that
        // when WorkoutsScreen has prefetched the catalog, these are instant
        // hash-table lookups rather than N individual network calls.
        try {
          final results = await Future.wait(
            dbIds.map((id) => ExerciseDbRapidService.instance.getById(id)),
          );
          if (mounted) {
            setState(() {
              for (final ex in results) {
                if (ex == null) continue;
                _exDbCache[ex.exerciseId] = ExerciseDetail(
                  exerciseId: ex.exerciseId,
                  name: ex.name,
                  gifUrl: ex.displayUrl,
                  instructions: ex.instructions,
                  targetMuscles: ex.targetMuscles,
                  bodyParts: ex.bodyParts,
                  equipments: ex.equipments,
                  secondaryMuscles: ex.secondaryMuscles,
                );
              }
              _isPrefetching = false;
            });
            await _updateLiveActivity();
          }
        } catch (_) {
          // Rate-limit or network failure — gracefully degrade; workout continues.
          if (mounted) setState(() => _isPrefetching = false);
        }
      } else {
        if (mounted) setState(() => _isPrefetching = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'Não foi possível carregar esta sessão.';
        });
      }
    }
  }

  void _retryLoadWorkout() {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    unawaited(_loadWorkout());
  }

  // ── Live Activity ─────────────────────────────────────────────────────────

  String get _currentExerciseName {
    if (_exercises.isEmpty) return _effectiveWorkoutName;
    final ex = _exercises[_currentExerciseIdx];
    final exData = ex['exercise'] as Map<String, dynamic>;
    final exerciseDbId = exData['exercise_db_id'] as String?;
    return resolveExerciseDisplayName(
      internalName: exData['name'] as String? ?? exData['free_name'] as String?,
      exerciseDbName:
          exerciseDbId == null ? null : _exDbCache[exerciseDbId]?.name,
      fallback: _effectiveWorkoutName,
    );
  }

  int get _currentTotalSets {
    if (_exercises.isEmpty) return 1;
    return (_exercises[_currentExerciseIdx]['totalSets'] as int?) ?? 1;
  }

  Future<void> _startLiveActivity() => LiveActivityService.startWorkout(
        mode: 'free',
        workoutName: _effectiveWorkoutName,
        exerciseName: _currentExerciseName,
        exerciseSet: _currentSetNumber,
        exerciseTotalSets: _currentTotalSets,
        exerciseIndex: _currentExerciseIdx,
        exerciseTotalExercises: _exercises.length,
        weightKg: _weight,
        reps: _reps,
        workoutStartTimestamp: _startTime.millisecondsSinceEpoch / 1000.0,
      );

  Future<void> _updateLiveActivity(
      {bool? isResting, int? restTotalSeconds, DateTime? restEndTime}) {
    final effectiveIsResting = isResting ?? _resting;
    final endTime = restEndTime ?? _restEndTime;
    final restEnd = effectiveIsResting && endTime != null
        ? endTime.millisecondsSinceEpoch / 1000.0
        : 0.0;
    return LiveActivityService.update(
      mode: 'free',
      workoutName: _effectiveWorkoutName,
      exerciseName: _currentExerciseName,
      exerciseSet: _currentSetNumber,
      exerciseTotalSets: _currentTotalSets,
      exerciseIndex: _currentExerciseIdx,
      exerciseTotalExercises: _exercises.length,
      isResting: effectiveIsResting,
      restEndTimestamp: restEnd,
      restTotalSeconds: restTotalSeconds ?? _restTotalSeconds,
      weightKg: _weight,
      reps: _reps,
      workoutStartTimestamp: _startTime.millisecondsSinceEpoch / 1000.0,
    );
  }

  // ── actions ───────────────────────────────────────────────────────────────

  void _confirmSet() async {
    if (_exercises.isEmpty) return;

    final exGroup = _exercises[_currentExerciseIdx];
    final sets = exGroup['sets'] as List<Map<String, dynamic>>;
    final setIdx = _currentSetNumber - 1;

    if (setIdx >= sets.length) return;

    final setId = sets[setIdx]['id']?.toString() ?? '';
    if (setId.isEmpty) return;

    if (!_confirmationGuard.tryAcquire(setId)) return;
    if (mounted) setState(() => _confirmingSetId = setId);

    try {
      final result = await getIt<uc.CompleteWorkoutSet>()(
        setId: setId,
        weightKg: _weight,
        reps: _reps,
      );
      if (result.failureOrNull != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result.failureOrNull!.message),
          ));
        }
        return;
      }
      if (!mounted) return;

      // Item 8 — espelha localmente o que acabou de ser persistido, para que
      // a lista de séries mostre o valor real confirmado (e não o default
      // carregado no início da sessão). Não afeta a chamada acima nem o
      // avanço de sequência abaixo.
      sets[setIdx]['weight_kg'] = _weight;
      sets[setIdx]['reps'] = _reps;
      sets[setIdx]['completed_at'] = DateTime.now().toIso8601String();

      final totalSets = exGroup['totalSets'] as int;

      // Start rest timer
      final restSec = (sets[setIdx]['rest_seconds'] as int?) ?? 90;
      _startRestTimer(restSec);

      if (_currentSetNumber < totalSets) {
        setState(() => _currentSetNumber++);
      } else if (!_advanceToNextExercise()) {
        await _finishWorkout();
        return;
      }

      await _updateLiveActivity(
        isResting: true,
        restTotalSeconds: restSec,
        restEndTime: _restEndTime,
      );
      _sendToWatch();
    } finally {
      _confirmationGuard.release(setId);
      if (mounted && _confirmingSetId == setId) {
        setState(() => _confirmingSetId = null);
      }
    }
  }

  bool _advanceToNextExercise() {
    if (_currentExerciseIdx < _exercises.length - 1) {
      setState(() {
        _currentExerciseIdx++;
        _currentSetNumber = 1;
        final sets = (_exercises[_currentExerciseIdx]['sets']
            as List<Map<String, dynamic>>);
        if (sets.isNotEmpty) {
          _reps = (sets.first['reps'] as int?) ?? 10;
          _weight = ((sets.first['weight_kg'] as num?)?.toDouble()) ?? 0;
        }
      });
      return true;
    } else {
      return false;
    }
  }

  Future<void> _nextExercise() async {
    if (_advanceToNextExercise()) {
      await _updateLiveActivity(isResting: false);
    } else {
      await _finishWorkout();
    }
  }

  Future<void> _skipExercise() async {
    if (_exercises.isEmpty) return;
    final exGroup = _exercises[_currentExerciseIdx];
    final sets = exGroup['sets'] as List<Map<String, dynamic>>;
    final setIdx = _currentSetNumber - 1;
    if (setIdx >= sets.length) return;
    final setId = sets[setIdx]['id']?.toString() ?? '';
    if (!_confirmationGuard.tryAcquire(setId)) return;
    if (mounted) setState(() => _confirmingSetId = setId);
    try {
      final result = await getIt<uc.SkipWorkoutSet>()(setId);
      if (result.isFailure || !mounted) return;
      sets[setIdx]['is_skipped'] = true;
      if (_currentSetNumber < (exGroup['totalSets'] as int)) {
        setState(() => _currentSetNumber++);
      } else if (!_advanceToNextExercise()) {
        await _finishWorkout();
        return;
      }
      await _updateLiveActivity(isResting: false);
      _sendToWatch();
    } finally {
      _confirmationGuard.release(setId);
      if (mounted && _confirmingSetId == setId) {
        setState(() => _confirmingSetId = null);
      }
    }
  }

  void _startRestTimer(int seconds) {
    _restTimer?.cancel();
    _restEndTime = DateTime.now().add(Duration(seconds: seconds));
    setState(() {
      _resting = true;
      _restSecondsLeft = seconds;
      _restTotalSeconds = seconds;
    });
    getIt<NotificationService>().scheduleRestNotification(seconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      final left = _restEndTime!.difference(DateTime.now()).inSeconds;
      if (left <= 0) {
        t.cancel();
        HapticFeedback.heavyImpact();
        setState(() {
          _resting = false;
          _restSecondsLeft = 0;
        });
        unawaited(_updateLiveActivity(isResting: false));
      } else {
        setState(() => _restSecondsLeft = left);
      }
    });
  }

  /// Estende o descanso em andamento — soma ao fim previsto e ao total, sem
  /// reiniciar o timer, para o anel continuar coerente.
  void _addRestSeconds(int extra) {
    if (!_resting || _restEndTime == null) return;
    _restEndTime = _restEndTime!.add(Duration(seconds: extra));
    setState(() {
      _restTotalSeconds += extra;
      _restSecondsLeft += extra;
    });
    _updateLiveActivity(
      isResting: true,
      restTotalSeconds: _restTotalSeconds,
      restEndTime: _restEndTime,
    );
  }

  void _endRestEarly() {
    _restTimer?.cancel();
    getIt<NotificationService>().cancelRestNotification();
    setState(() => _resting = false);
    _updateLiveActivity(isResting: false);
  }

  Future<void> _startHealthKit() async {
    final granted = await getIt<HealthKitService>().requestPermission();
    if (!granted || !mounted) return;
    _hrSubscription = getIt<HealthKitService>().heartRateStream.listen((bpm) {
      if (!mounted) return;
      setState(() => _currentBpm = bpm);
      if (_exercises.isEmpty) return;
      final exercises = _exercises.map((exGroup) {
        final ex = exGroup['exercise'] as Map<String, dynamic>;
        return {
          'nome': ex['free_name'] as String? ??
              ex['name'] as String? ??
              'Exercício',
          'series': (exGroup['totalSets'] as int?) ?? 1,
          'reps': ((exGroup['sets'] as List).isNotEmpty
              ? ((exGroup['sets'] as List<Map<String, dynamic>>)
                      .first['reps']
                      ?.toString() ??
                  '—')
              : '—'),
          'duracao_segundos': ex['duration_seconds'] as int? ?? 0,
        };
      }).toList();
      getIt<WatchService>().sendWorkoutState(
        workoutName: _effectiveWorkoutName,
        bpm: '${bpm.round()} bpm',
        exercises: exercises,
      );
    });
  }

  void _sendToWatch() {
    if (_exercises.isEmpty) return;
    final exercises = _exercises.map((exGroup) {
      final ex = exGroup['exercise'] as Map<String, dynamic>;
      return {
        'nome':
            ex['free_name'] as String? ?? ex['name'] as String? ?? 'Exercício',
        'series': (exGroup['totalSets'] as int?) ?? 1,
        'reps': ((exGroup['sets'] as List).isNotEmpty
            ? ((exGroup['sets'] as List<Map<String, dynamic>>)
                    .first['reps']
                    ?.toString() ??
                '—')
            : '—'),
        'duracao_segundos': ex['duration_seconds'] as int? ?? 0,
      };
    }).toList();
    getIt<WatchService>().sendWorkoutState(
      workoutName: _effectiveWorkoutName,
      bpm: '— bpm',
      exercises: exercises,
    );
  }

  // MET ~5 (musculação moderada) × peso padrão 70 kg × horas
  double get _estimatedCalories => 5.0 * 70 * (_elapsedSeconds / 3600.0);

  Future<void> _exitWorkout() async {
    if (_finishing || _isFinishing || _pausing) return;
    _pausing = true;
    context.read<WorkoutSessionProvider>().setPausedWorkout(
          PausedWorkoutSummary(
            id: widget.workoutId,
            name: _effectiveWorkoutName,
            source: 'free',
            startedAt: _startTime,
            totalExercises: _exercises.length,
            completedExercises: _currentExerciseIdx,
            currentExerciseName: _currentExerciseName,
          ),
        );
    try {
      await LiveActivityService.end(reason: 'pause', mode: 'free');
      if (mounted) Navigator.of(context).pop();
    } finally {
      _pausing = false;
    }
  }

  int get _completedSetsCount {
    int count = 0;
    for (final ex in _exercises) {
      final sets = ex['sets'] as List<Map<String, dynamic>>? ?? [];
      // `_confirmSet` grava `completed_at` (não `is_completed`) — mesmo
      // campo que `_setToUiMap` usa para hidratar o estado inicial.
      count += sets.where((s) => s['completed_at'] != null).length;
    }
    return count;
  }

  int get _totalSetsCount => _exercises.fold<int>(
      0,
      (total, exercise) =>
          total +
          (exercise['sets'] as List<Map<String, dynamic>>? ?? const []).length);

  int get _completedExercisesCount => _exercises.where((exercise) {
        final sets =
            exercise['sets'] as List<Map<String, dynamic>>? ?? const [];
        return sets.any((set) => set['completed_at'] != null);
      }).length;

  Future<void> _finishWorkout() async {
    if (_finishing) return;
    _finishing = true;
    _isFinishing = true;
    final sessionProvider = context.read<WorkoutSessionProvider>();
    sessionProvider.beginFinishing(widget.workoutId);
    final setsCount = _completedSetsCount;
    final exerciseCount = _completedExercisesCount;
    debugPrint('[Summary] setsCount capturado: $setsCount');
    debugPrint('[Summary] exerciseCount capturado: $exerciseCount');
    final result = await getIt<uc.CompleteWorkoutWithAnalytics>()(
      workoutId: widget.workoutId,
      source: 'free',
      setsCompleted: setsCount,
      exerciseCount: exerciseCount,
    );
    final summaryData = result.valueOrNull;
    if (summaryData == null) {
      _finishing = false;
      _isFinishing = false;
      sessionProvider.markActive(widget.workoutId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result.failureOrNull?.message ??
              'Não foi possível concluir o treino. Tente novamente.'),
        ));
      }
      return;
    }
    sessionProvider.markCompleted(widget.workoutId);
    _timer?.cancel();
    _restTimer?.cancel();
    try {
      await getIt<NotificationService>().cancelRestNotification();
    } catch (error) {
      debugPrint(
          '[WorkoutLifecycle] Falha ao cancelar rest notification: $error');
    }
    unawaited(getIt<WatchService>().sendWorkoutFinished());
    _hrSubscription?.cancel();
    unawaited(getIt<HealthKitService>().saveCalories(
      calories: _estimatedCalories,
      startTime: _startTime,
      endTime: DateTime.now(),
    ));
    getIt<HealthKitService>().stopHeartRateMonitoring();
    unawaited(getIt<CheckAndUnlockAchievements>()('workout'));
    try {
      await LiveActivityService.end(reason: 'finish', mode: 'free');
    } catch (error) {
      debugPrint('[WorkoutLifecycle] Falha ao encerrar Live Activity: $error');
    }
    unawaited(WidgetDataService.updateAll());
    if (!mounted) return;
    await _maybeTriggerPopups();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => WorkoutSummaryScreen(data: summaryData)),
    );
  }

  Future<void> _maybeTriggerPopups() async {
    // Review popup has priority; both can't show the same day
    final showReview = await PopupService.shouldShowReviewPopup();
    if (showReview && mounted) {
      await ReviewModal.show(context);
      return;
    }

    if (!mounted) return;
    try {
      final profile = await UserService.instance.getCurrentUserProfile();
      if (profile == null || !mounted) return;
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      final permGranted =
          settings.authorizationStatus == AuthorizationStatus.authorized;
      final showNotif = await PopupService.shouldShowNotificationPopup(
        userCreatedAt: profile.createdAt,
        osPermissionGranted: permGranted,
      );
      if (showNotif && mounted) {
        await NotificationPermissionModal.show(context);
      }
    } catch (_) {}
  }

  Future<void> _stopWorkout() async {
    final l10n = AppLocalizations.of(context);
    final ok = await BldrV2ConfirmDialog.show(
      context,
      title: l10n.workout_stop_title,
      message: l10n.workout_stop_body,
      cancelLabel: l10n.common_continue_btn,
      confirmLabel: l10n.workout_stop_btn,
    );
    if (ok && mounted) _finishWorkout();
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_isFinishing) _exitWorkout();
      },
      child: Scaffold(
        backgroundColor: BldrColors.bgBase,
        body: BldrBackground(
          child: SafeArea(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: BldrColors.goldBright))
                : _loadError != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_loadError!, style: BldrText.body),
                            const SizedBox(height: 12),
                            BldrPrimaryButton(
                              label: 'Tentar novamente',
                              onPressed: _retryLoadWorkout,
                            ),
                          ],
                        ),
                      )
                    : _buildV2Body(),
          ),
        ),
      ),
    );
  }

  // ══ Treino em andamento v2 (179:1319) ══════════════════════════════════════

  static const double _px = 18;

  Widget _buildV2Body() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(_px, 12, _px, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _v2Header(),
                const SizedBox(height: 14),
                _v2Hud(),
                if (_exercises.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _v2CurrentExercise(),
                  const SizedBox(height: 16),
                  _v2Execution(),
                  const SizedBox(height: 20),
                  _v2NextSet(),
                  const SizedBox(height: 16),
                  _v2Inputs(),
                  const SizedBox(height: 16),
                  _v2Rest(),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(_px, 4, _px, 12),
          child: Column(children: [
            _v2PrimaryCta(),
            const SizedBox(height: 10),
            _v2BottomNav(),
          ]),
        ),
      ],
    );
  }

  Widget _v2Header() {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                      color: BldrActiveColorsV2.gold, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(l10n.workout_in_progress,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrActiveTextV2.status),
                ),
              ]),
              const SizedBox(height: 4),
              Text(_effectiveWorkoutName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BldrActiveTextV2.name),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(l10n.workout_time_label, style: BldrActiveTextV2.label),
            const SizedBox(height: 2),
            Text(_formatTime(_elapsedSeconds), style: BldrActiveTextV2.timer),
          ],
        ),
        const SizedBox(width: 16),
        Semantics(
          button: true,
          label: l10n.workout_stop_label,
          child: GestureDetector(
            onTap: _isFinishing ? null : _stopWorkout,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 34,
              height: 34,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: BldrActiveColorsV2.closeBg,
                shape: BoxShape.circle,
                border: Border.all(color: BldrActiveColorsV2.closeBorder),
              ),
              child: const Icon(TablerIcons.x,
                  size: 18, color: BldrActiveColorsV2.muted),
            ),
          ),
        ),
      ],
    );
  }

  Widget _hudTile(String label, String value,
      {String? suffix, bool accent = false}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: BldrActiveColorsV2.hudBg,
        borderRadius: BorderRadius.circular(20),
        border: accent
            ? Border.all(color: BldrActiveColorsV2.hudAccentBorder)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BldrActiveTextV2.label),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value,
                    style: accent
                        ? BldrActiveTextV2.hudAccent
                        : BldrActiveTextV2.hudValue),
                if (suffix != null) ...[
                  const SizedBox(width: 6),
                  Text(suffix, style: BldrActiveTextV2.hudSuffix),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _v2Hud() {
    final l10n = AppLocalizations.of(context);
    final total = _totalSetsCount;
    final done = _completedSetsCount;
    final current = total == 0 ? 0 : (done + 1).clamp(1, total);
    final pct = total == 0 ? 0 : (done / total * 100).round();
    final tiles = <Widget>[
      // FC só com batimento recebido (Watch/HealthKit) — sem "—".
      if (_currentBpm > 0)
        _hudTile(l10n.aw_hr, '${_currentBpm.round()}', suffix: l10n.aw_bpm),
      _hudTile(l10n.aw_kcal, '${_estimatedCalories.round()}'),
      _hudTile(l10n.workout_set_label, '$current',
          suffix: l10n.aw_set_of(total)),
      _hudTile(l10n.aw_workout, '$pct%', accent: true),
    ];
    return Row(children: [
      for (var i = 0; i < tiles.length; i++) ...[
        if (i > 0) const SizedBox(width: 9),
        Expanded(child: tiles[i]),
      ],
    ]);
  }

  /// Dados de exibição do exercício atual (nome, músculos, GIF).
  ({
    String name,
    String muscles,
    String? gifUrl,
    Map<String, dynamic> ex,
    ExerciseDetail? detail
  }) _currentView() {
    final exGroup = _exercises[_currentExerciseIdx];
    final ex = exGroup['exercise'] as Map<String, dynamic>;
    final exerciseDbId = ex['exercise_db_id'] as String?;
    final detail = exerciseDbId != null ? _exDbCache[exerciseDbId] : null;
    final name = resolveExerciseDisplayName(
      internalName: ex['name'] as String?,
      exerciseDbName: detail?.name,
    );
    final muscle = detail?.targetMuscles.isNotEmpty == true
        ? detail!.targetMuscles.first
        : (_muscleGroupText(ex['primary_muscle_group']) ?? '');
    final secondary = detail?.secondaryMuscles ?? <String>[];
    final muscles =
        [muscle, ...secondary.take(2)].where((m) => m.isNotEmpty).join(' • ');
    String? gifUrl = detail?.gifUrl;
    if ((gifUrl == null || gifUrl.isEmpty) && exerciseDbId != null) {
      gifUrl = 'https://static.exercisedb.dev/media/$exerciseDbId.gif';
    }
    return (
      name: name,
      muscles: muscles,
      gifUrl: gifUrl,
      ex: ex,
      detail: detail
    );
  }

  Map<String, dynamic>? get _currentSetRow {
    final sets =
        _exercises[_currentExerciseIdx]['sets'] as List<Map<String, dynamic>>;
    final i = _currentSetNumber - 1;
    return i >= 0 && i < sets.length ? sets[i] : null;
  }

  Widget _v2CurrentExercise() {
    final l10n = AppLocalizations.of(context);
    final v = _currentView();
    final totalSets = _exercises[_currentExerciseIdx]['totalSets'] as int;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.aw_current, style: BldrActiveTextV2.eyebrow),
              const SizedBox(height: 4),
              Text(v.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: BldrActiveTextV2.exName),
              if (v.muscles.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(v.muscles,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BldrActiveTextV2.muscles),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          margin: const EdgeInsets.only(top: 22),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: BldrActiveColorsV2.closeBg,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: BldrActiveColorsV2.badgeBorder),
          ),
          child: Text(l10n.aw_set_badge(_currentSetNumber, totalSets),
              style: BldrActiveTextV2.badge),
        ),
      ],
    );
  }

  /// Área "Execução" (P4): GIF atual em loop; tocar abre a técnica.
  Widget _v2Execution() {
    final l10n = AppLocalizations.of(context);
    final v = _currentView();
    final reps = (_currentSetRow?['reps'] as int?) ?? _reps;
    return Semantics(
      button: true,
      label: l10n.workout_see_technique,
      child: GestureDetector(
        onTap: () => _showTechniqueSheet(v.ex, v.detail),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: BldrActiveColorsV2.mediaBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: BldrActiveColorsV2.goldBrand),
          ),
          child: Column(children: [
            Container(
              height: 188,
              decoration: BoxDecoration(
                color: BldrActiveColorsV2.mediaInner,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: BldrActiveColorsV2.mediaInnerBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(fit: StackFit.expand, children: [
                  if (_isPrefetching)
                    const Center(
                      child: CircularProgressIndicator(
                          color: BldrActiveColorsV2.gold, strokeWidth: 2),
                    )
                  else if (v.gifUrl != null)
                    ColorFiltered(
                      // GIFs do ExerciseDB têm fundo branco: o multiply
                      // escurece sem lavar o conteúdo (mesmo filtro de antes).
                      colorFilter: const ColorFilter.mode(
                          Color(0xFFB8B8B8), BlendMode.multiply),
                      child: CachedNetworkImage(
                        imageUrl: v.gifUrl!,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(
                              color: BldrActiveColorsV2.gold, strokeWidth: 2),
                        ),
                        errorWidget: (_, __, ___) => const Center(
                          child: Icon(TablerIcons.barbell,
                              color: BldrActiveColorsV2.muted, size: 32),
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: Icon(TablerIcons.barbell,
                          color: BldrActiveColorsV2.muted, size: 32),
                    ),
                  Positioned(
                    left: 16,
                    top: 13,
                    child:
                        Text(l10n.aw_execution, style: BldrActiveTextV2.label),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              constraints: const BoxConstraints(minHeight: 28),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: BldrActiveColorsV2.cueBg,
                borderRadius: BorderRadius.circular(14),
              ),
              // Cadência oculta ([F]); alvo = reps da série.
              alignment: Alignment.centerRight,
              child: Text(l10n.aw_target(reps),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BldrActiveTextV2.cueTarget),
            ),
          ]),
        ),
      ),
    );
  }

  static String _kgText(double kg) => BldrV2Stepper.format(kg, decimal: true);

  Widget _v2NextSet() {
    final l10n = AppLocalizations.of(context);
    final row = _currentSetRow;
    final kg = (row?['weight_kg'] as num?)?.toDouble() ?? _weight;
    final reps = (row?['reps'] as int?) ?? _reps;
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
      decoration: BoxDecoration(
        color: BldrActiveColorsV2.mediaBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: BldrActiveColorsV2.cardBorder),
      ),
      // "PR possível", "Última vez" e delta ocultos ([F]).
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.aw_next_set, style: BldrActiveTextV2.label),
          const SizedBox(height: 6),
          Text('${_kgText(kg)} kg  ×  $reps',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BldrActiveTextV2.nextSet),
        ],
      ),
    );
  }

  Widget _inputCard(String label, String value, String? unit,
      VoidCallback onTap, String semantics) {
    return Semantics(
      button: true,
      label: semantics,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          constraints: const BoxConstraints(minHeight: 94),
          padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
          decoration: BoxDecoration(
            color: BldrActiveColorsV2.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: BldrActiveColorsV2.inputBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: BldrActiveTextV2.label),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value, style: BldrActiveTextV2.inputValue),
                    if (unit != null) ...[
                      const SizedBox(width: 8),
                      Text(unit, style: BldrActiveTextV2.inputUnit),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLoadSheet() {
    final l10n = AppLocalizations.of(context);
    BldrV2Sheet.show<void>(
      context,
      title: l10n.aw_sheet_load,
      child: BldrV2Stepper(
        initial: _weight,
        step: 2.5,
        decimal: true,
        unit: 'kg',
        decreaseLabel: l10n.workout_decrease_load,
        increaseLabel: l10n.workout_increase_load,
        onChanged: (v) {
          setState(() => _weight = v);
          _updateLiveActivity();
        },
      ),
    );
  }

  void _openRepsSheet() {
    final l10n = AppLocalizations.of(context);
    BldrV2Sheet.show<void>(
      context,
      title: l10n.aw_sheet_reps,
      child: BldrV2Stepper(
        initial: _reps.toDouble(),
        step: 1,
        decreaseLabel: l10n.workout_decrease_reps,
        increaseLabel: l10n.workout_increase_reps,
        onChanged: (v) {
          setState(() => _reps = v.round());
          _updateLiveActivity();
        },
      ),
    );
  }

  Widget _v2Inputs() {
    final l10n = AppLocalizations.of(context);
    return Row(children: [
      Expanded(
        child: _inputCard(l10n.aw_load, _kgText(_weight), 'kg', _openLoadSheet,
            l10n.aw_sheet_load),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: _inputCard(
            l10n.aw_reps, '$_reps', null, _openRepsSheet, l10n.aw_sheet_reps),
      ),
    ]);
  }

  /// Card de descanso (P3): fora do descanso mostra o descanso da série;
  /// descansando, contagem regressiva, "+15 s" e "›" (pular).
  Widget _v2Rest() {
    final l10n = AppLocalizations.of(context);
    final planned = (_currentSetRow?['rest_seconds'] as int?) ?? 90;
    final seconds = _resting ? _restSecondsLeft : planned;
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.only(left: 15, right: 4),
      decoration: BoxDecoration(
        color: BldrActiveColorsV2.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BldrActiveColorsV2.cardBorder),
      ),
      child: Row(children: [
        const Icon(TablerIcons.clock, size: 18, color: BldrActiveColorsV2.gold),
        const SizedBox(width: 10),
        Expanded(
          child: Row(children: [
            Flexible(
              child: Text(l10n.aw_rest,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BldrActiveTextV2.label),
            ),
            if (_resting) ...[
              const SizedBox(width: 6),
              Semantics(
                button: true,
                label: l10n.workout_add_rest_label,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _addRestSeconds(15),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                    child: Text(l10n.aw_add15, style: BldrActiveTextV2.restAdd),
                  ),
                ),
              ),
            ],
          ]),
        ),
        Text(_formatTime(seconds), style: BldrActiveTextV2.restValue),
        if (_resting)
          Semantics(
            button: true,
            label: l10n.workout_skip_rest,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _endRestEarly,
              child: const SizedBox(
                width: 40,
                height: 50,
                child: Icon(TablerIcons.chevron_right,
                    size: 22, color: BldrActiveColorsV2.gold),
              ),
            ),
          )
        else
          const SizedBox(width: 14),
      ]),
    );
  }

  Widget _v2PrimaryCta() {
    final l10n = AppLocalizations.of(context);
    final enabled = _confirmingSetId == null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? _confirmSet : null,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: BldrActiveColorsV2.goldBrand),
            ),
            child: Text(l10n.aw_confirm,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BldrActiveTextV2.cta),
          ),
        ),
      ),
    );
  }

  Widget _v2BottomNav() {
    final l10n = AppLocalizations.of(context);
    final hasNext = _currentExerciseIdx < _exercises.length - 1;
    String nextName = l10n.aw_last;
    if (hasNext) {
      final ex = _exercises[_currentExerciseIdx + 1]['exercise']
          as Map<String, dynamic>;
      final id = ex['exercise_db_id'] as String?;
      nextName = resolveExerciseDisplayName(
        internalName: ex['name'] as String?,
        exerciseDbName: id != null ? _exDbCache[id]?.name : null,
      );
    }
    final canSkip = _confirmingSetId == null && _exercises.isNotEmpty;
    // "Anterior" oculto: voltar ao exercício anterior não existe ([F]).
    return Row(children: [
      Semantics(
        button: true,
        label: l10n.aw_pause,
        child: GestureDetector(
          onTap: _isFinishing ? null : _exitWorkout,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: BldrActiveColorsV2.mediaBg,
              shape: BoxShape.circle,
              border: Border.all(color: BldrActiveColorsV2.pauseBorder),
            ),
            child: const Icon(TablerIcons.player_pause,
                size: 20, color: BldrActiveColorsV2.gold),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Semantics(
          button: true,
          label: l10n.workout_skip_exercise,
          child: GestureDetector(
            // Mesmo "Pular" de hoje (decisão do usuário).
            onTap: canSkip ? _skipExercise : null,
            behavior: HitTestBehavior.opaque,
            child: Container(
              constraints: const BoxConstraints(minHeight: 58),
              padding: const EdgeInsets.only(left: 13, right: 6),
              decoration: BoxDecoration(
                color: BldrActiveColorsV2.mediaBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: BldrActiveColorsV2.cardBorder),
              ),
              child: Row(children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.aw_next, style: BldrActiveTextV2.label),
                      Text(nextName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BldrActiveTextV2.nextName),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 36,
                  child: Icon(TablerIcons.chevron_right,
                      size: 22, color: BldrActiveColorsV2.gold),
                ),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }

  void _showTechniqueSheet(Map<String, dynamic> ex, ExerciseDetail? detail) {
    // Instructions: prefer ExerciseDB detail, then internal exercises table,
    // then empty (shows "Sem instruções disponíveis." message).
    final instructions = detail?.instructions.isNotEmpty == true
        ? detail!.instructions
        : (ex['instructions'] as List?)?.cast<String>() ?? [];

    final targetMuscles = detail?.targetMuscles ??
        (_muscleGroupText(ex['primary_muscle_group']) != null
            ? [_muscleGroupText(ex['primary_muscle_group'])!]
            : <String>[]);
    final secondaryMuscles = detail?.secondaryMuscles ?? <String>[];

    final l10n = AppLocalizations.of(context);
    BldrV2Sheet.show<void>(
      context,
      title: resolveExerciseDisplayName(
        internalName: ex['name'] as String?,
        exerciseDbName: detail?.name,
        fallback: l10n.workout_technique_fallback,
      ),
      child: Builder(
        builder: (sheetCtx) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (targetMuscles.isNotEmpty) ...[
              MuscleVisualizerWidget(
                targetMuscles: targetMuscles,
                secondaryMuscles: secondaryMuscles,
                isPro: _isPro,
                size: VisualizerSize.full,
                paywallMessage: l10n.workout_paywall_muscle_message,
                paywallButtonLabel: l10n.plan_paywall_muscle_btn,
                onUpgradeTap: () {
                  Navigator.pop(sheetCtx);
                  Navigator.pushNamed(context, AppRoutes.checkoutScreen);
                },
              ),
              const SizedBox(height: 18),
            ],
            Text(l10n.aw_execution, style: BldrSheetV2Text.label),
            const SizedBox(height: 10),
            if (instructions.isEmpty)
              Text(l10n.workout_no_instructions, style: BldrSheetV2Text.body)
            else
              for (var i = 0; i < instructions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(right: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: BldrSheetV2Colors.border),
                        ),
                        child: Text('${i + 1}', style: BldrActiveTextV2.badge),
                      ),
                      Expanded(
                        child:
                            Text(instructions[i], style: BldrSheetV2Text.body),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  // ── steppers de carga / repetições (item 6) ─────────────────────────────
}

/// `Exercise.primaryMuscleGroup` é `dynamic` por design: `String` nos
/// exercícios da base interna, `List` nos vindos do ExerciseDB (ver
/// lib/features/workouts/domain/entities/exercise.dart). Cast direto para
/// `String?` quebra em runtime para exercícios do ExerciseDB — esta função
/// normaliza os dois formatos para exibição.
String? _muscleGroupText(dynamic value) {
  if (value is String) return value.isEmpty ? null : value;
  if (value is List) {
    final parts = value.whereType<String>().where((e) => e.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(', ');
  }
  return null;
}
