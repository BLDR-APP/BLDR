import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/features/nutrition/data/models/food_item_model.dart';
import 'package:bldr_fitness/features/nutrition/data/models/meal_entry_model.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/macro_nutrients.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/meal_entry.dart';
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

  test('líquido por unidade grava unit/unit_weight/unit_description', () {
    const d = CreateFoodDraft(
        name: 'Leite',
        liquid: true,
        byUnit: true,
        unitWeight: '200',
        unitDescription: '1 copo',
        values: {'kcal': '60'});
    final f = d.toFoodItem()!;
    expect(f.isLiquid, isTrue);
    expect(f.unit, 'ml');
    expect(f.unitWeight, 200);
    final map = FoodItemModel.toFavoriteMap(f, 'u');
    expect(map['unit'], 'ml');
    expect(map['unit_weight'], 200);
    expect(map['unit_description'], '1 copo');
    final back = FoodItemModel.fromMap(map);
    expect(back.isLiquid, isTrue);
    expect(back.unitWeight, 200);
    expect(back.unitDescription, '1 copo');
  });

  test('padrão sólido não grava campos opcionais', () {
    const d = CreateFoodDraft(name: 'Pão', values: {'kcal': '1'}, unitWeight: '50');
    final map = FoodItemModel.toFavoriteMap(d.toFoodItem()!, 'u');
    expect(map.containsKey('unit'), isFalse);
    expect(map.containsKey('unit_weight'), isFalse);
  });

  test('peso de unidade inválido → null', () {
    expect(const CreateFoodDraft(unitWeight: '0').unitWeightValue, isNull);
    expect(const CreateFoodDraft(unitWeight: '55,5').unitWeightValue, 55.5);
  });

  test('diário guarda unit ml e lê de volta', () {
    final e = MealEntry(
        userId: 'u',
        mealType: 'snack',
        date: DateTime(2026, 9, 4),
        foodName: 'Leite',
        quantityGrams: 200,
        macros: const MacroNutrients(calories: 120, protein: 6, carbs: 10, fat: 6),
        unit: 'ml');
    final map = MealEntryModel.toMap(e);
    expect(map['unit'], 'ml');
    expect(MealEntryModel.fromMap(map).isLiquid, isTrue);
    expect(MealEntryModel.toMap(MealEntry(
            userId: 'u', mealType: 'x', date: DateTime(2026), foodName: 'a',
            quantityGrams: 1, macros: MacroNutrients.zero))
        .containsKey('unit'), isFalse);
    expect(e.copyWith(quantityGrams: 300).unit, 'ml');
  });
}
