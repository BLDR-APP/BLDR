import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/analytics/domain/entities/health_recovery_analytics.dart';
import 'package:bldr_fitness/features/analytics/domain/entities/progress_analytics.dart';
import 'package:bldr_fitness/features/analytics/domain/entities/workout_analytics.dart';
import 'package:bldr_fitness/features/analytics/domain/services/health_recovery_analytics_engine.dart';
import 'package:bldr_fitness/features/analytics/domain/services/progress_analytics_engine.dart';
import 'package:bldr_fitness/features/analytics/domain/services/workout_analytics_engine.dart';
import 'package:bldr_fitness/features/integrations/domain/entities/canonical_health.dart';
import 'package:bldr_fitness/features/integrations/domain/repositories/canonical_health_reader.dart';
import 'package:bldr_fitness/features/progress/domain/repositories/progress_repository.dart';

class WorkoutAnalyticsQuery {
  final WorkoutAnalyticsEngine _engine;
  const WorkoutAnalyticsQuery(this._engine);
  Future<Result<WorkoutAnalyticsSummary>> call(
          {required String userId, required WorkoutAnalyticsRange range}) =>
      _engine.summarize(userId: userId, range: range);
}

class ProgressAnalyticsQuery {
  final ProgressRepository _repository;
  const ProgressAnalyticsQuery(this._repository);
  Future<Result<ProgressAnalyticsSummary>> call(
      {required WorkoutAnalyticsRange range}) async {
    final r = await _repository.measurements(
        startDate: range.start, endDate: range.end, limit: 50);
    return r.map((m) => const ProgressAnalyticsEngine()
        .summarize(range: range, measurements: m));
  }
}

class NutritionAnalyticsQuery {
  const NutritionAnalyticsQuery();
  Future<
      Result<
          Never>> history() async => const Result.failure(ValidationFailure(
      'Histórico nutricional indisponível até validar a consulta Firestore.'));
}

enum HealthProviderQueryState { data, empty, disconnected, failure }

enum HealthRecoveryQueryState { complete, partial, totalFailure }

class HealthProviderQueryResult<T> {
  final HealthProviderQueryState state;
  final T? data;
  final Failure? failure;

  const HealthProviderQueryResult({
    required this.state,
    this.data,
    this.failure,
  });
}

class HealthRecoveryQueryResult {
  final HealthRecoveryQueryState state;
  final HealthProviderQueryResult<List<CanonicalHealthDailySnapshot>> whoop;
  final HealthProviderQueryResult<List<CanonicalHealthActivity>> appleHealth;
  final HealthRecoveryAnalyticsSummary? summary;

  const HealthRecoveryQueryResult({
    required this.state,
    required this.whoop,
    required this.appleHealth,
    this.summary,
  });
}

class HealthRecoveryAnalyticsQuery {
  final CanonicalHealthReader _reader;
  const HealthRecoveryAnalyticsQuery(this._reader);
  Future<Result<HealthRecoveryQueryResult>> call(
      {required String userId,
      required WorkoutAnalyticsRange range,
      int pageSize = 30,
      int maxPages = 50}) async {
    if (pageSize <= 0 || maxPages <= 0) {
      return const Result.failure(ValidationFailure('Limites inválidos.'));
    }
    final all = <CanonicalHealthDailySnapshot>[];
    final ids = <String>{};
    DateTime? cursor;
    CanonicalHealthAvailability state = CanonicalHealthAvailability.empty;
    Failure? whoopFailure;
    var whoopFinished = false;
    for (var pageIndex = 0; pageIndex < maxPages; pageIndex++) {
      final whoop = await _reader.whoopDailySnapshots(
          userId: userId,
          start: range.start,
          end: range.end,
          beforeDate: cursor,
          limit: pageSize);
      if (whoop.isFailure) {
        whoopFailure = whoop.failureOrNull!;
        break;
      }
      final page = whoop.valueOrNull!;
      state = page.availability;
      for (final snapshot in page.snapshots) {
        if (ids.add(snapshot.sourceRecordId)) all.add(snapshot);
      }
      final next = page.nextBeforeDate;
      if (next == null) {
        whoopFinished = true;
        break;
      }
      if (cursor == next) {
        whoopFailure = const ValidationFailure('Cursor WHOOP repetido.');
        break;
      }
      cursor = next;
    }
    if (!whoopFinished && whoopFailure == null) {
      whoopFailure =
          const ValidationFailure('Limite de páginas WHOOP excedido.');
    }
    final apple = await _reader.appleHealthActivities(userId: userId);
    final appleFailure = apple.failureOrNull;
    final whoopResult =
        HealthProviderQueryResult<List<CanonicalHealthDailySnapshot>>(
      state: whoopFailure != null
          ? HealthProviderQueryState.failure
          : state == CanonicalHealthAvailability.disconnected
              ? HealthProviderQueryState.disconnected
              : all.isEmpty
                  ? HealthProviderQueryState.empty
                  : HealthProviderQueryState.data,
      data: whoopFailure == null ? List.unmodifiable(all) : null,
      failure: whoopFailure,
    );
    final appleData = apple.valueOrNull;
    final appleResult =
        HealthProviderQueryResult<List<CanonicalHealthActivity>>(
      state: appleFailure != null
          ? HealthProviderQueryState.failure
          : appleData!.isEmpty
              ? HealthProviderQueryState.empty
              : HealthProviderQueryState.data,
      data: appleData,
      failure: appleFailure,
    );
    final usable = whoopFailure == null || appleFailure == null;
    final aggregate = !usable
        ? HealthRecoveryQueryState.totalFailure
        : whoopFailure != null ||
                appleFailure != null ||
                whoopResult.state == HealthProviderQueryState.disconnected
            ? HealthRecoveryQueryState.partial
            : HealthRecoveryQueryState.complete;
    return Result.success(HealthRecoveryQueryResult(
      state: aggregate,
      whoop: whoopResult,
      appleHealth: appleResult,
      summary: usable
          ? const HealthRecoveryAnalyticsEngine().summarize(
              range: range,
              availability: state,
              snapshots: all,
              activities: appleData ?? const [],
            )
          : null,
    ));
  }
}
