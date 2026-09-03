import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/services/exercise_db_rapid_service.dart';
import 'package:bldr_fitness/services/workout_service.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/paused_workout_summary.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/exercise_display_name.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/muscle_normalizer.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_summary_data.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';
import 'package:bldr_fitness/features/workouts/domain/repositories/workout_session_repository.dart';
import 'package:bldr_fitness/features/workouts/domain/repositories/workout_template_repository.dart';
import 'package:bldr_fitness/features/workouts/data/models/workout_models.dart';

/// Implementações que DELEGAM ao WorkoutService legado (estratégia strangler,
/// Fase 4a): o service atua como datasource; as queries migram para
/// datasources dedicados na Fase 4b, sem que domain/presentation mudem.
Future<Result<T>> _guard<T>(Future<T> Function() action) async {
  try {
    return Result.success(await action());
  } on Failure catch (f) {
    return Result.failure(f);
  } on supabase.PostgrestException catch (e) {
    return Result.failure(ServerFailure(e.message, cause: e));
  } on SocketException catch (e) {
    return Result.failure(NetworkFailure('Sem conexão com a internet.', e));
  } on TimeoutException catch (e) {
    return Result.failure(NetworkFailure('Tempo de conexão esgotado.', e));
  } catch (e) {
    return Result.failure(UnexpectedFailure('Ocorreu um erro inesperado.', e));
  }
}

class WorkoutTemplateRepositoryImpl implements WorkoutTemplateRepository {
  final WorkoutService _service;

  WorkoutTemplateRepositoryImpl(this._service);

  @override
  Future<Result<List<WorkoutTemplate>>> templates({
    String? workoutType,
    int? difficultyLevel,
    bool publicOnly = false,
  }) =>
      _guard(() async {
        final rows = await _service.getWorkoutTemplates(
          workoutType: workoutType,
          difficultyLevel: difficultyLevel,
          publicOnly: publicOnly,
        );
        return rows.map(WorkoutModels.templateFromMap).toList();
      });

  @override
  Future<Result<WorkoutTemplate?>> templateWithExercises(String templateId) =>
      _guard(() async {
        final map = await _service.getWorkoutTemplateWithExercises(templateId);
        return map == null ? null : WorkoutModels.templateFromMap(map);
      });

  @override
  Future<Result<WorkoutTemplate>> create(WorkoutTemplate template) =>
      _guard(() async {
        final map = await _service.createWorkoutTemplate(
          name: template.name,
          description: template.description,
          workoutType: template.workoutType ?? 'força',
          estimatedDurationMinutes: template.estimatedDurationMinutes,
          difficultyLevel: template.difficultyLevel,
          isPublic: template.isPublic,
          source: template.source ?? 'user',
          exercises: template.exercises
              .map(WorkoutModels.templateExerciseToServiceMap)
              .toList(),
        );
        return WorkoutModels.templateFromMap(map);
      });

  @override
  Future<Result<WorkoutTemplate>> update(WorkoutTemplate template) =>
      _guard(() async {
        final id = template.id;
        if (id == null) {
          throw const ValidationFailure(
              'Template sem id não pode ser atualizado.');
        }
        final map = await _service.updateWorkoutTemplate(
          id: id,
          name: template.name,
          description: template.description,
          workoutType: template.workoutType ?? 'força',
          estimatedDurationMinutes: template.estimatedDurationMinutes,
          difficultyLevel: template.difficultyLevel,
          exercises: template.exercises
              .map(WorkoutModels.templateExerciseToServiceMap)
              .toList(),
        );
        return WorkoutModels.templateFromMap(map);
      });

  @override
  Future<Result<void>> delete(String templateId) =>
      _guard(() => _service.deleteWorkoutTemplate(templateId));
}

class WorkoutSessionRepositoryImpl implements WorkoutSessionRepository {
  final WorkoutService _service;

  WorkoutSessionRepositoryImpl(this._service);

  @override
  Future<Result<WorkoutSession>> start({
    required String name,
    String? templateId,
  }) =>
      _guard(() async {
        final map = await _service.startWorkout(
            name: name, workoutTemplateId: templateId);
        return WorkoutModels.sessionFromMap(map);
      });

  @override
  Future<Result<WorkoutSession>> complete({
    required String workoutId,
    String? notes,
  }) =>
      _guard(() async {
        final map =
            await _service.completeWorkout(workoutId: workoutId, notes: notes);
        return WorkoutModels.sessionFromMap(map);
      });

  @override
  Future<Result<WorkoutSet>> logSet(WorkoutSet set) => _guard(() async {
        final exerciseId = set.exerciseId;
        // Exercícios HAVOK (freeName) não têm exercise_id — permitido.
        if (exerciseId == null &&
            set.freeName == null &&
            set.exerciseDbId == null) {
          throw const ValidationFailure('Série sem exercise_id nem freeName.');
        }
        final map = await _service.logExerciseSet(
          userWorkoutId: set.userWorkoutId,
          exerciseId: exerciseId,
          setNumber: set.setNumber,
          reps: set.reps,
          weightKg: set.weightKg,
          durationSeconds: set.durationSeconds,
          distanceMeters: set.distanceMeters,
          restSeconds: set.restSeconds,
          notes: set.notes,
        );
        return WorkoutModels.setFromMap(map);
      });

  @override
  Future<Result<void>> completeSet({
    required String setId,
    int? reps,
    double? weightKg,
  }) =>
      _guard(() =>
          _service.completeSet(setId: setId, reps: reps, weight: weightKg));

  @override
  Future<Result<void>> undoSet(String setId) =>
      _guard(() => _service.undoSet(setId: setId));

  @override
  Future<Result<void>> skipSet(String setId) =>
      _guard(() => _service.skipSet(setId: setId));

  @override
  Future<Result<bool>> hasActiveWorkout() => _guard(_service.hasActiveWorkout);

  @override
  Future<Result<WorkoutSession?>> activeWorkoutDetails() => _guard(() async {
        final map = await _service.getActiveWorkoutWithDetailsOnce();
        return map == null ? null : WorkoutModels.sessionFromMap(map);
      });

  @override
  Stream<WorkoutSession?> activeWorkoutStream() => _service
      .activeWorkoutStream()
      .map((map) => map == null ? null : WorkoutModels.sessionFromMap(map));

  @override
  Future<Result<WorkoutSession?>> workoutDetails(String workoutId) =>
      _guard(() async {
        final map = await _service.getWorkoutDetails(workoutId);
        return map == null ? null : WorkoutModels.sessionFromMap(map);
      });

  @override
  Future<Result<List<WorkoutSession>>> history({
    String? userId,
    bool completedOnly = false,
    int limit = 20,
  }) =>
      _guard(() async {
        final rows = await _service.getUserWorkouts(
          userId: userId,
          completedOnly: completedOnly,
          limit: limit,
        );
        return rows.map(WorkoutModels.sessionFromMap).toList();
      });

  @override
  Future<Result<List<PausedWorkoutSummary>>> pausedSummaries({int limit = 2}) =>
      _guard(() async {
        final rows = await _service.getPausedWorkoutSummaries(limit: limit);
        return rows.map(WorkoutModels.pausedSummaryFromMap).toList();
      });

  @override
  Future<Result<void>> deletePaused(String workoutId, String source) =>
      _guard(() => _service.deletePausedWorkout(workoutId, source));

  @override
  Future<Result<void>> deleteCompleted(String workoutId) =>
      _guard(() => _service.deleteCompletedWorkout(workoutId));

  @override
  Future<Result<void>> ensureInitialSets(String sessionId, String templateId) =>
      _guard(() => _service.ensureInitialSets(sessionId, templateId));

  @override
  Future<Result<WorkoutSummaryData>> completeWithAnalytics({
    required String workoutId,
    required String source,
    required int setsCompleted,
    int? exerciseCount,
    String? notes,
  }) =>
      _guard(() async {
        final raw = await _service.completeWorkoutWithAnalytics(
          workoutId: workoutId,
          source: source,
          notes: notes,
        );
        final muscleGroups = (raw['muscle_groups'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const <String>[];
        final muscles = MuscleNormalizer.aggregate([
          BldrMuscleContribution(primary: muscleGroups),
        ]);
        final completedAt =
            DateTime.tryParse(raw['completed_at']?.toString() ?? '') ??
                DateTime.now();
        return WorkoutSummaryData(
          workoutId: workoutId,
          workoutName: raw['workout_name'] as String? ?? '',
          source: source,
          durationSeconds: (raw['duration_seconds'] as num?)?.toInt() ?? 0,
          volumeKg: (raw['volume_kg'] as num?)?.toDouble() ?? 0,
          setsCompleted: setsCompleted,
          exerciseCount:
              (raw['exercise_count'] as num?)?.toInt() ?? exerciseCount,
          muscleGroups: muscleGroups,
          muscleMapData: muscles.isEmpty
              ? null
              : BldrMuscleMapData(
                  muscles: muscles,
                  view: MuscleNormalizer.dominantView(muscles),
                ),
          newPRs: await _parsePRs(
            raw['new_prs'],
            workoutId: workoutId,
            source: source,
          ),
          xpEarned: (raw['xp_earned'] as num?)?.toInt() ?? 0,
          completedAt: completedAt,
        );
      });

  Future<List<PersonalRecordData>> _parsePRs(
    dynamic prsJson, {
    required String workoutId,
    required String source,
  }) async {
    if (prsJson == null) return [];
    final prs = prsJson as List;
    if (prs.isEmpty) return [];
    List<Map<String, dynamic>> nameSources;
    try {
      nameSources = await _service.getWorkoutExerciseDisplaySources(
        workoutId: workoutId,
        source: source,
      );
    } catch (_) {
      nameSources = const [];
    }
    final internalById = <String, String?>{};
    final internalByDbId = <String, String?>{};
    for (final nameSource in nameSources) {
      final exerciseId = nameSource['exercise_id']?.toString();
      final exerciseDbId = nameSource['exercise_db_id']?.toString();
      final internalName = nameSource['internal_name']?.toString();
      if (exerciseId != null) internalById[exerciseId] = internalName;
      if (exerciseDbId != null) internalByDbId[exerciseDbId] = internalName;
    }

    return Future.wait(prs.map((pr) async {
      final map = pr as Map<String, dynamic>;
      final exerciseId = map['exercise_id']?.toString();
      final exerciseDbId = map['exercise_db_id']?.toString();
      final internalName = map['exercise_name']?.toString() ??
          map['name']?.toString() ??
          (exerciseId == null ? null : internalById[exerciseId]) ??
          (exerciseDbId == null ? null : internalByDbId[exerciseDbId]);
      final exerciseDbName = exerciseDbId == null
          ? null
          : (await ExerciseDbRapidService.instance.getById(exerciseDbId))?.name;
      return PersonalRecordData(
        exerciseName: resolveExerciseDisplayName(
          internalName: internalName ?? map['free_name']?.toString(),
          exerciseDbName: exerciseDbName,
        ),
        newWeightKg: (map['max_weight_kg'] as num?)?.toDouble() ?? 0,
        newE1rm: (map['e1rm'] as num?)?.toDouble(),
      );
    }));
  }
}
