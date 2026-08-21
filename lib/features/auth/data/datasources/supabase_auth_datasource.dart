import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Acesso cru ao Supabase Auth. Única classe da feature que conhece o SDK.
///
/// Não trata erros — exceções sobem para o repository, que as converte
/// em [Failure].
class SupabaseAuthDatasource {
  final SupabaseClient _client;

  SupabaseAuthDatasource(this._client);

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      _client.auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? emailRedirectTo,
    Map<String, dynamic>? additionalData,
  }) =>
      _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: emailRedirectTo,
        data: {'full_name': fullName, ...?additionalData},
      );

  Future<void> signOut() => _client.auth.signOut();

  Future<void> resendConfirmationEmail({
    required String email,
    required String emailRedirectTo,
  }) =>
      _client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: emailRedirectTo,
      );

  Future<void> sendPasswordResetOtp(String email) =>
      _client.auth.signInWithOtp(email: email, shouldCreateUser: false);

  Future<AuthResponse> verifyPasswordResetOtp({
    required String email,
    required String token,
  }) =>
      _client.auth.verifyOTP(email: email, token: token, type: OtpType.email);

  Future<UserResponse> updatePassword(String newPassword) =>
      _client.auth.updateUser(UserAttributes(password: newPassword));

  Future<void> deleteAccountViaEdgeFunction() async {
    final response =
        await _client.functions.invoke('delete-user-account');
    if (response.status != 200) {
      throw Exception(
          'Erro ao excluir a conta: ${response.data?['error'] ?? response.status}');
    }
  }

  /// Fluxo nativo do Sign in with Apple (Face ID / Touch ID) com nonce.
  Future<void> signInWithApple() async {
    final rawNonce = _generateNonce();
    final hashedNonce = _sha256(rawNonce);

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw Exception('Apple Sign-In failed: Missing ID token.');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );

    // A Apple só envia o nome no primeiro login; nas sessões seguintes chega
    // null e o nome já gravado é preservado.
    final fullName = [credential.givenName, credential.familyName]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ')
        .trim();
    if (fullName.isNotEmpty) {
      await _client.auth.updateUser(
        UserAttributes(data: {'full_name': fullName}),
      );
    }
  }

  Future<void> signInWithGoogle() => _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'bldr://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

  String _generateNonce([int length = 32]) {
    final random = Random.secure();
    return List.generate(length, (_) => random.nextInt(256))
        .map((i) => i.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  String _sha256(String input) =>
      sha256.convert(utf8.encode(input)).toString();
}
