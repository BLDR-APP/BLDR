enum CanonicalHealthSource { whoop, appleHealth }

enum CanonicalHealthAvailability { data, empty, disconnected }

class CanonicalHealthDailySnapshot {
  final String userId;
  final CanonicalHealthSource source;
  final String sourceRecordId;
  final DateTime date;
  final DateTime syncedAt;
  final int? recoveryScore;
  final double? hrvRmssd;
  final int? restingHeartRateBpm;
  final double? strainScore;
  final int? sleepScore;
  final int? sleepDurationMinutes;

  const CanonicalHealthDailySnapshot({
    required this.userId,
    required this.source,
    required this.sourceRecordId,
    required this.date,
    required this.syncedAt,
    this.recoveryScore,
    this.hrvRmssd,
    this.restingHeartRateBpm,
    this.strainScore,
    this.sleepScore,
    this.sleepDurationMinutes,
  });
}

class CanonicalHealthActivity {
  final String userId;
  final CanonicalHealthSource source;
  final String sourceRecordId;
  final String? activityType;
  final String? sourceName;
  final DateTime startedAt;
  final DateTime endedAt;
  final int? durationSeconds;
  final double? activeEnergyKcal;
  final double? distanceMeters;
  final double? averageHeartRateBpm;

  const CanonicalHealthActivity({
    required this.userId,
    required this.source,
    required this.sourceRecordId,
    required this.startedAt,
    required this.endedAt,
    this.activityType,
    this.sourceName,
    this.durationSeconds,
    this.activeEnergyKcal,
    this.distanceMeters,
    this.averageHeartRateBpm,
  });
}

class CanonicalHealthDailyPage {
  final CanonicalHealthAvailability availability;
  final List<CanonicalHealthDailySnapshot> snapshots;
  final DateTime? nextBeforeDate;

  const CanonicalHealthDailyPage({
    required this.availability,
    required this.snapshots,
    this.nextBeforeDate,
  });
}
