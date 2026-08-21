import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:bldr_fitness/features/nutrition/domain/entities/macro_nutrients.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/meal_entry.dart';

/// Conversão MealEntry <-> documentos do Firestore `user_meals`.
class MealEntryModel {
  static String dateKey(DateTime date) =>
      date.toIso8601String().split('T')[0];

  static MealEntry fromMap(Map<String, dynamic> map, {String? id}) {
    double read(String key) => (map[key] as num?)?.toDouble() ?? 0.0;

    return MealEntry(
      id: id ?? map['id'] as String?,
      userId: map['user_id'] as String? ?? '',
      mealType: map['meal_type'] as String? ?? '',
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate(),
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

  static Map<String, dynamic> toMap(MealEntry entry) => {
        'user_id': entry.userId,
        'meal_type': entry.mealType,
        'timestamp': Timestamp.fromDate(entry.timestamp ?? DateTime.now()),
        'date': dateKey(entry.date),
        'food_item_id': entry.foodItemId,
        'food_name': entry.foodName,
        'quantity_grams': entry.quantityGrams,
        'calories': entry.macros.calories,
        'protein': entry.macros.protein,
        'carbs': entry.macros.carbs,
        'fat': entry.macros.fat,
        'sodium': entry.macros.sodium,
        'fiber': entry.macros.fiber,
        'added_sugar': entry.macros.addedSugar,
        'created_by': entry.createdBy,
      };

  static Map<String, dynamic> toQuantityUpdate(MealEntry updated) => {
        'quantity_grams': updated.quantityGrams,
        'calories': updated.macros.calories,
        'protein': updated.macros.protein,
        'carbs': updated.macros.carbs,
        'fat': updated.macros.fat,
        'sodium': updated.macros.sodium,
        'fiber': updated.macros.fiber,
        'added_sugar': updated.macros.addedSugar,
        'updated_at': FieldValue.serverTimestamp(),
      };
}
