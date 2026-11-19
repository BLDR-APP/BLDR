import 'dart:convert';

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/analytics/domain/entities/ai_tool_contracts.dart';
import 'package:bldr_fitness/features/analytics/domain/services/ai_analytics_tools.dart';
import 'package:bldr_fitness/features/analytics/domain/services/ai_tool_router.dart';
import 'package:bldr_fitness/features/analytics/domain/entities/havok_context.dart';

/// Planeja somente capacidades conhecidas e explicitamente solicitadas.
class HavokContextPlanner {
  static const maxCapabilities = 4;
  const HavokContextPlanner();

  Result<List<String>> plan(
    HavokContextRequest request,
    Set<String> availableCapabilities,
  ) {
    final capabilities = request.capabilityIds.toSet().toList()..sort();
    if (capabilities.isEmpty || capabilities.length > maxCapabilities) {
      return const Result.failure(ValidationFailure('Capacidades inválidas.'));
    }
    if (capabilities.any((id) => !availableCapabilities.contains(id))) {
      return const Result.failure(
        ValidationFailure('Capacidade analítica desconhecida.'),
      );
    }
    return Result.success(capabilities);
  }
}

/// Único ponto do Context Engine que aciona ferramentas: sempre via Router.
class HavokContextProvider {
  final AiToolRouter _router;

  const HavokContextProvider(this._router);

  Future<List<AiToolResult>> provide({
    required List<String> capabilityIds,
    required AiToolExecutionContext context,
    required HavokContextRequest request,
  }) async {
    final results = <AiToolResult>[];
    for (var index = 0; index < capabilityIds.length; index++) {
      results.add(await _router.execute(
        AiToolCall(
          toolId: capabilityIds[index],
          arguments: _argumentsFor(capabilityIds[index], request),
        ),
        context,
        executionIndex: index,
      ));
    }
    return results;
  }

  Map<String, Object?> _argumentsFor(
    String capabilityId,
    HavokContextRequest request,
  ) =>
      {
        'start': request.period.start.toUtc().toIso8601String(),
        'end': request.period.end.toUtc().toIso8601String(),
        if (capabilityId == workoutAnalyticsToolId) ...{
          'comparePreviousPeriod': request.comparePreviousPeriod,
          if (request.pageSize != null) 'pageSize': request.pageSize,
          if (request.maxPages != null) 'maxPages': request.maxPages,
        },
        if (capabilityId == progressAnalyticsToolId && request.limit != null)
          'limit': request.limit,
        if (capabilityId == healthRecoveryAnalyticsToolId) ...{
          if (request.pageSize != null) 'pageSize': request.pageSize,
          if (request.maxPages != null) 'maxPages': request.maxPages,
        },
      };
}

/// Segurança e compactação aplicadas após a resposta tipada das ferramentas.
class HavokContextPolicies {
  static const maxSerializedBytes = 24000;
  static const _sensitiveKeys = {
    'token',
    'credential',
    'password',
    'authorization',
    'userid',
    'user_id',
  };
  const HavokContextPolicies();

  Result<void> validate(
    HavokContextRequest request,
    AiToolExecutionContext context,
  ) {
    if (context.userId.trim().isEmpty) {
      return const Result.failure(AuthFailure('Usuário não autenticado.'));
    }
    if (!request.period.end.isAfter(request.period.start)) {
      return const Result.failure(
          ValidationFailure('Período de consulta inválido.'));
    }
    if (request.period.end.difference(request.period.start).inDays >
        AiToolRouter.maxIntervalDays) {
      return const Result.failure(
          ValidationFailure('Período de consulta excede o limite.'));
    }
    return const Result.success(null);
  }

  Result<Map<String, Object?>> sanitizeAndValidate(
    Map<String, Object?> value,
  ) {
    final sanitized = _sanitizeMap(value);
    if (utf8.encode(jsonEncode(sanitized)).length > maxSerializedBytes) {
      return const Result.failure(
          ValidationFailure('Contexto analítico excede o limite.'));
    }
    return Result.success(sanitized);
  }

  Map<String, Object?> _sanitizeMap(Map<String, Object?> value) => {
        for (final entry in value.entries)
          if (!_sensitiveKeys.contains(entry.key.toLowerCase()))
            entry.key: _sanitizeValue(entry.value),
      };

  Object? _sanitizeValue(Object? value) {
    if (value is Map) {
      return _sanitizeMap(value.map((key, item) => MapEntry('$key', item)));
    }
    if (value is Iterable) {
      return [for (final item in value) _sanitizeValue(item)];
    }
    return value;
  }
}

class HavokContextBuilder {
  final HavokContextPolicies _policies;

  const HavokContextBuilder(this._policies);

  Result<HavokContextResult> build(
    AiToolPeriod period,
    List<AiToolResult> toolResults,
  ) {
    final entries = <HavokContextEntry>[];
    for (final result in toolResults
      ..sort((a, b) => a.toolId.compareTo(b.toolId))) {
      final metrics = _policies.sanitizeAndValidate(result.metrics);
      if (metrics.isFailure) return Result.failure(metrics.failureOrNull!);
      entries.add(HavokContextEntry(
        capabilityId: result.toolId,
        status: _status(result.status),
        metrics: metrics.valueOrNull!,
        sources: List.unmodifiable(result.sources),
        limitations: List.unmodifiable(result.limitations),
        failure: result.failure,
      ));
    }
    return Result.success(HavokContextResult(
      status: _aggregate(entries),
      period: period,
      entries: List.unmodifiable(entries),
    ));
  }

  HavokContextStatus _status(AiToolStatus status) => switch (status) {
        AiToolStatus.success => HavokContextStatus.success,
        AiToolStatus.empty => HavokContextStatus.empty,
        AiToolStatus.partial => HavokContextStatus.partial,
        AiToolStatus.unavailable => HavokContextStatus.unavailable,
        AiToolStatus.failure => HavokContextStatus.failure,
      };

  HavokContextStatus _aggregate(List<HavokContextEntry> entries) {
    if (entries.every((entry) => entry.status == HavokContextStatus.failure)) {
      return HavokContextStatus.failure;
    }
    if (entries.any((entry) =>
        entry.status == HavokContextStatus.partial ||
        entry.status == HavokContextStatus.failure)) {
      return HavokContextStatus.partial;
    }
    if (entries
        .every((entry) => entry.status == HavokContextStatus.unavailable)) {
      return HavokContextStatus.unavailable;
    }
    if (entries
        .any((entry) => entry.status == HavokContextStatus.unavailable)) {
      return HavokContextStatus.partial;
    }
    if (entries.any((entry) => entry.status == HavokContextStatus.success)) {
      return HavokContextStatus.success;
    }
    return HavokContextStatus.empty;
  }
}

/// Fachada read-only preparada para a Fase 12, ainda sem ligação ao HAVOK.
class HavokContextEngine {
  final AiToolRouter _router;
  final HavokContextPlanner _planner;
  final HavokContextProvider _provider;
  final HavokContextBuilder _builder;
  final HavokContextPolicies _policies;

  HavokContextEngine({
    required AiToolRouter router,
    HavokContextPlanner planner = const HavokContextPlanner(),
    HavokContextPolicies policies = const HavokContextPolicies(),
  })  : _router = router,
        _planner = planner,
        _policies = policies,
        _provider = HavokContextProvider(router),
        _builder = HavokContextBuilder(policies);

  Future<Result<HavokContextResult>> build({
    required HavokContextRequest request,
    required AiToolExecutionContext context,
  }) async {
    final valid = _policies.validate(request, context);
    if (valid.isFailure) return Result.failure(valid.failureOrNull!);
    final plan = _planner.plan(request, _router.toolIds);
    if (plan.isFailure) return Result.failure(plan.failureOrNull!);
    final results = await _provider.provide(
      capabilityIds: plan.valueOrNull!,
      context: context,
      request: request,
    );
    return _builder.build(request.period, results);
  }
}
