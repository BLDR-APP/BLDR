import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/analytics/domain/entities/workout_analytics.dart';
import 'package:bldr_fitness/features/analytics/domain/services/workout_analytics_engine.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/canonical_workout.dart';
import 'package:bldr_fitness/features/workouts/domain/repositories/canonical_workout_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final range = WorkoutAnalyticsRange(
    start: DateTime.utc(2026, 9, 1),
    end: DateTime.utc(2026, 9, 8),
  );

  test('returns empty metrics for an empty history', () async {
    final result = await WorkoutAnalyticsEngine(_FakeReader([])).summarize(
      userId: 'u1',
      range: range,
    );
    expect(result.valueOrNull!.completedSessions, 0);
    expect(result.valueOrNull!.totalVolumeKg, 0);
    expect(result.valueOrNull!.averageDurationSeconds, isNull);
  });

  test('counts completed FREE and CLUB sessions without double counting',
      () async {
    final result = await WorkoutAnalyticsEngine(_FakeReader([
      _session(
          'personal:a', WorkoutSessionSource.personal, '2026-09-02', 10, 50),
      _session(
          'bldrClub:b', WorkoutSessionSource.bldrClub, '2026-09-03', 8, 60),
      _session('pending', WorkoutSessionSource.personal, null, 10, 90),
    ])).summarize(userId: 'u1', range: range, comparePreviousPeriod: false);

    final summary = result.valueOrNull!;
    expect(summary.completedSessions, 2);
    expect(summary.totalVolumeKg, 980);
    expect(summary.activeDays, 2);
    expect(summary.weeklyFrequency, 2);
    expect(summary.averageDurationSeconds, 1800);
    expect(summary.volumeByMuscleGroup['chest'], 980);
  });

  test('excludes skipped and pending sets from volume and progression',
      () async {
    final session = _session(
        'personal:a', WorkoutSessionSource.personal, '2026-09-02', 10, 50,
        skipped: true);
    final result = await WorkoutAnalyticsEngine(_FakeReader([session]))
        .summarize(userId: 'u1', range: range);

    expect(result.valueOrNull!.totalVolumeKg, 0);
    expect(result.valueOrNull!.loadProgression, isEmpty);
  });

  test('compares equal periods and tracks exercise load progression', () async {
    final result = await WorkoutAnalyticsEngine(_FakeReader([
      _session('old', WorkoutSessionSource.personal, '2026-08-28', 10, 40),
      _session('early', WorkoutSessionSource.personal, '2026-09-02', 10, 50),
      _session('late', WorkoutSessionSource.bldrClub, '2026-09-05', 8, 60),
    ])).summarize(userId: 'u1', range: range);

    final summary = result.valueOrNull!;
    expect(summary.previousPeriodVolumeKg, 400);
    expect(summary.volumeDeltaPercent, closeTo(145, 0.0001));
    expect(summary.loadProgression.single.firstWeightKg, 50);
    expect(summary.loadProgression.single.latestWeightKg, 60);
  });

  test('uses bounded canonical pages and propagates reader failures', () async {
    final source = _FakeReader([
      for (var index = 0; index < 8; index++)
        _session('s$index', WorkoutSessionSource.personal,
            '2026-09-0${index + 1}', 1, 1),
    ]);
    final result = await WorkoutAnalyticsEngine(source).summarize(
      userId: 'u1',
      range: range,
      pageSize: 2,
    );
    expect(result.isSuccess, isTrue);
    expect(source.requestedLimits, everyElement(2));

    final failed = await WorkoutAnalyticsEngine(_FakeReader([], fail: true))
        .summarize(userId: 'u1', range: range);
    expect(failed.failureOrNull, isA<NetworkFailure>());
  });
}

CanonicalWorkoutSession _session(
  String id,
  WorkoutSessionSource source,
  String? completedDate,
  int reps,
  double weight, {
  bool skipped = false,
}) {
  final completedAt = completedDate == null
      ? null
      : DateTime.parse('${completedDate}T12:00:00Z');
  return CanonicalWorkoutSession(
    id: id,
    sourceSessionId: id,
    userId: 'u1',
    source: source,
    isCompleted: completedAt != null,
    completedAt: completedAt,
    durationSeconds: 1800,
    exercises: [
      CanonicalWorkoutExercise(
        id: 'exercise-row',
        internalExerciseId: 'bench',
        primaryMuscleGroup: 'chest',
        sets: [
          CanonicalWorkoutSet(
            id: '$id-set',
            sessionId: id,
            exerciseId: 'exercise-row',
            setNumber: 1,
            reps: reps,
            weightKg: weight,
            isSkipped: skipped,
            isCompleted: !skipped && completedAt != null,
            completedAt: skipped ? null : completedAt,
          ),
        ],
      ),
    ],
  );
}

class _FakeReader implements CanonicalWorkoutReader {
  final List<CanonicalWorkoutSession> all;
  final bool fail;
  final List<int> requestedLimits = [];
  _FakeReader(this.all, {this.fail = false});

  @override
  Future<Result<CanonicalWorkoutPage>> history({
    required String userId,
    CanonicalWorkoutCursor? cursor,
    int limit = 20,
  }) async {
    if (fail) return const Result.failure(NetworkFailure());
    requestedLimits.add(limit);
    final offset = cursor == null ? 0 : int.parse(cursor.toString());
    final sorted = [...all]..sort((a, b) =>
        (b.completedAt ?? DateTime(0)).compareTo(a.completedAt ?? DateTime(0)));
    final slice = sorted.skip(offset).take(limit).toList();
    final nextOffset = offset + slice.length;
    return Result.success(CanonicalWorkoutPage(
      sessions: slice,
      hasMore: nextOffset < sorted.length,
      nextCursor: nextOffset < sorted.length
          ? CanonicalWorkoutCursor('$nextOffset')
          : null,
    ));
  }
}
