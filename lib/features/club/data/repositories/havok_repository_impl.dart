import 'dart:async';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/club/domain/entities/havok_thread.dart';
import 'package:bldr_fitness/features/club/domain/entities/havok_workout.dart';
import 'package:bldr_fitness/features/club/domain/repositories/havok_repository.dart';
import 'package:bldr_fitness/core/providers/locale_provider.dart';
import 'package:get_it/get_it.dart';

class HavokRepositoryImpl implements HavokRepository {
  final supabase.SupabaseClient _client;
  final String? Function() _currentUserId;

  HavokRepositoryImpl(this._client, this._currentUserId);

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.success(await action());
    } on Failure catch (f) {
      return Result.failure(f);
    } on supabase.PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message, cause: e));
    } on supabase.FunctionException catch (e) {
      return Result.failure(
          ServerFailure('Erro na geração HAVOK (${e.status}).', cause: e));
    } on SocketException catch (e) {
      return Result.failure(NetworkFailure('Sem conexão com a internet.', e));
    } on TimeoutException catch (e) {
      return Result.failure(NetworkFailure('Tempo de conexão esgotado.', e));
    } catch (e) {
      return Result.failure(
          UnexpectedFailure('Ocorreu um erro inesperado.', e));
    }
  }

  String _requireUser() {
    final uid = _currentUserId();
    if (uid == null) throw const AuthFailure('Usuário não autenticado.');
    return uid;
  }

  Future<Map<String, dynamic>> _invoke(String fn,
      {Map<String, dynamic>? body}) async {
    final response = await _client.functions.invoke(fn, body: body);
    if (response.status != 200) {
      throw ServerFailure('Falha na função $fn (${response.status}).');
    }
    final data = response.data;
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  @override
  Future<Result<Map<String, dynamic>>> generateFreeWorkout(String userPrompt) =>
      _guard(() =>
          _invoke('gerar-treino-livre', body: {'userPrompt': userPrompt}));

  @override
  Future<Result<SavedWorkout>> generateHavokWorkout() => _guard(() async {
        final locale = GetIt.instance<LocaleProvider>().locale.languageCode;
        final map =
            await _invoke('gerar-treino-havok', body: {'locale': locale});
        return SavedWorkout.fromMap(map);
      });

  @override
  Future<Result<Map<String, dynamic>>> generateRecipe(String userQuery) =>
      _guard(
          () => _invoke('gerar-receita-havok', body: {'userQuery': userQuery}));

  @override
  Future<Result<void>> saveRecipe(Map<String, dynamic> recipeData) => _guard(
      () => _invoke('salvar-receita-havok', body: {'recipeData': recipeData}));

  @override
  Future<Result<List<Map<String, dynamic>>>> myRecipes() => _guard(() async {
        final rows = await _client
            .schema('bldr_club')
            .from('havok_recipes')
            .select()
            .eq('user_id', _requireUser())
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(rows);
      });

  @override
  Future<Result<List<Map<String, dynamic>>>> myWorkouts() => _guard(() async {
        final rows = await _client
            .schema('bldr_club')
            .from('havok_workouts')
            .select()
            .eq('user_id', _requireUser())
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(rows);
      });

  // --- Conversa ---

  bool _isToday(DateTime dt) {
    final local = dt.toLocal();
    final now = DateTime.now();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  @override
  Future<Result<HavokThread>> getOrCreateTodayThread(String originScreen) =>
      _guard(() async {
        final uid = _requireUser();
        final rows = await _client
            .schema('bldr_club')
            .from('havok_threads')
            .select()
            .eq('user_id', uid)
            .order('created_at', ascending: false)
            .limit(1);
        final latest = (rows as List).isNotEmpty
            ? Map<String, dynamic>.from(rows.first as Map)
            : null;

        if (latest != null && _isToday(DateTime.parse(latest['created_at']))) {
          return HavokThread.fromMap(latest);
        }

        final inserted = await _client
            .schema('bldr_club')
            .from('havok_threads')
            .insert({'user_id': uid, 'origin_screen': originScreen})
            .select()
            .single();
        return HavokThread.fromMap(Map<String, dynamic>.from(inserted));
      });

  @override
  Future<Result<List<HavokMessage>>> getThreadMessages(String threadId) =>
      _guard(() async {
        final rows = await _client
            .schema('bldr_club')
            .from('havok_messages')
            .select()
            .eq('thread_id', threadId)
            .order('created_at', ascending: true);
        return (rows as List)
            .map((r) =>
                HavokMessage.fromMap(Map<String, dynamic>.from(r as Map)))
            .toList();
      });

  @override
  Future<Result<HavokMessage>> sendMessage({
    required String threadId,
    required String userMessage,
    required String originScreen,
    required Map<String, dynamic> context,
  }) =>
      _guard(() async {
        final map = await _invoke('gerar-resposta-havok', body: {
          'threadId': threadId,
          'userMessage': userMessage,
          'originScreen': originScreen,
          'context': context,
        });
        await _client.schema('bldr_club').from('havok_threads').update({
          'last_message_at': DateTime.now().toUtc().toIso8601String()
        }).eq('id', threadId);
        return HavokMessage.fromMap(map);
      });

  @override
  Future<Result<void>> dismissInsight(DateTime date) => _guard(() async {
        final prefs = await SharedPreferences.getInstance();
        final key = 'havok_insight_dismissed_'
            '${date.year}-${date.month.toString().padLeft(2, '0')}-'
            '${date.day.toString().padLeft(2, '0')}';
        await prefs.setBool(key, true);
      });

  @override
  Future<Result<int>> getDailyMessageCount() => _guard(() async {
        final rows = await _client
            .schema('bldr_club')
            .from('havok_daily_usage')
            .select('message_count')
            .single();
        return (rows['message_count'] as num?)?.toInt() ?? 0;
      });

  @override
  Future<Result<List<HavokMemory>>> getMemories() => _guard(() async {
        final rows = await _client
            .schema('bldr_club')
            .from('havok_memories')
            .select()
            .eq('user_id', _requireUser())
            .eq('active', true)
            .order('updated_at', ascending: false);
        return (rows as List)
            .map((row) =>
                HavokMemory.fromMap(Map<String, dynamic>.from(row as Map)))
            .toList();
      });

  @override
  Future<Result<void>> updateMemory(HavokMemory memory, dynamic value) =>
      _guard(() async {
        await _client
            .schema('bldr_club')
            .from('havok_memories')
            .update({
              'value': value,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', memory.id)
            .eq('user_id', _requireUser());
      });

  @override
  Future<Result<void>> forgetMemory(String memoryId) => _guard(() async {
        await _client
            .schema('bldr_club')
            .from('havok_memories')
            .update({
              'active': false,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', memoryId)
            .eq('user_id', _requireUser());
      });

  @override
  Future<Result<void>> clearMemories() => _guard(() async {
        await _client
            .schema('bldr_club')
            .from('havok_memories')
            .update({
              'active': false,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('user_id', _requireUser())
            .eq('active', true);
      });
}
