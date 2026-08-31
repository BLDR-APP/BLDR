/// Thread de conversa do HAVOK (bldr_club.havok_threads).
///
/// Uma thread por dia por usuário (HAVOK_SPEC.md §4.4) — na virada do dia
/// uma nova é criada; a de hoje continua de onde parou entre telas.
class HavokThread {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String? originScreen;

  const HavokThread({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.lastMessageAt,
    this.originScreen,
  });

  factory HavokThread.fromMap(Map<String, dynamic> map) => HavokThread(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        lastMessageAt: DateTime.parse(
            (map['last_message_at'] ?? map['created_at']) as String),
        originScreen: map['origin_screen'] as String?,
      );
}

/// Mensagem dentro de uma thread do HAVOK (bldr_club.havok_messages).
class HavokMessage {
  final String id;
  final String threadId;
  final String role; // 'user' | 'assistant'
  final String content;
  final DateTime createdAt;
  final String? artifactType; // 'workout' | 'recipe' | null
  final String? artifactId;

  /// JSON do artefato gerado (treino/receita) — BACKLOG_FUNCIONAL.md B6.
  /// Persistido em `havok_messages.artifact_data`, sobrevive a reload da
  /// thread. Null quando a mensagem não tem artefato.
  final Map<String, dynamic>? artifactData;

  /// Contrato estruturado HAVOK V2. Mensagens antigas continuam sem versão e
  /// são tratadas como legado para manter o histórico íntegro.
  final int? responseVersion;
  final Map<String, dynamic>? responseData;

  const HavokMessage({
    required this.id,
    required this.threadId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.artifactType,
    this.artifactId,
    this.artifactData,
    this.responseVersion,
    this.responseData,
  });

  bool get isUser => role == 'user';

  factory HavokMessage.fromMap(Map<String, dynamic> map) => HavokMessage(
        id: map['id'] as String,
        threadId: map['thread_id'] as String,
        role: map['role'] as String,
        content: map['content'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        artifactType: map['artifact_type'] as String?,
        artifactId: map['artifact_id'] as String?,
        artifactData: map['artifact_data'] is Map
            ? Map<String, dynamic>.from(map['artifact_data'] as Map)
            : null,
        responseVersion: (map['response_version'] as num?)?.toInt(),
        responseData: map['response_data'] is Map
            ? Map<String, dynamic>.from(map['response_data'] as Map)
            : null,
      );
}

/// Uma preferência ou contexto persistente e controlável pelo usuário.
/// Métricas voláteis não pertencem a esta entidade.
class HavokMemory {
  final String id;
  final String category;
  final String key;
  final dynamic value;
  final double confidence;
  final DateTime updatedAt;

  const HavokMemory({
    required this.id,
    required this.category,
    required this.key,
    required this.value,
    required this.confidence,
    required this.updatedAt,
  });

  String get displayValue =>
      value is String ? value as String : value.toString();

  factory HavokMemory.fromMap(Map<String, dynamic> map) => HavokMemory(
        id: map['id'] as String,
        category: map['category'] as String,
        key: map['memory_key'] as String,
        value: map['value'],
        confidence: (map['confidence'] as num?)?.toDouble() ?? .8,
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}
