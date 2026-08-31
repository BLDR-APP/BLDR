import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:bldr_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:bldr_fitness/features/subscription/domain/repositories/revenue_cat_service.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/run_apple_revenuecat_migration.dart';

class RevenueCatLifecycle {
  final AuthRepository _authRepository;
  final RevenueCatService _service;
  final RunAppleRevenueCatMigration _runAppleMigration;
  StreamSubscription<Object?>? _subscription;
  Future<void> _serial = Future.value();
  String? _migrationAttemptedFor;

  RevenueCatLifecycle(
    this._authRepository,
    this._service,
    this._runAppleMigration,
  );

  Future<void> start() async {
    if (_subscription != null) return;
    _subscription = _authRepository.authStateChanges.listen(
      (user) => unawaited(_enqueueUser(user?.id)),
    );
    await _enqueueUser(_authRepository.currentUser?.id);
  }

  Future<void> _enqueueUser(String? userId) {
    final operation = _serial.then((_) => _handleUser(userId));
    _serial = operation.catchError((_) {});
    return operation;
  }

  Future<void> _handleUser(String? userId) async {
    if (userId == null) _migrationAttemptedFor = null;
    final result = userId == null
        ? await _service.clearSession()
        : await _service.configure(userId);
    if (result.isFailure) {
      final failure = result.failureOrNull!;
      if (kDebugMode) {
        debugPrint('RevenueCat lifecycle: ${failure.message}');
      }
      return;
    }
    if (userId == null ||
        !_service.billingEnabled ||
        !_service.supportsAppleMigration ||
        _authRepository.currentUser?.id != userId ||
        _migrationAttemptedFor == userId) {
      return;
    }
    _migrationAttemptedFor = userId;
    // One-shot server-side: completed/review/failed are not claimable.
    // This runs in the background and never gates app startup or navigation.
    final migration = await _runAppleMigration();
    if (migration.isFailure && kDebugMode) {
      debugPrint(
        'Apple RevenueCat reconciliation: ${migration.failureOrNull!.message}',
      );
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
