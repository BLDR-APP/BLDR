import 'package:bldr_fitness/features/nutrition/domain/entities/macro_nutrients.dart';

/// Registro de alimento consumido no diário (Firestore `user_meals`).
/// Os macros são os TOTAIS da quantidade consumida (não por 100g).
class MealEntry {
  final String? id;
  final String userId;
  final String mealType; // Breakfast | Lunch | Dinner | Snack
  final DateTime date;
  final DateTime? timestamp;
  final String foodName;
  final String? foodItemId;
  final String? createdBy;
  final double quantityGrams;
  final MacroNutrients macros;

  const MealEntry({
    this.id,
    required this.userId,
    required this.mealType,
    required this.date,
    this.timestamp,
    required this.foodName,
    this.foodItemId,
    this.createdBy,
    required this.quantityGrams,
    required this.macros,
  });

  MealEntry copyWith({double? quantityGrams, MacroNutrients? macros}) =>
      MealEntry(
        id: id,
        userId: userId,
        mealType: mealType,
        date: date,
        timestamp: timestamp,
        foodName: foodName,
        foodItemId: foodItemId,
        createdBy: createdBy,
        quantityGrams: quantityGrams ?? this.quantityGrams,
        macros: macros ?? this.macros,
      );

  /// Reconstrói os valores por 100g a partir dos totais gravados
  /// (engenharia reversa usada por "recentes" e pela edição de quantidade).
  FoodPer100g get per100g {
    final safeQuantity = quantityGrams > 0 ? quantityGrams : 100.0;
    double per(double total) => total / safeQuantity * 100.0;
    return FoodPer100g(
      calories: per(macros.calories),
      protein: per(macros.protein),
      carbs: per(macros.carbs),
      fat: per(macros.fat),
      sodium: per(macros.sodium),
      fiber: per(macros.fiber),
      addedSugar: per(macros.addedSugar),
    );
  }
}

/// Valores por 100g reconstruídos de um [MealEntry].
class FoodPer100g {
  final double calories, protein, carbs, fat, sodium, fiber, addedSugar;
  const FoodPer100g({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sodium,
    required this.fiber,
    required this.addedSugar,
  });
}
