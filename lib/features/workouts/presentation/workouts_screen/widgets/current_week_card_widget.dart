import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/design_system/bldr_workout_v2_components.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
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
      final extrasResult =
          await getIt<GetExtraActivities>()(weekStart, weekEnd);
      final extras = extrasResult.valueOrNull ?? const <ExtraActivity>[];

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
          workoutCompleted: completedByDay.containsKey(i),
          extraActivity: extraByDay[i],
        ));
      }

      if (mounted) {
        setState(() {
          _days = days;
          _extrasCount = extras.length;
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
                : Icons.circle_outlined;
    final title = isWorkoutDone
        ? AppLocalizations.of(context).plan_workout_done
        : isExtraDone
            ? 'Atividade concluída'
            : isRest
                ? AppLocalizations.of(context).plan_rest_day
                : AppLocalizations.of(context).plan_workout_not_done;
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
                    icon,
                    color: isWorkoutDone || isExtraDone
                        ? BldrColors.goldBright
                        : BldrColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: BldrText.cardTitleLg,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isWorkoutDone
                    ? '${day.workoutLabel ?? "Treino"} — concluído.'
                    : isExtraDone
                        ? '${extra.activityType.label} — concluída.'
                        : isRest
                            ? AppLocalizations.of(context).plan_rest_day
                            : AppLocalizations.of(context).plan_no_record,
                style: BldrText.description,
              ),
              if (isWorkoutDone && extra != null) ...[
                const SizedBox(height: 4),
                Text('Atividade extra também registrada.',
                    style: BldrText.meta),
              ],
              if (!isWorkoutDone && !isExtraDone && !isRest) ...[
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

  /// "Minha semana" v2 (Figma 249:18901 / 179:2): dias em círculos ligados
  /// por linhas douradas e métricas Treinos · Extras. A métrica XP fica
  /// pronta e oculta ([_showXp]) até `add_xp_to_user` gravar em xp_events.
  static const bool _showXp = false;

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
                  const SizedBox(width: 4),
                  const Icon(TablerIcons.arrow_narrow_right,
                      size: 22, color: BldrWorkoutColorsV2.goldBrand),
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
                if (_showXp) ...[
                  _divider(),
                  _metric('—', l10n.hub_week_xp),
                ],
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

  /// Letras dos dias (hoje em dourado) e círculos ligados por linhas.
  Widget _buildWeekRow() {
    return LayoutBuilder(builder: (context, c) {
      // 7 círculos de 44 + 6 ligações; em telas estreitas os círculos
      // encolhem proporcionalmente.
      final circle = ((c.maxWidth - 6 * 6) / 7).clamp(30.0, 44.0);
      return Row(
        children: [
          for (var i = 0; i < _days.length; i++) ...[
            if (i > 0)
              Expanded(
                // Linha na altura do centro do círculo (letra 12 × 1,21 +
                // 3 de espaço + metade do círculo), como no mockup.
                child: Padding(
                  padding: EdgeInsets.only(
                      top: 12 * 1.21 * MediaQuery.textScalerOf(context).scale(1) +
                          3 +
                          circle * 42 / 44 / 2),
                  child: Container(
                      height: 0.6, color: BldrWorkoutColorsV2.goldBrand),
                ),
              ),
            SizedBox(
              width: circle,
              child: Column(
                children: [
                  Text(_days[i].abbrev,
                      style: BldrWorkoutTextV2.weekDay.copyWith(
                          color: _days[i].status == _DayStatus.today
                              ? BldrWorkoutColorsV2.goldBrand
                              : null)),
                  const SizedBox(height: 3),
                  SizedBox(
                    width: circle,
                    height: circle * 42 / 44,
                    child: FittedBox(
                      child: BldrWeekDayCircle(
                        state: _stateOf(_days[i]),
                        // Mesmos dias tocáveis de antes: feito, extra, perdido.
                        onTap: (_days[i].workoutCompleted ||
                                _days[i].extraActivity != null ||
                                _days[i].status == _DayStatus.lost)
                            ? () => _showDaySheet(_days[i])
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    });
  }
}
