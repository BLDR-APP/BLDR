import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/features/workouts/data/models/workout_models.dart';

void main() {
  group('WorkoutModels.templateFromMap', () {
    test('parseia template com exercícios aninhados (formato Supabase)', () {
      final template = WorkoutModels.templateFromMap({
        'id': 't1',
        'name': 'Peito e Tríceps',
        'workout_type': 'strength',
        'estimated_duration_minutes': 45,
        'difficulty_level': 3,
        'is_public': true,
        'created_at': '2026-07-30T10:00:00Z',
        'user_profiles': {'full_name': 'Coach BLDR'},
        'workout_template_exercises': [
          {
            'id': 'te1',
            'order_index': 1,
            'sets': 4,
            'reps': 12,
            'rest_seconds': 60,
            'weight_kg': 40,
            'exercise_db_id': null,
            'exercises': {
              'id': 'e1',
              'name': 'Supino Reto',
              'primary_muscle_group': 'chest',
            },
          },
          {
            'id': 'te2',
            'order_index': 2,
            'sets': 3,
            'exercise_db_id': 'db_123',
            'exercises': null,
          },
        ],
      });

      expect(template.name, 'Peito e Tríceps');
      expect(template.createdByName, 'Coach BLDR');
      expect(template.exercises, hasLength(2));
      expect(template.exercises.first.exercise?.name, 'Supino Reto');
      expect(template.exercises.first.weightKg, 40.0);
      expect(template.exercises.last.exerciseDbId, 'db_123');
      expect(template.exercises.last.exercise, isNull);
    });
  });

  group('WorkoutModels.sessionFromMap', () {
    test('parseia sessão com séries e infere is_completed de completed_at', () {
      final session = WorkoutModels.sessionFromMap({
        'id': 'w1',
        'name': 'Treino A',
        'started_at': '2026-07-30T08:00:00Z',
        'completed_at': null,
        'is_completed': false,
        'workout_templates': {'name': 'Peito', 'workout_type': 'strength'},
        'workout_exercise_sets': [
          {
            'id': 's1',
            'user_workout_id': 'w1',
            'set_number': 1,
            'reps': 10,
            'weight_kg': 40.5,
            'completed_at': '2026-07-30T08:05:00Z',
            'exercises': {'id': 'e1', 'name': 'Supino'},
          },
          {
            'id': 's2',
            'user_workout_id': 'w1',
            'set_number': 2,
            'completed_at': null,
          },
        ],
      });

      expect(session.isActive, isTrue);
      expect(session.templateName, 'Peito');
      expect(session.sets, hasLength(2));
      expect(session.sets[0].isCompleted, isTrue,
          reason: 'completed_at preenchido ⇒ série concluída');
      expect(session.sets[0].exercise?.name, 'Supino');
      expect(session.sets[1].isCompleted, isFalse);
    });

    test('sessão concluída sem flag is_completed usa completed_at', () {
      final session = WorkoutModels.sessionFromMap({
        'id': 'w2',
        'name': 'Treino B',
        'completed_at': '2026-07-30T09:00:00Z',
      });

      expect(session.isCompleted, isTrue);
      expect(session.isActive, isFalse);
    });

    test('resume séries, volume e origem WHOOP somente das séries concluídas',
        () {
      final session = WorkoutModels.sessionFromMap({
        'id': 'w3',
        'name': 'Treino C',
        'notes': 'Atividade WHOOP vinculada ao treino planejado.',
        'completed_at': '2026-08-30T01:12:00Z',
        'workout_exercise_sets': [
          {
            'id': 's1',
            'user_workout_id': 'w3',
            'set_number': 1,
            'reps': 10,
            'weight_kg': 40,
            'completed_at': '2026-08-30T00:30:00Z',
          },
          {
            'id': 's2',
            'user_workout_id': 'w3',
            'set_number': 2,
            'reps': 8,
            'weight_kg': 50,
            'completed_at': '2026-08-30T00:35:00Z',
          },
          {
            'id': 's3',
            'user_workout_id': 'w3',
            'set_number': 3,
            'reps': 12,
            'weight_kg': 30,
            'completed_at': null,
          },
        ],
      });

      expect(session.completedViaWhoop, isTrue);
      expect(session.completedSetCount, 2);
      expect(session.completedVolumeKg, 800);
    });
  });

  group('WorkoutModels.templateExerciseToServiceMap', () {
    test('prioriza exercise_db_id e inclui exercise_id da biblioteca', () {
      final map = WorkoutModels.templateExerciseToServiceMap(
        WorkoutModels.templateExerciseFromMap({
          'order_index': 1,
          'sets': 3,
          'reps': 8,
          'exercise_db_id': 'db_9',
        }),
      );

      expect(map['sets'], 3);
      expect(map['reps'], 8);
      expect(map['exercise_db_id'], 'db_9');
      expect(map['exercise_id'], isNull);
    });

    test(
        'BACKLOG_FUNCIONAL.md B5 — grava free_name quando não há '
        'exercise_id nem exercise_db_id (exercício gerado pelo HAVOK)', () {
      final map = WorkoutModels.templateExerciseToServiceMap(
        WorkoutModels.templateExerciseFromMap({
          'order_index': 1,
          'sets': 4,
          'reps': 10,
          'free_name': 'Supino inclinado com halteres',
        }),
      );

      expect(map['free_name'], 'Supino inclinado com halteres');
      expect(map['exercise_id'], isNull);
      expect(map['exercise_db_id'], isNull);
    });

    test('não grava free_name quando o exercício tem exercise_db_id', () {
      final map = WorkoutModels.templateExerciseToServiceMap(
        WorkoutModels.templateExerciseFromMap({
          'order_index': 1,
          'sets': 3,
          'exercise_db_id': 'db_9',
          'free_name': 'Nome que não deveria ser gravado',
        }),
      );

      expect(map.containsKey('free_name'), isFalse);
    });
  });

  group('WorkoutModels.setFromMap (B5 — free_name propagado da sessão)', () {
    test('lê free_name quando o set não tem exercise_id/exercise_db_id', () {
      final set = WorkoutModels.setFromMap({
        'id': 's1',
        'user_workout_id': 'w1',
        'set_number': 1,
        'free_name': 'Remada curvada livre',
      });

      expect(set.freeName, 'Remada curvada livre');
      expect(set.exerciseId, isNull);
      expect(set.exercise, isNull);
    });
  });
}
