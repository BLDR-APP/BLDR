import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/auth/domain/entities/auth_user.dart';
import 'package:bldr_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:bldr_fitness/features/subscription/domain/entities/apple_revenuecat_migration.dart';
import 'package:bldr_fitness/features/subscription/domain/entities/revenue_cat_models.dart';
import 'package:bldr_fitness/features/subscription/domain/repositories/apple_revenuecat_migration_repository.dart';
import 'package:bldr_fitness/features/subscription/domain/repositories/revenue_cat_service.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/run_apple_revenuecat_migration.dart';

const userId = '194ff474-bf0e-455a-ba3c-e35706d2d9e3';
const claimId = '6410f707-edf9-424e-bcc6-ce7702d6c20d';

void main() {
  test('não sincroniza quando backend não concede claim', () async {
    final migration = FakeMigrationRepository(claimed: false);
    final revenueCat = FakeRevenueCatService();
    final useCase = RunAppleRevenueCatMigration(
      FakeAuthRepository(userId),
      migration,
      revenueCat,
    );

    final result = await useCase();

    expect(result.valueOrNull, AppleRevenueCatMigrationOutcome.notClaimable);
    expect(revenueCat.syncCalls, 0);
    expect(revenueCat.restoreCalls, 0);
  });

  test('claim viva permite sync e completion autoritativa no backend',
      () async {
    final migration = FakeMigrationRepository(claimed: true);
    final revenueCat = FakeRevenueCatService();
    final useCase = RunAppleRevenueCatMigration(
      FakeAuthRepository(userId),
      migration,
      revenueCat,
    );

    final result = await useCase();

    expect(result.valueOrNull, AppleRevenueCatMigrationOutcome.completed);
    expect(revenueCat.syncCalls, 1);
    expect(migration.verifyCalls, [claimId]);
    expect(migration.failCalls, isEmpty);
    expect(revenueCat.restoreCalls, 0);
  });

  test('exception no sync solicita fail com código fechado', () async {
    final migration = FakeMigrationRepository(claimed: true);
    final revenueCat = FakeRevenueCatService(syncFailure: true);
    final useCase = RunAppleRevenueCatMigration(
      FakeAuthRepository(userId),
      migration,
      revenueCat,
    );

    final result = await useCase();

    expect(result.isFailure, isTrue);
    expect(migration.verifyCalls, isEmpty);
    expect(
        migration.failCalls, [AppleRevenueCatMigrationFailureCode.syncFailed]);
  });

  test('identidade RevenueCat divergente bloqueia antes do claim', () async {
    final migration = FakeMigrationRepository(claimed: true);
    final revenueCat = FakeRevenueCatService(
      appUserId: '4a4ed139-5f98-46b8-8648-b7f6dc8d628c',
    );
    final useCase = RunAppleRevenueCatMigration(
      FakeAuthRepository(userId),
      migration,
      revenueCat,
    );

    final result = await useCase();

    expect(result.isFailure, isTrue);
    expect(migration.claimCalls, 0);
    expect(revenueCat.syncCalls, 0);
  });

  test('logout durante sync bloqueia verificação backend tardia', () async {
    final auth = FakeAuthRepository(userId);
    final migration = FakeMigrationRepository(claimed: true);
    final revenueCat =
        FakeRevenueCatService(onSync: () => auth.currentUser = null);
    final useCase = RunAppleRevenueCatMigration(auth, migration, revenueCat);

    final result = await useCase();

    expect(result.isFailure, isTrue);
    expect(revenueCat.syncCalls, 1);
    expect(migration.verifyCalls, isEmpty);
  });
}

class FakeAuthRepository implements AuthRepository {
  @override
  AuthUser? currentUser;

  FakeAuthRepository(String? id)
      : currentUser = id == null ? null : AuthUser(id: id);

  @override
  bool get isAuthenticated => currentUser != null;

  @override
  Stream<AuthUser?> get authStateChanges => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMigrationRepository implements AppleRevenueCatMigrationRepository {
  final bool claimed;
  int claimCalls = 0;
  final List<String> verifyCalls = [];
  final List<AppleRevenueCatMigrationFailureCode> failCalls = [];

  FakeMigrationRepository({required this.claimed});

  @override
  Future<Result<AppleRevenueCatMigrationState?>> currentState(
    String userId,
  ) async =>
      const Result.success(null);

  @override
  Future<Result<AppleRevenueCatMigrationClaim>> claim() async {
    claimCalls++;
    return Result.success(AppleRevenueCatMigrationClaim(
      claimed: claimed,
      claimId: claimed ? claimId : null,
    ));
  }

  @override
  Future<Result<bool>> verifyAndComplete(String claimId) async {
    verifyCalls.add(claimId);
    return const Result.success(true);
  }

  @override
  Future<Result<bool>> fail(
    String claimId,
    AppleRevenueCatMigrationFailureCode code,
  ) async {
    failCalls.add(code);
    return const Result.success(true);
  }
}

class FakeRevenueCatService implements RevenueCatService {
  final String appUserId;
  final bool syncFailure;
  final void Function()? onSync;
  int syncCalls = 0;
  int restoreCalls = 0;

  FakeRevenueCatService({
    this.appUserId = userId,
    this.syncFailure = false,
    this.onSync,
  });

  @override
  bool get billingEnabled => true;

  @override
  bool get supportsAppleMigration => true;

  @override
  Stream<RevenueCatCustomerInfo> get customerInfoUpdates =>
      const Stream.empty();

  @override
  Future<Result<RevenueCatCustomerInfo>> getCustomerInfo() async =>
      Result.success(RevenueCatCustomerInfo(
        appUserId: appUserId,
        hasClubAccess: false,
      ));

  @override
  Future<Result<RevenueCatCustomerInfo>> syncPurchasesForMigration({
    required bool eligible,
  }) async {
    syncCalls++;
    onSync?.call();
    if (syncFailure) {
      return const Result.failure(ServerFailure('sync failed'));
    }
    return Result.success(RevenueCatCustomerInfo(
      appUserId: appUserId,
      hasClubAccess: true,
    ));
  }

  @override
  Future<Result<RevenueCatCustomerInfo>> restorePurchases() async {
    restoreCalls++;
    return getCustomerInfo();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
