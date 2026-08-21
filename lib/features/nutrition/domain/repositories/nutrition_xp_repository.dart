import 'package:bldr_fitness/core/errors/result.dart';

/// Gamificação da nutrição: XP por refeição registrada e bônus diário.
abstract class NutritionXpRepository {
  /// XP concedido a cada refeição registrada.
  static const int mealXp = 80;

  /// Bônus por completar as 4 refeições do dia.
  static const int dailyBonusXp = 150;

  Future<Result<void>> awardMealXp(String userId);

  /// Concede o bônus diário uma única vez por dia (trava no Firestore).
  /// Retorna `true` se o bônus foi pago agora, `false` se já havia sido.
  Future<Result<bool>> awardDailyBonusIfNeeded(String userId, DateTime date);
}
