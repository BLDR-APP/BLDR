import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/services/club_workouts_service.dart';
import 'package:bldr_fitness/services/community_service.dart';
import 'package:bldr_fitness/features/workouts/data/models/workout_models.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/paused_workout_summary.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';
import 'package:bldr_fitness/features/club/domain/entities/club_community.dart';
import 'package:bldr_fitness/features/club/domain/repositories/club_community_repository.dart';
import 'package:bldr_fitness/features/club/domain/repositories/club_workout_repository.dart';
import 'package:bldr_fitness/features/club/data/datasources/supabase_club_datasource.dart';

/// Strangler (Fase 6a): delega aos services legados do Club, tipando a borda
/// com as mesmas entidades da feature Workouts.
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

class ClubWorkoutRepositoryImpl implements ClubWorkoutRepository {
  final ClubWorkoutsService _service;
  final SupabaseClubDatasource _datasource;
  final String? Function() _currentUserId;

  ClubWorkoutRepositoryImpl(this._service, this._datasource, this._currentUserId);

  /// Os maps do Club usam chaves `club_*`; realinha para o parse comum.
  WorkoutSession _clubSessionFromMap(Map<String, dynamic> map) =>
      WorkoutModels.sessionFromMap({
        ...map,
        'workout_exercise_sets': map['club_workout_exercise_sets'],
        'workout_templates': map['club_workout_templates'],
      });

  String _requireUser() {
    final uid = _currentUserId();
    if (uid == null) throw const AuthFailure('Usuário não autenticado.');
    return uid;
  }

  @override
  Future<Result<List<WorkoutTemplate>>> myTemplates() => _guard(() async {
        final rows = await _service.getMyClubWorkoutTemplates();
        return rows.map(WorkoutModels.templateFromMap).toList();
      });

  @override
  Future<Result<void>> createTemplate(WorkoutTemplate template) =>
      _guard(() => _service.createClubWorkoutTemplate(
            name: template.name,
            workoutType: template.workoutType ?? 'força',
            estimatedDurationMinutes: template.estimatedDurationMinutes ?? 45,
            difficultyLevel: template.difficultyLevel ?? 1,
            exercises: template.exercises
                .map(WorkoutModels.templateExerciseToServiceMap)
                .toList(),
          ));

  @override
  Future<Result<void>> updateTemplate(WorkoutTemplate template) =>
      _guard(() {
        final id = template.id;
        if (id == null) {
          throw const ValidationFailure('Template sem id não pode ser atualizado.');
        }
        return _service.updateClubWorkoutTemplate(
          templateId: id,
          name: template.name,
          workoutType: template.workoutType ?? 'força',
          estimatedDurationMinutes: template.estimatedDurationMinutes ?? 45,
          difficultyLevel: template.difficultyLevel ?? 1,
          exercises: template.exercises
              .map(WorkoutModels.templateExerciseToServiceMap)
              .toList(),
        );
      });

  @override
  Future<Result<WorkoutSession>> start({
    required String name,
    required String templateId,
  }) =>
      _guard(() async {
        final map = await _service.startClubWorkout(
            name: name, clubWorkoutTemplateId: templateId);
        return _clubSessionFromMap(map);
      });

  @override
  Future<Result<WorkoutSession>> complete({
    required String workoutId,
    String? notes,
  }) =>
      _guard(() async {
        final map = await _service.completeClubWorkout(
            workoutId: workoutId, notes: notes);
        return _clubSessionFromMap(map);
      });

  @override
  Future<Result<void>> completeSet({
    required String setId,
    int? reps,
    double? weightKg,
  }) =>
      _guard(() =>
          _service.completeClubSet(setId: setId, reps: reps, weight: weightKg));

  @override
  Future<Result<void>> undoSet(String setId) =>
      _guard(() => _service.undoClubSet(setId: setId));

  @override
  Stream<WorkoutSession?> activeWorkoutStream() => _service
      .activeClubWorkoutStream()
      .map((map) => map == null ? null : _clubSessionFromMap(map));

  @override
  Future<Result<List<WorkoutSession>>> userWorkouts({
    bool completedOnly = false,
    int limit = 20,
  }) =>
      _guard(() async {
        final rows = await _service.getClubUserWorkouts(
            completedOnly: completedOnly, limit: limit);
        return rows.map(WorkoutModels.sessionFromMap).toList();
      });

  @override
  Future<Result<void>> logCardio({
    required String label,
    required String activityType,
    required int durationSeconds,
  }) =>
      _guard(() => _service.logCardioActivity(
            label: label,
            activityType: activityType,
            durationSeconds: durationSeconds,
          ));

  @override
  Future<Result<bool>> isUserInActiveChallenge() =>
      _guard(_service.isUserInActiveChallenge);

  @override
  Future<Result<List<WorkoutTemplate>>> publicTemplates({int limit = 50}) =>
      _guard(() async {
        final rows = await _datasource.publicTemplates(limit: limit);
        return rows.map(WorkoutModels.templateFromMap).toList();
      });

  @override
  Future<Result<List<TemplateExercise>>> templateExercises(
          String templateId) =>
      _guard(() async {
        final rows = await _datasource.templateExercises(templateId);
        return rows.map(WorkoutModels.templateExerciseFromMap).toList();
      });

  @override
  Future<Result<List<WorkoutSession>>> workoutsBetween(
          DateTime start, DateTime end) =>
      _guard(() async {
        final rows =
            await _datasource.clubWorkoutsBetween(_requireUser(), start, end);
        return rows.map(WorkoutModels.sessionFromMap).toList();
      });

  @override
  Future<Result<List<ClubActivity>>> activitiesBetween(
          DateTime start, DateTime end) =>
      _guard(() async {
        final rows =
            await _datasource.activitiesBetween(_requireUser(), start, end);
        return rows
            .map((m) => ClubActivity(
                  id: m['id']?.toString(),
                  activityType: m['activity_type'] as String? ?? '',
                  createdAt:
                      DateTime.tryParse(m['created_at']?.toString() ?? ''),
                ))
            .toList();
      });

  @override
  Future<Result<int>> xpBetween(DateTime start, DateTime end) =>
      _guard(() => _datasource.xpBetween(_requireUser(), start, end));

  @override
  Future<Result<WorkoutSession?>> workoutDetails(String workoutId) =>
      _guard(() async {
        final map = await _service.getClubWorkoutDetails(workoutId);
        return map == null ? null : _clubSessionFromMap(map);
      });

  @override
  Future<Result<WorkoutTemplate?>> templateWithExercises(String templateId) =>
      _guard(() async {
        final map =
            await _service.getClubWorkoutTemplateWithExercises(templateId);
        return map == null ? null : WorkoutModels.templateFromMap(map);
      });

  @override
  Future<Result<void>> deleteTemplate(String templateId) =>
      _guard(() => _service.deleteClubWorkoutTemplate(templateId));

  @override
  Future<Result<List<PausedWorkoutSummary>>> pausedSummaries({int limit = 2}) =>
      _guard(() async {
        final rows =
            await _service.getPausedClubWorkoutSummaries(limit: limit);
        return rows.map(WorkoutModels.pausedSummaryFromMap).toList();
      });

  @override
  Future<Result<void>> deletePaused(String workoutId) =>
      _guard(() => _service.deletePausedClubWorkout(workoutId));

  @override
  Future<Result<void>> deleteWorkoutRecord(String workoutId) =>
      _guard(() => _service.deleteClubWorkoutRecord(workoutId));

  @override
  Future<Result<void>> deleteActivityRecord(String activityId) =>
      _guard(() => _service.deleteActivityRecord(activityId));

  @override
  Future<Result<void>> ensureClubInitialSets(String sessionId, String templateId) =>
      _guard(() => _service.ensureClubInitialSets(sessionId, templateId));

  @override
  Future<Result<List<RunActivity>>> runActivities({int? limit}) =>
      _guard(() async {
        final rows =
            await _datasource.userActivities(_requireUser(), limit: limit);
        return rows
            .map((m) => RunActivity(
                  id: m['id']?.toString(),
                  title: m['title'] as String?,
                  distanceMeters: m['distance_meters'] as num?,
                  durationSeconds:
                      (m['duration_seconds'] as num?)?.toInt(),
                  paceText: m['pace_text'] as String?,
                  earnedXp: (m['earned_xp'] as num?)?.toInt(),
                  createdAt:
                      DateTime.tryParse(m['created_at']?.toString() ?? ''),
                  routeData: (m['route_data'] as List?)
                          ?.map((p) =>
                              Map<String, dynamic>.from(p as Map))
                          .toList() ??
                      const [],
                ))
            .toList();
      });

  @override
  Future<Result<void>> saveRun({
    required double distanceMeters,
    required int durationSeconds,
    required String paceText,
    required List<Map<String, dynamic>> routeData,
    required int earnedXp,
  }) =>
      _guard(() async {
        final uid = _requireUser();
        final now = DateTime.now();
        // F19: calcular pace_sec = duration / (distance_km) para evitar parse futuro
        final paceSec = distanceMeters > 0
            ? (durationSeconds / (distanceMeters / 1000)).round()
            : null;
        await _datasource.insertRunActivity({
          'user_id': uid,
          'distance_meters': distanceMeters,
          'duration_seconds': durationSeconds,
          'pace_text': paceText,
          if (paceSec != null) 'pace_sec': paceSec,
          'route_data': routeData,
          'title': 'Corrida ${now.day}/${now.month}',
          'created_at': now.toIso8601String(),
          'earned_xp': earnedXp,
        });
        await _datasource.insertXpEvent(uid, earnedXp, 'Corrida Concluída');
        await _datasource.addXp(uid, earnedXp, source: 'run_tracker');
      });

  @override
  Future<Result<void>> saveMatchSession({
    required String modality,
    required String result,
    required List<Map<String, dynamic>> sets,
    required int intensity,
    required int durationSec,
  }) =>
      _guard(() async {
        final uid = _requireUser();
        // Map pt-BR result label to DB check constraint values
        final dbResult = result == 'Vitória'
            ? 'win'
            : result == 'Derrota'
                ? 'loss'
                : 'draw';
        await _datasource.insertMatchSession({
          'user_id': uid,
          'modality': modality,
          'result': dbResult,
          'sets': sets,
          'intensity': intensity,
          'duration_sec': durationSec,
          'played_at': DateTime.now().toIso8601String(),
        });
      });

  @override
  Future<Result<List<MatchSession>>> matchSessions({int limit = 50}) =>
      _guard(() async {
        final rows = await _datasource.matchSessions(_requireUser(), limit: limit);
        return rows
            .map((m) => MatchSession(
                  id: m['id']?.toString(),
                  modality: m['modality'] as String? ?? '',
                  result: m['result'] as String? ?? 'draw',
                  sets: (m['sets'] as List? ?? [])
                      .map((s) => Map<String, dynamic>.from(s as Map))
                      .toList(),
                  intensity: (m['intensity'] as num?)?.toInt(),
                  durationSec: (m['duration_sec'] as num?)?.toInt(),
                  playedAt: DateTime.tryParse(m['played_at']?.toString() ?? ''),
                ))
            .toList();
      });

  @override
  Future<Result<WeeklyOperation?>> getCurrentOperation() => _guard(() async {
        final row = await _datasource.currentOperation();
        if (row == null) return null;
        return WeeklyOperation(
          id: row['id'] as String,
          title: row['title'] as String,
          description: row['description'] as String?,
          goalType: row['goal_type'] as String,
          goalValue: (row['goal_value'] as num).toInt(),
          xpReward: (row['xp_reward'] as num).toInt(),
          weekStart: DateTime.parse(row['week_start'] as String),
          weekEnd: DateTime.parse(row['week_end'] as String),
        );
      });

  @override
  Future<Result<OperationProgress?>> getOperationProgress(
          String operationId) =>
      _guard(() async {
        final uid = _requireUser();
        final row = await _datasource.operationProgress(uid, operationId);
        if (row == null) return null;
        return OperationProgress(
          id: row['id'] as String,
          userId: row['user_id'] as String,
          operationId: row['operation_id'] as String,
          currentValue: (row['current_value'] as num).toInt(),
          completed: row['completed'] as bool? ?? false,
          completedAt: row['completed_at'] != null
              ? DateTime.tryParse(row['completed_at'] as String)
              : null,
        );
      });

  @override
  Future<Result<void>> tryIncrementOperation(String goalType, int delta) =>
      _guard(() async {
        final opRow = await _datasource.currentOperation();
        if (opRow == null) return;
        if ((opRow['goal_type'] as String) != goalType) return;
        final operationId = opRow['id'] as String;
        final goalValue = (opRow['goal_value'] as num).toInt();
        final uid = _requireUser();
        final progRow =
            await _datasource.operationProgress(uid, operationId);
        final current =
            progRow != null ? (progRow['current_value'] as num).toInt() : 0;
        final alreadyDone =
            progRow != null && (progRow['completed'] as bool? ?? false);
        if (alreadyDone) return;
        final updated = current + delta;
        final completed = updated >= goalValue;
        await _datasource.upsertOperationProgress(
          userId: uid,
          operationId: operationId,
          newValue: updated,
          completed: completed,
        );
      });
}

class ClubCommunityRepositoryImpl implements ClubCommunityRepository {
  final CommunityService _service;

  ClubCommunityRepositoryImpl(this._service);

  @override
  Future<Result<List<ClubAnnouncement>>> announcements({int limit = 20}) =>
      _guard(() async {
        final rows = await _service.fetchAnnouncements(limit: limit);
        return rows
            .map((m) => ClubAnnouncement(
                  id: m['id']?.toString(),
                  title: m['title'] as String? ?? '',
                  imageUrl: m['image_url'] as String?,
                  imageUrlMain: m['image_url_main'] as String?,
                  linkUrl: m['link_url'] as String?,
                  createdAt:
                      DateTime.tryParse(m['created_at']?.toString() ?? ''),
                ))
            .toList();
      });

  @override
  Future<Result<List<ClubEvent>>> events({int limit = 20}) =>
      _guard(() async {
        final rows = await _service.fetchEvents(limit: limit);
        return rows
            .map((m) => ClubEvent(
                  id: m['id']?.toString(),
                  title: m['title'] as String? ?? '',
                  imageUrl: m['image_url'] as String?,
                  linkUrl: m['link_url'] as String?,
                  createdAt:
                      DateTime.tryParse(m['created_at']?.toString() ?? ''),
                ))
            .toList();
      });
}
