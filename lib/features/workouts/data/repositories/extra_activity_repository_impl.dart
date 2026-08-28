import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/activity_type.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/extra_activity.dart';
import 'package:bldr_fitness/features/workouts/domain/repositories/extra_activity_repository.dart';

class ExtraActivityRepositoryImpl implements ExtraActivityRepository {
  final supabase.SupabaseClient _client;
  final String? Function() _currentUserId;

  ExtraActivityRepositoryImpl(this._client, this._currentUserId);

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.success(await action());
    } on Failure catch (f) {
      return Result.failure(f);
    } on supabase.PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message, cause: e));
    } on SocketException catch (e) {
      return Result.failure(NetworkFailure('Sem conexão com a internet.', e));
    } on TimeoutException catch (e) {
      return Result.failure(NetworkFailure('Tempo de conexão esgotado.', e));
    } catch (e) {
      return Result.failure(UnexpectedFailure('Ocorreu um erro inesperado.', e));
    }
  }

  String _requireUser() {
    final uid = _currentUserId();
    if (uid == null) throw const AuthFailure('Usuário não autenticado.');
    return uid;
  }

  @override
  Future<Result<void>> logExtraActivity({
    required DateTime date,
    required ActivityType activityType,
    int? durationMin,
    String? notes,
  }) =>
      _guard(() async {
        final uid = _requireUser();
        const xpEarned = 50;

        await _client.from('extra_activities').insert({
          'user_id': uid,
          'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          'activity_type': activityType.name,
          'duration_min': durationMin,
          'notes': notes,
          'xp_earned': xpEarned,
        });

        // Insere XP no schema bldr_club — silencioso se falhar
        try {
          await _client.schema('bldr_club').from('xp_events').insert({
            'user_id': uid,
            'delta': xpEarned,
            'reason': 'extra_activity',
          });
        } catch (_) {}
      });

  @override
  Future<Result<List<ExtraActivity>>> getExtraActivities(
    DateTime weekStart,
    DateTime weekEnd,
  ) =>
      _guard(() async {
        final uid = _requireUser();
        final rows = await _client
            .from('extra_activities')
            .select('id, user_id, date, activity_type, duration_min, notes, xp_earned, created_at')
            .eq('user_id', uid)
            .gte('date', weekStart.toIso8601String().substring(0, 10))
            .lte('date', weekEnd.toIso8601String().substring(0, 10))
            .order('date');

        return (rows as List).map((r) {
          final dateStr = r['date'] as String;
          final parts = dateStr.split('-');
          return ExtraActivity(
            id: r['id'] as String?,
            userId: r['user_id'] as String,
            date: DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])),
            activityType: ActivityType.fromString(r['activity_type'] as String?),
            durationMin: r['duration_min'] as int?,
            notes: r['notes'] as String?,
            xpEarned: r['xp_earned'] as int? ?? 50,
            createdAt: r['created_at'] != null
                ? DateTime.parse(r['created_at'] as String)
                : null,
          );
        }).toList();
      });
}
