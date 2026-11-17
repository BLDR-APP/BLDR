import 'package:bldr_fitness/features/analytics/domain/entities/workout_analytics.dart';
import 'package:bldr_fitness/features/integrations/domain/entities/canonical_health.dart';

class HealthMetricSeries {
  final String metric;
  final String unit;
  final List<num> values;
  const HealthMetricSeries(this.metric, this.unit, this.values);
  double? get average =>
      values.isEmpty ? null : values.reduce((a, b) => a + b) / values.length;
}

class AppleHealthActivitySummary {
  final int count;
  final int durationSeconds;
  final double distanceMeters;
  final double caloriesKcal;
  final double? averageHeartRateBpm;
  const AppleHealthActivitySummary(
      {required this.count,
      required this.durationSeconds,
      required this.distanceMeters,
      required this.caloriesKcal,
      this.averageHeartRateBpm});
}

class HealthRecoveryAnalyticsSummary {
  final WorkoutAnalyticsRange range;
  final CanonicalHealthAvailability availability;
  final int whoopDays;
  final Map<String, HealthMetricSeries> whoop;
  final AppleHealthActivitySummary appleHealth;
  const HealthRecoveryAnalyticsSummary(
      {required this.range,
      required this.availability,
      required this.whoopDays,
      required this.whoop,
      required this.appleHealth});
}
