import 'package:bldr_fitness/features/analytics/domain/entities/workout_analytics.dart';
import 'package:bldr_fitness/features/analytics/domain/services/progress_analytics_engine.dart';
import 'package:bldr_fitness/features/progress/domain/entities/body_measurement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final range = WorkoutAnalyticsRange(
      start: DateTime.utc(2026, 9, 1), end: DateTime.utc(2026, 10, 1));
  BodyMeasurement m(String t, double v, String d) => BodyMeasurement(
      measurementType: t,
      value: v,
      unit: t == 'weight' ? 'kg' : '%',
      measuredAt: DateTime.parse('${d}T12:00:00Z'));
  test('preserves measured series and calculates only same-type changes', () {
    final r =
        const ProgressAnalyticsEngine().summarize(range: range, measurements: [
      m('weight', 80, '2026-09-02'),
      m('weight', 78, '2026-09-20'),
      m('body_fat', 20, '2026-09-02')
    ]);
    expect(r.measurements['weight']!.absoluteChange, -2);
    expect(r.measurements['weight']!.percentChange, -2.5);
    expect(r.measurements['body_fat']!.latest, 20);
  });
  test('keeps missing measurements absent rather than zero', () {
    final r = const ProgressAnalyticsEngine()
        .summarize(range: range, measurements: []);
    expect(r.measurements, isEmpty);
  });
}
