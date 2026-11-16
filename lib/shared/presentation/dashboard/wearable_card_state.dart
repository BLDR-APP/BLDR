/// Estado do card do WHOOP na Home v2. Função pura — testada.
enum WhoopCardState {
  /// Conexão ainda não verificada — nada é desenhado.
  unknown,

  /// Sem conexão WHOOP: só o card "Conecte seu wearable" (57:382).
  disconnected,

  /// Conectado e sincronizando: skeleton dos anéis.
  syncing,

  /// Conectado, sincronização terminou sem valores (57:381).
  unavailable,

  /// Conectado com dados de hoje (57:384).
  data,
}

WhoopCardState resolveWhoopCardState({
  required bool checked,
  required bool connected,
  required bool syncing,
  required bool hasData,
}) {
  if (!checked) return WhoopCardState.unknown;
  if (!connected) return WhoopCardState.disconnected;
  if (syncing) return WhoopCardState.syncing;
  return hasData ? WhoopCardState.data : WhoopCardState.unavailable;
}
