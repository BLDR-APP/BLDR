import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/features/workouts/domain/entities/exercise.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_session.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/workout_details_format.dart';

WorkoutSet _set(double? w, int? r, {bool done = true, bool skipped = false}) =>
    WorkoutSet(
      userWorkoutId: 'w',
      setNumber: 1,
      weightKg: w,
      reps: r,
      isCompleted: done,
      isSkipped: skipped,
    );

void main() {
  test('faixa de reps', () {
    expect(
        WorkoutDetailsFormat.repsRange(const [
          TemplateSetDetail(reps: 8),
          TemplateSetDetail(reps: 12),
          TemplateSetDetail(reps: 10),
        ]),
        '8–12');
    expect(WorkoutDetailsFormat.repsRange(const [TemplateSetDetail(reps: 10)]),
        '10');
    expect(WorkoutDetailsFormat.repsRange(const []), isNull);
  });

  test('volume conta só séries concluídas, não puladas, com carga e reps', () {
    final s = WorkoutSession(name: 'x', sets: [
      _set(40, 10),
      _set(45, 8),
      _set(50, 5, done: false),
      _set(60, 5, skipped: true),
      _set(null, 10),
    ]);
    expect(WorkoutDetailsFormat.sessionVolume(s), 760);
  });

  test('volume null sem séries válidas', () {
    final s = WorkoutSession(name: 'x', sets: [_set(null, 10)]);
    expect(WorkoutDetailsFormat.sessionVolume(s), isNull);
  });

  test('última sessão concluída do template', () {
    final history = [
      const WorkoutSession(id: 'a', name: 'x', templateId: 't2', isCompleted: true),
      const WorkoutSession(id: 'b', name: 'x', templateId: 't1', isCompleted: true),
      const WorkoutSession(id: 'c', name: 'x', templateId: 't1', isCompleted: true),
    ];
    expect(WorkoutDetailsFormat.lastCompletedFor(history, 't1')?.id, 'b');
    expect(WorkoutDetailsFormat.lastCompletedFor(history, 't3'), isNull);
  });

  test('total de séries e grupos', () {
    const t = WorkoutTemplate(name: 'P', exercises: [
      TemplateExercise(orderIndex: 1, sets: 3, exercise: Exercise(name: 'a', primaryMuscleGroup: 'Peito', secondaryMuscleGroups: ['Tríceps'])),
      TemplateExercise(orderIndex: 2, sets: 2),
    ]);
    expect(WorkoutDetailsFormat.totalSets(t), 5);
    expect(WorkoutDetailsFormat.muscleGroups(t.exercises.first), 'Peito · Tríceps');
  });

  test('duplicar copia exercícios e séries, sem id e privado', () {
    const t = WorkoutTemplate(
      id: 'orig',
      name: 'Push A',
      workoutType: 'força',
      isPublic: true,
      source: 'havok',
      exercises: [
        TemplateExercise(
          orderIndex: 1,
          sets: 2,
          exerciseDbId: 'db1',
          setDetails: [
            TemplateSetDetail(weightKg: 40, reps: 10, restSeconds: 90),
            TemplateSetDetail(weightKg: 45, reps: 8, restSeconds: 90),
          ],
        ),
        TemplateExercise(orderIndex: 2, sets: 3, reps: 12, weightKg: 20),
      ],
    );
    final c = WorkoutDetailsFormat.duplicate(t,
        name: 'Push A (cópia)', durationMinutes: 30);
    expect(c.id, isNull);
    expect(c.name, 'Push A (cópia)');
    expect(c.isPublic, isFalse);
    expect(c.source, 'user');
    expect(c.workoutType, 'força');
    expect(c.estimatedDurationMinutes, 30);
    expect(c.exercises.first.exerciseDbId, 'db1');
    expect(c.exercises.first.setDetails.map((d) => d.weightKg), [40, 45]);
    // Template antigo sem set_details: séries agregadas viram lista.
    expect(c.exercises.last.setDetails.length, 3);
    expect(c.exercises.last.setDetails.first.weightKg, 20);
  });
}
