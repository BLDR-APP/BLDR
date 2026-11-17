import 'package:supabase_flutter/supabase_flutter.dart';

enum CanonicalWorkoutSessionBucket { completed, inProgress, undated }

enum CanonicalWorkoutCursorTie { exclude, afterId, includeAll }

/// Recorte keyset de uma das famílias físicas de sessões.
class CanonicalWorkoutSessionPageRequest {
  final String userId;
  final CanonicalWorkoutSessionBucket bucket;
  final int limit;
  final bool hasCursor;
  final DateTime? cursorTimestamp;
  final CanonicalWorkoutCursorTie tie;
  final String? cursorSessionId;

  const CanonicalWorkoutSessionPageRequest({
    required this.userId,
    required this.bucket,
    required this.limit,
    required this.hasCursor,
    required this.cursorTimestamp,
    required this.tie,
    this.cursorSessionId,
  });
}

/// Consultas read-only que abastecem o modelo canônico de workouts.
class SupabaseCanonicalWorkoutDatasource {
  static const String personalSetsProjection = '''
          id, user_workout_id, exercise_id, exercise_db_id,
          workout_template_exercise_id, set_number, order_index, reps,
          weight_kg, duration_seconds, distance_meters, rest_seconds,
          completed_at, is_skipped, notes, free_name
        ''';

  static const String clubSetsProjection = '''
          id, user_workout_id, exercise_id, workout_template_exercise_id,
          set_number, order_index, reps, weight_kg, duration_seconds,
          distance_meters, rest_seconds, completed_at, is_skipped, notes,
          free_name
        ''';

  final SupabaseClient _client;

  SupabaseCanonicalWorkoutDatasource(this._client);

  Future<List<Map<String, dynamic>>> personalSessionPage(
    CanonicalWorkoutSessionPageRequest request,
  ) =>
      _sessionPage('user_workouts', request);

  Future<List<Map<String, dynamic>>> clubSessionPage(
    CanonicalWorkoutSessionPageRequest request,
  ) =>
      _sessionPage('club_user_workouts', request);

  Future<List<Map<String, dynamic>>> _sessionPage(
    String table,
    CanonicalWorkoutSessionPageRequest request,
  ) async {
    if (_isEmptyAfterCursor(request)) return const [];

    var query = _client.from(table).select('''
          id, user_id, workout_template_id, name, started_at, completed_at,
          total_duration_seconds, volume_kg, muscle_groups, notes, is_completed
        ''').eq('user_id', request.userId);

    final timestampColumn = switch (request.bucket) {
      CanonicalWorkoutSessionBucket.completed => 'completed_at',
      CanonicalWorkoutSessionBucket.inProgress => 'started_at',
      CanonicalWorkoutSessionBucket.undated => 'id',
    };
    switch (request.bucket) {
      case CanonicalWorkoutSessionBucket.completed:
        query = query.not('completed_at', 'is', null);
      case CanonicalWorkoutSessionBucket.inProgress:
        query =
            query.isFilter('completed_at', null).not('started_at', 'is', null);
      case CanonicalWorkoutSessionBucket.undated:
        query =
            query.isFilter('completed_at', null).isFilter('started_at', null);
    }

    query = _applyKeyset(query, request, timestampColumn);
    final rows = request.bucket == CanonicalWorkoutSessionBucket.undated
        ? await query.order('id', ascending: true).limit(request.limit)
        : await query
            .order(timestampColumn, ascending: false)
            .order('id', ascending: true)
            .limit(request.limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  bool _isEmptyAfterCursor(CanonicalWorkoutSessionPageRequest request) {
    if (!request.hasCursor) return false;
    if (request.bucket == CanonicalWorkoutSessionBucket.undated) {
      return request.cursorTimestamp == null &&
          request.tie == CanonicalWorkoutCursorTie.exclude;
    }
    return request.cursorTimestamp == null;
  }

  dynamic _applyKeyset(
    dynamic query,
    CanonicalWorkoutSessionPageRequest request,
    String timestampColumn,
  ) {
    if (!request.hasCursor) return query;
    if (request.bucket == CanonicalWorkoutSessionBucket.undated) {
      if (request.cursorTimestamp != null) return query;
      return switch (request.tie) {
        CanonicalWorkoutCursorTie.exclude => query,
        CanonicalWorkoutCursorTie.afterId =>
          query.gt('id', request.cursorSessionId!),
        CanonicalWorkoutCursorTie.includeAll => query,
      };
    }

    final timestamp = request.cursorTimestamp!.toUtc().toIso8601String();
    return switch (request.tie) {
      CanonicalWorkoutCursorTie.exclude => query.lt(timestampColumn, timestamp),
      CanonicalWorkoutCursorTie.afterId => query.or(
          '$timestampColumn.lt.$timestamp,and($timestampColumn.eq.$timestamp,id.gt.${request.cursorSessionId!})',
        ),
      CanonicalWorkoutCursorTie.includeAll =>
        query.lte(timestampColumn, timestamp),
    };
  }

  Future<List<Map<String, dynamic>>> personalSets(
    List<String> sessionIds,
  ) async {
    if (sessionIds.isEmpty) return const [];

    final rows = await _client
        .from('workout_exercise_sets')
        .select(personalSetsProjection)
        .inFilter('user_workout_id', sessionIds);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> clubSets(List<String> sessionIds) async {
    if (sessionIds.isEmpty) return const [];

    final rows = await _client
        .from('club_workout_exercise_sets')
        .select(clubSetsProjection)
        .inFilter('user_workout_id', sessionIds);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> exercises(List<String> exerciseIds) async {
    if (exerciseIds.isEmpty) return const [];

    final rows = await _client.from('exercises').select('''
          id, name, exercise_db_id, primary_muscle_group,
          secondary_muscle_groups
        ''').inFilter('id', exerciseIds);
    return List<Map<String, dynamic>>.from(rows);
  }
}
