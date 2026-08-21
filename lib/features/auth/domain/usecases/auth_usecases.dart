import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/auth/domain/entities/auth_user.dart';
import 'package:bldr_fitness/features/auth/domain/repositories/auth_repository.dart';

/// Use cases de autenticação — um por operação de negócio.
///
/// Cada classe é registrada no get_it e chamada pela UI como função:
/// `final result = await getIt<SignIn>()(email: ..., password: ...);`

class GetCurrentUser {
  final AuthRepository _repository;
  const GetCurrentUser(this._repository);

  AuthUser? call() => _repository.currentUser;
}

class SignIn {
  final AuthRepository _repository;
  const SignIn(this._repository);

  Future<Result<AuthUser>> call({
    required String email,
    required String password,
  }) =>
      _repository.signIn(email: email, password: password);
}

class SignUp {
  final AuthRepository _repository;
  const SignUp(this._repository);

  Future<Result<AuthUser>> call({
    required String email,
    required String password,
    required String fullName,
    String? emailRedirectTo,
    Map<String, dynamic>? additionalData,
  }) =>
      _repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        emailRedirectTo: emailRedirectTo,
        additionalData: additionalData,
      );
}

class SignOut {
  final AuthRepository _repository;
  const SignOut(this._repository);

  Future<Result<void>> call() => _repository.signOut();
}

class SignInWithApple {
  final AuthRepository _repository;
  const SignInWithApple(this._repository);

  Future<Result<void>> call() => _repository.signInWithApple();
}

class SignInWithGoogle {
  final AuthRepository _repository;
  const SignInWithGoogle(this._repository);

  Future<Result<void>> call() => _repository.signInWithGoogle();
}

class ResendConfirmationEmail {
  final AuthRepository _repository;
  const ResendConfirmationEmail(this._repository);

  Future<Result<void>> call({
    required String email,
    required String emailRedirectTo,
  }) =>
      _repository.resendConfirmationEmail(
        email: email,
        emailRedirectTo: emailRedirectTo,
      );
}

class SendPasswordResetOtp {
  final AuthRepository _repository;
  const SendPasswordResetOtp(this._repository);

  Future<Result<void>> call(String email) =>
      _repository.sendPasswordResetOtp(email);
}

class VerifyPasswordResetOtp {
  final AuthRepository _repository;
  const VerifyPasswordResetOtp(this._repository);

  Future<Result<AuthUser>> call({
    required String email,
    required String token,
  }) =>
      _repository.verifyPasswordResetOtp(email: email, token: token);
}

class UpdatePassword {
  final AuthRepository _repository;
  const UpdatePassword(this._repository);

  Future<Result<void>> call(String newPassword) =>
      _repository.updatePassword(newPassword);
}

class DeleteAccount {
  final AuthRepository _repository;
  const DeleteAccount(this._repository);

  Future<Result<void>> call() => _repository.deleteAccount();
}
