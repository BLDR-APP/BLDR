class CommunityProfile {
  final String id;
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final bool isFollowing;

  const CommunityProfile({
    required this.id,
    this.username,
    this.fullName,
    this.avatarUrl,
    this.isFollowing = false,
  });

  String get displayName => fullName?.trim().isNotEmpty == true
      ? fullName!
      : username?.trim().isNotEmpty == true
          ? username!
          : 'Atleta';

  CommunityProfile copyWith({bool? isFollowing}) => CommunityProfile(
        id: id,
        username: username,
        fullName: fullName,
        avatarUrl: avatarUrl,
        isFollowing: isFollowing ?? this.isFollowing,
      );
}
