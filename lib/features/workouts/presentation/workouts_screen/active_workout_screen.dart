import 'dart:async';
import 'dart:math' as math;
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
import 'package:bldr_fitness/features/subscription/domain/usecases/resolve_club_access.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';
import 'package:bldr_fitness/features/workouts/presentation/exercise_display_name.dart';
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
  final Set<int> _skippedExerciseIndexes = <int>{};

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
        _restTotalSeconds = action.totalSeconds > 0
            ? action.totalSeconds
            : _restTotalSeconds;
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
    return exData['name'] as String? ??
        exData['free_name'] as String? ??
        _effectiveWorkoutName;
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

  void _skipExercise() {
    if (_currentExerciseIdx >= _exercises.length - 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Conclua ou pause o treino no último exercício.'),
      ));
      return;
    }
    _skippedExerciseIndexes.add(_currentExerciseIdx);
    unawaited(_nextExercise());
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

  void _stopWorkout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BldrColors.sheetBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(ctx).workout_stop_title,
            style: BldrText.cardTitleLg),
        content: Text(AppLocalizations.of(ctx).workout_stop_body,
            style: BldrText.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx).common_continue_btn,
                style: BldrText.buttonSecondary),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finishWorkout();
            },
            child: Text(AppLocalizations.of(ctx).workout_stop_btn,
                style: const TextStyle(
                    fontFamily: BldrText.family,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: BldrColors.danger)),
          ),
        ],
      ),
    );
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
                : Stack(
                    children: [
                      Column(
                        children: [
                          _buildHeader(),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: BldrSpacing.pageX),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 16),
                                  _buildTimeSeriesCards(),
                                  const SizedBox(height: 14),
                                  _buildOverallProgress(),
                                  const SizedBox(height: 22),
                                  if (_exercises.isNotEmpty) ...[
                                    _buildCurrentExercise(),
                                    const SizedBox(height: 18),
                                    _buildInputRow(),
                                    const SizedBox(height: 14),
                                    _buildSeriesList(),
                                    const SizedBox(height: 22),
                                    _buildExerciseTimeline(),
                                    const SizedBox(height: 130),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          _buildFooter(),
                        ],
                      ),
                      // Faixa de descanso — flutua sobre o conteúdo, que
                      // continua rolável e utilizável por trás dela.
                      if (_resting)
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 88,
                          child: _buildRestFloatingStrip(),
                        ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ── header (item 2) ──────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BldrSpacing.pageX, 12, BldrSpacing.pageX, 14),
      child: Row(
        children: [
          Semantics(
            label: AppLocalizations.of(context).common_back_btn,
            button: true,
            child: BldrCircleButton(
              icon: Icons.chevron_left,
              size: 36,
              filled: false,
              onPressed: _isFinishing ? null : _exitWorkout,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(AppLocalizations.of(context).workout_in_progress,
                    style: BldrText.label),
                const SizedBox(height: 2),
                Text(
                  _effectiveWorkoutName,
                  style: BldrText.cardTitleLg,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Semantics(
            label: AppLocalizations.of(context).workout_stop_label,
            button: true,
            child: GestureDetector(
              onTap: _stopWorkout,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0x24E06B5A), // rgba(224,107,90,0.14)
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x4DE06B5A)),
                ),
                child: const Icon(Icons.stop_rounded,
                    color: BldrColors.danger, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── tempo / série (item 3) ───────────────────────────────────────────────

  Widget _buildTimeSeriesCards() {
    final totalSets = _exercises.isEmpty
        ? 1
        : (_exercises[_currentExerciseIdx]['totalSets'] as int);

    return Row(
      children: [
        Expanded(
          child: BldrGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).workout_time_label,
                    style: BldrText.label),
                const SizedBox(height: 4),
                Text(
                  _formatTime(_elapsedSeconds),
                  style: const TextStyle(
                    fontFamily: BldrText.family,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: BldrColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: BldrSpacing.gapCard),
        Expanded(
          child: BldrGlassCard(
            background: BldrColors.goldTintStrong,
            borderColor: BldrColors.goldBorder,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).workout_set_label,
                    style:
                        BldrText.label.copyWith(color: BldrColors.goldBright)),
                const SizedBox(height: 4),
                Text(
                  '$_currentSetNumber de $totalSets',
                  style: const TextStyle(
                    fontFamily: BldrText.family,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: BldrColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_currentBpm > 0) ...[
          const SizedBox(width: BldrSpacing.gapCard),
          Expanded(
            child: BldrGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.favorite_rounded,
                        size: 12, color: BldrColors.danger),
                    const SizedBox(width: 4),
                    Text('FC', style: BldrText.label),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    '${_currentBpm.round()} bpm',
                    style: const TextStyle(
                      fontFamily: BldrText.family,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: BldrColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── progresso do treino (item 4) ─────────────────────────────────────────

  Widget _buildOverallProgress() {
    final totalEx = _exercises.length;
    final doneEx = _currentExerciseIdx;
    final totalSets = _totalSetsCount;
    final progress = totalSets == 0 ? 0.0 : _completedSetsCount / totalSets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                AppLocalizations.of(context).workout_exercise_of(
                    totalEx == 0 ? 0 : doneEx + 1, totalEx),
                style: BldrText.meta),
            Text(
                AppLocalizations.of(context)
                    .workout_percent_done((progress * 100).round()),
                style: BldrText.meta.copyWith(
                    color: BldrColors.goldBright, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 8),
        BldrProgressBar(value: progress, gradient: true),
      ],
    );
  }

  // ── exercício atual (item 1 + item 5) ────────────────────────────────────

  Widget _buildCurrentExercise() {
    if (_exercises.isEmpty) return const SizedBox();
    final exGroup = _exercises[_currentExerciseIdx];
    final ex = exGroup['exercise'] as Map<String, dynamic>;
    final exerciseDbId = ex['exercise_db_id'] as String?;
    final detail = exerciseDbId != null ? _exDbCache[exerciseDbId] : null;

    // Prefer name from ExerciseDB detail (covers ExerciseDB-picker exercises
    // that have no row in the internal exercises table).
    final name = resolveExerciseDisplayName(
      internalName: ex['name'] as String?,
      exerciseDbName: detail?.name,
    );

    final equipment = detail != null && detail.equipments.isNotEmpty
        ? detail.equipments.join(', ')
        : (_muscleGroupText(ex['primary_muscle_group']) ?? 'Sem equipamento');

    final muscle = detail?.targetMuscles.isNotEmpty == true
        ? detail!.targetMuscles.first
        : (_muscleGroupText(ex['primary_muscle_group']) ?? '');

    final secondaryMuscles = detail?.secondaryMuscles ?? <String>[];
    final muscleSubtitle = secondaryMuscles.isNotEmpty
        ? '$muscle · ${secondaryMuscles.take(2).join(', ')}'
        : muscle;

    String? gifUrl = detail?.gifUrl;
    if ((gifUrl == null || gifUrl.isEmpty) && exerciseDbId != null) {
      gifUrl = 'https://static.exercisedb.dev/media/$exerciseDbId.gif';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item 5 — título curto + subtítulo (grupos musculares) + chip de
        // equipamento à direita.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: BldrText.family,
                      fontSize: 21,
                      fontWeight: FontWeight.w600,
                      color: BldrColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  if (muscleSubtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(muscleSubtitle, style: BldrText.meta),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            BldrChip(
                icon: Icons.fitness_center, label: equipment, active: true),
          ],
        ),
        const SizedBox(height: 14),
        // Item 1 — imagem do exercício em card de vidro, nunca fundo branco.
        SizedBox(
          height: 168,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                  child: _buildExerciseImageCard(gifUrl, muscle, ex, detail)),
              const SizedBox(width: 10),
              MuscleVisualizerWidget(
                targetMuscles: detail?.targetMuscles ??
                    (muscle.isNotEmpty ? [muscle] : []),
                secondaryMuscles: secondaryMuscles,
                isPro: _isPro,
                size: VisualizerSize.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseImageCard(String? gifUrl, String muscle,
      Map<String, dynamic> ex, ExerciseDetail? detail) {
    return Container(
      decoration: BoxDecoration(
        color: BldrColors.surface,
        borderRadius: BldrRadius.all(BldrRadius.card),
        border: Border.all(color: BldrColors.border),
      ),
      child: ClipRRect(
        borderRadius: BldrRadius.all(BldrRadius.card),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isPrefetching)
              const Center(
                child: CircularProgressIndicator(
                    color: BldrColors.goldBright, strokeWidth: 2),
              )
            else if (gifUrl != null)
              ColorFiltered(
                // A maioria das imagens do ExerciseDB tem fundo branco — em
                // academia com pouca luz isso ofusca. O multiply escurece
                // sem lavar o conteúdo da imagem.
                colorFilter: const ColorFilter.mode(
                    Color(0xFFB8B8B8), BlendMode.multiply),
                child: CachedNetworkImage(
                  imageUrl: gifUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(
                        color: BldrColors.goldBright, strokeWidth: 2),
                  ),
                  errorWidget: (_, __, ___) => const Center(
                    child: Icon(Icons.fitness_center,
                        color: BldrColors.textMuted, size: 32),
                  ),
                ),
              )
            else
              const Center(
                child: Icon(Icons.fitness_center,
                    color: BldrColors.textMuted, size: 32),
              ),
            // Gradiente escuro na parte inferior — legibilidade dos badges.
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 76,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xBF050505), Color(0x00050505)],
                    stops: [0.0, 1.0],
                  ),
                ),
              ),
            ),
            if (muscle.isNotEmpty)
              Positioned(
                left: 8,
                bottom: 8,
                child: BldrBadge(label: muscle, gold: false),
              ),
            if (!_isPrefetching)
              Positioned(
                right: 8,
                top: 8,
                child: GestureDetector(
                  onTap: () => _showTechniqueSheet(ex, detail),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: BldrColors.goldSolid,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      AppLocalizations.of(context).workout_see_technique,
                      style: TextStyle(
                        fontFamily: BldrText.family,
                        color: Color(0xFF0A0A0A),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
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

    showModalBottomSheet(
      context: context,
      backgroundColor: BldrColors.sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (_, sc) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: BldrColors.textMuted,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                resolveExerciseDisplayName(
                  internalName: ex['name'] as String?,
                  exerciseDbName: detail?.name,
                  fallback: AppLocalizations.of(sheetCtx)
                      .workout_technique_fallback,
                ),
                style: BldrText.cardTitleLg,
              ),
              const SizedBox(height: 14),
              // ── Muscle visualizer ─────────────────────────────────────────
              if (targetMuscles.isNotEmpty)
                MuscleVisualizerWidget(
                  targetMuscles: targetMuscles,
                  secondaryMuscles: secondaryMuscles,
                  isPro: _isPro,
                  size: VisualizerSize.full,
                  paywallMessage: AppLocalizations.of(sheetCtx)
                      .workout_paywall_muscle_message,
                  paywallButtonLabel:
                      AppLocalizations.of(sheetCtx).plan_paywall_muscle_btn,
                  onUpgradeTap: () {
                    Navigator.pop(sheetCtx);
                    Navigator.pushNamed(context, AppRoutes.checkoutScreen);
                  },
                ),
              if (targetMuscles.isNotEmpty) const SizedBox(height: 16),
              // ── Instructions ──────────────────────────────────────────────
              if (instructions.isNotEmpty)
                Text(AppLocalizations.of(sheetCtx).workout_execution_label,
                    style: BldrText.label),
              if (instructions.isNotEmpty) const SizedBox(height: 8),
              Expanded(
                child: instructions.isEmpty
                    ? Center(
                        child: Text(
                            AppLocalizations.of(sheetCtx)
                                .workout_no_instructions,
                            style: BldrText.description),
                      )
                    : ListView.separated(
                        controller: sc,
                        itemCount: instructions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2, right: 8),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: BldrColors.goldTint,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: BldrColors.goldBorder),
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                      fontFamily: BldrText.family,
                                      color: BldrColors.goldBright,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            Expanded(
                              child:
                                  Text(instructions[i], style: BldrText.body),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── steppers de carga / repetições (item 6) ─────────────────────────────

  Widget _buildInputRow() {
    // ⚠️ IntrinsicHeight é obrigatório aqui: Row com CrossAxisAlignment.stretch
    // direto num Column/SingleChildScrollView de altura não-limitada quebra a
    // renderização inteira da tela, sem exceção nem log (já aconteceu no
    // Dashboard — ver BldrTimelineItem).
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildStepper(
              label: AppLocalizations.of(context).workout_load_kg,
              valueLabel: _weight == _weight.roundToDouble()
                  ? _weight.toInt().toString()
                  : _weight.toStringAsFixed(1),
              decreaseSemantics:
                  AppLocalizations.of(context).workout_decrease_load,
              increaseSemantics:
                  AppLocalizations.of(context).workout_increase_load,
              onDecrease: () {
                setState(() => _weight = (_weight - 2.5).clamp(0, 999));
                _updateLiveActivity();
              },
              onIncrease: () {
                setState(() => _weight = _weight + 2.5);
                _updateLiveActivity();
              },
            ),
          ),
          const SizedBox(width: BldrSpacing.gapCard),
          Expanded(
            child: _buildStepper(
              label: AppLocalizations.of(context).workout_reps_label,
              valueLabel: '$_reps',
              decreaseSemantics:
                  AppLocalizations.of(context).workout_decrease_reps,
              increaseSemantics:
                  AppLocalizations.of(context).workout_increase_reps,
              onDecrease: () {
                setState(() => _reps = (_reps - 1).clamp(0, 999));
                _updateLiveActivity();
              },
              onIncrease: () {
                setState(() => _reps = _reps + 1);
                _updateLiveActivity();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper({
    required String label,
    required String valueLabel,
    required String decreaseSemantics,
    required String increaseSemantics,
    required VoidCallback onDecrease,
    required VoidCallback onIncrease,
  }) {
    return BldrGlassCard(
      child: Column(
        children: [
          Text(label, style: BldrText.label),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                label: decreaseSemantics,
                button: true,
                child: BldrCircleButton(
                    icon: Icons.remove,
                    size: 38,
                    filled: false,
                    onPressed: onDecrease),
              ),
              Text(
                valueLabel,
                style: const TextStyle(
                  fontFamily: BldrText.family,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: BldrColors.textPrimary,
                ),
              ),
              Semantics(
                label: increaseSemantics,
                button: true,
                child: BldrCircleButton(
                    icon: Icons.add,
                    size: 38,
                    filled: false,
                    onPressed: onIncrease),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── lista de séries (item 8) ─────────────────────────────────────────────

  Widget _buildSeriesList() {
    if (_exercises.isEmpty) return const SizedBox();
    final sets =
        _exercises[_currentExerciseIdx]['sets'] as List<Map<String, dynamic>>;

    return Column(
      children: List.generate(sets.length, (i) {
        final setIndex = i + 1;
        final isDone = setIndex < _currentSetNumber;
        final isCurrent = setIndex == _currentSetNumber;
        final state = isDone
            ? BldrSetRowState.done
            : isCurrent
                ? BldrSetRowState.current
                : BldrSetRowState.pending;

        String? valueLabel;
        if (isDone) {
          final w = (sets[i]['weight_kg'] as num?)?.toDouble();
          final r = sets[i]['reps'] as int?;
          final parts = <String>[
            if (w != null)
              '${w == w.roundToDouble() ? w.toInt() : w.toStringAsFixed(1)} kg',
            if (r != null) '$r reps',
          ];
          valueLabel = parts.isEmpty ? null : parts.join(' · ');
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child:
              BldrSetRow(index: setIndex, state: state, valueLabel: valueLabel),
        );
      }),
    );
  }

  // ── descanso — faixa flutuante ───────────────────────────────────────────

  Widget _buildRestFloatingStrip() {
    final progress =
        _restTotalSeconds > 0 ? _restSecondsLeft / _restTotalSeconds : 0.0;
    final mm = _restSecondsLeft ~/ 60;
    final ss = _restSecondsLeft % 60;
    final label = mm > 0 ? '$mm:${ss.toString().padLeft(2, '0')}' : '${ss}s';

    final exGroup =
        _exercises.isNotEmpty ? _exercises[_currentExerciseIdx] : null;
    final totalSets = exGroup != null ? exGroup['totalSets'] as int : 1;
    final nextSet = _currentSetNumber.clamp(1, totalSets);

    return ClipRRect(
      borderRadius: BldrRadius.all(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0x29C9A227), // rgba(201,162,39,0.16)
            borderRadius: BldrRadius.all(22),
            border: Border.all(
                color: const Color(0x52E0B830)), // rgba(224,184,48,0.32)
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: CustomPaint(
                  painter: _MiniRingPainter(progress: progress.clamp(0.0, 1.0)),
                  child: Center(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontFamily: BldrText.family,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: BldrColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AppLocalizations.of(context).workout_resting,
                        style: BldrText.label.copyWith(
                            fontSize: 10, color: BldrColors.goldBright)),
                    const SizedBox(height: 2),
                    Text(
                        AppLocalizations.of(context)
                            .workout_next_set(nextSet, totalSets),
                        style: BldrText.body.copyWith(
                            fontSize: 12, color: BldrColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _restActionButton(
                icon: Icons.add,
                semanticLabel:
                    AppLocalizations.of(context).workout_add_rest_label,
                onTap: () => _addRestSeconds(15),
              ),
              const SizedBox(width: 8),
              _restActionButton(
                icon: Icons.skip_next_rounded,
                semanticLabel: AppLocalizations.of(context).workout_skip_rest,
                onTap: _endRestEarly,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _restActionButton({
    required IconData icon,
    required String semanticLabel,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0x17FFFFFF), // rgba(255,255,255,0.09)
          ),
          child: Icon(icon, color: BldrColors.goldBright, size: 18),
        ),
      ),
    );
  }

  // ── linha do tempo de exercícios ──────────────────────────────────────────

  Widget _buildExerciseTimeline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context).workout_exercises_label,
            style: BldrText.sectionTitle),
        const SizedBox(height: 12),
        ...List.generate(_exercises.length, (i) {
          final ex = _exercises[i]['exercise'] as Map<String, dynamic>;
          final exDbId = ex['exercise_db_id'] as String?;
          final detail = exDbId != null ? _exDbCache[exDbId] : null;
          final name = resolveExerciseDisplayName(
            internalName: ex['name'] as String?,
            exerciseDbName: detail?.name,
          );
          final isCurrent = i == _currentExerciseIdx;
          final isDone = i < _currentExerciseIdx;
          final isSkipped = _skippedExerciseIndexes.contains(i);

          return BldrTimelineItem(
            dotStyle: isDone
                ? BldrTimelineDotStyle.done
                : isCurrent
                    ? BldrTimelineDotStyle.next
                    : BldrTimelineDotStyle.pending,
            isFirst: i == 0,
            isLast: i == _exercises.length - 1,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontFamily: BldrText.family,
                        fontSize: 14,
                        color: isCurrent
                            ? BldrColors.textPrimary
                            : isDone
                                ? BldrColors.textSecondary
                                : BldrColors.textTertiary,
                        fontWeight:
                            isCurrent ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (isCurrent)
                    BldrBadge(
                        label:
                            AppLocalizations.of(context).workout_set_current),
                  if (!isCurrent && !isDone)
                    Text(AppLocalizations.of(context).workout_next_up,
                        style: BldrText.meta),
                  if (isSkipped)
                    const Text('Pulado', style: BldrText.meta)
                  else if (isDone)
                    const Icon(Icons.check_circle_outline,
                        color: BldrColors.goldBright, size: 16),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── rodapé (item 9) ──────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          BldrSpacing.pageX, 12, BldrSpacing.pageX, 18),
      decoration: BoxDecoration(
        color: BldrColors.sheetBg,
        border: Border(top: BorderSide(color: BldrColors.border)),
      ),
      child: Row(
        children: [
          Semantics(
            label: AppLocalizations.of(context).workout_skip_exercise,
            button: true,
            child: GestureDetector(
              onTap: _confirmingSetId == null ? _skipExercise : null,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 56,
                height: 48,
                decoration: BoxDecoration(
                  color: BldrColors.surface,
                  borderRadius: BldrRadius.all(BldrRadius.button),
                  border: Border.all(color: BldrColors.border),
                ),
                child: const Icon(Icons.skip_next_rounded,
                    color: BldrColors.textSecondary, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: BldrPrimaryButton(
              label: AppLocalizations.of(context).workout_confirm_set_btn,
              icon: Icons.check_rounded,
              onPressed: _confirmingSetId == null ? _confirmSet : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Anel de progresso (faixa de descanso flutuante) ───────────────────────────

class _MiniRingPainter extends CustomPainter {
  final double progress; // 1.0 = tempo cheio restante, 0.0 = zerado

  const _MiniRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;
    const strokeW = 4.0;

    // Trilho
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0x1FFFFFFF) // rgba(255,255,255,0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );

    // Arco de progresso — esvazia conforme o tempo corre.
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = const Color(0xFFE0B830)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_MiniRingPainter old) => old.progress != progress;
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
