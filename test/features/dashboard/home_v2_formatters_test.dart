import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/features/workouts/domain/entities/exercise.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/home_v2_formatters.dart';

TemplateExercise _ex(int i, dynamic muscle) => TemplateExercise(
      orderIndex: i,
      exercise: Exercise(name: 'ex$i', primaryMuscleGroup: muscle),
    );

void main() {
  group('xpCompact', () {
    test('usa vírgula decimal em pt', () {
      expect(HomeV2Format.xpCompact(13200, 'pt'), '13,2k');
    });
    test('usa ponto decimal em en', () {
      expect(HomeV2Format.xpCompact(13200, 'en'), '13.2k');
    });
    test('milhar redondo sem decimal', () {
      expect(HomeV2Format.xpCompact(20000, 'pt'), '20k');
    });
    test('abaixo de mil fica inteiro', () {
      expect(HomeV2Format.xpCompact(850, 'pt'), '850');
    });
  });

  group('totalDuration', () {
    test('horas e minutos', () {
      expect(HomeV2Format.totalDuration(260), '4h 20');
      expect(HomeV2Format.totalDuration(245), '4h 05');
    });
    test('só horas', () => expect(HomeV2Format.totalDuration(240), '4h'));
    test('só minutos', () => expect(HomeV2Format.totalDuration(45), '45m'));
    test('zero vira traço', () => expect(HomeV2Format.totalDuration(0), '—'));
  });

  test('thousands usa separador do locale', () {
    expect(HomeV2Format.thousands(3474, 'pt'), '3.474');
    expect(HomeV2Format.thousands(3474, 'en'), '3,474');
  });

  group('muscleGroups', () {
    test('ordem dos exercícios, sem repetição', () {
      final t = WorkoutTemplate(name: 'Push A', exercises: [
        _ex(0, 'Peito'),
        _ex(1, 'Ombros'),
        _ex(2, 'Peito'),
        _ex(3, 'Tríceps'),
      ]);
      expect(HomeV2Format.muscleGroups(t), 'Peito · Ombros · Tríceps');
    });
    test('aceita lista (ExerciseDB) e ignora vazios/sem exercício', () {
      final t = WorkoutTemplate(name: 'X', exercises: [
        _ex(0, ['chest', 'triceps']),
        _ex(1, ''),
        const TemplateExercise(orderIndex: 2, freeName: 'Livre'),
      ]);
      expect(HomeV2Format.muscleGroups(t), 'chest, triceps');
    });
    test('template sem exercícios gera texto vazio', () {
      expect(HomeV2Format.muscleGroups(const WorkoutTemplate(name: 'X')), '');
    });
  });

  test('workoutsInLast7Days conta treinos (não minutos) na janela', () {
    final now = DateTime(2026, 11, 16, 10);
    final counts = {
      DateTime(2026, 11, 16): 1,
      DateTime(2026, 11, 14): 2,
      DateTime(2026, 11, 10): 1, // limite da janela (6 dias atrás)
      DateTime(2026, 11, 9): 5, // fora da janela
    };
    expect(HomeV2Format.workoutsInLast7Days(counts, now), 4);
  });
}
