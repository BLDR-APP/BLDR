import 'package:bldr_fitness/features/analytics/domain/entities/workout_analytics.dart';
import 'package:bldr_fitness/features/analytics/domain/services/nutrition_analytics_engine.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/macro_nutrients.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/meal_entry.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/nutrition_goals.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final range = WorkoutAnalyticsRange(
      start: DateTime.utc(2026, 9, 1), end: DateTime.utc(2026, 9, 8));
  MealEntry meal(String id, String date, double calories) => MealEntry(
      id: id,
      userId: 'u',
      mealType: 'Lunch',
      date: DateTime.parse('${date}T12:00:00Z'),
      foodName: id,
      quantityGrams: 100,
      macros:
          MacroNutrients(calories: calories, protein: 20, carbs: 30, fat: 10));
  test('keeps empty history distinct from zero confirmed consumption', () {
    final result =
        const NutritionAnalyticsEngine().summarize(range: range, entries: []);
    expect(result.loggedDays, 0);
    expect(result.days, isEmpty);
    expect(result.periodTotals.calories, 0);
  });
  test('aggregates multiple meals, goals and excludes out-of-range entries',
      () {
    final result = const NutritionAnalyticsEngine().summarize(
        range: range,
        entries: [
          meal('a', '2026-09-02', 500),
          meal('b', '2026-09-02', 300),
          meal('old', '2026-08-30', 900)
        ],
        currentGoals: const NutritionGoals(
            calories: 1000, protein: 40, carbs: 60, fat: 20));
    expect(result.loggedDays, 1);
    expect(result.days.single.entriesCount, 2);
    expect(result.periodTotals.calories, 800);
    expect(result.calorieGoalAdherencePercent, 80);
  });
  test(
      'does not invent historical goals and preserves previous comparison totals',
      () {
    final result = const NutritionAnalyticsEngine().summarize(
        range: range,
        entries: [meal('a', '2026-09-02', 500)],
        previousEntries: [meal('p', '2026-08-28', 400)]);
    expect(result.currentGoals, isNull);
    expect(result.calorieGoalAdherencePercent, isNull);
    expect(result.previousPeriodTotals!.calories, 400);
  });
}
