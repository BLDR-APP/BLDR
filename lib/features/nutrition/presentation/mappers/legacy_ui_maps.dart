import 'package:bldr_fitness/features/nutrition/domain/entities/daily_nutrition_summary.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/food_item.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/macro_nutrients.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/meal_entry.dart';

/// Mappers TRANSITÓRIOS entre as entidades do domain e o formato de map
/// que os widgets legados de nutrição ainda renderizam.
///
/// Dívida técnica registrada no ARCHITECTURE.md: quando os widgets internos
/// (MealTimelineWidget, DailyNutritionOverviewWidget, modal) forem tipados,
/// este arquivo deve ser removido. Não usar em código novo.

Map<String, dynamic> foodItemToLegacyMap(FoodItem item) => {
      'id': item.id,
      'name': item.name,
      if (item.brand != null) 'brand': item.brand,
      if (item.category != null) 'category': item.category,
      if (item.createdBy != null) 'created_by': item.createdBy,
      'calories_per_100g': item.caloriesPer100g,
      'protein_per_100g': item.proteinPer100g,
      'carbs_per_100g': item.carbsPer100g,
      'fat_per_100g': item.fatPer100g,
      'sodium_per_100g': item.sodiumPer100g,
      'fiber_per_100g': item.fiberPer100g,
      'added_sugar_per_100g': item.addedSugarPer100g,
    };

FoodItem legacyMapToFoodItem(Map<String, dynamic> map) {
  double read(String key, [String? fallback]) =>
      (map[key] as num?)?.toDouble() ??
      (fallback != null ? (map[fallback] as num?)?.toDouble() : null) ??
      0.0;
  return FoodItem(
    id: map['id'] as String?,
    name: map['name'] as String? ?? '',
    brand: map['brand'] as String?,
    category: map['category'] as String?,
    createdBy: map['created_by'] as String?,
    caloriesPer100g: read('calories_per_100g'),
    proteinPer100g: read('protein_per_100g'),
    carbsPer100g: read('carbs_per_100g'),
    fatPer100g: read('fat_per_100g'),
    sodiumPer100g: read('sodium_per_100g', 'sodium'),
    fiberPer100g: read('fiber_per_100g', 'fiber'),
    addedSugarPer100g: read('added_sugar_per_100g', 'added_sugar'),
  );
}

Map<String, dynamic> mealEntryToLegacyMap(MealEntry entry) => {
      'id': entry.id,
      'user_id': entry.userId,
      'meal_type': entry.mealType,
      'date': entry.date.toIso8601String().split('T')[0],
      'food_name': entry.foodName,
      'food_item_id': entry.foodItemId,
      'created_by': entry.createdBy,
      'quantity_grams': entry.quantityGrams,
      'calories': entry.macros.calories,
      'protein': entry.macros.protein,
      'carbs': entry.macros.carbs,
      'fat': entry.macros.fat,
      'sodium': entry.macros.sodium,
      'fiber': entry.macros.fiber,
      'added_sugar': entry.macros.addedSugar,
    };

MealEntry legacyMapToMealEntry(Map<String, dynamic> map) {
  double read(String key) => (map[key] as num?)?.toDouble() ?? 0.0;
  return MealEntry(
    id: map['id'] as String?,
    userId: map['user_id'] as String? ?? '',
    mealType: map['meal_type'] as String? ?? '',
    date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
    foodName: map['food_name'] as String? ?? '',
    foodItemId: map['food_item_id'] as String?,
    createdBy: map['created_by'] as String?,
    quantityGrams: read('quantity_grams'),
    macros: MacroNutrients(
      calories: read('calories'),
      protein: read('protein'),
      carbs: read('carbs'),
      fat: read('fat'),
      sodium: read('sodium'),
      fiber: read('fiber'),
      addedSugar: read('added_sugar'),
    ),
  );
}

/// Mesmas chaves e arredondamentos do summary legado.
Map<String, dynamic> summaryToLegacyMap(DailyNutritionSummary summary) => {
      'date': summary.date.toIso8601String().split('T')[0],
      'total_calories': summary.totals.calories.round(),
      'total_protein': summary.totals.protein.round(),
      'total_carbs': summary.totals.carbs.round(),
      'total_fat': summary.totals.fat.round(),
      'total_sodium': summary.totals.sodium.roundToDouble(),
      'total_fiber': summary.totals.fiber.roundToDouble(),
      'total_added_sugar': summary.totals.addedSugar.roundToDouble(),
      'meals_count': summary.mealsCount,
    };
