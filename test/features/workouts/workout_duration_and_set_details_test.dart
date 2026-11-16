import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/features/workouts/data/models/workout_models.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_duration_estimator.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';

TemplateExercise _ex(int sets, {int? reps = 10, int rest = 60, int? dur}) =>
    TemplateExercise(
      orderIndex: 0,
      sets: sets,
      reps: reps,
      restSeconds: rest,
      durationSeconds: dur,
    );

void main() {
  group('WorkoutDurationEstimator (P1)', () {
    test('exemplo do TREINOS_V2: 3 exercícios, 12 séries de 10, 60 s', () {
      // 12×30 s + 11×60 s de descanso + 2×60 s de transição = 1140 s → 19 min
      final m = WorkoutDurationEstimator.estimateTemplate(
          [_ex(4), _ex(4), _ex(4)]);
      expect(m, 19);
    });

    test('série com poucas reps respeita o mínimo de 20 s', () {
      expect(WorkoutDurationEstimator.setWorkSeconds(reps: 3), 20);
    });

    test('exercício por tempo usa a duração da série', () {
      expect(WorkoutDurationEstimator.setWorkSeconds(durationSeconds: 45), 45);
    });

    test('sem reps nem duração usa 40 s', () {
      expect(WorkoutDurationEstimator.setWorkSeconds(), 40);
    });

    test('não conta descanso após a última série do treino', () {
      // 1 série de 10 reps (30 s) com 600 s de descanso → só 30 s → 1 min
      expect(WorkoutDurationEstimator.estimateTemplate([_ex(1, rest: 600)]), 1);
    });

    test('usa os descansos por série quando existirem', () {
      const ex = TemplateExercise(orderIndex: 0, sets: 2, setDetails: [
        TemplateSetDetail(reps: 10, restSeconds: 120),
        TemplateSetDetail(reps: 10, restSeconds: 999),
      ]);
      // 30 + 120 + 30 = 180 s → 3 min
      expect(WorkoutDurationEstimator.estimateTemplate([ex]), 3);
    });

    test('treino vazio → 0', () {
      expect(WorkoutDurationEstimator.estimateTemplate(const []), 0);
    });
  });

  group('TemplateSetDetail (P2)', () {
    test('sem lista por série, replica os valores agregados', () {
      final sets = _ex(3, reps: 8, rest: 90).resolvedSets;
      expect(sets.length, 3);
      expect(sets.every((s) => s.reps == 8 && s.restSeconds == 90), isTrue);
    });

    test('com lista por série, ela prevalece', () {
      const ex = TemplateExercise(orderIndex: 0, sets: 3, setDetails: [
        TemplateSetDetail(weightKg: 20, reps: 12, restSeconds: 60),
        TemplateSetDetail(weightKg: 17.5, reps: 10, restSeconds: 90),
      ]);
      expect(ex.resolvedSets.map((s) => s.weightKg), [20, 17.5]);
    });

    test('ida e volta pelo model: o que foi digitado por série não se perde',
        () {
      const ex = TemplateExercise(orderIndex: 1, sets: 2, setDetails: [
        TemplateSetDetail(weightKg: 20, reps: 12, restSeconds: 60),
        TemplateSetDetail(weightKg: 17.5, reps: 10, restSeconds: 90),
      ]);
      final map = WorkoutModels.templateExerciseToServiceMap(ex);
      final back = WorkoutModels.templateExerciseFromMap(map);
      expect(back.setDetails.map((d) => d.toJson()).toList(),
          ex.setDetails.map((d) => d.toJson()).toList());
    });

    test('template antigo (sem set_details) não grava a chave', () {
      final map = WorkoutModels.templateExerciseToServiceMap(_ex(3));
      expect(map.containsKey('set_details'), isFalse);
      expect(WorkoutModels.templateExerciseFromMap(map).setDetails, isEmpty);
    });

    test('set_details inválido é ignorado', () {
      expect(TemplateSetDetail.listFromJson('x'), isEmpty);
      expect(TemplateSetDetail.listFromJson(null), isEmpty);
    });
  });
}
