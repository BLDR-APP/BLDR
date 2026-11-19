import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/features/club/domain/entities/challenge_hub_rules.dart';
import 'package:bldr_fitness/features/club/domain/entities/challenges.dart';

void main() {
  final now = DateTime(2026, 11, 19, 12);

  CollectiveChallenge c(
    String id, {
    bool joined = false,
    int people = 0,
    String type = 'workouts',
    int? endsInDays,
    DateTime? createdAt,
  }) =>
      CollectiveChallenge(
        id: id,
        title: id,
        joined: joined,
        participantCount: people,
        challengeType: type,
        endsAt: endsInDays == null ? null : now.add(Duration(days: endsInDays)),
        createdAt: createdAt,
      );

  test('dias restantes arredondam para cima e não ficam negativos', () {
    expect(ChallengeHubRules.daysLeft(null, now), isNull);
    expect(
        ChallengeHubRules.daysLeft(now.add(const Duration(hours: 25)), now), 2);
    expect(
        ChallengeHubRules.daysLeft(now.subtract(const Duration(hours: 1)), now),
        0);
  });

  test('progresso fica entre 0 e 1 e tolera meta vazia', () {
    expect(
        ChallengeHubRules.progress(const CollectiveChallenge(
            id: 'a', title: 'a', targetValue: 10, currentValue: 25)),
        1);
    expect(
        ChallengeHubRules.progress(
            const CollectiveChallenge(id: 'a', title: 'a', currentValue: 5)),
        0);
  });

  test('ativos: destaque, outros e próximos a terminar', () {
    final s = ChallengeHubRules.active([
      c('fora', people: 99),
      c('top', joined: true, people: 50, endsInDays: 2),
      c('longo', joined: true, people: 10, endsInDays: 30),
      c('b', joined: true, people: 5, endsInDays: 6),
      c('a', joined: true, people: 4, endsInDays: 3),
    ], now);
    expect(s.featured?.id, 'top');
    expect(s.others.map((e) => e.id), ['longo']);
    expect(s.endingSoon.map((e) => e.id), ['a', 'b']);
  });

  test('ativos: vazio sem participação', () {
    expect(ChallengeHubRules.active([c('x')], now).featured, isNull);
  });

  test('descobrir: recomenda pelo tipo e não repete desafios', () {
    final s = ChallengeHubRules.discover([
      c('entrei', joined: true, people: 500),
      c('popular', people: 100, type: 'xp_total'),
      c('afim', people: 1, type: 'streak'),
      c('alta', people: 50, type: 'xp_total'),
      c('velho', people: 2, createdAt: DateTime(2026, 1, 1)),
      c('novo', people: 3, createdAt: DateTime(2026, 11, 1)),
    ], myTypes: [
      'streak',
      'streak',
      null
    ]);
    expect(s.recommended?.id, 'afim');
    expect(s.trending.map((e) => e.id), ['popular', 'alta']);
    expect(s.newest.map((e) => e.id), ['novo', 'velho']);
  });

  test('descobrir: sem histórico recomenda o mais popular', () {
    final s = ChallengeHubRules.discover([c('a', people: 1), c('b', people: 9)],
        myTypes: const []);
    expect(s.recommended?.id, 'b');
  });

  test('posição considera empates e exige participação', () {
    const rows = {'a': 30, 'b': 30, 'me': 10, 'c': 5};
    final s = ChallengeHubRules.standing(rows, 'me');
    expect((s?.position, s?.total, s?.contribution), (3, 4, 10));
    expect(ChallengeHubRules.standing(rows, 'b')?.position, 1);
    expect(ChallengeHubRules.standing(rows, 'x'), isNull);
  });
}
