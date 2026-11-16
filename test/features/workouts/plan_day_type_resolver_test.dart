import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/features/onboarding/domain/entities/onboarding_plan.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/plan_day_type_resolver.dart';

PlanDay _d(int dia, String tipo) => PlanDay(diaSemana: dia, tipo: tipo);

void main() {
  group('PlanDayTypeResolver', () {
    test('dados atuais: 7 linhas "treino", freq 6, rest_days vazio → 7 treinos',
        () {
      final r = PlanDayTypeResolver.trainingDays(
        plan: [for (var i = 1; i <= 7; i++) _d(i, 'treino')],
        restDays: const [],
        frequencyDays: 6,
      );
      expect(r, List.filled(7, true));
    });

    test('marcar terça como descanso → só terça é descanso', () {
      final r = PlanDayTypeResolver.trainingDays(
        plan: [for (var i = 1; i <= 7; i++) _d(i, i == 2 ? 'descanso' : 'treino')],
        restDays: const [],
        frequencyDays: 6,
      );
      expect(r, [true, false, true, true, true, true, true]);
    });

    test('a linha do plano vence rest_days e a frequência', () {
      final r = PlanDayTypeResolver.trainingDays(
        plan: [_d(4, 'treino'), _d(1, 'descanso')],
        restDays: const [3], // quinta descanso no onboarding
        frequencyDays: 6,
      );
      expect(r[3], isTrue); // quinta: linha diz treino
      expect(r[0], isFalse); // segunda: linha diz descanso
      expect(r[6], isTrue); // domingo: sem linha → rest_days
    });

    test('sem linhas → rest_days', () {
      final r = PlanDayTypeResolver.trainingDays(
        plan: const [],
        restDays: const [2, 6],
        frequencyDays: 3,
      );
      expect(r, [true, true, false, true, true, true, false]);
    });

    test('sem linhas e rest_days vazio → frequência (6 → quinta descansa)', () {
      final r = PlanDayTypeResolver.trainingDays(
        plan: const [],
        restDays: const [],
        frequencyDays: 6,
      );
      expect(r, [true, true, true, false, true, true, true]);
    });

    test('trainingIndices', () {
      expect(PlanDayTypeResolver.trainingIndices([true, false, true]), [0, 2]);
    });
  });
}
