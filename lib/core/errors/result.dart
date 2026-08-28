import 'package:bldr_fitness/core/errors/failure.dart';

/// Resultado de uma operação que pode falhar, sem lançar exceção.
///
/// Use cases e repositories retornam `Result<T>`; a UI decide o que mostrar
/// com [fold] ou checando [isSuccess].
///
/// ```dart
/// final result = await getWorkoutTemplates();
/// result.fold(
///   onSuccess: (templates) => setState(() => _templates = templates),
///   onFailure: (failure) => _showError(failure.message),
/// );
/// ```
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(Failure failure) = FailureResult<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is FailureResult<T>;

  /// Valor em caso de sucesso, ou `null`.
  T? get valueOrNull => switch (this) {
        Success(:final value) => value,
        FailureResult() => null,
      };

  /// Falha em caso de erro, ou `null`.
  Failure? get failureOrNull => switch (this) {
        Success() => null,
        FailureResult(:final failure) => failure,
      };

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  }) =>
      switch (this) {
        Success(:final value) => onSuccess(value),
        FailureResult(:final failure) => onFailure(failure),
      };

  /// Transforma o valor de sucesso, propagando a falha.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
        Success(:final value) => Result.success(transform(value)),
        FailureResult(:final failure) => Result.failure(failure),
      };
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class FailureResult<T> extends Result<T> {
  final Failure failure;
  const FailureResult(this.failure);
}
