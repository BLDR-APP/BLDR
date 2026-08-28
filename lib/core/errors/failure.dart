/// Falhas padronizadas do app (Clean Architecture).
///
/// Camadas de domínio e apresentação nunca veem exceções cruas de
/// Supabase/Firebase/HTTP — os datasources/repositories convertem qualquer
/// erro em um [Failure] antes de devolvê-lo.
abstract class Failure {
  final String message;
  final Object? cause;

  const Failure(this.message, {this.cause});

  @override
  String toString() => '$runtimeType: $message';
}

/// Erro vindo do servidor (Supabase, Firestore, edge functions, APIs).
class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.cause});
}

/// Sem conexão ou timeout de rede.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão com a internet.', Object? cause])
      : super(cause: cause);
}

/// Usuário não autenticado ou sessão expirada.
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.cause});
}

/// Dados inválidos ou em formato inesperado (ex.: parse de JSON).
class DataFailure extends Failure {
  const DataFailure(super.message, {super.cause});
}

/// Regra de negócio violada (ex.: limite de treinos atingido).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.cause});
}

/// Erro não mapeado.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Ocorreu um erro inesperado.', Object? cause])
      : super(cause: cause);
}
