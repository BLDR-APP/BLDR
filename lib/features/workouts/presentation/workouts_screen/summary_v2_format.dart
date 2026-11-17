import 'package:bldr_fitness/features/workouts/domain/entities/workout_share_data.dart';

/// Nível de estímulo de um músculo no resumo (faixas aprovadas no
/// TREINOS_V2.md: ≥ 0,66 Alto, ≥ 0,33 Moderado; abaixo disso não aparece).
enum SummaryMuscleLevel { high, moderate }

/// Formatação de apresentação do resumo v2 (Figma 211:5). Funções puras.
abstract final class SummaryV2Format {
  /// 2852 → "47:32"; 3725 → "1:02:05".
  static String clock(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  static SummaryMuscleLevel? level(double score) {
    if (score >= 0.66) return SummaryMuscleLevel.high;
    if (score >= 0.33) return SummaryMuscleLevel.moderate;
    return null;
  }

  /// Até 3 músculos principais com nota, na mesma ordem e com os mesmos
  /// rótulos de [WorkoutShareData.primaryMuscleLabels].
  static List<({String label, double score})> topMuscles(
      WorkoutShareData data) {
    final labels = data.primaryMuscleLabels;
    final scores = (data.muscleMapData?.muscles.values.toList() ?? <double>[])
      ..sort((a, b) => b.compareTo(a));
    return [
      for (var i = 0; i < labels.length && i < scores.length; i++)
        (label: labels[i], score: scores[i]),
    ];
  }

  /// "42,5" / "40".
  static String kg(double v) => v == v.roundToDouble()
      ? v.round().toString()
      : v.toStringAsFixed(1).replaceAll('.', ',');
}
