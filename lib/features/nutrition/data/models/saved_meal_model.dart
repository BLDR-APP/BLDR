import 'package:bldr_fitness/features/nutrition/domain/entities/macro_nutrients.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/saved_meal.dart';

/// SavedMeal <-> documento de `user_favorites` com `type: 'meal'`.
/// Itens usam as mesmas chaves de `user_meals` (totais da quantidade).
class SavedMealModel {
  static SavedMeal fromMap(Map<String, dynamic> map) {
    double r(Map m, String k) => (m[k] as num?)?.toDouble() ?? 0;
    final items = (map['items'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => SavedMealItem(
              foodName: m['food_name'] as String? ?? '',
              foodItemId: m['food_item_id'] as String?,
              quantityGrams: r(m, 'quantity_grams'),
              macros: MacroNutrients(
                calories: r(m, 'calories'),
                protein: r(m, 'protein'),
                carbs: r(m, 'carbs'),
                fat: r(m, 'fat'),
                sodium: r(m, 'sodium'),
                fiber: r(m, 'fiber'),
                addedSugar: r(m, 'added_sugar'),
              ),
            ))
        .toList();
    return SavedMeal(
        id: map['id'] as String?,
        name: map['name'] as String? ?? '',
        items: items);
  }

  static Map<String, dynamic> toMap(SavedMeal meal, String userId) => {
        'user_id': userId,
        'type': 'meal',
        'name': meal.name,
        'items': [
          for (final i in meal.items)
            {
              'food_name': i.foodName,
              'food_item_id': i.foodItemId,
              'quantity_grams': i.quantityGrams,
              'calories': i.macros.calories,
              'protein': i.macros.protein,
              'carbs': i.macros.carbs,
              'fat': i.macros.fat,
              'sodium': i.macros.sodium,
              'fiber': i.macros.fiber,
              'added_sugar': i.macros.addedSugar,
            },
        ],
      };
}
