import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/food_item.dart';

/// Catálogo de alimentos (Firestore `alimentos` + favoritos/recentes do usuário).
abstract class FoodCatalogRepository {
  /// Busca por prefixo de nome (a base grava nomes em CAIXA ALTA).
  Future<Result<List<FoodItem>>> search(String query, {int limit = 20});

  Future<Result<List<FoodItem>>> byCategory(String category, {int limit = 30});

  Future<Result<List<FoodItem>>> favorites(String userId);

  /// Salva um alimento manual nos favoritos e o retorna com id.
  Future<Result<FoodItem>> saveFavorite(FoodItem item, String userId);

  /// Alimentos consumidos recentemente (deduplicados, por 100g reconstruído).
  Future<Result<List<FoodItem>>> recentFoods(String userId, {int limit = 15});
}
