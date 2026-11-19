import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/features/analytics/domain/entities/ai_tool_contracts.dart';
import 'package:bldr_fitness/features/analytics/domain/services/ai_analytics_tools.dart';

/// Resolve e executa somente capacidades analíticas read-only.
///
/// O chamador confiável fornece [AiToolExecutionContext]; argumentos vindos do
/// modelo nunca incluem identidade, credenciais ou acessos a infraestrutura.
class AiToolRouter {
  static const maxIntervalDays = 366;
  static const maxPageSize = 100;
  static const maxPages = 50;
  static const maxLimit = 100;

  final Map<String, AiAnalyticsTool> _tools;
  final int maxExecutions;

  AiToolRouter(
    Iterable<AiAnalyticsTool> tools, {
    this.maxExecutions = 8,
  }) : _tools = {for (final tool in tools) tool.id: tool} {
    if (maxExecutions <= 0 || _tools.length != tools.length) {
      throw ArgumentError('Configuração inválida do AI Tool Router.');
    }
  }

  Set<String> get toolIds => Set.unmodifiable(_tools.keys);

  Future<AiToolResult> execute(
    AiToolCall call,
    AiToolExecutionContext context, {
    int executionIndex = 0,
  }) async {
    if (context.userId.trim().isEmpty) {
      return _failure(
          call.toolId, const AuthFailure('Usuário não autenticado.'));
    }
    if (executionIndex < 0 || executionIndex >= maxExecutions) {
      return _failure(
        call.toolId,
        const ValidationFailure('Limite de execuções de ferramentas atingido.'),
      );
    }
    final tool = _tools[call.toolId];
    if (tool == null) {
      return _failure(
        call.toolId,
        const ValidationFailure('Ferramenta analítica desconhecida.'),
      );
    }
    final arguments = _parseArguments(call.toolId, call.arguments);
    if (arguments is Failure) return _failure(call.toolId, arguments);
    return tool.execute(context, arguments as AiToolArguments);
  }

  AiToolResult _failure(String toolId, Failure failure) => AiToolResult(
        toolId: toolId,
        status: AiToolStatus.failure,
        failure: AiToolFailure.fromFailure(failure),
      );

  Object _parseArguments(String toolId, Map<String, Object?> raw) {
    final allowed = switch (toolId) {
      workoutAnalyticsToolId => {
          'start',
          'end',
          'comparePreviousPeriod',
          'pageSize',
          'maxPages',
        },
      progressAnalyticsToolId => {'start', 'end', 'limit'},
      healthRecoveryAnalyticsToolId => {'start', 'end', 'pageSize', 'maxPages'},
      nutritionAnalyticsToolId => {'start', 'end'},
      _ => <String>{},
    };
    if (raw.keys.any((key) => !allowed.contains(key))) {
      return const ValidationFailure('Argumentos de ferramenta inválidos.');
    }
    final start = _date(raw['start']);
    final end = _date(raw['end']);
    if (start == null || end == null || !end.isAfter(start)) {
      return const ValidationFailure('Período de consulta inválido.');
    }
    if (end.difference(start).inDays > maxIntervalDays) {
      return const ValidationFailure('Período de consulta excede o limite.');
    }
    final pageSize = _boundedInt(raw['pageSize'], maxPageSize);
    final maxPagesValue = _boundedInt(raw['maxPages'], maxPages);
    final limit = _boundedInt(raw['limit'], maxLimit);
    if (pageSize == -1 || maxPagesValue == -1 || limit == -1) {
      return const ValidationFailure('Limite de consulta inválido.');
    }
    final comparison = raw['comparePreviousPeriod'];
    if (comparison != null && comparison is! bool) {
      return const ValidationFailure('Argumentos de ferramenta inválidos.');
    }
    return AiToolArguments(
      period: AiToolPeriod(start: start, end: end),
      comparePreviousPeriod: comparison as bool? ?? true,
      pageSize: pageSize,
      maxPages: maxPagesValue,
      limit: limit,
    );
  }

  DateTime? _date(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value)?.toUtc();
  }

  int? _boundedInt(Object? value, int maximum) {
    if (value == null) return null;
    if (value is! int || value <= 0 || value > maximum) return -1;
    return value;
  }
}
