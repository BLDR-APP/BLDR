import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';

/// Um dia do plano semanal gerado pelo HAVOK no onboarding (L4).
class PlanDay {
  final int diaSemana; // 1=segunda ... 7=domingo
  final String tipo; // 'treino' | 'descanso'
  final WorkoutTemplate? treino;

  const PlanDay({
    required this.diaSemana,
    required this.tipo,
    this.treino,
  });

  bool get isRestDay => tipo == 'descanso';
}

/// Plano semanal completo gerado no onboarding (HAVOK_SPEC.md §7.1).
class OnboardingPlan {
  final List<PlanDay> plano;
  final String resumo;
  final int metaCalorica;
  final int metaProteina;
  final int metaCarboidrato;
  final int metaGordura;

  /// true quando o plano veio do fallback (biblioteca), não da IA.
  final bool isFallback;

  const OnboardingPlan({
    required this.plano,
    required this.resumo,
    required this.metaCalorica,
    required this.metaProteina,
    required this.metaCarboidrato,
    required this.metaGordura,
    this.isFallback = false,
  });

  PlanDay? get today {
    final weekday = DateTime.now().weekday; // 1..7, mesma convenção do plano
    for (final d in plano) {
      if (d.diaSemana == weekday) return d;
    }
    return null;
  }
}
