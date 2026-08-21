import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/services/achievement_service.dart';
import 'package:bldr_fitness/features/achievements/domain/entities/achievement.dart';
import 'package:bldr_fitness/features/achievements/domain/repositories/achievements_repository.dart';

/// Strangler (Fase 5): delega ao AchievementService legado, tipando a borda.
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

Achievement _achievementFromMap(Map<String, dynamic> map) => Achievement(
      id: map['id']?.toString(),
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      category: map['category'] as String?,
      iconName: map['icon_name'] as String?,
      xpValue: (map['xp_value'] as num?)?.toInt(),
      criteriaType: map['criteria_type'] as String?,
      criteriaValue: map['criteria_value'] as num?,
    );

UnlockedAchievement _unlockedFromMap(Map<String, dynamic> map) =>
    UnlockedAchievement(
      id: map['id']?.toString(),
      achievementName: map['achievement_name'] as String? ?? '',
      achievementDescription: map['achievement_description'] as String?,
      achievedAt: DateTime.tryParse(map['achieved_at']?.toString() ?? ''),
    );

class AchievementsRepositoryImpl implements AchievementsRepository {
  final AchievementService _service;

  AchievementsRepositoryImpl(this._service);

  @override
  Future<Result<List<Achievement>>> catalog() => _guard(() async {
        final rows = await _service.getCatalog();
        return rows.map(_achievementFromMap).toList();
      });

  @override
  Future<Result<List<UnlockedAchievement>>> userAchievements(String userId) =>
      _guard(() async {
        final rows = await _service.getUserAchievements(userId);
        return rows.map(_unlockedFromMap).toList();
      });

  @override
  Future<Result<List<Achievement>>> checkAndUnlock(String triggerType) =>
      _guard(() async {
        final rows = await _service.checkAndUnlock(triggerType: triggerType);
        return rows.map(_achievementFromMap).toList();
      });

  @override
  Future<Result<Map<String, dynamic>>> workoutContext(String userId) =>
      _guard(() => _service.getWorkoutContext(userId));
}
