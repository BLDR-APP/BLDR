import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/integrations/domain/entities/external_workout_activity.dart';
import 'package:bldr_fitness/features/integrations/domain/repositories/wearable_activity_repository.dart';

class GetWearableActivity {
  final WearableActivityRepository _repository;
  const GetWearableActivity(this._repository);

  Future<Result<ExternalWorkoutActivity>> call(String activityId) =>
      _repository.getActivity(activityId);
}

class PrepareWearableWorkout {
  final WearableActivityRepository _repository;
  const PrepareWearableWorkout(this._repository);

  Future<Result<PreparedWearableWorkout>> call({
    required String activityId,
    String? templateId,
    required String source,
  }) =>
      _repository.prepareWorkout(
        activityId: activityId,
        templateId: templateId,
        source: source,
      );
}

class ConfirmWearableActivity {
  final WearableActivityRepository _repository;
  const ConfirmWearableActivity(this._repository);

  Future<Result<void>> call(String activityId) =>
      _repository.markConfirmed(activityId);
}

class DismissWearableActivity {
  final WearableActivityRepository _repository;
  const DismissWearableActivity(this._repository);

  Future<Result<void>> call(String activityId) =>
      _repository.dismiss(activityId);
}
