import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/club/domain/entities/havok_thread.dart';
import 'package:bldr_fitness/features/club/domain/entities/havok_workout.dart';

/// Conteúdo gerado por IA do HAVOK (treinos e receitas).
///
/// Os payloads são schemaless por natureza (saída do modelo) — por isso os
/// métodos trafegam `Map<String, dynamic>` documentadamente.
abstract class HavokRepository {
  /// Gera um treino a partir de um pedido livre do usuário.
  Future<Result<Map<String, dynamic>>> generateFreeWorkout(String userPrompt);

  /// Gera o treino HAVOK do dia (salvo pela edge function).
  ///
  /// A edge function já devolve a linha recém-inserida de `havok_workouts` —
  /// retornamos esse dado direto em vez de descartá-lo e fazer um SELECT
  /// adicional em seguida (dívida técnica HAVOK_SPEC.md §10).
  Future<Result<SavedWorkout>> generateHavokWorkout();

  Future<Result<Map<String, dynamic>>> generateRecipe(String userQuery);

  Future<Result<void>> saveRecipe(Map<String, dynamic> recipeData);

  /// Linhas cruas de bldr_club.havok_recipes do usuário.
  Future<Result<List<Map<String, dynamic>>>> myRecipes();

  /// Linhas cruas de bldr_club.havok_workouts do usuário.
  Future<Result<List<Map<String, dynamic>>>> myWorkouts();

  // --- Conversa (HAVOK_SPEC.md §4) ---

  /// Thread de hoje do usuário — cria uma nova se a última for de outro dia
  /// ou não existir ainda. `originScreen` é salvo só na criação (marca de
  /// onde a conversa nasceu, para o divisor de contexto no histórico).
  Future<Result<HavokThread>> getOrCreateTodayThread(String originScreen);

  /// Mensagens da thread, ordenadas por `created_at` ascendente.
  Future<Result<List<HavokMessage>>> getThreadMessages(String threadId);

  /// Envia a mensagem do usuário, persiste-a junto com a resposta do
  /// assistente (gerada pela edge function com o histórico da thread + o
  /// contexto do usuário já lido no Flutter) e retorna a mensagem gerada.
  Future<Result<HavokMessage>> sendMessage({
    required String threadId,
    required String userMessage,
    required String originScreen,
    required Map<String, dynamic> context,
  });

  /// Memória local (não é dado de servidor) de que o card de insight foi
  /// dispensado na data informada — HAVOK_SPEC.md §3.1.
  Future<Result<void>> dismissInsight(DateTime date);

  /// Conta as mensagens `role='user'` do usuário atual no HAVOK hoje.
  /// Usado para aplicar o limite de 10 msg/dia no plano Free.
  Future<Result<int>> getDailyMessageCount();

  /// Memórias persistentes do usuário autenticado, nunca métricas voláteis.
  Future<Result<List<HavokMemory>>> getMemories();
  Future<Result<void>> updateMemory(HavokMemory memory, dynamic value);
  Future<Result<void>> forgetMemory(String memoryId);
  Future<Result<void>> clearMemories();
}
