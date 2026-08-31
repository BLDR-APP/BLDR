import 'dart:async';
import 'dart:io';

import 'package:postgrest/postgrest.dart';

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/integrations/data/datasources/supabase_wearable_activity_datasource.dart';
import 'package:bldr_fitness/features/integrations/domain/entities/external_workout_activity.dart';
import 'package:bldr_fitness/features/integrations/domain/repositories/wearable_activity_repository.dart';

class WearableActivityRepositoryImpl implements WearableActivityRepository {
  final SupabaseWearableActivityDatasource _datasource;

  const WearableActivityRepositoryImpl(this._datasource);

  Future<Result<T>> _guard<T>(Future<T> Function() operation) async {
    try {
      return Result.success(await operation());
    } on PostgrestException catch (error) {
      return Result.failure(ServerFailure(error.message, cause: error));
    } on SocketException catch (error) {
      return Result.failure(
          NetworkFailure('Sem conexão com a internet.', error));
    } on TimeoutException catch (error) {
      return Result.failure(
          NetworkFailure('Tempo de conexão esgotado.', error));
    } catch (error) {
      return Result.failure(UnexpectedFailure(
        'Não foi possível processar a atividade do wearable.',
        error,
      ));
    }
  }

  @override
  Future<Result<ExternalWorkoutActivity>> getActivity(String activityId) =>
      _guard(() async => ExternalWorkoutActivity.fromMap(
            await _datasource.activity(activityId),
          ));

  @override
  Future<Result<PreparedWearableWorkout>> prepareWorkout({
    required String activityId,
    String? templateId,
    required String source,
  }) =>
      _guard(() async {
        final row = await _datasource.prepareWorkout(
          activityId: activityId,
          templateId: templateId,
          source: source,
        );
        return PreparedWearableWorkout(
          workoutId: row['workout_id'] as String,
          source: row['workout_source'] as String? ?? 'free',
        );
      });

  @override
  Future<Result<void>> markConfirmed(String activityId) =>
      _guard(() => _datasource.markConfirmed(activityId));

  @override
  Future<Result<void>> dismiss(String activityId) =>
      _guard(() => _datasource.dismiss(activityId));
}
