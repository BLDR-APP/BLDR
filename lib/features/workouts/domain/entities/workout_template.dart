import 'package:bldr_fitness/features/workouts/domain/entities/exercise.dart';

/// Prescrição de um exercício dentro de um template.
class TemplateExercise {
  final String? id;
  final int orderIndex;
  final int sets;
  final int? reps;
  final int? durationSeconds;
  final int? restSeconds;
  final double? weightKg;
  final double? distanceMeters;
  final String? notes;
  final String? exerciseDbId;
  final Exercise? exercise;

  /// Nome do exercício quando ele não veio da biblioteca (BACKLOG_FUNCIONAL.md
  /// B5) — caso do HAVOK, que gera nome livre sem exercise_id/exercise_db_id.
  /// Nulo para exercícios normais da biblioteca.
  final String? freeName;

  const TemplateExercise({
    this.id,
    required this.orderIndex,
    this.sets = 1,
    this.reps,
    this.durationSeconds,
    this.restSeconds,
    this.weightKg,
    this.distanceMeters,
    this.notes,
    this.exerciseDbId,
    this.exercise,
    this.freeName,
  });
}

/// Template de treino (Supabase `workout_templates`).
class WorkoutTemplate {
  final String? id;
  final String name;
  final String? description;
  final String? workoutType;
  final int? estimatedDurationMinutes;
  final int? difficultyLevel;
  final bool isPublic;
  final DateTime? createdAt;
  final String? createdByName;
  final List<TemplateExercise> exercises;
  /// Origem do template: 'havok' | 'user' | 'bldr'. Nullable para legado.
  final String? source;

  const WorkoutTemplate({
    this.id,
    required this.name,
    this.description,
    this.workoutType,
    this.estimatedDurationMinutes,
    this.difficultyLevel,
    this.isPublic = false,
    this.createdAt,
    this.createdByName,
    this.exercises = const [],
    this.source,
  });
}
