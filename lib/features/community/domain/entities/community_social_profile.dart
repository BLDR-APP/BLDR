/// Dados do perfil social (Figma 56:855).
class CommunitySocialProfile {
  final String id;
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final String? city;
  final bool isClubMember;
  final bool isFollowing;

  const CommunitySocialProfile({
    required this.id,
    this.username,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.city,
    this.isClubMember = false,
    this.isFollowing = false,
  });

  String get displayName => fullName?.trim().isNotEmpty == true
      ? fullName!.trim()
      : username?.trim().isNotEmpty == true
          ? username!.trim()
          : 'Atleta';

  CommunitySocialProfile copyWith({bool? isFollowing}) =>
      CommunitySocialProfile(
        id: id,
        username: username,
        fullName: fullName,
        avatarUrl: avatarUrl,
        bio: bio,
        city: city,
        isClubMember: isClubMember,
        isFollowing: isFollowing ?? this.isFollowing,
      );
}

/// Contadores do perfil (RPC `follow_counts`).
class CommunityFollowCounts {
  final int followers;
  final int following;

  const CommunityFollowCounts({this.followers = 0, this.following = 0});

  factory CommunityFollowCounts.fromRow(Map<String, dynamic> row) =>
      CommunityFollowCounts(
        followers: (row['followers'] as num?)?.toInt() ?? 0,
        following: (row['following'] as num?)?.toInt() ?? 0,
      );

  /// Ajuste local depois de seguir ou deixar de seguir.
  CommunityFollowCounts withFollower({required bool added}) =>
      CommunityFollowCounts(
        followers: (followers + (added ? 1 : -1)).clamp(0, 1 << 31).toInt(),
        following: following,
      );
}

/// Melhor marca de um exercício no perfil.
class CommunityProfilePr {
  final String exercise;
  final double weightKg;
  final int reps;
  final double e1rm;

  const CommunityProfilePr({
    required this.exercise,
    required this.weightKg,
    required this.reps,
    required this.e1rm,
  });

  factory CommunityProfilePr.fromJson(Map<String, dynamic> json) =>
      CommunityProfilePr(
        exercise: json['exercise'] as String,
        weightKg: (json['weight_kg'] as num).toDouble(),
        reps: (json['reps'] as num).toInt(),
        e1rm: (json['e1rm'] as num).toDouble(),
      );
}

/// Estatísticas públicas do perfil (RPC `public_profile_stats`).
class CommunityProfileStats {
  final List<CommunityProfilePr> bestPrs;
  final int activeWeeks;
  final List<String> achievements;

  const CommunityProfileStats({
    this.bestPrs = const [],
    this.activeWeeks = 0,
    this.achievements = const [],
  });

  factory CommunityProfileStats.fromRow(Map<String, dynamic> row) =>
      CommunityProfileStats(
        bestPrs: [
          for (final item in (row['best_prs'] as List? ?? const []))
            CommunityProfilePr.fromJson(Map<String, dynamic>.from(item as Map)),
        ],
        activeWeeks: (row['active_weeks'] as num?)?.toInt() ?? 0,
        achievements: [
          for (final item in (row['achievements'] as List? ?? const []))
            (item as Map)['name'] as String,
        ],
      );
}
