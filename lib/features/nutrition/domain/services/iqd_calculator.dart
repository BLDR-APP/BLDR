/// Índice de Qualidade da Dieta (IQD), 0–100. Fórmula inalterada (antes só
/// em `lib/services/iqd_calculator_service.dart`, que agora delega para cá):
/// base 60; fibra +40 proporcional até 25 g; sódio −20 proporcional entre
/// 2000 e 3000 mg; açúcar adicionado −20 proporcional entre 50 e 100 g.
abstract final class IqdCalculator {
  static double calculate({
    required double fiberGrams,
    required double sodiumMg,
    required double addedSugarGrams,
  }) {
    var score = 60.0;
    const fiberTarget = 25.0;
    score += (fiberGrams.clamp(0.0, fiberTarget) / fiberTarget) * 40.0;
    const sodiumThreshold = 2000.0, sodiumMax = 3000.0;
    if (sodiumMg > sodiumThreshold) {
      final excess =
          (sodiumMg - sodiumThreshold).clamp(0.0, sodiumMax - sodiumThreshold);
      score -= (excess / (sodiumMax - sodiumThreshold)) * 20.0;
    }
    const sugarThreshold = 50.0, sugarMax = 100.0;
    if (addedSugarGrams > sugarThreshold) {
      final excess = (addedSugarGrams - sugarThreshold)
          .clamp(0.0, sugarMax - sugarThreshold);
      score -= (excess / (sugarMax - sugarThreshold)) * 20.0;
    }
    return score.clamp(0.0, 100.0);
  }

  static IqdBand bandOf(double score) {
    if (score >= 75) return IqdBand.veryGood;
    if (score >= 50) return IqdBand.regular;
    return IqdBand.poor;
  }
}

/// Faixas do IQD (mesmos cortes de antes; a de ≥75 agora se chama
/// "Muito bom").
enum IqdBand { veryGood, regular, poor }
