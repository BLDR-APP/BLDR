class IqdCalculatorService {
  /// Calcula o Índice de Qualidade da Dieta (IQD) de 0 a 100.
  ///
  /// Regras ANVISA:
  /// - Base: 60 pontos
  /// - Bônus Fibras: até +40 pts (máximo em 25g)
  /// - Penalidade Sódio: até -20 pts (inicia acima de 2000mg, máximo em 3000mg)
  /// - Penalidade Açúcar Adicionado: até -20 pts (inicia acima de 50g, máximo em 100g)
  static double calculate({
    required double fiberGrams,
    required double sodiumMg,
    required double addedSugarGrams,
  }) {
    double score = 60.0;

    // --- Bônus de Fibras (+0 a +40) ---
    // 0g = 0 pts bonus | 25g+ = 40 pts bonus
    const double fiberTarget = 25.0;
    final double fiberBonus = (fiberGrams.clamp(0.0, fiberTarget) / fiberTarget) * 40.0;
    score += fiberBonus;

    // --- Penalidade de Sódio (0 a -20) ---
    // Até 2000mg: sem penalidade | 3000mg+: -20 pts
    const double sodiumThreshold = 2000.0;
    const double sodiumMax = 3000.0;
    if (sodiumMg > sodiumThreshold) {
      final double sodiumExcess = (sodiumMg - sodiumThreshold).clamp(0.0, sodiumMax - sodiumThreshold);
      final double sodiumPenalty = (sodiumExcess / (sodiumMax - sodiumThreshold)) * 20.0;
      score -= sodiumPenalty;
    }

    // --- Penalidade de Açúcares Adicionados (0 a -20) ---
    // Até 50g: sem penalidade | 100g+: -20 pts
    const double sugarThreshold = 50.0;
    const double sugarMax = 100.0;
    if (addedSugarGrams > sugarThreshold) {
      final double sugarExcess = (addedSugarGrams - sugarThreshold).clamp(0.0, sugarMax - sugarThreshold);
      final double sugarPenalty = (sugarExcess / (sugarMax - sugarThreshold)) * 20.0;
      score -= sugarPenalty;
    }

    return score.clamp(0.0, 100.0);
  }

  /// Retorna uma cor representando a qualidade da nota.
  /// Verde (bom) > Amarelo (médio) > Vermelho (ruim)
  static Map<String, dynamic> getScoreLabel(double score) {
    if (score >= 75) {
      return {'label': 'Ótimo', 'color': 'green'};
    } else if (score >= 50) {
      return {'label': 'Regular', 'color': 'yellow'};
    } else {
      return {'label': 'Ruim', 'color': 'red'};
    }
  }
}
