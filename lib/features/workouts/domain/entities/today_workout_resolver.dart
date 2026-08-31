import 'package:bldr_fitness/features/onboarding/domain/entities/onboarding_plan.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';

/// Resolve o treino explicitamente atribuído em `weekly_plan_days` pelo ID.
/// Não usa nome do split nem escolhe um template default.
abstract final class TodayWorkoutResolver {
  static WorkoutSession? completedOnDate({
    required Iterable<WorkoutSession> sessions,
    required DateTime date,
  }) {
    for (final session in sessions) {
      final completedAt = session.completedAt?.toLocal();
      if (completedAt != null &&
          completedAt.year == date.year &&
          completedAt.month == date.month &&
          completedAt.day == date.day) {
        return session;
      }
    }
    return null;
  }

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
