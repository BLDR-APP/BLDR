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

  factory RankingEntry.fromRow(Map<String, dynamic> row, {String? currentUserId}) {
    final userId = row['user_id'] as String;
    return RankingEntry(
      position: (row['position'] as num).toInt(),
      userId: userId,
      displayName: (row['display_name'] as String?) ?? 'Atleta',
      avatarUrl: row['avatar_url'] as String?,
      value: (row['value'] as num).toDouble(),
      isMe: currentUserId != null && userId == currentUserId,
    );
  }
}
