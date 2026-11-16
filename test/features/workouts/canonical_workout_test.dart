import 'package:bldr_fitness/features/workouts/domain/entities/canonical_workout.dart';
import 'package:bldr_fitness/features/workouts/domain/repositories/canonical_workout_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('canonicalWorkoutSessionId', () {
    test('prefixes a personal source session ID', () {
      expect(
        canonicalWorkoutSessionId(WorkoutSessionSource.personal, 'uuid-1'),
        'personal:uuid-1',
      );
    });

    test('prefixes a BLDR Club source session ID', () {
      expect(
        canonicalWorkoutSessionId(WorkoutSessionSource.bldrClub, 'uuid-1'),
        'bldrClub:uuid-1',
      );
    });

    test('keeps matching source IDs globally distinct by source', () {
      const sourceSessionId = 'same-uuid';

      expect(
        canonicalWorkoutSessionId(
          WorkoutSessionSource.personal,
          sourceSessionId,
        ),
        isNot(
          canonicalWorkoutSessionId(
            WorkoutSessionSource.bldrClub,
            sourceSessionId,
          ),
        ),
      );
    });
  });

  group('CanonicalWorkoutSession', () {
    test('preserves source and definition provenance independently', () {
      const personal = CanonicalWorkoutSession(
        id: 'personal:session-1',
        sourceSessionId: 'session-1',
        userId: 'user-1',
        source: WorkoutSessionSource.personal,
        definitionId: 'template-1',
        definitionSource: WorkoutDefinitionSource.personal,
        isCompleted: true,
      );
      const club = CanonicalWorkoutSession(
        id: 'bldrClub:session-2',
        sourceSessionId: 'session-2',
        userId: 'user-1',
        source: WorkoutSessionSource.bldrClub,
        definitionId: 'club-template-1',
        definitionSource: WorkoutDefinitionSource.bldrClub,
        isCompleted: false,
      );

      expect(personal.source, WorkoutSessionSource.personal);
      expect(personal.definitionSource, WorkoutDefinitionSource.personal);
      expect(club.source, WorkoutSessionSource.bldrClub);
      expect(club.definitionSource, WorkoutDefinitionSource.bldrClub);
    });

    test('preserves nullable fields as null and allows no exercises', () {
      const session = CanonicalWorkoutSession(
        id: 'personal:session-1',
        sourceSessionId: 'session-1',
        userId: 'user-1',
        source: WorkoutSessionSource.personal,
        isCompleted: false,
      );

      expect(session.definitionId, isNull);
      expect(session.definitionSource, isNull);
      expect(session.name, isNull);
      expect(session.startedAt, isNull);
      expect(session.completedAt, isNull);
      expect(session.durationSeconds, isNull);
      expect(session.volumeKg, isNull);
      expect(session.muscleGroups, isNull);
      expect(session.notes, isNull);
      expect(session.exercises, isEmpty);
    });
  });

  test('exercise identity and names coexist without replacement', () {
    const exercise = CanonicalWorkoutExercise(
      id: 'exercise-occurrence-1',
      internalExerciseId: 'internal-1',
      exerciseDbId: 'exercisedb-1',
      templateExerciseId: 'template-exercise-1',
      displayName: 'Remada curvada',
      freeName: 'Remada personalizada',
    );

    expect(exercise.internalExerciseId, 'internal-1');
    expect(exercise.exerciseDbId, 'exercisedb-1');
    expect(exercise.templateExerciseId, 'template-exercise-1');
    expect(exercise.displayName, 'Remada curvada');
    expect(exercise.freeName, 'Remada personalizada');
    expect(exercise.secondaryMuscleGroups, isEmpty);
    expect(exercise.sets, isEmpty);
  });

  test('skipped set remains incomplete and without completed timestamp', () {
    const set = CanonicalWorkoutSet(
      id: 'set-1',
      sessionId: 'personal:session-1',
      exerciseId: 'exercise-1',
      setNumber: 1,
      isSkipped: true,
      isCompleted: false,
    );

    expect(set.isSkipped, isTrue);
    expect(set.isCompleted, isFalse);
    expect(set.completedAt, isNull);
  });

  group('CanonicalWorkoutPage', () {
    test('represents an empty final page', () {
      const page = CanonicalWorkoutPage(sessions: [], hasMore: false);

      expect(page.sessions, isEmpty);
      expect(page.nextCursor, isNull);
      expect(page.hasMore, isFalse);
    });

    test('keeps an opaque cursor for a subsequent page', () {
      const page = CanonicalWorkoutPage(
        sessions: [
          CanonicalWorkoutSession(
            id: 'bldrClub:session-1',
            sourceSessionId: 'session-1',
            userId: 'user-1',
            source: WorkoutSessionSource.bldrClub,
            isCompleted: true,
          ),
        ],
        nextCursor: CanonicalWorkoutCursor('opaque-token'),
        hasMore: true,
      );

      expect(page.sessions, hasLength(1));
      expect(page.nextCursor, isNotNull);
      expect(page.hasMore, isTrue);
    });
  });
}
