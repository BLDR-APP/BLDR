import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/auth/domain/entities/auth_user.dart';

/// Contrato de autenticação do app.
///
/// A implementação (data/) fala com o Supabase; o domínio só conhece
/// [AuthUser], [Result] e este contrato.
abstract class AuthRepository {
  /// Usuário logado no momento, ou `null`.
  AuthUser? get currentUser;

  bool get isAuthenticated;

  /// Emite o usuário a cada mudança de sessão (login, logout, refresh).
  Stream<AuthUser?> get authStateChanges;

  Future<Result<AuthUser>> signIn({
    required String email,
    required String password,
  });

  /// Cadastro com e-mail/senha. Retorna o usuário criado (pode estar com
  /// e-mail ainda não confirmado).
  Future<Result<AuthUser>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? emailRedirectTo,
    Map<String, dynamic>? additionalData,
  });

  Future<Result<void>> signOut();

  Future<Result<void>> signInWithApple();

  Future<Result<void>> signInWithGoogle();

  Future<Result<void>> resendConfirmationEmail({
    required String email,
    required String emailRedirectTo,
  });

  /// Envia código OTP de 6 dígitos para redefinição de senha.
  Future<Result<void>> sendPasswordResetOtp(String email);

  /// Verifica o OTP e abre sessão de recuperação.
  Future<Result<AuthUser>> verifyPasswordResetOtp({
    required String email,
    required String token,
  });

  /// Troca a senha do usuário autenticado.
  Future<Result<void>> updatePassword(String newPassword);

  /// Exclui a conta via edge function e encerra a sessão.
  Future<Result<void>> deleteAccount();
}
