import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/onboarding/domain/entities/onboarding_plan.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/resolve_club_access.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/week_override.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';
import 'package:bldr_fitness/features/workouts/domain/repositories/weekly_plan_repository.dart';

/// Plano efetivo da semana: recorrente (`weekly_plan_days`) + ajustes da
/// semana (`weekly_plan_overrides`). Único ponto de leitura do "plano desta
/// semana" (MINHA_SEMANA.md §9). Sem ajustes legíveis, devolve o recorrente.
class GetWeekPlan {
  final WeeklyPlanRepository _repo;
  const GetWeekPlan(this._repo);

  Future<Result<List<PlanDay>>> call(DateTime weekStart) async {
    final recurring = await _repo.getWeeklyPlan();
    final days = recurring.valueOrNull;
    if (days == null) return recurring;
    final overrides = await _repo.getOverrides(weekStart);
    return Result.success(
        WeekPlanMerger.merge(days, overrides.valueOrNull ?? const []));
  }
}

/// Ajuste pedido na tela (só nesta semana).
sealed class WeekAdjustment {
  const WeekAdjustment();
}

/// Arrastar / "Mover para outro dia": treino → descanso move (origem vira
/// descanso); treino → treino troca os dois.
class MoveWorkout extends WeekAdjustment {
  final int fromDay; // 1–7
  final int toDay; // 1–7
  const MoveWorkout(this.fromDay, this.toDay);
}

/// "Transformar em descanso" (o template não é apagado).
class MakeRestDay extends WeekAdjustment {
  final int day;
  const MakeRestDay(this.day);
}

/// "Trocar treino" ou "Adicionar treino" só nesta semana.
class SetDayWorkout extends WeekAdjustment {
  final int day;
  final WorkoutTemplate template;
  const SetDayWorkout(this.day, this.template);
}

/// Ajuste da semana exige BLDR CLUB (a tela abre o paywall).
class ClubRequiredFailure extends ValidationFailure {
  const ClubRequiredFailure()
      : super('Ajustes só desta semana são exclusivos do BLDR CLUB.');
}

/// Resultado de um ajuste aplicado: o que foi gravado e o estado anterior
/// de cada dia afetado (null = sem ajuste antes), para desfazer.
class WeekAdjustmentOutcome {
  final DateTime weekStart;
  final List<WeekOverride> applied;
  final Map<int, WeekOverride?> previous;
  const WeekAdjustmentOutcome({
    required this.weekStart,
    required this.applied,
    required this.previous,
  });
}

/// Aplica um ajuste da semana validando as regras de MINHA_SEMANA.md §4/§7:
/// CLUB, semana editável (atual + até 4 futuras), dias passados e dias com
/// treino concluído/em andamento protegidos, destino válido. Grava tudo em
/// uma operação; em erro nada muda e a tela restaura o estado anterior.
class ApplyWeekAdjustment {
  final WeeklyPlanRepository _repo;
  final ResolveClubAccess _clubAccess;
  const ApplyWeekAdjustment(this._repo, this._clubAccess);

  static const int maxFutureWeeks = 4;

  Future<Result<WeekAdjustmentOutcome>> call({
    required WeekAdjustment adjustment,
    required DateTime weekStart,
    required DateTime today,
    required List<PlanDay> weekPlan,
    Set<int> protectedDays = const {},
  }) async {
    final access = await _clubAccess();
    if (access.valueOrNull != true) {
      return const Result.failure(ClubRequiredFailure());
    }

    final todayDate = DateTime(today.year, today.month, today.day);
    final currentWeek = WeekCalendar.weekStartFor(todayDate);
    final offset = WeekCalendar.weeksBetween(currentWeek, weekStart);
    if (offset < 0 || offset > maxFutureWeeks) {
      return const Result.failure(
          ValidationFailure('Esta semana não pode ser alterada.'));
    }

    final built = buildOverrides(
        adjustment: adjustment, weekStart: weekStart, weekPlan: weekPlan);
    if (built.isFailure) return Result.failure(built.failureOrNull!);
    final applied = built.valueOrNull!;

    for (final o in applied) {
      if (WeekCalendar.dayOf(weekStart, o.diaSemana).isBefore(todayDate)) {
        return const Result.failure(
            ValidationFailure('Dias que já passaram não podem ser alterados.'));
      }
      if (protectedDays.contains(o.diaSemana)) {
        return const Result.failure(ValidationFailure(
            'Dias com treino concluído ou em andamento não podem ser alterados.'));
      }
    }

    final existing = await _repo.getOverrides(weekStart);
    if (existing.isFailure) return Result.failure(existing.failureOrNull!);
    final existingByDay = {
      for (final o in existing.valueOrNull!) o.diaSemana: o,
    };

    final write = await _repo.upsertOverrides(weekStart, applied);
    if (write.isFailure) return Result.failure(write.failureOrNull!);

    return Result.success(WeekAdjustmentOutcome(
      weekStart: weekStart,
      applied: applied,
      previous: {
        for (final o in applied) o.diaSemana: existingByDay[o.diaSemana]
      },
    ));
  }

  /// Ajustes que um pedido gera, sem gravar (a tela usa para a prévia
  /// otimista; [call] usa para gravar). Valida só o destino.
  static Result<List<WeekOverride>> buildOverrides({
    required WeekAdjustment adjustment,
    required DateTime weekStart,
    required List<PlanDay> weekPlan,
  }) {
    final byDay = {for (final d in weekPlan) d.diaSemana: d};
    PlanDay dayOf(int d) => byDay[d] ?? PlanDay(diaSemana: d, tipo: 'descanso');

    final List<WeekOverride> applied;
    switch (adjustment) {
      case MoveWorkout(:final fromDay, :final toDay):
        if (fromDay == toDay || !_valid(fromDay) || !_valid(toDay)) {
          return const Result.failure(
              ValidationFailure('Escolha um dia de destino válido.'));
        }
        final from = dayOf(fromDay);
        final to = dayOf(toDay);
        if (from.isRestDay) {
          return const Result.failure(
              ValidationFailure('Escolha um dia de destino válido.'));
        }
        applied = to.isRestDay
            ? [
                WeekOverride(
                    weekStart: weekStart,
                    diaSemana: toDay,
                    tipo: 'treino',
                    treino: from.treino),
                WeekOverride(
                    weekStart: weekStart, diaSemana: fromDay, tipo: 'descanso'),
              ]
            : [
                WeekOverride(
                    weekStart: weekStart,
                    diaSemana: toDay,
                    tipo: 'treino',
                    treino: from.treino),
                WeekOverride(
                    weekStart: weekStart,
                    diaSemana: fromDay,
                    tipo: 'treino',
                    treino: to.treino),
              ];
      case MakeRestDay(:final day):
        if (!_valid(day) || dayOf(day).isRestDay) {
          return const Result.failure(
              ValidationFailure('Este dia já é de descanso.'));
        }
        applied = [
          WeekOverride(weekStart: weekStart, diaSemana: day, tipo: 'descanso'),
        ];
      case SetDayWorkout(:final day, :final template):
        if (!_valid(day)) {
          return const Result.failure(
              ValidationFailure('Escolha um dia válido.'));
        }
        applied = [
          WeekOverride(
              weekStart: weekStart,
              diaSemana: day,
              tipo: 'treino',
              treino: template),
        ];
    }

    return Result.success(applied);
  }

  static bool _valid(int d) => d >= 1 && d <= 7;
}

/// Desfaz um ajuste: restaura cada dia afetado ao estado anterior (apaga o
/// ajuste quando antes não havia, ou regrava o ajuste anterior).
class UndoWeekAdjustment {
  final WeeklyPlanRepository _repo;
  const UndoWeekAdjustment(this._repo);

  Future<Result<void>> call(WeekAdjustmentOutcome outcome) async {
    final toDelete = [
      for (final e in outcome.previous.entries)
        if (e.value == null) e.key,
    ];
    final toRestore = [
      for (final e in outcome.previous.entries)
        if (e.value != null) e.value!,
    ];
    if (toRestore.isNotEmpty) {
      final r = await _repo.upsertOverrides(outcome.weekStart, toRestore);
      if (r.isFailure) return r;
    }
    if (toDelete.isNotEmpty) {
      return _repo.deleteOverrides(outcome.weekStart, toDelete);
    }
    return const Result.success(null);
  }
}

/// Remove o ajuste de um dia nesta semana (ex.: ao escolher "Todas as
/// semanas", o plano recorrente volta a valer neste dia).
class ClearWeekDayOverride {
  final WeeklyPlanRepository _repo;
  const ClearWeekDayOverride(this._repo);

  Future<Result<void>> call(DateTime weekStart, int day) =>
      _repo.deleteOverrides(weekStart, [day]);
}
