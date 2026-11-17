import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/onboarding/domain/entities/onboarding_plan.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/resolve_club_access.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/plan_day_type_resolver.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/week_override.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';
import 'package:bldr_fitness/features/workouts/domain/repositories/weekly_plan_repository.dart';
import 'package:bldr_fitness/features/workouts/domain/usecases/week_plan_usecases.dart';

/// Repository fake em memória: plano recorrente + ajustes por semana.
class _FakeRepo implements WeeklyPlanRepository {
  List<PlanDay> recurring = [];
  final Map<String, Map<int, WeekOverride>> overrides = {};
  bool failUpsert = false;
  int upsertCalls = 0;

  Map<int, WeekOverride> _week(DateTime ws) =>
      overrides.putIfAbsent(WeekCalendar.toDateString(ws), () => {});

  @override
  Future<Result<List<PlanDay>>> getWeeklyPlan() async =>
      Result.success(recurring);

  @override
  Future<Result<List<WeekOverride>>> getOverrides(DateTime weekStart) async =>
      Result.success(_week(weekStart).values.toList());

  @override
  Future<Result<void>> upsertOverrides(
      DateTime weekStart, List<WeekOverride> list) async {
    upsertCalls++;
    if (failUpsert) {
      return const Result.failure(ServerFailure('Falha ao salvar.'));
    }
    for (final o in list) {
      _week(weekStart)[o.diaSemana] = o;
    }
    return const Result.success(null);
  }

  @override
  Future<Result<void>> deleteOverrides(DateTime weekStart, List<int> dias) async {
    for (final d in dias) {
      _week(weekStart).remove(d);
    }
    return const Result.success(null);
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Access implements ResolveClubAccess {
  bool club;
  _Access(this.club);
  @override
  Future<Result<bool>> call() async => Result.success(club);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

const _push = WorkoutTemplate(id: 'push', name: 'Push A');
const _pull = WorkoutTemplate(id: 'pull', name: 'Pull A');
const _legs = WorkoutTemplate(id: 'legs', name: 'Legs A');

// Semana de 16/11/2026 (segunda). "Hoje" = segunda 16.
final _ws = DateTime(2026, 11, 16);
final _today = DateTime(2026, 11, 16, 9);

/// Seg Push · Ter Pull · Qua descanso · Qui Legs · Sex–Dom descanso.
List<PlanDay> _plan() => const [
      PlanDay(diaSemana: 1, tipo: 'treino', treino: _push),
      PlanDay(diaSemana: 2, tipo: 'treino', treino: _pull),
      PlanDay(diaSemana: 3, tipo: 'descanso'),
      PlanDay(diaSemana: 4, tipo: 'treino', treino: _legs),
      PlanDay(diaSemana: 5, tipo: 'descanso'),
      PlanDay(diaSemana: 6, tipo: 'descanso'),
      PlanDay(diaSemana: 7, tipo: 'descanso'),
    ];

void main() {
  late _FakeRepo repo;
  late _Access access;
  late ApplyWeekAdjustment apply;

  setUp(() {
    repo = _FakeRepo()..recurring = _plan();
    access = _Access(true);
    apply = ApplyWeekAdjustment(repo, access);
  });

  Future<Result<WeekAdjustmentOutcome>> run(WeekAdjustment a,
          {DateTime? weekStart, DateTime? today, Set<int> protectedDays = const {}}) =>
      apply(
        adjustment: a,
        weekStart: weekStart ?? _ws,
        today: today ?? _today,
        weekPlan: _plan(),
        protectedDays: protectedDays,
      );

  Future<List<PlanDay>> effective() async =>
      (await GetWeekPlan(repo)(_ws)).valueOrNull!;

  group('week_start na data local', () {
    test('domingo 23h em São Paulo continua na semana da segunda anterior', () {
      // 2026-11-23T02:00Z = domingo 22/11, 23h em SP (UTC-3).
      final instant = DateTime.utc(2026, 11, 23, 2);
      expect(
          WeekCalendar.weekStartFor(instant,
              utcOffset: const Duration(hours: -3)),
          DateTime(2026, 11, 16));
      // Em UTC já seria a segunda seguinte — não é o que o usuário vê.
      expect(WeekCalendar.weekStartFor(instant, utcOffset: Duration.zero),
          DateTime(2026, 11, 23));
    });

    test('segunda 00h é o início da própria semana', () {
      expect(
          WeekCalendar.weekStartFor(DateTime.utc(2026, 11, 16, 3),
              utcOffset: const Duration(hours: -3)),
          DateTime(2026, 11, 16));
    });

    test('formato date da coluna', () {
      expect(WeekCalendar.toDateString(DateTime(2026, 1, 5)), '2026-01-05');
    });
  });

  group('mesclagem e resolver', () {
    test('ajuste da semana vence o recorrente; resolver respeita a ordem', () {
      final merged = WeekPlanMerger.merge(_plan(), [
        WeekOverride(weekStart: _ws, diaSemana: 1, tipo: 'descanso'),
        WeekOverride(
            weekStart: _ws, diaSemana: 3, tipo: 'treino', treino: _push),
      ]);
      expect(merged[0].isRestDay, isTrue);
      expect(merged[2].treino?.id, 'push');
      final days = PlanDayTypeResolver.trainingDays(
        plan: _plan(),
        restDays: const [],
        frequencyDays: 3,
        overrides: [WeekOverride(weekStart: _ws, diaSemana: 1, tipo: 'descanso')],
      );
      expect(days[0], isFalse);
      expect(days[1], isTrue);
    });

    test('sem ajustes, o resolver é o de sempre', () {
      final a = PlanDayTypeResolver.trainingDays(
          plan: _plan(), restDays: const [], frequencyDays: 3);
      expect(PlanDayTypeResolver.trainingIndices(a), [0, 1, 3]);
    });
  });

  group('arrastar / mover', () {
    test('treino → descanso: move e a origem vira descanso', () async {
      final r = await run(const MoveWorkout(2, 3)); // Ter Pull → Qua
      expect(r.isSuccess, isTrue);
      final plan = await effective();
      expect(plan[1].isRestDay, isTrue);
      expect(plan[2].treino?.id, 'pull');
      // Plano recorrente intacto.
      expect(repo.recurring[1].treino?.id, 'pull');
    });

    test('treino → treino: troca os dois', () async {
      await run(const MoveWorkout(2, 4)); // Pull ↔ Legs
      final plan = await effective();
      expect(plan[1].treino?.id, 'legs');
      expect(plan[3].treino?.id, 'pull');
    });

    test('destino inválido não grava', () async {
      for (final a in const [
        MoveWorkout(2, 2),
        MoveWorkout(2, 8),
        MoveWorkout(3, 5), // origem é descanso
      ]) {
        final r = await run(a);
        expect(r.failureOrNull, isA<ValidationFailure>());
      }
      expect(repo.upsertCalls, 0);
    });
  });

  group('dias protegidos', () {
    test('dia concluído ou em andamento não muda', () async {
      final r = await run(const MoveWorkout(2, 3), protectedDays: {2});
      expect(r.failureOrNull, isA<ValidationFailure>());
      final r2 = await run(const MakeRestDay(4), protectedDays: {4});
      expect(r2.failureOrNull, isA<ValidationFailure>());
      expect(repo.upsertCalls, 0);
    });

    test('dia que já passou não muda', () async {
      // Hoje = quarta 18: segunda e terça passaram.
      final r = await run(const MoveWorkout(2, 3),
          today: DateTime(2026, 11, 18, 10));
      expect(r.failureOrNull, isA<ValidationFailure>());
      final r2 = await run(const MoveWorkout(4, 5),
          today: DateTime(2026, 11, 18, 10));
      expect(r2.isSuccess, isTrue);
    });

    test('semana passada e além de 4 futuras não mudam', () async {
      final past = await run(const MakeRestDay(4),
          weekStart: DateTime(2026, 11, 9));
      expect(past.failureOrNull, isA<ValidationFailure>());
      final far = await run(const MakeRestDay(4),
          weekStart: DateTime(2026, 12, 21)); // +5 semanas
      expect(far.failureOrNull, isA<ValidationFailure>());
      final ok = await run(const MakeRestDay(4),
          weekStart: DateTime(2026, 12, 14)); // +4 semanas
      expect(ok.isSuccess, isTrue);
    });
  });

  group('descanso e trocar/adicionar', () {
    test('transformar em descanso só nesta semana', () async {
      await run(const MakeRestDay(4));
      final plan = await effective();
      expect(plan[3].isRestDay, isTrue);
      expect(repo.recurring[3].isRestDay, isFalse);
    });

    test('trocar / adicionar treino só nesta semana', () async {
      await run(const SetDayWorkout(3, _legs)); // adicionar na quarta
      await run(const SetDayWorkout(1, _pull)); // trocar a segunda
      final plan = await effective();
      expect(plan[2].treino?.id, 'legs');
      expect(plan[0].treino?.id, 'pull');
    });
  });

  group('desfazer e erro', () {
    test('desfazer volta ao estado anterior', () async {
      final r = await run(const MoveWorkout(2, 3));
      await UndoWeekAdjustment(repo)(r.valueOrNull!);
      final plan = await effective();
      expect(plan[1].treino?.id, 'pull');
      expect(plan[2].isRestDay, isTrue);
      expect(repo.overrides[WeekCalendar.toDateString(_ws)], isEmpty);
    });

    test('desfazer regrava um ajuste que já existia', () async {
      await run(const MakeRestDay(4));
      final r = await run(const SetDayWorkout(4, _push));
      await UndoWeekAdjustment(repo)(r.valueOrNull!);
      final plan = await effective();
      expect(plan[3].isRestDay, isTrue);
    });

    test('erro ao salvar: falha e nada muda', () async {
      repo.failUpsert = true;
      final r = await run(const MoveWorkout(2, 3));
      expect(r.failureOrNull, isA<ServerFailure>());
      final plan = await effective();
      expect(plan[1].treino?.id, 'pull');
      expect(plan[2].isRestDay, isTrue);
    });
  });

  group('FREE / CLUB', () {
    test('FREE recebe ClubRequiredFailure e nada é gravado', () async {
      access.club = false;
      final r = await run(const MoveWorkout(2, 3));
      expect(r.failureOrNull, isA<ClubRequiredFailure>());
      expect(repo.upsertCalls, 0);
    });

    test('CLUB grava', () async {
      final r = await run(const MakeRestDay(1));
      expect(r.isSuccess, isTrue);
    });
  });

  test('limpar o ajuste de um dia devolve o recorrente', () async {
    await run(const MakeRestDay(4));
    await ClearWeekDayOverride(repo)(_ws, 4);
    final plan = await effective();
    expect(plan[3].treino?.id, 'legs');
  });
}
