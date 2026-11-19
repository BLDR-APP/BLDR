import 'package:bldr_fitness/features/nutrition/domain/services/iqd_calculator.dart';

/// Legado: delega para [IqdCalculator] (domain), mantendo a API antiga.
class IqdCalculatorService {
  /// Calcula o Índice de Qualidade da Dieta (IQD) de 0 a 100.
  static double calculate({
    required double fiberGrams,
    required double sodiumMg,
    required double addedSugarGrams,
  }) =>
      IqdCalculator.calculate(
          fiberGrams: fiberGrams,
          sodiumMg: sodiumMg,
          addedSugarGrams: addedSugarGrams);

  /// Faixa da nota (≥75 "Muito bom", ≥50 "Regular", abaixo "Ruim").
  static Map<String, dynamic> getScoreLabel(double score) =>
      switch (IqdCalculator.bandOf(score)) {
        IqdBand.veryGood => {'label': 'Muito bom', 'color': 'green'},
        IqdBand.regular => {'label': 'Regular', 'color': 'yellow'},
        IqdBand.poor => {'label': 'Ruim', 'color': 'red'},
      };
}
