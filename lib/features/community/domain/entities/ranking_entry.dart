class RankingEntry {
  final int position;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final double value;
  final bool isMe;

  const RankingEntry({
    required this.position,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.value,
    this.isMe = false,
  });

  // RPCs retornam: user_id, full_name, username, avatar_url, total
  // position é calculado externamente pelo índice da lista.
  factory RankingEntry.fromRow(
    Map<String, dynamic> row, {
    String? currentUserId,
    int position = 0,
  }) {
    final userId = row['user_id'] as String;
    final displayName = (row['full_name'] as String?)?.isNotEmpty == true
        ? row['full_name'] as String
        : (row['username'] as String?) ?? 'Atleta';
    return RankingEntry(
      position: position,
      userId: userId,
      displayName: displayName,
      avatarUrl: row['avatar_url'] as String?,
      value: (row['total'] as num?)?.toDouble() ?? 0.0,
      isMe: currentUserId != null && userId == currentUserId,
    );
  }
}
