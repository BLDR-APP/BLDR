import 'package:bldr_fitness/core/errors/failure.dart';

/// Falhas específicas de autenticação que a UI trata de forma diferenciada
/// (checando o tipo, nunca comparando strings de mensagem).

/// Login recusado porque o e-mail ainda não foi confirmado.
class EmailNotConfirmedFailure extends AuthFailure {
  const EmailNotConfirmedFailure({Object? cause})
      : super('E-mail ainda não confirmado. Verifique sua caixa de entrada.',
            cause: cause);
}

/// Usuário cancelou o fluxo de login social (não é um erro real).
class SignInCanceledFailure extends AuthFailure {
  const SignInCanceledFailure({Object? cause})
      : super('Login cancelado', cause: cause);
}
