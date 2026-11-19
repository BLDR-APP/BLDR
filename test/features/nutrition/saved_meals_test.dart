import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/nutrition/data/models/saved_meal_model.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/food_item.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/macro_nutrients.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/meal_entry.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/saved_meal.dart';
import 'package:bldr_fitness/features/nutrition/domain/repositories/food_catalog_repository.dart';
import 'package:bldr_fitness/features/nutrition/domain/usecases/nutrition_usecases.dart';

import 'nutrition_usecases_test.dart' show FakeDiaryRepository;

class _FakeCatalog implements FoodCatalogRepository {
  final saved = <SavedMeal>[];
  @override
  Future<Result<SavedMeal>> saveMeal(SavedMeal meal, String userId) async {
    final m = SavedMeal(id: 'm${saved.length}', name: meal.name, items: meal.items);
    saved.add(m);
    return Result.success(m);
  }

  @override
  Future<Result<List<SavedMeal>>> savedMeals(String userId) async =>
      Result.success(saved);
  @override
  noSuchMethod(Invocation i) => throw UnimplementedError();
}

MealEntry _e(String n, double g, double kcal) => MealEntry(
    id: n,
    userId: 'u',
    mealType: 'lunch',
    date: DateTime(2026, 9, 3),
    foodName: n,
    foodItemId: 'f-$n',
    quantityGrams: g,
    macros: MacroNutrients(calories: kcal, protein: 10, carbs: 20, fat: 3));

void main() {
  test('salva refeição com nome e snapshot dos alimentos', () async {
    final cat = _FakeCatalog();
    final r = await SaveMealFromEntries(cat)(
        name: '  Almoço completo ',
        entries: [_e('Arroz', 150, 186), _e('Frango', 180, 297)],
        userId: 'u');
    final m = r.valueOrNull!;
    expect(m.name, 'Almoço completo');
    expect(m.items.map((i) => i.quantityGrams), [150, 180]);
    expect(m.totals.calories, 483);
    expect(m.description, 'Arroz, Frango');
  });

  test('nome vazio ou sem alimentos falha', () async {
    final cat = _FakeCatalog();
    expect((await SaveMealFromEntries(cat)(name: ' ', entries: [_e('A', 1, 1)], userId: 'u')).failureOrNull,
        isA<ValidationFailure>());
    expect((await SaveMealFromEntries(cat)(name: 'X', entries: const [], userId: 'u')).failureOrNull,
        isA<ValidationFailure>());
  });

  test('adicionar ao diário copia itens para data e refeição', () async {
    final diary = FakeDiaryRepository();
    const meal = SavedMeal(name: 'X', items: [
      SavedMealItem(
          foodName: 'Arroz',
          quantityGrams: 150,
          macros: MacroNutrients(calories: 186, protein: 4, carbs: 39, fat: 2)),
    ]);
    final r = await AddSavedMealToDiary(CopyMeal(diary))(
        meal: meal, userId: 'u', date: DateTime(2026, 9, 4), mealType: 'dinner');
    expect(r.valueOrNull, 1);
    expect(diary.entries.single.mealType, 'dinner');
    expect(diary.entries.single.quantityGrams, 150);
  });

  test('modelo: type meal e ida e volta', () {
    const meal = SavedMeal(name: 'X', items: [
      SavedMealItem(
          foodName: 'Arroz',
          foodItemId: 'a',
          quantityGrams: 150,
          macros: MacroNutrients(calories: 186, protein: 4, carbs: 39, fat: 2, fiber: 3)),
    ]);
    final map = SavedMealModel.toMap(meal, 'u');
    expect(map['type'], 'meal');
    expect(map['user_id'], 'u');
    final back = SavedMealModel.fromMap({...map, 'id': 'z'});
    expect(back.id, 'z');
    expect(back.items.single.macros.fiber, 3);
    expect(back.items.single.foodItemId, 'a');
  });

  test('FoodItem não é afetado (sanidade)', () {
    expect(const FoodItem(name: 'a').caloriesPer100g, 0);
  });
}
