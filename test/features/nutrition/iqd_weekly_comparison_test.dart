import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/features/nutrition/domain/entities/macro_nutrients.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/meal_entry.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/nutrition_goals.dart';
import 'package:bldr_fitness/features/nutrition/domain/services/iqd_calculator.dart';
import 'package:bldr_fitness/features/nutrition/domain/usecases/nutrition_usecases.dart';
import 'package:bldr_fitness/services/iqd_calculator_service.dart';

import 'nutrition_usecases_test.dart' show FakeDiaryRepository;

MealEntry _e(DateTime d, {double fiber = 0, double sodium = 0, double sugar = 0}) =>
    MealEntry(
      userId: 'u',
      mealType: 'lunch',
      date: d,
      foodName: 'x',
      quantityGrams: 100,
      macros: MacroNutrients(
          calories: 100,
          protein: 0,
          carbs: 0,
          fat: 0,
          fiber: fiber,
          sodium: sodium,
          addedSugar: sugar),
    );

void main() {
  final day = DateTime(2026, 9, 10);
  DateTime ago(int n) => DateTime(day.year, day.month, day.day - n);

  test('fórmula inalterada e faixa ≥75 renomeada para Muito bom', () {
    expect(IqdCalculator.calculate(fiberGrams: 25, sodiumMg: 0, addedSugarGrams: 0), 100);
    expect(IqdCalculator.calculate(fiberGrams: 0, sodiumMg: 2500, addedSugarGrams: 75), 40);
    expect(IqdCalculator.bandOf(75), IqdBand.veryGood);
    expect(IqdCalculator.bandOf(74.9), IqdBand.regular);
    expect(IqdCalculator.bandOf(49), IqdBand.poor);
    expect(IqdCalculatorService.getScoreLabel(80)['label'], 'Muito bom');
  });

  test('compara com a média dos 7 dias anteriores com registro', () async {
    final repo = FakeDiaryRepository();
    repo.entries.addAll([
      _e(day, fiber: 15), // 84
      _e(ago(1), fiber: 10), // 76
      _e(ago(3), fiber: 5), // 68
      _e(ago(8), fiber: 25), // fora da janela
    ]);
    final r = await GetIqdWeeklyComparison(GetMealsForRange(repo))(day);
    final v = r.valueOrNull!;
    expect(repo.rangeCalls, 1);
    expect(v.score, 84);
    expect(v.band, IqdBand.veryGood);
    expect(v.weekAverage, 72);
    expect(v.delta, 12);
  });

  test('sem dia anterior com registro → sem delta', () async {
    final repo = FakeDiaryRepository()..entries.add(_e(day, fiber: 5));
    final v = (await GetIqdWeeklyComparison(GetMealsForRange(repo))(day)).valueOrNull!;
    expect(v.weekAverage, isNull);
    expect(v.delta, isNull);
  });

  test('meta de água padrão é 2500 ml', () {
    expect(NutritionGoals.defaults.waterMl, 2500);
  });
}
