/// Estado de rede do aparelho (só "tem alguma interface ativa"; não garante
/// que o backend responda).
abstract class ConnectivityRepository {
  Future<bool> isOnline();

  /// Emite a cada mudança (sem repetir o mesmo estado).
  Stream<bool> onlineChanges();
}
