import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/club/domain/repositories/arena_repository.dart';

class ArenaRepositoryImpl implements ArenaRepository {
  final supabase.SupabaseClient _client;
  final String? Function() _currentUserId;

  ArenaRepositoryImpl(this._client, this._currentUserId);

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Result.success(await action());
    } on Failure catch (f) {
      return Result.failure(f);
    } on supabase.PostgrestException catch (e) {
      return Result.failure(ServerFailure(e.message, cause: e));
    } on supabase.StorageException catch (e) {
      return Result.failure(ServerFailure(e.message, cause: e));
    } on SocketException catch (e) {
      return Result.failure(NetworkFailure('Sem conexão com a internet.', e));
    } on TimeoutException catch (e) {
      return Result.failure(NetworkFailure('Tempo de conexão esgotado.', e));
    } catch (e) {
      return Result.failure(UnexpectedFailure('Ocorreu um erro inesperado.', e));
    }
  }

  String _requireUser() {
    final uid = _currentUserId();
    if (uid == null) throw const AuthFailure('Usuário não autenticado.');
    return uid;
  }

  supabase.SupabaseQuerySchema get _club => _client.schema('bldr_club');

  Future<Map<String, Map<String, dynamic>>> _profilesFor(
      List<dynamic> userIds) async {
    if (userIds.isEmpty) return {};
    final rows = await _client
        .from('user_profiles')
        .select('id, full_name, avatar_url')
        .filter('id', 'in', '(${userIds.map((e) => '"$e"').join(',')})');
    return {
      for (final p in (rows as List))
        p['id'].toString(): Map<String, dynamic>.from(p as Map)
    };
  }

  // ── Arena / Squad ──

  @override
  Future<Result<Map<String, dynamic>?>> arenaById(String arenaId) =>
      _guard(() async {
        final row =
            await _club.from('arenas').select('*').eq('id', arenaId).single();
        return Map<String, dynamic>.from(row);
      });

  @override
  Future<Result<Map<String, dynamic>?>> findArenaByCode(String code) =>
      _guard(() async {
        final byShare = await _club
            .from('arenas')
            .select()
            .eq('share_code', code)
            .maybeSingle();
        if (byShare != null) return Map<String, dynamic>.from(byShare);
        // UUIDs têm 36 chars; com menos nem tenta o id (evita erro de tipo).
        if (code.length == 36) {
          final byId =
              await _club.from('arenas').select().eq('id', code).maybeSingle();
          if (byId != null) return Map<String, dynamic>.from(byId);
        }
        return null;
      });

  @override
  Future<Result<bool>> isParticipant(String arenaId) => _guard(() async {
        final existing = await _club
            .from('arena_participants')
            .select()
            .eq('arena_id', arenaId)
            .eq('user_id', _requireUser())
            .maybeSingle();
        return existing != null;
      });

  @override
  Future<Result<void>> joinArena(String arenaId,
          {required String gameMode}) =>
      _guard(() => _club.from('arena_participants').upsert({
            'arena_id': arenaId,
            'user_id': _requireUser(),
            'lives_count': gameMode == 'survivor' ? 2 : 0,
            'current_score': 0,
            'status': 'active',
            'role': 'member',
          }, onConflict: 'arena_id, user_id'));

  @override
  Future<Result<Map<String, dynamic>>> createArena(
          Map<String, dynamic> payload,
          {required String gameMode}) =>
      _guard(() async {
        final uid = _requireUser();
        final arena = await _club
            .from('arenas')
            .insert({...payload, 'creator_id': uid})
            .select()
            .single();
        await _club.from('arena_participants').upsert({
          'arena_id': arena['id'],
          'user_id': uid,
          'lives_count': gameMode == 'survivor' ? 2 : 0,
          'status': 'active',
        }, onConflict: 'arena_id, user_id');
        return Map<String, dynamic>.from(arena);
      });

  @override
  Future<Result<Map<String, dynamic>>> createSquadWithQuota({
    required String name,
    required String description,
    required String gameMode,
    required int durationDays,
    required String validationType,
    required String shareCode,
  }) =>
      _guard(() async {
        final response = await _club.rpc('create_squad_with_quota', params: {
          'p_name': name,
          'p_description': description,
          'p_game_mode': gameMode,
          'p_duration_days': durationDays,
          'p_validation_type': validationType,
          'p_share_code': shareCode,
        });
        return Map<String, dynamic>.from(response as Map);
      });

  @override
  Future<Result<Map<String, dynamic>>> joinSquadWithQuota(
          String arenaId, String shareCode) =>
      _guard(() async {
        final response = await _club.rpc('join_squad_with_quota', params: {
          'p_arena_id': arenaId,
          'p_share_code': shareCode,
        });
        return Map<String, dynamic>.from(response as Map);
      });

  @override
  Future<Result<void>> updateArena(
          String arenaId, Map<String, dynamic> updates) =>
      _guard(() => _club.from('arenas').update(updates).eq('id', arenaId));

  @override
  Future<Result<void>> leaveArena(String arenaId) =>
      _guard(() => _club
          .from('arena_participants')
          .delete()
          .eq('arena_id', arenaId)
          .eq('user_id', _requireUser()));

  @override
  Future<Result<void>> kickMember(String arenaId, String userId) =>
      _guard(() => _club
          .from('arena_participants')
          .delete()
          .eq('arena_id', arenaId)
          .eq('user_id', userId));

  @override
  Future<Result<void>> deleteArenaTotally(String arenaId) =>
      _guard(() => _club
          .rpc('delete_arena_totally', params: {'target_arena_id': arenaId}));

  @override
  Future<Result<List<Map<String, dynamic>>>> participantsCombined(
          String arenaId, {required String orderBy}) =>
      _guard(() async {
        final parts = await _club
            .from('arena_participants')
            .select()
            .eq('arena_id', arenaId)
            .order(orderBy, ascending: false);
        final rawParts = List<Map<String, dynamic>>.from(parts);
        if (rawParts.isEmpty) return rawParts;

        final profiles =
            await _profilesFor(rawParts.map((e) => e['user_id']).toList());
        return rawParts.map((p) {
          final profile = profiles[p['user_id'].toString()];
          return {
            ...p,
            'name': profile?['full_name'] ?? 'Atleta',
            'avatar': profile?['avatar_url'],
          };
        }).toList();
      });

  @override
  Future<Result<List<Map<String, dynamic>>>> membersCombined(String arenaId) =>
      _guard(() async {
        final parts = await _club
            .from('arena_participants')
            .select()
            .eq('arena_id', arenaId);
        final rawParts = List<Map<String, dynamic>>.from(parts);
        final profiles =
            await _profilesFor(rawParts.map((e) => e['user_id']).toList());
        return rawParts.map((p) {
          final prof = profiles[p['user_id'].toString()];
          return {
            'user_id': p['user_id'],
            'status': p['status'],
            'name': prof?['full_name'] ?? 'Agente',
            'avatar': prof?['avatar_url'],
          };
        }).toList();
      });

  @override
  Future<Result<List<Map<String, dynamic>>>> mySquads() => _guard(() async {
        final response = await _club
            .from('arena_participants')
            .select('arenas(*)')
            .eq('user_id', _requireUser());
        final squads = <Map<String, dynamic>>[];
        for (final item in (response as List)) {
          if (item['arenas'] != null) {
            squads.add(Map<String, dynamic>.from(item['arenas'] as Map));
          }
        }
        squads.sort((a, b) =>
            (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
        return squads;
      });

  @override
  Future<Result<Map<String, dynamic>?>> myActiveSquadArena() =>
      _guard(() async {
        final participation = await _club
            .from('arena_participants')
            .select('arena_id')
            .eq('user_id', _requireUser())
            .eq('status', 'active')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (participation == null) return null;
        final arena = await _club
            .from('arenas')
            .select()
            .eq('id', participation['arena_id'])
            .single();
        return Map<String, dynamic>.from(arena);
      });

  // ── Tribunal / check-ins ──

  @override
  Future<Result<String>> validationType(String arenaId) => _guard(() async {
        final arena = await _club
            .from('arenas')
            .select('validation_type')
            .eq('id', arenaId)
            .single();
        return (arena['validation_type'] as String?) ?? 'photo';
      });

  @override
  Future<Result<List<Map<String, dynamic>>>> tribunalFeed(String arenaId) =>
      _guard(() async {
        final data = await _club
            .from('tribunal_posts')
            .select('*, tribunal_votes(vote_type, voter_id)')
            .eq('arena_id', arenaId)
            .order('created_at', ascending: false);
        final posts = List<Map<String, dynamic>>.from(data);
        final profiles =
            await _profilesFor(posts.map((e) => e['user_id']).toSet().toList());
        return posts
            .map((p) =>
                {...p, 'user_profiles': profiles[p['user_id'].toString()]})
            .toList();
      });

  @override
  Future<Result<List<Map<String, dynamic>>>> arenaHistory(String arenaId) =>
      _guard(() async {
        final data = await _club
            .from('tribunal_posts')
            .select('*')
            .eq('arena_id', arenaId)
            .neq('status', 'chat')
            .order('created_at', ascending: false)
            .limit(50);
        final posts = List<Map<String, dynamic>>.from(data);
        if (posts.isEmpty) return posts;
        final profiles = await _profilesFor(posts
            .map((p) => p['user_id'])
            .where((id) => id != null)
            .toSet()
            .toList());
        return posts
            .map((p) =>
                {...p, 'user_profiles': profiles[p['user_id'].toString()]})
            .toList();
      });

  @override
  Future<Result<void>> sendChatMessage(String arenaId, String text) =>
      _guard(() => _club.from('tribunal_posts').insert({
            'arena_id': arenaId,
            'user_id': _requireUser(),
            'caption': text,
            'photo_url': null, // null = mensagem de texto
            'status': 'chat', // não vai para votação
          }));

  @override
  Future<Result<void>> postPhotoProof({
    required String arenaId,
    required Uint8List bytes,
    required String fileExt,
    required String caption,
    required bool isHonorMode,
  }) =>
      _guard(() async {
        final uid = _requireUser();
        final fileName =
            '$uid/${DateTime.now().millisecondsSinceEpoch}$fileExt';
        await _client.storage.from('proofs').uploadBinary(fileName, bytes,
            fileOptions: const supabase.FileOptions(upsert: false));
        final imageUrl = _client.storage.from('proofs').getPublicUrl(fileName);

        await _club.from('tribunal_posts').insert({
          'arena_id': arenaId,
          'user_id': uid,
          'photo_url': imageUrl,
          'caption': caption.isNotEmpty ? caption : 'Missão cumprida! 💀',
          // Em arenas de honra a foto é só chat (não conta como check-in).
          'status': isHonorMode ? 'chat' : 'pending',
        });
      });

  @override
  Future<Result<void>> vote(String postId, {required bool isValid}) =>
      _guard(() => _club.from('tribunal_votes').insert({
            'post_id': postId,
            'voter_id': _requireUser(),
            'vote_type': isValid ? 'valid' : 'fake',
          }));

  @override
  Future<Result<void>> submitCheckin({
    required String arenaId,
    String? imagePath,
    required Map<String, dynamic> post,
  }) =>
      _guard(() async {
        final uid = _requireUser();
        String? imageUrl;
        if (imagePath != null) {
          final fileExt = imagePath.split('.').last;
          final fileName =
              '$uid/${DateTime.now().millisecondsSinceEpoch}.$fileExt';
          await _client.storage.from('proofs').upload(fileName, File(imagePath));
          imageUrl = _client.storage.from('proofs').getPublicUrl(fileName);
        }
        await _club.from('tribunal_posts').insert({
          ...post,
          'arena_id': arenaId,
          'user_id': uid,
          'photo_url': imageUrl,
          'status': imageUrl != null ? 'pending' : 'approved',
        });
      });

  @override
  Future<Result<List<Map<String, dynamic>>>> myTodayPosts(String arenaId) =>
      _guard(() async {
        final now = DateTime.now().toUtc();
        final startOfDay =
            DateTime(now.year, now.month, now.day).toIso8601String();
        final rows = await _club
            .from('tribunal_posts')
            .select('xp_earned, activity_type')
            .eq('arena_id', arenaId)
            .eq('user_id', _requireUser())
            .gte('created_at', startOfDay);
        return List<Map<String, dynamic>>.from(rows);
      });

  @override
  Future<Result<String?>> todayCheckinStatus(String arenaId) =>
      _guard(() async {
        final now = DateTime.now().toUtc();
        final startOfDay =
            DateTime(now.year, now.month, now.day).toIso8601String();
        final response = await _club
            .from('tribunal_posts')
            .select('status')
            .eq('arena_id', arenaId)
            .eq('user_id', _requireUser())
            .gte('created_at', startOfDay)
            .or('photo_url.neq.null,activity_title.neq.null')
            .limit(1)
            .maybeSingle();
        return response == null
            ? null
            : (response['status'] as String? ?? 'pending');
      });

  // ── Streams realtime ──

  @override
  Stream<List<Map<String, dynamic>>> myParticipationStream() {
    final uid = _currentUserId();
    if (uid == null) return Stream.value(const []);
    return _club
        .from('arena_participants')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(1);
  }

  @override
  Stream<List<Map<String, dynamic>>> recentDuelsStream({int limit = 50}) =>
      _club
          .from('user_challenges')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .limit(limit);
}
