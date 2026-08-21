import 'dart:async';
import 'dart:io';

import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/auth/domain/auth_failures.dart';
import 'package:bldr_fitness/features/auth/domain/entities/auth_user.dart';
import 'package:bldr_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:bldr_fitness/features/auth/data/datasources/supabase_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseAuthDatasource _datasource;

  AuthRepositoryImpl(this._datasource);

  @override
  AuthUser? get currentUser => _toEntity(_datasource.currentUser);

  @override
  bool get isAuthenticated => _datasource.currentUser != null;

  @override
  Stream<AuthUser?> get authStateChanges =>
      _datasource.authStateChanges.map((state) => _toEntity(state.session?.user));

  @override
  Future<Result<AuthUser>> signIn({
    required String email,
    required String password,
  }) =>
      _guardUser(() async {
        final response =
            await _datasource.signIn(email: email, password: password);
        return response.user;
      });

  @override
  Future<Result<AuthUser>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? emailRedirectTo,
    Map<String, dynamic>? additionalData,
  }) =>
      _guardUser(() async {
        final response = await _datasource.signUp(
          email: email,
          password: password,
          fullName: fullName,
          emailRedirectTo: emailRedirectTo,
          additionalData: additionalData,
        );
        return response.user;
      });

  @override
  Future<Result<void>> signOut() => _guard(_datasource.signOut);

  @override
  Future<Result<void>> signInWithApple() => _guard(_datasource.signInWithApple);

  @override
  Future<Result<void>> signInWithGoogle() =>
      _guard(_datasource.signInWithGoogle);

  @override
  Future<Result<void>> resendConfirmationEmail({
    required String email,
    required String emailRedirectTo,
  }) =>
      _guard(() => _datasource.resendConfirmationEmail(
            email: email,
            emailRedirectTo: emailRedirectTo,
          ));

  @override
  Future<Result<void>> sendPasswordResetOtp(String email) =>
      _guard(() => _datasource.sendPasswordResetOtp(email));

  @override
  Future<Result<AuthUser>> verifyPasswordResetOtp({
    required String email,
    required String token,
  }) =>
      _guardUser(() async {
        final response = await _datasource.verifyPasswordResetOtp(
          email: email,
          token: token,
        );
        return response.user;
      });

  @override
  Future<Result<void>> updatePassword(String newPassword) =>
      _guard(() => _datasource.updatePassword(newPassword));

  @override
  Future<Result<void>> deleteAccount() => _guard(() async {
        await _datasource.deleteAccountViaEdgeFunction();
        await _datasource.signOut();
      });

  // --- Conversões ---

  AuthUser? _toEntity(supabase.User? user) {
    if (user == null) return null;
    return AuthUser(
      id: user.id,
      email: user.email,
      fullName: user.userMetadata?['full_name'] as String?,
      emailConfirmed: user.emailConfirmedAt != null,
    );
  }

  /// Executa [action] convertendo exceções em [Failure].
  Future<Result<T>> _run<T>(Future<T> Function() action) async {
    try {
      return Result.success(await action());
    } on supabase.AuthException catch (e) {
      return Result.failure(_mapAuthException(e));
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return Result.failure(SignInCanceledFailure(cause: e));
      }
      return Result.failure(AuthFailure('Falha no login com a Apple.', cause: e));
    } on SocketException catch (e) {
      return Result.failure(NetworkFailure('Sem conexão com a internet.', e));
    } on TimeoutException catch (e) {
      return Result.failure(NetworkFailure('Tempo de conexão esgotado.', e));
    } catch (e) {
      return Result.failure(UnexpectedFailure('Ocorreu um erro inesperado.', e));
    }
  }

  Future<Result<void>> _guard(Future<void> Function() action) => _run(action);

  Future<Result<AuthUser>> _guardUser(
      Future<supabase.User?> Function() action) async {
    final result = await _run(action);
    return result.fold(
      onSuccess: (user) {
        final entity = _toEntity(user);
        if (entity == null) {
          return Result.failure(
              const AuthFailure('Não foi possível autenticar o usuário.'));
        }
        return Result.success(entity);
      },
      onFailure: Result.failure,
    );
  }

  /// Converte erros do Supabase Auth em falhas com mensagens pt-BR.
  Failure _mapAuthException(supabase.AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('email not confirmed')) {
      return EmailNotConfirmedFailure(cause: e);
    }
    if (message.contains('invalid login credentials')) {
      return AuthFailure('E-mail ou senha incorretos.', cause: e);
    }
    if (message.contains('user already registered')) {
      return AuthFailure('Este e-mail já está cadastrado.', cause: e);
    }
    if (message.contains('token has expired') || message.contains('otp')) {
      return AuthFailure('Código inválido ou expirado.', cause: e);
    }
    if (message.contains('rate limit') || message.contains('too many requests')) {
      return AuthFailure('Muitas tentativas. Aguarde alguns minutos.', cause: e);
    }
    return AuthFailure(e.message, cause: e);
  }
}
