import 'package:flutter/material.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';
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

  const _WeekDay({
    required this.abbrev,
    required this.dayNumber,
    required this.status,
    this.workoutLabel,
    this.workoutId,
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

  // Evenly spread n training days across 7, starting from Monday (0-indexed)
  List<int> _trainingIndices(int n) {
    n = n.clamp(1, 7);
    if (n >= 7) return List.generate(7, (i) => i);
    return {
      for (int i = 0; i < n; i++) (i * 7 / n).round() % 7,
    }.toList()
      ..sort();
  }

  // Derive training indices from stored rest_days (0=Mon … 6=Sun)
  List<int> _trainingFromRestDays(List<int> restDays) =>
      List.generate(7, (i) => i).where((i) => !restDays.contains(i)).toList();

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
      final weeklyPlanResult = await getIt<GetWeeklyPlan>()();
      final config = configResult.valueOrNull;
      final splitPref = config?.splitPreference ?? '';
      final freqDays = config?.frequencyDays ?? 3;

      // Prefer explicit rest_days; fallback to even distribution
      final restDaysRaw = config?.restDays ?? const <int>[];
      final labels = _splitLabels(splitPref);
      final indices = restDaysRaw.isNotEmpty
          ? _trainingFromRestDays(restDaysRaw)
          : _trainingIndices(freqDays);
      // This-week's workouts
      final now = DateTime.now();
      final weekStart = _monday(now);
      final weekEnd = weekStart.add(const Duration(days: 7));

      // Histórico consolidado (user_workouts + club_user_workouts) — um
      // treino do Club também conta como "feito" nesta semana.
      final historyResult =
          await getIt<GetConsolidatedWorkoutHistory>()(userId: uid, limit: 50);
      final sessions = historyResult.valueOrNull ?? [];

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

      const abbrevs = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
      final todayIdx = now.weekday - 1;
      final assignedByIndex = {
        for (final day in weeklyPlanResult.valueOrNull ?? const [])
          if (day.treino != null) day.diaSemana - 1: day.treino!,
      };

      final List<_WeekDay> days = [];
      for (int i = 0; i < 7; i++) {
        final date = weekStart.add(Duration(days: i));
        final assigned = assignedByIndex[i];
        final isTraining = assigned != null || indices.contains(i);
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
        ));
      }

      if (mounted) {
        setState(() {
          _days = days;
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
    final isDone = day.status == _DayStatus.done;
    showModalBottomSheet(
      context: context,
      backgroundColor: BldrColors.sheetBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BldrColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    isDone
                        ? Icons.check_circle_outline_rounded
                        : Icons.circle_outlined,
                    color: isDone
                        ? BldrColors.goldBright
                        : BldrColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isDone
                        ? AppLocalizations.of(context).plan_workout_done
                        : AppLocalizations.of(context).plan_workout_not_done,
                    style: BldrText.cardTitleLg,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isDone
                    ? '${day.workoutLabel ?? "Treino"} — concluído.'
                    : AppLocalizations.of(context).plan_no_record,
                style: BldrText.description,
              ),
              if (!isDone) ...[
                const SizedBox(height: 16),
                BldrPrimaryButton(
                  label: AppLocalizations.of(context).plan_view_week_btn,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final completed = _days.where((d) => d.status == _DayStatus.done).length;
    final planned = _days.where((d) => d.status != _DayStatus.rest).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppLocalizations.of(context).plan_current_week,
                style: BldrText.cardTitleLg),
            GestureDetector(
              onTap: widget.onViewPlan,
              behavior: HitTestBehavior.opaque,
              child: Text(
                AppLocalizations.of(context).plan_see_plan,
                style: BldrText.buttonSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Days grid
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _days.map(_buildDayCol).toList(),
          ),
        if (!_loading && planned > 0) ...[
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: completed / planned,
              minHeight: 4,
              color: BldrColors.goldBright,
              backgroundColor: BldrColors.track,
            ),
          ),
          const SizedBox(height: 8),
          Text('$completed / $planned treinos concluídos',
              style: BldrText.metaSm.copyWith(
                  color: completed > 0
                      ? BldrColors.goldBright
                      : BldrColors.textTertiary)),
        ],
      ],
    );
  }

  Widget _buildDayCol(_WeekDay day) {
    final isToday = day.status == _DayStatus.today;
    // G4/P1 — dia perdido é neutro, mesmo tratamento visual de "futuro".
    final squareState = switch (day.status) {
      _DayStatus.done => BldrDayState.done,
      _DayStatus.today => BldrDayState.today,
      _DayStatus.rest => BldrDayState.rest,
      _DayStatus.pending || _DayStatus.lost => BldrDayState.pending,
    };
    final tappable =
        day.status == _DayStatus.done || day.status == _DayStatus.lost;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          children: [
            Text(
              day.abbrev,
              style: BldrText.metaSm.copyWith(
                color:
                    isToday ? BldrColors.goldBright : BldrColors.textTertiary,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: 6),
            BldrDaySquare(
              state: squareState,
              icon: null,
              onTap: tappable ? () => _showDaySheet(day) : null,
            ),
            const SizedBox(height: 6),
            Text(
              '${day.dayNumber}',
              style: BldrText.metaSm.copyWith(
                color:
                    isToday ? BldrColors.textPrimary : BldrColors.textTertiary,
                fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
