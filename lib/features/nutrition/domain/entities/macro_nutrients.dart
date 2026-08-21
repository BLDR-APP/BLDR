/// Totais de macronutrientes (valor calculado, imutável).
class MacroNutrients {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sodium;
  final double fiber;
  final double addedSugar;

  const MacroNutrients({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.sodium = 0,
    this.fiber = 0,
    this.addedSugar = 0,
  });

  static const zero = MacroNutrients();

  /// Regra de 3 a partir dos valores por 100g — a lógica de cálculo central
  /// de nutrição do app (antes em FirebaseNutritionService.calculateMacros).
  factory MacroNutrients.fromPer100g({
    required double quantityGrams,
    required double caloriesPer100g,
    required double proteinPer100g,
    required double carbsPer100g,
    required double fatPer100g,
    double sodiumPer100g = 0,
    double fiberPer100g = 0,
    double addedSugarPer100g = 0,
  }) {
    if (quantityGrams <= 0) return zero;
    final m = quantityGrams / 100.0;
    return MacroNutrients(
      calories: caloriesPer100g * m,
      protein: proteinPer100g * m,
      carbs: carbsPer100g * m,
      fat: fatPer100g * m,
      sodium: sodiumPer100g * m,
      fiber: fiberPer100g * m,
      addedSugar: addedSugarPer100g * m,
    );
  }

  MacroNutrients operator +(MacroNutrients other) => MacroNutrients(
        calories: calories + other.calories,
        protein: protein + other.protein,
        carbs: carbs + other.carbs,
        fat: fat + other.fat,
        sodium: sodium + other.sodium,
        fiber: fiber + other.fiber,
        addedSugar: addedSugar + other.addedSugar,
      );

  /// Arredonda cada macro para o inteiro mais próximo (como o app grava hoje).
  MacroNutrients rounded() => MacroNutrients(
        calories: calories.roundToDouble(),
        protein: protein.roundToDouble(),
        carbs: carbs.roundToDouble(),
        fat: fat.roundToDouble(),
        sodium: sodium.roundToDouble(),
        fiber: fiber.roundToDouble(),
        addedSugar: addedSugar.roundToDouble(),
      );
}
