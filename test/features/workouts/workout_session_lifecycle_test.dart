import 'package:bldr_fitness/features/workouts/domain/entities/paused_workout_summary.dart';
import 'package:bldr_fitness/shared/providers/workout_session_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const workoutId = 'workout-1';
  const paused = PausedWorkoutSummary(
    id: workoutId,
    name: 'Treino de teste',
  );

  test('active → finish → completed', () {
    final provider = WorkoutSessionProvider();
    provider.markActive(workoutId);
    provider.beginFinishing(workoutId);
    provider.markCompleted(workoutId);

    expect(provider.stateOf(workoutId), WorkoutLifecycleState.completed);
    expect(provider.canRecover(workoutId), isFalse);
  });

  test('paused → resume → finish → completed', () {
    final provider = WorkoutSessionProvider();
    provider.setPausedWorkout(paused);
    expect(provider.stateOf(workoutId), WorkoutLifecycleState.paused);

    provider.markActive(workoutId);
    provider.beginFinishing(workoutId);
    provider.markCompleted(workoutId);

    expect(provider.stateOf(workoutId), WorkoutLifecycleState.completed);
    expect(provider.pausedWorkout, isNull);
  });

  test('finish → summary → background → foreground permanece completed', () {
    final provider = WorkoutSessionProvider()
      ..markActive(workoutId)
      ..beginFinishing(workoutId)
      ..markCompleted(workoutId);

    // Simula um callback tardio de lifecycle tentando pausar a rota anterior.
    provider.setPausedWorkout(paused);

    expect(provider.stateOf(workoutId), WorkoutLifecycleState.completed);
    expect(provider.pausedWorkout, isNull);
  });

  test('finish → share → retorno ao app permanece completed', () {
    final provider = WorkoutSessionProvider()
      ..markActive(workoutId)
      ..beginFinishing(workoutId)
      ..markCompleted(workoutId);

    provider.hide();
    provider.show();
    provider.setPausedWorkout(paused);

    expect(provider.stateOf(workoutId), WorkoutLifecycleState.completed);
    expect(provider.isVisible, isFalse);
  });

  test('completed workout não é recuperado como active workout', () {
    final provider = WorkoutSessionProvider()..markCompleted(workoutId);

    expect(provider.canRecover(workoutId), isFalse);
    provider.setPausedWorkout(paused);
    provider.markActive(workoutId);

    expect(provider.stateOf(workoutId), WorkoutLifecycleState.completed);
    expect(provider.pausedWorkout, isNull);
  });
}
