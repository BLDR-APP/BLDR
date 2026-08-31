import 'package:bldr_fitness/features/club/domain/entities/havok_action.dart';

/// Validates the model proposal before the UI can present it. Mutation is not
/// performed here: a user must explicitly confirm in the existing workout UI.
class HavokActionController {
  const HavokActionController();

  List<HavokActionProposal> supportedActions(
    Map<String, dynamic>? responseData, {
    required bool hasCanonicalWorkout,
  }) {
    if (!hasCanonicalWorkout) return const [];
    final raw = responseData?['actions'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((row) =>
            HavokActionProposal.fromMap(Map<String, dynamic>.from(row)))
        .whereType<HavokActionProposal>()
        .toList(growable: false);
  }

  /// Applies only an already server-resolved replacement to the in-memory
  /// artifact. It does not write anything; the normal workout UI remains the
  /// single owner of save/start/plan mutations.
  Map<String, dynamic>? workoutForAction(
    Map<String, dynamic> workout,
    HavokActionProposal action,
  ) {
    if (action.type != 'REPLACE_EXERCISE') return workout;
    final exercises = workout['exercicios'] ?? workout['exercises'];
    if (exercises is! List) return null;
    final targetId = action.payload['target_exercise_id'];
    final replacementId = action.payload['replacement_exercise_id'];
    final replacementName = action.payload['replacement_name'];
    if (targetId is! String ||
        replacementId is! String ||
        replacementName is! String) return null;
    var replaced = false;
    final updated = exercises.map((item) {
      if (item is! Map) return item;
      final exercise = Map<String, dynamic>.from(item);
      if (exercise['exercise_id'] != targetId) return exercise;
      replaced = true;
      return {
        ...exercise,
        'exercise_id': replacementId,
        'exercise_db_id': action.payload['replacement_exercise_db_id'],
        'nome': replacementName,
        'resolution': 'RESOLVED',
      };
    }).toList(growable: false);
    if (!replaced) return null;
    return {...workout, 'canonical': true, 'exercicios': updated};
  }
}
