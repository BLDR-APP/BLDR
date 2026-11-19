import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/macro_nutrients.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/meal_entry.dart';
import 'package:bldr_fitness/features/nutrition/domain/usecases/nutrition_usecases.dart';

import 'nutrition_usecases_test.dart' show FakeDiaryRepository;

MealEntry _e(String name, double g, double kcal) => MealEntry(
      id: name,
      userId: 'u',
      mealType: 'lunch',
      date: DateTime(2026, 9, 3),
      foodName: name,
      quantityGrams: g,
      macros: MacroNutrients(calories: kcal, protein: 1, carbs: 2, fat: 3),
    );

void main() {
  test('copia para a data/refeição destino preservando quantidades', () async {
    final repo = FakeDiaryRepository()..entries.add(_e('Existente', 50, 60));
    final now = DateTime(2026, 9, 4, 10);
    final r = await CopyMeal(repo)(
      entries: [_e('Arroz', 150, 186), _e('Feijão', 100, 76)],
      toDate: DateTime(2026, 9, 4, 18),
      toMealType: 'dinner',
      now: now,
    );
    expect(r.valueOrNull, 2);
    expect(repo.entries, hasLength(3)); // não substitui o existente
    final copied = repo.entries.skip(1).toList();
    expect(copied.map((e) => e.mealType).toSet(), {'dinner'});
    expect(copied.first.date, DateTime(2026, 9, 4));
    expect(copied.first.id, isNull);
    expect(copied.first.quantityGrams, 150);
    expect(copied.first.macros.calories, 186);
    expect(copied.first.timestamp, now);
  });

  test('lista vazia falha com mensagem', () async {
    final r = await CopyMeal(FakeDiaryRepository())(
        entries: const [], toDate: DateTime(2026), toMealType: 'lunch');
    expect(r.failureOrNull, isA<ValidationFailure>());
  });

  test('para no primeiro erro', () async {
    final repo = FakeDiaryRepository()
      ..nextFailure = const ServerFailure('falhou');
    final r = await CopyMeal(repo)(
        entries: [_e('A', 1, 1)], toDate: DateTime(2026), toMealType: 'lunch');
    expect(r.isFailure, isTrue);
  });
}
