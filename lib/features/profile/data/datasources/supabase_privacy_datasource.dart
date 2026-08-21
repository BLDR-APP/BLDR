import 'package:supabase_flutter/supabase_flutter.dart';

class SupabasePrivacyDatasource {
  final SupabaseClient _client;
  const SupabasePrivacyDatasource(this._client);

  Future<Map<String, dynamic>?> getPrivacy(String userId) async {
    final row = await _client
        .from('user_profiles')
        .select('display_name, photo_visibility, feed_visible, reactions_enabled, ranking_visible')
        .eq('id', userId)
        .maybeSingle();
    return row != null ? Map<String, dynamic>.from(row) : null;
  }

  Future<void> savePrivacy(String userId, Map<String, dynamic> data) async {
    await _client.from('user_profiles').update(data).eq('id', userId);

    // Propaga display_name para club_profiles, se o registro existir.
    final displayName = data['display_name'];
    if (displayName != null) {
      try {
        await _client
            .from('club_profiles')
            .update({'display_name': displayName})
            .eq('user_id', userId);
      } catch (_) {
        // club_profiles pode não ter registro (usuário sem squad) — não é erro fatal.
      }
    }
  }
}
