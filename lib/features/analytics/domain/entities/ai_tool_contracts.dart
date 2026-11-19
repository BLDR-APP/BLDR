import 'package:bldr_fitness/core/errors/failure.dart';

enum AiToolStatus { success, empty, partial, unavailable, failure }

class AiToolPeriod {
  final DateTime start;
  final DateTime end;

  const AiToolPeriod({required this.start, required this.end});

  Map<String, Object> toJson() => {
        'start': start.toUtc().toIso8601String(),
        'end': end.toUtc().toIso8601String(),
      };
}

/// Contexto fornecido exclusivamente por uma camada autenticada confiável.
/// O modelo nunca recebe nem controla este identificador.
class AiToolExecutionContext {
  final String userId;

  const AiToolExecutionContext({required this.userId});
}

class AiToolArguments {
  final AiToolPeriod period;
  final bool comparePreviousPeriod;
  final int? pageSize;
  final int? maxPages;
  final int? limit;

  const AiToolArguments({
    required this.period,
    this.comparePreviousPeriod = true,
    this.pageSize,
    this.maxPages,
    this.limit,
  });
}

class AiToolCall {
  final String toolId;
  final Map<String, Object?> arguments;

  const AiToolCall({required this.toolId, required this.arguments});
}

class AiToolFailure {
  final String code;
  final String message;

  const AiToolFailure({required this.code, required this.message});

  factory AiToolFailure.fromFailure(Failure failure) => AiToolFailure(
        code: failure.runtimeType.toString(),
        message: failure.message,
      );

  Map<String, String> toJson() => {'code': code, 'message': message};
}

class AiToolResult {
  final String toolId;
  final AiToolStatus status;
  final AiToolPeriod? period;
  final Map<String, Object?> metrics;
  final List<String> sources;
  final List<String> limitations;
  final AiToolFailure? failure;

  const AiToolResult({
    required this.toolId,
    required this.status,
    this.period,
    this.metrics = const {},
    this.sources = const [],
    this.limitations = const [],
    this.failure,
  });

  Map<String, Object?> toJson() => {
        'toolId': toolId,
        'status': status.name,
        if (period != null) 'period': period!.toJson(),
        'metrics': metrics,
        'sources': sources,
        'limitations': limitations,
        if (failure != null) 'failure': failure!.toJson(),
      };
}

abstract class AiAnalyticsTool {
  String get id;

  Future<AiToolResult> execute(
    AiToolExecutionContext context,
    AiToolArguments arguments,
  );
}
