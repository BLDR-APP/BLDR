import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseWearableActivityDatasource {
  final SupabaseClient _client;

  const SupabaseWearableActivityDatasource(this._client);

  Future<Map<String, dynamic>> activity(String activityId) async {
    final row = await _client
        .from('wearable_activities')
        .select()
        .eq('id', activityId)
        .single();
    return Map<String, dynamic>.from(row);
  }

  Future<Map<String, dynamic>> prepareWorkout({
    required String activityId,
    String? templateId,
    required String source,
  }) async {
    final response = await _client.rpc('prepare_wearable_workout', params: {
      'p_activity_id': activityId,
      'p_template_id': templateId,
      'p_source': source,
    });
    final rows = List<Map<String, dynamic>>.from(response as List);
    if (rows.isEmpty) throw StateError('Treino não foi preparado.');
    return rows.first;
  }

  Future<void> markConfirmed(String activityId) =>
      _client.rpc('confirm_wearable_activity', params: {
        'p_activity_id': activityId,
      });

  Future<void> dismiss(String activityId) =>
      _client.rpc('dismiss_wearable_activity', params: {
        'p_activity_id': activityId,
      });
}
