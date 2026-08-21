/// Exercício — pode vir da biblioteca interna (Supabase `exercises`)
/// ou do ExerciseDB (RapidAPI); `exerciseDbId` identifica a origem externa.
class Exercise {
  final String? id;
  final String? exerciseDbId;
  final String name;
  final String? description;
  final dynamic exerciseType; // String na base interna; List no ExerciseDB
  final dynamic primaryMuscleGroup;
  final List<String> secondaryMuscleGroups;
  final List<String> instructions;
  final List<String> tips;
  final String? imageUrl;
  final List<String> equipmentNeeded;

  const Exercise({
    this.id,
    this.exerciseDbId,
    required this.name,
    this.description,
    this.exerciseType,
    this.primaryMuscleGroup,
    this.secondaryMuscleGroups = const [],
    this.instructions = const [],
    this.tips = const [],
    this.imageUrl,
    this.equipmentNeeded = const [],
  });

  bool get isFromExerciseDb => exerciseDbId != null && id == null;
}
