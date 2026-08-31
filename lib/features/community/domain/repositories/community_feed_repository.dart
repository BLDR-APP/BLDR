import 'dart:typed_data';

import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_post.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_comment.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_profile.dart';
import 'package:bldr_fitness/features/community/domain/entities/ranking_entry.dart';
import 'package:bldr_fitness/features/community/domain/entities/recent_workout.dart';
import 'package:bldr_fitness/features/community/domain/entities/workout_exercise.dart';

abstract class CommunityFeedRepository {
  /// Feed público — paginado por cursor (created_at DESC).
  ///
  /// Retorna [Result.failure] em caso de erro de rede/servidor.
  /// Lista vazia com [Result.success] significa que não há posts públicos.
  Future<Result<List<CommunityPost>>> fetchFeed({
    int limit = 20,
    DateTime? before,
  });

  Future<Result<List<CommunityPost>>> fetchFollowingFeed({
    int limit = 20,
    DateTime? before,
  });

  Future<Result<List<CommunityPost>>> fetchPrivatePosts({int limit = 50});

  Future<Result<List<CommunityPost>>> fetchSquadFeed(
    String squadId, {
    int limit = 50,
  });

  Future<Result<void>> followUser(String userId);

  Future<Result<void>> unfollowUser(String userId);

  Future<Result<void>> deletePost(String postId);

  Future<Result<void>> blockUser(String userId);

  Future<Result<void>> reportUser({
    required String userId,
    required String feedId,
    required String reason,
    String? details,
  });

  Future<Result<List<CommunityProfile>>> searchProfiles(String query);

  Future<Result<List<CommunityPost>>> searchPublicPosts(String query);

  Future<Result<List<CommunityComment>>> fetchComments(String feedId);
  Future<Result<void>> addComment({
    required String feedId,
    required String body,
    String? parentId,
  });
  Future<Result<void>> editComment({required String id, required String body});
  Future<Result<void>> deleteComment(String id);

  /// Publicar post manual.
  Future<Result<void>> createPost({
    required String eventType,
    required Map<String, dynamic> payload,
    required String visibility,
    String? squadId,
  });

  Future<Result<Map<String, dynamic>?>> detectRecentWearableActivity();

  Future<Result<List<Map<String, dynamic>>>> fetchWearableActivities(
    String provider,
  );

  Future<Result<String>> uploadCommunityPhoto({
    required Uint8List bytes,
    required String extension,
  });

  /// Reagir ou retirar reação (toggle).
  Future<Result<void>> toggleReaction({
    required String feedId,
    required String emoji,
  });

  /// Copiar treino de um post para workout_templates do usuário.
  /// Retorna o id do novo template criado.
  Future<Result<String>> copyWorkout({
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

  /// Ranking por categoria e período.
  ///
  /// [category] — 'volume' | 'consistency' | 'progression'
  /// [period]   — 'week' | 'month' | 'all'
  ///
  /// Nota: os valores de [period] são assumidos como 'week', 'month', 'all'.
  /// Confirmar contra a assinatura real das RPCs no Supabase antes de alterar.
  Future<Result<List<RankingEntry>>> fetchRanking({
    required String category,
    required String period,
  });
}
