/// Item do feed de XP da comunidade (bldr_club.xp_events + perfil + reações).
class XpFeedItem {
  final String id;
  final String userId;
  final String userName;
  final String? avatarUrl;
  final String? reason;
  final DateTime? createdAt;
  final int xp;
  final int reactionCount;

  const XpFeedItem({
    required this.id,
    required this.userId,
    required this.userName,
    this.avatarUrl,
    this.reason,
    this.createdAt,
    this.xp = 0,
    this.reactionCount = 0,
  });
}

/// Posição no ranking do Club (bldr_club.club_ranking).
class ClubRankingEntry {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int xpTotal;
  final int currentLevel;

  const ClubRankingEntry({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    this.xpTotal = 0,
    this.currentLevel = 1,
  });
}

/// Duelo 1x1 de XP (bldr_club.user_challenges), já enriquecido com o
/// oponente e o progresso de ambos.
class Duel {
  final String id;
  final String opponentName;
  final String? opponentAvatar;
  final int targetXp;
  final String status; // pending | accepted | declined | ...
  final bool isSender;
  final int myProgress;
  final int opponentProgress;
  final String? winnerId;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  const Duel({
    required this.id,
    required this.opponentName,
    this.opponentAvatar,
    this.targetXp = 500,
    this.status = 'pending',
    this.isSender = false,
    this.myProgress = 0,
    this.opponentProgress = 0,
    this.winnerId,
    this.createdAt,
    this.expiresAt,
  });
}

/// Desafio coletivo (bldr_club.collective_challenges), com contagem de
/// participantes e se o usuário atual já entrou.
class CollectiveChallenge {
  final String id;
  final String title;
  final String? description;
  final String? challengeType;
  final num? targetValue;
  final num? currentValue;
  final int? rewardXp;
  final String? rewardBadge;
  final String? coverImageUrl;
  final DateTime? endsAt;
  final String status;
  final String? createdBy;
  final bool isOfficial;
  final int participantCount;
  final bool joined;
  final DateTime? createdAt;
  final List<String>? allowedSources;

  const CollectiveChallenge({
    required this.id,
    required this.title,
    this.description,
    this.challengeType,
    this.targetValue,
    this.currentValue,
    this.rewardXp,
    this.rewardBadge,
    this.coverImageUrl,
    this.endsAt,
    this.status = 'active',
    this.createdBy,
    this.isOfficial = false,
    this.participantCount = 0,
    this.joined = false,
    this.createdAt,
    this.allowedSources,
  });
}

/// Dados para criar um desafio coletivo.
class NewCollectiveChallenge {
  final String title;
  final String description;
  final String challengeType;
  final num targetValue;
  final int rewardXp;
  final String? rewardBadge;
  final DateTime endsAt;

  /// Caminho local da imagem de capa (feita upload pelo repositório).
  final String? coverImagePath;

  /// Fontes de progresso permitidas (null = todas).
  final List<String>? allowedSources;

  const NewCollectiveChallenge({
    required this.title,
    required this.description,
    required this.challengeType,
    required this.targetValue,
    required this.rewardXp,
    this.rewardBadge,
    required this.endsAt,
    this.coverImagePath,
    this.allowedSources,
  });
}

/// Participação do usuário atual num desafio coletivo.
class ChallengeParticipation {
  final bool joined;
  final int contribution;

  const ChallengeParticipation({this.joined = false, this.contribution = 0});
}

/// Participante no top do desafio.
class ChallengeContributor {
  final String userId;
  final String name;
  final String? avatarUrl;
  final int contribution;

  const ChallengeContributor({
    required this.userId,
    required this.name,
    this.avatarUrl,
    this.contribution = 0,
  });
}

/// Item do feed recente do desafio (evento de XP, com treino correlacionado
/// quando identificável).
class ChallengeFeedItem {
  final String userId;
  final String userName;
  final String? reason;
  final int delta;
  final DateTime? createdAt;

  /// Ex.: "Peito e Tríceps · 42 min" quando um treino coincide (±30 s).
  final String? activityLabel;

  const ChallengeFeedItem({
    required this.userId,
    required this.userName,
    this.reason,
    this.delta = 0,
    this.createdAt,
    this.activityLabel,
  });
}

/// Comentário no desafio coletivo.
class ChallengeComment {
  final String id;
  final String userId;
  final String userName;
  final String? avatarUrl;
  final String content;
  final DateTime? createdAt;

  const ChallengeComment({
    required this.id,
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.content,
    this.createdAt,
  });
}

/// Marco de progresso do desafio (25%, 50%…).
class ChallengeMilestone {
  final num milestonePct;
  final DateTime? reachedAt;

  const ChallengeMilestone({required this.milestonePct, this.reachedAt});
}

/// Convite de duelo pendente recebido.
class DuelInvite {
  final String id;
  final String senderName;
  final String? senderAvatar;

  const DuelInvite({
    required this.id,
    required this.senderName,
    this.senderAvatar,
  });
}

/// Estado do duelo aceito em andamento (ou recém-finalizado).
class ActiveDuelStatus {
  final bool finished;

  /// Válido quando [finished] — se o usuário atual venceu.
  final bool wonByMe;
  final int targetXp;
  final String opponentName;
  final String? opponentAvatar;
  final int opponentXp;
  final int myXp;

  const ActiveDuelStatus({
    this.finished = false,
    this.wonByMe = false,
    this.targetXp = 500,
    this.opponentName = 'Rival',
    this.opponentAvatar,
    this.opponentXp = 0,
    this.myXp = 0,
  });
}

/// Desafio encerrado no qual o usuário participou.
class PastChallengeEntry {
  final CollectiveChallenge challenge;
  final int myContribution;

  const PastChallengeEntry({
    required this.challenge,
    this.myContribution = 0,
  });
}

/// Notificação in-app do Club (bldr_club.notifications).
class ClubNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime? createdAt;
  final String? actionType;
  final Map<String, dynamic>? actionData;

  const ClubNotification({
    required this.id,
    required this.title,
    required this.message,
    this.type = 'info',
    this.isRead = false,
    this.createdAt,
    this.actionType,
    this.actionData,
  });
}

/// Perfil público de um membro do Club, com estatísticas agregadas.
class PublicClubProfile {
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final String? email;
  final int xpTotal;
  final int currentLevel;
  final int rankPosition; // 0 = fora do top consultado
  final int totalWorkouts;
  final int duelWins;
  final int duelLosses;
  final List<XpFeedItem> recentActivity;

  const PublicClubProfile({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    this.email,
    this.xpTotal = 0,
    this.currentLevel = 1,
    this.rankPosition = 0,
    this.totalWorkouts = 0,
    this.duelWins = 0,
    this.duelLosses = 0,
    this.recentActivity = const [],
  });
}
