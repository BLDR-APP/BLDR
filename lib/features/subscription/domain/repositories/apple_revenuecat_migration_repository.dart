import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/subscription/domain/entities/apple_revenuecat_migration.dart';

abstract class AppleRevenueCatMigrationRepository {
  Future<Result<AppleRevenueCatMigrationState?>> currentState(String userId);
  Future<Result<AppleRevenueCatMigrationClaim>> claim();
  Future<Result<bool>> verifyAndComplete(String claimId);
  Future<Result<bool>> fail(
    String claimId,
    AppleRevenueCatMigrationFailureCode code,
  );
}
