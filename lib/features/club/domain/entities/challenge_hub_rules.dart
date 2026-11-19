import 'package:bldr_fitness/features/club/domain/entities/challenges.dart';

/// Minha posição num desafio.
class ChallengeStanding {
  final int position;
  final int total;
  final int contribution;

  const ChallengeStanding({
    required this.position,
    required this.total,
    required this.contribution,
  });
}

/// Seções da aba Ativos.
class ActiveChallengeSections {
  final CollectiveChallenge? featured;
  final List<CollectiveChallenge> others;
  final List<CollectiveChallenge> endingSoon;

  const ActiveChallengeSections({
    this.featured,
    this.others = const [],
    this.endingSoon = const [],
  });
}

/// Seções da aba Descobrir.
class DiscoverChallengeSections {
  final CollectiveChallenge? recommended;
  final List<CollectiveChallenge> trending;
  final List<CollectiveChallenge> newest;

  const DiscoverChallengeSections({
    this.recommended,
    this.trending = const [],
    this.newest = const [],
  });
}

/// Regras do hub de Desafios (D9: recomendação simples, sem motor).
abstract final class ChallengeHubRules {
  static const endingSoonDays = 7;
  static const trendingCount = 2;

  /// Dias restantes, arredondando para cima (null sem data).
  static int? daysLeft(DateTime? endsAt, DateTime now) {
    if (endsAt == null) return null;
    final diff = endsAt.difference(now);
    if (diff.isNegative) return 0;
    return (diff.inMinutes / Duration.minutesPerDay).ceil();
  }

  /// Progresso coletivo entre 0 e 1.
  static double progress(CollectiveChallenge c) {
    final target = c.targetValue ?? 0;
    if (target <= 0) return 0;
    return ((c.currentValue ?? 0) / target).clamp(0, 1).toDouble();
  }

  /// Destaque = mais participantes; quem termina em até 7 dias vai para
  /// "Próximos a terminar"; o restante, para "Outros desafios".
  static ActiveChallengeSections active(
      List<CollectiveChallenge> all, DateTime now) {
    final joined = all.where((c) => c.joined).toList()
      ..sort((a, b) => b.participantCount.compareTo(a.participantCount));
    if (joined.isEmpty) return const ActiveChallengeSections();
    final rest = joined.skip(1).toList();
    bool ending(CollectiveChallenge c) {
      final days = daysLeft(c.endsAt, now);
      return days != null && days <= endingSoonDays;
    }

    return ActiveChallengeSections(
      featured: joined.first,
      others: rest.where((c) => !ending(c)).toList(),
      endingSoon: rest.where(ending).toList()
        ..sort((a, b) => a.endsAt!.compareTo(b.endsAt!)),
    );
  }

  /// Recomendado = tipo em que o usuário mais participou, depois o mais
  /// popular. Em alta = mais participantes. Novos = o restante, recentes
  /// primeiro. Cada desafio aparece uma única vez.
  static DiscoverChallengeSections discover(
    List<CollectiveChallenge> all, {
    required Iterable<String?> myTypes,
  }) {
    final open = all.where((c) => !c.joined).toList();
    if (open.isEmpty) return const DiscoverChallengeSections();

    final affinity = <String, int>{};
    for (final type in myTypes) {
      if (type != null) affinity[type] = (affinity[type] ?? 0) + 1;
    }
    int byPopularity(CollectiveChallenge a, CollectiveChallenge b) =>
        b.participantCount.compareTo(a.participantCount);

    final ranked = [...open]..sort((a, b) {
        final byType = (affinity[b.challengeType] ?? 0)
            .compareTo(affinity[a.challengeType] ?? 0);
        return byType != 0 ? byType : byPopularity(a, b);
      });
    final recommended = ranked.first;
    final rest = open.where((c) => c.id != recommended.id).toList()
      ..sort(byPopularity);
    final trending = rest.take(trendingCount).toList();
    final newest = rest.skip(trendingCount).toList()
      ..sort((a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return DiscoverChallengeSections(
      recommended: recommended,
      trending: trending,
      newest: newest,
    );
  }

  /// Posição por contribuição; empates dividem a mesma posição.
  static ChallengeStanding? standing(
      Map<String, int> contributions, String userId) {
    final mine = contributions[userId];
    if (mine == null) return null;
    final ahead = contributions.values.where((v) => v > mine).length;
    return ChallengeStanding(
      position: ahead + 1,
      total: contributions.length,
      contribution: mine,
    );
  }
}
