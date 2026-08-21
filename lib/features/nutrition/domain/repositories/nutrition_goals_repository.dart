import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/nutrition_goals.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/user_goals.dart';

/// Metas nutricionais do usuário (Supabase `user_profiles.onboarding_data`).
abstract class NutritionGoalsRepository {
  Future<Result<NutritionGoals>> getGoals(String userId);
  Future<Result<UserGoals>> getFullGoals(String userId);
  Future<Result<void>> saveFullGoals(String userId, UserGoals goals);
}
