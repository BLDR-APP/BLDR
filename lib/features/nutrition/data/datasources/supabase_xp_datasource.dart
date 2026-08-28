import 'package:supabase_flutter/supabase_flutter.dart';

/// XP do usuário fica no Supabase (RPC `add_xp_to_user`).
class SupabaseXpDatasource {
  final SupabaseClient _client;

  SupabaseXpDatasource(this._client);

  Future<void> addXp(String userId, int amount, {String? source}) =>
      _client.rpc('add_xp_to_user', params: {
        'p_user_id': userId,
        'p_xp_amount': amount,
        if (source != null) 'p_source': source,
      });
}
