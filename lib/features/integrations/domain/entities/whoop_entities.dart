class WhoopDailyData {
  final String userId;
  final DateTime date;
  final int? recoveryScore;
  final double? hrvRmssd;
  final int? restingHr;
  final double? strainScore;
  final int? sleepScore;
  final int? sleepDuration;
  final DateTime syncedAt;

  const WhoopDailyData({
    required this.userId,
    required this.date,
    this.recoveryScore,
    this.hrvRmssd,
    this.restingHr,
    this.strainScore,
    this.sleepScore,
    this.sleepDuration,
    required this.syncedAt,
  });

  @override
  String toString() =>
      'WhoopDailyData(recovery:$recoveryScore, strain:$strainScore, sleep:$sleepScore, hrv:$hrvRmssd, date:$date)';

  factory WhoopDailyData.fromMap(Map<String, dynamic> map) => WhoopDailyData(
        userId: map['user_id'] as String,
        date: DateTime.parse(map['date'] as String),
        recoveryScore: map['recovery_score'] as int?,
        hrvRmssd: (map['hrv_rmssd'] as num?)?.toDouble(),
        restingHr: map['resting_hr'] as int?,
        strainScore: (map['strain_score'] as num?)?.toDouble(),
        sleepScore: map['sleep_score'] as int?,
        sleepDuration: map['sleep_duration'] as int?,
        syncedAt: DateTime.parse(
            map['synced_at'] as String? ?? DateTime.now().toIso8601String()),
      );
}

class WhoopConnection {
  final bool isConnected;
  final String? whoopUserId;
  final DateTime? connectedAt;
  final DateTime? expiresAt;

  const WhoopConnection({
    required this.isConnected,
    this.whoopUserId,
    this.connectedAt,
    this.expiresAt,
  });

  const WhoopConnection.disconnected() : this(isConnected: false);

  factory WhoopConnection.fromMap(Map<String, dynamic> map) => WhoopConnection(
        isConnected: true,
        whoopUserId: map['whoop_user_id'] as String?,
        connectedAt: map['connected_at'] != null
            ? DateTime.parse(map['connected_at'] as String)
            : null,
        expiresAt: map['expires_at'] != null
            ? DateTime.parse(map['expires_at'] as String)
            : null,
      );
}
