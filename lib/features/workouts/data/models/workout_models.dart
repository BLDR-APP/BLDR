import 'package:bldr_fitness/features/workouts/domain/entities/exercise.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/paused_workout_summary.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';

/// Conversões entre as entidades de Workouts e os maps do Supabase
/// (formatos produzidos pelo WorkoutService/ExerciseService legados).
class WorkoutModels {
  static List<String> _stringList(dynamic v) =>
      v is List ? v.map((e) => e.toString()).toList() : const [];

  static DateTime? _date(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  static double? _double(dynamic v) => (v as num?)?.toDouble();

  // --- Exercise ---

  static Exercise exerciseFromMap(Map<String, dynamic> map) => Exercise(
        id: map['id'] as String?,
        exerciseDbId: map['exercise_db_id'] as String?,
        name: map['name'] as String? ?? '',
        description: map['description'] as String?,
        exerciseType: map['exercise_type'],
        primaryMuscleGroup: map['primary_muscle_group'],
        secondaryMuscleGroups: _stringList(map['secondary_muscle_groups']),
        instructions: _stringList(map['instructions']),
        tips: _stringList(map['tips']),
        imageUrl: map['image_url'] as String?,
        equipmentNeeded: _stringList(map['equipment_needed']),
      );

  // --- Template ---

  static WorkoutTemplate templateFromMap(Map<String, dynamic> map) {
    final rawExercises =
        (map['workout_template_exercises'] as List?)?.cast<Map>() ?? const [];
    return WorkoutTemplate(
      id: map['id'] as String?,
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      workoutType: map['workout_type'] as String?,
      estimatedDurationMinutes: map['estimated_duration_minutes'] as int?,
      difficultyLevel: map['difficulty_level'] as int?,
      isPublic: map['is_public'] as bool? ?? false,
      createdAt: _date(map['created_at']),
      createdByName: (map['user_profiles'] as Map?)?['full_name'] as String?,
      source: map['source'] as String?,
      exercises: rawExercises
          .map((e) => templateExerciseFromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  static TemplateExercise templateExerciseFromMap(Map<String, dynamic> map) {
    final exerciseMap = map['exercises'];
    return TemplateExercise(
      id: map['id'] as String?,
      orderIndex: map['order_index'] as int? ?? 0,
      sets: map['sets'] as int? ?? 1,
      reps: map['reps'] as int?,
      durationSeconds: map['duration_seconds'] as int?,
      restSeconds: map['rest_seconds'] as int?,
      weightKg: _double(map['weight_kg']),
      distanceMeters: _double(map['distance_meters']),
      notes: map['notes'] as String?,
      exerciseDbId: map['exercise_db_id'] as String?,
      exercise: exerciseMap is Map
          ? exerciseFromMap(Map<String, dynamic>.from(exerciseMap))
          : null,
      freeName: map['free_name'] as String?,
    );
  }

  /// Formato aceito por create/updateWorkoutTemplate do service legado.
  ///
  /// free_name só é gravado quando não há exercise_id nem exercise_db_id
  /// (exercício gerado pelo HAVOK, sem match na biblioteca —
  /// BACKLOG_FUNCIONAL.md B5). Exercícios normais continuam como estavam.
  static Map<String, dynamic> templateExerciseToServiceMap(TemplateExercise e) {
    final exerciseId = e.exercise?.id;
    final exerciseDbId = e.exerciseDbId ?? e.exercise?.exerciseDbId;
    return {
      'sets': e.sets,
      'reps': e.reps,
      'duration_seconds': e.durationSeconds,
      'rest_seconds': e.restSeconds,
      'weight_kg': e.weightKg,
      'distance_meters': e.distanceMeters,
      'notes': e.notes,
      'exercise_id': exerciseId,
      'exercise_db_id': exerciseDbId,
      if (exerciseId == null && exerciseDbId == null && e.freeName != null)
        'free_name': e.freeName,
    };
  }

  static PausedWorkoutSummary pausedSummaryFromMap(Map<String, dynamic> map) =>
      PausedWorkoutSummary(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? 'Treino',
        source: map['source'] as String? ?? 'free',
        startedAt: _date(map['started_at']),
        totalExercises: map['total_exercises'] as int? ?? 0,
        completedExercises: map['completed_exercises'] as int? ?? 0,
        currentExerciseName: map['current_exercise_name'] as String? ?? '',
      );

  // --- Session / sets ---

  static WorkoutSession sessionFromMap(Map<String, dynamic> map) {
    final template = map['workout_templates'] as Map?;
    final rawSets =
        (map['workout_exercise_sets'] as List?)?.cast<Map>() ?? const [];
    return WorkoutSession(
      id: map['id'] as String?,
      name: map['name'] as String? ?? '',
      templateId: map['workout_template_id'] as String?,
      startedAt: _date(map['started_at']),
      completedAt: _date(map['completed_at']),
      totalDurationSeconds: map['total_duration_seconds'] as int?,
      notes: map['notes'] as String?,
      isCompleted: map['is_completed'] as bool? ?? map['completed_at'] != null,
      templateName: template?['name'] as String?,
      workoutType: template?['workout_type'] as String?,
      templateEstimatedDurationMinutes:
          template?['estimated_duration_minutes'] as int?,
      sets:
          rawSets.map((s) => setFromMap(Map<String, dynamic>.from(s))).toList(),
    );
  }

  static WorkoutSet setFromMap(Map<String, dynamic> map) {
    final exerciseMap = map['exercises'];
    return WorkoutSet(
      id: map['id'] as String?,
      userWorkoutId: map['user_workout_id'] as String? ?? '',
      exerciseId: map['exercise_id'] as String?,
      exerciseDbId: map['exercise_db_id'] as String?,
      setNumber: map['set_number'] as int? ?? 0,
      orderIndex: map['order_index'] as int?,
      reps: map['reps'] as int?,
      weightKg: _double(map['weight_kg']),
      durationSeconds: map['duration_seconds'] as int?,
      distanceMeters: _double(map['distance_meters']),
      restSeconds: map['rest_seconds'] as int?,
      notes: map['notes'] as String?,
      // Mesma regra do service: sem coluna is_completed, vale completed_at.
      isCompleted: map['is_completed'] as bool? ?? map['completed_at'] != null,
      isSkipped: map['is_skipped'] as bool? ?? false,
      completedAt: _date(map['completed_at']),
      exercise: exerciseMap is Map
          ? exerciseFromMap(Map<String, dynamic>.from(exerciseMap))
          : null,
      freeName: map['free_name'] as String?,
    );
  }
}
