import 'package:bldr_fitness/features/analytics/domain/entities/ai_tool_contracts.dart';
import 'package:bldr_fitness/features/analytics/domain/services/ai_analytics_tools.dart';
import 'package:bldr_fitness/features/analytics/domain/services/ai_tool_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final context = const AiToolExecutionContext(userId: 'trusted-user');
  final arguments = <String, Object?>{
    'start': '2026-01-01T00:00:00.000Z',
    'end': '2026-01-08T00:00:00.000Z',
  };

  test('executes a registered tool with a trusted identity', () async {
    final tool = _Tool(workoutAnalyticsToolId, AiToolStatus.success);
    final router = AiToolRouter([tool]);

    final result = await router.execute(
      AiToolCall(toolId: workoutAnalyticsToolId, arguments: arguments),
      context,
    );

    expect(result.status, AiToolStatus.success);
    expect(tool.contexts.single.userId, 'trusted-user');
    expect(result.toJson()['status'], 'success');
  });

  test('keeps empty, partial and unavailable states serializable', () async {
    for (final status in [
      AiToolStatus.empty,
      AiToolStatus.partial,
      AiToolStatus.unavailable,
    ]) {
      final router = AiToolRouter([_Tool(workoutAnalyticsToolId, status)]);
      final result = await router.execute(
        AiToolCall(toolId: workoutAnalyticsToolId, arguments: arguments),
        context,
      );

      expect(result.status, status);
      expect(result.toJson()['status'], status.name);
    }
  });

  test('rejects unauthenticated contexts before executing a tool', () async {
    final tool = _Tool(workoutAnalyticsToolId, AiToolStatus.success);
    final result = await AiToolRouter([tool]).execute(
      AiToolCall(toolId: workoutAnalyticsToolId, arguments: arguments),
      const AiToolExecutionContext(userId: ' '),
    );

    expect(result.status, AiToolStatus.failure);
    expect(result.failure!.code, 'AuthFailure');
    expect(tool.contexts, isEmpty);
  });

  test('rejects model-supplied user identities without executing a tool',
      () async {
    final tool = _Tool(workoutAnalyticsToolId, AiToolStatus.success);
    final result = await AiToolRouter([tool]).execute(
      AiToolCall(
        toolId: workoutAnalyticsToolId,
        arguments: {...arguments, 'userId': 'another-user'},
      ),
      context,
    );

    expect(result.status, AiToolStatus.failure);
    expect(result.failure!.code, 'ValidationFailure');
    expect(tool.contexts, isEmpty);
  });

  test('rejects unknown tools and unexpected arguments', () async {
    final router = AiToolRouter(const []);
    final unknown = await router.execute(
      AiToolCall(toolId: 'unknown', arguments: arguments),
      context,
    );
    final unexpected = await AiToolRouter([
      _Tool(nutritionAnalyticsToolId, AiToolStatus.unavailable),
    ]).execute(
      AiToolCall(
        toolId: nutritionAnalyticsToolId,
        arguments: {...arguments, 'limit': 1},
      ),
      context,
    );

    expect(unknown.failure!.code, 'ValidationFailure');
    expect(unexpected.failure!.code, 'ValidationFailure');
  });

  test('rejects invalid and excessive periods before executing a tool',
      () async {
    final tool = _Tool(progressAnalyticsToolId, AiToolStatus.success);
    final router = AiToolRouter([tool]);
    final invalid = await router.execute(
      AiToolCall(
        toolId: progressAnalyticsToolId,
        arguments: {
          'start': '2026-01-08T00:00:00.000Z',
          'end': '2026-01-01T00:00:00.000Z',
        },
      ),
      context,
    );
    final excessive = await router.execute(
      AiToolCall(
        toolId: progressAnalyticsToolId,
        arguments: {
          'start': '2024-01-01T00:00:00.000Z',
          'end': '2026-01-08T00:00:00.000Z',
        },
      ),
      context,
    );

    expect(invalid.failure!.code, 'ValidationFailure');
    expect(excessive.failure!.code, 'ValidationFailure');
    expect(tool.contexts, isEmpty);
  });

  test('enforces per-tool query limits before execution', () async {
    final tool = _Tool(healthRecoveryAnalyticsToolId, AiToolStatus.success);
    final result = await AiToolRouter([tool]).execute(
      AiToolCall(
        toolId: healthRecoveryAnalyticsToolId,
        arguments: {...arguments, 'pageSize': AiToolRouter.maxPageSize + 1},
      ),
      context,
    );

    expect(result.failure!.code, 'ValidationFailure');
    expect(tool.contexts, isEmpty);
  });

  test('limits repeated execution without re-invoking a tool', () async {
    final tool = _Tool(workoutAnalyticsToolId, AiToolStatus.success);
    final router = AiToolRouter([tool], maxExecutions: 1);

    final result = await router.execute(
      AiToolCall(toolId: workoutAnalyticsToolId, arguments: arguments),
      context,
      executionIndex: 1,
    );

    expect(result.failure!.code, 'ValidationFailure');
    expect(tool.contexts, isEmpty);
  });

  test('preserves safe typed failures from tools', () async {
    final router = AiToolRouter([
      _Tool(
        healthRecoveryAnalyticsToolId,
        AiToolStatus.failure,
        failure:
            const AiToolFailure(code: 'NetworkFailure', message: 'Falhou.'),
      ),
    ]);

    final result = await router.execute(
      AiToolCall(toolId: healthRecoveryAnalyticsToolId, arguments: arguments),
      context,
    );

    expect(result.status, AiToolStatus.failure);
    expect(result.failure!.code, 'NetworkFailure');
    expect(result.toJson()['failure'],
        {'code': 'NetworkFailure', 'message': 'Falhou.'});
  });
}

class _Tool implements AiAnalyticsTool {
  @override
  final String id;
  final AiToolStatus status;
  final AiToolFailure? failure;
  final List<AiToolExecutionContext> contexts = [];

  _Tool(this.id, this.status, {this.failure});

  @override
  Future<AiToolResult> execute(
    AiToolExecutionContext context,
    AiToolArguments arguments,
  ) async {
    contexts.add(context);
    return AiToolResult(
      toolId: id,
      status: status,
      period: arguments.period,
      sources: const ['fixture'],
      metrics: const {'unit': 'kg'},
      failure: failure,
    );
  }
}
