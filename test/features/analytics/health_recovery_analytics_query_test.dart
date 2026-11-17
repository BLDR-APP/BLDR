import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/analytics/domain/entities/workout_analytics.dart';
import 'package:bldr_fitness/features/analytics/domain/services/analytics_queries.dart';
import 'package:bldr_fitness/features/integrations/domain/entities/canonical_health.dart';
import 'package:bldr_fitness/features/integrations/domain/repositories/canonical_health_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final range = WorkoutAnalyticsRange(
    start: DateTime.utc(2026, 1, 1),
    end: DateTime.utc(2026, 2, 1),
  );

  Future<HealthRecoveryQueryResult> run(_Reader reader,
      {int maxPages = 50}) async {
    final result = await HealthRecoveryAnalyticsQuery(reader).call(
      userId: 'u',
      range: range,
      pageSize: 2,
      maxPages: maxPages,
    );
    expect(result.isSuccess, isTrue);
    return result.valueOrNull!;
  }

  group('WHOOP pagination', () {
    test('returns an empty history without failure', () async {
      final reader = _Reader([_page(const [])]);

      final result = await run(reader);

      expect(result.state, HealthRecoveryQueryState.complete);
      expect(result.whoop.state, HealthProviderQueryState.empty);
      expect(result.whoop.data, isEmpty);
      expect(result.summary!.whoopDays, 0);
      expect(reader.whoopCalls, 1);
    });

    test('keeps a single final page intact', () async {
      final reader = _Reader([
        _page([_snapshot('one', 4, recovery: 80)])
      ]);

      final result = await run(reader);

      expect(reader.whoopCalls, 1);
      expect(result.whoop.state, HealthProviderQueryState.data);
      expect(result.summary!.whoopDays, 1);
      expect(result.summary!.whoop['recovery_score']!.unit, 'score');
    });

    test('paginates and deduplicates snapshots', () async {
      final secondCursor = DateTime.utc(2026, 1, 2);
      final reader = _Reader([
        _page([_snapshot('a', 1), _snapshot('b', 2)], next: secondCursor),
        _page([_snapshot('b', 2), _snapshot('c', 3)]),
      ]);

      final result = await run(reader);

      expect(result.summary!.whoopDays, 3);
      expect(result.whoop.data!.map((snapshot) => snapshot.sourceRecordId),
          ['a', 'b', 'c']);
      expect(reader.whoopCalls, 2);
      expect(reader.whoopCursors, [null, secondCursor]);
    });

    test('fails the WHOOP provider on a repeated cursor', () async {
      final repeatedCursor = DateTime.utc(2026, 1, 1);
      final reader = _Reader([
        _page([_snapshot('a', 1)], next: repeatedCursor),
        _page([_snapshot('b', 2)], next: repeatedCursor),
      ]);

      final result = await run(reader);

      expect(result.state, HealthRecoveryQueryState.partial);
      expect(result.whoop.state, HealthProviderQueryState.failure);
      expect(result.whoop.failure, isA<ValidationFailure>());
      expect(reader.whoopCalls, 2);
      expect(reader.appleCalls, 1);
    });

    test('propagates an intermediate reader failure', () async {
      final nextCursor = DateTime.utc(2026, 1, 2);
      final reader = _Reader(
        [
          _page([_snapshot('a', 1)], next: nextCursor)
        ],
        whoopFailureAtCall: 1,
      );

      final result = await run(reader);

      expect(result.state, HealthRecoveryQueryState.partial);
      expect(result.whoop.failure, isA<NetworkFailure>());
      expect(reader.whoopCalls, 2);
      expect(reader.whoopCursors, [null, nextCursor]);
      expect(reader.appleCalls, 1);
    });

    test('fails the WHOOP provider when maxPages is exceeded', () async {
      final reader = _Reader([
        _page([_snapshot('a', 1)], next: DateTime.utc(2026, 1, 2)),
        _page([_snapshot('b', 2)]),
      ]);

      final result = await run(reader, maxPages: 1);

      expect(result.state, HealthRecoveryQueryState.partial);
      expect(result.whoop.failure, isA<ValidationFailure>());
      expect(reader.whoopCalls, 1);
    });

    test('continues after duplicate snapshots and preserves provenance',
        () async {
      final first = _snapshot('same', 5, recovery: 75);
      final finalSnapshot = _snapshot('last', 6, recovery: 77);
      final reader = _Reader([
        _page([first], next: DateTime.utc(2026, 1, 6)),
        _page([first, finalSnapshot]),
      ]);

      final result = await run(reader);

      expect(reader.whoopCalls, 2);
      expect(result.whoop.data, [first, finalSnapshot]);
      expect(first.source, CanonicalHealthSource.whoop);
      expect(first.sourceRecordId, 'same');
      expect(first.date, DateTime.utc(2026, 1, 5));
      expect(result.summary!.whoop['recovery_score']!.unit, 'score');
    });
  });

  group('independent provider outcomes', () {
    test('returns complete when WHOOP and Apple Health both provide data',
        () async {
      final reader = _Reader(
        [
          _page([_snapshot('w', 1)])
        ],
        appleResult: Result.success([_activity('a')]),
      );

      final result = await run(reader);

      expect(result.state, HealthRecoveryQueryState.complete);
      expect(result.whoop.state, HealthProviderQueryState.data);
      expect(result.appleHealth.state, HealthProviderQueryState.data);
      expect(result.summary!.appleHealth.count, 1);
    });

    test('preserves WHOOP data when Apple Health fails', () async {
      final failure = const NetworkFailure();
      final reader = _Reader(
        [
          _page([_snapshot('w', 1)])
        ],
        appleResult: Result.failure(failure),
      );

      final result = await run(reader);

      expect(result.state, HealthRecoveryQueryState.partial);
      expect(result.whoop.data!.single.sourceRecordId, 'w');
      expect(result.appleHealth.state, HealthProviderQueryState.failure);
      expect(result.appleHealth.failure, same(failure));
      expect(reader.whoopCalls, 1);
      expect(reader.appleCalls, 1);
    });

    test('preserves Apple Health data when WHOOP fails', () async {
      final failure = const NetworkFailure();
      final reader = _Reader(
        const [],
        whoopFailureAtCall: 0,
        whoopFailure: failure,
        appleResult: Result.success([_activity('a')]),
      );

      final result = await run(reader);

      expect(result.state, HealthRecoveryQueryState.partial);
      expect(result.whoop.failure, same(failure));
      expect(result.appleHealth.data!.single.sourceRecordId, 'a');
      expect(reader.whoopCalls, 1);
      expect(reader.appleCalls, 1);
    });

    test('returns totalFailure only when both providers fail', () async {
      final whoopFailure = const NetworkFailure();
      final appleFailure = const ServerFailure('Apple Health indisponível.');
      final reader = _Reader(
        const [],
        whoopFailureAtCall: 0,
        whoopFailure: whoopFailure,
        appleResult: Result.failure(appleFailure),
      );

      final result = await run(reader);

      expect(result.state, HealthRecoveryQueryState.totalFailure);
      expect(result.summary, isNull);
      expect(result.whoop.failure, same(whoopFailure));
      expect(result.appleHealth.failure, same(appleFailure));
      expect(reader.whoopCalls, 1);
      expect(reader.appleCalls, 1);
    });

    test('returns complete for empty WHOOP and Apple Health data', () async {
      final reader = _Reader(
        [_page(const [])],
        appleResult: Result.success([_activity('a')]),
      );

      final result = await run(reader);

      expect(result.state, HealthRecoveryQueryState.complete);
      expect(result.whoop.state, HealthProviderQueryState.empty);
      expect(result.appleHealth.state, HealthProviderQueryState.data);
    });

    test('returns complete for WHOOP data and empty Apple Health', () async {
      final result = await run(_Reader([
        _page([_snapshot('w', 1)])
      ]));

      expect(result.state, HealthRecoveryQueryState.complete);
      expect(result.whoop.state, HealthProviderQueryState.data);
      expect(result.appleHealth.state, HealthProviderQueryState.empty);
    });

    test('returns complete when both providers are empty', () async {
      final result = await run(_Reader([_page(const [])]));

      expect(result.state, HealthRecoveryQueryState.complete);
      expect(result.whoop.state, HealthProviderQueryState.empty);
      expect(result.appleHealth.state, HealthProviderQueryState.empty);
    });

    test('keeps WHOOP disconnected distinct from Apple Health data', () async {
      final reader = _Reader(
        [
          _page(const [],
              availability: CanonicalHealthAvailability.disconnected)
        ],
        appleResult: Result.success([_activity('a')]),
      );

      final result = await run(reader);

      expect(result.state, HealthRecoveryQueryState.partial);
      expect(result.whoop.state, HealthProviderQueryState.disconnected);
      expect(result.whoop.failure, isNull);
      expect(result.appleHealth.state, HealthProviderQueryState.data);
    });

    test('keeps WHOOP disconnected distinct from empty Apple Health', () async {
      final result = await run(_Reader([
        _page(const [], availability: CanonicalHealthAvailability.disconnected),
      ]));

      expect(result.state, HealthRecoveryQueryState.partial);
      expect(result.whoop.state, HealthProviderQueryState.disconnected);
      expect(result.appleHealth.state, HealthProviderQueryState.empty);
    });

    test('keeps WHOOP disconnected distinct from Apple Health failure',
        () async {
      final failure = const NetworkFailure();
      final reader = _Reader(
        [
          _page(const [],
              availability: CanonicalHealthAvailability.disconnected)
        ],
        appleResult: Result.failure(failure),
      );

      final result = await run(reader);

      expect(result.state, HealthRecoveryQueryState.partial);
      expect(result.whoop.state, HealthProviderQueryState.disconnected);
      expect(result.appleHealth.failure, same(failure));
    });

    test('keeps paginated WHOOP data when Apple Health fails', () async {
      final reader = _Reader(
        [
          _page([_snapshot('a', 1)], next: DateTime.utc(2026, 1, 2)),
          _page([_snapshot('b', 2)]),
        ],
        appleResult: const Result.failure(NetworkFailure()),
      );

      final result = await run(reader);

      expect(result.state, HealthRecoveryQueryState.partial);
      expect(result.whoop.data!.map((snapshot) => snapshot.sourceRecordId),
          ['a', 'b']);
      expect(reader.whoopCalls, 2);
    });
  });
}

CanonicalHealthDailySnapshot _snapshot(String id, int day, {int? recovery}) =>
    CanonicalHealthDailySnapshot(
      userId: 'u',
      source: CanonicalHealthSource.whoop,
      sourceRecordId: id,
      date: DateTime.utc(2026, 1, day),
      syncedAt: DateTime.utc(2026, 1, day),
      recoveryScore: recovery,
    );

CanonicalHealthDailyPage _page(
  List<CanonicalHealthDailySnapshot> snapshots, {
  DateTime? next,
  CanonicalHealthAvailability availability = CanonicalHealthAvailability.data,
}) =>
    CanonicalHealthDailyPage(
      availability: availability,
      snapshots: snapshots,
      nextBeforeDate: next,
    );

CanonicalHealthActivity _activity(String id) => CanonicalHealthActivity(
      userId: 'u',
      source: CanonicalHealthSource.appleHealth,
      sourceRecordId: id,
      startedAt: DateTime.utc(2026, 1, 1, 12),
      endedAt: DateTime.utc(2026, 1, 1, 13),
      durationSeconds: 3600,
      activeEnergyKcal: 250,
      distanceMeters: 5000,
      averageHeartRateBpm: 130,
    );

class _Reader implements CanonicalHealthReader {
  final List<CanonicalHealthDailyPage> whoopPages;
  final int? whoopFailureAtCall;
  final Failure whoopFailure;
  final Result<List<CanonicalHealthActivity>> appleResult;
  final List<DateTime?> whoopCursors = [];
  int whoopCalls = 0;
  int appleCalls = 0;

  _Reader(
    this.whoopPages, {
    this.whoopFailureAtCall,
    this.whoopFailure = const NetworkFailure(),
    Result<List<CanonicalHealthActivity>>? appleResult,
  }) : appleResult = appleResult ?? const Result.success([]);

  @override
  Future<Result<CanonicalHealthDailyPage>> whoopDailySnapshots({
    required String userId,
    required DateTime start,
    required DateTime end,
    DateTime? beforeDate,
    int limit = 30,
  }) async {
    whoopCursors.add(beforeDate);
    final call = whoopCalls++;
    if (whoopFailureAtCall == call) {
      return Result.failure(whoopFailure);
    }
    return Result.success(whoopPages[call]);
  }

  @override
  Future<Result<List<CanonicalHealthActivity>>> appleHealthActivities({
    required String userId,
    Duration lookback = const Duration(days: 7),
    int limit = 20,
  }) async {
    appleCalls++;
    return appleResult;
  }
}
