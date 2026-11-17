/// Intervalo semiaberto [start, end) usado pelo Analytics Core.
class WorkoutAnalyticsRange {
  final DateTime start;
  final DateTime end;

  const WorkoutAnalyticsRange({required this.start, required this.end});

  Duration get duration => end.difference(start);
  bool contains(DateTime value) =>
      !value.isBefore(start) && value.isBefore(end);
}

class WorkoutVolumePoint {
  final DateTime date;
  final double volumeKg;
  const WorkoutVolumePoint(this.date, this.volumeKg);
}

class ExerciseLoadProgression {
  final String exerciseId;
  final double firstWeightKg;
  final double latestWeightKg;
  final int observations;

  const ExerciseLoadProgression({
    required this.exerciseId,
    required this.firstWeightKg,
    required this.latestWeightKg,
    required this.observations,
  });

  double get deltaKg => latestWeightKg - firstWeightKg;
}

class WorkoutAnalyticsSummary {
  final WorkoutAnalyticsRange range;
  final int completedSessions;
  final int activeDays;
  final double weeklyFrequency;
  final double consistencyPercent;
  final double totalVolumeKg;
  final double? averageDurationSeconds;
  final Map<String, double> volumeByMuscleGroup;
  final Map<String, int> completedSetsByExercise;
  final List<WorkoutVolumePoint> volumeSeries;
  final List<ExerciseLoadProgression> loadProgression;
  final double? previousPeriodVolumeKg;
  final double? volumeDeltaPercent;

  const WorkoutAnalyticsSummary({
    required this.range,
    required this.completedSessions,
    required this.activeDays,
    required this.weeklyFrequency,
    required this.consistencyPercent,
    required this.totalVolumeKg,
    required this.averageDurationSeconds,
    required this.volumeByMuscleGroup,
    required this.completedSetsByExercise,
    required this.volumeSeries,
    required this.loadProgression,
    required this.previousPeriodVolumeKg,
    required this.volumeDeltaPercent,
  });

  bool get hasData => completedSessions > 0;
}
