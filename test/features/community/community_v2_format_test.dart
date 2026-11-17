import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/design_system/bldr_community_v2_components.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_v2_format.dart';

void main() {
  group('CommunityV2Format', () {
    final now = DateTime(2026, 11, 17, 12);

    test('ago: agora, minutos, horas e dias', () {
      expect(CommunityV2Format.ago(now, now).unit, CommunityAgoUnit.now);
      final m =
          CommunityV2Format.ago(now.subtract(const Duration(minutes: 18)), now);
      expect((m.unit, m.value), (CommunityAgoUnit.minutes, 18));
      final h =
          CommunityV2Format.ago(now.subtract(const Duration(minutes: 70)), now);
      expect((h.unit, h.value), (CommunityAgoUnit.hours, 1));
      final d =
          CommunityV2Format.ago(now.subtract(const Duration(days: 3)), now);
      expect((d.unit, d.value), (CommunityAgoUnit.days, 3));
    });

    test('duração, relógio, pace e números', () {
      expect(CommunityV2Format.duration(4320), '1h 12min');
      expect(CommunityV2Format.duration(2700), '45min');
      expect(CommunityV2Format.clock(2058), '34:18');
      expect(CommunityV2Format.clock(3725), '1:02:05');
      expect(CommunityV2Format.pace(2058, 6.42), '5:21');
      expect(CommunityV2Format.pace(null, 6.42), isNull);
      expect(CommunityV2Format.pace(100, 0), isNull);
      expect(CommunityV2Format.thousands(12480, 'pt_BR'), '12.480');
      expect(CommunityV2Format.decimal(6.42, 'pt_BR'), '6,42');
    });

    test('fonte e nome da atividade', () {
      expect(CommunityV2Format.providerLabel('apple_health'), 'APPLE WATCH');
      expect(CommunityV2Format.providerLabel('WHOOP'), 'WHOOP');
      expect(CommunityV2Format.providerLabel('strava'), isNull);
      expect(CommunityV2Format.activityName('outdoor_run'), 'Outdoor Run');
    });

    test('iniciais', () {
      expect(bldrInitials('Pedro Lima'), 'PL');
      expect(bldrInitials('pedro'), 'PE');
      expect(bldrInitials('  '), '?');
      expect(bldrInitials('+3'), '+3');
    });
  });

  group('CommunityV2Format.squad', () {
    final now = DateTime(2026, 11, 17, 20);
    String iso(DateTime d) => d.toUtc().toIso8601String();

    test('posição, treinaram hoje (sem chat), semana e último post', () {
      final s = CommunityV2Format.squad(
        arena: {'created_at': iso(DateTime(2026, 11, 1, 9))},
        participants: [
          {'user_id': 'a'},
          {'user_id': 'me'},
          {'user_id': 'c'},
        ],
        posts: [
          {'user_id': 'c', 'status': 'chat', 'created_at': iso(now)},
          {
            'user_id': 'a',
            'status': 'approved',
            'created_at': iso(DateTime(2026, 11, 17, 8))
          },
          {
            'user_id': 'a',
            'status': 'pending',
            'created_at': iso(DateTime(2026, 11, 17, 7))
          },
          {
            'user_id': 'me',
            'status': 'approved',
            'created_at': iso(DateTime(2026, 11, 17, 6))
          },
          {
            'user_id': 'c',
            'status': 'approved',
            'created_at': iso(DateTime(2026, 11, 16, 23))
          },
        ],
        myUserId: 'me',
        now: now,
      );
      expect(s.myRank, 2);
      expect(s.trainedToday, 2);
      expect(s.week, 3);
      expect(s.latest?['user_id'], 'a');
    });

    test('sem participação, sem posts e sem data', () {
      final s = CommunityV2Format.squad(
        arena: const {},
        participants: const [],
        posts: const [],
        myUserId: 'me',
        now: now,
      );
      expect(s.myRank, isNull);
      expect(s.trainedToday, 0);
      expect(s.week, isNull);
      expect(s.latest, isNull);
    });
  });
}
