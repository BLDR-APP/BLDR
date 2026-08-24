import 'package:bldr_fitness/features/onboarding/domain/entities/onboarding_plan.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';

/// Resolve o treino explicitamente atribuído em `weekly_plan_days` pelo ID.
/// Não usa nome do split nem escolhe um template default.
abstract final class TodayWorkoutResolver {
  static WorkoutTemplate? resolve({
    required Iterable<PlanDay> plan,
    required Iterable<WorkoutTemplate> templates,
    required int weekday,
  }) {
    PlanDay? today;
    for (final day in plan) {
      if (day.diaSemana == weekday) {
        today = day;
        break;
      }
    }
    final assigned = today?.treino;
    final assignedId = assigned?.id;
    if (assignedId == null || assignedId.isEmpty) return null;
    for (final template in templates) {
      if (template.id == assignedId) return template;
    }
    return null;
  }
}
