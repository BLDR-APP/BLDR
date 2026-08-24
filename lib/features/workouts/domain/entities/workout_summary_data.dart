import 'package:bldr_fitness/features/workouts/domain/entities/muscle_normalizer.dart';

class WorkoutSummaryData {
  final String workoutId;
  final String workoutName;
  final String source; // 'free' | 'club'
  final int durationSeconds;
  final double volumeKg;
  final int setsCompleted;
  final int? exerciseCount;
  final List<String> muscleGroups;
  final BldrMuscleMapData? muscleMapData;
  final List<PersonalRecordData> newPRs;
  final double? previousVolumeKg;
  final int xpEarned;
  final DateTime completedAt;

  const WorkoutSummaryData({
    required this.workoutId,
    required this.workoutName,
    required this.source,
    required this.durationSeconds,
    required this.volumeKg,
    required this.setsCompleted,
    this.exerciseCount,
    required this.muscleGroups,
    this.muscleMapData,
    required this.newPRs,
    this.previousVolumeKg,
    required this.xpEarned,
    required this.completedAt,
  });

  String get durationLabel {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    if (m == 0) return '${s}s';
    if (s == 0) return '${m}min';
    return '${m}min ${s}s';
  }

  bool get hasDuration => durationSeconds > 0;
  bool get hasVolume => volumeKg > 0;
  bool get hasSets => setsCompleted > 0;

  String get volumeLabel {
    if (volumeKg >= 1000) return '${(volumeKg / 1000).toStringAsFixed(1)}t';
    return '${volumeKg.toStringAsFixed(0)}kg';
  }

  String get completedAtLabel {
    final local = completedAt.toLocal();
    const weekdays = ['', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    const months = [
      '',
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez'
    ];
    final h = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '${weekdays[local.weekday]}, ${local.day} ${months[local.month]} ${local.year} · $h:$min';
  }

  double? get volumeDeltaPercent {
    if (previousVolumeKg == null || previousVolumeKg == 0) return null;
    return ((volumeKg - previousVolumeKg!) / previousVolumeKg!) * 100;
  }
}

class PersonalRecordData {
  final String exerciseName;
  final double newWeightKg;
  final double? previousWeightKg;
  final double? newE1rm;

  const PersonalRecordData({
    required this.exerciseName,
    required this.newWeightKg,
    this.previousWeightKg,
    this.newE1rm,
  });
}
