import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';

/// Mapper TRANSITÓRIO: formato de map com chaves `club_*` que o banner e a
/// tela de treino ativo do Club ainda consomem. Remover quando forem tipados.
Map<String, dynamic> sessionToClubLegacyMap(WorkoutSession w) => {
      'id': w.id,
      'name': w.name,
      'workout_template_id': w.templateId,
      'started_at': w.startedAt?.toIso8601String(),
      'completed_at': w.completedAt?.toIso8601String(),
      'total_duration_seconds': w.totalDurationSeconds,
      'notes': w.notes,
      'is_completed': w.isCompleted,
      if (w.templateName != null || w.templateEstimatedDurationMinutes != null)
        'club_workout_templates': {
          'name': w.templateName,
          'workout_type': w.workoutType,
          'estimated_duration_minutes': w.templateEstimatedDurationMinutes,
        },
      'club_workout_exercise_sets': w.sets
          .map((s) => {
                'id': s.id,
                'user_workout_id': s.userWorkoutId,
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
                'exercise_db_id': s.exerciseDbId ?? s.exercise?.exerciseDbId,
                'free_name': s.freeName,
                'exercises': s.exercise == null
                    ? null
                    : {
                        'id': s.exercise!.id,
                        'name': s.exercise!.name,
                        'primary_muscle_group': s.exercise!.primaryMuscleGroup,
                        'instructions': s.exercise!.instructions,
                        'exercise_db_id': s.exercise!.exerciseDbId,
                      },
              })
          .toList(),
    };
