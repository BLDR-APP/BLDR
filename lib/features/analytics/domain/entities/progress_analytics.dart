import 'package:bldr_fitness/features/analytics/domain/entities/workout_analytics.dart';

class BodyMeasurementSeries {
  final String measurementType;
  final String unit;
  final List<BodyMeasurementPoint> points;
  const BodyMeasurementSeries(
      {required this.measurementType,
      required this.unit,
      required this.points});
}

class BodyMeasurementPoint {
  final DateTime at;
  final double value;
  const BodyMeasurementPoint(this.at, this.value);
}

class ProgressMetricSummary {
  final BodyMeasurementSeries series;
  final double? latest;
  final double? first;
  final double? absoluteChange;
  final double? percentChange;
  const ProgressMetricSummary(
      {required this.series,
      this.latest,
      this.first,
      this.absoluteChange,
      this.percentChange});
}

class ProgressAnalyticsSummary {
  final WorkoutAnalyticsRange range;
  final Map<String, ProgressMetricSummary> measurements;
  const ProgressAnalyticsSummary(
      {required this.range, required this.measurements});
}
