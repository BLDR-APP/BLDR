import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/analytics/domain/entities/workout_analytics.dart';
import 'package:bldr_fitness/features/analytics/domain/services/analytics_queries.dart';
import 'package:bldr_fitness/features/progress/domain/entities/body_measurement.dart';
import 'package:bldr_fitness/features/progress/domain/repositories/progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final range = WorkoutAnalyticsRange(
    start: DateTime.utc(2026, 9, 1),
    end: DateTime.utc(2026, 10, 1),
  );

  test('returns a valid empty summary for empty history', () async {
    final repository = _Repository(const Result.success([]));

    final result = await ProgressAnalyticsQuery(repository).call(range: range);

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.measurements, isEmpty);
  });

  test('passes interval and explicit limit to the existing measurements source',
      () async {
    final repository = _Repository(Result.success([
      _measurement('weight', 80, 'kg', DateTime.utc(2026, 9, 2)),
    ]));

    final result = await ProgressAnalyticsQuery(repository).call(
      range: range,
      limit: 25,
    );

    expect(result.isSuccess, isTrue);
    expect(repository.startDate, range.start);
    expect(repository.endDate, range.end);
    expect(repository.limit, 25);
  });

  test('preserves dates, units, and distinct measurement types', () async {
    final result = await ProgressAnalyticsQuery(_Repository(Result.success([
      _measurement('weight', 80, 'kg', DateTime.utc(2026, 9, 2)),
      _measurement('body_fat', 20, '%', DateTime.utc(2026, 9, 3)),
      _measurement('muscle_mass', 35, 'kg', DateTime.utc(2026, 9, 4)),
    ]))).call(range: range);

    final measurements = result.valueOrNull!.measurements;
    expect(measurements['weight']!.series.unit, 'kg');
    expect(measurements['weight']!.series.points.single.at,
        DateTime.utc(2026, 9, 2));
    expect(measurements['body_fat']!.series.unit, '%');
    expect(measurements['muscle_mass']!.latest, 35);
  });

  test('filters values outside the requested interval in the engine', () async {
    final result = await ProgressAnalyticsQuery(_Repository(Result.success([
      _measurement('weight', 80, 'kg', DateTime.utc(2026, 9, 2)),
      _measurement('weight', 70, 'kg', DateTime.utc(2026, 10, 1)),
    ]))).call(range: range);

    expect(result.valueOrNull!.measurements['weight']!.latest, 80);
  });

  test('rejects invalid intervals and limits without reading the repository',
      () async {
    final repository = _Repository(const Result.success([]));
    final invalidRange = WorkoutAnalyticsRange(
      start: range.end,
      end: range.start,
    );

    final invalidRangeResult =
        await ProgressAnalyticsQuery(repository).call(range: invalidRange);
    final invalidLimitResult =
        await ProgressAnalyticsQuery(repository).call(range: range, limit: 0);

    expect(invalidRangeResult.failureOrNull, isA<ValidationFailure>());
    expect(invalidLimitResult.failureOrNull, isA<ValidationFailure>());
    expect(repository.calls, 0);
  });

  test('propagates authentication and user-isolation failures', () async {
    final authentication = await ProgressAnalyticsQuery(
      _Repository(
          const Result.failure(AuthFailure('Usuário não autenticado.'))),
    ).call(range: range);
    final isolation = await ProgressAnalyticsQuery(
      _Repository(const Result.failure(AuthFailure('Acesso negado.'))),
    ).call(range: range);

    expect(authentication.failureOrNull, isA<AuthFailure>());
    expect(isolation.failureOrNull, isA<AuthFailure>());
  });

  test('propagates typed datasource failures unchanged', () async {
    final result = await ProgressAnalyticsQuery(
      _Repository(const Result.failure(NetworkFailure())),
    ).call(range: range);

    expect(result.failureOrNull, isA<NetworkFailure>());
  });

  test('uses the Progress Analytics Engine for same-type comparison', () async {
    final result = await ProgressAnalyticsQuery(_Repository(Result.success([
      _measurement('weight', 80, 'kg', DateTime.utc(2026, 9, 2)),
      _measurement('weight', 78, 'kg', DateTime.utc(2026, 9, 20)),
      _measurement('body_fat', 20, '%', DateTime.utc(2026, 9, 2)),
    ]))).call(range: range);

    final weight = result.valueOrNull!.measurements['weight']!;
    expect(weight.absoluteChange, -2);
    expect(weight.percentChange, -2.5);
    expect(result.valueOrNull!.measurements['body_fat']!.latest, 20);
  });
}

BodyMeasurement _measurement(
  String type,
  double value,
  String unit,
  DateTime at,
) =>
    BodyMeasurement(
      id: '$type-${at.toIso8601String()}',
      measurementType: type,
      value: value,
      unit: unit,
      measuredAt: at,
    );

class _Repository implements ProgressRepository {
  final Result<List<BodyMeasurement>> result;
  DateTime? startDate;
  DateTime? endDate;
  int? limit;
  int calls = 0;

  _Repository(this.result);

  @override
  Future<Result<List<BodyMeasurement>>> measurements({
    String? measurementType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    calls++;
    this.startDate = startDate;
    this.endDate = endDate;
    this.limit = limit;
    return result;
  }

  @override
  Future<Result<void>> deleteMeasurement(String id) =>
      throw UnimplementedError();

  @override
  Future<Result<DailyWaterIntake>> dailyWaterIntake(DateTime date) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> logWater(int amountMl) => throw UnimplementedError();

  @override
  Future<Result<MeasurementProgress>> measurementProgress({
    required String measurementType,
    int daysPeriod = 30,
  }) =>
      throw UnimplementedError();

  @override
  Future<Result<BodyMeasurement>> recordMeasurement(BodyMeasurement m) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> removeWater(int amountMl) => throw UnimplementedError();
}
