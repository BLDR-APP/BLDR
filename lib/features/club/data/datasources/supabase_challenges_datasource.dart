import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Queries da comunidade competitiva (schema `bldr_club`), antes na
/// comunidade_screen. Não trata erros — exceções sobem para o repository.
class SupabaseChallengesDatasource {
  final SupabaseClient _client;

  SupabaseChallengesDatasource(this._client);

  Future<List<Map<String, dynamic>>> xpEvents({int limit = 50}) async {
    final rows = await _client
        .schema('bldr_club')
        .from('xp_events')
        .select('id, created_at, delta, reason, user_id')
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> profilesByIds(List<String> ids) async {
    final rows = await _client
        .from('user_profiles')
        .select('id, full_name, display_name, avatar_url')
        .filter('id', 'in', ids);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, int>> reactionCounts(List<String> eventIds) async {
    final rows = await _client
        .schema('bldr_club')
        .from('xp_reactions')
        .select('event_id')
        .filter('event_id', 'in', eventIds);
    final counts = <String, int>{};
    for (final r in (rows as List)) {
      final eid = r['event_id'].toString();
      counts[eid] = (counts[eid] ?? 0) + 1;
    }
    return counts;
  }

  /// F7: retorna Set de event_ids que o usuário já reagiu (persistido).
  Future<Set<String>> myReactions(String userId, List<String> eventIds) async {
    if (eventIds.isEmpty) return {};
    final rows = await _client
        .schema('bldr_club')
        .from('xp_reactions')
        .select('event_id')
        .eq('user_id', userId)
        .filter('event_id', 'in', eventIds);
    return {for (final r in (rows as List)) r['event_id'].toString()};
  }

  Future<void> addReaction(String userId, String eventId) =>
      _client.schema('bldr_club').from('xp_reactions').insert({
        'user_id': userId,
        'event_id': eventId,
      });

  /// F7: remove reação (toggle off).
  Future<void> removeReaction(String userId, String eventId) =>
      _client
          .schema('bldr_club')
          .from('xp_reactions')
          .delete()
          .eq('user_id', userId)
          .eq('event_id', eventId);

  Future<List<Map<String, dynamic>>> ranking({int limit = 100}) async {
    final rows = await _client
        .schema('bldr_club')
        .from('club_ranking')
        .select('user_id, display_name, avatar_url, xp_total, current_level')
        .eq('ranking_visible', true)
        .order('xp_total', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<int> rankingXp(String userId) async {
    final row = await _client
        .schema('bldr_club')
        .from('club_ranking')
        .select('xp_total')
        .eq('user_id', userId)
        .single();
    return (row['xp_total'] as num?)?.toInt() ?? 0;
  }

  Future<List<Map<String, dynamic>>> myDuels(String userId,
      {int limit = 20}) async {
    final rows = await _client
        .schema('bldr_club')
        .from('user_challenges')
        .select(
            'id, sender_id, receiver_id, target_xp, status, created_at, winner_id, expires_at')
        .or('sender_id.eq.$userId,receiver_id.eq.$userId')
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>?> profileById(String userId) async {
    try {
      final row = await _client
          .from('user_profiles')
          .select('full_name, avatar_url')
          .eq('id', userId)
          .single();
      return Map<String, dynamic>.from(row);
    } catch (_) {
      return null;
    }
  }

  Future<void> respondDuel(String duelId, bool accept) => _client
      .schema('bldr_club')
      .from('user_challenges')
      .update({'status': accept ? 'accepted' : 'declined'}).eq('id', duelId);

  Future<List<Map<String, dynamic>>> collectiveChallenges(
      {int limit = 10}) async {
    final rows = await _client
        .schema('bldr_club')
        .from('collective_challenges')
        .select(
            'id, title, description, challenge_type, target_value, current_value, reward_xp, reward_badge, cover_image_url, ends_at, status, created_by, is_official')
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> pastChallenges(String userId,
      {int limit = 20}) async {
    final participations = await _client
        .schema('bldr_club')
        .from('collective_challenge_participants')
        .select('challenge_id, contribution')
        .eq('user_id', userId);

    final partList = List<Map<String, dynamic>>.from(participations);
    if (partList.isEmpty) return [];

    final challengeIds =
        partList.map((p) => p['challenge_id'].toString()).toList();
    final contribMap = {
      for (final p in partList)
        p['challenge_id'].toString(): (p['contribution'] as num?)?.toInt() ?? 0,
    };

    final rows = await _client
        .schema('bldr_club')
        .from('collective_challenges')
        .select(
            'id, title, description, challenge_type, ends_at, status, reward_xp, cover_image_url')
        .inFilter('id', challengeIds)
        .order('ends_at', ascending: false)
        .limit(limit);

    final now = DateTime.now();
    return List<Map<String, dynamic>>.from(rows)
        .where((r) {
          final status = r['status'] as String? ?? 'active';
          final endsAt =
              DateTime.tryParse(r['ends_at']?.toString() ?? '');
          return status != 'active' ||
              (endsAt != null && endsAt.isBefore(now));
        })
        .map((r) => {
              ...r,
              'my_contribution': contribMap[r['id'].toString()] ?? 0,
            })
        .toList();
  }

  Future<Map<String, int>> participantCounts(List<String> challengeIds) async {
    final rows = await _client
        .schema('bldr_club')
        .from('collective_challenge_participants')
        .select('challenge_id')
        .inFilter('challenge_id', challengeIds);
    final counts = <String, int>{};
    for (final p in (rows as List)) {
      final cid = p['challenge_id'].toString();
      counts[cid] = (counts[cid] ?? 0) + 1;
    }
    return counts;
  }

  Future<Set<String>> joinedChallengeIds(
      String userId, List<String> challengeIds) async {
    final rows = await _client
        .schema('bldr_club')
        .from('collective_challenge_participants')
        .select('challenge_id')
        .eq('user_id', userId)
        .inFilter('challenge_id', challengeIds);
    return (rows as List).map((j) => j['challenge_id'].toString()).toSet();
  }

  Future<void> joinChallenge(String userId, String challengeId) =>
      _client.schema('bldr_club').from('collective_challenge_participants')
          .insert({'challenge_id': challengeId, 'user_id': userId});

  Future<void> leaveChallenge(String userId, String challengeId) => _client
      .schema('bldr_club')
      .from('collective_challenge_participants')
      .delete()
      .eq('challenge_id', challengeId)
      .eq('user_id', userId);

  /// Sobe a capa para o storage e retorna a URL pública (null em erro,
  /// como no comportamento original).
  Future<String?> uploadChallengeCover(String userId, String filePath) async {
    try {
      final ext = filePath.split('.').last;
      final path =
          'collective_challenges/${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _client.storage.from('Images').upload(
            path,
            File(filePath),
            fileOptions: const FileOptions(upsert: true),
          );
      return _client.storage.from('Images').getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }

  Future<void> insertCollectiveChallenge(Map<String, dynamic> data) => _client
      .schema('bldr_club')
      .from('collective_challenges')
      .insert(data);

  Future<Map<String, dynamic>?> pendingDuelInvite(String userId) async {
    final row = await _client
        .schema('bldr_club')
        .from('user_challenges')
        .select('id, sender_id')
        .eq('receiver_id', userId)
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<Map<String, dynamic>?> acceptedDuel(String userId) async {
    final row = await _client
        .schema('bldr_club')
        .from('user_challenges')
        .select('id, sender_id, receiver_id, target_xp')
        .eq('status', 'accepted')
        .or('sender_id.eq.$userId,receiver_id.eq.$userId')
        .limit(1)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<Map<String, dynamic>> rankingRow(String userId) async {
    final row = await _client
        .schema('bldr_club')
        .from('club_ranking')
        .select()
        .eq('user_id', userId)
        .single();
    return Map<String, dynamic>.from(row);
  }

  Future<void> finishDuel(String duelId, String winnerId) => _client
      .schema('bldr_club')
      .from('user_challenges')
      .update({'status': 'finished', 'winner_id': winnerId}).eq('id', duelId);

  Future<void> insertNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) =>
      _client.schema('bldr_club').from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
      });

  Future<void> insertDuel({
    required String senderId,
    required String receiverId,
    required int targetXp,
    required String expiresAtIso,
  }) =>
      _client.schema('bldr_club').from('user_challenges').insert({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'target_xp': targetXp,
        'expires_at': expiresAtIso,
      });

  // ── Notificações ──

  Future<List<Map<String, dynamic>>> notifications(String userId,
      {int limit = 50}) async {
    final rows = await _client
        .schema('bldr_club')
        .from('notifications')
        .select(
            'id, title, message, type, is_read, created_at, action_type, action_data')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> markAllNotificationsRead(String userId) => _client
      .schema('bldr_club')
      .from('notifications')
      .update({'is_read': true})
      .eq('user_id', userId)
      .eq('is_read', false);

  Future<void> markNotificationRead(String id) => _client
      .schema('bldr_club')
      .from('notifications')
      .update({'is_read': true}).eq('id', id);

  // ── Perfil público ──

  Future<Map<String, dynamic>> publicProfileRaw(String userId) async {
    final results = await Future.wait([
      _client
          .from('user_profiles')
          .select('id, full_name, avatar_url, email')
          .eq('id', userId)
          .single(),
      _client
          .schema('bldr_club')
          .from('club_ranking')
          .select('xp_total, current_level')
          .eq('user_id', userId)
          .maybeSingle(),
      _client
          .schema('bldr_club')
          .from('club_ranking')
          .select('user_id, xp_total')
          .eq('ranking_visible', true)
          .order('xp_total', ascending: false)
          .limit(200),
      _client
          .schema('bldr_club')
          .from('user_activities')
          .select('id')
          .eq('user_id', userId),
      _client
          .schema('bldr_club')
          .from('user_challenges')
          .select('status, winner_id')
          .or('sender_id.eq.$userId,receiver_id.eq.$userId')
          .eq('status', 'finished'),
      _client
          .schema('bldr_club')
          .from('xp_events')
          .select('id, delta, reason, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(3),
    ]);
    return {
      'profile': results[0],
      'rank': results[1],
      'all_ranking': results[2],
      'workouts': results[3],
      'duels': results[4],
      'events': results[5],
    };
  }

  Future<Map<String, dynamic>?> myRankingRowOrNull(String userId) async {
    final row = await _client
        .schema('bldr_club')
        .from('club_ranking')
        .select('xp_total, current_level')
        .eq('user_id', userId)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  // ── Detalhe do desafio ──

  Future<Map<String, dynamic>?> challengeById(String id) async {
    final row = await _client
        .schema('bldr_club')
        .from('collective_challenges')
        .select(
            'id, title, description, challenge_type, target_value, current_value, '
            'reward_xp, reward_badge, cover_image_url, ends_at, status, created_by, '
            'created_at, is_official, allowed_sources')
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<List<String>> participantUserIds(String challengeId) async {
    final rows = await _client
        .schema('bldr_club')
        .from('collective_challenge_participants')
        .select('user_id')
        .eq('challenge_id', challengeId);
    return (rows as List).map((p) => p['user_id'].toString()).toList();
  }

  Future<Map<String, dynamic>?> myParticipation(
      String challengeId, String userId) async {
    final row = await _client
        .schema('bldr_club')
        .from('collective_challenge_participants')
        .select('contribution')
        .eq('challenge_id', challengeId)
        .eq('user_id', userId)
        .maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<List<Map<String, dynamic>>> topContributors(String challengeId,
      {int limit = 10}) async {
    final rows = await _client
        .schema('bldr_club')
        .from('collective_challenge_participants')
        .select('user_id, contribution')
        .eq('challenge_id', challengeId)
        .order('contribution', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> xpEventsForUsers(List<String> userIds,
      {String? sinceIso, int limit = 30}) async {
    var q = _client
        .schema('bldr_club')
        .from('xp_events')
        .select('id, user_id, reason, delta, created_at')
        .filter('user_id', 'in', userIds);
    if (sinceIso != null) q = q.gte('created_at', sinceIso);
    final rows = await q.order('created_at', ascending: false).limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> completedClubWorkoutsForUsers(
      List<String> userIds,
      {String? sinceIso,
      int limit = 100}) async {
    var q = _client
        .from('club_user_workouts')
        .select(
            'user_id, name, workout_type, total_duration_seconds, completed_at')
        .filter('user_id', 'in', userIds)
        .eq('is_completed', true);
    if (sinceIso != null) q = q.gte('completed_at', sinceIso);
    final rows = await q.order('completed_at', ascending: false).limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> milestones(String challengeId) async {
    final rows = await _client
        .schema('bldr_club')
        .from('challenge_milestones')
        .select('milestone_pct, reached_at')
        .eq('challenge_id', challengeId)
        .order('milestone_pct');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> comments(String challengeId,
      {int limit = 30}) async {
    final rows = await _client
        .schema('bldr_club')
        .from('challenge_comments')
        .select('id, user_id, content, created_at')
        .eq('challenge_id', challengeId)
        .order('created_at', ascending: false)
        .limit(limit);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> insertComment(
          String challengeId, String userId, String content) =>
      _client.schema('bldr_club').from('challenge_comments').insert({
        'challenge_id': challengeId,
        'user_id': userId,
        'content': content,
      });

  Future<void> updateChallenge(
          String challengeId, Map<String, dynamic> updates) =>
      _client
          .schema('bldr_club')
          .from('collective_challenges')
          .update(updates)
          .eq('id', challengeId);

  Future<void> insertReport(
          String challengeId, String userId, String reason) =>
      _client.schema('bldr_club').from('challenge_reports').insert({
        'challenge_id': challengeId,
        'reported_by': userId,
        'reason': reason,
      });
}
