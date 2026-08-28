/// Metas diárias de calorias e macros do usuário (calculadas no onboarding).
class NutritionGoals {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  const NutritionGoals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  /// Usado apenas quando o usuário não completou o onboarding ainda.
  static const defaults = NutritionGoals(
    calories: 2000,
    protein: 120,
    carbs: 250,
    fat: 67,
  );
}
