class AppleRevenueCatMigrationClaim {
  final bool claimed;
  final String? claimId;
  final DateTime? claimExpiresAt;
  final int? attemptCount;
  final String? reason;

  const AppleRevenueCatMigrationClaim({
    required this.claimed,
    this.claimId,
    this.claimExpiresAt,
    this.attemptCount,
    this.reason,
  });
}

enum AppleRevenueCatMigrationOutcome { notClaimable, completed }

enum AppleRevenueCatMigrationFailureCode { syncFailed }

/// Estado server-side da reconciliação Apple. Ele é usado somente para evitar
/// que um registro Apple legado stale continue concedendo Club depois de uma
/// prova RevenueCat autoritativa de entitlement inativo.
class AppleRevenueCatMigrationState {
  final String status;
  final bool? revenueCatEntitlementActive;

  const AppleRevenueCatMigrationState({
    required this.status,
    required this.revenueCatEntitlementActive,
  });

  bool get completedInactive =>
      status == 'completed' && revenueCatEntitlementActive == false;
}
