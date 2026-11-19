import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/features/nutrition/domain/entities/macro_nutrients.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/meal_entry.dart';
import 'package:bldr_fitness/features/nutrition/domain/usecases/nutrition_usecases.dart';

import 'nutrition_usecases_test.dart' show FakeDiaryRepository;

void main() {
  group('nutritionGoalCrossed', () {
    test('dispara só ao cruzar a meta', () {
      expect(nutritionGoalCrossed(before: 2300, after: 2600, goal: 2500), isTrue);
      expect(nutritionGoalCrossed(before: 2000, after: 2500, goal: 2500), isTrue);
      expect(nutritionGoalCrossed(before: 2500, after: 2800, goal: 2500), isFalse);
      expect(nutritionGoalCrossed(before: 1000, after: 2000, goal: 2500), isFalse);
      expect(nutritionGoalCrossed(before: 0, after: 10, goal: 0), isFalse);
    });
  });

  test('RestoreMealEntry regrava o registro com o horário original', () async {
    final repo = FakeDiaryRepository();
    final ts = DateTime(2026, 9, 4, 12, 30);
    final entry = MealEntry(
      id: 'abc',
      userId: 'u',
      mealType: 'lunch',
      date: DateTime(2026, 9, 4),
      timestamp: ts,
      foodName: 'Arroz',
      quantityGrams: 150,
      macros: const MacroNutrients(calories: 186, protein: 4, carbs: 39, fat: 2),
    );
    final r = await RestoreMealEntry(repo)(entry);
    expect(r.isSuccess, isTrue);
    expect(repo.entries.single.timestamp, ts);
    expect(repo.entries.single.quantityGrams, 150);
  });
}
