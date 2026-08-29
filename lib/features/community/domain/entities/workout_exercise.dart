class WorkoutExercise {
  final String name;
  final List<WorkoutSet> sets;

  WorkoutExercise({required this.name, List<WorkoutSet>? sets})
      : sets = sets ?? [];
}

class WorkoutSet {
  final double? weightKg;
  final int? reps;

  const WorkoutSet({this.weightKg, this.reps});
}
