import 'package:flutter/foundation.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/paused_workout_summary.dart';

class WorkoutSessionProvider extends ChangeNotifier {
  PausedWorkoutSummary? _pausedWorkout;
  bool _isVisible = false;

  PausedWorkoutSummary? get pausedWorkout => _pausedWorkout;
  bool get isVisible => _isVisible && _pausedWorkout != null;

  void setPausedWorkout(PausedWorkoutSummary? workout) {
    _pausedWorkout = workout;
    _isVisible = workout != null;
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
