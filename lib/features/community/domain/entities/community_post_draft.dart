import 'package:bldr_fitness/features/community/domain/entities/community_post_payload.dart';
import 'package:bldr_fitness/features/community/domain/entities/recent_workout.dart';

/// PR anexado ao post de treino.
class CommunityDraftPr {
  final String exerciseName;
  final double weightKg;
  final double? e1rm;

  const CommunityDraftPr({
    required this.exerciseName,
    required this.weightKg,
    this.e1rm,
  });
}

/// Rascunho de publicação: define o tipo do evento e monta o payload.
/// Treino e wearable são exclusivos; a foto pode acompanhar qualquer um.
class CommunityPostDraft {
  final String caption;
  final String? workoutId;
  final String? workoutSource;
  final RecentWorkout? workout;
  final bool includePrs;
  final List<CommunityDraftPr> prs;
  final Map<String, dynamic>? wearable;
  final String? photoUrl;

  const CommunityPostDraft({
    this.caption = '',
    this.workoutId,
    this.workoutSource,
    this.workout,
    this.includePrs = true,
    this.prs = const [],
    this.wearable,
    this.photoUrl,
  });

  String get eventType => workoutId != null
      ? 'workout_completed'
      : wearable != null
          ? 'wearable_activity'
          : 'manual';

  Map<String, dynamic> toPayload() {
    final text = caption.trim();
    final selected = workout;
    return {
      'version': CommunityPostPayload.currentVersion,
      'kind': workoutId != null
          ? CommunityPayloadKind.workout.name
          : wearable != null
              ? CommunityPayloadKind.wearable.name
              : CommunityPayloadKind.manual.name,
      if (text.isNotEmpty) 'caption': text,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (workoutId != null) ...{
        'workout_id': workoutId,
        'source': workoutSource ?? 'free',
        if (selected != null) ...{
          'workout_name': selected.name,
          'volume_kg': selected.volumeKg,
          'set_count': selected.completedSetCount,
          'duration_s': selected.durationSeconds,
          'muscle_groups': selected.muscleGroups,
        },
        if (includePrs) ...{
          'include_prs': true,
          if (prs.isNotEmpty)
            'prs': [
              for (final pr in prs)
                {
                  'exercise_name': pr.exerciseName,
                  'weight_kg': pr.weightKg,
                  if (pr.e1rm != null) 'e1rm': pr.e1rm,
                },
            ],
        },
      } else if (wearable != null)
        'wearable': wearable,
    };
  }
}
