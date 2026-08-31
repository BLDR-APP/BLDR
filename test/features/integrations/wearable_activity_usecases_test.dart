import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/integrations/domain/entities/external_workout_activity.dart';
import 'package:bldr_fitness/features/integrations/domain/repositories/wearable_activity_repository.dart';
import 'package:bldr_fitness/features/integrations/domain/usecases/wearable_activity_usecases.dart';

class _FakeWearableActivityRepository implements WearableActivityRepository {
  String? preparedActivityId;
  String? preparedTemplateId;
  String? preparedSource;
  String? confirmedId;
  String? dismissedId;
  bool fail = false;

  final activity = ExternalWorkoutActivity(
    id: 'activity-1',
    provider: 'whoop',
    externalActivityId: 'whoop-1',
    activityType: 'Weightlifting',
    startedAt: DateTime.utc(2026, 8, 29, 12),
    endedAt: DateTime.utc(2026, 8, 29, 13),
    durationSeconds: 3600,
    strain: 12.4,
    status: 'pending',
  );

  @override
  Future<Result<ExternalWorkoutActivity>> getActivity(
          String activityId) async =>
      fail
          ? const Result.failure(ServerFailure('Falha de leitura.'))
          : Result.success(activity);

  @override
  Future<Result<PreparedWearableWorkout>> prepareWorkout({
    required String activityId,
    String? templateId,
    required String source,
  }) async {
    preparedActivityId = activityId;
    preparedTemplateId = templateId;
    preparedSource = source;
    return const Result.success(
      PreparedWearableWorkout(workoutId: 'workout-1', source: 'free'),
    );
  }

  @override
  Future<Result<void>> markConfirmed(String activityId) async {
    confirmedId = activityId;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> dismiss(String activityId) async {
    dismissedId = activityId;
    return const Result.success(null);
  }
}

void main() {
  late _FakeWearableActivityRepository repository;

  setUp(() => repository = _FakeWearableActivityRepository());

  test('GetWearableActivity retorna atividade normalizada', () async {
    final result = await GetWearableActivity(repository)('activity-1');
    expect(result.valueOrNull?.externalActivityId, 'whoop-1');
    expect(result.valueOrNull?.durationSeconds, 3600);
  });

  test('GetWearableActivity preserva Failure', () async {
    repository.fail = true;
    final result = await GetWearableActivity(repository)('activity-1');
    expect(result.failureOrNull?.message, 'Falha de leitura.');
  });

  test('PrepareWearableWorkout repassa template e origem', () async {
    final result = await PrepareWearableWorkout(repository)(
      activityId: 'activity-1',
      templateId: 'template-1',
      source: 'club',
    );
    expect(result.valueOrNull?.workoutId, 'workout-1');
    expect(repository.preparedActivityId, 'activity-1');
    expect(repository.preparedTemplateId, 'template-1');
    expect(repository.preparedSource, 'club');
  });

  test('Confirm e dismiss usam a atividade correta', () async {
    await ConfirmWearableActivity(repository)('activity-1');
    await DismissWearableActivity(repository)('activity-2');
    expect(repository.confirmedId, 'activity-1');
    expect(repository.dismissedId, 'activity-2');
  });
}
