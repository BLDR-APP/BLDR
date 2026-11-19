import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/analytics/domain/entities/ai_tool_contracts.dart';
import 'package:bldr_fitness/features/analytics/domain/services/ai_analytics_tools.dart';
import 'package:bldr_fitness/features/analytics/domain/services/analytics_queries.dart';
import 'package:bldr_fitness/features/integrations/domain/entities/canonical_health.dart';
import 'package:bldr_fitness/features/integrations/domain/repositories/canonical_health_reader.dart';
import 'package:bldr_fitness/features/progress/domain/entities/body_measurement.dart';
import 'package:bldr_fitness/features/progress/domain/repositories/progress_repository.dart';
import 'package:bldr_fitness/features/workouts/domain/repositories/canonical_workout_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final arguments = AiToolArguments(
    period: AiToolPeriod(
      start: DateTime.utc(2026, 1, 1),
      end: DateTime.utc(2026, 1, 8),
    ),
  );
  const context = AiToolExecutionContext(userId: 'u');

  test('workout tool delegates only to the canonical workout query', () async {
    final reader = _WorkoutReader();
    final result = await WorkoutAnalyticsTool(WorkoutAnalyticsQuery(reader))
        .execute(context, arguments);

    expect(result.status, AiToolStatus.empty);
    expect(result.sources, ['canonical_workout']);
    expect(reader.userIds, ['u']);
    expect(result.metrics['completedSessions'], 0);
  });

  test('progress tool preserves measurements returned by the query', () async {
    final repository = _ProgressRepository();
    final result =
        await ProgressAnalyticsTool(ProgressAnalyticsQuery(repository))
            .execute(context, arguments);

    final measurements = result.metrics['measurements'] as Map<String, Object?>;
    expect(result.status, AiToolStatus.success);
    expect(measurements['weight'], isNotNull);
    expect(repository.calls, 1);
  });

  test('health tool preserves independent provider state and provenance',
      () async {
    final result = await HealthRecoveryAnalyticsTool(
      HealthRecoveryAnalyticsQuery(_HealthReader()),
    ).execute(context, arguments);

    final whoop = result.metrics['whoop'] as Map<String, Object?>;
    expect(result.status, AiToolStatus.success);
    expect(whoop['state'], 'data');
    expect(result.sources, ['whoop_daily_data', 'apple_health']);
  });

  test('nutrition tool reports historical unavailability without metrics',
      () async {
    final result = await const NutritionAnalyticsTool(NutritionAnalyticsQuery())
        .execute(context, arguments);

    expect(result.status, AiToolStatus.unavailable);
    expect(result.metrics, isEmpty);
    expect(result.failure!.code, 'ValidationFailure');
  });
}

class _WorkoutReader implements CanonicalWorkoutReader {
  final List<String> userIds = [];

  @override
  Future<Result<CanonicalWorkoutPage>> history({
    required String userId,
    CanonicalWorkoutCursor? cursor,
    int limit = 20,
  }) async {
    userIds.add(userId);
    return const Result.success(
      CanonicalWorkoutPage(sessions: [], hasMore: false),
    );
  }
}

class _ProgressRepository implements ProgressRepository {
  int calls = 0;

  @override
  Future<Result<List<BodyMeasurement>>> measurements({
    String? measurementType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    calls++;
    return Result.success([
      BodyMeasurement(
        id: 'weight-1',
        measurementType: 'weight',
        value: 80,
        unit: 'kg',
        measuredAt: DateTime.utc(2026, 1, 2),
      ),
    ]);
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
  Future<Result<BodyMeasurement>> recordMeasurement(
          BodyMeasurement measurement) =>
      throw UnimplementedError();
  @override
  Future<Result<void>> removeWater(int amountMl) => throw UnimplementedError();
}

class _HealthReader implements CanonicalHealthReader {
  @override
  Future<Result<List<CanonicalHealthActivity>>> appleHealthActivities({
    required String userId,
    Duration lookback = const Duration(days: 7),
    int limit = 20,
  }) async =>
      const Result.success([]);

  @override
  Future<Result<CanonicalHealthDailyPage>> whoopDailySnapshots({
    required String userId,
    required DateTime start,
    required DateTime end,
    DateTime? beforeDate,
    int limit = 30,
  }) async =>
      Result.success(
        CanonicalHealthDailyPage(
          availability: CanonicalHealthAvailability.data,
          snapshots: [
            CanonicalHealthDailySnapshot(
              userId: userId,
              source: CanonicalHealthSource.whoop,
              sourceRecordId: 'whoop-1',
              date: DateTime.utc(2026, 1, 2),
              syncedAt: DateTime.utc(2026, 1, 2),
              recoveryScore: 80,
            ),
          ],
        ),
      );
}
