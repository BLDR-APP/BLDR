import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/onboarding/domain/entities/onboarding_plan.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/weekly_plan.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/today_workout_resolver.dart';
import 'package:bldr_fitness/features/workouts/domain/repositories/weekly_plan_repository.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart';

// ── Fake repository ───────────────────────────────────────────────────────────

class _FakeWeeklyPlanRepository implements WeeklyPlanRepository {
  final List<PlanDay> _stored = [];

  @override
  Future<Result<void>> saveWeeklyPlan(List<PlanDay> days) async {
    _stored.clear();
    _stored.addAll(days);
    return const Result.success(null);
  }

  @override
  Future<Result<List<PlanDay>>> getWeeklyPlan() async {
    final sorted = [..._stored]
      ..sort((a, b) => a.diaSemana.compareTo(b.diaSemana));
    return Result.success(sorted);
  }

  // ── Métodos não testados aqui — implementação mínima ─────────────────────

  @override
  Future<Result<WeeklyPlanConfig>> planConfig() async =>
      Result.success(WeeklyPlanConfig(splitPreference: '', restDays: const []));

  @override
  Future<Result<void>> savePlanConfig({
    required String splitPreference,
    required List<int> restDays,
  }) async =>
      const Result.success(null);

  @override
  Future<Result<WeekCompletedWorkouts>> completedBetween(
          DateTime a, DateTime b) async =>
      Result.success(WeekCompletedWorkouts(personal: const [], club: const []));

  @override
  Future<Result<List<String>>> musclesForWorkout(String workoutId) async =>
      const Result.success([]);

  @override
  Future<Result<void>> deleteCompletedClub(String id) async =>
      const Result.success(null);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

PlanDay _treino(int dia, String templateId, String nome) => PlanDay(
      diaSemana: dia,
      tipo: 'treino',
      treino: WorkoutTemplate(id: templateId, name: nome, isPublic: false),
    );

PlanDay _descanso(int dia) =>
    const PlanDay(diaSemana: 0, tipo: 'descanso').copyWith(diaSemana: dia);

// ── Testes ────────────────────────────────────────────────────────────────────

void main() {
  late _FakeWeeklyPlanRepository repo;
  late SaveWeeklyPlan saveUC;
  late GetWeeklyPlan getUC;

  setUp(() {
    repo = _FakeWeeklyPlanRepository();
    saveUC = SaveWeeklyPlan(repo);
    getUC = GetWeeklyPlan(repo);
  });

  group('B8 — WeeklyPlan no Supabase', () {
    test('SaveWeeklyPlan salva 7 dias e GetWeeklyPlan retorna os mesmos',
        () async {
      final days = [
        _treino(1, 'id-a', 'Peito'),
        _descanso(2),
        _treino(3, 'id-b', 'Costas'),
        _descanso(4),
        _treino(5, 'id-c', 'Pernas'),
        _descanso(6),
        _descanso(7),
      ];

      final saveResult = await saveUC(days);
      expect(saveResult.isSuccess, isTrue);

      final getResult = await getUC();
      expect(getResult.isSuccess, isTrue);
      final loaded = getResult.valueOrNull!;
      expect(loaded.length, 7);
      expect(loaded.map((d) => d.diaSemana).toList(), [1, 2, 3, 4, 5, 6, 7]);
      expect(loaded.first.treino?.id, 'id-a');
      expect(loaded.first.treino?.name, 'Peito');
    });

    test('Dia de descanso tem templateId=null e tipo=descanso', () async {
      await saveUC([_descanso(7)]);
      final result = await getUC();
      final day = result.valueOrNull!.first;
      expect(day.tipo, 'descanso');
      expect(day.treino, isNull);
    });

    test('GetWeeklyPlan retorna lista vazia quando nenhum plano foi salvo',
        () async {
      final result = await getUC();
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('Salvar novamente substitui o plano anterior inteiro', () async {
      await saveUC([_treino(1, 'old-id', 'Antigo')]);
      await saveUC([_treino(1, 'new-id', 'Novo'), _descanso(2)]);
      final result = await getUC();
      final days = result.valueOrNull!;
      expect(days.length, 2);
      expect(days.first.treino?.id, 'new-id');
    });
  });

  group('Workout Home — treino de hoje', () {
    const push = WorkoutTemplate(id: 'push-id', name: 'Push');
    const teste = WorkoutTemplate(id: 'teste-id', name: 'Teste');

    test('alteração no Meu Plano troca imediatamente o template do Hero', () {
      final before = TodayWorkoutResolver.resolve(
        plan: [_treino(1, 'push-id', 'Push')],
        templates: const [push, teste],
        weekday: 1,
      );
      final after = TodayWorkoutResolver.resolve(
        plan: [_treino(1, 'teste-id', 'Teste')],
        templates: const [push, teste],
        weekday: 1,
      );
      expect(before?.id, 'push-id');
      expect(after?.id, 'teste-id');
      expect(after?.name, 'Teste');
    });

    test('não usa primeiro template ou nome do split como fallback', () {
      final selected = TodayWorkoutResolver.resolve(
        plan: [_treino(1, 'missing-id', 'Push')],
        templates: const [teste, push],
        weekday: 1,
      );
      expect(selected, isNull);
    });

    test('recupera sessão concluída hoje para manter o Hero visível', () {
      final selected = TodayWorkoutResolver.completedOnDate(
        sessions: [
          WorkoutSession(
            id: 'today',
            name: 'Pernas',
            templateId: 'pernas-id',
            completedAt: DateTime(2026, 8, 30, 10),
            isCompleted: true,
          ),
          WorkoutSession(
            id: 'yesterday',
            name: 'Push',
            templateId: 'push-id',
            completedAt: DateTime(2026, 8, 29, 10),
            isCompleted: true,
          ),
        ],
        date: DateTime(2026, 8, 30, 18),
      );

      expect(selected?.id, 'today');
      expect(selected?.templateId, 'pernas-id');
    });
  });
}

// ── Extensão auxiliar para criar PlanDay com copyWith (não existe no domínio) ─

extension _PlanDayX on PlanDay {
  PlanDay copyWith({int? diaSemana, String? tipo, WorkoutTemplate? treino}) =>
      PlanDay(
        diaSemana: diaSemana ?? this.diaSemana,
        tipo: tipo ?? this.tipo,
        treino: treino ?? this.treino,
      );
}
