enum CommunityEventType {
  workoutCompleted,
  prBeaten,
  streakMilestone,
  levelUp,
  squadJoined,
  challengeCompleted,
  manual,
}

class CommunityPost {
  final String id;
  final String userId;
  final String? username;
  final String? userFullName;
  final String? userAvatarUrl;
  final CommunityEventType eventType;
  final Map<String, dynamic> payload;
  final String visibility;
  final DateTime createdAt;
  final List<CommunityReaction> reactions;
  final int commentCount;
  final String? myReactionEmoji;

  const CommunityPost({
    required this.id,
    required this.userId,
    this.username,
    this.userFullName,
    this.userAvatarUrl,
    required this.eventType,
    required this.payload,
    required this.visibility,
    required this.createdAt,
    this.reactions = const [],
    this.commentCount = 0,
    this.myReactionEmoji,
  });

  String get workoutName => payload['workout_name'] as String? ?? 'Treino concluído';
  int? get durationSeconds => payload['duration_s'] as int?;
  double? get volumeKg => (payload['volume_kg'] as num?)?.toDouble();
  List<String> get muscleGroups =>
      (payload['muscle_groups'] as List?)?.cast<String>() ?? [];
  String? get exerciseName => payload['exercise_name'] as String?;
  double? get prWeightKg => (payload['weight_kg'] as num?)?.toDouble();
  int? get prReps => payload['reps'] as int?;
  double? get e1rm => (payload['e1rm'] as num?)?.toDouble();
  int? get streakDays => payload['days'] as int?;
  String? get caption => payload['caption'] as String?;
  String? get photoUrl => payload['photo_url'] as String?;
  String? get activityType => payload['activity_type'] as String?;

  String get displayName => username != null ? '@$username' : (userFullName ?? 'Atleta');
  String get authorName => userFullName ?? username ?? 'Atleta';

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final profile = json['user_profiles'] as Map<String, dynamic>?;
    return CommunityPost(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: profile?['username'] as String?,
      userFullName: profile?['full_name'] as String?,
      userAvatarUrl: profile?['avatar_url'] as String?,
      eventType: _parseEventType(json['event_type'] as String),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      visibility: json['visibility'] as String? ?? 'public',
      createdAt: DateTime.parse(json['created_at'] as String),
      reactions: (json['reactions'] as List?)
              ?.map((r) => CommunityReaction.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      commentCount: json['comment_count'] as int? ?? 0,
      myReactionEmoji: json['my_reaction'] as String?,
    );
  }

  static CommunityEventType _parseEventType(String raw) {
    switch (raw) {
      case 'workout_completed':
        return CommunityEventType.workoutCompleted;
      case 'pr_beaten':
        return CommunityEventType.prBeaten;
      case 'streak_milestone':
        return CommunityEventType.streakMilestone;
      case 'level_up':
        return CommunityEventType.levelUp;
      case 'squad_joined':
        return CommunityEventType.squadJoined;
      case 'challenge_completed':
        return CommunityEventType.challengeCompleted;
      default:
        return CommunityEventType.manual;
    }
  }
}

class CommunityReaction {
  final String emoji;
  final int count;

  const CommunityReaction({required this.emoji, required this.count});

  factory CommunityReaction.fromJson(Map<String, dynamic> json) =>
      CommunityReaction(
        emoji: json['emoji'] as String,
        count: json['count'] as int,
      );
}
