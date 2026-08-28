import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/profile/data/datasources/supabase_privacy_datasource.dart';
import 'package:bldr_fitness/features/profile/domain/entities/privacy_settings.dart';
import 'package:bldr_fitness/features/profile/domain/repositories/privacy_repository.dart';

class PrivacyRepositoryImpl implements PrivacyRepository {
  final SupabasePrivacyDatasource _datasource;
  const PrivacyRepositoryImpl(this._datasource);

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.success(await action());
    } on Failure catch (f) {
      return Result.failure(f);
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message, cause: e));
    } on SocketException catch (e) {
      return Result.failure(NetworkFailure('Sem conexão com a internet.', e));
    } on TimeoutException catch (e) {
      return Result.failure(NetworkFailure('Tempo de conexão esgotado.', e));
    } catch (e) {
      return Result.failure(UnexpectedFailure('Ocorreu um erro inesperado.', e));
    }
  }

  @override
  Future<Result<PrivacySettings>> getPrivacySettings(String userId) =>
      _guard(() async {
        final row = await _datasource.getPrivacy(userId);
        if (row == null) return PrivacySettings.defaults;
        return PrivacySettings(
          displayName: row['display_name'] as String?,
          photoVisibility: (row['photo_visibility'] as String?) ?? 'public',
          feedVisible: (row['feed_visible'] as bool?) ?? true,
          reactionsEnabled: (row['reactions_enabled'] as bool?) ?? true,
          rankingVisible: (row['ranking_visible'] as bool?) ?? true,
        );
      });

  @override
  Future<Result<void>> savePrivacySettings(String userId, PrivacySettings settings) =>
      _guard(() => _datasource.savePrivacy(userId, {
            'display_name': settings.displayName?.trim().isEmpty == true
                ? null
                : settings.displayName?.trim(),
            'photo_visibility': settings.photoVisibility,
            'feed_visible': settings.feedVisible,
            'reactions_enabled': settings.reactionsEnabled,
            'ranking_visible': settings.rankingVisible,
          }));
}
