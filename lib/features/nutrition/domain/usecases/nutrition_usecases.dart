import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/daily_nutrition_summary.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/food_item.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/meal_entry.dart';
import 'package:bldr_fitness/features/nutrition/domain/services/iqd_calculator.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/nutrition_goals.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/user_goals.dart';
import 'package:bldr_fitness/features/nutrition/domain/repositories/food_catalog_repository.dart';
import 'package:bldr_fitness/features/nutrition/domain/repositories/nutrition_diary_repository.dart';
import 'package:bldr_fitness/features/nutrition/domain/repositories/nutrition_goals_repository.dart';
import 'package:bldr_fitness/features/nutrition/domain/repositories/nutrition_xp_repository.dart';

// --- Catálogo ---

class SearchFoods {
  final FoodCatalogRepository _catalog;
  const SearchFoods(this._catalog);

  Future<Result<List<FoodItem>>> call(String query, {int limit = 20}) =>
      _catalog.search(query, limit: limit);
}

class GetCategoryFoods {
  final FoodCatalogRepository _catalog;
  const GetCategoryFoods(this._catalog);

  Future<Result<List<FoodItem>>> call(String category, {int limit = 30}) =>
      _catalog.byCategory(category, limit: limit);
}

class GetFavoriteFoods {
  final FoodCatalogRepository _catalog;
  const GetFavoriteFoods(this._catalog);

  Future<Result<List<FoodItem>>> call(String userId) =>
      _catalog.favorites(userId);
}

class SaveFavoriteFood {
  final FoodCatalogRepository _catalog;
  const SaveFavoriteFood(this._catalog);

  Future<Result<FoodItem>> call(FoodItem item, String userId) =>
      _catalog.saveFavorite(item, userId);
}

class GetRecentFoods {
  final FoodCatalogRepository _catalog;
  const GetRecentFoods(this._catalog);

  Future<Result<List<FoodItem>>> call(String userId) =>
      _catalog.recentFoods(userId);
}

// --- Metas ---

class GetNutritionGoals {
  final NutritionGoalsRepository _goals;
  const GetNutritionGoals(this._goals);

  Future<Result<NutritionGoals>> call(String userId) => _goals.getGoals(userId);
}

class GetUserGoals {
  final NutritionGoalsRepository _goals;
  const GetUserGoals(this._goals);
  Future<Result<UserGoals>> call(String userId) => _goals.getFullGoals(userId);
}

class SaveUserGoals {
  final NutritionGoalsRepository _goals;
  const SaveUserGoals(this._goals);
  Future<Result<void>> call(String userId, UserGoals goals) =>
      _goals.saveFullGoals(userId, goals);
}

// --- Diário ---

class GetMealsForDate {
  final NutritionDiaryRepository _diary;
  const GetMealsForDate(this._diary);

  Future<Result<List<MealEntry>>> call(DateTime date, {String? userId}) =>
      _diary.mealsForDate(date, userId: userId);
}

class GetMealsForRange {
  final NutritionDiaryRepository _diary;
  const GetMealsForRange(this._diary);

  Future<Result<List<MealEntry>>> call(DateTime start, DateTime end,
          {String? userId}) =>
      _diary.mealsForRange(start, end, userId: userId);
}

/// IQD do dia comparado com a média dos 7 dias anteriores que têm registro.
class IqdWeeklyComparison {
  final double score;
  final IqdBand band;

  /// Média dos dias anteriores com registro; `null` se não houver nenhum.
  final double? weekAverage;
  const IqdWeeklyComparison(
      {required this.score, required this.band, this.weekAverage});

  /// Diferença arredondada (dia − média); `null` sem dia anterior.
  int? get delta => weekAverage == null ? null : (score - weekAverage!).round();
}

/// Uma consulta por intervalo (8 dias: os 7 anteriores + o dia), IQD por dia
/// com [IqdCalculator] e média só dos dias anteriores que têm registro.
class GetIqdWeeklyComparison {
  final GetMealsForRange _range;
  const GetIqdWeeklyComparison(this._range);

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static double scoreOf(List<MealEntry> entries) {
    var fiber = 0.0, sodium = 0.0, sugar = 0.0;
    for (final e in entries) {
      fiber += e.macros.fiber;
      sodium += e.macros.sodium;
      sugar += e.macros.addedSugar;
    }
    return IqdCalculator.calculate(
        fiberGrams: fiber, sodiumMg: sodium, addedSugarGrams: sugar);
  }

  Future<Result<IqdWeeklyComparison>> call(DateTime date,
      {String? userId}) async {
    final day = DateTime(date.year, date.month, date.day);
    final start = DateTime(day.year, day.month, day.day - 7);
    final result = await _range(start, day, userId: userId);
    return result.map((entries) {
      final byDay = <String, List<MealEntry>>{};
      for (final e in entries) {
        byDay.putIfAbsent(_key(e.date), () => []).add(e);
      }
      final score = scoreOf(byDay[_key(day)] ?? const []);
      final previous = <double>[];
      for (var i = 1; i <= 7; i++) {
        final list = byDay[_key(DateTime(day.year, day.month, day.day - i))];
        if (list != null && list.isNotEmpty) previous.add(scoreOf(list));
      }
      return IqdWeeklyComparison(
        score: score,
        band: IqdCalculator.bandOf(score),
        weekAverage: previous.isEmpty
            ? null
            : previous.reduce((a, b) => a + b) / previous.length,
      );
    });
  }
}

class GetDailySummary {
  final NutritionDiaryRepository _diary;
  const GetDailySummary(this._diary);

  Future<Result<DailyNutritionSummary>> call(DateTime date, {String? userId}) =>
      _diary.dailySummary(date, userId: userId);
}

class DeleteMealEntry {
  final NutritionDiaryRepository _diary;
  const DeleteMealEntry(this._diary);

  Future<Result<void>> call(String entryId) => _diary.deleteEntry(entryId);
}

/// Atualiza a quantidade de um registro existente, recalculando os macros a
/// partir dos valores por 100g reconstruídos do próprio registro.
class UpdateMealQuantity {
  final NutritionDiaryRepository _diary;
  const UpdateMealQuantity(this._diary);

  Future<Result<void>> call({
    required MealEntry entry,
    required double newQuantityGrams,
  }) {
    if (entry.id == null) {
      return Future.value(
          const Result.failure(ValidationFailure('Registro sem id.')));
    }
    final per100g = entry.per100g;
    final updated = entry.copyWith(
      quantityGrams: newQuantityGrams,
      macros: FoodItem(
        name: entry.foodName,
        caloriesPer100g: per100g.calories,
        proteinPer100g: per100g.protein,
        carbsPer100g: per100g.carbs,
        fatPer100g: per100g.fat,
        sodiumPer100g: per100g.sodium,
        fiberPer100g: per100g.fiber,
        addedSugarPer100g: per100g.addedSugar,
      ).macrosFor(newQuantityGrams).rounded(),
    );
    return _diary.updateEntry(entryId: entry.id!, updated: updated);
  }
}

/// Registra um alimento numa refeição e aplica a gamificação:
/// +80 XP por registro e +150 XP na primeira vez que o dia fica completo
/// (Breakfast, Lunch, Dinner e Snack registrados).
class LogMeal {
  static const _requiredMealTypes = {'Breakfast', 'Lunch', 'Dinner', 'Snack'};

  final NutritionDiaryRepository _diary;
  final NutritionXpRepository _xp;

  const LogMeal(this._diary, this._xp);

  Future<Result<void>> call({
    required String userId,
    required String mealType,
    required DateTime mealDate,
    required FoodItem food,
    required double quantityGrams,
    String? createdBy,
  }) async {
    final entry = MealEntry(
      userId: userId,
      mealType: mealType,
      date: mealDate,
      timestamp: DateTime.now(),
      foodName: food.name,
      foodItemId: food.id,
      createdBy: food.createdBy ?? createdBy,
      quantityGrams: quantityGrams,
      macros: food.macrosFor(quantityGrams).rounded(),
    );

    final saved = await _diary.addEntry(entry);
    if (saved.isFailure) return saved;

    final xp = await _xp.awardMealXp(userId);
    if (xp.isFailure) return xp;

    // Bônus diário: só quando as 4 refeições do dia estão presentes.
    final mealsResult = await _diary.mealsForDate(mealDate, userId: userId);
    final meals = mealsResult.valueOrNull;
    if (meals != null) {
      final types = meals.map((m) => m.mealType).toSet();
      if (types.containsAll(_requiredMealTypes)) {
        final bonus = await _xp.awardDailyBonusIfNeeded(userId, mealDate);
        if (bonus.isFailure) return bonus;
      }
    }

    return const Result.success(null);
  }
}
