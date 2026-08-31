import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_post.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_comment.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_profile.dart';
import 'package:bldr_fitness/features/community/domain/entities/ranking_entry.dart';
import 'package:bldr_fitness/features/community/domain/entities/recent_workout.dart';
import 'package:bldr_fitness/features/community/domain/entities/workout_exercise.dart';
import 'package:bldr_fitness/features/community/domain/repositories/community_feed_repository.dart';
import 'package:bldr_fitness/features/integrations/data/health_kit_service.dart';

class CommunityFeedRepositoryImpl implements CommunityFeedRepository {
  final SupabaseClient _client;
  final HealthKitService _healthKitService;

  const CommunityFeedRepositoryImpl(this._client, this._healthKitService);

  String get _uid => _client.auth.currentUser!.id;

  // ── fetchFeed ──────────────────────────────────────────────────────────────
  //
  // Correções em relação à versão anterior:
  //  D1: removido 'comment_count' (coluna não existe em community_feed)
  //  D2: removido join 'user_profiles!community_feed_user_id_fkey' (FK inexistente).
  //      Perfis são buscados em lote após os posts e mesclados em memória.
  //  D7: erros retornam Result.failure em vez de serem silenciados.
  @override
  Future<Result<List<CommunityPost>>> fetchFeed({
    int limit = 20,
    DateTime? before,
  }) =>
      _fetchPublicFeed(limit: limit, before: before);

  @override
  Future<Result<List<CommunityPost>>> fetchFollowingFeed({
    int limit = 20,
    DateTime? before,
  }) async {
    try {
      final rows = await _client
          .from('community_follows')
          .select('followed_id')
          .eq('follower_id', _uid) as List;
      final followedIds = rows
          .map((row) => (row as Map)['followed_id'] as String)
          .toSet()
          .toList();
      if (followedIds.isEmpty) return const Result.success([]);
      return _fetchPublicFeed(
        limit: limit,
        before: before,
        authorIds: followedIds,
      );
    } catch (e) {
      return Result.failure(ServerFailure(
        'Não foi possível carregar o feed Seguindo.',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<List<CommunityPost>>> fetchPrivatePosts({int limit = 50}) =>
      _fetchPublicFeed(
        limit: limit,
        authorIds: [_uid],
        visibility: 'private',
      );

  @override
  Future<Result<List<CommunityPost>>> fetchSquadFeed(
    String squadId, {
    int limit = 50,
  }) =>
      _fetchPublicFeed(
        limit: limit,
        visibility: 'squad',
        squadId: squadId,
      );

  Future<Result<List<CommunityPost>>> _fetchPublicFeed({
    required int limit,
    DateTime? before,
    List<String>? authorIds,
    String? captionQuery,
    String visibility = 'public',
    String? squadId,
  }) async {
    try {
      // 1. Buscar posts sem join de perfil
      var query = _client.from('community_feed').select('''
            id,
            user_id,
            event_type,
            payload,
            visibility,
            squad_id,
            created_at,
            reactions:community_reactions (
              emoji,
              user_id
            ),
            comments:community_comments (id)
          ''').eq('visibility', visibility);

      if (before != null) {
        query = query.lt('created_at', before.toUtc().toIso8601String());
      }
      if (authorIds != null) {
        query = query.inFilter('user_id', authorIds);
      }
      if (captionQuery != null) {
        query = query.ilike('payload->>caption', '%$captionQuery%');
      }
      if (squadId != null) {
        query = query.eq('squad_id', squadId);
      }

      final rows = await query
          .order('created_at', ascending: false)
          .limit(limit) as List;

      if (rows.isEmpty) return const Result.success([]);

      // 2. Coletar user_ids distintos
      final userIds =
          rows.map((r) => (r as Map)['user_id'] as String).toSet().toList();

      final followingIds = <String>{};
      try {
        final followingRows = await _client
            .from('community_follows')
            .select('followed_id')
            .eq('follower_id', _uid)
            .inFilter('followed_id', userIds) as List;
        followingIds.addAll(
            followingRows.map((row) => (row as Map)['followed_id'] as String));
      } catch (_) {
        // O feed continua utilizável se o social graph estiver indisponível.
      }

      final blockedIds = <String>{};
      try {
        final blockedRows = await _client
            .from('community_blocks')
            .select('blocked_id')
            .eq('blocker_id', _uid)
            .inFilter('blocked_id', userIds) as List;
        blockedIds.addAll(
            blockedRows.map((row) => (row as Map)['blocked_id'] as String));
      } catch (_) {
        // Compatibilidade enquanto a migration de segurança aguarda aplicação.
      }

      final clubMemberIds = <String>{};
      try {
        final metadataRows = await _client.rpc(
          'community_author_metadata',
          params: {'p_user_ids': userIds},
        ) as List;
        clubMemberIds.addAll(metadataRows.where((row) {
          return (row as Map)['is_club_member'] == true;
        }).map((row) => (row as Map)['user_id'] as String));
      } catch (_) {
        // A assinatura de terceiros não é consultada diretamente por causa da RLS.
      }

      // 3. Buscar perfis em lote (uma única query)
      final profileRows = await _client
          .from('user_profiles')
          .select('id, username, full_name, avatar_url')
          .inFilter('id', userIds) as List;

      final profilesById = <String, Map<String, dynamic>>{
        for (final p in profileRows)
          (p as Map<String, dynamic>)['id'] as String: p,
      };

      // 4. Montar entidades
      final posts = <CommunityPost>[];
      for (final row in rows) {
        final json = Map<String, dynamic>.from(row as Map);
        final authorId = json['user_id'] as String;
        if (blockedIds.contains(authorId)) continue;

        // Agregar reactions por emoji e detectar minha reação
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
        json['comment_count'] = (json['comments'] as List?)?.length ?? 0;

        // Injetar perfil buscado em lote
        final profile = profilesById[json['user_id'] as String];
        json['user_profiles'] =
            profile; // null é tratado com segurança em fromJson
        json['is_club_member'] = clubMemberIds.contains(authorId);
        json['is_following'] = followingIds.contains(authorId);
        json['is_own_post'] = authorId == _uid;

        posts.add(CommunityPost.fromJson(json));
      }

      return Result.success(posts);
    } catch (e) {
      return Result.failure(
        ServerFailure('Não foi possível carregar o feed.', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> followUser(String userId) async {
    try {
      if (userId == _uid) {
        return const Result.failure(
          ValidationFailure('Você não pode seguir a si mesmo.'),
        );
      }
      await _client.from('community_follows').upsert({
        'follower_id': _uid,
        'followed_id': userId,
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(
        'Não foi possível seguir este atleta.',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<void>> unfollowUser(String userId) async {
    try {
      await _client
          .from('community_follows')
          .delete()
          .eq('follower_id', _uid)
          .eq('followed_id', userId);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(
        'Não foi possível deixar de seguir este atleta.',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<void>> deletePost(String postId) async {
    try {
      await _client
          .from('community_feed')
          .delete()
          .eq('id', postId)
          .eq('user_id', _uid);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(
        'Não foi possível excluir este post.',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<void>> blockUser(String userId) async {
    try {
      if (userId == _uid) {
        return const Result.failure(
          ValidationFailure('Você não pode bloquear a si mesmo.'),
        );
      }
      await _client.from('community_blocks').upsert({
        'blocker_id': _uid,
        'blocked_id': userId,
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(
        'Não foi possível bloquear este usuário.',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<void>> reportUser({
    required String userId,
    required String feedId,
    required String reason,
    String? details,
  }) async {
    try {
      if (userId == _uid) {
        return const Result.failure(
          ValidationFailure('Você não pode denunciar a si mesmo.'),
        );
      }
      await _client.from('community_reports').insert({
        'reporter_id': _uid,
        'reported_user_id': userId,
        'feed_id': feedId,
        'reason': reason,
        if (details != null && details.trim().isNotEmpty)
          'details': details.trim(),
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(
        'Não foi possível enviar a denúncia.',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<List<CommunityProfile>>> searchProfiles(String query) async {
    try {
      final term = query.trim();
      if (term.length < 2) return const Result.success([]);
      final rows = await _client
          .from('user_profiles')
          .select('id, username, full_name, avatar_url')
          .or('username.ilike.%$term%,full_name.ilike.%$term%')
          .neq('id', _uid)
          .limit(30) as List;
      final followingRows = await _client
          .from('community_follows')
          .select('followed_id')
          .eq('follower_id', _uid) as List;
      final following = followingRows
          .map((row) => (row as Map)['followed_id'] as String)
          .toSet();
      return Result.success(rows.map((raw) {
        final row = raw as Map;
        final id = row['id'] as String;
        return CommunityProfile(
          id: id,
          username: row['username'] as String?,
          fullName: row['full_name'] as String?,
          avatarUrl: row['avatar_url'] as String?,
          isFollowing: following.contains(id),
        );
      }).toList());
    } catch (e) {
      return Result.failure(ServerFailure(
        'Não foi possível buscar atletas.',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<List<CommunityPost>>> searchPublicPosts(String query) {
    final term = query.trim();
    if (term.length < 2) return Future.value(const Result.success([]));
    return _fetchPublicFeed(limit: 30, captionQuery: term);
  }

  @override
  Future<Result<List<CommunityComment>>> fetchComments(String feedId) async {
    try {
      final post = await _client
          .from('community_feed')
          .select('user_id')
          .eq('id', feedId)
          .single();
      final postOwnerId = post['user_id'] as String;
      final rows = await _client
          .from('community_comments')
          .select(
              'id, feed_id, user_id, parent_id, body, created_at, updated_at')
          .eq('feed_id', feedId)
          .order('created_at') as List;
      final userIds =
          rows.map((row) => (row as Map)['user_id'] as String).toSet().toList();
      final profileRows = userIds.isEmpty
          ? const <dynamic>[]
          : await _client
              .from('user_profiles')
              .select('id, username, full_name, avatar_url')
              .inFilter('id', userIds) as List;
      final profiles = <String, Map>{
        for (final raw in profileRows) (raw as Map)['id'] as String: raw,
      };
      CommunityComment parse(dynamic raw) {
        final row = raw as Map;
        final userId = row['user_id'] as String;
        final profile = profiles[userId];
        return CommunityComment(
          id: row['id'] as String,
          feedId: row['feed_id'] as String,
          userId: userId,
          parentId: row['parent_id'] as String?,
          body: row['body'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
          updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? ''),
          username: profile?['username'] as String?,
          fullName: profile?['full_name'] as String?,
          avatarUrl: profile?['avatar_url'] as String?,
          canEdit: userId == _uid,
          canDelete: userId == _uid || postOwnerId == _uid,
        );
      }

      final parsed = rows.map(parse).toList();
      final replies = <String, List<CommunityComment>>{};
      for (final comment in parsed.where((item) => item.parentId != null)) {
        replies.putIfAbsent(comment.parentId!, () => []).add(comment);
      }
      return Result.success(parsed
          .where((item) => item.parentId == null)
          .map((item) => item.copyWith(replies: replies[item.id] ?? const []))
          .toList());
    } catch (e) {
      return Result.failure(ServerFailure(
        'Não foi possível carregar os comentários.',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<void>> addComment({
    required String feedId,
    required String body,
    String? parentId,
  }) async {
    final text = body.trim();
    if (text.isEmpty || text.length > 300) {
      return const Result.failure(
        ValidationFailure('O comentário deve ter entre 1 e 300 caracteres.'),
      );
    }
    try {
      await _client.from('community_comments').insert({
        'feed_id': feedId,
        'user_id': _uid,
        'body': text,
        if (parentId != null) 'parent_id': parentId,
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(
        'Não foi possível enviar o comentário.',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<void>> editComment(
      {required String id, required String body}) async {
    final text = body.trim();
    if (text.isEmpty || text.length > 300) {
      return const Result.failure(
        ValidationFailure('O comentário deve ter entre 1 e 300 caracteres.'),
      );
    }
    try {
      await _client.from('community_comments').update({
        'body': text,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(
        'Não foi possível editar o comentário.',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<void>> deleteComment(String id) async {
    try {
      await _client.from('community_comments').delete().eq('id', id);
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(
        'Não foi possível excluir o comentário.',
        cause: e,
      ));
    }
  }

  // ── createPost ─────────────────────────────────────────────────────────────

  @override
  Future<Result<void>> createPost({
    required String eventType,
    required Map<String, dynamic> payload,
    required String visibility,
    String? squadId,
  }) async {
    try {
      await _client.from('community_feed').insert({
        'user_id': _uid,
        'event_type': eventType,
        'payload': payload,
        'visibility': visibility,
        if (squadId != null) 'squad_id': squadId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(
        'Não foi possível publicar o post.',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<Map<String, dynamic>?>> detectRecentWearableActivity() async {
    final result = await fetchWearableActivities('whoop');
    return result.map((activities) => activities.firstOrNull);
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> fetchWearableActivities(
    String provider,
  ) async {
    if (provider == 'apple_watch' || provider == 'apple_health') {
      try {
        final permissionRequested = await _healthKitService.requestPermission();
        if (!permissionRequested) {
          return const Result.failure(ValidationFailure(
            'Autorize o acesso aos treinos no app Saúde para importar atividades do Apple Watch.',
          ));
        }
        final activities = await _healthKitService.fetchRecentWorkouts();
        return Result.success(activities);
      } catch (e) {
        return Result.failure(ServerFailure(
          'Não foi possível consultar os treinos do Apple Watch. Verifique as permissões do app Saúde.',
          cause: e,
        ));
      }
    }
    if (provider != 'whoop') {
      return Result.failure(ValidationFailure(
        provider == 'garmin'
            ? 'Garmin ainda não foi configurado.'
            : 'Wearable não suportado.',
      ));
    }
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) {
        return const Result.failure(AuthFailure('Usuário não autenticado.'));
      }
      final response = await _client.functions.invoke('whoop-workouts');
      if (response.status != 200) {
        final message = response.data is Map
            ? (response.data as Map)['error']?.toString()
            : null;
        return Result.failure(ServerFailure(
          message ?? 'Não foi possível carregar atividades Whoop.',
        ));
      }
      final data = Map<String, dynamic>.from(response.data as Map);
      final activities = (data['activities'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      return Result.success(activities);
    } catch (e) {
      return Result.failure(ServerFailure(
        'Não foi possível consultar atividades Whoop.',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<String>> uploadCommunityPhoto({
    required Uint8List bytes,
    required String extension,
  }) async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) {
        return const Result.failure(AuthFailure('Usuário não autenticado.'));
      }
      final cleaned =
          extension.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
      final suffix = cleaned.isEmpty ? 'jpg' : cleaned;
      final path = '$uid/${DateTime.now().microsecondsSinceEpoch}.$suffix';
      await _client.storage.from('community-posts').uploadBinary(path, bytes);
      return Result.success(
        _client.storage.from('community-posts').getPublicUrl(path),
      );
    } catch (e) {
      return Result.failure(ServerFailure(
        'Não foi possível enviar a foto. Tente novamente.',
        cause: e,
      ));
    }
  }

  // ── toggleReaction ─────────────────────────────────────────────────────────

  @override
  Future<Result<void>> toggleReaction({
    required String feedId,
    required String emoji,
  }) async {
    try {
      final existingRows = await _client
          .from('community_reactions')
          .select('id, emoji')
          .eq('feed_id', feedId)
          .eq('user_id', _uid) as List;
      final hasSameReaction = existingRows.any(
        (row) => (row as Map)['emoji'] == emoji,
      );

      if (existingRows.isNotEmpty) {
        await _client
            .from('community_reactions')
            .delete()
            .eq('feed_id', feedId)
            .eq('user_id', _uid);
      }
      if (!hasSameReaction) {
        await _client.from('community_reactions').insert({
          'feed_id': feedId,
          'user_id': _uid,
          'emoji': emoji,
        });
      }
      return const Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure(
        'Não foi possível atualizar a reação.',
        cause: e,
      ));
    }
  }

  // ── copyWorkout ────────────────────────────────────────────────────────────

  @override
  Future<Result<String>> copyWorkout({
    required String workoutId,
    required String source,
  }) async {
    try {
      final result = await _client.rpc(
        'copy_workout_to_template',
        params: {'p_workout_id': workoutId, 'p_source': source},
      );
      return Result.success(result as String);
    } catch (e) {
      return Result.failure(ServerFailure(
        'Não foi possível copiar o treino.',
        cause: e,
      ));
    }
  }

  // ── postStreakMilestone ────────────────────────────────────────────────────

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

  // ── fetchRecentWorkouts ────────────────────────────────────────────────────

  @override
  Future<Result<List<RecentWorkout>>> fetchRecentWorkouts() async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) {
        return const Result.failure(AuthFailure('Usuário não autenticado.'));
      }

      Future<List<dynamic>?> loadFree() async {
        try {
          return await _client
              .from('user_workouts')
              .select(
                  'id, workout_template_id, completed_at, volume_kg, muscle_groups, total_duration_seconds')
              .eq('user_id', uid)
              .eq('is_completed', true)
              .order('completed_at', ascending: false)
              .limit(5) as List;
        } catch (_) {
          return null;
        }
      }

      Future<List<dynamic>?> loadClub() async {
        try {
          return await _client
              .from('club_user_workouts')
              .select(
                  'id, workout_template_id, completed_at, volume_kg, muscle_groups, total_duration_seconds')
              .eq('user_id', uid)
              .eq('is_completed', true)
              .order('completed_at', ascending: false)
              .limit(5) as List;
        } catch (_) {
          return null;
        }
      }

      final results = await Future.wait([loadFree(), loadClub()]);
      if (results.every((rows) => rows == null)) {
        return const Result.failure(ServerFailure(
          'Não foi possível carregar os treinos recentes.',
        ));
      }

      final combined = <Map<String, dynamic>>[];
      for (final row in results[0] ?? const <dynamic>[]) {
        combined.add({...row as Map<String, dynamic>, 'source': 'free'});
      }
      for (final row in results[1] ?? const <dynamic>[]) {
        combined.add({...row as Map<String, dynamic>, 'source': 'club'});
      }
      combined.sort((a, b) {
        final aTs = a['completed_at'] as String? ?? '';
        final bTs = b['completed_at'] as String? ?? '';
        return bTs.compareTo(aTs);
      });
      final top5 = combined.take(5).toList();

      final workouts = <RecentWorkout>[];
      await Future.wait(top5.map((row) async {
        final templateId = row['workout_template_id'] as String?;
        final source = row['source'] as String;
        String name = 'Treino';

        if (templateId != null) {
          try {
            final table = source == 'club'
                ? 'club_workout_templates'
                : 'workout_templates';
            final tmpl = await _client
                .from(table)
                .select('name')
                .eq('id', templateId)
                .maybeSingle();
            name = tmpl?['name'] as String? ?? 'Treino';
          } catch (_) {}
        }

        final rawMuscles = row['muscle_groups'];
        final muscles = rawMuscles is List
            ? rawMuscles.map((m) => m.toString()).toList()
            : <String>[];

        int? completedSetCount;
        try {
          final setsTable = source == 'club'
              ? 'club_workout_exercise_sets'
              : 'workout_exercise_sets';
          final completedSets = await _client
              .from(setsTable)
              .select('id')
              .eq('user_workout_id', row['id'] as String)
              .not('completed_at', 'is', null) as List;
          completedSetCount = completedSets.length;
        } catch (_) {
          // A indisponibilidade das séries não deve ocultar o treino recente.
        }

        final completedAt = row['completed_at'] as String?;
        workouts.add(RecentWorkout(
          id: row['id'] as String,
          name: name,
          source: source,
          completedAt:
              completedAt != null ? DateTime.tryParse(completedAt) : null,
          volumeKg: (row['volume_kg'] as num?)?.toDouble(),
          durationSeconds: row['total_duration_seconds'] as int?,
          completedSetCount: completedSetCount,
          muscleGroups: muscles,
        ));
      }));

      workouts.sort((a, b) {
        final aTs = a.completedAt?.toIso8601String() ?? '';
        final bTs = b.completedAt?.toIso8601String() ?? '';
        return bTs.compareTo(aTs);
      });

      return Result.success(workouts);
    } catch (e) {
      return Result.failure(ServerFailure(
        'Não foi possível carregar os treinos recentes.',
        cause: e,
      ));
    }
  }

  // ── fetchWorkoutExercises ──────────────────────────────────────────────────

  @override
  Future<Result<List<WorkoutExercise>>> fetchWorkoutExercises({
    required String workoutId,
    required String source,
  }) async {
    try {
      final table = source == 'club'
          ? 'club_workout_exercise_sets'
          : 'workout_exercise_sets';

      final rows = await _client
          .from(table)
          .select('exercise_id, free_name, weight_kg, reps, created_at')
          .eq('user_workout_id', workoutId)
          .not('completed_at', 'is', null)
          .order('created_at') as List;

      final grouped = <String, List<WorkoutSet>>{};
      final names = <String, String>{};
      for (final row in rows) {
        final key = (row['exercise_id'] as String?) ??
            (row['free_name'] as String?) ??
            'Exercício';
        names.putIfAbsent(key, () => row['free_name'] as String? ?? key);
        grouped.putIfAbsent(key, () => []);
        final weight = (row['weight_kg'] as num?)?.toDouble();
        final reps = row['reps'] as int?;
        if (weight != null || reps != null) {
          grouped[key]!.add(WorkoutSet(weightKg: weight, reps: reps));
        }
      }

      final exercises = grouped.entries
          .map((e) => WorkoutExercise(name: names[e.key]!, sets: e.value))
          .toList();

      return Result.success(exercises);
    } catch (e) {
      return Result.failure(ServerFailure(
        'Não foi possível carregar os exercícios.',
        cause: e,
      ));
    }
  }

  // ── fetchRanking ───────────────────────────────────────────────────────────
  //
  // D3: usa p_period (correto) em vez de p_start (incorreto).
  // D5: valores de period assumidos como 'week', 'month', 'all'.
  //     Requer confirmação contra assinatura real das RPCs no Supabase.
  @override
  Future<Result<List<RankingEntry>>> fetchRanking({
    required String category,
    required String period,
  }) async {
    try {
      final uid = _client.auth.currentUser?.id;
      final rpcName = switch (category) {
        'volume' => 'ranking_volume',
        'consistency' => 'ranking_consistency',
        'progression' => 'ranking_progression',
        _ => throw ArgumentError('Categoria inválida: $category'),
      };

      final rows = await _client.rpc(
        rpcName,
        params: {'p_period': period},
      ) as List;

      final entries = rows
          .asMap()
          .entries
          .map((e) => RankingEntry.fromRow(
                Map<String, dynamic>.from(e.value as Map),
                currentUserId: uid,
                position: e.key + 1,
              ))
          .toList();

      return Result.success(entries);
    } catch (e) {
      return Result.failure(
        ServerFailure('Não foi possível carregar o ranking.', cause: e),
      );
    }
  }
}
