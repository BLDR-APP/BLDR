import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/features/workouts/domain/usecases/week_plan_usecases.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/week_override.dart';
import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_workout_v2_components.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/plan_day_type_resolver.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/extra_activity.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

enum _DayStatus { done, today, pending, rest, lost }

class _WeekDay {
  final String abbrev;
  final int dayNumber;
  final _DayStatus status;
  final String? workoutLabel;
  final String? workoutId;
  final bool workoutCompleted;
  final ExtraActivity? extraActivity;

  const _WeekDay({
    required this.abbrev,
    required this.dayNumber,
    required this.status,
    this.workoutLabel,
    this.workoutId,
    this.workoutCompleted = false,
    this.extraActivity,
  });
}

class CurrentWeekCardWidget extends StatefulWidget {
  final VoidCallback onViewPlan;

  /// T3 — expõe o rótulo do ciclo de HOJE ("Legs", "Push"…) para o hero da
  /// tela de Treinos, sem duplicar a derivação de split/onboarding_data.
  /// `null` quando hoje é dia de descanso ou o dado ainda não carregou.
  final ValueChanged<String?>? onTodayLabel;

  const CurrentWeekCardWidget({
    Key? key,
    required this.onViewPlan,
    this.onTodayLabel,
  }) : super(key: key);

  @override
  State<CurrentWeekCardWidget> createState() => CurrentWeekCardWidgetState();
}

class CurrentWeekCardWidgetState extends State<CurrentWeekCardWidget> {
  /// Atividades extras da semana (métrica "Extras" do hub v2).
  int _extrasCount = 0;

  /// XP da semana (fonte atual: bldr_club.xp_events via GetClubXpBetween).
  /// Incompleto até a unificação de XP (BACKLOG B10).
  int? _weekXp;

  /// Allows a parent to force-reload after the user edits the plan.
  Future<void> reload() => _load();
  List<_WeekDay> _days = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  DateTime _monday(DateTime d) =>
      DateTime(d.year, d.month, d.day - (d.weekday - 1));

  List<String> _splitLabels(String pref) {
    if (pref.contains('Full Body')) return ['Full Body'];
    if (pref.contains('Upper/Lower')) return ['Upper', 'Lower'];
    if (pref.contains('Push/Pull/Legs')) return ['Push', 'Pull', 'Legs'];
    if (pref.contains('ABCDE')) return ['A', 'B', 'C', 'D', 'E'];
    return ['Treino'];
  }

  // ── data loading ──────────────────────────────────────────────────────────

  Future<void> _load() async {
    try {
      final uid = getIt<GetCurrentUser>()()?.id;
      if (uid == null) {
        if (mounted) setState(() => _loading = false);
        widget.onTodayLabel?.call(null);
        return;
      }

      final configResult = await getIt<GetWeeklyPlanConfig>()();
      final weeklyPlanResult = await getIt<GetWeekPlan>()(WeekCalendar.weekStartFor(DateTime.now()));
      final config = configResult.valueOrNull;
      final splitPref = config?.splitPreference ?? '';
      final freqDays = config?.frequencyDays ?? 3;

      // Prefer explicit rest_days; fallback to even distribution
      final restDaysRaw = config?.restDays ?? const <int>[];
      final labels = _splitLabels(splitPref);
      // Regra única do tipo do dia (mesma da WeeklyPlanScreen e da Home).
      final trainingDays = PlanDayTypeResolver.trainingDays(
        plan: weeklyPlanResult.valueOrNull ?? const [],
        restDays: restDaysRaw,
        frequencyDays: freqDays,
      );
      final indices = PlanDayTypeResolver.trainingIndices(trainingDays);
      // This-week's workouts
      final now = DateTime.now();
      final weekStart = _monday(now);
      final weekEnd = weekStart.add(const Duration(days: 7));

      // Histórico consolidado (user_workouts + club_user_workouts) — um
      // treino do Club também conta como "feito" nesta semana.
      final historyResult =
          await getIt<GetConsolidatedWorkoutHistory>()(userId: uid, limit: 50);
      final sessions = historyResult.valueOrNull ?? [];
      final extrasResult =
          await getIt<GetExtraActivities>()(weekStart, weekEnd);
      final extras = extrasResult.valueOrNull ?? const <ExtraActivity>[];
      final weekXp =
          (await getIt<GetClubXpBetween>()(weekStart, weekEnd)).valueOrNull;

      // Build map: dayIndex (0=Mon) → sessão concluída
      final Map<int, WorkoutSession> completedByDay = {};
      for (final s in sessions) {
        final startedAt = s.startedAt;
        if (s.completedAt != null && startedAt != null) {
          final dt = startedAt.toLocal();
          if (!dt.isBefore(weekStart) && dt.isBefore(weekEnd)) {
            final idx = dt.weekday - 1; // 0=Mon … 6=Sun
            completedByDay[idx] = s;
          }
        }
      }

      // A atividade extra não substitui o treino concluído: ela só é usada
      // para o check quando não há workout completion naquele dia.
      final Map<int, ExtraActivity> extraByDay = {};
      for (final extra in extras) {
        extraByDay.putIfAbsent(extra.date.weekday - 1, () => extra);
      }

      const abbrevs = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
      final todayIdx = now.weekday - 1;
      final assignedByIndex = {
        for (final day in weeklyPlanResult.valueOrNull ?? const [])
          if (day.treino != null && !day.isRestDay)
            day.diaSemana - 1: day.treino!,
      };

      final List<_WeekDay> days = [];
      for (int i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        final assigned = assignedByIndex[i];
        final isTraining = trainingDays[i];
        final labelIdx = indices.indexOf(i);

        _DayStatus status;
        String? wId;

        if (!isTraining) {
          status = _DayStatus.rest;
        } else if (completedByDay.containsKey(i)) {
          status = _DayStatus.done;
          wId = completedByDay[i]!.id as String?;
        } else if (i == todayIdx) {
          status = _DayStatus.today;
        } else if (i < todayIdx) {
          status = _DayStatus.lost;
        } else {
          status = _DayStatus.pending;
        }

        days.add(_WeekDay(
          abbrev: abbrevs[i],
          dayNumber: date.day,
          status: status,
          workoutLabel: assigned?.name ??
              (isTraining && labelIdx >= 0
                  ? labels[labelIdx % labels.length]
                  : null),
          workoutId: wId,
          workoutCompleted: completedByDay.containsKey(i),
          extraActivity: extraByDay[i],
        ));
      }

      if (mounted) {
        setState(() {
          _days = days;
          _extrasCount = extras.length;
          _weekXp = weekXp;
          _loading = false;
        });
      }
      widget.onTodayLabel?.call(days[todayIdx].workoutLabel);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
      widget.onTodayLabel?.call(null);
    }
  }

  // ── bottom sheet ──────────────────────────────────────────────────────────

  void _showDaySheet(_WeekDay day) {
    final l10n = AppLocalizations.of(context);
    final isWorkoutDone = day.workoutCompleted;
    final extra = day.extraActivity;
    final isExtraDone = !isWorkoutDone && extra != null;
    final isRest = day.status == _DayStatus.rest && !isExtraDone;
    final icon = isWorkoutDone
        ? TablerIcons.barbell
        : isExtraDone
            ? TablerIcons.check
            : isRest
                ? TablerIcons.barbell_off
                : TablerIcons.circle;
    final title = isWorkoutDone
        ? l10n.plan_workout_done
        : isExtraDone
            ? l10n.wk_extra_done_title
            : isRest
                ? l10n.plan_rest_day
                : l10n.plan_workout_not_done;
    final body = isWorkoutDone
        ? l10n.wk_workout_done(day.workoutLabel ?? l10n.wk_workout_fallback)
        : isExtraDone
            ? l10n.wk_extra_done(extra.activityType.label)
            : isRest
                ? l10n.plan_rest_day
                : l10n.plan_no_record;
    BldrV2Sheet.show<void>(
      context,
      title: title.toUpperCase(),
      child: Builder(
        builder: (ctx) => Column(children: [
          Icon(icon,
              size: 28,
              color: isWorkoutDone || isExtraDone
                  ? BldrSheetV2Colors.border
                  : BldrSheetV2Colors.unit),
          const SizedBox(height: 12),
          Text(body,
              textAlign: TextAlign.center, style: BldrSheetV2Text.body),
          if (isWorkoutDone && extra != null) ...[
            const SizedBox(height: 6),
            Text(l10n.wk_extra_also,
                textAlign: TextAlign.center, style: BldrSheetV2Text.label),
          ],
          if (!isWorkoutDone && !isExtraDone && !isRest) ...[
            const SizedBox(height: 22),
            BldrV2SheetButton(
              label: l10n.plan_view_week_btn.toUpperCase(),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ]),
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  /// "Minha semana" v2 (Figma 249:18901 / 179:2): dias em círculos ligados
  /// por linhas douradas e métricas Treinos · Extras · XP.

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final completed = _days.where((d) => d.workoutCompleted).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.hub_week_title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BldrWorkoutTextV2.hubSection),
            ),
            GestureDetector(
              onTap: widget.onViewPlan,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.hub_week_see, style: BldrWorkoutTextV2.hubSection),
                  const SizedBox(width: 8),
                  // Seta longa e fina do mockup (vetor "Arrow 1", 23 × 3,7).
                  SvgPicture.asset('assets/images/v2/icons/week_arrow.svg',
                      width: 23.25, height: 3.68),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(
                    color: BldrColors.goldBright, strokeWidth: 2),
              ),
            ),
          )
        else
          _buildWeekRow(),
        if (!_loading) ...[
          const SizedBox(height: 18),
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _metric('$completed', l10n.hub_week_workouts),
                _divider(),
                _metric('$_extrasCount', l10n.hub_week_extras),
                _divider(),
                _metric('${_weekXp ?? 0}', l10n.hub_week_xp),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        margin: const EdgeInsets.symmetric(vertical: 2),
        color: BldrWorkoutColorsV2.secondary,
      );

  Widget _metric(String value, String label) => SizedBox(
        width: 60,
        child: Column(
          children: [
            Text(value,
                maxLines: 1,
                style: BldrWorkoutTextV2.weekValue),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BldrWorkoutTextV2.weekLabel),
          ],
        ),
      );

  BldrWeekDayState _stateOf(_WeekDay day) {
    if (day.workoutCompleted) return BldrWeekDayState.workoutDone;
    if (day.extraActivity != null) return BldrWeekDayState.extraDone;
    return switch (day.status) {
      _DayStatus.lost => BldrWeekDayState.lost,
      _DayStatus.rest => BldrWeekDayState.rest,
      _ => BldrWeekDayState.pending,
    };
  }

  /// Faixa da semana v2. "Hoje" é sempre o índice do dia atual (antes
  /// dependia do status "today", que não existe em dia concluído ou de
  /// descanso — a letra ficava branca).
  Widget _buildWeekRow() {
    final todayIdx = DateTime.now().weekday - 1; // 0 = segunda
    return BldrWeekStrip(
      letters: [for (final d in _days) d.abbrev],
      states: [for (final d in _days) _stateOf(d)],
      todayIndex: todayIdx,
      onTaps: [
        for (final d in _days)
          // Mesmos dias tocáveis de antes: feito, extra, perdido.
          (d.workoutCompleted ||
                  d.extraActivity != null ||
                  d.status == _DayStatus.lost)
              ? () => _showDaySheet(d)
              : null,
      ],
    );
  }
}
