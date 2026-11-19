import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_post.dart';
import 'package:bldr_fitness/features/community/domain/entities/pr_history.dart';
import 'package:bldr_fitness/features/community/domain/repositories/community_feed_repository.dart';
import 'package:bldr_fitness/features/community/domain/usecases/edit_community_post.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_v2_format.dart';

class _Repo implements CommunityFeedRepository {
  Map<String, dynamic>? saved;

  @override
  Future<Result<void>> editPost({
    required String postId,
    required Map<String, dynamic> payload,
  }) async {
    saved = payload;
    return const Result.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CommunityPost _post({
  bool own = true,
  CommunityEventType type = CommunityEventType.manual,
  Map<String, dynamic> payload = const {'caption': 'antes'},
}) =>
    CommunityPost(
      id: 'p',
      userId: 'u',
      eventType: type,
      payload: payload,
      visibility: 'public',
      createdAt: DateTime(2026, 11, 18),
      isOwnPost: own,
    );

void main() {
  group('EditCommunityPost', () {
    test('troca só a legenda e preserva o restante do payload', () async {
      final repo = _Repo();
      final result = await EditCommunityPost(repo)(
        _post(
          type: CommunityEventType.workoutCompleted,
          payload: const {'caption': 'antes', 'volume_kg': 100},
        ),
        '  depois ',
      );
      expect(repo.saved, {'caption': 'depois', 'volume_kg': 100});
      expect(result.valueOrNull?.caption, 'depois');
    });

    test('legenda vazia remove a chave quando há outro conteúdo', () async {
      final repo = _Repo();
      await EditCommunityPost(repo)(
        _post(payload: const {'caption': 'a', 'photo_url': 'x'}),
        '   ',
      );
      expect(repo.saved, {'photo_url': 'x'});
    });

    test('recusa post alheio, post vazio e texto longo', () async {
      final repo = _Repo();
      final edit = EditCommunityPost(repo);
      expect((await edit(_post(own: false), 'x')).isFailure, isTrue);
      expect((await edit(_post(), ' ')).isFailure, isTrue);
      expect((await edit(_post(), 'a' * 2001)).isFailure, isTrue);
      expect(repo.saved, isNull);
    });
  });

  group('PrEvolution', () {
    PrHistoryEntry e(int day, double kg, double rm) => PrHistoryEntry(
        performedOn: DateTime(2026, 11, day), weightKg: kg, reps: 3, e1rm: rm);

    test('compara com o melhor dia anterior ao post', () {
      final r = PrEvolution.from(
        history: [e(18, 150, 165), e(10, 145, 160), e(2, 140, 150)],
        postDate: DateTime(2026, 11, 18, 20),
        weightKg: 150,
        e1rm: 165,
      );
      expect(r.previous?.weightKg, 145);
      expect(r.deltaKg, 5);
      expect(r.deltaPercent, closeTo(3.125, 0.001));
    });

    test('sem registro anterior não inventa comparação', () {
      final r = PrEvolution.from(
        history: [e(18, 150, 165)],
        postDate: DateTime(2026, 11, 18),
        weightKg: 150,
        e1rm: 165,
      );
      expect(r.previous, isNull);
      expect(r.deltaKg, isNull);
    });
  });

  test('exerciseMeta resume séries, repetições e maior carga', () {
    expect(
      CommunityV2Format.exerciseMeta([
        (weightKg: 30, reps: 8),
        (weightKg: 32, reps: 8),
        (weightKg: 32, reps: 6),
      ], 'pt_BR'),
      '3 × 8 · 32 kg',
    );
    expect(CommunityV2Format.exerciseMeta(const [], 'pt_BR'), '');
  });
}
