import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:bldr_fitness/features/subscription/domain/repositories/apple_revenuecat_migration_repository.dart';
import 'package:bldr_fitness/features/subscription/domain/repositories/revenue_cat_service.dart';
import 'package:bldr_fitness/features/subscription/domain/repositories/subscription_repository.dart';

/// Fonte canônica de acesso Club durante o cutover.
///
/// RevenueCat ativo sempre concede acesso. Um Apple legado somente deixa de
/// conceder acesso quando a reconciliação server-side terminou com evidência
/// positiva de entitlement inativo; estados elegível/falhado/revisão preservam
/// o acesso legado para não causar remoção indevida durante a transição.
class ResolveClubAccess {
  final AuthRepository _auth;
  final SubscriptionRepository _legacySubscriptions;
  final RevenueCatService _revenueCat;
  final AppleRevenueCatMigrationRepository _appleMigration;

  const ResolveClubAccess(
    this._auth,
    this._legacySubscriptions,
    this._revenueCat,
    this._appleMigration,
  );

  Future<Result<bool>> call() async {
    final userId = _auth.currentUser?.id;
    if (userId == null) return const Result.success(false);

    final legacyResult = await _legacySubscriptions.currentSubscription();
    if (legacyResult.isFailure) {
      return Result.failure(legacyResult.failureOrNull!);
    }
    final legacyAccess = legacyResult.valueOrNull?.hasClubAccess ?? false;

    if (!_revenueCat.billingEnabled) return Result.success(legacyAccess);

    final revenueCat = await _revenueCat.getCustomerInfo();
    // A indisponibilidade de RevenueCat nunca remove acesso legado durante a
    // transição. Novas contas, sem legado, continuam sem acesso.
    if (revenueCat.isFailure) return Result.success(legacyAccess);
    if (revenueCat.valueOrNull?.hasClubAccess == true) {
      return const Result.success(true);
    }
    if (!legacyAccess) return const Result.success(false);

    final state = await _appleMigration.currentState(userId);
    if (state.isFailure) return Result.success(true);
    return Result.success(!(state.valueOrNull?.completedInactive ?? false));
  }
}
