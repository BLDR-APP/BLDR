import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/analytics/domain/entities/workout_analytics.dart';
import 'package:bldr_fitness/features/analytics/domain/services/analytics_queries.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/canonical_workout.dart';
import 'package:bldr_fitness/features/workouts/domain/repositories/canonical_workout_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final range = WorkoutAnalyticsRange(
    start: DateTime.utc(2026, 9, 1),
    end: DateTime.utc(2026, 9, 8),
  );

  Future<Result<WorkoutAnalyticsSummary>> query(
    _Reader reader, {
    WorkoutAnalyticsRange? requestedRange,
    int pageSize = 2,
    int maxPages = 10,
  }) =>
      WorkoutAnalyticsQuery(reader).call(
        userId: 'u',
        range: requestedRange ?? range,
        comparePreviousPeriod: false,
        pageSize: pageSize,
        maxPages: maxPages,
      );

  test('returns an empty summary for an empty history', () async {
    final result = await query(_Reader([_page(const [])]));

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.completedSessions, 0);
    expect(result.valueOrNull!.totalVolumeKg, 0);
  });

  test('preserves a completed FREE workout', () async {
    final free = _session('free', WorkoutSessionSource.personal, 2);
    final result = await query(_Reader([
      _page([free])
    ]));

    expect(result.valueOrNull!.completedSessions, 1);
    expect(free.source, WorkoutSessionSource.personal);
    expect(free.id, 'personal:free');
  });

  test('preserves a completed BLDR CLUB workout', () async {
    final club = _session('club', WorkoutSessionSource.bldrClub, 2);
    final result = await query(_Reader([
      _page([club])
    ]));

    expect(result.valueOrNull!.completedSessions, 1);
    expect(club.source, WorkoutSessionSource.bldrClub);
    expect(club.id, 'bldrClub:club');
  });

  test('aggregates mixed FREE and BLDR CLUB history', () async {
    final result = await query(_Reader([
      _page([
        _session('free', WorkoutSessionSource.personal, 2),
        _session('club', WorkoutSessionSource.bldrClub, 3),
      ]),
    ]));

    expect(result.valueOrNull!.completedSessions, 2);
    expect(result.valueOrNull!.totalVolumeKg, 200);
  });

  test('uses the requested interval when calculating the summary', () async {
    final result = await query(_Reader([
      _page([
        _session('inside', WorkoutSessionSource.personal, 2),
        _session('outside', WorkoutSessionSource.personal, 8),
      ]),
    ]));

    expect(result.valueOrNull!.completedSessions, 1);
  });

  test('rejects an invalid interval without reading history', () async {
    final reader = _Reader([_page(const [])]);
    final invalidRange = WorkoutAnalyticsRange(
      start: range.end,
      end: range.start,
    );

    final result = await query(reader, requestedRange: invalidRange);

    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(reader.calls, 0);
  });

  test('uses one bounded page when there is no next cursor', () async {
    final reader = _Reader([
      _page([_session('one', WorkoutSessionSource.personal, 2)])
    ]);

    final result = await query(reader);

    expect(result.isSuccess, isTrue);
    expect(reader.calls, 1);
    expect(reader.requestedLimits, [2]);
    expect(reader.cursors, [null]);
  });

  test('aggregates multiple pages with the supplied cursor', () async {
    const next = CanonicalWorkoutCursor('cursor-2');
    final reader = _Reader([
      _page([_session('first', WorkoutSessionSource.personal, 2)], next: next),
      _page([_session('second', WorkoutSessionSource.bldrClub, 3)]),
    ]);

    final result = await query(reader);

    expect(result.valueOrNull!.completedSessions, 2);
    expect(reader.cursors, [null, next]);
  });

  test('returns a controlled failure for a repeated cursor', () async {
    const cursor = CanonicalWorkoutCursor('repeated');
    final result = await query(_Reader([
      _page([_session('first', WorkoutSessionSource.personal, 2)],
          next: cursor),
      _page([_session('second', WorkoutSessionSource.personal, 3)],
          next: cursor),
    ]));

    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(result.failureOrNull!.message, contains('repetido'));
  });

  test('does not return a truncated result when maxPages is exceeded',
      () async {
    final result = await query(
      _Reader([
        _page(
          [_session('first', WorkoutSessionSource.personal, 2)],
          next: const CanonicalWorkoutCursor('next'),
        ),
        _page([_session('second', WorkoutSessionSource.personal, 3)]),
      ]),
      maxPages: 1,
    );

    expect(result.failureOrNull, isA<ValidationFailure>());
    expect(result.failureOrNull!.message, contains('limite de páginas'));
  });

  test('deduplicates sessions across pages using canonical identity', () async {
    const next = CanonicalWorkoutCursor('next');
    final free = _session('same', WorkoutSessionSource.personal, 2);
    final club = _session('same', WorkoutSessionSource.bldrClub, 3);
    final result = await query(_Reader([
      _page([free], next: next),
      _page([free, club]),
    ]));

    expect(result.valueOrNull!.completedSessions, 2);
    expect(free.id, 'personal:same');
    expect(club.id, 'bldrClub:same');
  });

  test('propagates a first-page reader failure', () async {
    final result = await query(_Reader(const [], failureAtCall: 0));

    expect(result.failureOrNull, isA<NetworkFailure>());
  });

  test('propagates an intermediate reader failure', () async {
    final reader = _Reader(
      [
        _page(
          [_session('first', WorkoutSessionSource.personal, 2)],
          next: const CanonicalWorkoutCursor('next'),
        ),
      ],
      failureAtCall: 1,
    );

    final result = await query(reader);

    expect(result.failureOrNull, isA<NetworkFailure>());
    expect(reader.calls, 2);
  });

  test('propagates authentication and user-isolation failures', () async {
    final unauthenticated =
        await query(_Reader(const [], authenticated: false));
    final foreign =
        await WorkoutAnalyticsQuery(_Reader([_page(const [])])).call(
      userId: 'another-user',
      range: range,
      comparePreviousPeriod: false,
    );

    expect(unauthenticated.failureOrNull, isA<AuthFailure>());
    expect(foreign.failureOrNull, isA<AuthFailure>());
  });

  test('forwards canonical set metrics to the engine unchanged', () async {
    final result = await query(_Reader([
      _page([
        _session('metrics', WorkoutSessionSource.personal, 2,
            reps: 8, weight: 60),
      ]),
    ]));

    final summary = result.valueOrNull!;
    expect(summary.totalVolumeKg, 480);
    expect(summary.completedSetsByExercise['bench'], 1);
    expect(summary.volumeByMuscleGroup['chest'], 480);
    expect(summary.loadProgression.single.latestWeightKg, 60);
  });
}

CanonicalWorkoutPage _page(
  List<CanonicalWorkoutSession> sessions, {
  CanonicalWorkoutCursor? next,
}) =>
    CanonicalWorkoutPage(
      sessions: sessions,
      nextCursor: next,
      hasMore: next != null,
    );

CanonicalWorkoutSession _session(
  String sourceId,
  WorkoutSessionSource source,
  int day, {
  int reps = 10,
  double weight = 10,
}) {
  final completedAt = DateTime.utc(2026, 9, day, 12);
  final id = canonicalWorkoutSessionId(source, sourceId);
  return CanonicalWorkoutSession(
    id: id,
    sourceSessionId: sourceId,
    userId: 'u',
    source: source,
    startedAt: completedAt.subtract(const Duration(minutes: 45)),
    completedAt: completedAt,
    isCompleted: true,
    durationSeconds: 2700,
    exercises: [
      CanonicalWorkoutExercise(
        id: '$id:exercise',
        internalExerciseId: 'bench',
        primaryMuscleGroup: 'chest',
        sets: [
          CanonicalWorkoutSet(
            id: '$id:set',
            sessionId: id,
            exerciseId: '$id:exercise',
            setNumber: 1,
            reps: reps,
            weightKg: weight,
            completedAt: completedAt,
            isCompleted: true,
            isSkipped: false,
          ),
        ],
      ),
    ],
  );
}

class _Reader implements CanonicalWorkoutReader {
  final List<CanonicalWorkoutPage> pages;
  final int? failureAtCall;
  final bool authenticated;
  final List<CanonicalWorkoutCursor?> cursors = [];
  final List<int> requestedLimits = [];
  int calls = 0;

  _Reader(
    this.pages, {
    this.failureAtCall,
    this.authenticated = true,
  });

  @override
  Future<Result<CanonicalWorkoutPage>> history({
    required String userId,
    CanonicalWorkoutCursor? cursor,
    int limit = 20,
  }) async {
    cursors.add(cursor);
    requestedLimits.add(limit);
    final call = calls++;
    if (!authenticated || userId != 'u') {
      return const Result.failure(AuthFailure('Usuário não autorizado.'));
    }
    if (failureAtCall == call) {
      return const Result.failure(NetworkFailure());
    }
    return Result.success(pages[call]);
  }
}
