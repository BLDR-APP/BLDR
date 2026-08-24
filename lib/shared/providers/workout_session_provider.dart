import 'package:flutter/foundation.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/paused_workout_summary.dart';

enum WorkoutLifecycleState { active, paused, finishing, completed }

class WorkoutSessionProvider extends ChangeNotifier {
  PausedWorkoutSummary? _pausedWorkout;
  bool _isVisible = false;
  final Map<String, WorkoutLifecycleState> _states = {};

  PausedWorkoutSummary? get pausedWorkout => _pausedWorkout;
  bool get isVisible => _isVisible && _pausedWorkout != null;

  WorkoutLifecycleState? stateOf(String workoutId) => _states[workoutId];

  bool canRecover(String workoutId) {
    final state = _states[workoutId];
    return state != WorkoutLifecycleState.finishing &&
        state != WorkoutLifecycleState.completed;
  }

  void markActive(String workoutId) {
    if (_states[workoutId] == WorkoutLifecycleState.completed) return;
    _states[workoutId] = WorkoutLifecycleState.active;
    if (_pausedWorkout?.id == workoutId) {
      _pausedWorkout = null;
      _isVisible = false;
    }
    notifyListeners();
  }

  void beginFinishing(String workoutId) {
    if (_states[workoutId] == WorkoutLifecycleState.completed) return;
    _states[workoutId] = WorkoutLifecycleState.finishing;
    if (_pausedWorkout?.id == workoutId) {
      _pausedWorkout = null;
      _isVisible = false;
    }
    notifyListeners();
  }

  void markCompleted(String workoutId) {
    _states[workoutId] = WorkoutLifecycleState.completed;
    if (_pausedWorkout?.id == workoutId) {
      _pausedWorkout = null;
      _isVisible = false;
    }
    notifyListeners();
  }

  void setPausedWorkout(PausedWorkoutSummary? workout) {
    if (workout != null && !canRecover(workout.id)) return;
    _pausedWorkout = workout;
    _isVisible = workout != null;
    if (workout != null) {
      _states[workout.id] = WorkoutLifecycleState.paused;
    }
    notifyListeners();
  }

  void hide() {
    _isVisible = false;
    notifyListeners();
  }

  void show() {
    if (_pausedWorkout != null) {
      _isVisible = true;
      notifyListeners();
    }
  }
}
