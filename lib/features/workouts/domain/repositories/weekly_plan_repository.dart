import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/onboarding/domain/entities/onboarding_plan.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/weekly_plan.dart';

abstract class WeeklyPlanRepository {
  Future<Result<WeeklyPlanConfig>> planConfig();

  /// Persiste o plano completo (7 dias) no Supabase via upsert.
  Future<Result<void>> saveWeeklyPlan(List<PlanDay> days);

  /// Retorna os dias do plano ordenados por dia_semana.
  Future<Result<List<PlanDay>>> getWeeklyPlan();

  /// Atualiza apenas split e dias de descanso, preservando o restante do
  /// `onboarding_data`.
  Future<Result<void>> savePlanConfig({
    required String splitPreference,
    required List<int> restDays,
  });

  /// Treinos concluídos no intervalo [weekStart, weekEnd).
  Future<Result<WeekCompletedWorkouts>> completedBetween(
      DateTime weekStart, DateTime weekEnd);

  /// Músculos-alvo de um treino concluído (ExerciseDB + biblioteca interna,
  /// mesclados e deduplicados).
  Future<Result<List<String>>> musclesForWorkout(String workoutId);

  /// Exclui um treino concluído do BLDR Club (sets + registro).
  Future<Result<void>> deleteCompletedClub(String clubWorkoutId);
}
