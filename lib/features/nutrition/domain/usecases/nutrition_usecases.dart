import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/daily_nutrition_summary.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/food_item.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/meal_entry.dart';
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

  Future<Result<NutritionGoals>> call(String userId) =>
      _goals.getGoals(userId);
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
