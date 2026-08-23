// flutter_body_atlas incompatível com flutter_local_notifications (conflito xml ^6 vs ^7).
// BLDRMuscleAtlas renderiza grupos musculares como chips visuais até o conflito resolver.
import 'package:flutter/material.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

const _muscleLabels = <String, String>{
  'chest': 'Peitoral',
  'shoulders': 'Ombros',
  'triceps': 'Tríceps',
  'biceps': 'Bíceps',
  'back': 'Costas',
  'lats': 'Dorsais',
  'upper back': 'Trapézio',
  'traps': 'Trapézio',
  'lower back': 'Lombar',
  'abs': 'Abdômen',
  'quads': 'Quadríceps',
  'hamstrings': 'Isquiotibiais',
  'glutes': 'Glúteos',
  'calves': 'Panturrilha',
  'forearms': 'Antebraços',
};

class BLDRMuscleAtlas extends StatelessWidget {
  final List<String> muscleGroups;

  const BLDRMuscleAtlas({super.key, required this.muscleGroups});

  @override
  Widget build(BuildContext context) {
    if (muscleGroups.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        for (int i = 0; i < muscleGroups.length; i++)
          _MuscleChip(
            label: _muscleLabels[muscleGroups[i]] ?? muscleGroups[i],
            isPrimary: i == 0,
          ),
      ],
    );
  }
}

class _MuscleChip extends StatelessWidget {
  final String label;
  final bool isPrimary;

  const _MuscleChip({required this.label, required this.isPrimary});

  @override
  Widget build(BuildContext context) {
    const gold = BldrColors.goldBright;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPrimary
            ? gold.withValues(alpha: 0.15)
            : gold.withValues(alpha: 0.06),
        border: Border.all(
          color: isPrimary
              ? gold.withValues(alpha: 0.5)
              : gold.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: BldrText.family,
          fontSize: isPrimary ? 11 : 10,
          fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w400,
          color: isPrimary
              ? gold
              : gold.withValues(alpha: 0.65),
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
