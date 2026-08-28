import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';

/// Configuração do plano semanal, guardada em `user_profiles.onboarding_data`.
class WeeklyPlanConfig {
  final String splitPreference;
  final int frequencyDays;

  /// Índices dos dias de descanso escolhidos pelo usuário (0=Seg … 6=Dom);
  /// vazio quando o app distribui automaticamente.
  final List<int> restDays;

  const WeeklyPlanConfig({
    this.splitPreference = '',
    this.frequencyDays = 3,
    this.restDays = const [],
  });
}

/// Treinos concluídos na semana, separados por origem.
class WeekCompletedWorkouts {
  final List<WorkoutSession> personal; // user_workouts
  final List<WorkoutSession> club; // club_user_workouts

  const WeekCompletedWorkouts({
    this.personal = const [],
    this.club = const [],
  });
}
