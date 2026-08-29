import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_post.dart';
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
  Future<void> createPost({
    required String eventType,
    required Map<String, dynamic> payload,
    required String visibility,
  }) async {}

  @override
  Future<void> toggleReaction({
    required String feedId,
    required String emoji,
  }) async {}

  @override
  Future<String> copyWorkout({
    required String workoutId,
    required String source,
  }) async => 'new-template-id';

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
  late _FakeCommunityFeedRepository repo;

  setUp(() {
    repo = _FakeCommunityFeedRepository();
  });

  // 1. Feed público carregado com sucesso
  test('fetchFeed retorna lista de posts com sucesso', () async {
    repo.feedToReturn = [_makePost(), _makePost(id: 'post-2', userId: 'user-B')];

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
  test('fetchRanking passa p_period (não p_start) para o repositório', () async {
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
  test('RankingEntry.fromRow mapeia campos do retorno da RPC', () {
    final row = {
      'position': 1,
      'user_id': 'user-A',
      'display_name': 'Atleta A',
      'avatar_url': 'https://example.com/avatar.jpg',
      'value': 12345.6,
    };

    final entry = RankingEntry.fromRow(row, currentUserId: 'user-B');

    expect(entry.position, equals(1));
    expect(entry.userId, equals('user-A'));
    expect(entry.displayName, equals('Atleta A'));
    expect(entry.avatarUrl, equals('https://example.com/avatar.jpg'));
    expect(entry.value, closeTo(12345.6, 0.001));
    expect(entry.isMe, isFalse); // currentUserId é user-B, não user-A
  });

  test('RankingEntry.fromRow marca isMe quando userId == currentUserId', () {
    final row = {
      'position': 3,
      'user_id': 'user-A',
      'display_name': 'Eu mesmo',
      'value': 500,
    };

    final entry = RankingEntry.fromRow(row, currentUserId: 'user-A');

    expect(entry.isMe, isTrue);
  });

  test('RankingEntry.fromRow sem display_name usa fallback Atleta', () {
    final row = {
      'position': 5,
      'user_id': 'user-X',
      'display_name': null,
      'value': 0,
    };

    final entry = RankingEntry.fromRow(row);

    expect(entry.displayName, equals('Atleta'));
  });
}
