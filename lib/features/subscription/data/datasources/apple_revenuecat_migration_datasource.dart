import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AppleRevenueCatMigrationDatasource {
  Future<Map<String, dynamic>> invoke(Map<String, dynamic> body);
  Future<Map<String, dynamic>?> currentState(String userId);
}

class SupabaseAppleRevenueCatMigrationDatasource
    implements AppleRevenueCatMigrationDatasource {
  final SupabaseClient _client;

  const SupabaseAppleRevenueCatMigrationDatasource(this._client);

  @override
  Future<Map<String, dynamic>> invoke(Map<String, dynamic> body) async {
    final response = await _client.functions.invoke(
      'apple-revenuecat-migration',
      body: body,
    );
    final data = response.data;
    if (data is! Map) {
      throw const FormatException('Resposta de migração inválida.');
    }
    return Map<String, dynamic>.from(data);
  }

  @override
  Future<Map<String, dynamic>?> currentState(String userId) async {
    final row = await _client
        .from('apple_revenuecat_migrations')
        .select('status,revenuecat_entitlement_active')
        .eq('user_id', userId)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }
}
