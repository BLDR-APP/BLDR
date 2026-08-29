import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/features/community/domain/entities/community_post.dart';
import 'package:bldr_fitness/features/community/domain/repositories/community_feed_repository.dart';

class CommunityFeedRepositoryImpl implements CommunityFeedRepository {
  final SupabaseClient _client;

  const CommunityFeedRepositoryImpl(this._client);

  String get _uid => _client.auth.currentUser!.id;

  @override
  Future<List<CommunityPost>> fetchFeed({
    int limit = 20,
    DateTime? before,
  }) async {
    var query = _client
        .from('community_feed')
        .select('''
          id,
          user_id,
          event_type,
          payload,
          visibility,
          created_at,
          comment_count,
          user_profiles!community_feed_user_id_fkey (
            username,
            full_name,
            avatar_url
          ),
          reactions:community_reactions (
            emoji,
            user_id
          )
        ''')
        .eq('visibility', 'public');

    if (before != null) {
      query = query.lt('created_at', before.toUtc().toIso8601String());
    }

    final rows = await query
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List).map((row) {
      final json = Map<String, dynamic>.from(row as Map);

      // Agrupar reactions por emoji e calcular minha reação
      final rawReactions = (json['reactions'] as List?) ?? [];
      final reactionMap = <String, int>{};
      String? myEmoji;
      for (final r in rawReactions) {
        final m = r as Map;
        final emoji = m['emoji'] as String;
        reactionMap[emoji] = (reactionMap[emoji] ?? 0) + 1;
        if (m['user_id'] == _uid) myEmoji = emoji;
      }
      json['reactions'] = reactionMap.entries
          .map((e) => {'emoji': e.key, 'count': e.value})
          .toList();
      json['my_reaction'] = myEmoji;

      // user_profiles pode vir como lista em FK joins do Supabase
      final profiles = json['user_profiles'];
      if (profiles is List && profiles.isNotEmpty) {
        json['user_profiles'] = profiles.first;
      } else if (profiles is List) {
        json['user_profiles'] = null;
      }

      return CommunityPost.fromJson(json);
    }).toList();
  }

  @override
  Future<void> createPost({
    required String eventType,
    required Map<String, dynamic> payload,
    required String visibility,
  }) async {
    await _client.from('community_feed').insert({
      'user_id': _uid,
      'event_type': eventType,
      'payload': payload,
      'visibility': visibility,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> toggleReaction({
    required String feedId,
    required String emoji,
  }) async {
    final existing = await _client
        .from('community_reactions')
        .select('id')
        .eq('feed_id', feedId)
        .eq('user_id', _uid)
        .eq('emoji', emoji)
        .maybeSingle();

    if (existing != null) {
      await _client
          .from('community_reactions')
          .delete()
          .eq('feed_id', feedId)
          .eq('user_id', _uid)
          .eq('emoji', emoji);
    } else {
      await _client.from('community_reactions').insert({
        'feed_id': feedId,
        'user_id': _uid,
        'emoji': emoji,
      });
    }
  }

  @override
  Future<String> copyWorkout({
    required String workoutId,
    required String source,
  }) async {
    final result = await _client.rpc(
      'copy_workout_to_template',
      params: {'p_workout_id': workoutId, 'p_source': source},
    );
    return result as String;
  }

  @override
  Future<void> postStreakMilestone({required int days}) async {
    await _client.from('community_feed').insert({
      'user_id': _uid,
      'event_type': 'streak_milestone',
      'payload': {'days': days},
      'visibility': 'public',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
