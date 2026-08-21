import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:bldr_fitness/features/onboarding/domain/usecases/onboarding_usecases.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';
import 'package:bldr_fitness/features/workouts/domain/repositories/workout_template_repository.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart';

class FakeOnboardingRepository implements OnboardingRepository {
  Result<Map<String, dynamic>>? generatePlanResult;
  Map<String, dynamic>? savedGoals;

  @override
  Future<Result<Map<String, dynamic>>> generatePlan(
          Map<String, dynamic> onboardingData) async =>
      generatePlanResult ?? const Result.success({});

  @override
  Future<Result<Map<String, dynamic>>> getOnboardingData() async =>
      const Result.success({});

  @override
  Future<Result<void>> saveNutritionGoals({
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
  }) async {
    savedGoals = {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
    return const Result.success(null);
  }
}

class FakeWorkoutTemplateRepository implements WorkoutTemplateRepository {
  int createCallCount = 0;
  final List<WorkoutTemplate> created = [];

  @override
  Future<Result<WorkoutTemplate>> create(WorkoutTemplate template) async {
    createCallCount++;
    final withId = WorkoutTemplate(
      id: 't$createCallCount',
      name: template.name,
      workoutType: template.workoutType,
      estimatedDurationMinutes: template.estimatedDurationMinutes,
      exercises: template.exercises,
    );
    created.add(withId);
    return Result.success(withId);
  }

  @override
  Future<Result<List<WorkoutTemplate>>> templates(
          {String? workoutType, int? difficultyLevel, bool publicOnly = false}) =>
      throw UnimplementedError();
  @override
  Future<Result<WorkoutTemplate?>> templateWithExercises(String templateId) =>
      throw UnimplementedError();
  @override
  Future<Result<WorkoutTemplate>> update(WorkoutTemplate template) =>
      throw UnimplementedError();
  @override
  Future<Result<void>> delete(String templateId) => throw UnimplementedError();
}

void main() {
  group('GenerateOnboardingPlan (L4 — HAVOK_SPEC.md §7.1)', () {
    late FakeOnboardingRepository repo;
    late FakeWorkoutTemplateRepository templateRepo;

    setUp(() {
      repo = FakeOnboardingRepository();
      templateRepo = FakeWorkoutTemplateRepository();
    });

    test('cria um WorkoutTemplate por dia com treino, com exercícios de nome livre',
        () async {
      repo.generatePlanResult = const Result.success({
        'plano': [
          {
            'diaSemana': 1,
            'tipo': 'treino',
            'treino': {
              'nome': 'Push A',
              'duracaoEstimada': 45,
              'exercicios': [
                {'nome': 'Supino reto', 'series': 4, 'repeticoes': 10, 'descanso': 60},
              ],
            },
          },
          {'diaSemana': 2, 'tipo': 'descanso', 'treino': null},
        ],
        'resumo': 'Push·Pull 2x/semana',
        'metaCalorica': 2200,
        'metaProteina': 150,
        'metaCarboidrato': 220,
        'metaGordura': 70,
      });

      final result = await GenerateOnboardingPlan(
          repo, CreateWorkoutTemplate(templateRepo))({'main_goal': 'Ganhar massa'});

      final plan = result.valueOrNull;
      expect(plan, isNotNull);
      expect(plan!.plano, hasLength(2));
      expect(plan.plano[0].tipo, 'treino');
      expect(plan.plano[0].treino?.name, 'Push A');
      expect(plan.plano[0].treino?.exercises.single.freeName, 'Supino reto');
      expect(plan.plano[0].treino?.exercises.single.exercise, isNull);
      expect(plan.plano[1].tipo, 'descanso');
      expect(plan.plano[1].treino, isNull);
      expect(templateRepo.createCallCount, 1);
      expect(plan.resumo, 'Push·Pull 2x/semana');
    });

    test('salva as metas nutricionais na mesma fonte que a Nutrição lê', () async {
      repo.generatePlanResult = const Result.success({
        'plano': <Map<String, dynamic>>[],
        'resumo': 'Full body',
        'metaCalorica': 1900,
        'metaProteina': 130,
        'metaCarboidrato': 190,
        'metaGordura': 60,
      });

      await GenerateOnboardingPlan(repo, CreateWorkoutTemplate(templateRepo))({});

      expect(repo.savedGoals, {
        'calories': 1900,
        'protein': 130,
        'carbs': 190,
        'fat': 60,
      });
    });

    test('propaga a falha da edge function sem alterá-la (fallback do L4 decide na UI)',
        () async {
      const failure = ServerFailure('Falha na função gerar-plano-havok.');
      repo.generatePlanResult = const Result.failure(failure);

      final result = await GenerateOnboardingPlan(
          repo, CreateWorkoutTemplate(templateRepo))({});

      expect(result.failureOrNull, failure);
      expect(templateRepo.createCallCount, 0);
      expect(repo.savedGoals, isNull);
    });
  });
}
