import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/features/nutrition/data/datasources/firestore_nutrition_datasource.dart';
import 'package:bldr_fitness/features/nutrition/data/models/food_item_model.dart';

void main() {
  test('favoritos ignoram refeições salvas e aceitam docs antigos', () {
    final docs = [
      {'id': 'a', 'name': 'Iogurte', 'calories_per_100g': 62},
      {'id': 'm', 'name': 'Almoço', 'type': 'meal', 'items': []},
      {'id': 'b', 'name': 'Leite', 'unit': 'ml', 'calories_per_100g': 60},
    ];
    final foods = FirestoreNutritionDatasource.foodsOnly(docs);
    expect(foods.map((d) => d['id']), ['a', 'b']);
    // O leitor de alimentos não quebra mesmo se receber o doc de refeição.
    expect(FoodItemModel.fromMap(docs[1]).caloriesPer100g, 0);
  });
}
