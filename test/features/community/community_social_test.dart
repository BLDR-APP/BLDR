import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/features/community/domain/entities/community_post.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_social_profile.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_post_tile_v2.dart';

CommunityPost _post(List<CommunityReaction> reactions, String? mine) =>
    CommunityPost(
      id: 'p',
      userId: 'u',
      eventType: CommunityEventType.manual,
      payload: const {},
      visibility: 'public',
      createdAt: DateTime(2026, 11, 18),
      reactions: reactions,
      myReactionEmoji: mine,
    );

int _count(CommunityPost p, String emoji) =>
    p.reactions.where((r) => r.emoji == emoji).firstOrNull?.count ?? 0;

void main() {
  group('applyReaction', () {
    test('adiciona a primeira reação', () {
      final r = CommunityPostActions.applyReaction(_post(const [], null), '🔥');
      expect(_count(r, '🔥'), 1);
      expect(r.myReactionEmoji, '🔥');
    });

    test('o mesmo emoji remove a reação', () {
      final r = CommunityPostActions.applyReaction(
        _post(const [CommunityReaction(emoji: '🔥', count: 2)], '🔥'),
        '🔥',
      );
      expect(_count(r, '🔥'), 1);
      expect(r.myReactionEmoji, isNull);
    });

    test('outro emoji troca sem somar duas vezes', () {
      final r = CommunityPostActions.applyReaction(
        _post(const [CommunityReaction(emoji: '🔥', count: 1)], '🔥'),
        '💪',
      );
      expect(_count(r, '🔥'), 0);
      expect(_count(r, '💪'), 1);
      expect(r.myReactionEmoji, '💪');
    });
  });

  group('CommunityFollowCounts', () {
    test('lê a RPC e ajusta depois de seguir', () {
      final counts =
          CommunityFollowCounts.fromRow(const {'followers': 3, 'following': 2});
      expect(counts.withFollower(added: true).followers, 4);
      expect(counts.withFollower(added: false).followers, 2);
      expect(counts.withFollower(added: true).following, 2);
    });

    test('nunca fica negativo', () {
      expect(
        const CommunityFollowCounts().withFollower(added: false).followers,
        0,
      );
    });
  });

  group('CommunityProfileStats', () {
    test('lê PRs, semanas ativas e conquistas da RPC', () {
      final stats = CommunityProfileStats.fromRow(const {
        'best_prs': [
          {'exercise': 'Agachamento', 'weight_kg': 150, 'reps': 3, 'e1rm': 165},
        ],
        'active_weeks': 8,
        'achievements': [
          {'name': 'Veterano', 'achieved_at': '2026-11-01T10:00:00Z'},
        ],
      });
      expect(stats.bestPrs.single.exercise, 'Agachamento');
      expect(stats.bestPrs.single.weightKg, 150);
      expect(stats.activeWeeks, 8);
      expect(stats.achievements, ['Veterano']);
    });

    test('campos ausentes viram vazios', () {
      final stats = CommunityProfileStats.fromRow(const {});
      expect(stats.bestPrs, isEmpty);
      expect(stats.activeWeeks, 0);
      expect(stats.achievements, isEmpty);
    });
  });

  test('perfil usa o nome, depois o usuário e por fim Atleta', () {
    expect(
        const CommunitySocialProfile(id: 'a', fullName: ' Ana ', username: 'x')
            .displayName,
        'Ana');
    expect(
        const CommunitySocialProfile(id: 'a', username: 'x').displayName, 'x');
    expect(const CommunitySocialProfile(id: 'a').displayName, 'Atleta');
  });
}
