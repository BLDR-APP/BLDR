import 'package:bldr_fitness/features/analytics/domain/entities/workout_analytics.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/macro_nutrients.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/nutrition_goals.dart';

class NutritionDailyConsumption {
  final DateTime date;
  final MacroNutrients totals;
  final int entriesCount;
  const NutritionDailyConsumption(
      {required this.date, required this.totals, required this.entriesCount});
}

class NutritionAnalyticsSummary {
  final WorkoutAnalyticsRange range;
  final List<NutritionDailyConsumption> days;
  final MacroNutrients periodTotals;
  final MacroNutrients averagePerLoggedDay;
  final int loggedDays;
  final double consistencyPercent;
  final NutritionGoals? currentGoals;
  final double? calorieGoalAdherencePercent;
  final double? proteinGoalAdherencePercent;
  final double? carbsGoalAdherencePercent;
  final double? fatGoalAdherencePercent;
  final MacroNutrients? previousPeriodTotals;

  const NutritionAnalyticsSummary({
    required this.range,
    required this.days,
    required this.periodTotals,
    required this.averagePerLoggedDay,
    required this.loggedDays,
    required this.consistencyPercent,
    this.currentGoals,
    this.calorieGoalAdherencePercent,
    this.proteinGoalAdherencePercent,
    this.carbsGoalAdherencePercent,
    this.fatGoalAdherencePercent,
    this.previousPeriodTotals,
  });
}
