import 'package:supabase_flutter/supabase_flutter.dart';

abstract class CanonicalHealthReadDatasource {
  Future<bool> hasWhoopConnection(String userId);

  Future<List<Map<String, dynamic>>> whoopDaily({
    required String userId,
    required DateTime start,
    required DateTime end,
    DateTime? beforeDate,
    required int limit,
  });
}

class CanonicalHealthDatasource implements CanonicalHealthReadDatasource {
  final SupabaseClient _client;

  CanonicalHealthDatasource(this._client);

  @override
  Future<bool> hasWhoopConnection(String userId) async {
    final row = await _client
        .schema('bldr_club')
        .from('whoop_tokens')
        .select('user_id')
        .eq('user_id', userId)
        .maybeSingle();
    return row != null;
  }

  @override
  Future<List<Map<String, dynamic>>> whoopDaily({
    required String userId,
    required DateTime start,
    required DateTime end,
    DateTime? beforeDate,
    required int limit,
  }) async {
    var query = _client
        .schema('bldr_club')
        .from('whoop_daily_data')
        .select('''
      id, user_id, date, recovery_score, hrv_rmssd, resting_hr, strain_score,
      sleep_score, sleep_duration, synced_at
    ''')
        .eq('user_id', userId)
        .gte('date', start.toIso8601String().split('T').first)
        .lt('date', end.toIso8601String().split('T').first);
    if (beforeDate != null) {
      query = query.lt('date', beforeDate.toIso8601String().split('T').first);
    }
    final rows = await query.order('date', ascending: false).limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }
}
