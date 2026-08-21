import 'dart:typed_data';

import 'package:bldr_fitness/core/errors/result.dart';

/// Squads/Arenas, Tribunal (check-ins com prova + votação) e chat.
///
/// TRANSITÓRIO (Fase 6c): os métodos trafegam linhas cruas
/// (`Map<String, dynamic>`) em vez de entidades — a tipagem fica como dívida
/// registrada no ARCHITECTURE.md. As telas desta cauda consomem o contrato
/// diretamente via getIt (sem camada de use cases), decisão tomada para
/// conter o custo da migração da cauda.
abstract class ArenaRepository {
  // ── Arena / Squad ──

  Future<Result<Map<String, dynamic>?>> arenaById(String arenaId);

  Future<Result<Map<String, dynamic>?>> findArenaByCode(String code);

  Future<Result<bool>> isParticipant(String arenaId);

  /// Entra na arena (upsert; vidas iniciais dependem do modo survivor).
  Future<Result<void>> joinArena(String arenaId, {required String gameMode});

  /// Cria a arena e inscreve o criador. Retorna a linha criada.
  Future<Result<Map<String, dynamic>>> createArena(
      Map<String, dynamic> payload,
      {required String gameMode});

  Future<Result<void>> updateArena(
      String arenaId, Map<String, dynamic> updates);

  Future<Result<void>> leaveArena(String arenaId);

  Future<Result<void>> kickMember(String arenaId, String userId);

  Future<Result<void>> deleteArenaTotally(String arenaId);

  /// Participantes ordenados por vidas/pontos, com nome/avatar anexados
  /// (chaves extras: `name`, `avatar`).
  Future<Result<List<Map<String, dynamic>>>> participantsCombined(
      String arenaId, {required String orderBy});

  /// Membros com `user_id`, `status`, `name`, `avatar`.
  Future<Result<List<Map<String, dynamic>>>> membersCombined(String arenaId);

  /// Arenas em que o usuário participa (linhas de `arenas`).
  Future<Result<List<Map<String, dynamic>>>> mySquads();

  /// Arena ativa mais recente do usuário (survivor card), ou null.
  Future<Result<Map<String, dynamic>?>> myActiveSquadArena();

  // ── Tribunal / check-ins ──

  Future<Result<String>> validationType(String arenaId);

  /// Posts do tribunal com `tribunal_votes` embutidos e `user_profiles`
  /// anexado por post.
  Future<Result<List<Map<String, dynamic>>>> tribunalFeed(String arenaId);

  /// Histórico de check-ins (exclui mensagens de chat), com `user_profiles`.
  Future<Result<List<Map<String, dynamic>>>> arenaHistory(String arenaId);

  Future<Result<void>> sendChatMessage(String arenaId, String text);

  /// Sobe a prova e cria o post (status 'chat' em arenas de honra).
  Future<Result<void>> postPhotoProof({
    required String arenaId,
    required Uint8List bytes,
    required String fileExt,
    required String caption,
    required bool isHonorMode,
  });

  Future<Result<void>> vote(String postId, {required bool isValid});

  /// Check-in estruturado (atividade + métricas + XP), com upload opcional.
  Future<Result<void>> submitCheckin({
    required String arenaId,
    String? imagePath,
    required Map<String, dynamic> post,
  });

  /// Posts de hoje do usuário na arena (para bônus/trava de XP).
  Future<Result<List<Map<String, dynamic>>>> myTodayPosts(String arenaId);

  /// Status do check-in de hoje ('pending'/'approved'/...) ou null.
  Future<Result<String?>> todayCheckinStatus(String arenaId);

  // ── Streams realtime (slider do hub) ──

  Stream<List<Map<String, dynamic>>> myParticipationStream();

  Stream<List<Map<String, dynamic>>> recentDuelsStream({int limit = 50});
}
