import 'package:bldr_fitness/features/analytics/domain/entities/health_recovery_analytics.dart';
import 'package:bldr_fitness/features/analytics/domain/entities/workout_analytics.dart';
import 'package:bldr_fitness/features/integrations/domain/entities/canonical_health.dart';

class HealthRecoveryAnalyticsEngine {
  const HealthRecoveryAnalyticsEngine();
  HealthRecoveryAnalyticsSummary summarize(
      {required WorkoutAnalyticsRange range,
      required CanonicalHealthAvailability availability,
      required Iterable<CanonicalHealthDailySnapshot> snapshots,
      required Iterable<CanonicalHealthActivity> activities}) {
    final inRange = snapshots.where((s) => range.contains(s.date)).toList();
    List<num> values(num? Function(CanonicalHealthDailySnapshot s) pick) => [
          for (final s in inRange)
            if (pick(s) != null) pick(s)!
        ];
    final whoop = <String, HealthMetricSeries>{
      'recovery_score': HealthMetricSeries(
          'recovery_score', 'score', values((s) => s.recoveryScore)),
      'hrv_rmssd':
          HealthMetricSeries('hrv_rmssd', 'ms', values((s) => s.hrvRmssd)),
      'resting_heart_rate': HealthMetricSeries(
          'resting_heart_rate', 'bpm', values((s) => s.restingHeartRateBpm)),
      'strain':
          HealthMetricSeries('strain', 'score', values((s) => s.strainScore)),
      'sleep_score': HealthMetricSeries(
          'sleep_score', 'score', values((s) => s.sleepScore)),
      'sleep_duration': HealthMetricSeries(
          'sleep_duration', 'minutes', values((s) => s.sleepDurationMinutes)),
    };
    final apple = activities.where((a) => range.contains(a.startedAt)).toList();
    final hr = [
      for (final a in apple)
        if (a.averageHeartRateBpm != null) a.averageHeartRateBpm!
    ];
    return HealthRecoveryAnalyticsSummary(
        range: range,
        availability: availability,
        whoopDays: inRange.length,
        whoop: Map.unmodifiable(whoop),
        appleHealth: AppleHealthActivitySummary(
            count: apple.length,
            durationSeconds:
                apple.fold(0, (v, a) => v + (a.durationSeconds ?? 0)),
            distanceMeters:
                apple.fold(0, (v, a) => v + (a.distanceMeters ?? 0)),
            caloriesKcal:
                apple.fold(0, (v, a) => v + (a.activeEnergyKcal ?? 0)),
            averageHeartRateBpm:
                hr.isEmpty ? null : hr.reduce((a, b) => a + b) / hr.length));
  }
}
