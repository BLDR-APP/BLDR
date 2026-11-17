import 'package:bldr_fitness/features/analytics/domain/entities/progress_analytics.dart';
import 'package:bldr_fitness/features/analytics/domain/entities/workout_analytics.dart';
import 'package:bldr_fitness/features/progress/domain/entities/body_measurement.dart';

/// Analisa medições reais; não preenche lacunas nem infere composição corporal.
class ProgressAnalyticsEngine {
  const ProgressAnalyticsEngine();
  ProgressAnalyticsSummary summarize(
      {required WorkoutAnalyticsRange range,
      required Iterable<BodyMeasurement> measurements}) {
    final groups = <String, List<BodyMeasurement>>{};
    for (final measurement in measurements) {
      final at = measurement.measuredAt;
      if (at == null ||
          !range.contains(at) ||
          measurement.measurementType.isEmpty) {
        continue;
      }
      groups
          .putIfAbsent(measurement.measurementType, () => [])
          .add(measurement);
    }
    final values = <String, ProgressMetricSummary>{};
    for (final entry in groups.entries) {
      final rows = entry.value
        ..sort((a, b) => a.measuredAt!.compareTo(b.measuredAt!));
      final first = rows.first.value;
      final latest = rows.last.value;
      final series = BodyMeasurementSeries(
          measurementType: entry.key,
          unit: rows.last.unit,
          points: List.unmodifiable([
            for (final row in rows)
              BodyMeasurementPoint(row.measuredAt!, row.value)
          ]));
      values[entry.key] = ProgressMetricSummary(
          series: series,
          first: first,
          latest: latest,
          absoluteChange: latest - first,
          percentChange: first == 0 ? null : (latest - first) / first * 100);
    }
    return ProgressAnalyticsSummary(
        range: range, measurements: Map.unmodifiable(values));
  }
}
