import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_post.dart';
import 'package:bldr_fitness/features/community/domain/entities/ranking_entry.dart';
import 'package:bldr_fitness/features/community/domain/entities/recent_workout.dart';
import 'package:bldr_fitness/features/community/domain/entities/workout_exercise.dart';
import 'package:bldr_fitness/features/community/domain/repositories/community_feed_repository.dart';

class CommunityFeedRepositoryImpl implements CommunityFeedRepository {
  final SupabaseClient _client;

  const CommunityFeedRepositoryImpl(this._client);

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
  }) async {
    try {
      // 1. Buscar posts sem join de perfil
      var query = _client
          .from('community_feed')
          .select('''
            id,
            user_id,
            event_type,
            payload,
            visibility,
            created_at,
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
          .limit(limit) as List;

      if (rows.isEmpty) return const Result.success([]);

      // 2. Coletar user_ids distintos
      final userIds = rows
          .map((r) => (r as Map)['user_id'] as String)
          .toSet()
          .toList();

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

        // Injetar perfil buscado em lote
        final profile = profilesById[json['user_id'] as String];
        json['user_profiles'] = profile; // null é tratado com segurança em fromJson

        posts.add(CommunityPost.fromJson(json));
      }

      return Result.success(posts);
    } catch (e) {
      return Result.failure(
        ServerFailure('Não foi possível carregar o feed.', cause: e),
      );
    }
  }

  // ── createPost ─────────────────────────────────────────────────────────────

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

  // ── toggleReaction ─────────────────────────────────────────────────────────

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

  // ── copyWorkout ────────────────────────────────────────────────────────────

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

      final results = await Future.wait([
        _client
            .from('user_workouts')
            .select('id, workout_template_id, completed_at, volume_kg, muscle_groups, total_duration_seconds')
            .eq('user_id', uid)
            .eq('is_completed', true)
            .order('completed_at', ascending: false)
            .limit(5),
        _client
            .from('club_user_workouts')
            .select('id, workout_template_id, completed_at, volume_kg, muscle_groups, total_duration_seconds')
            .eq('user_id', uid)
            .eq('is_completed', true)
            .order('completed_at', ascending: false)
            .limit(5),
      ]);

      final combined = <Map<String, dynamic>>[];
      for (final row in results[0] as List) {
        combined.add({...row as Map<String, dynamic>, 'source': 'free'});
      }
      for (final row in results[1] as List) {
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

        final completedAt = row['completed_at'] as String?;
        workouts.add(RecentWorkout(
          id: row['id'] as String,
          name: name,
          source: source,
          completedAt:
              completedAt != null ? DateTime.tryParse(completedAt) : null,
          volumeKg: (row['volume_kg'] as num?)?.toDouble(),
          durationSeconds: row['total_duration_seconds'] as int?,
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
          .map((r) => RankingEntry.fromRow(
                Map<String, dynamic>.from(r as Map),
                currentUserId: uid,
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
