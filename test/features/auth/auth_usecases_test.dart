import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/auth/domain/auth_failures.dart';
import 'package:bldr_fitness/features/auth/domain/entities/auth_user.dart';
import 'package:bldr_fitness/features/auth/domain/repositories/auth_repository.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';

/// Repository fake controlável — sem Supabase, sem rede.
class FakeAuthRepository implements AuthRepository {
  AuthUser? user;
  Failure? nextFailure;

  /// Última chamada registrada, para asserções.
  String? lastCall;
  Map<String, Object?> lastArgs = {};

  Result<AuthUser> _userResult() => nextFailure != null
      ? Result.failure(nextFailure!)
      : Result.success(user ?? const AuthUser(id: 'user-1', email: 'a@b.com'));

  Result<void> _voidResult() =>
      nextFailure != null ? Result.failure(nextFailure!) : const Result.success(null);

  @override
  AuthUser? get currentUser => user;

  @override
  bool get isAuthenticated => user != null;

  @override
  Stream<AuthUser?> get authStateChanges => Stream.value(user);

  @override
  Future<Result<AuthUser>> signIn(
      {required String email, required String password}) async {
    lastCall = 'signIn';
    lastArgs = {'email': email, 'password': password};
    return _userResult();
  }

  @override
  Future<Result<AuthUser>> signUp({
    required String email,
    required String password,
    required String fullName,
    String? emailRedirectTo,
    Map<String, dynamic>? additionalData,
  }) async {
    lastCall = 'signUp';
    lastArgs = {'email': email, 'fullName': fullName};
    return _userResult();
  }

  @override
  Future<Result<void>> signOut() async {
    lastCall = 'signOut';
    return _voidResult();
  }

  @override
  Future<Result<void>> signInWithApple() async {
    lastCall = 'signInWithApple';
    return _voidResult();
  }

  @override
  Future<Result<void>> signInWithGoogle() async {
    lastCall = 'signInWithGoogle';
    return _voidResult();
  }

  @override
  Future<Result<void>> resendConfirmationEmail(
      {required String email, required String emailRedirectTo}) async {
    lastCall = 'resendConfirmationEmail';
    lastArgs = {'email': email, 'emailRedirectTo': emailRedirectTo};
    return _voidResult();
  }

  @override
  Future<Result<void>> sendPasswordResetOtp(String email) async {
    lastCall = 'sendPasswordResetOtp';
    lastArgs = {'email': email};
    return _voidResult();
  }

  @override
  Future<Result<AuthUser>> verifyPasswordResetOtp(
      {required String email, required String token}) async {
    lastCall = 'verifyPasswordResetOtp';
    lastArgs = {'email': email, 'token': token};
    return _userResult();
  }

  @override
  Future<Result<void>> updatePassword(String newPassword) async {
    lastCall = 'updatePassword';
    lastArgs = {'newPassword': newPassword};
    return _voidResult();
  }

  @override
  Future<Result<void>> deleteAccount() async {
    lastCall = 'deleteAccount';
    return _voidResult();
  }
}

void main() {
  late FakeAuthRepository repository;

  setUp(() {
    repository = FakeAuthRepository();
  });

  group('SignIn', () {
    test('retorna o usuário em caso de sucesso', () async {
      repository.user = const AuthUser(id: 'abc', email: 'x@y.com');

      final result =
          await SignIn(repository)(email: 'x@y.com', password: 'secret');

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.id, 'abc');
      expect(repository.lastCall, 'signIn');
      expect(repository.lastArgs['email'], 'x@y.com');
    });

    test('propaga EmailNotConfirmedFailure sem alterá-la', () async {
      repository.nextFailure = const EmailNotConfirmedFailure();

      final result =
          await SignIn(repository)(email: 'x@y.com', password: 'secret');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<EmailNotConfirmedFailure>());
    });
  });

  group('SignUp', () {
    test('repassa e-mail e nome ao repository', () async {
      final result = await SignUp(repository)(
        email: 'novo@y.com',
        password: 'secret',
        fullName: 'Novo Usuário',
      );

      expect(result.isSuccess, isTrue);
      expect(repository.lastCall, 'signUp');
      expect(repository.lastArgs['fullName'], 'Novo Usuário');
    });

    test('propaga falha de e-mail já cadastrado', () async {
      repository.nextFailure = const AuthFailure('Este e-mail já está cadastrado.');

      final result = await SignUp(repository)(
        email: 'novo@y.com',
        password: 'secret',
        fullName: 'Novo Usuário',
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('já está cadastrado'));
    });
  });

  group('Fluxo de recuperação de senha', () {
    test('SendPasswordResetOtp envia para o e-mail informado', () async {
      final result = await SendPasswordResetOtp(repository)('x@y.com');

      expect(result.isSuccess, isTrue);
      expect(repository.lastCall, 'sendPasswordResetOtp');
      expect(repository.lastArgs['email'], 'x@y.com');
    });

    test('VerifyPasswordResetOtp retorna usuário logado na sessão de reset',
        () async {
      final result = await VerifyPasswordResetOtp(repository)(
          email: 'x@y.com', token: '123456');

      expect(result.isSuccess, isTrue);
      expect(repository.lastArgs['token'], '123456');
    });

    test('UpdatePassword propaga a nova senha', () async {
      final result = await UpdatePassword(repository)('novaSenha123');

      expect(result.isSuccess, isTrue);
      expect(repository.lastArgs['newPassword'], 'novaSenha123');
    });
  });

  group('GetCurrentUser', () {
    test('retorna null sem sessão e o usuário quando logado', () {
      expect(GetCurrentUser(repository)(), isNull);

      repository.user = const AuthUser(id: 'abc');
      expect(GetCurrentUser(repository)()?.id, 'abc');
    });
  });

  group('Login social', () {
    test('SignInWithApple propaga cancelamento como SignInCanceledFailure',
        () async {
      repository.nextFailure = const SignInCanceledFailure();

      final result = await SignInWithApple(repository)();

      expect(result.failureOrNull, isA<SignInCanceledFailure>());
    });

    test('SignInWithGoogle retorna sucesso', () async {
      final result = await SignInWithGoogle(repository)();

      expect(result.isSuccess, isTrue);
      expect(repository.lastCall, 'signInWithGoogle');
    });
  });

  group('Result', () {
    test('fold executa apenas o ramo correto', () {
      const success = Result<int>.success(2);
      const failure = Result<int>.failure(UnexpectedFailure());

      expect(success.fold(onSuccess: (v) => v * 2, onFailure: (_) => -1), 4);
      expect(failure.fold(onSuccess: (v) => v * 2, onFailure: (_) => -1), -1);
    });

    test('map transforma sucesso e preserva falha', () {
      const success = Result<int>.success(2);
      const failure = Result<int>.failure(NetworkFailure());

      expect(success.map((v) => 'v$v').valueOrNull, 'v2');
      expect(failure.map((v) => 'v$v').failureOrNull, isA<NetworkFailure>());
    });
  });
}
