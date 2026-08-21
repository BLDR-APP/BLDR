import 'package:bldr_fitness/features/nutrition/domain/entities/macro_nutrients.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/meal_entry.dart';

/// Resumo do dia: soma dos macros de todas as refeições.
class DailyNutritionSummary {
  final DateTime date;
  final MacroNutrients totals;
  final int mealsCount;

  const DailyNutritionSummary({
    required this.date,
    required this.totals,
    required this.mealsCount,
  });

  factory DailyNutritionSummary.fromEntries(
      DateTime date, List<MealEntry> entries) {
    var totals = MacroNutrients.zero;
    for (final e in entries) {
      totals = totals + e.macros;
    }
    return DailyNutritionSummary(
      date: date,
      totals: totals,
      mealsCount: entries.length,
    );
  }
}
