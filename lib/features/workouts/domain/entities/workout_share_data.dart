import 'package:bldr_fitness/features/workouts/domain/entities/bldr_muscle.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/muscle_normalizer.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_summary_data.dart';

class WorkoutShareData {
  final WorkoutSummaryData summary;
  final String? username;
  final String? avatarUrl;

  const WorkoutShareData({
    required this.summary,
    this.username,
    this.avatarUrl,
  });

  factory WorkoutShareData.fromSummary(
    WorkoutSummaryData summary, {
    String? username,
    String? avatarUrl,
  }) {
    return WorkoutShareData(
      summary: summary,
      username: normalizeUsername(username),
      avatarUrl: avatarUrl,
    );
  }

  String get workoutName => summary.workoutName.trim().isEmpty
      ? 'Treino concluído'
      : summary.workoutName.trim();
  DateTime get completedAt => summary.completedAt;
  int? get durationSeconds =>
      summary.hasDuration ? summary.durationSeconds : null;
  double? get totalVolume => summary.hasVolume ? summary.volumeKg : null;
  int? get totalSets => summary.hasSets ? summary.setsCompleted : null;
  int? get exerciseCount =>
      (summary.exerciseCount ?? 0) > 0 ? summary.exerciseCount : null;
  int? get xpEarned => summary.xpEarned > 0 ? summary.xpEarned : null;
  List<PersonalRecordData> get prs => summary.newPRs;
  BldrMuscleMapData? get muscleMapData => summary.muscleMapData;
  String? get handle => username == null ? null : '@$username';

  BldrMuscleMapView get shareMuscleView {
    final data = muscleMapData;
    if (data == null || data.muscles.isEmpty) return BldrMuscleMapView.front;
    final scores = MuscleNormalizer.viewScores(data.muscles);
    if (scores.front > 0 && scores.back > 0) return BldrMuscleMapView.both;
    return data.view;
  }

  List<String> get primaryMuscleLabels {
    final entries = muscleMapData?.muscles.entries.toList() ?? const [];
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).map((e) => _muscleLabel(e.key)).toList();
  }

  static String? normalizeUsername(String? raw) {
    final value = raw?.trim().replaceFirst(RegExp(r'^@+'), '');
    return value == null || value.isEmpty ? null : value;
  }

  static String _muscleLabel(BldrMuscle muscle) => switch (muscle) {
        BldrMuscle.chest => 'Peito',
        BldrMuscle.frontDelts ||
        BldrMuscle.sideDelts ||
        BldrMuscle.rearDelts =>
          'Ombros',
        BldrMuscle.biceps => 'Bíceps',
        BldrMuscle.triceps => 'Tríceps',
        BldrMuscle.forearms => 'Antebraços',
        BldrMuscle.abs => 'Abdômen',
        BldrMuscle.obliques => 'Oblíquos',
        BldrMuscle.traps => 'Trapézio',
        BldrMuscle.lats => 'Dorsais',
        BldrMuscle.lowerBack => 'Lombar',
        BldrMuscle.glutes => 'Glúteos',
        BldrMuscle.quads => 'Quadríceps',
        BldrMuscle.hamstrings => 'Posteriores',
        BldrMuscle.calves => 'Panturrilhas',
        BldrMuscle.adductors => 'Adutores',
      };
}

enum WorkoutShareStyle { performance, muscleMap, minimal }
