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
