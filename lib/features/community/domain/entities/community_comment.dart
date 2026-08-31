class CommunityComment {
  final String id;
  final String feedId;
  final String userId;
  final String? parentId;
  final String body;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final bool canEdit;
  final bool canDelete;
  final List<CommunityComment> replies;

  const CommunityComment({
    required this.id,
    required this.feedId,
    required this.userId,
    this.parentId,
    required this.body,
    required this.createdAt,
    this.updatedAt,
    this.username,
    this.fullName,
    this.avatarUrl,
    this.canEdit = false,
    this.canDelete = false,
    this.replies = const [],
  });

  String get authorName => fullName ?? username ?? 'Atleta';
  bool get wasEdited => updatedAt != null && updatedAt!.isAfter(createdAt);

  CommunityComment copyWith({List<CommunityComment>? replies}) =>
      CommunityComment(
        id: id,
        feedId: feedId,
        userId: userId,
        parentId: parentId,
        body: body,
        createdAt: createdAt,
        updatedAt: updatedAt,
        username: username,
        fullName: fullName,
        avatarUrl: avatarUrl,
        canEdit: canEdit,
        canDelete: canDelete,
        replies: replies ?? this.replies,
      );
}
