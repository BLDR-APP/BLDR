import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';

/// Estimativa automática da duração de um treino (TREINOS_V2.md, P1).
///
/// - Execução por série = reps × 3 s, mínimo 20 s; sem reps, usa a duração
///   da série (exercício por tempo); sem nenhum dos dois, 40 s.
/// - Descanso = descanso de cada série, exceto após a última série do treino.
/// - Transição entre exercícios = 60 s × (nº de exercícios − 1).
/// - Resultado em minutos, arredondado para cima. Treino vazio → 0.
abstract final class WorkoutDurationEstimator {
  static const int secondsPerRep = 3;
  static const int minSetSeconds = 20;
  static const int defaultSetSeconds = 40;
  static const int transitionSeconds = 60;

  static int setWorkSeconds({int? reps, int? durationSeconds}) {
    if (reps != null && reps > 0) {
      final s = reps * secondsPerRep;
      return s < minSetSeconds ? minSetSeconds : s;
    }
    if (durationSeconds != null && durationSeconds > 0) return durationSeconds;
    return defaultSetSeconds;
  }

  /// [exercises]: para cada exercício, a lista de séries e a duração por
  /// série (exercícios por tempo).
  static int estimateMinutes(
    List<({List<TemplateSetDetail> sets, int? durationSeconds})> exercises,
  ) {
    final nonEmpty = exercises.where((e) => e.sets.isNotEmpty).toList();
    if (nonEmpty.isEmpty) return 0;

    var total = transitionSeconds * (nonEmpty.length - 1);
    for (var i = 0; i < nonEmpty.length; i++) {
      final ex = nonEmpty[i];
      for (var j = 0; j < ex.sets.length; j++) {
        final set = ex.sets[j];
        total +=
            setWorkSeconds(reps: set.reps, durationSeconds: ex.durationSeconds);
        final isLastOfWorkout =
            i == nonEmpty.length - 1 && j == ex.sets.length - 1;
        if (!isLastOfWorkout) total += set.restSeconds ?? 0;
      }
    }
    return (total / 60).ceil();
  }

  /// Atalho para um template já montado.
  static int estimateTemplate(List<TemplateExercise> exercises) =>
      estimateMinutes([
        for (final e in exercises)
          (sets: e.resolvedSets, durationSeconds: e.durationSeconds),
      ]);
}
