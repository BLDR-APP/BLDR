import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:bldr_fitness/features/subscription/domain/entities/apple_revenuecat_migration.dart';
import 'package:bldr_fitness/features/subscription/domain/repositories/apple_revenuecat_migration_repository.dart';
import 'package:bldr_fitness/features/subscription/domain/repositories/revenue_cat_service.dart';

/// Reconciliação one-shot disparada em background após a identidade RevenueCat
/// estar configurada. A claim server-side é a autoridade de elegibilidade.
class RunAppleRevenueCatMigration {
  final AuthRepository _authRepository;
  final AppleRevenueCatMigrationRepository _migrationRepository;
  final RevenueCatService _revenueCatService;

  const RunAppleRevenueCatMigration(
    this._authRepository,
    this._migrationRepository,
    this._revenueCatService,
  );

  Future<Result<AppleRevenueCatMigrationOutcome>> call() async {
    final userId = _authRepository.currentUser?.id;
    if (userId == null) {
      return const Result.failure(
          AuthFailure('Entre na sua conta para continuar.'));
    }

    final identityBeforeClaim = await _revenueCatService.getCustomerInfo();
    if (identityBeforeClaim.isFailure) {
      return Result.failure(identityBeforeClaim.failureOrNull!);
    }
    if (identityBeforeClaim.valueOrNull?.appUserId != userId) {
      return const Result.failure(
        AuthFailure(
            'A identidade da assinatura não corresponde à sessão atual.'),
      );
    }

    final claimResult = await _migrationRepository.claim();
    if (claimResult.isFailure) {
      return Result.failure(claimResult.failureOrNull!);
    }
    final claim = claimResult.valueOrNull!;
    if (!claim.claimed) {
      return const Result.success(AppleRevenueCatMigrationOutcome.notClaimable);
    }
    final claimId = claim.claimId;
    if (claimId == null || claimId.isEmpty) {
      return const Result.failure(DataFailure('Claim de migração inválido.'));
    }

    if (_authRepository.currentUser?.id != userId) {
      return const Result.failure(
          AuthFailure('A sessão mudou durante a migração.'));
    }
    final identityAfterClaim = await _revenueCatService.getCustomerInfo();
    if (identityAfterClaim.isFailure ||
        identityAfterClaim.valueOrNull?.appUserId != userId) {
      return const Result.failure(
        AuthFailure('A identidade da assinatura mudou durante a migração.'),
      );
    }

    final syncResult =
        await _revenueCatService.syncPurchasesForMigration(eligible: true);
    if (syncResult.isFailure) {
      await _migrationRepository.fail(
        claimId,
        AppleRevenueCatMigrationFailureCode.syncFailed,
      );
      return Result.failure(syncResult.failureOrNull!);
    }
    if (syncResult.valueOrNull?.appUserId != userId) {
      return const Result.failure(
        AuthFailure('A identidade RevenueCat retornada é inválida.'),
      );
    }
    if (_authRepository.currentUser?.id != userId) {
      return const Result.failure(
        AuthFailure('A sessão mudou durante a migração.'),
      );
    }

    // O CustomerInfo do client não concede completion. O backend consulta
    // RevenueCat novamente e persiste apenas a assertion autoritativa.
    final completion = await _migrationRepository.verifyAndComplete(claimId);
    if (completion.isFailure) {
      return Result.failure(completion.failureOrNull!);
    }
    if (completion.valueOrNull != true) {
      return const Result.failure(
        ServerFailure('Não foi possível confirmar a migração da assinatura.'),
      );
    }
    return const Result.success(AppleRevenueCatMigrationOutcome.completed);
  }
}
