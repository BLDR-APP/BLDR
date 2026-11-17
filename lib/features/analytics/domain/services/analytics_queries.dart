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
import 'package:bldr_fitness/features/workouts/domain/repositories/canonical_workout_reader.dart';

class WorkoutAnalyticsQuery {
  final CanonicalWorkoutReader _reader;
  const WorkoutAnalyticsQuery(this._reader);

  Future<Result<WorkoutAnalyticsSummary>> call(
          {required String userId,
          required WorkoutAnalyticsRange range,
          bool comparePreviousPeriod = true,
          int pageSize = 50,
          int maxPages = 50}) =>
      WorkoutAnalyticsEngine(_ValidatingWorkoutReader(_reader)).summarize(
        userId: userId,
        range: range,
        comparePreviousPeriod: comparePreviousPeriod,
        pageSize: pageSize,
        maxPages: maxPages,
      );
}

/// Mantém as garantias de paginação da Query Layer sem alterar o reader
/// canônico ou repetir os cálculos do [WorkoutAnalyticsEngine].
class _ValidatingWorkoutReader implements CanonicalWorkoutReader {
  final CanonicalWorkoutReader _delegate;
  final Set<String> _seenSessionIds = {};
  final Set<String> _issuedCursorTokens = {};

  _ValidatingWorkoutReader(this._delegate);

  @override
  Future<Result<CanonicalWorkoutPage>> history({
    required String userId,
    CanonicalWorkoutCursor? cursor,
    int limit = 20,
  }) async {
    final result = await _delegate.history(
      userId: userId,
      cursor: cursor,
      limit: limit,
    );
    if (result.isFailure) return Result.failure(result.failureOrNull!);

    final page = result.valueOrNull!;
    if (page.hasMore && page.nextCursor == null) {
      return const Result.failure(
        ValidationFailure('Página de histórico de treinos sem cursor.'),
      );
    }
    final next = page.nextCursor;
    if (next != null && !_issuedCursorTokens.add(next.toString())) {
      return const Result.failure(
        ValidationFailure('Cursor do histórico de treinos repetido.'),
      );
    }
    return Result.success(CanonicalWorkoutPage(
      sessions: page.sessions
          .where((session) => _seenSessionIds.add(session.id))
          .toList(growable: false),
      nextCursor: next,
      hasMore: page.hasMore,
    ));
  }
}

class ProgressAnalyticsQuery {
  final ProgressRepository _repository;
  const ProgressAnalyticsQuery(this._repository);

  Future<Result<ProgressAnalyticsSummary>> call(
      {required WorkoutAnalyticsRange range, int limit = 50}) async {
    if (!range.end.isAfter(range.start) || limit <= 0) {
      return const Result.failure(
        ValidationFailure('Parâmetros inválidos para analytics de progresso.'),
      );
    }
    final r = await _repository.measurements(
      startDate: range.start,
      endDate: range.end,
      limit: limit,
    );
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
