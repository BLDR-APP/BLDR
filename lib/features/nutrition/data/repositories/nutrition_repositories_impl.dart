import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

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
import 'package:bldr_fitness/features/nutrition/data/datasources/firestore_nutrition_datasource.dart';
import 'package:bldr_fitness/features/nutrition/data/datasources/supabase_nutrition_goals_datasource.dart';
import 'package:bldr_fitness/features/nutrition/data/datasources/supabase_xp_datasource.dart';
import 'package:bldr_fitness/features/nutrition/data/models/food_item_model.dart';
import 'package:bldr_fitness/features/nutrition/data/models/meal_entry_model.dart';

/// Converte exceções de Firestore/Supabase/rede em [Failure].
Future<Result<T>> _guard<T>(Future<T> Function() action) async {
  try {
    return Result.success(await action());
  } on Failure catch (f) {
    return Result.failure(f);
  } on FirebaseException catch (e) {
    return Result.failure(
        ServerFailure(e.message ?? 'Erro no banco de alimentos.', cause: e));
  } on supabase.PostgrestException catch (e) {
    return Result.failure(ServerFailure(e.message, cause: e));
  } on SocketException catch (e) {
    return Result.failure(NetworkFailure('Sem conexão com a internet.', e));
  } on TimeoutException catch (e) {
    return Result.failure(NetworkFailure('Tempo de conexão esgotado.', e));
  } catch (e) {
    return Result.failure(UnexpectedFailure('Ocorreu um erro inesperado.', e));
  }
}

class FoodCatalogRepositoryImpl implements FoodCatalogRepository {
  final FirestoreNutritionDatasource _firestore;

  FoodCatalogRepositoryImpl(this._firestore);

  @override
  Future<Result<List<FoodItem>>> search(String query, {int limit = 20}) =>
      _guard(() async {
        final rows = await _firestore.searchFoods(query, limit: limit);
        return rows.map((r) => FoodItemModel.fromMap(r)).toList();
      });

  @override
  Future<Result<List<FoodItem>>> byCategory(String category,
          {int limit = 30}) =>
      _guard(() async {
        final rows = await _firestore.foodsByCategory(category, limit: limit);
        return rows.map((r) => FoodItemModel.fromMap(r)).toList();
      });

  @override
  Future<Result<List<FoodItem>>> favorites(String userId) => _guard(() async {
        final rows = await _firestore.favorites(userId);
        return rows.map((r) => FoodItemModel.fromMap(r)).toList();
      });

  @override
  Future<Result<FoodItem>> saveFavorite(FoodItem item, String userId) =>
      _guard(() async {
        final saved = await _firestore
            .addFavorite(FoodItemModel.toFavoriteMap(item, userId));
        return FoodItemModel.fromMap({...saved, 'created_by': userId});
      });

  @override
  Future<Result<List<FoodItem>>> recentFoods(String userId,
          {int limit = 15}) =>
      _guard(() async {
        final rows = await _firestore.recentMeals(userId);

        // Deduplica por nome e reconstrói os valores por 100g a partir dos
        // totais gravados (mesma lógica do service legado).
        final unique = <FoodItem>[];
        final seenNames = <String>{};
        for (final row in rows) {
          final entry = MealEntryModel.fromMap(row);
          if (entry.foodName.isEmpty || seenNames.contains(entry.foodName)) {
            continue;
          }
          seenNames.add(entry.foodName);
          final per100g = entry.per100g;
          unique.add(FoodItem(
            id: entry.foodItemId ?? entry.id,
            name: entry.foodName,
            brand: row['brand'] as String? ?? '',
            caloriesPer100g: per100g.calories,
            proteinPer100g: per100g.protein,
            carbsPer100g: per100g.carbs,
            fatPer100g: per100g.fat,
            sodiumPer100g: per100g.sodium,
            fiberPer100g: per100g.fiber,
            addedSugarPer100g: per100g.addedSugar,
          ));
          if (unique.length >= limit) break;
        }
        return unique;
      });
}

class NutritionDiaryRepositoryImpl implements NutritionDiaryRepository {
  final FirestoreNutritionDatasource _firestore;

  /// Resolve o usuário logado quando o chamador não informa `userId`
  /// (mesmo comportamento do service legado).
  final String? Function() _currentUserId;

  NutritionDiaryRepositoryImpl(this._firestore, this._currentUserId);

  @override
  Future<Result<void>> addEntry(MealEntry entry) =>
      _guard(() => _firestore.addMeal(MealEntryModel.toMap(entry)));

  @override
  Future<Result<void>> updateEntry({
    required String entryId,
    required MealEntry updated,
  }) =>
      _guard(() => _firestore.updateMeal(
          entryId, MealEntryModel.toQuantityUpdate(updated)));

  @override
  Future<Result<void>> deleteEntry(String entryId) =>
      _guard(() => _firestore.deleteMeal(entryId));

  @override
  Future<Result<List<MealEntry>>> mealsForDate(DateTime date,
          {String? userId}) =>
      _guard(() async {
        final uid = userId ?? _currentUserId();
        if (uid == null) {
          throw const AuthFailure('Usuário não autenticado.');
        }
        final rows = await _firestore.mealsForDate(uid, date);
        return rows.map((r) => MealEntryModel.fromMap(r)).toList();
      });

  @override
  Future<Result<DailyNutritionSummary>> dailySummary(DateTime date,
      {String? userId}) async {
    final meals = await mealsForDate(date, userId: userId);
    return meals.map(
        (entries) => DailyNutritionSummary.fromEntries(date, entries));
  }
}

class NutritionXpRepositoryImpl implements NutritionXpRepository {
  final SupabaseXpDatasource _xp;
  final FirestoreNutritionDatasource _firestore;

  NutritionXpRepositoryImpl(this._xp, this._firestore);

  @override
  Future<Result<void>> awardMealXp(String userId) =>
      _guard(() => _xp.addXp(userId, NutritionXpRepository.mealXp));

  @override
  Future<Result<bool>> awardDailyBonusIfNeeded(
          String userId, DateTime date) =>
      _guard(() async {
        if (await _firestore.dailyBonusExists(userId, date)) return false;
        await _xp.addXp(userId, NutritionXpRepository.dailyBonusXp,
            source: 'daily_completion_bonus');
        await _firestore.markDailyBonusAwarded(userId, date);
        return true;
      });
}

class NutritionGoalsRepositoryImpl implements NutritionGoalsRepository {
  final SupabaseNutritionGoalsDatasource _datasource;

  NutritionGoalsRepositoryImpl(this._datasource);

  @override
  Future<Result<NutritionGoals>> getGoals(String userId) => _guard(() async {
        final onboardingData = await _datasource.getOnboardingData(userId);
        if (onboardingData == null) return NutritionGoals.defaults;
        return NutritionGoals(
          calories: (onboardingData['target_calories'] as num?)?.round() ??
              NutritionGoals.defaults.calories,
          protein: (onboardingData['target_protein'] as num?)?.round() ??
              NutritionGoals.defaults.protein,
          carbs: (onboardingData['target_carbs'] as num?)?.round() ??
              NutritionGoals.defaults.carbs,
          fat: (onboardingData['target_fat'] as num?)?.round() ??
              NutritionGoals.defaults.fat,
        );
      });

  @override
  Future<Result<UserGoals>> getFullGoals(String userId) => _guard(() async {
        final d = await _datasource.getFullGoals(userId);
        return UserGoals(
          calories: (d['target_calories'] as num?)?.round() ?? UserGoals.defaults.calories,
          protein: (d['target_protein'] as num?)?.round() ?? UserGoals.defaults.protein,
          carbs: (d['target_carbs'] as num?)?.round() ?? UserGoals.defaults.carbs,
          fat: (d['target_fat'] as num?)?.round() ?? UserGoals.defaults.fat,
          targetWeightKg: (d['target_weight_kg'] as num?)?.toDouble(),
          currentWeightKg: (d['current_weight_kg'] as num?)?.toDouble(),
          goalPace: (d['goal_pace'] as String?) ?? 'Moderado',
          customCalories: (d['custom_calories'] as bool?) ?? false,
        );
      });

  @override
  Future<Result<void>> saveFullGoals(String userId, UserGoals goals) =>
      _guard(() => _datasource.saveFullGoals(userId, {
            'target_calories': goals.calories,
            'target_protein': goals.protein,
            'target_carbs': goals.carbs,
            'target_fat': goals.fat,
            'goal_pace': goals.goalPace,
            'custom_calories': goals.customCalories,
            'target_weight_kg': goals.targetWeightKg,
          }));
}
