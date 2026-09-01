class WorkoutResumePosition {
  final bool hasPendingSet;
  final int exerciseIndex;
  final int setNumber;
  final double weightKg;
  final int reps;

  const WorkoutResumePosition({
    required this.hasPendingSet,
    required this.exerciseIndex,
    required this.setNumber,
    required this.weightKg,
    required this.reps,
  });
}

WorkoutResumePosition findWorkoutResumePosition(
  List<Map<String, dynamic>> exercises,
) {
  for (var exerciseIndex = 0;
      exerciseIndex < exercises.length;
      exerciseIndex++) {
    final sets =
        exercises[exerciseIndex]['sets'] as List<Map<String, dynamic>>? ??
            const [];
    for (final set in sets) {
      if (set['completed_at'] == null && set['is_completed'] != true) {
        return WorkoutResumePosition(
          hasPendingSet: true,
          exerciseIndex: exerciseIndex,
          setNumber: (set['set_number'] as int?) ?? 1,
          weightKg: ((set['weight_kg'] as num?)?.toDouble()) ?? 0,
          reps: (set['reps'] as int?) ?? 10,
        );
      }
    }
  }
  if (exercises.isEmpty) {
    return const WorkoutResumePosition(
      hasPendingSet: false,
      exerciseIndex: 0,
      setNumber: 1,
      weightKg: 0,
      reps: 10,
    );
  }
  return WorkoutResumePosition(
    hasPendingSet: false,
    exerciseIndex: 0,
    setNumber: 1,
    weightKg: 0,
    reps: 10,
  );
}

class WorkoutSetConfirmationGuard {
  final Set<String> _inFlight = <String>{};
  bool tryAcquire(String setId) => setId.isNotEmpty && _inFlight.add(setId);
  void release(String setId) => _inFlight.remove(setId);
}
