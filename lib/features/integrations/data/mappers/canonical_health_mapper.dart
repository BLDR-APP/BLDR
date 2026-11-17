import 'package:bldr_fitness/features/integrations/domain/entities/canonical_health.dart';

class CanonicalHealthMapper {
  static CanonicalHealthDailySnapshot whoop(Map<String, dynamic> row) =>
      CanonicalHealthDailySnapshot(
        userId: row['user_id'].toString(),
        source: CanonicalHealthSource.whoop,
        sourceRecordId: row['id'].toString(),
        date: DateTime.parse(row['date'].toString()),
        syncedAt: DateTime.parse(row['synced_at'].toString()),
        recoveryScore: row['recovery_score'] as int?,
        hrvRmssd: (row['hrv_rmssd'] as num?)?.toDouble(),
        restingHeartRateBpm: row['resting_hr'] as int?,
        strainScore: (row['strain_score'] as num?)?.toDouble(),
        sleepScore: row['sleep_score'] as int?,
        sleepDurationMinutes: row['sleep_duration'] as int?,
      );

  static CanonicalHealthActivity appleHealth({
    required String userId,
    required Map<String, dynamic> row,
  }) =>
      CanonicalHealthActivity(
        userId: userId,
        source: CanonicalHealthSource.appleHealth,
        sourceRecordId: row['id'].toString(),
        activityType: row['activity_type']?.toString(),
        sourceName: row['source_name']?.toString(),
        startedAt: DateTime.parse(row['started_at'].toString()),
        endedAt: DateTime.parse(row['ended_at'].toString()),
        durationSeconds: row['duration_s'] as int?,
        activeEnergyKcal: (row['calories'] as num?)?.toDouble(),
        distanceMeters: (row['distance_km'] as num?)?.toDouble() == null
            ? null
            : (row['distance_km'] as num).toDouble() * 1000,
        averageHeartRateBpm: (row['average_heart_rate'] as num?)?.toDouble(),
      );
}
