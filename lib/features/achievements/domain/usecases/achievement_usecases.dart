import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/achievements/domain/entities/achievement.dart';
import 'package:bldr_fitness/features/achievements/domain/repositories/achievements_repository.dart';

class GetAchievementCatalog {
  final AchievementsRepository _repo;
  const GetAchievementCatalog(this._repo);

  Future<Result<List<Achievement>>> call() => _repo.catalog();
}

class GetUserAchievements {
  final AchievementsRepository _repo;
  const GetUserAchievements(this._repo);

  Future<Result<List<UnlockedAchievement>>> call(String userId) =>
      _repo.userAchievements(userId);
}

class CheckAndUnlockAchievements {
  final AchievementsRepository _repo;
  const CheckAndUnlockAchievements(this._repo);

  Future<Result<List<Achievement>>> call(String triggerType) =>
      _repo.checkAndUnlock(triggerType);
}

class GetWorkoutAchievementContext {
  final AchievementsRepository _repo;
  const GetWorkoutAchievementContext(this._repo);

  Future<Result<Map<String, dynamic>>> call(String userId) =>
      _repo.workoutContext(userId);
}
