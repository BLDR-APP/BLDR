import 'package:bldr_fitness/features/community/domain/entities/community_post_payload.dart';

enum CommunityEventType {
  workoutCompleted,
  prBeaten,
  streakMilestone,
  levelUp,
  squadJoined,
  challengeCompleted,
  activityCompleted,
  wearableActivity,
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
  final String? squadId;
  final DateTime createdAt;
  final List<CommunityReaction> reactions;
  final int commentCount;
  final String? myReactionEmoji;
  final bool isClubMember;
  final bool isFollowing;
  final bool isOwnPost;

  const CommunityPost({
    required this.id,
    required this.userId,
    this.username,
    this.userFullName,
    this.userAvatarUrl,
    required this.eventType,
    required this.payload,
    required this.visibility,
    this.squadId,
    required this.createdAt,
    this.reactions = const [],
    this.commentCount = 0,
    this.myReactionEmoji,
    this.isClubMember = false,
    this.isFollowing = false,
    this.isOwnPost = false,
  });

  CommunityPost copyWith({
    List<CommunityReaction>? reactions,
    String? myReactionEmoji,
    bool clearMyReaction = false,
    bool? isFollowing,
  }) =>
      CommunityPost(
        id: id,
        userId: userId,
        username: username,
        userFullName: userFullName,
        userAvatarUrl: userAvatarUrl,
        eventType: eventType,
        payload: payload,
        visibility: visibility,
        squadId: squadId,
        createdAt: createdAt,
        reactions: reactions ?? this.reactions,
        commentCount: commentCount,
        myReactionEmoji:
            clearMyReaction ? null : myReactionEmoji ?? this.myReactionEmoji,
        isClubMember: isClubMember,
        isFollowing: isFollowing ?? this.isFollowing,
        isOwnPost: isOwnPost,
      );

  String get workoutName =>
      payload['workout_name'] as String? ?? 'Treino concluído';
  int? get durationSeconds => payload['duration_s'] as int?;
  double? get volumeKg => (payload['volume_kg'] as num?)?.toDouble();
  int? get completedSetCount => (payload['set_count'] as num?)?.toInt();
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
  CommunityPostPayload get typedPayload =>
      CommunityPostPayload.fromJson(payload);

  String get displayName =>
      username != null ? '@$username' : (userFullName ?? 'Atleta');
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
      squadId: json['squad_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      reactions: (json['reactions'] as List?)
              ?.map(
                  (r) => CommunityReaction.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      commentCount: json['comment_count'] as int? ?? 0,
      myReactionEmoji: json['my_reaction'] as String?,
      isClubMember: json['is_club_member'] as bool? ?? false,
      isFollowing: json['is_following'] as bool? ?? false,
      isOwnPost: json['is_own_post'] as bool? ?? false,
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
      case 'activity_completed':
        return CommunityEventType.activityCompleted;
      case 'wearable_activity':
        return CommunityEventType.wearableActivity;
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
