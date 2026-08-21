/// Resumo de um treino pausado (não concluído) para o card "continuar treino".
/// Enriquecido com progresso e o exercício onde o usuário parou.
class PausedWorkoutSummary {
  final String id;
  final String name;

  /// 'free' (treinos normais) ou 'club' (BLDR Club).
  final String source;
  final DateTime? startedAt;
  final int totalExercises;
  final int completedExercises;
  final String currentExerciseName;

  const PausedWorkoutSummary({
    required this.id,
    required this.name,
    this.source = 'free',
    this.startedAt,
    this.totalExercises = 0,
    this.completedExercises = 0,
    this.currentExerciseName = '',
  });
}
