import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/club/domain/entities/challenges.dart';

/// Comunidade competitiva do Club: feed de XP, ranking, duelos 1x1 e
/// desafios coletivos (schema `bldr_club`).
abstract class ChallengeRepository {
  /// Feed de XP com nome/avatar e contagem de reações resolvidos.
  Future<Result<List<XpFeedItem>>> xpFeed({int limit = 50});

  Future<Result<void>> reactToXpEvent(String eventId);
  Future<Result<void>> removeReactionFromXpEvent(String eventId);
  Future<Result<Set<String>>> myReactions(List<String> eventIds);

  Future<Result<List<ClubRankingEntry>>> ranking({int limit = 100});

  /// Duelos do usuário, enriquecidos com oponente e progresso.
  Future<Result<List<Duel>>> myDuels({int limit = 20});

  Future<Result<void>> respondDuel(String duelId, {required bool accept});

  /// Desafios coletivos ativos/concluídos, com contagem e flag de inscrição.
  Future<Result<List<CollectiveChallenge>>> collectiveChallenges(
      {int limit = 10});

  Future<Result<void>> joinChallenge(String challengeId);

  Future<Result<void>> leaveChallenge(String challengeId);

  Future<Result<void>> createCollectiveChallenge(NewCollectiveChallenge data);

  /// Convite de duelo pendente mais recente recebido pelo usuário.
  Future<Result<DuelInvite?>> pendingDuelInvite();

  /// Estado do duelo aceito. Se alguém atingiu a meta, fecha o duelo,
  /// envia as notificações e retorna com `finished = true`.
  Future<Result<ActiveDuelStatus?>> checkActiveDuel();

  Future<Result<void>> sendDuelInvite({
    required String opponentId,
    required int targetXp,
    required DateTime expiresAt,
  });

  // ── Notificações ──

  Future<Result<List<ClubNotification>>> notifications({int limit = 50});

  Future<Result<void>> markAllNotificationsRead();

  Future<Result<void>> markNotificationRead(String id);

  // ── Perfil público ──

  Future<Result<PublicClubProfile>> publicProfile(String userId);

  /// Minha posição/XP no ranking (para o modal de duelo do perfil).
  Future<Result<ClubRankingEntry?>> myRankingEntry();

  // ── Detalhe do desafio ──

  /// Desafio com contagem de participantes (null se não existir).
  Future<Result<CollectiveChallenge?>> challengeDetail(String challengeId);

  Future<Result<ChallengeParticipation>> myParticipation(String challengeId);

  Future<Result<List<ChallengeContributor>>> topContributors(
      String challengeId, {int limit = 10});

  /// Feed recente dos participantes, com treino correlacionado (±30 s).
  Future<Result<List<ChallengeFeedItem>>> challengeFeed(String challengeId,
      {DateTime? since});

  Future<Result<List<ChallengeMilestone>>> milestones(String challengeId);

  Future<Result<List<ChallengeComment>>> comments(String challengeId,
      {int limit = 30});

  Future<Result<void>> addComment(String challengeId, String content);

  Future<Result<void>> reportChallenge(String challengeId, String reason);

  /// Desafios encerrados nos quais o usuário participou.
  Future<Result<List<PastChallengeEntry>>> pastChallenges({int limit = 20});

  /// Atualiza fontes permitidas e, opcionalmente, a meta (edição pelo criador).
  Future<Result<void>> updateChallengeSettings(
    String challengeId, {
    required List<String>? allowedSources,
    num? targetValue,
  });
}
