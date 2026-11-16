import 'package:bldr_fitness/features/onboarding/domain/entities/onboarding_plan.dart';

/// Regra ÚNICA do tipo de cada dia da semana (treino × descanso), usada pela
/// WeeklyPlanScreen, pelo hub de Treinos e pela Home.
///
/// Prioridade:
/// 1. Linha em `weekly_plan_days` para o dia → o `tipo` decide
///    ('descanso' = descanso; qualquer outro = treino, mesmo sem template).
/// 2. Sem linha → `rest_days` do onboarding_data (0 = segunda … 6 = domingo).
/// 3. `rest_days` vazio → distribuição pela frequência semanal.
abstract final class PlanDayTypeResolver {
  /// 7 posições (0 = segunda): `true` = treino, `false` = descanso.
  static List<bool> trainingDays({
    required Iterable<PlanDay> plan,
    required List<int> restDays,
    required int frequencyDays,
  }) {
    final byIndex = <int, PlanDay>{
      for (final d in plan)
        if (d.diaSemana >= 1 && d.diaSemana <= 7) d.diaSemana - 1: d,
    };
    final fallback = restDays.isNotEmpty
        ? [for (var i = 0; i < 7; i++) !restDays.contains(i)]
        : () {
            final idx = trainingIndicesFromFrequency(frequencyDays);
            return [for (var i = 0; i < 7; i++) idx.contains(i)];
          }();
    return [
      for (var i = 0; i < 7; i++)
        byIndex.containsKey(i) ? !byIndex[i]!.isRestDay : fallback[i],
    ];
  }

  /// Índices de treino distribuídos pela frequência (a partir de segunda).
  /// Mesma regra que a WeeklyPlanScreen e o card da semana já usavam.
  static List<int> trainingIndicesFromFrequency(int n) {
    n = n.clamp(1, 7);
    if (n >= 7) return List.generate(7, (i) => i);
    return {
      for (var i = 0; i < n; i++) (i * 7 / n).round() % 7,
    }.toList()
      ..sort();
  }

  /// Índices (0 = segunda) dos dias de treino.
  static List<int> trainingIndices(List<bool> days) =>
      [for (var i = 0; i < days.length; i++) if (days[i]) i];
}
