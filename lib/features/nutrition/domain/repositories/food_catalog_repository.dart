import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/food_country.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/food_item.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/saved_meal.dart';

/// Catálogo de alimentos (Firestore `alimentos` + favoritos/recentes do usuário).
abstract class FoodCatalogRepository {
  /// Busca por nome, sem diferenciar maiúsculas/minúsculas nem acentos.
  Future<Result<List<FoodItem>>> search(String query,
      {int limit = 20, FoodCountry country = FoodCountry.br});

  Future<Result<List<FoodItem>>> byCategory(String category,
      {int limit = 30, FoodCountry country = FoodCountry.br});

  Future<Result<List<FoodItem>>> favorites(String userId);

  /// Salva um alimento manual nos favoritos e o retorna com id.
  Future<Result<FoodItem>> saveFavorite(FoodItem item, String userId);

  /// Alimentos consumidos recentemente (deduplicados, por 100g reconstruído).
  Future<Result<List<FoodItem>>> recentFoods(String userId, {int limit = 15});

  /// Refeições salvas do usuário (N7, `user_favorites` com `type: 'meal'`).
  Future<Result<List<SavedMeal>>> savedMeals(String userId);

  Future<Result<SavedMeal>> saveMeal(SavedMeal meal, String userId);

  /// Remove só o documento `type: 'meal'` dessa refeição.
  Future<Result<void>> deleteSavedMeal(String id);
}
