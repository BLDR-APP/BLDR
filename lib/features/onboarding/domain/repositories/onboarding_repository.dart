import 'package:bldr_fitness/core/errors/result.dart';

abstract class OnboardingRepository {
  /// Gera o plano semanal via HAVOK (edge function gerar-plano-havok).
  /// Payload schemaless — mesmo padrão de HavokRepository.
  Future<Result<Map<String, dynamic>>> generatePlan(
      Map<String, dynamic> onboardingData);

  /// Retorna o `onboarding_data` do perfil do usuário atual.
  Future<Result<Map<String, dynamic>>> getOnboardingData();

  /// Grava as metas nutricionais calculadas/geradas em `onboarding_data`
  /// (a mesma fonte que `NutritionGoalsRepository.getGoals` já lê —
  /// BACKLOG_FUNCIONAL.md B4).
  Future<Result<void>> saveNutritionGoals({
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
  });
}
