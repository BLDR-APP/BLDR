import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/onboarding/domain/entities/onboarding_plan.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/weekly_plan.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';
import 'package:bldr_fitness/features/workouts/domain/repositories/weekly_plan_repository.dart';
import 'package:bldr_fitness/services/exercise_db_rapid_service.dart';
import 'package:bldr_fitness/features/workouts/data/datasources/supabase_weekly_plan_datasource.dart';
import 'package:bldr_fitness/features/workouts/data/models/workout_models.dart';

class WeeklyPlanRepositoryImpl implements WeeklyPlanRepository {
  final SupabaseWeeklyPlanDatasource _datasource;

  /// ExerciseDB legado usado para resolver músculos-alvo (cacheado).
  final ExerciseDbRapidService _exerciseDb;

  final String? Function() _currentUserId;

  WeeklyPlanRepositoryImpl(
      this._datasource, this._exerciseDb, this._currentUserId);

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

  String _requireUser() {
    final uid = _currentUserId();
    if (uid == null) throw const AuthFailure('Usuário não autenticado.');
    return uid;
  }

  @override
  Future<Result<void>> saveWeeklyPlan(List<PlanDay> days) => _guard(() async {
        final uid = _requireUser();
        final rows = days.map((d) => {
              'user_id': uid,
              'dia_semana': d.diaSemana,
              'tipo': d.tipo,
              'template_id': d.treino?.id,
              'template_name': d.treino?.name,
              'source': d.treino?.source ?? 'user',
            }).toList();
        await _datasource.upsertWeeklyPlan(uid, rows);
      });

  @override
  Future<Result<List<PlanDay>>> getWeeklyPlan() => _guard(() async {
        final uid = _requireUser();
        final rows = await _datasource.getWeeklyPlan(uid);
        return rows.map((r) {
          final templateId = r['template_id'] as String?;
          final templateName = r['template_name'] as String?;
          return PlanDay(
            diaSemana: (r['dia_semana'] as int),
            tipo: (r['tipo'] as String?) ?? 'treino',
            treino: (templateId != null || (templateName != null && templateName.isNotEmpty))
                ? WorkoutTemplate(
                    id: templateId,
                    name: templateName ?? '',
                    isPublic: false,
                    source: r['source'] as String?,
                  )
                : null,
          );
        }).toList();
      });

  @override
  Future<Result<WeeklyPlanConfig>> planConfig() => _guard(() async {
        final ob = await _datasource.onboardingData(_requireUser()) ?? {};
        return WeeklyPlanConfig(
          splitPreference: ob['split_preference'] as String? ?? '',
          frequencyDays: ob['workout_frequency_days'] as int? ?? 3,
          restDays: (ob['rest_days'] as List?)
                  ?.map((e) => (e as num).toInt())
                  .toList() ??
              const [],
        );
      });

  @override
  Future<Result<void>> savePlanConfig({
    required String splitPreference,
    required List<int> restDays,
  }) =>
      _guard(() async {
        final uid = _requireUser();
        // Lê o onboarding_data atual para não sobrescrever outros campos.
        final ob =
            Map<String, dynamic>.from(await _datasource.onboardingData(uid) ?? {});
        ob['split_preference'] = splitPreference;
        ob['rest_days'] = restDays;
        await _datasource.updateOnboardingData(uid, ob);
      });

  @override
  Future<Result<WeekCompletedWorkouts>> completedBetween(
          DateTime weekStart, DateTime weekEnd) =>
      _guard(() async {
        final uid = _requireUser();
        final personalRows =
            await _datasource.personalWorkoutsBetween(uid, weekStart, weekEnd);

        List<Map<String, dynamic>> clubRows = const [];
        try {
          clubRows =
              await _datasource.clubCompletedBetween(uid, weekStart, weekEnd);
        } catch (_) {
          // Tabelas do Club podem não existir para todos — mesmo fallback
          // silencioso do código original.
        }

        return WeekCompletedWorkouts(
          personal: personalRows.map(WorkoutModels.sessionFromMap).toList(),
          club: clubRows.map(WorkoutModels.sessionFromMap).toList(),
        );
      });

  @override
  Future<Result<List<String>>> musclesForWorkout(String workoutId) =>
      _guard(() async {
        final muscles = <String>{};

        final dbIds = await _datasource.exerciseDbIdsForWorkout(workoutId);
        if (dbIds.isNotEmpty) {
          final allExercises = await _exerciseDb.listAllExercises();
          final idSet = dbIds.toSet();
          for (final ex in allExercises) {
            if (idSet.contains(ex.exerciseId)) {
              muscles.addAll(ex.targetMuscles);
            }
          }
        }

        muscles.addAll(
            await _datasource.internalMusclesForWorkout(workoutId));
        return muscles.toList();
      });

  @override
  Future<Result<void>> deleteCompletedClub(String clubWorkoutId) =>
      _guard(() => _datasource.deleteClubWorkout(clubWorkoutId));
}
