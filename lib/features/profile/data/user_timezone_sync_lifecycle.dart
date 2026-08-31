import 'dart:async';

import 'package:bldr_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:bldr_fitness/features/profile/domain/usecases/user_timezone_usecases.dart';

/// Mantém o timezone IANA do perfil alinhado ao dispositivo a cada sessão.
/// Falhas são não bloqueantes: usuários legados continuam com fallback UTC.
class UserTimezoneSyncLifecycle {
  UserTimezoneSyncLifecycle(this._auth, this._sync);

  final AuthRepository _auth;
  final SyncDeviceTimezone _sync;
  StreamSubscription? _subscription;

  Future<void> start() async {
    final current = _auth.currentUser;
    if (current != null) unawaited(_sync(current.id));
    _subscription ??= _auth.authStateChanges.listen((user) {
      if (user != null) unawaited(_sync(user.id));
    });
  }

  Future<void> dispose() async => _subscription?.cancel();
}
