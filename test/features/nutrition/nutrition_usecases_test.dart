import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/daily_nutrition_summary.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/food_item.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/macro_nutrients.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/meal_entry.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/nutrition_goals.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/user_goals.dart';
import 'package:bldr_fitness/features/nutrition/domain/repositories/nutrition_diary_repository.dart';
import 'package:bldr_fitness/features/nutrition/domain/repositories/nutrition_goals_repository.dart';
import 'package:bldr_fitness/features/nutrition/domain/repositories/nutrition_xp_repository.dart';
import 'package:bldr_fitness/features/nutrition/domain/usecases/nutrition_usecases.dart';

class FakeDiaryRepository implements NutritionDiaryRepository {
  final List<MealEntry> entries = [];
  final Map<String, MealEntry> updates = {};
  final List<String> deleted = [];
  Failure? nextFailure;

  @override
  Future<Result<void>> addEntry(MealEntry entry) async {
    if (nextFailure != null) return Result.failure(nextFailure!);
    entries.add(entry);
    return const Result.success(null);
  }

  @override
  Future<Result<void>> updateEntry(
      {required String entryId, required MealEntry updated}) async {
    updates[entryId] = updated;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> deleteEntry(String entryId) async {
    deleted.add(entryId);
    return const Result.success(null);
  }

  @override
  Future<Result<List<MealEntry>>> mealsForDate(DateTime date,
          {String? userId}) async =>
      Result.success(List.of(entries));

  @override
  Future<Result<DailyNutritionSummary>> dailySummary(DateTime date,
          {String? userId}) async =>
      Result.success(DailyNutritionSummary.fromEntries(date, entries));
}

class FakeGoalsRepository implements NutritionGoalsRepository {
  final Map<String, NutritionGoals> goalsByUser;
  FakeGoalsRepository(this.goalsByUser);

  @override
  Future<Result<NutritionGoals>> getGoals(String userId) async {
    final goals = goalsByUser[userId];
    if (goals == null) return const Result.success(NutritionGoals.defaults);
    return Result.success(goals);
  }

  @override
  Future<Result<UserGoals>> getFullGoals(String userId) async =>
      const Result.success(UserGoals.defaults);

  @override
  Future<Result<void>> saveFullGoals(String userId, UserGoals goals) async =>
      const Result.success(null);
}

class FakeXpRepository implements NutritionXpRepository {
  int mealXpAwards = 0;
  int bonusAwards = 0;
  bool bonusAlreadyAwarded = false;

  @override
  Future<Result<void>> awardMealXp(String userId) async {
    mealXpAwards++;
    return const Result.success(null);
  }

  @override
  Future<Result<bool>> awardDailyBonusIfNeeded(
      String userId, DateTime date) async {
    if (bonusAlreadyAwarded) return const Result.success(false);
    bonusAwards++;
    bonusAlreadyAwarded = true;
    return const Result.success(true);
  }
}

MealEntry entryOf(String mealType, {double calories = 100}) => MealEntry(
      userId: 'u1',
      mealType: mealType,
      date: DateTime(2026, 7, 30),
      foodName: 'Arroz',
      quantityGrams: 100,
      macros: MacroNutrients(calories: calories, protein: 10, carbs: 20, fat: 5),
    );

void main() {
  final date = DateTime(2026, 7, 30);
  const food = FoodItem(
    id: 'f1',
    name: 'FRANGO GRELHADO',
    caloriesPer100g: 165,
    proteinPer100g: 31,
    carbsPer100g: 0,
    fatPer100g: 3.6,
  );

  late FakeDiaryRepository diary;
  late FakeXpRepository xp;
  late LogMeal logMeal;

  setUp(() {
    diary = FakeDiaryRepository();
    xp = FakeXpRepository();
    logMeal = LogMeal(diary, xp);
  });

  group('MacroNutrients', () {
    test('regra de 3 a partir de 100g', () {
      final m = food.macrosFor(200);
      expect(m.calories, 330);
      expect(m.protein, 62);
      expect(m.fat, closeTo(7.2, 0.001));
    });

    test('quantidade zero ou negativa retorna zero', () {
      expect(food.macrosFor(0).calories, 0);
      expect(food.macrosFor(-10).calories, 0);
    });
  });

  group('LogMeal', () {
    test('grava a refeição com macros arredondados e concede 80 XP', () async {
      final result = await logMeal(
        userId: 'u1',
        mealType: 'Lunch',
        mealDate: date,
        food: food,
        quantityGrams: 150,
      );

      expect(result.isSuccess, isTrue);
      expect(diary.entries, hasLength(1));
      final entry = diary.entries.first;
      expect(entry.foodName, 'FRANGO GRELHADO');
      expect(entry.macros.calories, 248); // 165 * 1.5 = 247.5 → 248
      expect(xp.mealXpAwards, 1);
      expect(xp.bonusAwards, 0, reason: 'dia incompleto: sem bônus');
    });

    test('concede bônus de 150 XP quando as 4 refeições ficam completas',
        () async {
      diary.entries.addAll([
        entryOf('Breakfast'),
        entryOf('Lunch'),
        entryOf('Dinner'),
      ]);

      final result = await logMeal(
        userId: 'u1',
        mealType: 'Snack',
        mealDate: date,
        food: food,
        quantityGrams: 100,
      );

      expect(result.isSuccess, isTrue);
      expect(xp.bonusAwards, 1);
    });

    test('não paga o bônus duas vezes no mesmo dia', () async {
      diary.entries.addAll(
          [entryOf('Breakfast'), entryOf('Lunch'), entryOf('Dinner')]);
      xp.bonusAlreadyAwarded = true;

      await logMeal(
        userId: 'u1',
        mealType: 'Snack',
        mealDate: date,
        food: food,
        quantityGrams: 100,
      );

      expect(xp.bonusAwards, 0);
    });

    test('falha ao gravar não concede XP', () async {
      diary.nextFailure = const ServerFailure('sem conexão com Firestore');

      final result = await logMeal(
        userId: 'u1',
        mealType: 'Lunch',
        mealDate: date,
        food: food,
        quantityGrams: 100,
      );

      expect(result.isFailure, isTrue);
      expect(xp.mealXpAwards, 0);
      expect(xp.bonusAwards, 0);
    });
  });

  group('UpdateMealQuantity', () {
    test('recalcula macros proporcionalmente à nova quantidade', () async {
      final existing = MealEntry(
        id: 'log1',
        userId: 'u1',
        mealType: 'Lunch',
        date: date,
        foodName: 'Arroz',
        quantityGrams: 100,
        macros: const MacroNutrients(
            calories: 130, protein: 2.5, carbs: 28, fat: 0.3),
      );

      final result = await UpdateMealQuantity(diary)(
          entry: existing, newQuantityGrams: 200);

      expect(result.isSuccess, isTrue);
      final updated = diary.updates['log1']!;
      expect(updated.quantityGrams, 200);
      expect(updated.macros.calories, 260);
      expect(updated.macros.protein, 5);
    });

    test('registro sem id retorna ValidationFailure', () async {
      final result = await UpdateMealQuantity(diary)(
          entry: entryOf('Lunch'), newQuantityGrams: 50);

      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('DailyNutritionSummary', () {
    test('soma os macros de todas as refeições', () {
      final summary = DailyNutritionSummary.fromEntries(date, [
        entryOf('Breakfast', calories: 300),
        entryOf('Lunch', calories: 700),
      ]);

      expect(summary.totals.calories, 1000);
      expect(summary.totals.protein, 20);
      expect(summary.mealsCount, 2);
    });
  });

  group('GetNutritionGoals (bug B4 — metas divergentes)', () {
    test('retorna a meta real do usuário, não o default 2000/120/250/67', () async {
      final repo = FakeGoalsRepository({
        'user-teste': const NutritionGoals(
            calories: 3543, protein: 140, carbs: 620, fat: 56),
      });

      final result = await GetNutritionGoals(repo)('user-teste');

      final goals = result.valueOrNull;
      expect(goals, isNotNull);
      expect(goals!.calories, 3543);
      expect(goals.protein, 140);
      expect(goals.carbs, 620);
      expect(goals.fat, 56);
      // Antes da correção, o Dashboard usava um valor hardcoded que
      // divergia da meta real do usuário — este teste falharia se
      // qualquer tela voltasse a usar 2000/120/250/67 em vez do use case.
      expect(goals.calories, isNot(NutritionGoals.defaults.calories));
    });

    test('usa o default apenas quando o usuário não tem meta cadastrada',
        () async {
      final repo = FakeGoalsRepository({});

      final result = await GetNutritionGoals(repo)('user-sem-onboarding');

      final goals = result.valueOrNull;
      expect(goals!.calories, NutritionGoals.defaults.calories);
      expect(goals.protein, NutritionGoals.defaults.protein);
    });
  });

  group('per100g (engenharia reversa)', () {
    test('reconstrói valores por 100g a partir dos totais', () {
      final entry = MealEntry(
        userId: 'u1',
        mealType: 'Lunch',
        date: date,
        foodName: 'Arroz',
        quantityGrams: 250,
        macros: const MacroNutrients(calories: 325, protein: 6.25),
      );

      expect(entry.per100g.calories, 130);
      expect(entry.per100g.protein, 2.5);
    });

    test('quantidade zero usa 100g como base segura', () {
      final entry = MealEntry(
        userId: 'u1',
        mealType: 'Lunch',
        date: date,
        foodName: 'Arroz',
        quantityGrams: 0,
        macros: const MacroNutrients(calories: 130),
      );

      expect(entry.per100g.calories, 130);
    });
  });
}
