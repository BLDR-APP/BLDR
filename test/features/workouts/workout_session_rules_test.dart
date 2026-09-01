import 'dart:async';

import 'package:bldr_fitness/core/async_latest_wins_queue.dart';
import 'package:bldr_fitness/core/workout_start_guard.dart';
import 'package:bldr_fitness/features/workouts/domain/active_workout_name.dart';
import 'package:bldr_fitness/features/integrations/data/live_activity_service.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/workout_session_logic.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> exercise(List<Map<String, dynamic>> sets) => {
      'sets': sets,
      'totalSets': sets.length,
    };

Map<String, dynamic> set(
  int number, {
  bool completed = false,
  double weight = 0,
  int reps = 10,
}) =>
    {
      'id': 'set-$number',
      'set_number': number,
      'completed_at': completed ? '2026-09-01T00:00:00Z' : null,
      'is_completed': completed,
      'weight_kg': weight,
      'reps': reps,
    };

void main() {
  test('FREE retoma no primeiro set pendente com carga e reps próprias', () {
    final result = findWorkoutResumePosition([
      exercise([
        set(1, completed: true),
        set(2, completed: true),
        set(3, weight: 42.5, reps: 8),
      ]),
    ]);
    expect(result.exerciseIndex, 0);
    expect(result.hasPendingSet, isTrue);
    expect(result.setNumber, 3);
    expect(result.weightKg, 42.5);
    expect(result.reps, 8);
  });

  test('FREE retoma no exercício seguinte quando o anterior terminou', () {
    final result = findWorkoutResumePosition([
      exercise([set(1, completed: true), set(2, completed: true)]),
      exercise([set(1, completed: false, weight: 20, reps: 12)]),
    ]);
    expect(result.exerciseIndex, 1);
    expect(result.setNumber, 1);
    expect(result.hasPendingSet, isTrue);
  });

  test('FREE todos os sets concluídos não seleciona set já concluído', () {
    final result = findWorkoutResumePosition([
      exercise([set(1, completed: true), set(2, completed: true)]),
      exercise([set(1, completed: true)]),
    ]);
    expect(result.hasPendingSet, isFalse);
  });

  test('CLUB todos os sets concluídos não volta para exercício 1/set 1', () {
    final result = findWorkoutResumePosition([
      exercise([set(1, completed: true)]),
      exercise([set(1, completed: true), set(2, completed: true)]),
    ]);
    expect(result.hasPendingSet, isFalse);
  });

  test('último set do último exercício concluído não vira posição retomável', () {
    final result = findWorkoutResumePosition([
      exercise([set(1, completed: true)]),
      exercise([set(1, completed: true, weight: 80, reps: 6)]),
    ]);
    expect(result.hasPendingSet, isFalse);
  });

  test('guard bloqueia botão e Watch para o mesmo set até release', () {
    final guard = WorkoutSetConfirmationGuard();
    expect(guard.tryAcquire('set-1'), isTrue);
    expect(guard.tryAcquire('set-1'), isFalse);
    guard.release('set-1');
    expect(guard.tryAcquire('set-1'), isTrue);
  });

  test('guard CLUB é liberado após exception pós-persistência', () async {
    final guard = WorkoutSetConfirmationGuard();
    const setId = 'club-set-1';
    expect(guard.tryAcquire(setId), isTrue);
    try {
      throw StateError('falha após persistir');
    } catch (_) {
      // O fluxo da tela preserva a persistência, mas sempre libera no finally.
    } finally {
      guard.release(setId);
    }
    expect(guard.tryAcquire(setId), isTrue);
  });

  test('guard global impede dois starts FREE/CLUB concorrentes', () {
    expect(WorkoutStartGuard.tryAcquire(), isTrue);
    expect(WorkoutStartGuard.tryAcquire(), isFalse);
    WorkoutStartGuard.release();
    expect(WorkoutStartGuard.tryAcquire(), isTrue);
    WorkoutStartGuard.release();
  });

  test('fila async preserva running e aplica somente o snapshot mais novo',
      () async {
    final gate = Completer<void>();
    final applied = <int>[];
    final dropped = <int>[];
    final queue = AsyncLatestWinsQueue<int>(
      handler: (value) async {
        if (value == 1) await gate.future;
        applied.add(value);
      },
      onDropped: dropped.add,
    );
    final first = queue.submit(1);
    final second = queue.submit(2);
    final third = queue.submit(3);
    gate.complete();
    await Future.wait([first, second, third]);
    expect(applied, [1, 3]);
    expect(dropped, [2]);
  });

  test('nome atual do template vence snapshot FREE', () {
    expect(
      resolveActiveWorkoutName(
        templateName: 'Novo',
        snapshotName: 'Antigo',
      ),
      'Novo',
    );
  });

  test('nome atual do template vence snapshot CLUB', () {
    expect(
      resolveActiveWorkoutName(
        templateName: 'Novo Club',
        snapshotName: 'Antigo',
      ),
      'Novo Club',
    );
  });

  test('snapshot é fallback quando template não existe', () {
    expect(
      resolveActiveWorkoutName(
        templateName: null,
        snapshotName: 'Snapshot',
      ),
      'Snapshot',
    );
  });

  test('ação nativa de outra Activity não é aplicada', () {
    const action = NativeRestAction(
      action: 'skip',
      endTimestamp: 0,
      totalSeconds: 0,
      activityId: 'activity-a',
      actionId: 'action-a',
    );
    expect(
      isNativeRestActionForCurrentActivity(
        action: action,
        activityId: 'activity-b',
        lastActionId: null,
      ),
      isFalse,
    );
  });

  test('ação nativa válida é aceita no máximo uma vez', () {
    const action = NativeRestAction(
      action: 'add',
      endTimestamp: 10,
      totalSeconds: 15,
      activityId: 'activity-a',
      actionId: 'action-a',
    );
    expect(
      isNativeRestActionForCurrentActivity(
        action: action,
        activityId: 'activity-a',
        lastActionId: null,
      ),
      isTrue,
    );
    expect(
      isNativeRestActionForCurrentActivity(
        action: action,
        activityId: 'activity-a',
        lastActionId: 'action-a',
      ),
      isFalse,
    );
  });
}
