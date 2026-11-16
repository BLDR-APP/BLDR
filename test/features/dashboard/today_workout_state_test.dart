import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/features/workouts/domain/entities/exercise.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/home_v2_formatters.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/today_workout_state.dart';

TodayWorkoutState _r({
  bool unfinished = false,
  bool done = false,
  bool template = false,
  bool rest = false,
}) =>
    resolveTodayWorkoutState(
      hasUnfinishedWorkout: unfinished,
      completedToday: done,
      hasTodayTemplate: template,
      todayIsRestDay: rest,
    );

void main() {
  group('resolveTodayWorkoutState', () {
    test('treino não concluído tem prioridade sobre tudo', () {
      expect(_r(unfinished: true, done: true, template: true, rest: true),
          TodayWorkoutState.inProgress);
    });
    test('concluído hoje vem antes do plano', () {
      expect(_r(done: true, template: true), TodayWorkoutState.done);
    });
    test('template no plano de hoje → planejado', () {
      expect(_r(template: true), TodayWorkoutState.planned);
    });
    test('PlanDay.isRestDay → descanso', () {
      expect(_r(rest: true), TodayWorkoutState.rest);
    });
    test('sem plano nem descanso → sem plano', () {
      expect(_r(), TodayWorkoutState.noPlan);
    });
  });

  group('formatação dos estados', () {
    test('elapsed', () {
      final s = DateTime(2026, 11, 16, 10);
      expect(HomeV2Format.elapsed(s, DateTime(2026, 11, 16, 10, 32)), '32 min');
      expect(HomeV2Format.elapsed(s, DateTime(2026, 11, 16, 11, 5)), '1h 05min');
    });
    test('doneDuration', () {
      expect(HomeV2Format.doneDuration(45 * 60), '45min');
      expect(HomeV2Format.doneDuration(65 * 60), '1h 05min');
    });
    test('volume', () {
      expect(HomeV2Format.volume(100), '100kg');
      expect(HomeV2Format.volume(1250), '1.3t');
      expect(HomeV2Format.volume(0), '—');
    });
    test('muscleGroupsFromSession pela ordem das séries, sem repetir', () {
      WorkoutSet set(int n, String m) => WorkoutSet(
            userWorkoutId: 'w',
            setNumber: n,
            exercise: Exercise(name: 'e$n', primaryMuscleGroup: m),
          );
      final session = WorkoutSession(
        name: 'Push A',
        sets: [set(1, 'Peito'), set(2, 'Peito'), set(3, 'Ombros')],
      );
      expect(HomeV2Format.muscleGroupsFromSession(session), 'Peito · Ombros');
    });
  });
}
