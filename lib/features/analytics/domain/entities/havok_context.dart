import 'package:bldr_fitness/features/analytics/domain/entities/ai_tool_contracts.dart';

enum HavokContextStatus { success, empty, partial, unavailable, failure }

/// Pedido explícito de capacidades analíticas. A futura integração HAVOK decide
/// as capacidades; este contrato não classifica texto livre do usuário.
class HavokContextRequest {
  final List<String> capabilityIds;
  final AiToolPeriod period;
  final bool comparePreviousPeriod;
  final int? pageSize;
  final int? maxPages;
  final int? limit;

  const HavokContextRequest({
    required this.capabilityIds,
    required this.period,
    this.comparePreviousPeriod = true,
    this.pageSize,
    this.maxPages,
    this.limit,
  });
}

class HavokContextEntry {
  final String capabilityId;
  final HavokContextStatus status;
  final Map<String, Object?> metrics;
  final List<String> sources;
  final List<String> limitations;
  final AiToolFailure? failure;

  const HavokContextEntry({
    required this.capabilityId,
    required this.status,
    this.metrics = const {},
    this.sources = const [],
    this.limitations = const [],
    this.failure,
  });

  Map<String, Object?> toJson() => {
        'capabilityId': capabilityId,
        'status': status.name,
        'metrics': metrics,
        'sources': sources,
        'limitations': limitations,
        if (failure != null) 'failure': failure!.toJson(),
      };
}

class HavokContextResult {
  final HavokContextStatus status;
  final AiToolPeriod period;
  final List<HavokContextEntry> entries;
  final List<String> limitations;

  const HavokContextResult({
    required this.status,
    required this.period,
    required this.entries,
    this.limitations = const [],
  });

  Map<String, Object?> toJson() => {
        'status': status.name,
        'period': period.toJson(),
        'entries': [for (final entry in entries) entry.toJson()],
        'limitations': limitations,
      };
}
