import 'package:bldr_fitness/features/workouts/domain/entities/exercise.dart';

/// Prescrição de UMA série dentro de um exercício do template
/// (TREINOS_V2.md, P2). Persistida em `workout_template_exercises.set_details`.
class TemplateSetDetail {
  final double? weightKg;
  final int? reps;
  final int? restSeconds;

  const TemplateSetDetail({this.weightKg, this.reps, this.restSeconds});

  Map<String, dynamic> toJson() => {
        'weight_kg': weightKg,
        'reps': reps,
        'rest_seconds': restSeconds,
      };

  factory TemplateSetDetail.fromJson(Map<String, dynamic> json) =>
      TemplateSetDetail(
        weightKg: (json['weight_kg'] as num?)?.toDouble(),
        reps: (json['reps'] as num?)?.toInt(),
        restSeconds: (json['rest_seconds'] as num?)?.toInt(),
      );

  /// Lê o valor de `set_details` (lista JSON); qualquer outro formato → vazio.
  static List<TemplateSetDetail> listFromJson(dynamic value) => value is List
      ? value
          .whereType<Map>()
          .map((m) => TemplateSetDetail.fromJson(Map<String, dynamic>.from(m)))
          .toList()
      : const [];

  /// Séries efetivas de um exercício: a lista por série quando existir;
  /// senão, [sets] cópias dos valores agregados (templates antigos).
  static List<TemplateSetDetail> resolve({
    required int sets,
    int? reps,
    double? weightKg,
    int? restSeconds,
    List<TemplateSetDetail> details = const [],
  }) {
    if (details.isNotEmpty) return details;
    final count = sets < 1 ? 1 : sets;
    return List.generate(
      count,
      (_) => TemplateSetDetail(
          weightKg: weightKg, reps: reps, restSeconds: restSeconds),
    );
  }
}

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

  /// Carga/reps/descanso de cada série. Vazia em templates antigos — use
  /// [resolvedSets] para obter as séries efetivas.
  final List<TemplateSetDetail> setDetails;

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
    this.setDetails = const [],
  });

  List<TemplateSetDetail> get resolvedSets => TemplateSetDetail.resolve(
        sets: sets,
        reps: reps,
        weightKg: weightKg,
        restSeconds: restSeconds,
        details: setDetails,
      );
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
