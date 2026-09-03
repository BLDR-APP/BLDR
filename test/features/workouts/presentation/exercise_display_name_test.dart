import 'package:flutter_test/flutter_test.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/exercise_display_name.dart';

void main() {
  test('preserva nome interno localizado quando ExerciseDB também existe', () {
    expect(
      resolveExerciseDisplayName(
        internalName: 'Remada invertida',
        exerciseDbName: 'inverted row',
      ),
      'Remada invertida',
    );
  });

  test('usa ExerciseDB somente quando o nome interno está ausente', () {
    expect(
      resolveExerciseDisplayName(exerciseDbName: 'dead bug'),
      'dead bug',
    );
  });

  test('ignora nomes vazios e usa fallback sem produzir string null', () {
    expect(
      resolveExerciseDisplayName(
        internalName: '  ',
        exerciseDbName: '',
      ),
      'Exercício',
    );
  });

  test('normaliza espaços dos nomes antes de exibir', () {
    expect(
      resolveExerciseDisplayName(
        internalName: '  Rosca inversa  ',
        exerciseDbName: 'barbell reverse curl',
      ),
      'Rosca inversa',
    );
  });
}
