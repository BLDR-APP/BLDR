import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart'; // <<< ADIÇÃO
import 'package:crypto/crypto.dart'; // <<< ADIÇÃO
import 'dart:math';
import 'dart:convert';

import './supabase_service.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  // Current user getter
  User? get currentUser => _client.auth.currentUser;

  // Auth state stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Check if user is authenticated
  bool get isAuthenticated => _client.auth.currentUser != null;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? emailRedirectTo,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final Map<String, dynamic> metadata = {
        'full_name': fullName,
        ...?additionalData,
      };

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: metadata,
        emailRedirectTo: emailRedirectTo,
      );

      return response;
    } catch (error) {
      throw Exception('Sign-up failed: $error');
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return response;
    } catch (error) {
      throw Exception('Sign-in failed: $error');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (error) {
      throw Exception('Sign-out failed: $error');
    }
  }

  /// Reenvia o e-mail de confirmação (método padrão Supabase)
  Future<void> resendConfirmationEmail({
    required String email,
    required String emailRedirectTo,
  }) async {
    try {
      // Usamos o 'resend' padrão do Supabase.
      await _client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: emailRedirectTo,
      );
    } catch (error) {
      throw Exception('Failed to resend confirmation email: $error');
    }
  }

  // <<< INÍCIO DA ADIÇÃO: Novo Fluxo de Reset com OTP >>>

  /// 1. Envia um código OTP (6 dígitos) para o e-mail do usuário
  Future<void> sendPasswordResetOtp(String email) async {
    try {
      // Esta função envia um OTP (código) para o e-mail
      await _client.auth.signInWithOtp(
        email: email,
      );
    } catch (error) {
      throw Exception('Failed to send OTP: $error');
    }
  }

  /// 2. Verifica o código OTP e loga o usuário em uma sessão de recuperação
  Future<AuthResponse> verifyPasswordResetOtp(String email, String token) async {
    try {
      // <<< CORREÇÃO AQUI (linha 111) >>>
      final response = await _client.auth.verifyOTP( // Era 'verifyOtp', agora é 'verifyOTP'
        email: email,
        token: token,
        type: OtpType.email, // Especifica que é um OTP de e-mail
      );
      // Se for um sucesso, o usuário está logado e pode trocar a senha
      return response;
    } catch (error) {
      throw Exception('Invalid OTP code: $error');
    }
  }
  // <<< FIM DA ADIÇÃO >>>

  /// Update user password
  Future<UserResponse> updatePassword({required String newPassword}) async {
    try {
      // Esta função continua perfeita. Ela funciona desde que
      // o usuário esteja autenticado (o que o verifyOTP fará).
      final response = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      return response;
    } catch (error) {
      throw Exception('Password update failed: $error');
    }
  }

  /// Update user metadata
  Future<UserResponse> updateUserMetadata({
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(data: data),
      );

      return response;
    } catch (error) {
      throw Exception('User metadata update failed: $error');
    }
  }

  Future<void> deleteUserAccount() async {
    final response = await Supabase.instance.client.functions.invoke('delete-user-account');

    if (response.status != 200) {
      throw Exception('Erro ao excluir a conta: ${response.data['error']}');
    }

    await signOut();
  }

  // --- Funções de getter (mantidas como estavam) ---
  String? getCurrentUserId() {
    return currentUser?.id;
  }
  String? getCurrentUserEmail() {
    return currentUser?.email;
  }
  Map<String, dynamic>? getCurrentUserMetadata() {
    return currentUser?.userMetadata;
  }

  /// Sign in with Apple (Fluxo NATIVO com Face ID)
  Future<void> signInWithApple() async {
    try {
      // 1. Gera o 'nonce' (token de segurança)
      final rawNonce = _generateNonce();
      final hashedNonce = _sha256(rawNonce);

      // 2. Chama o pop-up nativo do iOS (Face ID / Touch ID)
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce, // Passa o nonce com hash
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw Exception('Apple Sign-In failed: Missing ID token.');
      }

      print('>>> DIAG: Apple ID Token obtido. Enviando para Supabase...');

      // 3. Envia o token para o Supabase para criar a sessão
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce, // Passa o nonce original (sem hash)
      );

      print('>>> DIAG: Chamada signInWithIdToken FINALIZADA. Sessão criada.');

    } catch (error) {
      if (error is SignInWithAppleAuthorizationException &&
          error.code == AuthorizationErrorCode.canceled) {
        print('Apple Sign-In canceled by user.');
        throw Exception('Login cancelado');
      }
      throw Exception('Apple Sign-In failed: $error');
    }
  }
  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
      );
    } catch (error) {
      throw Exception('Google Sign-In failed: $error');
    }
  }
    /// Gera uma string aleatória para o 'nonce'
    String _generateNonce([int length = 32]) {
      final random = Random.secure();
      return List.generate(length, (_) => random.nextInt(256))
          .map((i) => i.toRadixString(16).padLeft(2, '0'))
          .join();
    }

    /// Cria um hash SHA-256 da string
    String _sha256(String input) {
      final bytes = utf8.encode(input);
      final digest = sha256.convert(bytes);
      return digest.toString();
    }
  }