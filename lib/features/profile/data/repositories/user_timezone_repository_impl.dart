import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/profile/data/datasources/supabase_privacy_datasource.dart';
import 'package:bldr_fitness/features/profile/domain/repositories/user_timezone_repository.dart';

class UserTimezoneRepositoryImpl implements UserTimezoneRepository {
  const UserTimezoneRepositoryImpl(this._datasource);

  final SupabasePrivacyDatasource _datasource;

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.success(await action());
    } on PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message, cause: e));
    } on SocketException catch (e) {
      return Result.failure(NetworkFailure('Sem conexão com a internet.', e));
    } on TimeoutException catch (e) {
      return Result.failure(NetworkFailure('Tempo de conexão esgotado.', e));
    } catch (e) {
      return Result.failure(
          UnexpectedFailure('Não foi possível sincronizar o fuso horário.', e));
    }
  }

  @override
  Future<Result<String?>> getTimezone(String userId) =>
      _guard(() => _datasource.getTimezone(userId));

  @override
  Future<Result<void>> syncTimezone(String userId, String timezone) =>
      _guard(() => _datasource.saveTimezone(userId, timezone));
}
