import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/features/community/domain/entities/community_post_draft.dart';
import 'package:bldr_fitness/features/community/domain/entities/recent_workout.dart';

void main() {
  test('treino com foto, legenda e PRs', () {
    const draft = CommunityPostDraft(
      caption: ' Push ',
      workoutId: 'w',
      workoutSource: 'club',
      workout:
          RecentWorkout(id: 'w', name: 'Push', source: 'club', volumeKg: 100),
      prs: [CommunityDraftPr(exerciseName: 'Supino', weightKg: 100, e1rm: 110)],
      photoUrl: 'url',
    );
    final p = draft.toPayload();
    expect(draft.eventType, 'workout_completed');
    expect(p['kind'], 'workout');
    expect(p['caption'], 'Push');
    expect(p['photo_url'], 'url');
    expect(p['source'], 'club');
    expect(p['workout_name'], 'Push');
    expect((p['prs'] as List).single['e1rm'], 110);
  });

  test('desligar PRs não envia a lista', () {
    final p = const CommunityPostDraft(
      workoutId: 'w',
      includePrs: false,
      prs: [CommunityDraftPr(exerciseName: 'Supino', weightKg: 100)],
    ).toPayload();
    expect(p.containsKey('prs'), isFalse);
    expect(p.containsKey('include_prs'), isFalse);
    expect(p['source'], 'free');
  });

  test('wearable e post manual', () {
    const wearable = CommunityPostDraft(wearable: {'provider': 'whoop'});
    expect(wearable.eventType, 'wearable_activity');
    expect(wearable.toPayload()['wearable'], {'provider': 'whoop'});

    const manual = CommunityPostDraft(caption: 'oi');
    expect(manual.eventType, 'manual');
    expect(manual.toPayload()['kind'], 'manual');
    expect(manual.toPayload().containsKey('workout_id'), isFalse);
  });
}
