import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_community_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_post.dart';
import 'package:bldr_fitness/features/community/domain/entities/workout_exercise.dart';
import 'package:bldr_fitness/features/community/domain/repositories/community_feed_repository.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_v2_format.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Ver treino (Figma 22:254). Conteúdo do [BldrV2Sheet].
class WorkoutDetailSheet extends StatefulWidget {
  final CommunityPost post;

  const WorkoutDetailSheet({super.key, required this.post});

  static Future<void> show(BuildContext context, CommunityPost post) =>
      BldrV2Sheet.show<void>(
        context,
        title: post.workoutName.toUpperCase(),
        child: WorkoutDetailSheet(post: post),
      );

  @override
  State<WorkoutDetailSheet> createState() => _WorkoutDetailSheetState();
}

class _WorkoutDetailSheetState extends State<WorkoutDetailSheet> {
  final _repo = getIt<CommunityFeedRepository>();

  bool _loading = true;
  bool _copying = false;
  int? _expanded;
  List<WorkoutExercise> _exercises = [];

  String get _workoutId => widget.post.payload['workout_id'] as String;
  String get _source => widget.post.payload['source'] as String? ?? 'free';

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    final result = await _repo.fetchWorkoutExercises(
      workoutId: _workoutId,
      source: _source,
    );
    if (!mounted) return;
    setState(() {
      _exercises = result.valueOrNull ?? const [];
      _loading = false;
    });
  }

  void _snack(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _copyWorkout() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _copying = true);
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final key = 'workout_copies_${now.year}_${now.month}';
    final count = prefs.getInt(key) ?? 0;

    if (_source == 'free' && count >= 3) {
      if (!mounted) return;
      _snack(l10n.comm_copy_limit);
      setState(() => _copying = false);
      return;
    }

    final result =
        await _repo.copyWorkout(workoutId: _workoutId, source: _source);
    if (!mounted) return;
    if (result.isFailure) {
      _snack(result.failureOrNull!.message);
      setState(() => _copying = false);
      return;
    }
    if (_source == 'free') await prefs.setInt(key, count + 1);
    if (!mounted) return;
    _snack(l10n.comm_copy_done);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final post = widget.post;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (post.username != null)
          Text(l10n.comm_workout_by('@${post.username}'),
              textAlign: TextAlign.center, style: BldrCommunityTextV2.sheetSub),
        const SizedBox(height: 16),
        Text(l10n.comm_type_workout, style: BldrCommunityTextV2.type),
        const SizedBox(height: 8),
        BldrCommunitySheetMetrics(items: [
          if (post.durationSeconds case final d?)
            (CommunityV2Format.duration(d), l10n.comm_label_duration),
          if (post.volumeKg case final v? when v > 0)
            (
              '${CommunityV2Format.thousands(v, locale)} kg',
              l10n.comm_label_volume
            ),
          if (post.completedSetCount case final s?)
            ('$s', l10n.comm_label_sets),
        ]),
        const SizedBox(height: 12),
        const BldrCommunitySheetDivider(),
        const SizedBox(height: 16),
        Text(l10n.comm_section_exercises, style: BldrCommunityTextV2.section),
        const SizedBox(height: 4),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(
                  color: BldrCommunityColorsV2.gold, strokeWidth: 2),
            ),
          )
        else if (_exercises.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(l10n.comm_exercises_empty,
                style: BldrCommunityTextV2.sheetSub),
          )
        else
          for (var i = 0; i < _exercises.length; i++)
            _exerciseRow(i, l10n, locale),
        const SizedBox(height: 20),
        Text(l10n.comm_copy_note, style: BldrCommunityTextV2.sheetSub),
        const SizedBox(height: 14),
        BldrV2SheetButton(
          label: _copying ? l10n.comm_copying : l10n.comm_copy_cta,
          onTap: _copying ? null : _copyWorkout,
        ),
      ],
    );
  }

  Widget _exerciseRow(int index, AppLocalizations l10n, String locale) {
    final ex = _exercises[index];
    final open = _expanded == index;
    final meta = CommunityV2Format.exerciseMeta(
      [for (final s in ex.sets) (weightKg: s.weightKg, reps: s.reps)],
      locale,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (index > 0) const BldrCommunitySheetDivider(),
        Semantics(
          button: true,
          expanded: open,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _expanded = open ? null : index),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ex.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: BldrCommunityTextV2.exercise),
                        if (meta.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(meta, style: BldrCommunityTextV2.sheetSub),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: open ? 0.25 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Text('›',
                        style: BldrCommunityTextV2.sheetMetric
                            .copyWith(color: BldrCommunityColorsV2.muted)),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (open)
          for (var s = 0; s < ex.sets.length; s++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.comm_set_line(s + 1),
                      style: BldrCommunityTextV2.historyDate),
                  Text(
                    [
                      if (ex.sets[s].weightKg case final w?)
                        CommunityV2Format.kg(w, locale),
                      if (ex.sets[s].reps case final r?) '$r',
                    ].join(' × '),
                    style: BldrCommunityTextV2.detailValue,
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
