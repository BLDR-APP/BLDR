import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/achievements/domain/entities/achievement.dart';

abstract class AchievementsRepository {
  Future<Result<List<Achievement>>> catalog();

  Future<Result<List<UnlockedAchievement>>> userAchievements(String userId);

  /// Avalia o gatilho ('workout', 'nutrition', 'bldr_club', …) e desbloqueia
  /// o que for atingido. Retorna as conquistas recém-desbloqueadas.
  Future<Result<List<Achievement>>> checkAndUnlock(String triggerType);

  /// Estatísticas usadas para exibir progresso rumo às conquistas de treino
  /// (workout_count, consecutive_days, …). Chaves dinâmicas por natureza.
  Future<Result<Map<String, dynamic>>> workoutContext(String userId);
}
