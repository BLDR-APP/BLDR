import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/auth/domain/entities/auth_user.dart';
import 'package:bldr_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:bldr_fitness/features/subscription/domain/entities/apple_revenuecat_migration.dart';
import 'package:bldr_fitness/features/subscription/domain/entities/revenue_cat_models.dart';
import 'package:bldr_fitness/features/subscription/domain/repositories/apple_revenuecat_migration_repository.dart';
import 'package:bldr_fitness/features/subscription/domain/repositories/revenue_cat_service.dart';
import 'package:bldr_fitness/features/subscription/domain/repositories/subscription_repository.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/resolve_club_access.dart';
import 'package:bldr_fitness/models/subscription_plan.dart';

const _userId = '194ff474-bf0e-455a-ba3c-e35706d2d9e3';

void main() {
  test('RevenueCat ativo é a autoridade canônica', () async {
    final result = await _resolver(revenueCatActive: true).call();
    expect(result.valueOrNull, isTrue);
  });

  test('Apple completed inactive não preserva acesso legado stale', () async {
    final result = await _resolver(completedInactive: true).call();
    expect(result.valueOrNull, isFalse);
  });

  test('falha/no-evidence preserva acesso legado durante transição', () async {
    final result = await _resolver(migrationStatus: 'failed').call();
    expect(result.valueOrNull, isTrue);
  });

  test('falha RevenueCat não remove acesso legado', () async {
    final result = await _resolver(revenueCatFailure: true).call();
    expect(result.valueOrNull, isTrue);
  });
}

ResolveClubAccess _resolver({
  bool revenueCatActive = false,
  bool completedInactive = false,
  String? migrationStatus,
  bool revenueCatFailure = false,
}) =>
    ResolveClubAccess(
      _Auth(),
      _LegacySubscription(),
      _RevenueCat(active: revenueCatActive, failure: revenueCatFailure),
      _Migration(
        completedInactive
            ? const AppleRevenueCatMigrationState(
                status: 'completed', revenueCatEntitlementActive: false)
            : migrationStatus == null
                ? null
                : AppleRevenueCatMigrationState(
                    status: migrationStatus, revenueCatEntitlementActive: null),
      ),
    );

class _Auth implements AuthRepository {
  @override
  AuthUser? get currentUser =>
      const AuthUser(id: _userId, email: 'test@bldr.app');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LegacySubscription implements SubscriptionRepository {
  @override
  Future<Result<UserSubscription?>> currentSubscription() async =>
      Result.success(
        UserSubscription(
          id: '6410f707-edf9-424e-bcc6-ce7702d6c20d',
          userId: _userId,
          planId: 'plan',
          status: 'active',
          billingPeriod: 'monthly',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RevenueCat implements RevenueCatService {
  final bool active;
  final bool failure;
  const _RevenueCat({required this.active, required this.failure});

  @override
  bool get billingEnabled => true;

  @override
  bool get supportsAppleMigration => true;

  @override
  Future<Result<RevenueCatCustomerInfo>> getCustomerInfo() async => failure
      ? const Result.failure(ServerFailure('offline'))
      : Result.success(RevenueCatCustomerInfo(
          appUserId: _userId,
          hasClubAccess: active,
        ));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Migration implements AppleRevenueCatMigrationRepository {
  final AppleRevenueCatMigrationState? state;
  const _Migration(this.state);

  @override
  Future<Result<AppleRevenueCatMigrationState?>> currentState(
          String userId) async =>
      Result.success(state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
