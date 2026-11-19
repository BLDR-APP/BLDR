import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/core/toast/bldr_toaster.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/domain/repositories/club_workout_repository.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/club_active_workout_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/havok/havok_sheet.dart';
import 'package:bldr_fitness/features/integrations/data/widget_data_service.dart';
import 'package:bldr_fitness/features/onboarding/domain/entities/onboarding_plan.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/resolve_club_access.dart';
import 'package:bldr_fitness/features/subscription/presentation/paywall/club_paywall_sheet.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/activity_type.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/plan_day_type_resolver.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/week_override.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/weekly_plan.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/week_plan_usecases.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/active_workout_screen.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/routes/app_routes.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/home_v2_formatters.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/widgets/muscle_visualizer_widget.dart';

/// Estado exibido no card do dia (Figma 282:68).
enum _DayState { today, planned, free, done, missed, inProgress }

/// Dia da semana já resolvido para a tela.
class _DayVM {
  final int dia; // 1 = segunda … 7 = domingo
  final DateTime date;
  final PlanDay plan; // plano efetivo (recorrente + ajuste da semana)
  final _DayState state;
  final String? label;
  final String groups;
  final WorkoutSession? doneSession;
  final String? clubSessionId;

  const _DayVM({
    required this.dia,
    required this.date,
    required this.plan,
    required this.state,
    this.label,
    this.groups = '',
    this.doneSession,
    this.clubSessionId,
  });

  bool get isTraining => !plan.isRestDay;
  bool get isDone => state == _DayState.done;

  /// Concluído ou em andamento: sem mover, trocar ou descanso (§7).
  bool get isProtected => isDone || state == _DayState.inProgress;
}

/// "Minha semana" v2 (Figma 282:68 · 285:141 · 285:231 · 285:320 ·
/// 278:1487 · 278:1600 · 291:76). Regras em MINHA_SEMANA.md §4/§7.
class WeeklyPlanScreen extends StatefulWidget {
  /// Mostra o selo "CLUB" no cabeçalho quando aberta a partir do Club.
  final bool isClub;

  const WeeklyPlanScreen({super.key, this.isClub = false});

  @override
  State<WeeklyPlanScreen> createState() => _WeeklyPlanScreenState();
}

class _WeeklyPlanScreenState extends State<WeeklyPlanScreen> {
  static const _px = 25.0;

  bool _loading = true;
  bool _hasClub = false;
  int _weekOffset = 0;

  WeeklyPlanConfig _config = const WeeklyPlanConfig();

  /// Plano efetivo da semana exibida: 7 linhas, `tipo` já resolvido.
  List<PlanDay> _weekPlan = const [];

  /// Tipo de cada dia no plano recorrente (para "Editar plano").
  List<bool> _recurringTraining = List.filled(7, true);
  List<_DayVM> _days = const [];

  final Map<int, WorkoutSession> _doneByDay = {};
  final Map<int, String> _clubDoneByDay = {};
  bool _activeToday = false;
  List<WorkoutTemplate> _userTemplates = const [];
  List<WorkoutTemplate> _clubTemplates = const [];

  DateTime get _now => DateTime.now();
  DateTime get _today => WeekCalendar.dateOf(_now);
  DateTime get _currentWeek => WeekCalendar.weekStartFor(_now);
  DateTime get _weekStart => DateTime(_currentWeek.year, _currentWeek.month,
      _currentWeek.day + 7 * _weekOffset);

  bool get _isPastWeek => _weekOffset < 0;
  bool get _isEditableWeek =>
      _weekOffset >= 0 && _weekOffset <= ApplyWeekAdjustment.maxFutureWeeks;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── dados ─────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    if (getIt<GetCurrentUser>()() == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final ws = _weekStart;
      final we = ws.add(const Duration(days: 7));
      final results = await Future.wait<Object?>([
        getIt<GetWeeklyPlanConfig>()(),
        getIt<ResolveClubAccess>()(),
        getIt<GetWeekPlan>()(ws),
        getIt<GetWeeklyPlan>()(),
        getIt<GetWeekCompletedWorkouts>()(ws, we),
        getIt<GetWorkoutTemplates>()(),
        getIt<ClubWorkoutRepository>().myTemplates(),
        _weekOffset == 0
            ? getIt<HasActiveWorkout>()()
            : Future<Object?>.value(null),
      ]);
      if (!mounted) return;

      final config = (results[0] as dynamic).valueOrNull as WeeklyPlanConfig? ??
          const WeeklyPlanConfig();
      final hasClub = (results[1] as dynamic).valueOrNull as bool? ?? false;
      final weekRows =
          (results[2] as dynamic).valueOrNull as List<PlanDay>? ?? const [];
      final recurringRows =
          (results[3] as dynamic).valueOrNull as List<PlanDay>? ?? const [];
      final week =
          (results[4] as dynamic).valueOrNull as WeekCompletedWorkouts? ??
              const WeekCompletedWorkouts();
      final userTemplates =
          (results[5] as dynamic).valueOrNull as List<WorkoutTemplate>? ??
              const [];
      final clubTemplates =
          (results[6] as dynamic).valueOrNull as List<WorkoutTemplate>? ??
              const [];
      final active = results[7] == null
          ? false
          : ((results[7] as dynamic).valueOrNull as bool? ?? false);

      // Regra única do tipo do dia (ajuste → recorrente → rest_days → freq.).
      final training = PlanDayTypeResolver.trainingDays(
        plan: weekRows,
        restDays: config.restDays,
        frequencyDays: config.frequencyDays,
      );
      final byDay = {for (final d in weekRows) d.diaSemana: d};

      _doneByDay.clear();
      _clubDoneByDay.clear();
      for (final w in week.personal) {
        if (w.completedAt != null && w.startedAt != null) {
          _doneByDay.putIfAbsent(w.startedAt!.toLocal().weekday, () => w);
        }
      }
      for (final w in week.club) {
        if (w.completedAt != null && w.startedAt != null && w.id != null) {
          _clubDoneByDay.putIfAbsent(
              w.startedAt!.toLocal().weekday, () => w.id!);
        }
      }

      setState(() {
        _config = config;
        _hasClub = hasClub;
        _activeToday = active;
        _userTemplates = userTemplates;
        _clubTemplates = clubTemplates;
        _recurringTraining = PlanDayTypeResolver.trainingDays(
          plan: recurringRows,
          restDays: config.restDays,
          frequencyDays: config.frequencyDays,
        );
        _weekPlan = [
          for (var d = 1; d <= 7; d++)
            PlanDay(
              diaSemana: d,
              tipo: training[d - 1] ? 'treino' : 'descanso',
              treino: byDay[d]?.treino,
            ),
        ];
        _compose();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Monta os cards a partir de [_weekPlan] (também na prévia otimista).
  void _compose() {
    final labels = _splitLabels(_config.splitPreference);
    final trainingIdx = [
      for (final d in _weekPlan)
        if (!d.isRestDay) d.diaSemana,
    ];
    final byId = {
      for (final t in _userTemplates)
        if (t.id != null) t.id!: t,
    };
    _days = [
      for (final d in _weekPlan)
        () {
          final date = WeekCalendar.dayOf(_weekStart, d.diaSemana);
          final done = _doneByDay[d.diaSemana];
          final clubDone = _clubDoneByDay[d.diaSemana];
          final isToday = date == _today;
          final _DayState state;
          if (done != null || clubDone != null) {
            state = _DayState.done;
          } else if (d.isRestDay) {
            state = _DayState.free;
          } else if (isToday) {
            state = _activeToday ? _DayState.inProgress : _DayState.today;
          } else if (date.isBefore(_today)) {
            state = _DayState.missed;
          } else {
            state = _DayState.planned;
          }
          // Dias sem template_id mostram o template_name (§7).
          final name = d.treino?.name;
          final idx = trainingIdx.indexOf(d.diaSemana);
          final label = (name != null && name.isNotEmpty)
              ? name
              : (!d.isRestDay && idx >= 0
                  ? labels[idx % labels.length]
                  : (done?.templateName ?? done?.name));
          final tpl = d.treino?.id == null ? null : byId[d.treino!.id];
          return _DayVM(
            dia: d.diaSemana,
            date: date,
            plan: d,
            state: state,
            label: label,
            groups: tpl == null
                ? ''
                : HomeV2Format.muscleGroups(tpl).replaceAll(' · ', ' + '),
            doneSession: done,
            clubSessionId: clubDone,
          );
        }(),
    ];
  }

  List<String> _splitLabels(String pref) {
    if (pref.contains('Full Body')) return ['Full Body'];
    if (pref.contains('Upper/Lower')) return ['Upper', 'Lower'];
    if (pref.contains('Push/Pull/Legs')) return ['Push', 'Pull', 'Legs'];
    if (pref.contains('ABCDE')) return ['A', 'B', 'C', 'D', 'E'];
    return [AppLocalizations.of(context).ms_workout_fallback];
  }

  // ── textos de data (listas do .arb) ───────────────────────────────────────

  List<String> _list(String csv) => csv.split(',');
  String _dayShort(int dia) =>
      _list(AppLocalizations.of(context).ms_weekdays_short)[dia - 1];
  String _dayLong(int dia) =>
      _list(AppLocalizations.of(context).ms_weekdays_long)[dia - 1];

  String _rangeLabel() {
    final l10n = AppLocalizations.of(context);
    final a = _weekStart;
    final b = a.add(const Duration(days: 6));
    if (a.month == b.month) {
      return '${a.day} — ${b.day} ${_list(l10n.ms_months)[a.month - 1]}';
    }
    final short = _list(l10n.ms_months_short);
    return '${a.day} ${short[a.month - 1]} — ${b.day} ${short[b.month - 1]}';
  }

  String _dayHeader(_DayVM d) => '${_dayShort(d.dia)}  ${d.date.day}';

  // ── regras de acesso ──────────────────────────────────────────────────────

  bool _canAdjust(_DayVM d) =>
      _isEditableWeek && !d.isProtected && !d.date.isBefore(_today);

  void _openPaywall() =>
      ClubPaywallSheet.show(context, onSubscribed: () => _load());

  // ── ajustes da semana ─────────────────────────────────────────────────────

  Future<void> _applyAdjustment(WeekAdjustment adj, String savedMessage) async {
    if (!_hasClub) {
      _openPaywall();
      return;
    }
    final before = _weekPlan;
    final built = ApplyWeekAdjustment.buildOverrides(
        adjustment: adj, weekStart: _weekStart, weekPlan: before);
    if (built.isFailure) {
      _showError(built.failureOrNull!.message);
      return;
    }
    // Prévia otimista: a tela muda antes da resposta.
    setState(() {
      _weekPlan = WeekPlanMerger.merge(before, built.valueOrNull!);
      _compose();
    });
    final result = await getIt<ApplyWeekAdjustment>()(
      adjustment: adj,
      weekStart: _weekStart,
      today: _now,
      weekPlan: before,
      protectedDays: {
        for (final d in _days)
          if (d.isProtected) d.dia,
      },
    );
    if (!mounted) return;
    final failure = result.failureOrNull;
    if (failure != null) {
      setState(() {
        _weekPlan = before;
        _compose();
      });
      if (failure is ClubRequiredFailure) {
        _openPaywall();
      } else {
        _showError(AppLocalizations.of(context).ms_save_error);
      }
      return;
    }
    if (_weekOffset == 0) unawaited(WidgetDataService.updateAll());
    _showSaved(savedMessage, onUndo: () => _undo(result.valueOrNull!, before));
  }

  Future<void> _undo(
      WeekAdjustmentOutcome outcome, List<PlanDay> before) async {
    final after = _weekPlan;
    setState(() {
      _weekPlan = before;
      _compose();
    });
    final r = await getIt<UndoWeekAdjustment>()(outcome);
    if (!mounted) return;
    if (r.isFailure) {
      setState(() {
        _weekPlan = after;
        _compose();
      });
      _showError(AppLocalizations.of(context).ms_undo_error);
    } else if (_weekOffset == 0) {
      unawaited(WidgetDataService.updateAll());
    }
  }

  /// "Todas as semanas": muda o plano recorrente e remove o ajuste deste dia
  /// nesta semana, para o recorrente voltar a valer.
  Future<void> _applyRecurring(int dia, WorkoutTemplate tpl) async {
    final l10n = AppLocalizations.of(context);
    final r = await getIt<UpdatePlanDay>()(dia, template: tpl);
    if (r.isSuccess) {
      await getIt<ClearWeekDayOverride>()(_weekStart, dia);
    }
    if (!mounted) return;
    if (r.isFailure) {
      _showError(l10n.ms_save_error);
      return;
    }
    unawaited(WidgetDataService.updateAll());
    await _load();
    if (mounted) _showSaved(l10n.ms_saved_set(tpl.name, _dayLong(dia)));
  }

  void _showError(String message) => context.toast.error(message);

  /// Snackbar "Semana atualizada" + "Desfazer" (Figma 291:76). Mantido:
  /// visual próprio do mockup de Treinos (exceção da T5).
  void _showSaved(String message, {VoidCallback? onUndo}) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(_px, 0, _px, 16),
        duration: const Duration(seconds: 5),
        content: Container(
          constraints: const BoxConstraints(minHeight: 70),
          padding: const EdgeInsets.fromLTRB(17, 12, 12, 12),
          decoration: BoxDecoration(
            color: BldrWeekColorsV2.snackBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BldrWeekColorsV2.gold),
          ),
          child: Row(children: [
            const Icon(TablerIcons.check,
                size: 20, color: BldrWeekColorsV2.gold),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.ms_saved_title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrWeekTextV2.snackTitle),
                  const SizedBox(height: 4),
                  Text(message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: BldrWeekTextV2.snackSub),
                ],
              ),
            ),
            if (onUndo != null)
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  onUndo();
                },
                child: Text(l10n.ms_undo, style: BldrWeekTextV2.undo),
              ),
          ]),
        ),
      ));
  }

  // ── toques ────────────────────────────────────────────────────────────────

  void _onDayTap(_DayVM d) {
    if (d.isDone) {
      _showDoneSheet(d);
      return;
    }
    if (d.state == _DayState.inProgress) return;
    final canStart = d.isTraining &&
        d.plan.treino?.id != null &&
        (d.state == _DayState.today || d.state == _DayState.missed);
    if (!_canAdjust(d)) {
      if (canStart) _showDayActions(d, startOnly: true);
      return;
    }
    if (d.isTraining) {
      _showDayActions(d);
    } else {
      _pickTemplate(d, adding: true);
    }
  }

  void _onDrop(int fromDia, int toDia) {
    final l10n = AppLocalizations.of(context);
    final from = _days[fromDia - 1];
    final to = _days[toDia - 1];
    final name = from.label ?? l10n.ms_workout_fallback;
    final message = to.isTraining
        ? l10n.ms_saved_swapped(name, to.label ?? l10n.ms_workout_fallback)
        : l10n.ms_saved_moved(name, _dayLong(toDia));
    _applyAdjustment(MoveWorkout(fromDia, toDia), message);
  }

  // ── sheets ────────────────────────────────────────────────────────────────

  Widget _sheetSubtitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Text(text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: BldrWeekTextV2.sheetSub),
      );

  /// "Ações do dia" (Figma 285:141).
  void _showDayActions(_DayVM d, {bool startOnly = false}) {
    final l10n = AppLocalizations.of(context);
    final name = d.label ?? l10n.ms_workout_fallback;
    final canStart = d.plan.treino?.id != null &&
        (d.state == _DayState.today || d.state == _DayState.missed);
    BldrV2Sheet.show<void>(
      context,
      title: l10n.ms_actions_title,
      child: Builder(
        builder: (ctx) => Column(children: [
          _sheetSubtitle([
            '${_dayShort(d.dia)} ${d.date.day}',
            name,
            if (d.groups.isNotEmpty) d.groups,
          ].join('  ·  ')),
          if (!startOnly) ...[
            BldrV2SheetOption(
              icon: TablerIcons.arrows_exchange,
              label: l10n.ms_swap,
              subtitle: l10n.ms_swap_sub,
              onTap: () {
                Navigator.pop(ctx);
                _pickTemplate(d, adding: false);
              },
            ),
            BldrV2SheetOption(
              icon: TablerIcons.arrow_up_right,
              label: l10n.ms_move,
              subtitle: l10n.ms_move_sub,
              locked: !_hasClub,
              onTap: () {
                Navigator.pop(ctx);
                _hasClub ? _showMoveSheet(d) : _openPaywall();
              },
            ),
            BldrV2SheetOption(
              icon: TablerIcons.minus,
              label: l10n.ms_rest_action,
              subtitle: l10n.ms_rest_action_sub,
              locked: !_hasClub,
              onTap: () {
                Navigator.pop(ctx);
                _applyAdjustment(
                    MakeRestDay(d.dia), l10n.ms_saved_rest(_dayLong(d.dia)));
              },
            ),
          ],
          // Ação existente mantida: "Fazer agora" (hoje / dia não feito).
          if (canStart)
            BldrV2SheetOption(
              icon: TablerIcons.player_play,
              label: l10n.ms_start,
              subtitle: l10n.ms_start_sub,
              onTap: () {
                Navigator.pop(ctx);
                _startWorkout(d);
              },
            ),
        ]),
      ),
    );
  }

  /// "Trocar treino" / "Adicionar treino" (Figma 285:231) → escopo.
  Future<void> _pickTemplate(_DayVM d, {required bool adding}) async {
    final l10n = AppLocalizations.of(context);
    final options = [
      ..._userTemplates.where((t) => t.id != null),
      ..._clubTemplates
          .where((t) => t.id != null)
          .map((t) => WorkoutTemplate(id: t.id, name: t.name, source: 'club')),
    ];
    String? selected = d.plan.treino?.id;
    final picked = await BldrV2Sheet.show<WorkoutTemplate>(
      context,
      title: adding ? l10n.ms_add_title : l10n.ms_swap,
      child: StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sheetSubtitle(
                '${_dayShort(d.dia)} ${d.date.day}  ·  ${l10n.ms_swap_hint}'),
            if (options.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(l10n.ms_no_templates,
                    textAlign: TextAlign.center,
                    style: BldrWeekTextV2.optionSub),
              ),
            for (final t in options) ...[
              if (t.source == 'club' &&
                  options.indexOf(t) ==
                      options.indexWhere((o) => o.source == 'club'))
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                  child: Text(l10n.ms_club_section,
                      style: BldrWeekTextV2.editLabel),
                ),
              _RadioRow(
                title: t.name,
                subtitle:
                    t.source == 'club' ? '' : HomeV2Format.muscleGroups(t),
                selected: selected == t.id,
                onTap: () => setSheet(() => selected = t.id),
              ),
            ],
            const SizedBox(height: 18),
            BldrV2SheetButton(
              label: adding ? l10n.ms_confirm_add : l10n.ms_confirm_swap,
              onTap: selected == null
                  ? null
                  : () => Navigator.pop(
                      ctx, options.firstWhere((t) => t.id == selected)),
            ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    _askScope(d, picked);
  }

  /// "Só nesta semana / Todas as semanas" (§7).
  void _askScope(_DayVM d, WorkoutTemplate tpl) {
    final l10n = AppLocalizations.of(context);
    BldrV2Sheet.show<void>(
      context,
      title: l10n.ms_scope_title,
      child: Builder(
        builder: (ctx) => Column(children: [
          _sheetSubtitle('${tpl.name}  ·  ${_dayShort(d.dia)} ${d.date.day}'),
          BldrV2SheetOption(
            icon: TablerIcons.calendar_event,
            label: l10n.ms_scope_week,
            locked: !_hasClub,
            onTap: () {
              Navigator.pop(ctx);
              _applyAdjustment(SetDayWorkout(d.dia, tpl),
                  l10n.ms_saved_set(tpl.name, _dayLong(d.dia)));
            },
          ),
          BldrV2SheetOption(
            icon: TablerIcons.repeat,
            label: l10n.ms_scope_all,
            onTap: () {
              Navigator.pop(ctx);
              _applyRecurring(d.dia, tpl);
            },
          ),
        ]),
      ),
    );
  }

  /// "Mover treino" (Figma 285:320): tocar no destino já aplica.
  void _showMoveSheet(_DayVM from) {
    final l10n = AppLocalizations.of(context);
    final targets =
        _days.where((d) => d.dia != from.dia && _canAdjust(d)).toList();
    BldrV2Sheet.show<void>(
      context,
      title: l10n.ms_move_title,
      child: Builder(
        builder: (ctx) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sheetSubtitle(
                '${(from.label ?? l10n.ms_workout_fallback).toUpperCase()}  ·  ${l10n.ms_move_hint}'),
            for (final t in targets)
              _RadioRow(
                title: '${_dayShort(t.dia)} ${t.date.day}',
                subtitle: t.isTraining
                    ? l10n.ms_dest_busy(t.label ?? l10n.ms_workout_fallback)
                    : l10n.ms_dest_free,
                selected: false,
                compact: true,
                onTap: () {
                  Navigator.pop(ctx);
                  _onDrop(from.dia, t.dia);
                },
              ),
            const SizedBox(height: 14),
            Text(l10n.ms_dest_note, style: BldrWeekTextV2.optionSub),
          ],
        ),
      ),
    );
  }

  /// Dia concluído: mostra o treino feito (com os músculos) e mantém
  /// "Excluir registro".
  void _showDoneSheet(_DayVM d) {
    final l10n = AppLocalizations.of(context);
    final w = d.doneSession;
    final isClubOnly = w == null && d.clubSessionId != null;
    final minutes = (w?.totalDurationSeconds ?? 0) ~/ 60;
    final muscles = ValueNotifier<List<String>?>(null);
    if (w?.id != null) {
      getIt<GetWorkoutMuscles>()(w!.id!)
          .then((r) => muscles.value = r.valueOrNull ?? const []);
    }
    BldrV2Sheet.show<void>(
      context,
      title: l10n.plan_workout_done,
      child: Builder(
        builder: (ctx) => Column(children: [
          _sheetSubtitle([
            '${_dayShort(d.dia)} ${d.date.day}',
            w?.templateName ?? d.label ?? l10n.ms_workout_fallback,
            if (!isClubOnly && minutes > 0) '$minutes min',
            if (isClubOnly) 'CLUB',
          ].join('  ·  ')),
          if (w?.id != null)
            ValueListenableBuilder<List<String>?>(
              valueListenable: muscles,
              builder: (_, list, __) => list == null
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                          color: BldrWeekColorsV2.gold, strokeWidth: 2),
                    )
                  : list.isEmpty
                      ? const SizedBox.shrink()
                      : MuscleVisualizerWidget(
                          targetMuscles: list,
                          secondaryMuscles: const [],
                          isPro: _hasClub,
                          size: VisualizerSize.full,
                          mode: VisualizerMode.highlight,
                          paywallMessage: l10n.plan_paywall_muscle_message,
                          paywallButtonLabel: l10n.plan_paywall_muscle_btn,
                          onUpgradeTap: () {
                            Navigator.pop(ctx);
                            Navigator.pushNamed(
                                context, AppRoutes.checkoutScreen);
                          },
                        ),
            ),
          if (w?.id != null || d.clubSessionId != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              icon: const Icon(TablerIcons.trash,
                  size: 16, color: BldrColors.danger),
              label: Text(l10n.plan_delete_record_btn,
                  style: BldrWeekTextV2.optionTitle
                      .copyWith(color: BldrColors.danger)),
              onPressed: () => _deleteDone(ctx, d),
            ),
          ],
        ]),
      ),
    );
  }

  Future<void> _deleteDone(BuildContext sheetCtx, _DayVM d) async {
    final l10n = AppLocalizations.of(context);
    final ok = await BldrV2ConfirmDialog.show(
      context,
      title: l10n.plan_delete_record_title,
      message: l10n.plan_delete_record_body,
      cancelLabel: l10n.common_cancel,
      confirmLabel: l10n.common_delete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final r = d.doneSession?.id != null
        ? await getIt<DeleteCompletedWorkout>()(d.doneSession!.id!)
        : await getIt<DeleteCompletedClubWorkout>()(d.clubSessionId!);
    if (!mounted) return;
    if (r.isFailure) {
      _showError(l10n.plan_delete_record_error);
      return;
    }
    if (sheetCtx.mounted) Navigator.pop(sheetCtx);
    _load();
  }

  Future<void> _startWorkout(_DayVM d) async {
    final t = d.plan.treino;
    if (t?.id == null) return;
    final name = t!.name.isEmpty
        ? (d.label ?? AppLocalizations.of(context).ms_workout_fallback)
        : t.name;
    final isClub = t.source == 'club';
    final r = isClub
        ? await getIt<StartClubWorkout>()(name: name, templateId: t.id!)
        : await getIt<StartWorkout>()(name: name, templateId: t.id!);
    final session = r.valueOrNull;
    if (!mounted) return;
    if (session?.id == null) {
      final f = r.failureOrNull;
      if (f != null) _showError(f.message);
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => isClub
            ? ClubActiveWorkoutScreen(
                workoutId: session!.id!, workoutName: name)
            : ActiveWorkoutScreen(workoutId: session!.id!, workoutName: name),
      ),
    );
    if (mounted) _load();
  }

  // ── Editar plano (Figma 278:1487) — plano recorrente ──────────────────────

  static const _splits = [
    'Full Body',
    'Upper/Lower',
    'Push/Pull/Legs',
    'ABCDE'
  ];
  static const _splitPrefs = {
    'Full Body': 'Full Body (Corpo Inteiro)',
    'Upper/Lower': 'Upper/Lower (Superior/Inferior)',
    'Push/Pull/Legs': 'Push/Pull/Legs (Empurrar/Puxar/Pernas)',
    'ABCDE': 'ABCDE',
  };

  void _showEditPlanSheet() {
    final l10n = AppLocalizations.of(context);
    final pref = _config.splitPreference;
    String? split = _splits
        .where((s) => pref.contains(s))
        .firstOrNull; // null = HAVOK/vazio
    final training = List<bool>.of(_recurringTraining);
    final letters = _list(l10n.ms_weekdays_letter);
    BldrV2Sheet.show<void>(
      context,
      title: l10n.plan_edit_sheet_title,
      child: StatefulBuilder(builder: (ctx, setSheet) {
        final t = training.where((x) => x).length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.ms_split_label, style: BldrWeekTextV2.editLabel),
            const SizedBox(height: 12),
            Wrap(spacing: 7, runSpacing: 6, children: [
              for (final s in _splits)
                _PillChip(
                  label: s,
                  selected: split == s,
                  onTap: () => setSheet(() => split = s),
                ),
              // "HAVOK decide": desabilitado, "Em breve" (§7).
              _PillChip(
                label: 'HAVOK decide',
                badge: l10n.ms_soon,
                selected: split == null && pref.contains('HAVOK'),
                onTap: null,
              ),
            ]),
            const SizedBox(height: 32),
            Row(children: [
              Expanded(
                  child: Text(l10n.ms_days_label,
                      style: BldrWeekTextV2.editLabel)),
              Text(l10n.ms_days_summary(t, 7 - t),
                  style: BldrWeekTextV2.editCount),
            ]),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (_, c) {
              final w = math.min(44.0, (c.maxWidth - 6 * 7) / 7);
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 7; i++)
                    _DayToggle(
                      letter: letters[i],
                      training: training[i],
                      width: w,
                      onTap: () => setSheet(() => training[i] = !training[i]),
                    ),
                ],
              );
            }),
            const SizedBox(height: 14),
            Center(
              child: Text(l10n.plan_days_toggle_hint,
                  textAlign: TextAlign.center, style: BldrWeekTextV2.footer),
            ),
            const SizedBox(height: 28),
            BldrV2SheetButton(
              label: l10n.plan_save_btn,
              onTap: () {
                Navigator.pop(ctx);
                _savePlan(
                  split == null ? pref : _splitPrefs[split]!,
                  [
                    for (var i = 0; i < 7; i++)
                      if (!training[i]) i,
                  ],
                );
              },
            ),
          ],
        );
      }),
    );
  }

  Future<void> _savePlan(String splitPref, List<int> restDays) async {
    final l10n = AppLocalizations.of(context);
    final r = await getIt<SaveWeeklyPlanConfig>()(
        splitPreference: splitPref, restDays: restDays);
    if (!mounted) return;
    final f = r.failureOrNull;
    if (f != null) {
      _showError(l10n.plan_save_error(f.message));
      return;
    }
    unawaited(WidgetDataService.updateAll());
    context.toast.success(l10n.plan_save_success);
    _load();
  }

  // ── Registrar extra (Figma 278:1600) — "+50 XP" como hoje ─────────────────

  void _showRegisterExtraSheet() {
    final l10n = AppLocalizations.of(context);
    var type = ActivityType.musculacao;
    var minutes = 30.0;
    final notes = TextEditingController();
    BldrV2Sheet.show<void>(
      context,
      title: l10n.plan_extra_sheet_title,
      child: StatefulBuilder(
        builder: (ctx, setSheet) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _sheetSubtitle(l10n.plan_extra_sheet_subtitle)),
            Text(l10n.plan_extra_type_label.toUpperCase(),
                style: BldrWeekTextV2.editLabel),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 7, children: [
              for (final t in ActivityType.values)
                _PillChip(
                  label: t.label,
                  selected: type == t,
                  onTap: () => setSheet(() => type = t),
                ),
            ]),
            const SizedBox(height: 22),
            Row(children: [
              Expanded(
                child: Text(l10n.plan_extra_duration_label.toUpperCase(),
                    style: BldrWeekTextV2.editLabel),
              ),
              Text('${minutes.round()} min', style: BldrWeekTextV2.duration),
            ]),
            SliderTheme(
              data: SliderTheme.of(ctx).copyWith(
                trackHeight: 4,
                activeTrackColor: BldrWeekColorsV2.gold,
                inactiveTrackColor: BldrWeekColorsV2.track,
                thumbColor: BldrWeekColorsV2.gold,
                overlayColor: BldrWeekColorsV2.gold.withValues(alpha: 0.12),
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 9.5),
              ),
              child: Slider(
                value: minutes,
                min: 15,
                max: 120,
                divisions: 7,
                onChanged: (v) => setSheet(() => minutes = v),
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.plan_extra_notes_label.toUpperCase(),
                style: BldrWeekTextV2.editLabel),
            const SizedBox(height: 9),
            TextField(
              controller: notes,
              style: BldrWeekTextV2.optionTitle,
              cursorColor: BldrWeekColorsV2.gold,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: BldrWeekColorsV2.editChip,
                hintText: l10n.plan_extra_notes_hint,
                hintStyle: BldrWeekTextV2.optionSub,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            BldrV2SheetButton(
              label: l10n.plan_extra_register_btn,
              onTap: () async {
                Navigator.pop(ctx);
                final r = await getIt<LogExtraActivity>()(
                  date: _now,
                  activityType: type,
                  durationMin: minutes.round(),
                  notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
                );
                if (!mounted) return;
                final f = r.failureOrNull;
                if (f != null) {
                  _showError(l10n.plan_extra_register_error(f.message));
                } else {
                  context.toast.success(l10n.plan_extra_register_success);
                  _load();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final training = _days.where((d) => d.isTraining).length;
    return Scaffold(
      backgroundColor: BldrColorsV2.bg,
      body: BldrBackground(
        v2: true,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(_px, 12, _px, 28),
            children: [
              _header(l10n),
              const SizedBox(height: 24),
              _weekNav(l10n, training),
              const SizedBox(height: 18),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: BldrWeekColorsV2.gold, strokeWidth: 2),
                  ),
                )
              else
                _grid(),
              const SizedBox(height: 24),
              Text(l10n.ms_management, style: BldrWeekTextV2.section),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _ManageButton(
                    label: l10n.ms_edit_plan,
                    style: BldrWeekTextV2.editPlan,
                    gold: true,
                    onTap: _showEditPlanSheet,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ManageButton(
                    label: l10n.ms_register_extra,
                    icon: TablerIcons.plus,
                    style: BldrWeekTextV2.extra,
                    onTap: _showRegisterExtraSheet,
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              Text(l10n.ms_footer,
                  textAlign: TextAlign.center, style: BldrWeekTextV2.footer),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(AppLocalizations l10n) => Row(children: [
        Semantics(
          button: true,
          label: MaterialLocalizations.of(context).backButtonTooltip,
          child: GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                  color: BldrWeekColorsV2.headerButton, shape: BoxShape.circle),
              child: const Icon(TablerIcons.chevron_left,
                  size: 22, color: BldrWeekColorsV2.gold),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(
                  child: Text(l10n.ms_title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: BldrWeekTextV2.title),
                ),
                if (widget.isClub) ...[
                  const SizedBox(width: 7),
                  const BldrBadge(label: 'CLUB'),
                ],
              ]),
              const SizedBox(height: 4),
              Text(l10n.ms_subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: BldrWeekTextV2.subtitle),
            ],
          ),
        ),
        // Ação existente mantida no slot "Ação do cabeçalho": HAVOK.
        HavokEntryIcon(
            onTap: () => showHavokSheet(context, originScreen: 'weekly_plan')),
      ]);

  Widget _arrow(
          IconData icon, String label, bool enabled, VoidCallback onTap) =>
      Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon,
                size: 22,
                color: enabled
                    ? BldrWeekColorsV2.gold
                    : BldrWeekColorsV2.cardBorder),
          ),
        ),
      );

  Widget _weekNav(AppLocalizations l10n, int training) {
    void go(int delta) {
      // Navegar entre semanas é do BLDR CLUB (§7).
      if (!_hasClub) {
        _openPaywall();
        return;
      }
      setState(() => _weekOffset += delta);
      _load();
    }

    final instruction = _isPastWeek
        ? l10n.ms_read_only
        : (!_hasClub ? l10n.ms_club_hint : l10n.ms_instruction);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: Text(_rangeLabel(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BldrWeekTextV2.range),
          ),
          _arrow(
              TablerIcons.chevron_left, l10n.ms_prev_week, true, () => go(-1)),
          _arrow(TablerIcons.chevron_right, l10n.ms_next_week,
              _weekOffset < ApplyWeekAdjustment.maxFutureWeeks, () => go(1)),
        ]),
        const SizedBox(height: 2),
        Text(
            '${l10n.ms_workouts_planned(training)}  ·  ${l10n.ms_rest_days(7 - training)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: BldrWeekTextV2.summary),
        const SizedBox(height: 18),
        Center(
          child: Text(instruction,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: BldrWeekTextV2.instruction),
        ),
      ],
    );
  }

  Widget _grid() {
    if (_days.length != 7) return const SizedBox.shrink();
    return LayoutBuilder(builder: (_, c) {
      final half = (c.maxWidth - 9) / 2;
      Widget pair(int a, int b) => IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _cell(_days[a], width: half)),
                const SizedBox(width: 9),
                Expanded(child: _cell(_days[b], width: half)),
              ],
            ),
          );
      return Column(children: [
        pair(0, 1),
        const SizedBox(height: 11),
        pair(2, 3),
        const SizedBox(height: 11),
        pair(4, 5),
        const SizedBox(height: 21),
        // Domingo (7º card) ocupa a linha toda.
        _cell(_days[6], width: c.maxWidth, wide: true),
      ]);
    });
  }

  /// Card com arraste (CLUB) e alvo de soltura.
  Widget _cell(_DayVM d, {required double width, bool wide = false}) {
    final card = _DayCard(
      vm: d,
      header: _dayHeader(d),
      wide: wide,
      editable: _canAdjust(d),
      locked: !_hasClub,
      onTap: () => _onDayTap(d),
    );
    final canDrag = _hasClub && _canAdjust(d) && d.isTraining;
    Widget child = canDrag
        ? LongPressDraggable<int>(
            data: d.dia,
            feedback: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: width,
                child: Opacity(opacity: 0.9, child: card),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.35, child: card),
            child: card,
          )
        : (!_hasClub && _canAdjust(d) && d.isTraining)
            ? GestureDetector(onLongPress: _openPaywall, child: card)
            : card;
    if (!_hasClub || !_canAdjust(d)) return child;
    return DragTarget<int>(
      onWillAcceptWithDetails: (det) => det.data != d.dia,
      onAcceptWithDetails: (det) => _onDrop(det.data, d.dia),
      builder: (_, candidates, __) => AnimatedScale(
        scale: candidates.isEmpty ? 1 : 1.03,
        duration: const Duration(milliseconds: 120),
        child: child,
      ),
    );
  }
}

// ── componentes da tela ─────────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  final _DayVM vm;
  final String header;
  final bool wide;
  final bool editable;
  final bool locked;
  final VoidCallback onTap;

  const _DayCard({
    required this.vm,
    required this.header,
    required this.wide,
    required this.editable,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rest = !vm.isTraining && !vm.isDone;
    final today =
        vm.state == _DayState.today || vm.state == _DayState.inProgress;
    final (chipText, chipBg, chipStyle) = switch (vm.state) {
      _DayState.today => (
          l10n.ms_state_today,
          BldrWeekColorsV2.todayChip,
          BldrWeekTextV2.chipToday
        ),
      _DayState.inProgress => (
          l10n.ms_state_in_progress,
          BldrWeekColorsV2.todayChip,
          BldrWeekTextV2.chipToday
        ),
      _DayState.done => (
          l10n.ms_state_done,
          BldrWeekColorsV2.todayChip,
          BldrWeekTextV2.chipToday
        ),
      _DayState.missed => (
          l10n.ms_state_missed,
          BldrWeekColorsV2.chip,
          BldrWeekTextV2.chip
        ),
      _DayState.planned => (
          l10n.ms_state_planned,
          BldrWeekColorsV2.chip,
          BldrWeekTextV2.chip
        ),
      _DayState.free => (
          l10n.ms_state_free,
          BldrWeekColorsV2.restChip,
          BldrWeekTextV2.chip
        ),
    };
    final cornerIcon = !editable
        ? null
        : rest
            ? TablerIcons.plus
            : TablerIcons.grip_vertical;

    final name = rest
        ? l10n.ms_rest
        : (vm.label ?? l10n.ms_workout_fallback).toUpperCase();
    final sub = rest ? l10n.ms_free_day : vm.groups;

    final content = wide && rest
        ? Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(header, maxLines: 1, style: BldrWeekTextV2.day),
            ),
            const SizedBox(height: 6),
            Text(l10n.ms_rest,
                style: BldrWeekTextV2.name, textAlign: TextAlign.center),
            if (editable) ...[
              const SizedBox(height: 6),
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(TablerIcons.plus,
                    size: 13, color: BldrWeekColorsV2.gold),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(l10n.ms_add_workout,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrWeekTextV2.add),
                ),
              ]),
            ],
          ])
        : Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(header,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: today ? BldrWeekTextV2.dayToday : BldrWeekTextV2.day),
            ),
            SizedBox(height: wide ? 6 : 22),
            rest
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    child:
                        Text(name, maxLines: 1, style: BldrWeekTextV2.restName),
                  )
                : Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: BldrWeekTextV2.name),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(sub,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: BldrWeekTextV2.groups),
            ],
            SizedBox(height: wide ? 8 : 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(chipText, maxLines: 1, style: chipStyle),
              ),
            ),
          ]);

    final box = Container(
      constraints: BoxConstraints(minHeight: wide ? 79 : 142),
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      decoration: rest
          ? null
          : BoxDecoration(
              color: today ? null : BldrWeekColorsV2.cardBg,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                  color: today || vm.isDone
                      ? BldrWeekColorsV2.gold
                      : BldrWeekColorsV2.cardBorder),
            ),
      child: Stack(children: [
        Center(child: content),
        if (cornerIcon != null)
          Positioned(
            top: 0,
            right: 0,
            child: Icon(cornerIcon,
                size: 16,
                color: rest ? BldrWeekColorsV2.gold : BldrWeekColorsV2.muted),
          ),
      ]),
    );

    return Semantics(
      button: true,
      label: '$header · $name',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: rest
            ? CustomPaint(
                foregroundPainter: const _DashedBorderPainter(
                    color: BldrWeekColorsV2.restBorder, radius: 17),
                child: Container(
                  decoration: BoxDecoration(
                    color: BldrWeekColorsV2.cardBg,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: box,
                ),
              )
            : box,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  const _DashedBorderPainter(
      {required this.color, required this.radius, this.strokeWidth = 1.5});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(strokeWidth / 2),
          Radius.circular(radius)));
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 4), paint);
        d += 7;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

/// Linha selecionável dos sheets "Trocar" e "Mover" (285:231 / 285:320).
class _RadioRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _RadioRow({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: compact ? 51 : 60),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: selected ? BldrWeekColorsV2.gold : Colors.transparent),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: compact
                            ? BldrWeekTextV2.destName
                            : BldrWeekTextV2.pickName),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BldrWeekTextV2.optionSub),
                    ],
                  ],
                ),
              ),
              Icon(
                  selected ? TablerIcons.circle_dot_filled : TablerIcons.circle,
                  size: 18,
                  color: BldrWeekColorsV2.gold),
            ]),
          ),
        ),
      );
}

/// Chip em pílula do "Editar plano" e do "Registrar extra".
class _PillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final String? badge;
  final VoidCallback? onTap;

  const _PillChip(
      {required this.label, required this.selected, this.badge, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Semantics(
      button: true,
      enabled: !disabled,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: disabled ? 0.55 : 1,
          child: Container(
            constraints: const BoxConstraints(minHeight: 32),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? null : BldrWeekColorsV2.editChip,
              borderRadius: BorderRadius.circular(16),
              border:
                  selected ? Border.all(color: BldrWeekColorsV2.gold) : null,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(label,
                  style: selected
                      ? BldrWeekTextV2.editChipOn
                      : BldrWeekTextV2.editChip),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Text('· $badge', style: BldrWeekTextV2.editChip),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

/// Dia do "Editar plano": treino (halter, borda dourada) × descanso (zzz,
/// borda tracejada).
class _DayToggle extends StatelessWidget {
  final String letter;
  final bool training;
  final double width;
  final VoidCallback onTap;

  const _DayToggle(
      {required this.letter,
      required this.training,
      required this.width,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 50),
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: training
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: BldrWeekColorsV2.goldBrand),
            )
          : null,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(letter, style: BldrWeekTextV2.editChip),
        const SizedBox(height: 2),
        Icon(training ? TablerIcons.barbell : TablerIcons.zzz,
            size: 22,
            color: training
                ? BldrWeekColorsV2.goldBrand
                : BldrWeekColorsV2.goldBrand),
      ]),
    );
    return Semantics(
      button: true,
      toggled: training,
      label: letter,
      child: GestureDetector(
        onTap: onTap,
        child: training
            ? box
            : CustomPaint(
                foregroundPainter: const _DashedBorderPainter(
                    color: BldrWeekColorsV2.dayRestBorder,
                    radius: 11,
                    strokeWidth: 1),
                child: box,
              ),
      ),
    );
  }
}

class _ManageButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final TextStyle style;
  final bool gold;
  final VoidCallback onTap;

  const _ManageButton({
    required this.label,
    required this.style,
    required this.onTap,
    this.icon,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 63),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: gold ? null : BldrWeekColorsV2.cardBg,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(
                  color: gold
                      ? BldrWeekColorsV2.gold
                      : BldrWeekColorsV2.cardBorder),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: style.color),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: style),
              ),
            ]),
          ),
        ),
      );
}
