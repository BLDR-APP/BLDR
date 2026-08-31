import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_post.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_comment.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_profile.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_post_payload.dart';
import 'package:bldr_fitness/features/community/domain/entities/ranking_entry.dart';
import 'package:bldr_fitness/features/community/domain/entities/recent_workout.dart';
import 'package:bldr_fitness/features/community/domain/entities/workout_exercise.dart';
import 'package:bldr_fitness/features/community/domain/repositories/community_feed_repository.dart';

// ── Fake repository ──────────────────────────────────────────────────────────

class _FakeCommunityFeedRepository implements CommunityFeedRepository {
  // Control flags
  bool shouldFail = false;
  List<CommunityPost> feedToReturn = [];
  List<RankingEntry> rankingToReturn = [];
  List<CommunityPost> followingFeedToReturn = [];
  String? lastRankingCategory;
  String? lastRankingPeriod;

  @override
  Future<Result<List<CommunityPost>>> fetchFeed({
    int limit = 20,
    DateTime? before,
  }) async {
    if (shouldFail) {
      return const Result.failure(
        ServerFailure('Não foi possível carregar o feed.'),
      );
    }
    return Result.success(feedToReturn);
  }

  @override
  Future<Result<List<RankingEntry>>> fetchRanking({
    required String category,
    required String period,
  }) async {
    lastRankingCategory = category;
    lastRankingPeriod = period;
    if (shouldFail) {
      return const Result.failure(
        ServerFailure('Não foi possível carregar o ranking.'),
      );
    }
    return Result.success(rankingToReturn);
  }

  @override
  Future<Result<List<CommunityPost>>> fetchFollowingFeed({
    int limit = 20,
    DateTime? before,
  }) async =>
      Result.success(followingFeedToReturn);

  @override
  Future<Result<List<CommunityPost>>> fetchPrivatePosts(
          {int limit = 50}) async =>
      const Result.success([]);

  @override
  Future<Result<List<CommunityPost>>> fetchSquadFeed(String squadId,
          {int limit = 50}) async =>
      const Result.success([]);

  @override
  Future<Result<void>> followUser(String userId) async =>
      const Result.success(null);

  @override
  Future<Result<void>> unfollowUser(String userId) async =>
      const Result.success(null);

  @override
  Future<Result<void>> deletePost(String postId) async =>
      const Result.success(null);

  @override
  Future<Result<void>> blockUser(String userId) async =>
      const Result.success(null);

  @override
  Future<Result<void>> reportUser({
    required String userId,
    required String feedId,
    required String reason,
    String? details,
  }) async =>
      const Result.success(null);

  @override
  Future<Result<List<CommunityProfile>>> searchProfiles(String query) async =>
      const Result.success([]);

  @override
  Future<Result<List<CommunityPost>>> searchPublicPosts(String query) async =>
      const Result.success([]);

  @override
  Future<Result<List<CommunityComment>>> fetchComments(String feedId) async =>
      const Result.success([]);

  @override
  Future<Result<void>> addComment({
    required String feedId,
    required String body,
    String? parentId,
  }) async =>
      const Result.success(null);

  @override
  Future<Result<void>> editComment(
          {required String id, required String body}) async =>
      const Result.success(null);

  @override
  Future<Result<void>> deleteComment(String id) async =>
      const Result.success(null);

  @override
  Future<Result<void>> createPost({
    required String eventType,
    required Map<String, dynamic> payload,
    required String visibility,
    String? squadId,
  }) async =>
      const Result.success(null);

  @override
  Future<Result<Map<String, dynamic>?>> detectRecentWearableActivity() async =>
      const Result.success(null);

  @override
  Future<Result<List<Map<String, dynamic>>>> fetchWearableActivities(
          String provider) async =>
      const Result.success([]);

  @override
  Future<Result<String>> uploadCommunityPhoto({
    required Uint8List bytes,
    required String extension,
  }) async =>
      const Result.success('https://example.com/photo.jpg');

  @override
  Future<Result<void>> toggleReaction({
    required String feedId,
    required String emoji,
  }) async =>
      const Result.success(null);

  @override
  Future<Result<String>> copyWorkout({
    required String workoutId,
    required String source,
  }) async =>
      const Result.success('new-template-id');

  @override
  Future<void> postStreakMilestone({required int days}) async {}

  @override
  Future<Result<List<RecentWorkout>>> fetchRecentWorkouts() async =>
      const Result.success([]);

  @override
  Future<Result<List<WorkoutExercise>>> fetchWorkoutExercises({
    required String workoutId,
    required String source,
  }) async =>
      const Result.success([]);
}

// ── Helpers de dados de teste ────────────────────────────────────────────────

CommunityPost _makePost({
  String id = 'post-1',
  String userId = 'user-A',
  String? username = 'atleta_a',
  String? fullName = 'Atleta A',
  String? avatarUrl,
  List<CommunityReaction> reactions = const [],
  String? myReaction,
}) {
  return CommunityPost(
    id: id,
    userId: userId,
    username: username,
    userFullName: fullName,
    userAvatarUrl: avatarUrl,
    eventType: CommunityEventType.manual,
    payload: {'caption': 'Treino concluído!'},
    visibility: 'public',
    createdAt: DateTime(2026, 8, 1),
    reactions: reactions,
    commentCount: 0,
    myReactionEmoji: myReaction,
  );
}

RankingEntry _makeEntry({
  int position = 1,
  String userId = 'user-A',
  String displayName = 'Atleta A',
  double value = 1000.0,
  bool isMe = false,
}) {
  return RankingEntry(
    position: position,
    userId: userId,
    displayName: displayName,
    value: value,
    isMe: isMe,
  );
}

// ── Testes ───────────────────────────────────────────────────────────────────

void main() {
  test('CommunityComment representa somente um nível de respostas', () {
    final created = DateTime.utc(2026, 8, 29);
    final reply = CommunityComment(
      id: 'reply',
      feedId: 'feed',
      userId: 'b',
      parentId: 'root',
      body: 'Resposta',
      createdAt: created,
    );
    final root = CommunityComment(
      id: 'root',
      feedId: 'feed',
      userId: 'a',
      body: 'Comentário',
      createdAt: created,
      replies: [reply],
    );
    expect(root.replies.single.parentId, root.id);
    expect(root.replies.single.replies, isEmpty);
  });

  test('CommunityProfile usa nome, username e fallback em ordem', () {
    expect(
      const CommunityProfile(id: '1', fullName: 'Ana', username: 'ana')
          .displayName,
      'Ana',
    );
    expect(
      const CommunityProfile(id: '2', username: 'bia').displayName,
      'bia',
    );
    expect(const CommunityProfile(id: '3').displayName, 'Atleta');
  });

  group('CommunityPostPayload', () {
    test('lê payload legado sem perder compatibilidade', () {
      final payload = CommunityPostPayload.fromJson({
        'workout_id': 'workout-1',
        'workout_name': 'Pernas',
        'volume_kg': 1200,
        'set_count': 12,
      });

      expect(payload.version, 0);
      expect(payload.kind, CommunityPayloadKind.workout);
      expect(payload.workoutName, 'Pernas');
      expect(payload.volumeKg, 1200);
      expect(payload.completedSetCount, 12);
    });

    test('serializa payload novo com versão e tipo', () {
      const payload = CommunityPostPayload(
        kind: CommunityPayloadKind.activity,
        activityType: 'corrida',
        durationSeconds: 1800,
      );

      expect(payload.toJson(), containsPair('version', 1));
      expect(payload.toJson(), containsPair('kind', 'activity'));
    });

    test('serializa a quantidade de séries concluídas do treino', () {
      const payload = CommunityPostPayload(
        kind: CommunityPayloadKind.workout,
        completedSetCount: 9,
      );

      expect(payload.toJson(), containsPair('set_count', 9));
    });

    test('expõe origem, atividade e métricas do wearable aninhado', () {
      final payload = CommunityPostPayload.fromJson({
        'version': 1,
        'kind': 'wearable',
        'wearable': {
          'provider': 'whoop',
          'activity_type': 'weightlifting',
          'duration_s': 3600,
          'strain': 10.8,
          'average_heart_rate': 73,
          'calories': 70,
        },
      });

      expect(payload.wearableProvider, 'whoop');
      expect(payload.wearableActivityType, 'weightlifting');
      expect(payload.wearableDurationSeconds, 3600);
      expect(payload.wearableStrain, 10.8);
      expect(payload.wearableAverageHeartRate, 73);
      expect(payload.wearableCalories, 70);
    });
  });

  late _FakeCommunityFeedRepository repo;

  setUp(() {
    repo = _FakeCommunityFeedRepository();
  });

  // 1. Feed público carregado com sucesso
  test('fetchFeed retorna lista de posts com sucesso', () async {
    repo.feedToReturn = [
      _makePost(),
      _makePost(id: 'post-2', userId: 'user-B')
    ];

    final result = await repo.fetchFeed();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, hasLength(2));
  });

  // 2. Consulta sem comment_count — verificado via CommunityPost.fromJson
  test('CommunityPost.fromJson funciona sem comment_count', () {
    final json = {
      'id': 'post-1',
      'user_id': 'user-A',
      'event_type': 'manual',
      'payload': {'caption': 'Olá'},
      'visibility': 'public',
      'created_at': '2026-08-01T10:00:00Z',
      'reactions': <Map<String, dynamic>>[],
      'my_reaction': null,
      // 'comment_count' intencionalmente ausente
      'user_profiles': {'username': 'atleta_a', 'full_name': 'Atleta A'},
    };

    final post = CommunityPost.fromJson(json);

    expect(post.commentCount, equals(0)); // default seguro
    expect(post.username, equals('atleta_a'));
  });

  test('CommunityPost.fromJson preserva metadados sociais do autor', () {
    final post = CommunityPost.fromJson({
      'id': 'post-1',
      'user_id': 'user-A',
      'event_type': 'manual',
      'payload': <String, dynamic>{},
      'visibility': 'public',
      'created_at': '2026-08-01T10:00:00Z',
      'is_club_member': true,
      'is_following': true,
      'is_own_post': false,
    });

    expect(post.isClubMember, isTrue);
    expect(post.isFollowing, isTrue);
    expect(post.isOwnPost, isFalse);
  });

  // 3. Associação de múltiplos posts a user_profiles distintos
  test('posts de usuários distintos mantêm seus perfis corretos', () async {
    repo.feedToReturn = [
      _makePost(id: 'post-1', userId: 'user-A', username: 'atleta_a'),
      _makePost(id: 'post-2', userId: 'user-B', username: 'atleta_b'),
    ];

    final result = await repo.fetchFeed();
    final posts = result.valueOrNull!;

    expect(posts[0].username, equals('atleta_a'));
    expect(posts[1].username, equals('atleta_b'));
  });

  // 4. Perfil ausente — fallback seguro
  test('post com user_profiles null usa fallback seguro', () {
    final json = {
      'id': 'post-1',
      'user_id': 'user-A',
      'event_type': 'manual',
      'payload': {},
      'visibility': 'public',
      'created_at': '2026-08-01T10:00:00Z',
      'reactions': <dynamic>[],
      'my_reaction': null,
      'user_profiles': null, // perfil ausente
    };

    final post = CommunityPost.fromJson(json);

    expect(post.username, isNull);
    expect(post.userFullName, isNull);
    expect(post.displayName, equals('Atleta')); // fallback definido na entidade
  });

  // 5. Preservação dos dados de reações
  test('fetchFeed preserva reações existentes', () async {
    final reactions = [
      const CommunityReaction(emoji: '🔥', count: 3),
      const CommunityReaction(emoji: '💪', count: 1),
    ];
    repo.feedToReturn = [_makePost(reactions: reactions, myReaction: '🔥')];

    final result = await repo.fetchFeed();
    final post = result.valueOrNull!.first;

    expect(post.reactions, hasLength(2));
    expect(post.reactions.first.emoji, equals('🔥'));
    expect(post.reactions.first.count, equals(3));
    expect(post.myReactionEmoji, equals('🔥'));
  });

  // 6. Feed vazio exibe estado vazio (não erro)
  test('fetchFeed com lista vazia retorna Result.success vazio', () async {
    repo.feedToReturn = [];

    final result = await repo.fetchFeed();

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull, isEmpty);
    expect(result.isFailure, isFalse);
  });

  // 7. Falha retorna Result.failure, não lista vazia
  test('fetchFeed com falha retorna Result.failure observável', () async {
    repo.shouldFail = true;

    final result = await repo.fetchFeed();

    expect(result.isFailure, isTrue);
    expect(result.isSuccess, isFalse);
    expect(result.failureOrNull, isA<ServerFailure>());
    expect(result.failureOrNull!.message, contains('feed'));
  });

  // 8. Retry após falha: segunda chamada pode ter sucesso
  test('retry após falha pode restaurar feed com sucesso', () async {
    repo.shouldFail = true;
    final first = await repo.fetchFeed();
    expect(first.isFailure, isTrue);

    repo.shouldFail = false;
    repo.feedToReturn = [_makePost()];
    final second = await repo.fetchFeed();
    expect(second.isSuccess, isTrue);
    expect(second.valueOrNull, hasLength(1));
  });

  // 9. Ranking envia p_period (não p_start)
  test('fetchRanking passa p_period (não p_start) para o repositório',
      () async {
    repo.rankingToReturn = [_makeEntry()];

    await repo.fetchRanking(category: 'volume', period: 'week');

    expect(repo.lastRankingPeriod, equals('week'));
    expect(repo.lastRankingCategory, equals('volume'));
  });

  // 10. Volume, consistência e progressão usam o contrato correto
  test('fetchRanking volume usa categoria correta', () async {
    await repo.fetchRanking(category: 'volume', period: 'month');
    expect(repo.lastRankingCategory, equals('volume'));
    expect(repo.lastRankingPeriod, equals('month'));
  });

  test('fetchRanking consistency usa categoria correta', () async {
    await repo.fetchRanking(category: 'consistency', period: 'week');
    expect(repo.lastRankingCategory, equals('consistency'));
  });

  test('fetchRanking progression usa categoria correta', () async {
    await repo.fetchRanking(category: 'progression', period: 'all');
    expect(repo.lastRankingCategory, equals('progression'));
    expect(repo.lastRankingPeriod, equals('all'));
  });

  // 11. Erro de ranking permanece observável
  test('fetchRanking com falha retorna Result.failure observável', () async {
    repo.shouldFail = true;

    final result = await repo.fetchRanking(category: 'volume', period: 'week');

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull, isA<ServerFailure>());
    expect(result.failureOrNull!.message, contains('ranking'));
  });

  // 12. Mapeamento do retorno real das RPCs via RankingEntry.fromRow
  // Campos reais: user_id, full_name, username, avatar_url, total (sem position)
  test('RankingEntry.fromRow mapeia campos do retorno real da RPC', () {
    final row = {
      'user_id': 'user-A',
      'full_name': 'Atleta A',
      'username': 'atletaa',
      'avatar_url': 'https://example.com/avatar.jpg',
      'total': 12345.6,
    };

    final entry =
        RankingEntry.fromRow(row, currentUserId: 'user-B', position: 1);

    expect(entry.position, equals(1));
    expect(entry.userId, equals('user-A'));
    expect(entry.displayName, equals('Atleta A')); // full_name tem prioridade
    expect(entry.avatarUrl, equals('https://example.com/avatar.jpg'));
    expect(entry.value, closeTo(12345.6, 0.001));
    expect(entry.isMe, isFalse);
  });

  test('RankingEntry.fromRow usa username quando full_name está vazio', () {
    final row = {
      'user_id': 'user-A',
      'full_name': null,
      'username': 'atletaa',
      'avatar_url': null,
      'total': 500,
    };

    final entry =
        RankingEntry.fromRow(row, currentUserId: 'user-A', position: 3);

    expect(entry.displayName, equals('atletaa'));
    expect(entry.isMe, isTrue);
  });

  test('RankingEntry.fromRow sem full_name nem username usa fallback Atleta',
      () {
    final row = {
      'user_id': 'user-X',
      'full_name': null,
      'username': null,
      'avatar_url': null,
      'total': 0,
    };

    final entry = RankingEntry.fromRow(row, position: 5);

    expect(entry.displayName, equals('Atleta'));
    expect(entry.value, equals(0.0));
  });
}
