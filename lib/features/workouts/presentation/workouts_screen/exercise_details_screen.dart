import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/workout_details_format.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/workout_details_screen.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Detalhes do exercício v2 (Figma 322:113) — somente consulta.
class ExerciseDetailsScreen extends StatelessWidget {
  final TemplateExercise exercise;
  const ExerciseDetailsScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final e = exercise;
    final name =
        WorkoutDetailsFormat.exerciseName(e, l10n.workout_technique_fallback);
    final groups = WorkoutDetailsFormat.muscleGroups(e);
    final sets = e.resolvedSets;
    final range = WorkoutDetailsFormat.repsRange(sets);
    final setsText =
        range == null ? '${sets.length}' : '${sets.length} × $range';
    final equipment = (e.exercise?.equipmentNeeded ?? const <String>[])
        .where((s) => s.trim().isNotEmpty)
        .join(' · ');
    final instructions = e.exercise?.instructions ?? const <String>[];
    final tips = (e.exercise?.tips ?? const <String>[])
        .where((s) => s.trim().isNotEmpty)
        .toList();
    final w = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: BldrColorsV2.bg,
      body: BldrBackground(
        v2: true,
        child: SafeArea(
          child: Column(children: [
            SizedBox(
              height: 48,
              child: Stack(children: [
                Positioned(
                  left: 18,
                  top: 0,
                  bottom: 0,
                  child: Semantics(
                    button: true,
                    label: MaterialLocalizations.of(context).backButtonTooltip,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.pop(context),
                      child: const SizedBox(
                        width: 40,
                        child: Icon(TablerIcons.chevron_left,
                            size: 26, color: BldrDetailsColorsV2.value),
                      ),
                    ),
                  ),
                ),
                Center(
                    child:
                        Text(l10n.ex_title, style: BldrDetailsTextV2.exTitle)),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                children: [
                  Text(name,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: BldrDetailsTextV2.exHeroName),
                  if (groups.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(groups,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: BldrDetailsTextV2.exGroups),
                  ],
                  const SizedBox(height: 22),
                  Container(
                    height: (w - 56) * 236 / 384,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: BldrDetailsColorsV2.gold),
                    ),
                    child: LayoutBuilder(
                      builder: (_, c) => WorkoutGifThumb(
                        url: WorkoutDetailsFormat.gifUrl(e),
                        size: c.maxHeight,
                        width: c.maxWidth,
                        radius: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (equipment.isNotEmpty)
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.ex_equipment,
                                style: BldrDetailsTextV2.exMetaLabel),
                            const SizedBox(height: 6),
                            Text(equipment,
                                style: BldrDetailsTextV2.exMetaValue),
                          ],
                        ),
                      ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.ex_sets,
                              style: BldrDetailsTextV2.exMetaLabel),
                          const SizedBox(height: 6),
                          Text(setsText, style: BldrDetailsTextV2.exSetsValue),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  Container(height: 1, color: BldrDetailsColorsV2.separator),
                  const SizedBox(height: 20),
                  Text(l10n.ex_how, style: BldrDetailsTextV2.exHow),
                  const SizedBox(height: 16),
                  if (instructions.isEmpty)
                    Text(l10n.workout_no_instructions,
                        style: BldrDetailsTextV2.exStep)
                  else
                    for (var i = 0; i < instructions.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Text('${i + 1}. ${instructions[i]}',
                            style: BldrDetailsTextV2.exStep),
                      ),
                  // "Dica de execução" só com dado próprio (`tips`).
                  if (tips.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      decoration: BoxDecoration(
                        color: BldrDetailsColorsV2.tipBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: BldrDetailsColorsV2.gold),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.ex_tip,
                              style: BldrDetailsTextV2.exTipLabel),
                          const SizedBox(height: 8),
                          for (final tip in tips)
                            Text(tip, style: BldrDetailsTextV2.exTipText),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
              child: Semantics(
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 54),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: BldrDetailsColorsV2.gold),
                    ),
                    child: Text(l10n.ex_back, style: BldrDetailsTextV2.cta),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
