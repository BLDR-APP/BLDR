import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/core/toast/bldr_toaster.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/bldr_muscle.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/muscle_normalizer.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_duration_estimator.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/create_workout_screen.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/exercise_details_screen.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/workout_details_format.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/home_v2_formatters.dart';
import 'package:bldr_fitness/shared/presentation/widgets/bldr_muscle_map.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Resultado ao sair dos detalhes, tratado pelo hub.
enum WorkoutDetailsResult { start, changed, deleted, duplicated }

enum _MenuAction { edit, duplicate, delete }

/// Detalhes do treino v2 (Figma 316:113 / 320:113 / 320:214).
class WorkoutDetailsScreen extends StatefulWidget {
  final String templateId;
  final String fallbackName;

  /// Treino do usuário: mostra o menu (editar / excluir).
  final bool isOwned;

  const WorkoutDetailsScreen({
    super.key,
    required this.templateId,
    required this.fallbackName,
    required this.isOwned,
  });

  @override
  State<WorkoutDetailsScreen> createState() => _WorkoutDetailsScreenState();
}

class _WorkoutDetailsScreenState extends State<WorkoutDetailsScreen> {
  WorkoutTemplate? _template;
  bool _loading = true;
  bool _error = false;
  double? _lastVolume;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    final result = await getIt<GetTemplateWithExercises>()(widget.templateId);
    if (!mounted) return;
    final t = result.valueOrNull;
    setState(() {
      _template = t;
      _error = t == null;
      _loading = false;
    });
    if (t != null) _loadLastVolume();
  }

  /// Volume da última execução deste treino (séries reais da sessão).
  Future<void> _loadLastVolume() async {
    try {
      final history =
          (await getIt<GetWorkoutHistory>()(completedOnly: true, limit: 50))
                  .valueOrNull ??
              const [];
      final last =
          WorkoutDetailsFormat.lastCompletedFor(history, widget.templateId);
      if (last?.id == null) return;
      final session = (await getIt<GetWorkoutDetails>()(last!.id!)).valueOrNull;
      if (session == null || !mounted) return;
      setState(() => _lastVolume = WorkoutDetailsFormat.sessionVolume(session));
    } catch (_) {
      // Sem volume: a faixa mostra "—".
    }
  }

  void _close([WorkoutDetailsResult? result]) => Navigator.pop(
      context, result ?? (_changed ? WorkoutDetailsResult.changed : null));

  Future<void> _edit() async {
    final t = _template;
    if (t == null) return;
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreateWorkoutScreen(editTemplate: t)),
    );
    if (updated == true && mounted) {
      _changed = true;
      _load();
    }
  }

  bool _duplicating = false;

  /// Cópia com exercícios e séries (TREINOS_V2, plano aprovado).
  Future<void> _duplicate() async {
    final t = _template;
    if (t == null || _duplicating) return;
    final l10n = AppLocalizations.of(context);
    _duplicating = true;
    final copy = WorkoutDetailsFormat.duplicate(
      t,
      name: l10n.wd_copy_name(t.name),
      durationMinutes: WorkoutDurationEstimator.estimateTemplate(t.exercises),
    );
    final result = await getIt<CreateWorkoutTemplate>()(copy);
    _duplicating = false;
    if (!mounted) return;
    if (result.isFailure) {
      context.toast.error(l10n.wd_duplicate_error);
      return;
    }
    _close(WorkoutDetailsResult.duplicated);
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final name = _template?.name ?? widget.fallbackName;
    final ok = await BldrV2ConfirmDialog.show(
      context,
      title: l10n.wd_delete_title,
      message: l10n.wd_delete_body(name),
      cancelLabel: l10n.common_cancel,
      confirmLabel: l10n.wd_delete,
      destructive: true,
    );
    if (!ok || !mounted) return;
    final result = await getIt<DeleteWorkoutTemplate>()(widget.templateId);
    if (!mounted) return;
    final failure = result.failureOrNull;
    if (failure != null) {
      context.toast.error(l10n.workouts_delete_error(failure.message));
      return;
    }
    _close(WorkoutDetailsResult.deleted);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = _template;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: BldrColorsV2.bg,
        body: BldrBackground(
          v2: true,
          child: SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
                child: _header(l10n, t?.name ?? widget.fallbackName),
              ),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: BldrDetailsColorsV2.gold))
                    : _error || t == null
                        ? _errorState(l10n)
                        : _content(l10n, t),
              ),
              if (t != null) _bottomAction(l10n),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _headerButton(
          {required IconData icon,
          required String label,
          VoidCallback? onTap}) =>
      Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: BldrDetailsColorsV2.headerButton,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 18, color: BldrDetailsColorsV2.text),
          ),
        ),
      );

  Widget _header(AppLocalizations l10n, String name) {
    return Row(children: [
      _headerButton(
        icon: TablerIcons.chevron_left,
        label: MaterialLocalizations.of(context).backButtonTooltip,
        onTap: _close,
      ),
      const SizedBox(width: 18),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.wd_eyebrow, style: BldrDetailsTextV2.eyebrow),
            const SizedBox(height: 2),
            Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BldrDetailsTextV2.name),
          ],
        ),
      ),
      if (widget.isOwned && _template != null)
        PopupMenuButton<_MenuAction>(
          tooltip: l10n.wd_options,
          padding: EdgeInsets.zero,
          color: BldrDetailsColorsV2.menuBg,
          offset: const Offset(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: BldrDetailsColorsV2.gold),
          ),
          onSelected: (a) => switch (a) {
            _MenuAction.edit => _edit(),
            _MenuAction.duplicate => _duplicate(),
            _MenuAction.delete => _delete(),
          },
          itemBuilder: (_) => [
            _menuItem(_MenuAction.edit, TablerIcons.pencil, l10n.wd_edit,
                BldrDetailsColorsV2.value),
            const PopupMenuDivider(height: 1),
            _menuItem(_MenuAction.duplicate, TablerIcons.copy,
                l10n.wd_duplicate, BldrDetailsColorsV2.value),
            const PopupMenuDivider(height: 1),
            _menuItem(_MenuAction.delete, TablerIcons.trash_x, l10n.wd_delete,
                BldrDetailsColorsV2.destructive),
          ],
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: BldrDetailsColorsV2.headerButton,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(TablerIcons.dots,
                size: 18, color: BldrDetailsColorsV2.text),
          ),
        ),
    ]);
  }

  PopupMenuItem<_MenuAction> _menuItem(
          _MenuAction value, IconData icon, String label, Color color) =>
      PopupMenuItem(
        value: value,
        height: 54,
        child: Row(children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 14),
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BldrDetailsTextV2.menuItem.copyWith(color: color)),
          ),
        ]),
      );

  Widget _errorState(AppLocalizations l10n) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(l10n.wd_error,
                textAlign: TextAlign.center, style: BldrDetailsTextV2.exSub),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              child: BldrV2SheetButton(label: l10n.wd_retry, onTap: _load),
            ),
          ]),
        ),
      );

  Widget _content(AppLocalizations l10n, WorkoutTemplate t) {
    final sets = WorkoutDetailsFormat.totalSets(t);
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 11, 28, 24),
      children: [
        _performance(l10n, t),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
            child: Text(l10n.wd_exercises,
                maxLines: 1, style: BldrDetailsTextV2.section),
          ),
          Flexible(
            child: Text(
                '${l10n.wd_ex_count(t.exercises.length)} · ${l10n.wd_sets_count(sets)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: BldrDetailsTextV2.count),
          ),
        ]),
        const SizedBox(height: 18),
        if (t.exercises.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(l10n.wd_empty,
                textAlign: TextAlign.center, style: BldrDetailsTextV2.exSub),
          )
        else
          for (final e in t.exercises) ...[
            _exerciseCard(l10n, e),
            const SizedBox(height: 6),
          ],
      ],
    );
  }

  Widget _performance(AppLocalizations l10n, WorkoutTemplate t) {
    final minutes = WorkoutDurationEstimator.estimateTemplate(t.exercises);
    final locale = Localizations.localeOf(context).toString();
    final map = MuscleNormalizer.mapDataForTemplate(t);
    Widget metric(String label, String value, {String? caption}) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BldrDetailsTextV2.metricLabel),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value,
                      maxLines: 1, style: BldrDetailsTextV2.metricValue),
                ),
                if (caption != null) ...[
                  const SizedBox(height: 4),
                  Text(caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrDetailsTextV2.metricCaption),
                ],
              ],
            ),
          ),
        );
    Widget divider() => Container(
        width: 1,
        margin: const EdgeInsets.symmetric(vertical: 16),
        color: BldrDetailsColorsV2.divider);
    final cells = <Widget>[
      metric(l10n.wd_duration, l10n.wd_minutes(minutes)),
      metric(l10n.wd_exercises, '${t.exercises.length}'),
      // Volume real da última execução; nunca o planejado.
      metric(
        l10n.wd_volume,
        _lastVolume == null
            ? '—'
            : '${HomeV2Format.thousands(_lastVolume!, locale)} kg',
        caption: _lastVolume == null ? null : l10n.wd_last_time,
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              height: 51,
              child: FittedBox(
                fit: BoxFit.contain,
                child: BldrMuscleMap(
                  muscles: map.muscles,
                  view: map.view,
                  size: BldrMuscleMapSize.card,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(l10n.wd_muscle_map,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BldrDetailsTextV2.metricCaption),
          ]),
        ),
      ),
    ];
    Widget row(List<Widget> items) => IntrinsicHeight(
          child: Row(children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) divider(),
              items[i],
            ],
          ]),
        );
    return LayoutBuilder(builder: (context, c) {
      // Tela estreita / fonte grande: 2 × 2.
      final narrow =
          c.maxWidth / MediaQuery.textScalerOf(context).scale(1) < 330;
      return Container(
        constraints: const BoxConstraints(minHeight: 87),
        padding: EdgeInsets.symmetric(vertical: narrow ? 6 : 0),
        decoration: BoxDecoration(
          color: BldrDetailsColorsV2.panelBg,
          borderRadius: BorderRadius.circular(17),
        ),
        child: narrow
            ? Column(
                children: [row(cells.sublist(0, 2)), row(cells.sublist(2))])
            : row(cells),
      );
    });
  }

  Widget _exerciseCard(AppLocalizations l10n, TemplateExercise e) {
    final sets = e.resolvedSets;
    final range = WorkoutDetailsFormat.repsRange(sets);
    final sub = [
      l10n.wd_sets_count(sets.length),
      if (range != null) l10n.wd_reps(range),
    ].join(' · ');
    final name =
        WorkoutDetailsFormat.exerciseName(e, l10n.workout_technique_fallback);
    return Semantics(
      button: true,
      label: name,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ExerciseDetailsScreen(exercise: e)),
        ),
        child: Container(
          constraints: const BoxConstraints(minHeight: 63),
          padding: const EdgeInsets.fromLTRB(9, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BldrDetailsColorsV2.gold),
          ),
          child: Row(children: [
            WorkoutGifThumb(url: WorkoutDetailsFormat.gifUrl(e), size: 43),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: BldrDetailsTextV2.exName),
                  const SizedBox(height: 6),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrDetailsTextV2.exSub),
                ],
              ),
            ),
            const Icon(TablerIcons.chevron_right,
                size: 18, color: BldrDetailsColorsV2.muted),
          ]),
        ),
      ),
    );
  }

  Widget _bottomAction(AppLocalizations l10n) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _close(WorkoutDetailsResult.start),
              child: Container(
                constraints: const BoxConstraints(minHeight: 52),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: BldrDetailsColorsV2.gold),
                ),
                child: Text(l10n.wd_start, style: BldrDetailsTextV2.cta),
              ),
            ),
          ),
          if (widget.isOwned) ...[
            const SizedBox(height: 12),
            Text(l10n.wd_preview_note,
                textAlign: TextAlign.center, style: BldrDetailsTextV2.note),
          ],
        ]),
      );
}

/// Miniatura do GIF de execução (GIF atual; fallback: ícone).
class WorkoutGifThumb extends StatelessWidget {
  final String? url;
  final double size;
  final double radius;

  /// Largura própria (área ampliada); padrão: quadrado de [size].
  final double? width;
  const WorkoutGifThumb(
      {super.key,
      required this.url,
      required this.size,
      this.radius = 11,
      this.width});

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Icon(TablerIcons.barbell,
          size: size * 0.42, color: BldrDetailsColorsV2.goldLabel),
    );
    return Container(
      width: width ?? size,
      height: size,
      decoration: BoxDecoration(
        color: BldrDetailsColorsV2.gifBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: BldrDetailsColorsV2.gifBorder, width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? fallback
          : CachedNetworkImage(
              imageUrl: url!,
              fit: width == null ? BoxFit.cover : BoxFit.contain,
              placeholder: (_, __) => fallback,
              errorWidget: (_, __, ___) => fallback,
            ),
    );
  }
}
