import 'package:bldr_fitness/features/workouts/data/datasources/supabase_canonical_workout_datasource.dart';
import 'package:bldr_fitness/features/workouts/data/mappers/canonical_workout_mapper.dart';
import 'package:bldr_fitness/features/workouts/data/repositories/canonical_workout_reader_impl.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/canonical_workout.dart';
import 'package:bldr_fitness/features/workouts/domain/repositories/canonical_workout_reader.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> session({
  required String id,
  required String userId,
  String? completedAt,
  String? startedAt = '2026-01-01T10:00:00Z',
  String? templateId = 'template-1',
}) =>
    {
      'id': id,
      'user_id': userId,
      'workout_template_id': templateId,
      'name': 'Treino',
      'started_at': startedAt,
      'completed_at': completedAt,
      'total_duration_seconds': 3600,
      'volume_kg': 1200.5,
      'muscle_groups': ['costas'],
      'is_completed': completedAt != null,
    };

Map<String, dynamic> set({
  required String id,
  required String workoutId,
  int orderIndex = 0,
  int setNumber = 1,
  bool skipped = false,
  String? completedAt,
}) =>
    {
      'id': id,
      'user_workout_id': workoutId,
      'exercise_id': 'exercise-1',
      'exercise_db_id': 'db-1',
      'workout_template_exercise_id': 'template-exercise-1',
      'order_index': orderIndex,
      'set_number': setNumber,
      'reps': 10,
      'weight_kg': 50.0,
      'duration_seconds': null,
      'distance_meters': null,
      'rest_seconds': 90,
      'completed_at': completedAt,
      'is_completed': completedAt != null,
      'is_skipped': skipped,
      'notes': null,
    };

const exercise = {
  'id': 'exercise-1',
  'name': 'Remada curvada',
  'exercise_db_id': 'db-1',
  'primary_muscle_group': 'costas',
  'secondary_muscle_groups': ['bíceps'],
};

void main() {
  group('CanonicalWorkoutMapper', () {
    test('keeps set projections free of the unsupported is_completed field',
        () {
      expect(
        SupabaseCanonicalWorkoutDatasource.personalSetsProjection,
        isNot(contains('is_completed')),
      );
      expect(
        SupabaseCanonicalWorkoutDatasource.clubSetsProjection,
        isNot(contains('is_completed')),
      );
    });

    test('maps a FREE session preserving source, IDs and optional values', () {
      final mapped = CanonicalWorkoutMapper.personal(
        session: session(id: 'free-1', userId: 'user-1'),
        sets: [set(id: 'set-1', workoutId: 'free-1')],
        exercisesById: const {'exercise-1': exercise},
      );

      expect(mapped.id, 'personal:free-1');
      expect(mapped.sourceSessionId, 'free-1');
      expect(mapped.source, WorkoutSessionSource.personal);
      expect(mapped.definitionSource, WorkoutDefinitionSource.personal);
      expect(mapped.startedAt, DateTime.parse('2026-01-01T10:00:00Z'));
      expect(mapped.volumeKg, 1200.5);
      expect(mapped.exercises.single.internalExerciseId, 'exercise-1');
      expect(mapped.exercises.single.exerciseDbId, 'db-1');
      expect(mapped.exercises.single.templateExerciseId, 'template-exercise-1');
      expect(mapped.exercises.single.displayName, 'Remada curvada');
    });

    test(
        'maps a CLUB session with exercise metadata resolved from its internal ID',
        () {
      final clubSet = set(id: 'set-1', workoutId: 'club-1')
        ..remove('exercise_db_id');
      final mapped = CanonicalWorkoutMapper.club(
        session: session(id: 'club-1', userId: 'user-1', templateId: null),
        sets: [clubSet],
        exercisesById: const {'exercise-1': exercise},
      );

      expect(mapped.id, 'bldrClub:club-1');
      expect(mapped.source, WorkoutSessionSource.bldrClub);
      expect(mapped.definitionId, isNull);
      expect(mapped.definitionSource, isNull);
      expect(mapped.exercises.single.exerciseDbId, 'db-1');
    });

    test('keeps a skipped set pending and not completed', () {
      final mapped = CanonicalWorkoutMapper.personal(
        session: session(id: 'free-1', userId: 'user-1'),
        sets: [set(id: 'set-1', workoutId: 'free-1', skipped: true)],
        exercisesById: const {'exercise-1': exercise},
      );

      final mappedSet = mapped.exercises.single.sets.single;
      expect(mappedSet.isSkipped, isTrue);
      expect(mappedSet.isCompleted, isFalse);
      expect(mappedSet.completedAt, isNull);
    });

    test('infers completion from completed_at without is_completed', () {
      final completedSet = set(
        id: 'set-1',
        workoutId: 'free-1',
        completedAt: '2026-01-01T11:00:00Z',
      )..remove('is_completed');

      final free = CanonicalWorkoutMapper.personal(
        session: session(id: 'free-1', userId: 'user-1'),
        sets: [completedSet],
        exercisesById: const {'exercise-1': exercise},
      );
      final club = CanonicalWorkoutMapper.club(
        session: session(id: 'club-1', userId: 'user-1'),
        sets: [
          {
            ...completedSet,
            'id': 'club-set-1',
            'user_workout_id': 'club-1',
          },
        ],
        exercisesById: const {'exercise-1': exercise},
      );

      expect(free.exercises.single.sets.single.isCompleted, isTrue);
      expect(club.exercises.single.sets.single.isCompleted, isTrue);
    });

    test('orders exercises and sets by order index, set number, then ID', () {
      final mapped = CanonicalWorkoutMapper.personal(
        session: session(id: 'free-1', userId: 'user-1'),
        sets: [
          set(id: 'set-b', workoutId: 'free-1', orderIndex: 1, setNumber: 2),
          set(id: 'set-a', workoutId: 'free-1', orderIndex: 1, setNumber: 1),
          {
            ...set(id: 'set-c', workoutId: 'free-1', orderIndex: 0),
            'exercise_id': 'exercise-2',
          },
        ],
        exercisesById: const {
          'exercise-1': exercise,
          'exercise-2': {'id': 'exercise-2', 'name': 'Agachamento'},
        },
      );

      expect(mapped.exercises.first.internalExerciseId, 'exercise-2');
      expect(
        mapped.exercises.last.sets.map((item) => item.id),
        ['set-a', 'set-b'],
      );
    });
  });

  group('CanonicalWorkoutReaderImpl', () {
    test('reads only authenticated user rows and filters foreign sets',
        () async {
      final source = _FakeSource(
        personal: [
          session(id: 'owned', userId: 'user-1'),
          session(id: 'foreign', userId: 'user-2'),
        ],
        personalSetRows: [
          set(id: 'owned-set', workoutId: 'owned'),
          set(id: 'foreign-set', workoutId: 'foreign'),
        ],
      );
      final reader = _reader(source);

      final result = await reader.history(userId: 'user-1');

      expect(result.isSuccess, isTrue);
      final sessions = result.valueOrNull!.sessions;
      expect(sessions, hasLength(1));
      expect(sessions.single.sourceSessionId, 'owned');
      expect(sessions.single.exercises.single.sets.single.id, 'owned-set');
      expect(source.personalSetRequests, [
        <String>['owned']
      ]);
    });

    test('rejects a request for a user other than the authenticated user',
        () async {
      final result = await _reader(_FakeSource()).history(userId: 'user-2');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull!.message, contains('outro usuário'));
    });

    test('returns a stable mixed-source page and opaque next cursor', () async {
      final reader = _reader(_FakeSource(
        personal: [
          session(
            id: 'free-1',
            userId: 'user-1',
            completedAt: '2026-01-02T10:00:00Z',
          ),
        ],
        club: [
          session(
            id: 'club-1',
            userId: 'user-1',
            completedAt: '2026-01-03T10:00:00Z',
          ),
        ],
      ));

      final first = await reader.history(userId: 'user-1', limit: 1);
      final second = await reader.history(
        userId: 'user-1',
        limit: 1,
        cursor: first.valueOrNull!.nextCursor,
      );

      expect(first.valueOrNull!.sessions.single.id, 'bldrClub:club-1');
      expect(first.valueOrNull!.hasMore, isTrue);
      expect(second.valueOrNull!.sessions.single.id, 'personal:free-1');
      expect(second.valueOrNull!.hasMore, isFalse);
    });

    test('returns a validation failure for an unknown cursor', () async {
      final result = await _reader(_FakeSource(
        personal: [session(id: 'free-1', userId: 'user-1')],
      )).history(
        userId: 'user-1',
        cursor: const CanonicalWorkoutCursor('personal:missing'),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull!.message, contains('Cursor'));
    });

    test('reads bounded candidates rather than the full history', () async {
      final source = _FakeSource(
        personal: [
          for (var index = 0; index < 50; index++)
            session(
              id: 'free-$index',
              userId: 'user-1',
              startedAt:
                  '2026-01-01T${(23 - (index % 20)).toString().padLeft(2, '0')}:00:00Z',
            ),
        ],
      );

      final result = await _reader(source).history(userId: 'user-1', limit: 2);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.sessions, hasLength(2));
      expect(source.personalPageRequests, everyElement(isNotNull));
      expect(source.personalPageRequests.every((request) => request.limit == 3),
          isTrue);
    });

    test(
        'keeps a static mixed history complete across pages and timestamp ties',
        () async {
      final reader = _reader(_FakeSource(
        personal: [
          for (final id in ['free-a', 'free-b', 'free-c'])
            session(
              id: id,
              userId: 'user-1',
              completedAt: '2026-01-03T10:00:00Z',
            ),
        ],
        club: [
          for (final id in ['club-a', 'club-b'])
            session(
              id: id,
              userId: 'user-1',
              completedAt: '2026-01-03T10:00:00Z',
            ),
        ],
      ));

      final first = await reader.history(userId: 'user-1', limit: 2);
      final second = await reader.history(
        userId: 'user-1',
        limit: 2,
        cursor: first.valueOrNull!.nextCursor,
      );
      final third = await reader.history(
        userId: 'user-1',
        limit: 2,
        cursor: second.valueOrNull!.nextCursor,
      );

      expect(
        [
          ...first.valueOrNull!.sessions,
          ...second.valueOrNull!.sessions,
          ...third.valueOrNull!.sessions,
        ].map((session) => session.id),
        [
          'personal:free-a',
          'personal:free-b',
          'personal:free-c',
          'bldrClub:club-a',
          'bldrClub:club-b',
        ],
      );
      expect(third.valueOrNull!.hasMore, isFalse);
    });

    test('returns a failure when the read source throws', () async {
      final result = await _reader(_FakeSource(throwOnPersonal: true))
          .history(userId: 'user-1');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isNotNull);
    });
  });
}

CanonicalWorkoutReaderImpl _reader(CanonicalWorkoutReadSource source) =>
    CanonicalWorkoutReaderImpl(
      source: source,
      currentUserId: () => 'user-1',
    );

class _FakeSource implements CanonicalWorkoutReadSource {
  final List<Map<String, dynamic>> personal;
  final List<Map<String, dynamic>> club;
  final List<Map<String, dynamic>> personalSetRows;
  final bool throwOnPersonal;
  final List<List<String>> personalSetRequests = [];
  final List<CanonicalWorkoutSessionPageRequest> personalPageRequests = [];

  _FakeSource({
    this.personal = const [],
    this.club = const [],
    this.personalSetRows = const [],
    this.throwOnPersonal = false,
  });

  @override
  Future<List<Map<String, dynamic>>> clubSessionPage(
    CanonicalWorkoutSessionPageRequest request,
  ) async =>
      _page(club, request);

  @override
  Future<List<Map<String, dynamic>>> clubSets(List<String> sessionIds) async =>
      const [];

  @override
  Future<List<Map<String, dynamic>>> exercises(
          List<String> exerciseIds) async =>
      exerciseIds.isEmpty ? const [] : [exercise];

  @override
  Future<List<Map<String, dynamic>>> personalSessionPage(
    CanonicalWorkoutSessionPageRequest request,
  ) async {
    if (throwOnPersonal) throw StateError('offline');
    personalPageRequests.add(request);
    return _page(personal, request);
  }

  @override
  Future<List<Map<String, dynamic>>> personalSets(
      List<String> sessionIds) async {
    personalSetRequests.add(sessionIds);
    return personalSetRows;
  }

  List<Map<String, dynamic>> _page(
    List<Map<String, dynamic>> rows,
    CanonicalWorkoutSessionPageRequest request,
  ) {
    final filtered = rows
        .where((row) {
          final completedAt = _date(row['completed_at']);
          final startedAt = _date(row['started_at']);
          return switch (request.bucket) {
            CanonicalWorkoutSessionBucket.completed => completedAt != null,
            CanonicalWorkoutSessionBucket.inProgress =>
              completedAt == null && startedAt != null,
            CanonicalWorkoutSessionBucket.undated =>
              completedAt == null && startedAt == null,
          };
        })
        .where((row) => _afterCursor(row, request))
        .toList()
      ..sort((left, right) {
        final leftDate =
            request.bucket == CanonicalWorkoutSessionBucket.completed
                ? _date(left['completed_at'])
                : _date(left['started_at']);
        final rightDate =
            request.bucket == CanonicalWorkoutSessionBucket.completed
                ? _date(right['completed_at'])
                : _date(right['started_at']);
        if (leftDate != null && rightDate != null) {
          final compare = rightDate.compareTo(leftDate);
          if (compare != 0) return compare;
        }
        return left['id'].toString().compareTo(right['id'].toString());
      });
    return filtered.take(request.limit).toList();
  }

  bool _afterCursor(
    Map<String, dynamic> row,
    CanonicalWorkoutSessionPageRequest request,
  ) {
    if (!request.hasCursor) return true;
    if (request.bucket == CanonicalWorkoutSessionBucket.undated) {
      if (request.cursorTimestamp != null) return true;
      return switch (request.tie) {
        CanonicalWorkoutCursorTie.exclude => false,
        CanonicalWorkoutCursorTie.afterId =>
          row['id'].toString().compareTo(request.cursorSessionId!) > 0,
        CanonicalWorkoutCursorTie.includeAll => true,
      };
    }
    if (request.cursorTimestamp == null) return false;
    final date = request.bucket == CanonicalWorkoutSessionBucket.completed
        ? _date(row['completed_at'])!
        : _date(row['started_at'])!;
    final compare = date.compareTo(request.cursorTimestamp!);
    if (compare < 0) return true;
    if (compare > 0) return false;
    return switch (request.tie) {
      CanonicalWorkoutCursorTie.exclude => false,
      CanonicalWorkoutCursorTie.afterId =>
        row['id'].toString().compareTo(request.cursorSessionId!) > 0,
      CanonicalWorkoutCursorTie.includeAll => true,
    };
  }

  DateTime? _date(Object? value) =>
      value == null ? null : DateTime.parse(value.toString());
}
