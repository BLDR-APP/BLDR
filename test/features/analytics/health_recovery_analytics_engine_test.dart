import 'package:bldr_fitness/features/analytics/domain/entities/workout_analytics.dart';
import 'package:bldr_fitness/features/analytics/domain/services/health_recovery_analytics_engine.dart';
import 'package:bldr_fitness/features/integrations/domain/entities/canonical_health.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final r = WorkoutAnalyticsRange(
      start: DateTime.utc(2026, 9, 1), end: DateTime.utc(2026, 9, 8));
  test('preserves WHOOP units and disconnected state', () {
    final x = const HealthRecoveryAnalyticsEngine().summarize(
        range: r,
        availability: CanonicalHealthAvailability.disconnected,
        snapshots: [],
        activities: []);
    expect(x.availability, CanonicalHealthAvailability.disconnected);
    expect(x.whoop['hrv_rmssd']!.unit, 'ms');
  });
  test('keeps WHOOP and Apple Health separate', () {
    final s = CanonicalHealthDailySnapshot(
        userId: 'u',
        source: CanonicalHealthSource.whoop,
        sourceRecordId: 'w',
        date: DateTime.utc(2026, 9, 2),
        syncedAt: DateTime.utc(2026, 9, 2),
        recoveryScore: 80,
        hrvRmssd: 50);
    final a = CanonicalHealthActivity(
        userId: 'u',
        source: CanonicalHealthSource.appleHealth,
        sourceRecordId: 'a',
        startedAt: DateTime.utc(2026, 9, 2),
        endedAt: DateTime.utc(2026, 9, 2, 1),
        durationSeconds: 3600,
        distanceMeters: 5000,
        activeEnergyKcal: 400,
        averageHeartRateBpm: 140);
    final x = const HealthRecoveryAnalyticsEngine().summarize(
        range: r,
        availability: CanonicalHealthAvailability.data,
        snapshots: [s],
        activities: [a]);
    expect(x.whoopDays, 1);
    expect(x.whoop['recovery_score']!.average, 80);
    expect(x.appleHealth.count, 1);
    expect(x.appleHealth.distanceMeters, 5000);
  });
}
