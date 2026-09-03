import 'package:bldr_fitness/features/workouts/domain/entities/exercise.dart';

/// Uma série executada/planejada num treino (Supabase `workout_exercise_sets`).
class WorkoutSet {
  final String? id;
  final String userWorkoutId;
  final String? exerciseId;
  final String? exerciseDbId;
  final int setNumber;
  final int? orderIndex;
  final int? reps;
  final double? weightKg;
  final int? durationSeconds;
  final double? distanceMeters;
  final int? restSeconds;
  final String? notes;
  final bool isCompleted;
  final bool isSkipped;
  final DateTime? completedAt;
  final Exercise? exercise;

  /// Nome do exercício quando a série veio de um template com exercício de
  /// nome livre (BACKLOG_FUNCIONAL.md B5 — HAVOK) e não tem exercise_id nem
  /// exercise_db_id. Copiado do template ao iniciar a sessão.
  final String? freeName;

  const WorkoutSet({
    this.id,
    required this.userWorkoutId,
    this.exerciseId,
    this.exerciseDbId,
    required this.setNumber,
    this.orderIndex,
    this.reps,
    this.weightKg,
    this.durationSeconds,
    this.distanceMeters,
    this.restSeconds,
    this.notes,
    this.isCompleted = false,
    this.isSkipped = false,
    this.completedAt,
    this.exercise,
    this.freeName,
  });
}

/// Sessão de treino do usuário (Supabase `user_workouts`).
class WorkoutSession {
  final String? id;
  final String name;
  final String? templateId;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? totalDurationSeconds;
  final String? notes;
  final bool isCompleted;
  final String? templateName;
  final String? workoutType;
  final int? templateEstimatedDurationMinutes;
  final List<WorkoutSet> sets;

  const WorkoutSession({
    this.id,
    required this.name,
    this.templateId,
    this.startedAt,
    this.completedAt,
    this.totalDurationSeconds,
    this.notes,
    this.isCompleted = false,
    this.templateName,
    this.workoutType,
    this.templateEstimatedDurationMinutes,
    this.sets = const [],
  });

  bool get isActive => !isCompleted && completedAt == null;

  bool get completedViaWhoop => notes?.toLowerCase().contains('whoop') ?? false;

  int get completedSetCount => sets.where((set) => set.isCompleted).length;

  double get completedVolumeKg => sets
      .where((set) => set.isCompleted)
      .fold(0, (total, set) => total + ((set.reps ?? 0) * (set.weightKg ?? 0)));
}
