import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/subscription/data/datasources/apple_revenuecat_migration_datasource.dart';
import 'package:bldr_fitness/features/subscription/domain/entities/apple_revenuecat_migration.dart';
import 'package:bldr_fitness/features/subscription/domain/repositories/apple_revenuecat_migration_repository.dart';

class AppleRevenueCatMigrationRepositoryImpl
    implements AppleRevenueCatMigrationRepository {
  final AppleRevenueCatMigrationDatasource _datasource;

  const AppleRevenueCatMigrationRepositoryImpl(this._datasource);

  @override
  Future<Result<AppleRevenueCatMigrationState?>> currentState(String userId) =>
      _guard(() async {
        final data = await _datasource.currentState(userId);
        if (data == null) return null;
        return AppleRevenueCatMigrationState(
          status: data['status']?.toString() ?? '',
          revenueCatEntitlementActive:
              data['revenuecat_entitlement_active'] as bool?,
        );
      });

  @override
  Future<Result<AppleRevenueCatMigrationClaim>> claim() => _guard(() async {
        final data = await _datasource.invoke({'operation': 'claim'});
        final claimed = data['claimed'] == true;
        return AppleRevenueCatMigrationClaim(
          claimed: claimed,
          claimId: data['claim_id'] as String?,
          claimExpiresAt: DateTime.tryParse(
            data['claim_expires_at']?.toString() ?? '',
          ),
          attemptCount: (data['attempt_count'] as num?)?.toInt(),
          reason: data['reason'] as String?,
        );
      });

  @override
  Future<Result<bool>> verifyAndComplete(String claimId) => _guard(() async {
        final data = await _datasource.invoke({
          'operation': 'verify_and_complete',
          'claim_id': claimId,
        });
        return data['completed'] == true;
      });

  @override
  Future<Result<bool>> fail(
    String claimId,
    AppleRevenueCatMigrationFailureCode code,
  ) =>
      _guard(() async {
        final data = await _datasource.invoke({
          'operation': 'fail',
          'claim_id': claimId,
          'error_code': switch (code) {
            AppleRevenueCatMigrationFailureCode.syncFailed => 'RC_SYNC_FAILED',
          },
        });
        return data['failed'] == true;
      });

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.success(await action());
    } on FunctionException catch (error) {
      if (error.status == 401) {
        return Result.failure(
            AuthFailure('Sessão inválida ou expirada.', cause: error));
      }
      if (error.status == 409) {
        return Result.failure(ValidationFailure(
          'A migração não pode continuar neste estado.',
          cause: error,
        ));
      }
      return Result.failure(ServerFailure(
        'Não foi possível coordenar a migração da assinatura.',
        cause: error,
      ));
    } on SocketException catch (error) {
      return Result.failure(
          NetworkFailure('Sem conexão com a internet.', error));
    } on TimeoutException catch (error) {
      return Result.failure(
          NetworkFailure('Tempo de conexão esgotado.', error));
    } on FormatException catch (error) {
      return Result.failure(
          DataFailure('Resposta de migração inválida.', cause: error));
    } catch (error) {
      return Result.failure(UnexpectedFailure(
        'Não foi possível iniciar a migração da assinatura.',
        error,
      ));
    }
  }
}
