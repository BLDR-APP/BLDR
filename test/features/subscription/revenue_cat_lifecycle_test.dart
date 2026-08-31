import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/auth/domain/entities/auth_user.dart';
import 'package:bldr_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:bldr_fitness/features/subscription/data/revenue_cat_lifecycle.dart';
import 'package:bldr_fitness/features/subscription/domain/entities/apple_revenuecat_migration.dart';
import 'package:bldr_fitness/features/subscription/domain/entities/revenue_cat_models.dart';
import 'package:bldr_fitness/features/subscription/domain/repositories/apple_revenuecat_migration_repository.dart';
import 'package:bldr_fitness/features/subscription/domain/repositories/revenue_cat_service.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/run_apple_revenuecat_migration.dart';

const _userId = '194ff474-bf0e-455a-ba3c-e35706d2d9e3';
const _claimId = '6410f707-edf9-424e-bcc6-ce7702d6c20d';

void main() {
  test('startup concorrente serializa e sincroniza a claim apenas uma vez',
      () async {
    final auth = _LifecycleAuth();
    final service = _LifecycleRevenueCat();
    final migration = _LifecycleMigration();
    final useCase = RunAppleRevenueCatMigration(auth, migration, service);
    final lifecycle = RevenueCatLifecycle(auth, service, useCase);

    final started = lifecycle.start();
    await service.syncStarted.future;
    auth.emit(_userId);
    service.releaseSync.complete();
    await started;
    await Future<void>.delayed(Duration.zero);

    expect(service.syncCalls, 1);
    expect(migration.claimCalls, 1);
    await lifecycle.dispose();
    await auth.close();
  });

  test('não executa a migração Apple fora do iOS', () async {
    final auth = _LifecycleAuth();
    final service = _LifecycleRevenueCat(supportsAppleMigration: false);
    final migration = _LifecycleMigration();
    final lifecycle = RevenueCatLifecycle(
      auth,
      service,
      RunAppleRevenueCatMigration(auth, migration, service),
    );

    await lifecycle.start();

    expect(migration.claimCalls, 0);
    expect(service.syncCalls, 0);
    await lifecycle.dispose();
    await auth.close();
  });
}

class _LifecycleAuth implements AuthRepository {
  final _controller = StreamController<AuthUser?>.broadcast();
  @override
  AuthUser? currentUser = const AuthUser(id: _userId);

  void emit(String id) {
    currentUser = AuthUser(id: id);
    _controller.add(currentUser);
  }

  Future<void> close() => _controller.close();

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;
  @override
  bool get isAuthenticated => currentUser != null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LifecycleMigration implements AppleRevenueCatMigrationRepository {
  int claimCalls = 0;
  @override
  Future<Result<AppleRevenueCatMigrationState?>> currentState(
    String userId,
  ) async =>
      const Result.success(null);

  @override
  Future<Result<AppleRevenueCatMigrationClaim>> claim() async {
    claimCalls++;
    return Result.success(AppleRevenueCatMigrationClaim(
      claimed: claimCalls == 1,
      claimId: claimCalls == 1 ? _claimId : null,
    ));
  }

  @override
  Future<Result<bool>> verifyAndComplete(String claimId) async =>
      const Result.success(true);
  @override
  Future<Result<bool>> fail(
    String claimId,
    AppleRevenueCatMigrationFailureCode code,
  ) async =>
      const Result.success(true);
}

class _LifecycleRevenueCat implements RevenueCatService {
  final syncStarted = Completer<void>();
  final releaseSync = Completer<void>();
  int syncCalls = 0;
  final bool _supportsAppleMigration;

  _LifecycleRevenueCat({bool supportsAppleMigration = true})
      : _supportsAppleMigration = supportsAppleMigration;

  RevenueCatCustomerInfo get _info => const RevenueCatCustomerInfo(
        appUserId: _userId,
        hasClubAccess: false,
      );

  @override
  Future<Result<void>> configure(String? supabaseUserId) async =>
      const Result<void>.success(null);
  @override
  Future<Result<void>> clearSession() async => const Result<void>.success(null);
  @override
  Future<Result<RevenueCatCustomerInfo>> getCustomerInfo() async =>
      Result.success(_info);
  @override
  Future<Result<RevenueCatCustomerInfo>> syncPurchasesForMigration({
    required bool eligible,
  }) async {
    syncCalls++;
    if (!syncStarted.isCompleted) syncStarted.complete();
    await releaseSync.future;
    return Result.success(_info);
  }

  @override
  bool get billingEnabled => true;

  @override
  bool get supportsAppleMigration => _supportsAppleMigration;
  @override
  Stream<RevenueCatCustomerInfo> get customerInfoUpdates =>
      const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
