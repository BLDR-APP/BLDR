import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/features/integrations/data/datasources/canonical_health_datasource.dart';
import 'package:bldr_fitness/features/integrations/data/health_kit_service.dart';
import 'package:bldr_fitness/features/integrations/data/repositories/canonical_health_reader_impl.dart';
import 'package:bldr_fitness/features/integrations/domain/entities/canonical_health.dart';
import 'package:flutter_test/flutter_test.dart';

const _userId = 'user-1';

void main() {
  const userId = 'user-1';
  final start = DateTime.utc(2026, 9, 1);
  final end = DateTime.utc(2026, 9, 10);

  group('CanonicalHealthReaderImpl WHOOP', () {
    test('rejects unauthenticated and foreign user requests', () async {
      final unauthenticated = _reader(_FakeHealthSource(), currentUserId: null);
      final foreign = _reader(_FakeHealthSource());

      expect(
        (await unauthenticated.whoopDailySnapshots(
          userId: userId,
          start: start,
          end: end,
        ))
            .failureOrNull,
        isA<AuthFailure>(),
      );
      expect(
        (await foreign.whoopDailySnapshots(
          userId: 'another-user',
          start: start,
          end: end,
        ))
            .failureOrNull,
        isA<AuthFailure>(),
      );
    });

    test('keeps disconnected distinct from empty history', () async {
      final disconnected = await _reader(_FakeHealthSource(connected: false))
          .whoopDailySnapshots(userId: userId, start: start, end: end);
      final empty = await _reader(_FakeHealthSource()).whoopDailySnapshots(
        userId: userId,
        start: start,
        end: end,
      );

      expect(disconnected.valueOrNull!.availability,
          CanonicalHealthAvailability.disconnected);
      expect(
          empty.valueOrNull!.availability, CanonicalHealthAvailability.empty);
    });

    test('returns a controlled failure when WHOOP datasource fails', () async {
      final result = await _reader(_FakeHealthSource(throwsOnRead: true))
          .whoopDailySnapshots(userId: userId, start: start, end: end);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<UnexpectedFailure>());
    });

    test('pages deterministically and preserves provenance', () async {
      final source = _FakeHealthSource(rows: [
        _whoopRow('third', '2026-09-03'),
        _whoopRow('second', '2026-09-02'),
        _whoopRow('first', '2026-09-01'),
        {..._whoopRow('foreign', '2026-09-04'), 'user_id': 'another-user'},
      ]);
      final reader = _reader(source);
      final first = await reader.whoopDailySnapshots(
        userId: userId,
        start: start,
        end: end,
        limit: 2,
      );
      final second = await reader.whoopDailySnapshots(
        userId: userId,
        start: start,
        end: end,
        beforeDate: first.valueOrNull!.nextBeforeDate,
        limit: 2,
      );

      expect(first.valueOrNull!.snapshots.map((item) => item.sourceRecordId),
          ['third', 'second']);
      expect(
          first.valueOrNull!.snapshots.every((item) => item.userId == userId),
          isTrue);
      expect(first.valueOrNull!.snapshots.first.source,
          CanonicalHealthSource.whoop);
      expect(second.valueOrNull!.snapshots.map((item) => item.sourceRecordId),
          ['first']);
      expect(second.valueOrNull!.nextBeforeDate, isNull);
      expect(source.requests.map((item) => item.limit), everyElement(3));
    });

    test('rejects invalid cursor and invalid query bounds', () async {
      final reader = _reader(_FakeHealthSource());
      final badCursor = await reader.whoopDailySnapshots(
        userId: userId,
        start: start,
        end: end,
        beforeDate: start,
      );
      final badPeriod = await reader.whoopDailySnapshots(
        userId: userId,
        start: end,
        end: start,
      );

      expect(badCursor.failureOrNull, isA<ValidationFailure>());
      expect(badPeriod.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('CanonicalHealthReaderImpl Apple Health', () {
    test('maps activities and preserves identifiers and provenance', () async {
      final reader = _reader(
        _FakeHealthSource(),
        workouts: () async => [_workoutRow()],
      );

      final result = await reader.appleHealthActivities(userId: userId);

      expect(
          result.valueOrNull!.single.source, CanonicalHealthSource.appleHealth);
      expect(result.valueOrNull!.single.sourceRecordId, 'health-1');
      expect(result.valueOrNull!.single.userId, userId);
    });

    test('keeps empty result and channel failure distinct', () async {
      final empty = await _reader(_FakeHealthSource())
          .appleHealthActivities(userId: userId);
      final failed = await _reader(
        _FakeHealthSource(),
        workouts: () =>
            Future<List<Map<String, dynamic>>>.error(Exception('channel')),
      ).appleHealthActivities(userId: userId);

      expect(empty.valueOrNull, isEmpty);
      expect(failed.failureOrNull, isA<DataFailure>());
    });
  });
}

CanonicalHealthReaderImpl _reader(
  CanonicalHealthReadDatasource source, {
  String? currentUserId = _userId,
  Future<List<Map<String, dynamic>>> Function()? workouts,
}) =>
    CanonicalHealthReaderImpl(
      datasource: source,
      healthKit: HealthKitService(),
      currentUserId: () => currentUserId,
      fetchRecentWorkouts: ({lookback = const Duration(days: 7), limit = 20}) =>
          workouts?.call() ?? Future.value(const []),
    );

Map<String, dynamic> _whoopRow(String id, String date) => {
      'id': id,
      'user_id': _userId,
      'date': date,
      'synced_at': '${date}T12:00:00Z',
      'recovery_score': 80,
      'hrv_rmssd': 50.0,
      'resting_hr': 50,
      'strain_score': 10.0,
      'sleep_score': 80,
      'sleep_duration': 420,
    };

Map<String, dynamic> _workoutRow() => {
      'id': 'health-1',
      'started_at': '2026-09-01T10:00:00Z',
      'ended_at': '2026-09-01T11:00:00Z',
      'duration_s': 3600,
    };

class _Request {
  final int limit;
  final DateTime? beforeDate;
  const _Request(this.limit, this.beforeDate);
}

class _FakeHealthSource implements CanonicalHealthReadDatasource {
  final bool connected;
  final bool throwsOnRead;
  final List<Map<String, dynamic>> rows;
  final List<_Request> requests = [];

  _FakeHealthSource({
    this.connected = true,
    this.throwsOnRead = false,
    List<Map<String, dynamic>>? rows,
  }) : rows = rows ?? [];

  @override
  Future<bool> hasWhoopConnection(String requestedUserId) async => connected;

  @override
  Future<List<Map<String, dynamic>>> whoopDaily({
    required String userId,
    required DateTime start,
    required DateTime end,
    DateTime? beforeDate,
    required int limit,
  }) async {
    requests.add(_Request(limit, beforeDate));
    if (throwsOnRead) throw Exception('source');
    final filtered = rows.where((row) => row['user_id'] == userId).where((row) {
      final date = DateTime.parse(row['date'] as String);
      return !date.isBefore(start) &&
          date.isBefore(end) &&
          (beforeDate == null || date.isBefore(beforeDate));
    }).toList()
      ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    return filtered.take(limit).toList();
  }
}
