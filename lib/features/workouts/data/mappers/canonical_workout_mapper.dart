import 'package:bldr_fitness/features/workouts/domain/entities/canonical_workout.dart';

/// Converte rows já carregadas em entidades canônicas, sem persistir nem
/// completar dados ausentes.
class CanonicalWorkoutMapper {
  static CanonicalWorkoutSession personal({
    required Map<String, dynamic> session,
    required List<Map<String, dynamic>> sets,
    required Map<String, Map<String, dynamic>> exercisesById,
  }) =>
      _session(
        session: session,
        sets: sets,
        exercisesById: exercisesById,
        source: WorkoutSessionSource.personal,
        definitionSource: WorkoutDefinitionSource.personal,
      );

  static CanonicalWorkoutSession club({
    required Map<String, dynamic> session,
    required List<Map<String, dynamic>> sets,
    required Map<String, Map<String, dynamic>> exercisesById,
  }) =>
      _session(
        session: session,
        sets: sets,
        exercisesById: exercisesById,
        source: WorkoutSessionSource.bldrClub,
        definitionSource: WorkoutDefinitionSource.bldrClub,
      );

  static CanonicalWorkoutSession _session({
    required Map<String, dynamic> session,
    required List<Map<String, dynamic>> sets,
    required Map<String, Map<String, dynamic>> exercisesById,
    required WorkoutSessionSource source,
    required WorkoutDefinitionSource definitionSource,
  }) {
    final sourceSessionId = _requiredString(session, 'id');
    final canonicalSessionId =
        canonicalWorkoutSessionId(source, sourceSessionId);
    final definitionId = _string(session['workout_template_id']);

    return CanonicalWorkoutSession(
      id: canonicalSessionId,
      sourceSessionId: sourceSessionId,
      userId: _requiredString(session, 'user_id'),
      source: source,
      definitionId: definitionId,
      definitionSource: definitionId == null ? null : definitionSource,
      name: _string(session['name']),
      startedAt: _date(session['started_at']),
      completedAt: _date(session['completed_at']),
      isCompleted: _completed(session),
      durationSeconds: _int(session['total_duration_seconds']),
      volumeKg: _double(session['volume_kg']),
      muscleGroups: _stringsOrNull(session['muscle_groups']),
      notes: _string(session['notes']),
      exercises: _exercises(
        sessionId: canonicalSessionId,
        sets: sets,
        exercisesById: exercisesById,
      ),
    );
  }

  static List<CanonicalWorkoutExercise> _exercises({
    required String sessionId,
    required List<Map<String, dynamic>> sets,
    required Map<String, Map<String, dynamic>> exercisesById,
  }) {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final set in sets) {
      final key = [
        _int(set['order_index'])?.toString() ?? '',
        _string(set['exercise_id']) ?? '',
        _string(set['exercise_db_id']) ?? '',
        _string(set['workout_template_exercise_id']) ?? '',
        _string(set['free_name']) ?? '',
      ].join('|');
      groups.putIfAbsent(key, () => []).add(set);
    }

    final orderedGroups = groups.values.toList()
      ..sort((left, right) {
        final order = _compareNullableInts(
          _int(left.first['order_index']),
          _int(right.first['order_index']),
        );
        if (order != 0) return order;
        final number = _compareNullableInts(
          _int(left.first['set_number']),
          _int(right.first['set_number']),
        );
        if (number != 0) return number;
        return _requiredString(left.first, 'id')
            .compareTo(_requiredString(right.first, 'id'));
      });

    return [
      for (var index = 0; index < orderedGroups.length; index++)
        _exercise(
          sessionId: sessionId,
          occurrenceIndex: index,
          sets: orderedGroups[index],
          exercisesById: exercisesById,
        ),
    ];
  }

  static CanonicalWorkoutExercise _exercise({
    required String sessionId,
    required int occurrenceIndex,
    required List<Map<String, dynamic>> sets,
    required Map<String, Map<String, dynamic>> exercisesById,
  }) {
    final first = sets.first;
    final internalExerciseId = _string(first['exercise_id']);
    final exercise =
        internalExerciseId == null ? null : exercisesById[internalExerciseId];
    final exerciseId = '$sessionId:exercise:$occurrenceIndex';
    final orderedSets = [...sets]..sort((left, right) {
        final number = _compareNullableInts(
          _int(left['set_number']),
          _int(right['set_number']),
        );
        if (number != 0) return number;
        return _requiredString(left, 'id')
            .compareTo(_requiredString(right, 'id'));
      });

    return CanonicalWorkoutExercise(
      id: exerciseId,
      internalExerciseId: internalExerciseId,
      exerciseDbId: _string(first['exercise_db_id']) ??
          _string(exercise?['exercise_db_id']),
      templateExerciseId: _string(first['workout_template_exercise_id']),
      orderIndex: _int(first['order_index']),
      displayName: _string(exercise?['name']),
      freeName: _string(first['free_name']),
      primaryMuscleGroup: _string(exercise?['primary_muscle_group']),
      secondaryMuscleGroups:
          _stringsOrEmpty(exercise?['secondary_muscle_groups']),
      sets: [
        for (final set in orderedSets)
          _set(sessionId: sessionId, exerciseId: exerciseId, set: set),
      ],
    );
  }

  static CanonicalWorkoutSet _set({
    required String sessionId,
    required String exerciseId,
    required Map<String, dynamic> set,
  }) {
    final isSkipped = set['is_skipped'] == true;
    final completedAt = _date(set['completed_at']);
    final storedCompleted = set['is_completed'];
    if (isSkipped && (completedAt != null || storedCompleted == true)) {
      throw FormatException('Skipped set cannot be completed.');
    }

    return CanonicalWorkoutSet(
      id: _requiredString(set, 'id'),
      sessionId: sessionId,
      exerciseId: exerciseId,
      setNumber: _requiredInt(set, 'set_number'),
      orderIndex: _int(set['order_index']),
      reps: _int(set['reps']),
      weightKg: _double(set['weight_kg']),
      durationSeconds: _int(set['duration_seconds']),
      distanceMeters: _double(set['distance_meters']),
      restSeconds: _int(set['rest_seconds']),
      completedAt: completedAt,
      isCompleted: !isSkipped &&
          (storedCompleted is bool ? storedCompleted : completedAt != null),
      isSkipped: isSkipped,
      notes: _string(set['notes']),
    );
  }

  static bool _completed(Map<String, dynamic> session) {
    final stored = session['is_completed'];
    return stored is bool ? stored : _date(session['completed_at']) != null;
  }

  static String _requiredString(Map<String, dynamic> map, String key) {
    final value = _string(map[key]);
    if (value == null || value.isEmpty) {
      throw FormatException('Missing required field: $key.');
    }
    return value;
  }

  static int _requiredInt(Map<String, dynamic> map, String key) {
    final value = _int(map[key]);
    if (value == null) throw FormatException('Missing required field: $key.');
    return value;
  }

  static String? _string(Object? value) => value?.toString();

  static int? _int(Object? value) => value is num ? value.toInt() : null;

  static double? _double(Object? value) =>
      value is num ? value.toDouble() : null;

  static DateTime? _date(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) throw FormatException('Invalid timestamp.');
    return parsed;
  }

  static List<String>? _stringsOrNull(Object? value) {
    if (value == null) return null;
    return _stringsOrEmpty(value);
  }

  static List<String> _stringsOrEmpty(Object? value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }

  static int _compareNullableInts(int? left, int? right) {
    if (left == null && right == null) return 0;
    if (left == null) return 1;
    if (right == null) return -1;
    return left.compareTo(right);
  }
}
