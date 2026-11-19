import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/features/nutrition/data/models/food_item_model.dart';
import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/widgets/v2/nutrition_create_food_sheets.dart';

void main() {
  test('rascunho vira FoodItem por 100 g (vírgula decimal)', () {
    const d = CreateFoodDraft(name: ' Iogurte ', brand: 'Marca X', values: {
      'kcal': '62',
      'p': '3,5',
      'c': '4.7',
      'f': '3,3',
      'fiber': '',
      'sodium': '46',
      'sugar': '4,7',
    });
    final f = d.toFoodItem()!;
    expect(f.name, 'Iogurte');
    expect(f.brand, 'Marca X');
    expect(f.caloriesPer100g, 62);
    expect(f.proteinPer100g, 3.5);
    expect(f.carbsPer100g, 4.7);
    expect(f.fiberPer100g, 0);
    expect(f.sodiumPer100g, 46);
    expect(f.macrosFor(200).calories, 124);
  });

  test('sem calorias, calcula por 4/4/9', () {
    const d = CreateFoodDraft(name: 'X', values: {'p': '10', 'c': '20', 'f': '5'});
    expect(d.toFoodItem()!.caloriesPer100g, 165);
  });

  test('sem nenhum valor → null', () {
    expect(const CreateFoodDraft(name: 'X').toFoodItem(), isNull);
  });

  test('favorito grava marca e lê de volta', () {
    const d = CreateFoodDraft(name: 'X', brand: 'B', values: {'kcal': '1'});
    final map = FoodItemModel.toFavoriteMap(d.toFoodItem()!, 'u');
    expect(map['brand'], 'B');
    expect(map['calories_per_100g'], 1);
    expect(FoodItemModel.fromMap(map).brand, 'B');
    final noBrand = FoodItemModel.toFavoriteMap(
        const CreateFoodDraft(name: 'Y', values: {'kcal': '1'}).toFoodItem()!,
        'u');
    expect(noBrand.containsKey('brand'), isFalse);
  });
}
