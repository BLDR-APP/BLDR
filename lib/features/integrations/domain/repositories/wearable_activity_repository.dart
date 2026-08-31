import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/integrations/domain/entities/external_workout_activity.dart';

abstract class WearableActivityRepository {
  Future<Result<ExternalWorkoutActivity>> getActivity(String activityId);

  Future<Result<PreparedWearableWorkout>> prepareWorkout({
    required String activityId,
    String? templateId,
    required String source,
  });

  Future<Result<void>> markConfirmed(String activityId);

  Future<Result<void>> dismiss(String activityId);
}
