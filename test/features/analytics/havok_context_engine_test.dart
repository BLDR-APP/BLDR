import 'package:bldr_fitness/features/analytics/domain/entities/ai_tool_contracts.dart';
import 'package:bldr_fitness/features/analytics/domain/entities/havok_context.dart';
import 'package:bldr_fitness/features/analytics/domain/services/ai_analytics_tools.dart';
import 'package:bldr_fitness/features/analytics/domain/services/ai_tool_router.dart';
import 'package:bldr_fitness/features/analytics/domain/services/havok_context_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const context = AiToolExecutionContext(userId: 'authenticated-user');
  final period = AiToolPeriod(
    start: DateTime.utc(2026, 1, 1),
    end: DateTime.utc(2026, 1, 8),
  );

  HavokContextRequest request(List<String> capabilities) => HavokContextRequest(
        capabilityIds: capabilities,
        period: period,
      );

  test('selects and executes only explicitly requested capabilities', () async {
    final workout = _Tool(workoutAnalyticsToolId);
    final health = _Tool(healthRecoveryAnalyticsToolId);
    final engine = _engine([workout, health]);

    final result = await engine.build(
      request: request([workoutAnalyticsToolId]),
      context: context,
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.entries.single.capabilityId,
        workoutAnalyticsToolId);
    expect(workout.calls, 1);
    expect(health.calls, 0);
  });

  test('deduplicates and orders multiple requested capabilities', () async {
    final workout = _Tool(workoutAnalyticsToolId);
    final progress = _Tool(progressAnalyticsToolId);
    final result = await _engine([workout, progress]).build(
      request: request([
        progressAnalyticsToolId,
        workoutAnalyticsToolId,
        progressAnalyticsToolId
      ]),
      context: context,
    );

    expect(result.isSuccess, isTrue);
    expect(result.valueOrNull!.entries.map((entry) => entry.capabilityId), [
      progressAnalyticsToolId,
      workoutAnalyticsToolId,
    ]);
    expect(workout.calls, 1);
    expect(progress.calls, 1);
  });

  test('rejects empty, unknown and excessive capability requests', () async {
    final tool = _Tool(workoutAnalyticsToolId);
    final engine = _engine([tool]);
    final empty = await engine.build(request: request([]), context: context);
    final unknown =
        await engine.build(request: request(['unknown']), context: context);
    final excessive = await engine.build(
      request: request(['a', 'b', 'c', 'd', 'e']),
      context: context,
    );

    expect(empty.isFailure, isTrue);
    expect(unknown.isFailure, isTrue);
    expect(excessive.isFailure, isTrue);
    expect(tool.calls, 0);
  });

  test('rejects unauthenticated and invalid-period contexts before execution',
      () async {
    final tool = _Tool(workoutAnalyticsToolId);
    final engine = _engine([tool]);
    final unauthenticated = await engine.build(
      request: request([workoutAnalyticsToolId]),
      context: const AiToolExecutionContext(userId: ''),
    );
    final invalidPeriod = await engine.build(
      request: HavokContextRequest(
        capabilityIds: [workoutAnalyticsToolId],
        period: AiToolPeriod(start: period.end, end: period.start),
      ),
      context: context,
    );
    final excessivePeriod = await engine.build(
      request: HavokContextRequest(
        capabilityIds: [workoutAnalyticsToolId],
        period: AiToolPeriod(
          start: DateTime.utc(2024, 1, 1),
          end: DateTime.utc(2026, 1, 8),
        ),
      ),
      context: context,
    );

    expect(unauthenticated.isFailure, isTrue);
    expect(invalidPeriod.isFailure, isTrue);
    expect(excessivePeriod.isFailure, isTrue);
    expect(tool.calls, 0);
  });

  test('preserves partial, unavailable and independent failures', () async {
    final workout = _Tool(workoutAnalyticsToolId, status: AiToolStatus.success);
    final health =
        _Tool(healthRecoveryAnalyticsToolId, status: AiToolStatus.partial);
    final nutrition =
        _Tool(nutritionAnalyticsToolId, status: AiToolStatus.unavailable);
    final result = await _engine([workout, health, nutrition]).build(
      request: request([
        nutritionAnalyticsToolId,
        healthRecoveryAnalyticsToolId,
        workoutAnalyticsToolId,
      ]),
      context: context,
    );

    expect(result.valueOrNull!.status, HavokContextStatus.partial);
    expect(
      result.valueOrNull!.entries
          .firstWhere((entry) => entry.capabilityId == nutritionAnalyticsToolId)
          .status,
      HavokContextStatus.unavailable,
    );
    expect(
      result.valueOrNull!.entries
          .firstWhere(
              (entry) => entry.capabilityId == healthRecoveryAnalyticsToolId)
          .status,
      HavokContextStatus.partial,
    );
  });

  test('returns failure only when every requested capability fails', () async {
    final result = await _engine([
      _Tool(workoutAnalyticsToolId, status: AiToolStatus.failure),
      _Tool(progressAnalyticsToolId, status: AiToolStatus.failure),
    ]).build(
      request: request([workoutAnalyticsToolId, progressAnalyticsToolId]),
      context: context,
    );

    expect(result.valueOrNull!.status, HavokContextStatus.failure);
  });

  test('preserves units and provenance while excluding sensitive metric keys',
      () async {
    final tool = _Tool(
      workoutAnalyticsToolId,
      metrics: const {
        'weight': {'value': 80, 'unit': 'kg'},
        'token': 'must-not-leak',
        'nested': {'userId': 'must-not-leak', 'source': 'canonical'},
      },
      sources: const ['canonical_workout'],
    );
    final result = await _engine([tool]).build(
      request: request([workoutAnalyticsToolId]),
      context: context,
    );
    final entry = result.valueOrNull!.entries.single;

    expect(entry.sources, ['canonical_workout']);
    expect(entry.metrics['weight'], {'value': 80, 'unit': 'kg'});
    expect(entry.metrics.containsKey('token'), isFalse);
    expect(
        (entry.metrics['nested'] as Map<String, Object?>).containsKey('userId'),
        isFalse);
  });

  test('keeps serialization deterministic and rejects oversized context values',
      () async {
    final first = _Tool(workoutAnalyticsToolId);
    final second = _Tool(progressAnalyticsToolId);
    final engine = _engine([first, second]);
    final one = await engine.build(
      request: request([progressAnalyticsToolId, workoutAnalyticsToolId]),
      context: context,
    );
    final two = await engine.build(
      request: request([workoutAnalyticsToolId, progressAnalyticsToolId]),
      context: context,
    );
    final oversized = await _engine([
      _Tool(workoutAnalyticsToolId, metrics: {'blob': 'x' * 25000}),
    ]).build(
      request: request([workoutAnalyticsToolId]),
      context: context,
    );

    expect(one.valueOrNull!.toJson(), two.valueOrNull!.toJson());
    expect(oversized.isFailure, isTrue);
  });
}

HavokContextEngine _engine(List<AiAnalyticsTool> tools) =>
    HavokContextEngine(router: AiToolRouter(tools));

class _Tool implements AiAnalyticsTool {
  @override
  final String id;
  final AiToolStatus status;
  final Map<String, Object?> metrics;
  final List<String> sources;
  int calls = 0;

  _Tool(
    this.id, {
    this.status = AiToolStatus.success,
    this.metrics = const {'value': 1, 'unit': 'score'},
    this.sources = const ['fixture'],
  });

  @override
  Future<AiToolResult> execute(
    AiToolExecutionContext context,
    AiToolArguments arguments,
  ) async {
    calls++;
    return AiToolResult(
      toolId: id,
      status: status,
      period: arguments.period,
      metrics: metrics,
      sources: sources,
      limitations: status == AiToolStatus.unavailable
          ? const ['Indisponível.']
          : const [],
    );
  }
}
