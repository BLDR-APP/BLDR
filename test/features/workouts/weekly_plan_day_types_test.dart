import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/onboarding/domain/entities/onboarding_plan.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/today_workout_resolver.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';
import 'package:bldr_fitness/features/workouts/domain/repositories/weekly_plan_repository.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart';

class _Fake implements WeeklyPlanRepository {
  List<int>? savedRestDays;
  List<bool>? savedTypes;
  bool failConfig = false;

  @override
  Future<Result<void>> savePlanConfig({
    required String splitPreference,
    required List<int> restDays,
  }) async {
    if (failConfig) return const Result.failure(ServerFailure('x'));
    savedRestDays = restDays;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> saveDayTypes(List<bool> trainingDays) async {
    savedTypes = trainingDays;
    return const Result.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  group('SaveWeeklyPlanConfig grava rest_days e o tipo dos 7 dias', () {
    test('descanso nos restDays, treino nos demais', () async {
      final repo = _Fake();
      final r = await SaveWeeklyPlanConfig(repo)(
          splitPreference: 'Push/Pull/Legs', restDays: const [1, 6]);
      expect(r.isSuccess, isTrue);
      expect(repo.savedRestDays, [1, 6]);
      expect(repo.savedTypes, [true, false, true, true, true, true, false]);
    });

    test('falha ao gravar a config não grava os tipos', () async {
      final repo = _Fake()..failConfig = true;
      final r = await SaveWeeklyPlanConfig(repo)(
          splitPreference: 'x', restDays: const [3]);
      expect(r.isFailure, isTrue);
      expect(repo.savedTypes, isNull);
    });
  });

  test('descanso com template guardado não é treino do dia', () {
    const tpl = WorkoutTemplate(id: 't1', name: 'Push A');
    final r = TodayWorkoutResolver.resolve(
      plan: const [PlanDay(diaSemana: 2, tipo: 'descanso', treino: tpl)],
      templates: const [tpl],
      weekday: 2,
    );
    expect(r, isNull);
  });

  test('voltando a treino, o template guardado reaparece', () {
    const tpl = WorkoutTemplate(id: 't1', name: 'Push A');
    final r = TodayWorkoutResolver.resolve(
      plan: const [PlanDay(diaSemana: 2, tipo: 'treino', treino: tpl)],
      templates: const [tpl],
      weekday: 2,
    );
    expect(r?.id, 't1');
  });
}
