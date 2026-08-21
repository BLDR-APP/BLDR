import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/subscription_usecases.dart' as subUc;
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/havok/havok_sheet.dart';
import 'package:bldr_fitness/features/onboarding/domain/entities/onboarding_plan.dart' as domain;
import 'package:bldr_fitness/features/workouts/domain/entities/activity_type.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/extra_activity.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/weekly_plan.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart';

import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/active_workout_screen.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/routes/app_routes.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/features/integrations/data/widget_data_service.dart';
import 'package:bldr_fitness/widgets/muscle_visualizer_widget.dart';

// ── domain ────────────────────────────────────────────────────────────────────

enum DayStatus { done, today, pending, rest, lost }

class PlanDay {
  final int weekdayIndex; // 0 = Mon, 6 = Sun
  final String abbrev;
  final DateTime date;
  final DayStatus status;
  final String? workoutLabel;
  final String? workoutId;          // ID de user_workouts (treino pessoal)
  final String? clubWorkoutId;      // ID de club_user_workouts (treino BLDR Club)
  final WorkoutSession? completedWorkout;
  final ActivityType? activityType; // F1
  final int? xpDay;                 // F2 — XP agregado do dia (bldr_club.xp_events)
  final int? durationMinutes;       // F2
  final ExtraActivity? extraActivity; // F3
  /// Template atribuído ao dia em weekly_plan_days (pode ser null se não configurado).
  final String? assignedTemplateId;
  final String? assignedTemplateName;
  /// Origem do template: 'havok' | 'user' | 'bldr'. Null quando não há template.
  final String? assignedTemplateSource;

  const PlanDay({
    required this.weekdayIndex,
    required this.abbrev,
    required this.date,
    required this.status,
    this.workoutLabel,
    this.workoutId,
    this.clubWorkoutId,
    this.completedWorkout,
    this.activityType,
    this.xpDay,
    this.durationMinutes,
    this.extraActivity,
    this.assignedTemplateId,
    this.assignedTemplateName,
    this.assignedTemplateSource,
  });
}

// ── screen ────────────────────────────────────────────────────────────────────

class WeeklyPlanScreen extends StatefulWidget {
  /// Presentation-only: mostra o badge "CLUB" no cabeçalho quando aberta a
  /// partir de Club → Meu Plano. Não muda dado nem lógica — mesmo arquivo,
  /// mesma tela, só o rótulo de origem.
  final bool isClub;

  const WeeklyPlanScreen({Key? key, this.isClub = false}) : super(key: key);

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  bool _loading = true;
  bool _isPro = false;
  List<PlanDay> _days = [];

  // Plan metadata
  String _splitLabel = '';
  int _freqDays = 3;
  String _weekRange = '';
  List<int> _restDays = []; // 0=Mon … 6=Sun

  // Summary
  int _doneDays = 0;
  int _streak = 0;
  int _trainingDays = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  DateTime _monday(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - 1));

  // Training days derived from explicitly-stored rest days
  List<int> _trainingFromRestDays(List<int> restDays) =>
      List.generate(7, (i) => i).where((i) => !restDays.contains(i)).toList();

  String _splitChipLabel(String pref) {
    if (pref.contains('Full Body')) return 'Full Body';
    if (pref.contains('Upper/Lower')) return 'Upper · Lower';
    if (pref.contains('Push/Pull/Legs')) return 'Push · Pull · Legs';
    if (pref.contains('ABCDE')) return 'A · B · C · D · E';
    if (pref.contains('HAVOK') || pref.isEmpty) return 'HAVOK decide';
    return pref.split('(').first.trim();
  }

  List<String> _splitLabels(String pref) {
    if (pref.contains('Full Body')) return ['Full Body'];
    if (pref.contains('Upper/Lower')) return ['Upper', 'Lower'];
    if (pref.contains('Push/Pull/Legs')) return ['Push', 'Pull', 'Legs'];
    if (pref.contains('ABCDE')) return ['A', 'B', 'C', 'D', 'E'];
    return ['Treino'];
  }

  List<int> _trainingIndices(int n) {
    n = n.clamp(1, 7);
    if (n >= 7) return List.generate(7, (i) => i);
    return {
          for (int i = 0; i < n; i++) (i * 7 / n).round() % 7,
        }.toList()
        ..sort();
  }

  String _formatDate(DateTime d) {
    const months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez'
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  // ── data ──────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    try {
      final uid = getIt<GetCurrentUser>()()?.id;
      if (uid == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final configFuture = getIt<GetWeeklyPlanConfig>()();
      final subscriptionFuture =
          getIt<subUc.GetCurrentSubscription>()().then((r) => r.valueOrNull);

      final config =
          (await configFuture).valueOrNull ?? const WeeklyPlanConfig();
      final subscription = await subscriptionFuture;
      final isPro = subscription != null &&
          (subscription.status == 'active' ||
              subscription.status == 'trialing');

      final splitPref = config.splitPreference;
      final freqDays = config.frequencyDays;

      // Prefer explicit rest_days stored by the user; else even distribution
      final restDaysRaw = config.restDays;
      final labels = _splitLabels(splitPref);
      final indices = restDaysRaw.isNotEmpty
          ? _trainingFromRestDays(restDaysRaw)
          : _trainingIndices(freqDays);
      final effectiveFreq = indices.length;

      final now = DateTime.now();
      final weekStart = _monday(now);
      final weekEnd = weekStart.add(const Duration(days: 7));

      // ── Treinos concluídos na semana (pessoais + BLDR Club) ───────────────
      // F2: XP por dia + F3: atividades extras — carregados em paralelo
      final weekResultFuture = getIt<GetWeekCompletedWorkouts>()(weekStart, weekEnd);
      final extraResultFuture = getIt<GetExtraActivities>()(weekStart, weekEnd);
      final weeklyPlanFuture = getIt<GetWeeklyPlan>()();
      final xpFutures = List.generate(7, (i) {
        final dayStart = weekStart.add(Duration(days: i));
        final dayEnd = dayStart.add(const Duration(days: 1));
        return _fetchDayXp(uid, dayStart, dayEnd);
      });

      final weekResult = await weekResultFuture;
      final extraResult = await extraResultFuture;
      final xpByDay = await Future.wait(xpFutures);
      final weeklyPlanResult = await weeklyPlanFuture;

      // Mapeia template atribuído por diaSemana (1=Seg…7=Dom → 0-indexed: -1)
      final assignedByWeekday = <int, ({String id, String name, String? source})>{};
      for (final d in weeklyPlanResult.valueOrNull ?? <domain.PlanDay>[]) {
        final id = d.treino?.id;
        final name = d.treino?.name;
        if (id != null && name != null && name.isNotEmpty) {
          // diaSemana (1=Seg) → weekdayIndex (0=Seg)
          assignedByWeekday[d.diaSemana - 1] = (id: id, name: name, source: d.treino?.source);
        }
      }

      final week = weekResult.valueOrNull ?? const WeekCompletedWorkouts();
      final extras = extraResult.valueOrNull ?? <ExtraActivity>[];

      // Mapeia atividades extras por dia da semana (0=Seg)
      final Map<int, ExtraActivity> extraByDay = {};
      for (final ex in extras) {
        final idx = ex.date.weekday - 1;
        extraByDay.putIfAbsent(idx, () => ex);
      }

      final Map<int, WorkoutSession> completedByDay = {};
      for (final w in week.personal) {
        if (w.completedAt != null && w.startedAt != null) {
          final idx = w.startedAt!.toLocal().weekday - 1;
          completedByDay.putIfAbsent(idx, () => w);
        }
      }

      // F1: club notes → activityType (notes guarda o tipo conforme
      //     club_workouts_service.dart:720; dívida: criar coluna própria)
      final Map<int, String> clubWorkoutIdByDay = {};
      final Map<int, String?> clubWorkoutNotesByDay = {};
      for (final w in week.club) {
        if (w.completedAt != null && w.startedAt != null && w.id != null) {
          final idx = w.startedAt!.toLocal().weekday - 1;
          clubWorkoutIdByDay.putIfAbsent(idx, () => w.id!);
          clubWorkoutNotesByDay.putIfAbsent(idx, () => w.notes);
        }
      }

      const abbrevs = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
      final todayIdx = now.weekday - 1;
      final List<PlanDay> days = [];

      for (int i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        final isTraining = indices.contains(i);
        final labelIdx = indices.indexOf(i);

        DayStatus status;
        String? wId;
        String? clubWId;
        WorkoutSession? completedW;
        ActivityType? actType;
        ExtraActivity? extra;

        if (!isTraining) {
          status = DayStatus.rest;
          extra = extraByDay[i];
        } else if (completedByDay.containsKey(i)) {
          status = DayStatus.done;
          wId = completedByDay[i]!.id;
          completedW = completedByDay[i];
          // F1: workoutType do treino pessoal
          actType = ActivityType.fromString(completedW?.workoutType);
        } else if (clubWorkoutIdByDay.containsKey(i)) {
          status = DayStatus.done;
          clubWId = clubWorkoutIdByDay[i];
          // F1: activityType vem de notes (dívida técnica: club_user_workouts
          //     usa notes como veículo de activityType — criar coluna própria)
          actType = ActivityType.fromString(clubWorkoutNotesByDay[i]);
        } else if (i == todayIdx) {
          status = DayStatus.today;
          extra = extraByDay[i];
        } else if (i < todayIdx) {
          status = DayStatus.lost;
          extra = extraByDay[i];
        } else {
          status = DayStatus.pending;
          extra = extraByDay[i];
        }

        final sec = completedW?.totalDurationSeconds;
        final durMin = sec != null && sec > 0 ? sec ~/ 60 : null;

        final assigned = assignedByWeekday[i];
        days.add(PlanDay(
          weekdayIndex: i,
          abbrev: abbrevs[i],
          date: date,
          status: status,
          workoutLabel: assigned?.name ??
              (isTraining && labelIdx >= 0
                  ? labels[labelIdx % labels.length]
                  : null),
          workoutId: wId,
          clubWorkoutId: clubWId,
          completedWorkout: completedW,
          activityType: actType,
          xpDay: xpByDay[i] > 0 ? xpByDay[i] : null,
          durationMinutes: durMin,
          extraActivity: extra,
          assignedTemplateId: assigned?.id,
          assignedTemplateName: assigned?.name,
          assignedTemplateSource: assigned?.source,
        ));
      }

      final doneDays = days.where((d) => d.status == DayStatus.done).length;
      int streak = 0;
      for (int i = todayIdx; i >= 0; i--) {
        if (days[i].status == DayStatus.done) {
          streak++;
        } else if (days[i].status == DayStatus.lost) {
          break;
        }
      }

      if (mounted) {
        setState(() {
          _days = days;
          _splitLabel =
              '${_splitChipLabel(splitPref)} — ${effectiveFreq}x/semana';
          _freqDays = freqDays;
          _restDays = restDaysRaw;
          _weekRange =
              '${_formatDate(weekStart)} – ${_formatDate(weekStart.add(const Duration(days: 6)))}';
          _doneDays = doneDays;
          _streak = streak;
          _trainingDays = indices.length;
          _isPro = isPro;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  Future<int> _fetchDayXp(String uid, DateTime dayStart, DateTime dayEnd) async {
    try {
      final rows = await supabase.Supabase.instance.client
          .schema('bldr_club')
          .from('xp_events')
          .select('delta')
          .eq('user_id', uid)
          .gte('created_at', dayStart.toUtc().toIso8601String())
          .lt('created_at', dayEnd.toUtc().toIso8601String());
      int total = 0;
      for (final r in (rows as List)) {
        total += ((r['delta'] as num?) ?? 0).toInt();
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  // ── bottom sheets ─────────────────────────────────────────────────────────

  /// Músculos-alvo do treino concluído (ExerciseDB + biblioteca interna) —
  /// a estratégia de merge/fallback vive no WeeklyPlanRepository.
  Future<List<String>> _fetchWorkoutMuscles(String workoutId) async {
    final result = await getIt<GetWorkoutMuscles>()(workoutId);
    return result.valueOrNull ?? [];
  }

  void _showDoneSheet(PlanDay day) {
    final isClubOnly = day.workoutId == null && day.clubWorkoutId != null;
    final w = day.completedWorkout;
    final durationSec = w?.totalDurationSeconds ?? 0;
    final durationMin = durationSec ~/ 60;
    final tplName = isClubOnly
        ? (day.workoutLabel ?? 'Treino Club')
        : (w?.templateName ?? day.workoutLabel ?? 'Treino');

    // Load muscles asynchronously (only for personal workouts)
    final musclesNotifier = ValueNotifier<List<String>?>(null);
    if (day.workoutId != null) {
      _fetchWorkoutMuscles(day.workoutId!).then((m) {
        musclesNotifier.value = m;
      });
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: BldrColors.sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              Row(children: [
                const Icon(Icons.check_circle_rounded,
                    color: BldrColors.goldBright, size: 18),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(sheetCtx).plan_workout_done, style: BldrText.cardTitleLg),
                if (isClubOnly) ...[
                  const SizedBox(width: 8),
                  const BldrBadge(label: 'CLUB'),
                ],
              ]),
              const SizedBox(height: 4),
              Text('${day.abbrev} · $tplName', style: BldrText.meta),
              const SizedBox(height: 16),
              if (!isClubOnly)
                _summaryChip(Icons.timer_outlined, '$durationMin min'),
              if (!isClubOnly) const SizedBox(height: 16),
              // ── Muscle visualizer (apenas treino pessoal) ────────────────
              if (day.workoutId != null)
                ValueListenableBuilder<List<String>?>(
                  valueListenable: musclesNotifier,
                  builder: (_, muscles, __) {
                    if (muscles == null) {
                      return Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.12)),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: BldrColors.goldBright, strokeWidth: 2),
                        ),
                      );
                    }
                    if (muscles.isEmpty) return const SizedBox();
                    return MuscleVisualizerWidget(
                      targetMuscles: muscles,
                      secondaryMuscles: const [],
                      isPro: _isPro,
                      size: VisualizerSize.full,
                      mode: VisualizerMode.highlight,
                      paywallMessage:
                          AppLocalizations.of(sheetCtx).plan_paywall_muscle_message,
                      paywallButtonLabel: AppLocalizations.of(sheetCtx).plan_paywall_muscle_btn,
                      onUpgradeTap: () {
                        Navigator.pop(sheetCtx);
                        Navigator.pushNamed(
                            context, AppRoutes.checkoutScreen);
                      },
                    );
                  },
                ),
              const SizedBox(height: 8),

              // ── Delete record button ─────────────────────────────────────
              if (day.workoutId != null || day.clubWorkoutId != null)
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.delete_outline,
                        color: BldrColors.danger, size: 16),
                    label: Text(AppLocalizations.of(sheetCtx).plan_delete_record_btn,
                        style: const TextStyle(color: BldrColors.danger, fontSize: 13)),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: BldrColors.sheetBg,
                          title: Text(AppLocalizations.of(context).plan_delete_record_title,
                              style: const TextStyle(color: Colors.white)),
                          content: Text(
                            AppLocalizations.of(context).plan_delete_record_body,
                            style: BldrText.description,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(AppLocalizations.of(context).common_cancel,
                                  style: BldrText.description),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(AppLocalizations.of(context).common_delete,
                                  style: const TextStyle(color: BldrColors.danger)),
                            ),
                          ],
                        ),
                      );
                      if (confirm != true || !mounted) return;
                      try {
                        final result = day.workoutId != null
                            // Treino pessoal
                            ? await getIt<DeleteCompletedWorkout>()(
                                day.workoutId!)
                            // Treino BLDR Club
                            : await getIt<DeleteCompletedClubWorkout>()(
                                day.clubWorkoutId!);
                        final failure = result.failureOrNull;
                        if (failure != null) {
                          throw Exception(failure.message);
                        }
                        if (mounted) {
                          Navigator.of(context).pop();
                          setState(() => _loading = true);
                          _load();
                        }
                      } catch (_) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context).plan_delete_record_error),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// P1 — dia passado sem registro. Tom neutro: "não feito" informa, não
  /// repreende. Sem vermelho, sem julgamento.
  void _showNotDoneSheet(PlanDay day) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BldrColors.sheetBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              Row(children: [
                Icon(Icons.circle_outlined,
                    color: BldrColors.textSecondary, size: 18),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(ctx).plan_workout_not_done, style: BldrText.cardTitleLg),
              ]),
              const SizedBox(height: 4),
              Text('${day.abbrev} · ${day.workoutLabel ?? "Treino"}',
                  style: BldrText.meta),
              const SizedBox(height: 16),
              BldrPrimaryButton(
                label: AppLocalizations.of(ctx).plan_do_now_btn,
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// P4 — treino de hoje ainda não feito ("próximo treino"). O botão "Ver
  /// treino" do card abre este sheet; a ação final é a mesma navegação já
  /// usada em `_showNotDoneSheet` (voltar para a tela de treinos, de onde o
  /// usuário inicia o treino) — nenhuma rota nova.
  void _showTodaySheet(PlanDay day) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BldrColors.sheetBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              Row(children: [
                const Icon(Icons.bolt_rounded,
                    color: BldrColors.goldBright, size: 18),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(ctx).plan_today_sheet_title, style: BldrText.cardTitleLg),
              ]),
              const SizedBox(height: 4),
              Text('${day.abbrev} · ${day.workoutLabel ?? "Treino"}',
                  style: BldrText.meta),
              const SizedBox(height: 16),
              BldrPrimaryButton(
                label: AppLocalizations.of(ctx).plan_do_now_btn,
                icon: Icons.play_arrow_rounded,
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── template picker ───────────────────────────────────────────────────────

  Future<void> _showTemplatePicker(PlanDay day) async {
    final result = await getIt<GetWorkoutTemplates>()();
    final allTemplates = result.valueOrNull ?? const [];
    if (!mounted) return;

    // Separar em 3 seções
    final havokTemplates = allTemplates.where((t) => t.source == 'havok').toList();
    final bldrTemplates = allTemplates.where((t) => t.isPublic && t.source != 'havok').toList();
    final userTemplates = allTemplates.where((t) => !t.isPublic && t.source != 'havok').toList();

    const weekDayNames = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
    final dayName = weekDayNames[day.weekdayIndex];
    String? selectedId = day.assignedTemplateId;

    await showModalBottomSheet(
      context: context,
      backgroundColor: BldrColors.sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Widget templateTile(WorkoutTemplate tpl) {
            final isSelected = tpl.id == selectedId;
            final count = tpl.exercises.length;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(tpl.name,
                  style: BldrText.body.copyWith(
                      color: isSelected ? BldrColors.goldBright : BldrColors.textPrimary)),
              subtitle: count > 0
                  ? Text('$count exercício${count == 1 ? '' : 's'}', style: BldrText.meta)
                  : null,
              trailing: isSelected
                  ? const Icon(Icons.check_circle_rounded,
                      color: BldrColors.goldBright, size: 20)
                  : null,
              onTap: () => setSheet(() => selectedId = tpl.id),
            );
          }

          Widget sectionHeader(String label) => Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 4),
                child: Text(label,
                    style: BldrText.label.copyWith(color: BldrColors.textMuted)),
              );

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 16),
                  Text('Escolher treino para $dayName', style: BldrText.cardTitleLg),
                  const SizedBox(height: 4),
                  Text('Selecione um treino ou defina como descanso.', style: BldrText.meta),
                  const SizedBox(height: 4),
                  if (allTemplates.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Nenhum treino criado ainda.\nCrie fichas na tela de Treinos ou peça ao HAVOK.',
                        style: BldrText.description,
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(ctx).size.height * 0.50),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (havokTemplates.isNotEmpty) ...[
                              sectionHeader('🤖  Gerados pelo HAVOK'),
                              const Divider(color: BldrColors.borderSubtle, height: 1),
                              ...havokTemplates.map(templateTile),
                            ],
                            if (bldrTemplates.isNotEmpty) ...[
                              sectionHeader('📚  Biblioteca BLDR'),
                              const Divider(color: BldrColors.borderSubtle, height: 1),
                              ...bldrTemplates.map(templateTile),
                            ],
                            if (userTemplates.isNotEmpty) ...[
                              sectionHeader('👤  Meus treinos'),
                              const Divider(color: BldrColors.borderSubtle, height: 1),
                              ...userTemplates.map(templateTile),
                            ],
                          ],
                        ),
                      ),
                    ),
                  const Divider(color: BldrColors.borderSubtle, height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Definir como descanso',
                        style: BldrText.body.copyWith(
                            color: selectedId == null
                                ? BldrColors.goldBright
                                : BldrColors.textSecondary)),
                    trailing: selectedId == null
                        ? const Icon(Icons.check_circle_rounded,
                            color: BldrColors.goldBright, size: 20)
                        : null,
                    onTap: () => setSheet(() => selectedId = null),
                  ),
                  const SizedBox(height: 12),
                  BldrPrimaryButton(
                    label: 'Confirmar',
                    onPressed: () async {
                      final picked = selectedId != null
                          ? allTemplates.where((t) => t.id == selectedId).firstOrNull
                          : null;
                      Navigator.pop(ctx);
                      await _applyTemplateToDay(
                        day.weekdayIndex + 1,
                        selectedId,
                        picked,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _applyTemplateToDay(
      int diaSemana, String? templateId, WorkoutTemplate? template) async {
    final result = await getIt<UpdatePlanDay>()(
      diaSemana,
      template: templateId != null ? template : null,
    );
    final failure = result.failureOrNull;
    if (failure != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao salvar: ${failure.message}'),
        backgroundColor: BldrColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      unawaited(WidgetDataService.updateAll());
    }
    if (mounted) {
      setState(() => _loading = true);
      _load();
    }
  }

  // ── iniciar treino do plano ────────────────────────────────────────────────

  Future<void> _startWorkoutFromPlan(PlanDay day) async {
    final templateId = day.assignedTemplateId;
    final name = day.assignedTemplateName ?? 'Treino';
    if (templateId == null) {
      _showTodaySheet(day);
      return;
    }

    final startResult = await getIt<StartWorkout>()(
      name: name,
      templateId: templateId,
    );
    final session = startResult.valueOrNull;
    if (session?.id == null || !mounted) {
      final failure = startResult.failureOrNull;
      if (failure != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(failure.message),
          backgroundColor: BldrColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ActiveWorkoutScreen(
            workoutId: session!.id!,
            workoutName: name,
          ),
        ),
      );
    }
  }

  void _showEditPlanSheet() {
    const splitOptions = [
      'Full Body',
      'Upper/Lower',
      'Push/Pull/Legs',
      'ABCDE',
      'Deixe a HAVOK decidir',
    ];
    // Derive initial selected split from current label
    String selectedSplit = _splitLabel.split(' —').first.trim();

    // Initial rest days: use stored, or infer from freq
    final List<int> selectedRestDays = _restDays.isNotEmpty
        ? List<int>.from(_restDays)
        : List.generate(7, (i) => i)
            .where((i) => !_trainingIndices(_freqDays).contains(i))
            .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BldrColors.sheetBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final trainingCount = 7 - selectedRestDays.length;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(ctx).plan_edit_sheet_title, style: BldrText.cardTitleLg),

                  // ── Split ────────────────────────────────────────────────
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(ctx).plan_split_section, style: BldrText.label),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: splitOptions.map((opt) {
                      final sel = opt == selectedSplit ||
                          opt.contains(selectedSplit) ||
                          selectedSplit.contains(opt.split(' ').first);
                      return GestureDetector(
                        onTap: () => setSheet(() => selectedSplit = opt),
                        child: BldrChip(label: opt, active: sel),
                      );
                    }).toList(),
                  ),

                  // ── Days ─────────────────────────────────────────────────
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(ctx).plan_days_section, style: BldrText.label),
                      Text(
                          AppLocalizations.of(ctx).plan_training_rest_summary(trainingCount, selectedRestDays.length),
                          style: BldrText.meta),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final isRest = selectedRestDays.contains(i);
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: GestureDetector(
                            onTap: () {
                              setSheet(() {
                                if (isRest) {
                                  selectedRestDays.remove(i);
                                } else if (trainingCount > 1) {
                                  selectedRestDays.add(i);
                                  selectedRestDays.sort();
                                }
                              });
                            },
                            child: BldrDaySquare(
                              state: isRest
                                  ? BldrDayState.rest
                                  : BldrDayState.done,
                              icon: isRest
                                  ? null
                                  : Icons.fitness_center_rounded,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Text(AppLocalizations.of(ctx).plan_days_toggle_hint,
                      style: BldrText.metaSm),

                  // ── Save ─────────────────────────────────────────────────
                  const SizedBox(height: 20),
                  BldrPrimaryButton(
                    label: AppLocalizations.of(ctx).plan_save_btn,
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _savePlanChanges(selectedSplit, selectedRestDays);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _savePlanChanges(String split, List<int> restDays) async {
    if (getIt<GetCurrentUser>()() == null) return;

    const splitPrefMap = {
      'Full Body': 'Full Body (Corpo Inteiro)',
      'Upper/Lower': 'Upper/Lower (Superior/Inferior)',
      'Push/Pull/Legs': 'Push/Pull/Legs (Empurrar/Puxar/Pernas)',
      'ABCDE': 'ABCDE',
      'Deixe a HAVOK decidir': 'Deixe a HAVOK decidir',
    };
    final splitPref = splitPrefMap[split] ?? split;

    try {
      // O repository lê o onboarding_data atual e só altera split/rest_days.
      final result = await getIt<SaveWeeklyPlanConfig>()(
        splitPreference: splitPref,
        restDays: restDays,
      );
      final failure = result.failureOrNull;
      if (failure != null) throw Exception(failure.message);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).plan_save_success),
          backgroundColor: BldrColors.goldSolid,
          behavior: SnackBarBehavior.floating,
        ));
        setState(() => _loading = true);
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).plan_save_error(e.toString())),
          backgroundColor: BldrColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _showProUpsellSheet() {
    final l10nPro = AppLocalizations.of(context);
    final features = [
      l10nPro.plan_pro_feature_1,
      l10nPro.plan_pro_feature_2,
      l10nPro.plan_pro_feature_3,
      l10nPro.plan_pro_feature_4,
      l10nPro.plan_pro_feature_5,
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: BldrColors.sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetHandle(),
              const SizedBox(height: 16),
              const BldrBadge(label: 'PRO'),
              const SizedBox(height: 12),
              Text(AppLocalizations.of(context).plan_pro_title,
                  style: BldrText.screenTitle, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(AppLocalizations.of(context).plan_pro_subtitle,
                  style: BldrText.description, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      const Icon(Icons.check_circle_outline,
                          color: BldrColors.goldBright, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(f, style: BldrText.body)),
                    ]),
                  )),
              const SizedBox(height: 16),
              BldrPrimaryButton(
                label: AppLocalizations.of(context).plan_see_plans_btn,
                onPressed: () {
                  Navigator.pop(context);
                  // TODO: navigate to checkout/paywall
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetHandle() => Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: BldrColors.textMuted,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _summaryChip(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: BldrColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: BldrColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: BldrColors.goldBright, size: 15),
            const SizedBox(width: 6),
            Text(text,
                style: BldrText.meta.copyWith(
                    color: BldrColors.textPrimary, fontWeight: FontWeight.w500)),
          ],
        ),
      );

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BldrColors.bgBase,
      body: BldrBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: BldrColors.goldBright))
                    : RefreshIndicator(
                        color: BldrColors.goldBright,
                        backgroundColor: BldrColors.surface,
                        onRefresh: _load,
                        child: CustomScrollView(
                          physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics()),
                          slivers: [
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: BldrSpacing.pageX),
                              sliver: SliverToBoxAdapter(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 16),
                                    _buildSplitChip(),
                                    const SizedBox(height: 16),
                                    _buildSummaryBlock(),
                                    const SizedBox(height: 20),
                                    _buildTimeline(),
                                    const SizedBox(height: 16),
                                    _buildFooterButtons(),
                                    const SizedBox(height: 32),
                                  ],
                                ),
                              ),
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

  // ── header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BldrSpacing.pageX, 12, BldrSpacing.pageX, 12),
      child: Row(
        children: [
          BldrCircleButton(
            icon: Icons.chevron_left,
            size: 38,
            filled: false,
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppLocalizations.of(context).plan_title, style: BldrText.cardTitleLg),
                    if (widget.isClub) ...[
                      const SizedBox(width: 7),
                      const BldrBadge(label: 'CLUB'),
                    ],
                  ],
                ),
                Text(_weekRange, style: BldrText.meta),
              ],
            ),
          ),
          HavokEntryIcon(onTap: () => showHavokSheet(context, originScreen: 'weekly_plan')),
        ],
      ),
    );
  }

  // ── split chip ────────────────────────────────────────────────────────────

  Widget _buildSplitChip() {
    return Row(
      children: [
        BldrChip(label: _splitLabel),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: _isPro ? _showEditPlanSheet : _showProUpsellSheet,
          behavior: HitTestBehavior.opaque,
          child: Text(AppLocalizations.of(context).plan_change_btn, style: BldrText.buttonSecondary),
        ),
      ],
    );
  }

  // ── summary block ─────────────────────────────────────────────────────────

  Widget _buildSummaryBlock() {
    final restantes = _trainingDays - _doneDays;
    return BldrGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: '$_doneDays',
              style: BldrText.kpiLg,
              children: [
                TextSpan(text: ' ${AppLocalizations.of(context).plan_of_total_workouts(_trainingDays)}', style: BldrText.body),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(AppLocalizations.of(context).plan_remaining(restantes), style: BldrText.meta),
          const SizedBox(height: 15),
          // P2 — barra segmentada só em dourado: preenchido = feito,
          // resto (não feito, hoje, futuro, descanso) = neutro uniforme.
          Row(
            children: _days.map((d) {
              final filled = d.status == DayStatus.done;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 4,
                  decoration: BoxDecoration(
                    color: filled
                        ? BldrColors.goldBright
                        : const Color(0x17FFFFFF), // rgba(255,255,255,0.09)
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: BldrColors.borderSubtle)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _statItem('$_streak',
                      _streak == 1 ? AppLocalizations.of(context).plan_streak_singular : AppLocalizations.of(context).plan_streak_plural),
                ),
                Expanded(
                  child: _statItem(
                    '${_days.fold<int>(0, (sum, d) => sum + (d.xpDay ?? 0))}',
                    AppLocalizations.of(context).plan_xp_week,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: BldrText.kpiSm),
          Text(label, style: BldrText.meta),
        ],
      );

  // ── timeline (P3/P4/P5) ──────────────────────────────────────────────────

  Widget _buildTimeline() {
    return Column(
      children: List.generate(_days.length, (i) {
        final day = _days[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BldrTimelineItem(
            dotStyle: switch (day.status) {
              DayStatus.done => BldrTimelineDotStyle.done,
              DayStatus.today => BldrTimelineDotStyle.next,
              DayStatus.rest => BldrTimelineDotStyle.rest,
              DayStatus.pending || DayStatus.lost => BldrTimelineDotStyle.pending,
            },
            isFirst: i == 0,
            isLast: i == _days.length - 1,
            child: _buildDayCard(day),
          ),
        );
      }),
    );
  }

  Widget _buildDayCard(PlanDay day) {
    switch (day.status) {
      case DayStatus.rest:
        return _buildRestCard(day);
      case DayStatus.today:
        return _buildTodayCard(day);
      case DayStatus.done:
        return _buildDoneCard(day);
      case DayStatus.pending:
        return _buildPendingCard(day, isLost: false);
      case DayStatus.lost:
        return _buildPendingCard(day, isLost: true);
    }
  }

  String _dateLabel(PlanDay day) => '${day.abbrev} · ${day.date.day}/${day.date.month}';

  /// P4 — próximo treino destacado: tint dourado + halo na bolinha (no
  /// BldrTimelineItem) + botão "Ver treino" dentro do card.
  Widget _buildTodayCard(PlanDay day) {
    final hasTemplate = day.assignedTemplateId != null;
    final isHavok = day.assignedTemplateSource == 'havok';
    return BldrGlassCard(
      background: BldrColors.goldTintStrong,
      borderColor: BldrColors.goldBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(_dateLabel(day), style: BldrText.label),
                        if (isHavok) ...[
                          const SizedBox(width: 6),
                          _HavokBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(day.workoutLabel ?? 'Treino', style: BldrText.cardTitleLg),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _showTemplatePicker(day),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: BldrColors.goldTintChip,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: BldrColors.goldBorderChip),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.swap_horiz_rounded,
                          color: BldrColors.goldBright, size: 14),
                      const SizedBox(width: 4),
                      Text('Trocar',
                          style: BldrText.metaSm
                              .copyWith(color: BldrColors.goldBright)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasTemplate)
            BldrPrimaryButton(
              label: 'Iniciar treino',
              icon: Icons.play_arrow_rounded,
              onPressed: () => _startWorkoutFromPlan(day),
            )
          else
            BldrSecondaryButton(
              label: AppLocalizations.of(context).plan_next_workout,
              icon: Icons.play_arrow_rounded,
              onPressed: () => _showTodaySheet(day),
            ),
        ],
      ),
    );
  }

  /// P3/F1/F2 — dia feito: ícone do ActivityType (só no Club), métrica e XP.
  Widget _buildDoneCard(PlanDay day) {
    final actType = day.activityType ?? ActivityType.musculacao;
    final metricLabel = actType.metricLabel(day.durationMinutes, null);
    final showMetric = day.durationMinutes != null && day.durationMinutes! > 0;

    return BldrGlassCard(
      onTap: () => _showDoneSheet(day),
      child: Row(
        children: [
          if (widget.isClub) ...[
            Icon(actType.icon, color: BldrColors.goldBright, size: 18),
            const SizedBox(width: 10),
          ] else ...[
            Icon(Icons.check_circle_rounded, color: BldrColors.goldBright, size: 18),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_dateLabel(day), style: BldrText.label),
                const SizedBox(height: 2),
                Text(day.workoutLabel ?? 'Treino', style: BldrText.cardTitle),
                if (showMetric || day.xpDay != null)
                  const SizedBox(height: 3),
                if (showMetric || day.xpDay != null)
                  Row(
                    children: [
                      if (showMetric)
                        Text(metricLabel,
                            style: BldrText.metaSm.copyWith(
                                color: BldrColors.textMuted, fontSize: 9)),
                      if (showMetric && day.xpDay != null)
                        const SizedBox(width: 8),
                      if (day.xpDay != null)
                        Text(AppLocalizations.of(context).plan_xp_earned(day.xpDay!),
                            style: BldrText.metaSm.copyWith(
                                color: BldrColors.goldBright,
                                fontSize: 9,
                                fontWeight: FontWeight.w600)),
                    ],
                  ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded,
              color: BldrColors.goldBright, size: 20),
        ],
      ),
    );
  }

  /// P1/P3 — dia não feito (passado) ou futuro ainda não devido: tom
  /// neutro, sem vermelho. Card em surfaceInset + borda sutil.
  /// `isLost` (passado, sem registro) reduz opacidade e mostra o badge
  /// "Não feito"; dia futuro fica normal, sem badge (ainda não foi perdido).
  Widget _buildPendingCard(PlanDay day, {required bool isLost}) {
    final isHavok = day.assignedTemplateSource == 'havok';
    final card = BldrGlassCard(
      background: BldrColors.surfaceInset,
      borderColor: BldrColors.borderSubtle,
      onTap: isLost ? () => _showNotDoneSheet(day) : null,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_dateLabel(day), style: BldrText.label),
                    if (isHavok) ...[
                      const SizedBox(width: 6),
                      _HavokBadge(),
                    ],
                    if (isLost) ...[
                      const SizedBox(width: 8),
                      BldrBadge(label: AppLocalizations.of(context).plan_not_done, gold: false),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(day.workoutLabel ?? 'Treino',
                    style: BldrText.cardTitle
                        .copyWith(color: BldrColors.textSecondary)),
              ],
            ),
          ),
          if (!isLost)
            GestureDetector(
              onTap: () => _showTemplatePicker(day),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: BldrColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: BldrColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.swap_horiz_rounded,
                        color: BldrColors.textMuted, size: 14),
                    const SizedBox(width: 4),
                    Text('Trocar',
                        style: BldrText.metaSm
                            .copyWith(color: BldrColors.textSecondary)),
                  ],
                ),
              ),
            )
          else
            Icon(Icons.chevron_right, color: BldrColors.textMuted, size: 18),
        ],
      ),
    );

    // P1 — opacidade reduzida é deliberada: informa sem repreender.
    return isLost ? Opacity(opacity: 0.6, child: card) : card;
  }

  /// P5/F3 — dia de descanso. Se houver atividade extra registrada, exibe
  /// como card normal com ícone; senão, borda tracejada + ícone de sono.
  Widget _buildRestCard(PlanDay day) {
    final ex = day.extraActivity;
    if (ex != null) {
      return _buildExtraCard(day, ex);
    }
    return BldrDashedContainer(
      radius: BldrRadius.card,
      padding: const EdgeInsets.all(BldrSpacing.padCard),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_dateLabel(day), style: BldrText.label),
                const SizedBox(height: 4),
                Text(AppLocalizations.of(context).plan_rest_day,
                    style: BldrText.cardTitle
                        .copyWith(color: BldrColors.textSecondary)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showTemplatePicker(day),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: BldrColors.goldTintChip,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: BldrColors.goldBorderChip),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded,
                      color: BldrColors.goldBright, size: 14),
                  const SizedBox(width: 4),
                  Text('Adicionar',
                      style: BldrText.metaSm
                          .copyWith(color: BldrColors.goldBright)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// F3 — card de atividade extra registrada num dia de descanso/outro.
  Widget _buildExtraCard(PlanDay day, ExtraActivity ex) {
    return BldrGlassCard(
      child: Row(
        children: [
          Icon(ex.activityType.icon, color: BldrColors.goldBright, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_dateLabel(day), style: BldrText.label),
                const SizedBox(height: 2),
                Text(ex.activityType.label, style: BldrText.cardTitle),
                const SizedBox(height: 3),
                Row(children: [
                  BldrBadge(label: AppLocalizations.of(context).plan_extra_badge, gold: false),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context).plan_xp_earned(ex.xpEarned),
                      style: BldrText.metaSm.copyWith(
                          color: BldrColors.goldBright,
                          fontSize: 9,
                          fontWeight: FontWeight.w600)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── edit plan button ──────────────────────────────────────────────────────

  // T8-like — dois botões lado a lado no rodapé (mockup). "Registrar
  // extra" é [F] (CP5) — sem lógica ainda, entra desabilitado com badge
  // "Em breve", mesmo padrão já usado em Configurações.
  Widget _buildFooterButtons() {
    return Row(
      children: [
        Expanded(child: _buildEditPlanButton()),
        const SizedBox(width: 10),
        Expanded(child: _buildRegisterExtraButton()),
      ],
    );
  }

  Widget _buildEditPlanButton() {
    return GestureDetector(
      onTap: _isPro ? _showEditPlanSheet : _showProUpsellSheet,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: _isPro ? BldrColors.goldTintChip : BldrColors.surface,
          borderRadius: BldrRadius.all(BldrRadius.button),
          border: Border.all(
              color: _isPro ? BldrColors.goldBorderChip : BldrColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_outlined,
                color: _isPro ? BldrColors.goldBright : BldrColors.textSecondary,
                size: 16),
            const SizedBox(width: 7),
            Flexible(
              child: Text(AppLocalizations.of(context).plan_edit_btn,
                  overflow: TextOverflow.ellipsis,
                  style: BldrText.buttonSecondary.copyWith(
                      color: _isPro
                          ? BldrColors.goldBright
                          : BldrColors.textSecondary)),
            ),
            if (!_isPro) ...[
              const SizedBox(width: 6),
              const BldrBadge(label: 'PRO'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterExtraButton() {
    return GestureDetector(
      onTap: _showRegisterExtraSheet,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: BldrColors.surface,
          borderRadius: BldrRadius.all(BldrRadius.button),
          border: Border.all(color: BldrColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded,
                color: BldrColors.textSecondary, size: 16),
            const SizedBox(width: 7),
            Flexible(
              child: Text(AppLocalizations.of(context).plan_register_extra_btn,
                  overflow: TextOverflow.ellipsis,
                  style: BldrText.buttonSecondary
                      .copyWith(color: BldrColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  // ── F3: bottom sheet de atividade extra ──────────────────────────────────

  void _showRegisterExtraSheet() {
    ActivityType selectedType = ActivityType.musculacao;
    double selectedDuration = 30;
    final notesController = TextEditingController();
    final uid = getIt<GetCurrentUser>()()?.id;
    if (uid == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: BldrColors.sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(),
                const SizedBox(height: 16),
                Row(children: [
                  const Icon(Icons.add_circle_outline,
                      color: BldrColors.goldBright, size: 18),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(ctx).plan_extra_sheet_title, style: BldrText.cardTitleLg),
                ]),
                const SizedBox(height: 4),
                Text(AppLocalizations.of(ctx).plan_extra_sheet_subtitle, style: BldrText.meta),
                const SizedBox(height: 20),

                Text(AppLocalizations.of(ctx).plan_extra_type_label, style: BldrText.label),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ActivityType.values.map((t) {
                    final sel = t == selectedType;
                    return GestureDetector(
                      onTap: () => setSheet(() => selectedType = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? BldrColors.goldTintChip
                              : BldrColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: sel
                                  ? BldrColors.goldBorderChip
                                  : BldrColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(t.icon,
                                size: 14,
                                color: sel
                                    ? BldrColors.goldBright
                                    : BldrColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(t.label,
                                style: BldrText.metaSm.copyWith(
                                    color: sel
                                        ? BldrColors.goldBright
                                        : BldrColors.textSecondary,
                                    fontWeight: sel
                                        ? FontWeight.w600
                                        : FontWeight.normal)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocalizations.of(ctx).plan_extra_duration_label, style: BldrText.label),
                    Text('${selectedDuration.toInt()} min',
                        style: BldrText.label
                            .copyWith(color: BldrColors.goldBright)),
                  ],
                ),
                Slider(
                  value: selectedDuration,
                  min: 15,
                  max: 120,
                  divisions: 7,
                  activeColor: BldrColors.goldBright,
                  inactiveColor: BldrColors.border,
                  onChanged: (v) => setSheet(() => selectedDuration = v),
                ),

                const SizedBox(height: 8),
                Text(AppLocalizations.of(ctx).plan_extra_notes_label, style: BldrText.label),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  style: BldrText.body,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(ctx).plan_extra_notes_hint,
                    hintStyle: BldrText.meta,
                    filled: true,
                    fillColor: BldrColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: BldrColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: BldrColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: BldrColors.goldBright),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                BldrPrimaryButton(
                  label: AppLocalizations.of(ctx).plan_extra_register_btn,
                  onPressed: () async {
                    Navigator.pop(sheetCtx);
                    final result = await getIt<LogExtraActivity>()(
                      date: DateTime.now(),
                      activityType: selectedType,
                      durationMin: selectedDuration.toInt(),
                      notes: notesController.text.trim().isEmpty
                          ? null
                          : notesController.text.trim(),
                    );
                    if (mounted) {
                      if (result.failureOrNull != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text(AppLocalizations.of(context).plan_extra_register_error(result.failureOrNull!.message)),
                          backgroundColor: BldrColors.danger,
                          behavior: SnackBarBehavior.floating,
                        ));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(AppLocalizations.of(context).plan_extra_register_success),
                          backgroundColor: BldrColors.goldSolid,
                          behavior: SnackBarBehavior.floating,
                        ));
                        setState(() => _loading = true);
                        _load();
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge dourado pequeno exibido em dias/cards com template gerado pelo HAVOK.
class _HavokBadge extends StatelessWidget {
  const _HavokBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: BldrColors.goldTintChip,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: BldrColors.goldBorderChip),
      ),
      child: const Text(
        'HAVOK',
        style: TextStyle(
          color: BldrColors.goldBright,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
