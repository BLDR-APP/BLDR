/// Anúncio do BLDR Club (Supabase `club_announcements`).
class ClubAnnouncement {
  final String? id;
  final String title;
  final String? imageUrl;
  final String? imageUrlMain;
  final String? linkUrl;
  final DateTime? createdAt;

  const ClubAnnouncement({
    this.id,
    required this.title,
    this.imageUrl,
    this.imageUrlMain,
    this.linkUrl,
    this.createdAt,
  });
}

/// Evento do BLDR Club (Supabase `club_events`).
class ClubEvent {
  final String? id;
  final String title;
  final String? imageUrl;
  final String? linkUrl;
  final DateTime? createdAt;

  const ClubEvent({
    this.id,
    required this.title,
    this.imageUrl,
    this.linkUrl,
    this.createdAt,
  });
}

/// Atividade avulsa registrada no Club (corrida, esporte…).
class ClubActivity {
  final String? id;
  final String activityType;
  final DateTime? createdAt;

  const ClubActivity({this.id, required this.activityType, this.createdAt});
}

/// Sessão de partida salva (bldr_club.match_sessions).
class MatchSession {
  final String? id;
  final String modality;
  final String result; // 'win' | 'loss' | 'draw'
  final List<Map<String, dynamic>> sets;
  final int? intensity;
  final int? durationSec;
  final DateTime? playedAt;

  const MatchSession({
    this.id,
    required this.modality,
    required this.result,
    this.sets = const [],
    this.intensity,
    this.durationSec,
    this.playedAt,
  });
}

/// Operação semanal global (bldr_club.weekly_operations).
class WeeklyOperation {
  final String id;
  final String title;
  final String? description;
  final String goalType; // 'workout_count' | 'run_distance' | 'calorie_goal'
  final int goalValue;
  final int xpReward;
  final DateTime weekStart;
  final DateTime weekEnd;

  const WeeklyOperation({
    required this.id,
    required this.title,
    this.description,
    required this.goalType,
    required this.goalValue,
    required this.xpReward,
    required this.weekStart,
    required this.weekEnd,
  });
}

/// Progresso do usuário em uma operação (bldr_club.operation_progress).
class OperationProgress {
  final String id;
  final String userId;
  final String operationId;
  final int currentValue;
  final bool completed;
  final DateTime? completedAt;

  const OperationProgress({
    required this.id,
    required this.userId,
    required this.operationId,
    required this.currentValue,
    required this.completed,
    this.completedAt,
  });
}

/// Corrida GPS registrada (bldr_club.user_activities).
class RunActivity {
  final String? id;
  final String? title;
  final num? distanceMeters;
  final int? durationSeconds;
  final String? paceText;
  final int? earnedXp;
  final DateTime? createdAt;

  /// Pontos da rota como gravados ([{lat, lng}]).
  final List<Map<String, dynamic>> routeData;

  const RunActivity({
    this.id,
    this.title,
    this.distanceMeters,
    this.durationSeconds,
    this.paceText,
    this.earnedXp,
    this.createdAt,
    this.routeData = const [],
  });
}
