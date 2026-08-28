import 'package:supabase_flutter/supabase_flutter.dart';

/// Lê `onboarding_data` de `user_profiles` (fonte real das metas nutricionais).
class SupabaseNutritionGoalsDatasource {
  final SupabaseClient _client;

  SupabaseNutritionGoalsDatasource(this._client);

  Future<Map<String, dynamic>?> getOnboardingData(String userId) async {
    final row = await _client
        .from('user_profiles')
        .select('onboarding_data')
        .eq('id', userId)
        .maybeSingle();
    final data = row?['onboarding_data'];
    return data is Map ? Map<String, dynamic>.from(data) : null;
  }

  /// Retorna onboarding_data + target_weight_kg + peso atual (último registro).
  Future<Map<String, dynamic>> getFullGoals(String userId) async {
    final profileRow = await _client
        .from('user_profiles')
        .select('onboarding_data, target_weight_kg')
        .eq('id', userId)
        .maybeSingle();

    final obData = profileRow?['onboarding_data'];
    final ob = obData is Map ? Map<String, dynamic>.from(obData) : <String, dynamic>{};

    double? currentWeight;
    try {
      final wRows = await _client
          .from('user_measurements')
          .select('value')
          .eq('user_id', userId)
          .eq('measurement_type', 'weight')
          .order('measured_at', ascending: false)
          .limit(1);
      if ((wRows as List).isNotEmpty) {
        currentWeight = (wRows.first['value'] as num?)?.toDouble();
      }
    } catch (_) {}

    return {
      ...ob,
      'target_weight_kg': profileRow?['target_weight_kg'],
      'current_weight_kg': currentWeight,
    };
  }

  /// Salva macros em onboarding_data e peso alvo + ritmo diretamente.
  Future<void> saveFullGoals(String userId, Map<String, dynamic> goals) async {
    final profileRow = await _client
        .from('user_profiles')
        .select('onboarding_data')
        .eq('id', userId)
        .maybeSingle();

    final current = profileRow?['onboarding_data'];
    final merged = current is Map
        ? Map<String, dynamic>.from(current)
        : <String, dynamic>{};

    merged['target_calories'] = goals['target_calories'];
    merged['target_protein'] = goals['target_protein'];
    merged['target_carbs'] = goals['target_carbs'];
    merged['target_fat'] = goals['target_fat'];
    if (goals.containsKey('goal_pace')) merged['goal_pace'] = goals['goal_pace'];
    if (goals.containsKey('custom_calories')) merged['custom_calories'] = goals['custom_calories'];

    final Map<String, dynamic> update = {'onboarding_data': merged};
    if (goals.containsKey('target_weight_kg')) {
      update['target_weight_kg'] = goals['target_weight_kg'];
    }

    await _client.from('user_profiles').update(update).eq('id', userId);
  }
}
