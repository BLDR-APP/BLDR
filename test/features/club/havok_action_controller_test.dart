import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/features/club/domain/entities/havok_action.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/havok/havok_action_controller.dart';

void main() {
  const controller = HavokActionController();
  const workout = <String, dynamic>{
    'canonical': true,
    'exercicios': [
      {'exercise_id': 'supino-id', 'nome': 'Supino reto', 'series': 3},
    ],
  };

  HavokActionProposal action(String type, Map<String, dynamic> payload) =>
      HavokActionProposal.fromMap({
        'type': type,
        'label': 'Não confiar neste rótulo',
        'payload': payload,
      })!;

  test('expõe apenas ação allowlisted para artifact canônico', () {
    final actions = controller.supportedActions({
      'actions': [
        {'type': 'START_WORKOUT', 'label': 'qualquer', 'payload': {}},
        {'type': 'SAVE_RECIPE', 'label': 'não suportada', 'payload': {}},
      ],
    }, hasCanonicalWorkout: true);

    expect(actions, hasLength(1));
    expect(actions.single.type, 'START_WORKOUT');
    expect(actions.single.label, 'Iniciar treino');
    expect(
        controller.supportedActions({
          'actions': [
            {'type': 'START_WORKOUT', 'label': 'Iniciar', 'payload': {}},
          ],
        }, hasCanonicalWorkout: false),
        isEmpty);
  });

  test('rejeita payload executável e prepara replacement somente canônico', () {
    expect(
        HavokActionProposal.fromMap({
          'type': 'START_WORKOUT',
          'label': 'Iniciar',
          'payload': {'route': '/admin'},
        }),
        isNull);

    final replaced = controller.workoutForAction(
        workout,
        action(
          'REPLACE_EXERCISE',
          {
            'target_exercise_id': 'supino-id',
            'replacement_exercise_id': 'halter-id',
            'replacement_exercise_db_id': 'db-halter',
            'replacement_name': 'Supino com halteres',
          },
        ));
    final exercise = (replaced!['exercicios'] as List).single as Map;
    expect(exercise['exercise_id'], 'halter-id');
    expect(exercise['nome'], 'Supino com halteres');
    expect(exercise['resolution'], 'RESOLVED');
  });

  test('replacement sem IDs canônicos é rejeitado', () {
    expect(
        HavokActionProposal.fromMap({
          'type': 'REPLACE_EXERCISE',
          'label': 'Trocar',
          'payload': {'replacement_name': 'Supino com halteres'},
        }),
        isNull);
    expect(controller.workoutForAction(workout, action('SAVE_WORKOUT', {})),
        same(workout));
  });
}
