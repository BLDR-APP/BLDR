import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/daily_nutrition_summary.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/meal_entry.dart';

/// Diário alimentar do usuário (Firestore `user_meals`).
abstract class NutritionDiaryRepository {
  Future<Result<void>> addEntry(MealEntry entry);

  /// Atualiza a quantidade de um registro, com macros já recalculados.
  Future<Result<void>> updateEntry({
    required String entryId,
    required MealEntry updated,
  });

  Future<Result<void>> deleteEntry(String entryId);

  Future<Result<List<MealEntry>>> mealsForDate(DateTime date, {String? userId});

  Future<Result<DailyNutritionSummary>> dailySummary(DateTime date,
      {String? userId});
}
