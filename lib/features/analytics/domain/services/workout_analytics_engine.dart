import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/analytics/domain/entities/workout_analytics.dart';
import 'package:bldr_fitness/features/analytics/domain/repositories/workout_analytics_reader.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/canonical_workout.dart';
import 'package:bldr_fitness/features/workouts/domain/repositories/canonical_workout_reader.dart';

/// Calcula métricas somente a partir das sessões canônicas já persistidas.
///
/// O intervalo é UTC e semiaberto: [start, end). Séries pendentes ou ignoradas
/// não entram em volume, progressão ou distribuição.
class WorkoutAnalyticsEngine implements WorkoutAnalyticsReader {
  final CanonicalWorkoutReader _reader;

  const WorkoutAnalyticsEngine(this._reader);

  @override
  Future<Result<WorkoutAnalyticsSummary>> summarize({
    required String userId,
    required WorkoutAnalyticsRange range,
    bool comparePreviousPeriod = true,
    int pageSize = 50,
    int maxPages = 50,
  }) async {
    if (!range.end.isAfter(range.start) || pageSize <= 0 || maxPages <= 0) {
      return const Result.failure(
          ValidationFailure('Parâmetros inválidos para analytics.'));
    }
    final comparisonStart = comparePreviousPeriod
        ? range.start.subtract(range.duration)
        : range.start;
    final read = await _readUntil(
      userId: userId,
      start: comparisonStart,
      end: range.end,
      pageSize: pageSize,
      maxPages: maxPages,
    );
    if (read.isFailure) return Result.failure(read.failureOrNull!);

    final sessions = read.valueOrNull!;
    final current =
        sessions.where((session) => _inRange(session, range)).toList();
    final previousRange = WorkoutAnalyticsRange(
      start: comparisonStart,
      end: range.start,
    );
    final previous = comparePreviousPeriod
        ? sessions.where((session) => _inRange(session, previousRange)).toList()
        : const <CanonicalWorkoutSession>[];
    final result = _aggregate(range, current, previous);
    return Result.success(result);
  }

  Future<Result<List<CanonicalWorkoutSession>>> _readUntil({
    required String userId,
    required DateTime start,
    required DateTime end,
    required int pageSize,
    required int maxPages,
  }) async {
    CanonicalWorkoutCursor? cursor;
    final all = <CanonicalWorkoutSession>[];
    for (var pageIndex = 0; pageIndex < maxPages; pageIndex++) {
      final pageResult = await _reader.history(
        userId: userId,
        cursor: cursor,
        limit: pageSize,
      );
      if (pageResult.isFailure) {
        return Result.failure(pageResult.failureOrNull!);
      }
      final page = pageResult.valueOrNull!;
      all.addAll(page.sessions);
      final oldest = page.sessions.lastOrNull?._analyticsTimestamp;
      if (!page.hasMore || (oldest != null && oldest.isBefore(start))) {
        return Result.success(all);
      }
      cursor = page.nextCursor;
      if (cursor == null) return Result.success(all);
    }
    return const Result.failure(ValidationFailure(
      'O intervalo excede o limite de páginas permitido para analytics.',
    ));
  }

  WorkoutAnalyticsSummary _aggregate(
    WorkoutAnalyticsRange range,
    List<CanonicalWorkoutSession> sessions,
    List<CanonicalWorkoutSession> previous,
  ) {
    final completed = sessions.where((item) => item.isCompleted).toList()
      ..sort((a, b) => a.completedAt!.compareTo(b.completedAt!));
    final volumesByDay = <DateTime, double>{};
    final volumesByMuscle = <String, double>{};
    final setsByExercise = <String, int>{};
    final loads = <String, List<_LoadObservation>>{};
    var volume = 0.0;
    var durationTotal = 0;
    var durationCount = 0;

    for (final session in completed) {
      final completedAt = session.completedAt!;
      if (session.durationSeconds case final duration? when duration > 0) {
        durationTotal += duration;
        durationCount++;
      }
      for (final exercise in session.exercises) {
        final exerciseId = exercise.internalExerciseId ??
            exercise.exerciseDbId ??
            exercise.templateExerciseId;
        for (final set in exercise.sets) {
          if (!set.isCompleted || set.isSkipped) continue;
          final setVolume = _setVolume(set);
          if (setVolume == null) continue;
          volume += setVolume;
          final day = DateTime.utc(
              completedAt.year, completedAt.month, completedAt.day);
          volumesByDay[day] = (volumesByDay[day] ?? 0) + setVolume;
          if (exercise.primaryMuscleGroup case final muscle?
              when muscle.isNotEmpty) {
            volumesByMuscle[muscle] =
                (volumesByMuscle[muscle] ?? 0) + setVolume;
          }
          if (exerciseId != null) {
            setsByExercise[exerciseId] = (setsByExercise[exerciseId] ?? 0) + 1;
            if (set.weightKg case final weight? when weight >= 0) {
              loads.putIfAbsent(exerciseId, () => []).add(
                    _LoadObservation(completedAt, weight),
                  );
            }
          }
        }
      }
    }

    final previousVolume = _volumeOf(previous);
    final days = <DateTime>{
      for (final session in completed)
        DateTime.utc(session.completedAt!.year, session.completedAt!.month,
            session.completedAt!.day),
    };
    final dayCount = range.duration.inDays;
    final progression = loads.entries.map((entry) {
      final observations = entry.value..sort((a, b) => a.at.compareTo(b.at));
      return ExerciseLoadProgression(
        exerciseId: entry.key,
        firstWeightKg: observations.first.weightKg,
        latestWeightKg: observations.last.weightKg,
        observations: observations.length,
      );
    }).toList()
      ..sort((a, b) => a.exerciseId.compareTo(b.exerciseId));
    final series = volumesByDay.entries
        .map((entry) => WorkoutVolumePoint(entry.key, entry.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return WorkoutAnalyticsSummary(
      range: range,
      completedSessions: completed.length,
      activeDays: days.length,
      weeklyFrequency: dayCount == 0 ? 0 : completed.length / dayCount * 7,
      consistencyPercent: dayCount == 0 ? 0 : days.length / dayCount * 100,
      totalVolumeKg: volume,
      averageDurationSeconds:
          durationCount == 0 ? null : durationTotal / durationCount,
      volumeByMuscleGroup: Map.unmodifiable(volumesByMuscle),
      completedSetsByExercise: Map.unmodifiable(setsByExercise),
      volumeSeries: List.unmodifiable(series),
      loadProgression: List.unmodifiable(progression),
      previousPeriodVolumeKg: previous.isEmpty ? null : previousVolume,
      volumeDeltaPercent: previousVolume == null || previousVolume == 0
          ? null
          : (volume - previousVolume) / previousVolume * 100,
    );
  }

  static bool _inRange(
      CanonicalWorkoutSession session, WorkoutAnalyticsRange range) {
    final at = session.completedAt;
    return session.isCompleted && at != null && range.contains(at);
  }

  static double? _setVolume(CanonicalWorkoutSet set) {
    final reps = set.reps;
    final weight = set.weightKg;
    if (reps == null || weight == null || reps < 0 || weight < 0) return null;
    return reps * weight;
  }

  static double? _volumeOf(List<CanonicalWorkoutSession> sessions) {
    var hadCompletedSet = false;
    var total = 0.0;
    for (final session in sessions.where((item) => item.isCompleted)) {
      for (final exercise in session.exercises) {
        for (final set in exercise.sets) {
          if (!set.isCompleted || set.isSkipped) continue;
          final volume = _setVolume(set);
          if (volume == null) continue;
          hadCompletedSet = true;
          total += volume;
        }
      }
    }
    return hadCompletedSet ? total : null;
  }
}

class _LoadObservation {
  final DateTime at;
  final double weightKg;
  const _LoadObservation(this.at, this.weightKg);
}

extension on CanonicalWorkoutSession {
  DateTime? get _analyticsTimestamp => completedAt ?? startedAt;
}
