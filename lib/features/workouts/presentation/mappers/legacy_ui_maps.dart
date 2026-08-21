import 'package:bldr_fitness/features/workouts/domain/entities/paused_workout_summary.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';

/// Mappers TRANSITÓRIOS (Fase 4b): convertem entidades de Workouts para o
/// formato de map que widgets/telas ainda não migrados consomem
/// (WorkoutCardWidget, ContinueWorkoutCard, CreateWorkoutScreen.editTemplate).
/// Remover conforme esses widgets forem tipados. Não usar em código novo.

Map<String, dynamic> templateToLegacyMap(WorkoutTemplate t) => {
      'id': t.id,
      'name': t.name,
      'description': t.description,
      'workout_type': t.workoutType,
      'estimated_duration_minutes': t.estimatedDurationMinutes,
      'difficulty_level': t.difficultyLevel,
      'is_public': t.isPublic,
      if (t.createdByName != null)
        'user_profiles': {'full_name': t.createdByName},
      'workout_template_exercises': t.exercises
          .map((e) => {
                'id': e.id,
                'order_index': e.orderIndex,
                'sets': e.sets,
                'reps': e.reps,
                'duration_seconds': e.durationSeconds,
                'rest_seconds': e.restSeconds,
                'weight_kg': e.weightKg,
                'distance_meters': e.distanceMeters,
                'notes': e.notes,
                'exercise_db_id': e.exerciseDbId,
                'exercises': e.exercise == null
                    ? null
                    : {
                        'id': e.exercise!.id,
                        'exercise_db_id': e.exercise!.exerciseDbId,
                        'name': e.exercise!.name,
                        'exercise_type': e.exercise!.exerciseType,
                        'primary_muscle_group':
                            e.exercise!.primaryMuscleGroup,
                        'image_url': e.exercise!.imageUrl,
                        'instructions': e.exercise!.instructions,
                      },
              })
          .toList(),
    };

/// Formato consumido pelo banner de treino ativo e pelo card do dashboard.
Map<String, dynamic> sessionToLegacyMap(WorkoutSession w) => {
      'id': w.id,
      'name': w.name,
      'workout_template_id': w.templateId,
      'started_at': w.startedAt?.toIso8601String(),
      'completed_at': w.completedAt?.toIso8601String(),
      'total_duration_seconds': w.totalDurationSeconds,
      'notes': w.notes,
      'is_completed': w.isCompleted,
      if (w.templateName != null ||
          w.templateEstimatedDurationMinutes != null)
        'workout_templates': {
          'name': w.templateName,
          'workout_type': w.workoutType,
          'estimated_duration_minutes': w.templateEstimatedDurationMinutes,
        },
      'workout_exercise_sets': w.sets
          .map((s) => {
                'id': s.id,
                'set_number': s.setNumber,
                'order_index': s.orderIndex,
                'reps': s.reps,
                'weight_kg': s.weightKg,
                'duration_seconds': s.durationSeconds,
                'distance_meters': s.distanceMeters,
                'rest_seconds': s.restSeconds,
                'notes': s.notes,
                'is_completed': s.isCompleted,
                'completed_at': s.completedAt?.toIso8601String(),
                'exercise_id': s.exerciseId,
                'exercise_db_id': s.exerciseDbId,
                'exercises': s.exercise == null
                    ? null
                    : {
                        'id': s.exercise!.id,
                        'name': s.exercise!.name,
                        'primary_muscle_group':
                            s.exercise!.primaryMuscleGroup,
                        'exercise_db_id': s.exercise!.exerciseDbId,
                        'instructions': s.exercise!.instructions,
                      },
              })
          .toList(),
    };

Map<String, dynamic> pausedToLegacyMap(PausedWorkoutSummary p) => {
      'id': p.id,
      'name': p.name,
      'source': p.source,
      'started_at': p.startedAt?.toIso8601String(),
      'total_exercises': p.totalExercises,
      'completed_exercises': p.completedExercises,
      'current_exercise_name': p.currentExerciseName,
    };
