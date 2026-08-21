import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/integrations/domain/entities/whoop_entities.dart';

class WhoopDatasource {
  final SupabaseClient _client;
  final String? Function() _userId;

  WhoopDatasource(this._client, this._userId);

  String get _uid {
    final id = _userId();
    if (id == null) throw const ServerFailure('Usuário não autenticado.');
    return id;
  }

  Future<Result<WhoopConnection>> connectWhoop(String authCode) async {
    try {
      final res = await _client.functions.invoke(
        'whoop-auth',
        body: {'code': authCode},
      );
      if (res.status != 200) {
        final msg = (res.data as Map?)?['error'] ?? 'Falha ao conectar Whoop.';
        return Result.failure(ServerFailure(msg.toString()));
      }
      final data = Map<String, dynamic>.from(res.data as Map);
      return Result.success(WhoopConnection(
        isConnected: data['connected'] == true,
        whoopUserId: data['whoop_user_id']?.toString(),
      ));
    } catch (e) {
      return Result.failure(ServerFailure('Erro ao conectar Whoop: $e'));
    }
  }

  Future<Result<void>> disconnectWhoop() async {
    try {
      await _client.schema('bldr_club').from('whoop_tokens').delete().eq('user_id', _uid);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure('Erro ao desconectar Whoop: $e'));
    }
  }

  Future<Result<WhoopConnection?>> getConnection() async {
    try {
      final res = await _client
          .schema('bldr_club')
          .from('whoop_tokens')
          .select('whoop_user_id, connected_at, expires_at')
          .eq('user_id', _uid)
          .maybeSingle();
      if (res == null) return const Result.success(null);
      return Result.success(WhoopConnection.fromMap(Map<String, dynamic>.from(res)));
    } catch (e) {
      return Result.failure(ServerFailure('Erro ao ler conexão Whoop: $e'));
    }
  }

  Future<Result<WhoopDailyData>> syncTodayData() async {
    try {
      final res = await _client.functions.invoke('whoop-sync', body: {});
      if (res.status != 200) {
        final msg = (res.data as Map?)?['error'] ?? 'Falha ao sincronizar Whoop.';
        return Result.failure(ServerFailure(msg.toString()));
      }
      final data = WhoopDailyData.fromMap(Map<String, dynamic>.from(res.data as Map));
      return Result.success(data);
    } catch (e) {
      return Result.failure(ServerFailure('Erro ao sincronizar Whoop: $e'));
    }
  }

  Future<Result<WhoopDailyData?>> getDataForDate(DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final res = await _client
          .schema('bldr_club')
          .from('whoop_daily_data')
          .select()
          .eq('user_id', _uid)
          .eq('date', dateStr)
          .maybeSingle();
      if (res == null) return const Result.success(null);
      return Result.success(WhoopDailyData.fromMap(Map<String, dynamic>.from(res)));
    } catch (e) {
      return Result.failure(ServerFailure('Erro ao ler dados Whoop: $e'));
    }
  }
}
