import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/features/analytics/domain/entities/ai_tool_contracts.dart';
import 'package:bldr_fitness/features/analytics/domain/entities/workout_analytics.dart';
import 'package:bldr_fitness/features/analytics/domain/services/analytics_queries.dart';

const workoutAnalyticsToolId = 'getWorkoutAnalytics';
const progressAnalyticsToolId = 'getProgressAnalytics';
const healthRecoveryAnalyticsToolId = 'getHealthRecoveryAnalytics';
const nutritionAnalyticsToolId = 'getNutritionAnalytics';

WorkoutAnalyticsRange _range(AiToolArguments arguments) =>
    WorkoutAnalyticsRange(
      start: arguments.period.start,
      end: arguments.period.end,
    );

AiToolResult _failure(
        String toolId, AiToolArguments arguments, Failure failure) =>
    AiToolResult(
      toolId: toolId,
      status: AiToolStatus.failure,
      period: arguments.period,
      failure: AiToolFailure.fromFailure(failure),
    );

class WorkoutAnalyticsTool implements AiAnalyticsTool {
  final WorkoutAnalyticsQuery _query;

  const WorkoutAnalyticsTool(this._query);

  @override
  String get id => workoutAnalyticsToolId;

  @override
  Future<AiToolResult> execute(
    AiToolExecutionContext context,
    AiToolArguments arguments,
  ) async {
    final result = await _query.call(
      userId: context.userId,
      range: _range(arguments),
      comparePreviousPeriod: arguments.comparePreviousPeriod,
      pageSize: arguments.pageSize ?? 50,
      maxPages: arguments.maxPages ?? 50,
    );
    if (result.isFailure) return _failure(id, arguments, result.failureOrNull!);
    final summary = result.valueOrNull!;
    return AiToolResult(
      toolId: id,
      status: summary.hasData ? AiToolStatus.success : AiToolStatus.empty,
      period: arguments.period,
      sources: const ['canonical_workout'],
      metrics: {
        'completedSessions': summary.completedSessions,
        'activeDays': summary.activeDays,
        'weeklyFrequency': summary.weeklyFrequency,
        'consistencyPercent': summary.consistencyPercent,
        'totalVolumeKg': summary.totalVolumeKg,
        'averageDurationSeconds': summary.averageDurationSeconds,
        'volumeByMuscleGroup': summary.volumeByMuscleGroup,
        'completedSetsByExercise': summary.completedSetsByExercise,
        'previousPeriodVolumeKg': summary.previousPeriodVolumeKg,
        'volumeDeltaPercent': summary.volumeDeltaPercent,
      },
    );
  }
}

class ProgressAnalyticsTool implements AiAnalyticsTool {
  final ProgressAnalyticsQuery _query;

  const ProgressAnalyticsTool(this._query);

  @override
  String get id => progressAnalyticsToolId;

  @override
  Future<AiToolResult> execute(
    AiToolExecutionContext context,
    AiToolArguments arguments,
  ) async {
    final result = await _query.call(
      range: _range(arguments),
      limit: arguments.limit ?? 50,
    );
    if (result.isFailure) return _failure(id, arguments, result.failureOrNull!);
    final summary = result.valueOrNull!;
    return AiToolResult(
      toolId: id,
      status: summary.measurements.isEmpty
          ? AiToolStatus.empty
          : AiToolStatus.success,
      period: arguments.period,
      sources: const ['user_measurements'],
      metrics: {
        'measurements': {
          for (final entry in summary.measurements.entries)
            entry.key: {
              'unit': entry.value.series.unit,
              'first': entry.value.first,
              'latest': entry.value.latest,
              'absoluteChange': entry.value.absoluteChange,
              'percentChange': entry.value.percentChange,
              'points': [
                for (final point in entry.value.series.points)
                  {
                    'at': point.at.toUtc().toIso8601String(),
                    'value': point.value,
                  },
              ],
            },
        },
      },
    );
  }
}

class HealthRecoveryAnalyticsTool implements AiAnalyticsTool {
  final HealthRecoveryAnalyticsQuery _query;

  const HealthRecoveryAnalyticsTool(this._query);

  @override
  String get id => healthRecoveryAnalyticsToolId;

  @override
  Future<AiToolResult> execute(
    AiToolExecutionContext context,
    AiToolArguments arguments,
  ) async {
    final result = await _query.call(
      userId: context.userId,
      range: _range(arguments),
      pageSize: arguments.pageSize ?? 30,
      maxPages: arguments.maxPages ?? 50,
    );
    if (result.isFailure) return _failure(id, arguments, result.failureOrNull!);
    final queryResult = result.valueOrNull!;
    final summary = queryResult.summary;
    final status = switch (queryResult.state) {
      HealthRecoveryQueryState.complete => summary == null ||
              (queryResult.whoop.data?.isEmpty ?? true) &&
                  (queryResult.appleHealth.data?.isEmpty ?? true)
          ? AiToolStatus.empty
          : AiToolStatus.success,
      HealthRecoveryQueryState.partial => AiToolStatus.partial,
      HealthRecoveryQueryState.totalFailure => AiToolStatus.failure,
    };
    final failure =
        queryResult.whoop.failure ?? queryResult.appleHealth.failure;
    return AiToolResult(
      toolId: id,
      status: status,
      period: arguments.period,
      sources: const ['whoop_daily_data', 'apple_health'],
      failure: failure == null ? null : AiToolFailure.fromFailure(failure),
      metrics: {
        'whoop': {
          'state': queryResult.whoop.state.name,
          'days': summary?.whoopDays,
          'metrics': {
            if (summary != null)
              for (final entry in summary.whoop.entries)
                entry.key: {
                  'unit': entry.value.unit,
                  'values': entry.value.values,
                },
          },
        },
        'appleHealth': {
          'state': queryResult.appleHealth.state.name,
          'activityCount': summary?.appleHealth.count,
          'durationSeconds': summary?.appleHealth.durationSeconds,
          'distanceMeters': summary?.appleHealth.distanceMeters,
          'caloriesKcal': summary?.appleHealth.caloriesKcal,
          'averageHeartRateBpm': summary?.appleHealth.averageHeartRateBpm,
        },
      },
    );
  }
}

class NutritionAnalyticsTool implements AiAnalyticsTool {
  final NutritionAnalyticsQuery _query;

  const NutritionAnalyticsTool(this._query);

  @override
  String get id => nutritionAnalyticsToolId;

  @override
  Future<AiToolResult> execute(
    AiToolExecutionContext context,
    AiToolArguments arguments,
  ) async {
    final result = await _query.history();
    final failure = result.failureOrNull!;
    return AiToolResult(
      toolId: id,
      status: AiToolStatus.unavailable,
      period: arguments.period,
      sources: const ['nutrition_history_firestore'],
      limitations: const [
        'Histórico nutricional indisponível até validar a consulta Firestore.',
      ],
      failure: AiToolFailure.fromFailure(failure),
    );
  }
}
