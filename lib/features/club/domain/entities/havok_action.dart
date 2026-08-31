/// A constrained action proposed by HAVOK. It intentionally contains no route,
/// callback, SQL or user identity; the presentation layer owns confirmation.
class HavokActionProposal {
  final String type;
  final String label;
  final Map<String, dynamic> payload;

  const HavokActionProposal({
    required this.type,
    required this.label,
    required this.payload,
  });

  static const supportedWorkoutTypes = {
    'START_WORKOUT',
    'SAVE_WORKOUT',
    'ADD_WORKOUT_TO_PLAN',
    'REPLACE_EXERCISE',
  };

  static HavokActionProposal? fromMap(Map<String, dynamic> map) {
    final type = map['type'];
    final label = map['label'];
    final payload = map['payload'];
    if (type is! String || label is! String || payload is! Map) return null;
    if (!supportedWorkoutTypes.contains(type) || label.trim().isEmpty)
      return null;
    final normalized = Map<String, dynamic>.from(payload);
    if (normalized.keys.any((key) =>
        RegExp(r'route|function|url|sql|rpc|user', caseSensitive: false)
            .hasMatch(key))) return null;
    if (type == 'REPLACE_EXERCISE') {
      final target = normalized['target_exercise_id'];
      final replacement = normalized['replacement_exercise_id'];
      final name = normalized['replacement_name'];
      if (target is! String ||
          target.isEmpty ||
          replacement is! String ||
          replacement.isEmpty ||
          name is! String ||
          name.trim().isEmpty) {
        return null;
      }
    } else if (normalized.isNotEmpty) {
      // These operations act only on the validated artifact shown in the UI.
      return null;
    }
    return HavokActionProposal(
      type: type,
      label: _labelFor(type),
      payload: normalized,
    );
  }

  static String _labelFor(String type) => switch (type) {
        'START_WORKOUT' => 'Iniciar treino',
        'SAVE_WORKOUT' => 'Salvar treino',
        'ADD_WORKOUT_TO_PLAN' => 'Adicionar ao plano',
        'REPLACE_EXERCISE' => 'Aplicar substituição',
        _ => 'Ação HAVOK',
      };
}
