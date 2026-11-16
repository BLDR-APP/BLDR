/// Origem da sessão de treino persistida.
enum WorkoutSessionSource {
  personal,
  bldrClub,
}

/// Origem da definição/template que deu origem ao treino, quando disponível.
enum WorkoutDefinitionSource {
  personal,
  bldrClub,
}

/// Constrói a identidade global de uma sessão, sem perder o seu ID de origem.
///
/// Os IDs das famílias personal e BLDR Club pertencem a espaços distintos e
/// podem coincidir. Por isso, consumidores do modelo canônico devem usar este
/// ID, e não [CanonicalWorkoutSession.sourceSessionId], como identidade global.
String canonicalWorkoutSessionId(
  WorkoutSessionSource source,
  String sourceSessionId,
) =>
    '${source.name}:$sourceSessionId';

/// Sessão de treino normalizada para leitura entre as famílias personal e CLUB.
///
/// Datas representam instantes absolutos. Conversão de fuso e agregações de
/// analytics pertencem aos consumidores posteriores desta camada.
class CanonicalWorkoutSession {
  final String id;
  final String sourceSessionId;
  final String userId;
  final WorkoutSessionSource source;
  final String? definitionId;
  final WorkoutDefinitionSource? definitionSource;
  final String? name;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final bool isCompleted;
  final int? durationSeconds;
  final double? volumeKg;
  final List<String>? muscleGroups;
  final String? notes;
  final List<CanonicalWorkoutExercise> exercises;

  const CanonicalWorkoutSession({
    required this.id,
    required this.sourceSessionId,
    required this.userId,
    required this.source,
    this.definitionId,
    this.definitionSource,
    this.name,
    this.startedAt,
    this.completedAt,
    required this.isCompleted,
    this.durationSeconds,
    this.volumeKg,
    this.muscleGroups,
    this.notes,
    this.exercises = const [],
  });
}

/// Exercício executado dentro de uma [CanonicalWorkoutSession].
///
/// Os campos de identidade são preservados separadamente: o ID interno é a
/// identidade primária, o ExerciseDB é secundário e o ID do template registra
/// proveniência. Nomes nunca devem ser usados como identidade longitudinal.
class CanonicalWorkoutExercise {
  final String id;
  final String? internalExerciseId;
  final String? exerciseDbId;
  final String? templateExerciseId;
  final int? orderIndex;
  final String? displayName;
  final String? freeName;
  final String? primaryMuscleGroup;
  final List<String> secondaryMuscleGroups;
  final List<CanonicalWorkoutSet> sets;

  const CanonicalWorkoutExercise({
    required this.id,
    this.internalExerciseId,
    this.exerciseDbId,
    this.templateExerciseId,
    this.orderIndex,
    this.displayName,
    this.freeName,
    this.primaryMuscleGroup,
    this.secondaryMuscleGroups = const [],
    this.sets = const [],
  });
}

/// Série executada dentro de um [CanonicalWorkoutExercise].
class CanonicalWorkoutSet {
  final String id;
  final String sessionId;
  final String exerciseId;
  final int setNumber;
  final int? orderIndex;
  final int? reps;
  final double? weightKg;
  final int? durationSeconds;
  final double? distanceMeters;
  final int? restSeconds;
  final DateTime? completedAt;
  final bool isCompleted;
  final bool isSkipped;
  final String? notes;

  const CanonicalWorkoutSet({
    required this.id,
    required this.sessionId,
    required this.exerciseId,
    required this.setNumber,
    this.orderIndex,
    this.reps,
    this.weightKg,
    this.durationSeconds,
    this.distanceMeters,
    this.restSeconds,
    this.completedAt,
    required this.isCompleted,
    required this.isSkipped,
    this.notes,
  }) : assert(
          !isSkipped || (completedAt == null && !isCompleted),
          'A skipped set cannot be completed.',
        );
}
