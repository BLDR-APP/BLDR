import 'package:bldr_fitness/features/analytics/domain/entities/nutrition_analytics.dart';
import 'package:bldr_fitness/features/analytics/domain/entities/workout_analytics.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/macro_nutrients.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/meal_entry.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/nutrition_goals.dart';

/// Agrega entradas já lidas. Dias sem entrada permanecem desconhecidos: não são
/// contabilizados como consumo zero nem como aderência à meta.
class NutritionAnalyticsEngine {
  const NutritionAnalyticsEngine();

  NutritionAnalyticsSummary summarize({
    required WorkoutAnalyticsRange range,
    required Iterable<MealEntry> entries,
    NutritionGoals? currentGoals,
    Iterable<MealEntry> previousEntries = const [],
  }) {
    final grouped = <DateTime, List<MealEntry>>{};
    for (final entry in entries) {
      if (entry.userId.isEmpty || !range.contains(entry.date)) continue;
      final day =
          DateTime.utc(entry.date.year, entry.date.month, entry.date.day);
      grouped.putIfAbsent(day, () => []).add(entry);
    }
    final days = grouped.entries.map((item) {
      var totals = MacroNutrients.zero;
      for (final entry in item.value) {
        totals = totals + entry.macros;
      }
      return NutritionDailyConsumption(
          date: item.key, totals: totals, entriesCount: item.value.length);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    var total = MacroNutrients.zero;
    for (final day in days) {
      total = total + day.totals;
    }
    final count = days.length;
    MacroNutrients average() => count == 0
        ? MacroNutrients.zero
        : MacroNutrients(
            calories: total.calories / count,
            protein: total.protein / count,
            carbs: total.carbs / count,
            fat: total.fat / count,
          );
    MacroNutrients sum(Iterable<MealEntry> source) {
      var value = MacroNutrients.zero;
      for (final item in source) {
        value = value + item.macros;
      }
      return value;
    }

    double? adherence(double actual, int goal) =>
        goal <= 0 || count == 0 ? null : actual / count / goal * 100;
    return NutritionAnalyticsSummary(
      range: range,
      days: List.unmodifiable(days),
      periodTotals: total,
      averagePerLoggedDay: average(),
      loggedDays: count,
      consistencyPercent:
          range.duration.inDays == 0 ? 0 : count / range.duration.inDays * 100,
      currentGoals: currentGoals,
      calorieGoalAdherencePercent: currentGoals == null
          ? null
          : adherence(total.calories, currentGoals.calories),
      proteinGoalAdherencePercent: currentGoals == null
          ? null
          : adherence(total.protein, currentGoals.protein),
      carbsGoalAdherencePercent: currentGoals == null
          ? null
          : adherence(total.carbs, currentGoals.carbs),
      fatGoalAdherencePercent:
          currentGoals == null ? null : adherence(total.fat, currentGoals.fat),
      previousPeriodTotals:
          previousEntries.isEmpty ? null : sum(previousEntries),
    );
  }
}
