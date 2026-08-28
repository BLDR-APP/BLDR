/// Treino gerado pelo HAVOK (bldr_club.havok_workouts).
///
/// `workoutData` é o JSON schemaless devolvido pelo Gemini (`nome`,
/// `exercicios`) — ver HAVOK_SPEC.md §8.1 e BACKLOG_FUNCIONAL.md B5 para o
/// porquê disso ainda não virar um `WorkoutTemplate` de verdade.
class SavedWorkout {
  final String id;
  final String name;
  final DateTime createdAt;
  final Map<String, dynamic> workoutData;

  const SavedWorkout({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.workoutData,
  });

  factory SavedWorkout.fromMap(Map<String, dynamic> map) {
    return SavedWorkout(
      id: map['id'] as String,
      name: map['workout_name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      workoutData: Map<String, dynamic>.from(map['workout_data'] as Map),
    );
  }
}
