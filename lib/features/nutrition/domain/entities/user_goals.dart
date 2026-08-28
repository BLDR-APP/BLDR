/// Metas completas do usuário: nutrição + peso + ritmo.
/// Superconjunto de NutritionGoals — inclui campos que só a tela de Metas usa.
class UserGoals {
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final double? targetWeightKg;
  final double? currentWeightKg;
  final String goalPace; // 'Leve' | 'Moderado' | 'Agressivo'
  final bool customCalories; // true = usuário sobrescreveu o valor calculado

  const UserGoals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.targetWeightKg,
    this.currentWeightKg,
    this.goalPace = 'Moderado',
    this.customCalories = false,
  });

  static const defaults = UserGoals(
    calories: 2000,
    protein: 120,
    carbs: 250,
    fat: 67,
  );
}
