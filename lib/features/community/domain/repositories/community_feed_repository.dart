import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_post.dart';
import 'package:bldr_fitness/features/community/domain/entities/recent_workout.dart';
import 'package:bldr_fitness/features/community/domain/entities/workout_exercise.dart';

abstract class CommunityFeedRepository {
  /// Feed público — paginado por cursor (created_at DESC).
  Future<List<CommunityPost>> fetchFeed({
    int limit = 20,
    DateTime? before,
  });

  /// Publicar post manual.
  Future<void> createPost({
    required String eventType,
    required Map<String, dynamic> payload,
    required String visibility,
  });

  /// Reagir ou retirar reação (toggle).
  Future<void> toggleReaction({
    required String feedId,
    required String emoji,
  });

  /// Copiar treino de um post para workout_templates do usuário.
  /// Retorna o id do novo template criado.
  Future<String> copyWorkout({
    required String workoutId,
    required String source,
  });

  /// Inserir post de streak milestone (chamado pelo Flutter após detectar milestone).
  Future<void> postStreakMilestone({required int days});

  /// Últimos 5 treinos concluídos do usuário (free + club), ordenados por data.
  Future<Result<List<RecentWorkout>>> fetchRecentWorkouts();

  /// Exercícios e séries de um treino específico (para WorkoutDetailSheet).
  Future<Result<List<WorkoutExercise>>> fetchWorkoutExercises({
    required String workoutId,
    required String source,
  });
}
