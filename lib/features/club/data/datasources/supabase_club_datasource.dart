import 'package:supabase_flutter/supabase_flutter.dart';

/// Queries do BLDR Club que antes viviam nas telas.
/// Não trata erros — exceções sobem para o repository.
class SupabaseClubDatasource {
  final SupabaseClient _client;

  SupabaseClubDatasource(this._client);

  Future<List<Map<String, dynamic>>> publicTemplates({int limit = 50}) async {
    final rows = await _client
        .from('club_workout_templates')
        .select(
            'id, name, workout_type, estimated_duration_minutes, difficulty_level, is_public')
        .eq('is_public', true)
        .order('name', ascending: true)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Exercícios de um template com nomes resolvidos da tabela `exercises`.
  Future<List<Map<String, dynamic>>> templateExercises(
      String templateId) async {
    final rows = await _client
        .from('club_workout_template_exercises')
        .select(
            'id, exercise_id, order_index, sets, reps, duration_seconds, rest_seconds')
        .eq('workout_template_id', templateId)
        .order('order_index', ascending: true);
    final rawList = List<Map<String, dynamic>>.from(rows);

    final ids = rawList
        .map((m) => (m['exercise_id'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    final namesById = <String, String>{};
    if (ids.isNotEmpty) {
      final orCond = ids.map((id) => 'id.eq.$id').join(',');
      final exRes =
          await _client.from('exercises').select('id, name').or(orCond);
      for (final m in (exRes as List)) {
        namesById[(m['id'] ?? '').toString()] =
            (m['name'] ?? 'Exercício').toString();
      }
    }

    return rawList
        .map((m) => {
              ...m,
              'exercises': {
                'id': m['exercise_id'],
                'name': namesById[(m['exercise_id'] ?? '').toString()] ??
                    'Exercício',
              },
            })
        .toList();
  }

  /// Treinos do Club no intervalo, SEM filtrar is_completed (a tela usa
  /// treinos em andamento para inferir o tipo de atividade do dia).
  Future<List<Map<String, dynamic>>> clubWorkoutsBetween(
      String userId, DateTime start, DateTime end) async {
    final rows = await _client
        .from('club_user_workouts')
        .select('id, name, completed_at, started_at, notes')
        .eq('user_id', userId)
        .gte('started_at', start.toIso8601String())
        .lt('started_at', end.toIso8601String());
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> activitiesBetween(
      String userId, DateTime start, DateTime end) async {
    final rows = await _client
        .schema('bldr_club')
        .from('user_activities')
        .select('id, created_at, activity_type')
        .eq('user_id', userId)
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String());
    return List<Map<String, dynamic>>.from(rows);
  }

  // ── Corrida (GPS) ──

  Future<List<Map<String, dynamic>>> userActivities(String userId,
      {int? limit}) async {
    var q = _client
        .schema('bldr_club')
        .from('user_activities')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    final rows = limit != null ? await q.limit(limit) : await q;
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> insertRunActivity(Map<String, dynamic> data) => _client
      .schema('bldr_club')
      .from('user_activities')
      .insert(data);

  Future<void> insertXpEvent(String userId, int delta, String reason) =>
      _client.schema('bldr_club').from('xp_events').insert({
        'user_id': userId,
        'delta': delta,
        'reason': reason,
      });

  Future<void> addXp(String userId, int amount, {String? source}) =>
      _client.rpc('add_xp_to_user', params: {
        'p_user_id': userId,
        'p_xp_amount': amount,
        if (source != null) 'p_source': source,
      });

  Future<void> insertMatchSession(Map<String, dynamic> data) => _client
      .schema('bldr_club')
      .from('match_sessions')
      .insert(data);

  Future<List<Map<String, dynamic>>> matchSessions(String userId,
      {int limit = 50}) async {
    final rows = await _client
        .schema('bldr_club')
        .from('match_sessions')
        .select()
        .eq('user_id', userId)
        .order('played_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  // ── Operação da Semana ──

  Future<Map<String, dynamic>?> currentOperation() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await _client
        .schema('bldr_club')
        .from('weekly_operations')
        .select()
        .lte('week_start', today)
        .gte('week_end', today)
        .limit(1);
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  Future<Map<String, dynamic>?> operationProgress(
      String userId, String operationId) async {
    final rows = await _client
        .schema('bldr_club')
        .from('operation_progress')
        .select()
        .eq('user_id', userId)
        .eq('operation_id', operationId)
        .limit(1);
    return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
  }

  Future<void> upsertOperationProgress({
    required String userId,
    required String operationId,
    required int newValue,
    required bool completed,
  }) =>
      _client.schema('bldr_club').from('operation_progress').upsert(
        {
          'user_id': userId,
          'operation_id': operationId,
          'current_value': newValue,
          'completed': completed,
          if (completed) 'completed_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id,operation_id',
      );

  Future<int> xpBetween(String userId, DateTime start, DateTime end) async {
    final rows = await _client
        .schema('bldr_club')
        .from('xp_events')
        .select('delta')
        .eq('user_id', userId)
        .gte('created_at', start.toIso8601String())
        .lt('created_at', end.toIso8601String());
    var total = 0;
    for (final row in (rows as List)) {
      total += ((row['delta'] as num?) ?? 0).toInt();
    }
    return total;
  }
}
