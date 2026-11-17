import 'package:bldr_fitness/features/onboarding/domain/entities/onboarding_plan.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';

/// Ajuste do plano válido só para uma semana (`weekly_plan_overrides`,
/// MINHA_SEMANA.md §2/§9). Vence a linha recorrente de `weekly_plan_days`
/// naquela semana.
class WeekOverride {
  /// Segunda-feira da semana (data local, sem hora).
  final DateTime weekStart;
  final int diaSemana; // 1 = segunda … 7 = domingo
  final String tipo; // 'treino' | 'descanso'
  final WorkoutTemplate? treino;

  const WeekOverride({
    required this.weekStart,
    required this.diaSemana,
    required this.tipo,
    this.treino,
  });

  bool get isRestDay => tipo == 'descanso';

  PlanDay toPlanDay() =>
      PlanDay(diaSemana: diaSemana, tipo: tipo, treino: treino);

  factory WeekOverride.fromPlanDay(DateTime weekStart, PlanDay d) =>
      WeekOverride(
        weekStart: weekStart,
        diaSemana: d.diaSemana,
        tipo: d.tipo,
        treino: d.treino,
      );
}

/// Semana do calendário na data LOCAL do usuário (MINHA_SEMANA.md §9:
/// nunca em UTC).
abstract final class WeekCalendar {
  /// Segunda-feira (00:00, sem fuso) da semana do instante [instant].
  /// [utcOffset] fixa o fuso do usuário (testes / servidor); sem ele, usa o
  /// fuso do aparelho.
  static DateTime weekStartFor(DateTime instant, {Duration? utcOffset}) {
    final local =
        utcOffset == null ? instant.toLocal() : instant.toUtc().add(utcOffset);
    // Componentes de data → sem efeito de horário de verão.
    return DateTime(local.year, local.month, local.day - (local.weekday - 1));
  }

  /// Data local (sem hora) de [instant].
  static DateTime dateOf(DateTime instant, {Duration? utcOffset}) {
    final local =
        utcOffset == null ? instant.toLocal() : instant.toUtc().add(utcOffset);
    return DateTime(local.year, local.month, local.day);
  }

  /// Data do dia [diaSemana] (1–7) da semana [weekStart].
  static DateTime dayOf(DateTime weekStart, int diaSemana) =>
      DateTime(weekStart.year, weekStart.month, weekStart.day + diaSemana - 1);

  /// 'yyyy-MM-dd' (coluna `date`).
  static String toDateString(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Semanas entre [from] e [to] (segundas), positivo se [to] é depois.
  static int weeksBetween(DateTime from, DateTime to) =>
      (DateTime.utc(to.year, to.month, to.day)
                  .difference(DateTime.utc(from.year, from.month, from.day))
                  .inDays /
              7)
          .round();
}

/// Mesclagem pura: ajuste da semana → plano recorrente (§9).
abstract final class WeekPlanMerger {
  /// Plano efetivo da semana, ordenado por dia. Dias só com ajuste também
  /// entram; o ajuste substitui a linha recorrente do mesmo dia.
  static List<PlanDay> merge(
      Iterable<PlanDay> recurring, Iterable<WeekOverride> overrides) {
    final byDay = <int, PlanDay>{
      for (final d in recurring) d.diaSemana: d,
    };
    for (final o in overrides) {
      byDay[o.diaSemana] = o.toPlanDay();
    }
    final days = byDay.keys.toList()..sort();
    return [for (final k in days) byDay[k]!];
  }
}
