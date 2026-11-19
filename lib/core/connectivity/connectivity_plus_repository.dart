import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:bldr_fitness/core/connectivity/connectivity_repository.dart';

class ConnectivityPlusRepository implements ConnectivityRepository {
  ConnectivityPlusRepository([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _online(List<ConnectivityResult> r) =>
      r.any((e) => e != ConnectivityResult.none);

  @override
  Future<bool> isOnline() async {
    try {
      return _online(await _connectivity.checkConnectivity());
    } catch (_) {
      return true; // na dúvida, não acusa offline
    }
  }

  @override
  Stream<bool> onlineChanges() =>
      _connectivity.onConnectivityChanged.map(_online).distinct();
}
