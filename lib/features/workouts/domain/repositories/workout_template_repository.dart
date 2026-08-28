import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';

abstract class WorkoutTemplateRepository {
  Future<Result<List<WorkoutTemplate>>> templates({
    String? workoutType,
    int? difficultyLevel,
    bool publicOnly = false,
  });

  /// Template com exercícios, já enriquecidos quando vêm do ExerciseDB.
  Future<Result<WorkoutTemplate?>> templateWithExercises(String templateId);

  Future<Result<WorkoutTemplate>> create(WorkoutTemplate template);

  Future<Result<WorkoutTemplate>> update(WorkoutTemplate template);

  Future<Result<void>> delete(String templateId);
}
