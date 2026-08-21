import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/club/domain/entities/challenges.dart';
import 'package:bldr_fitness/features/club/domain/repositories/challenge_repository.dart';
import 'package:bldr_fitness/features/club/data/datasources/supabase_challenges_datasource.dart';

class ChallengeRepositoryImpl implements ChallengeRepository {
  final SupabaseChallengesDatasource _datasource;
  final String? Function() _currentUserId;

  ChallengeRepositoryImpl(this._datasource, this._currentUserId);

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

  @override
  Future<Result<List<XpFeedItem>>> xpFeed({int limit = 50}) =>
      _guard(() async {
        final events = await _datasource.xpEvents(limit: limit);
        if (events.isEmpty) return <XpFeedItem>[];

        final userIds = events
            .map((e) => (e['user_id'] ?? '').toString())
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();
        final profiles = await _datasource.profilesByIds(userIds);
        final profilesMap = {
          for (final p in profiles) p['id'].toString(): p,
        };

        // Reações são opcionais: falha não derruba o feed (comportamento
        // original da tela).
        var counts = <String, int>{};
        try {
          counts = await _datasource
              .reactionCounts(events.map((e) => e['id'].toString()).toList());
        } catch (_) {}

        return events.map((e) {
          final uid = (e['user_id'] ?? '').toString();
          final profile = profilesMap[uid];
          final displayName = (profile?['display_name'] as String?)?.trim() ?? '';
          final fullName = (profile?['full_name'] as String?)?.trim() ?? '';
          final resolvedName = displayName.isNotEmpty ? displayName : fullName;
          final id = e['id'].toString();
          return XpFeedItem(
            id: id,
            userId: uid,
            userName: resolvedName.isNotEmpty ? resolvedName : 'Atleta BLDR',
            avatarUrl: profile?['avatar_url'] as String?,
            reason: e['reason'] as String?,
            createdAt: DateTime.tryParse(e['created_at']?.toString() ?? ''),
            xp: (e['delta'] as num?)?.toInt() ?? 0,
            reactionCount: counts[id] ?? 0,
          );
        }).toList();
      });

  @override
  Future<Result<void>> reactToXpEvent(String eventId) =>
      _guard(() => _datasource.addReaction(_requireUser(), eventId));

  @override
  Future<Result<void>> removeReactionFromXpEvent(String eventId) =>
      _guard(() => _datasource.removeReaction(_requireUser(), eventId));

  @override
  Future<Result<Set<String>>> myReactions(List<String> eventIds) =>
      _guard(() => _datasource.myReactions(_requireUser(), eventIds));

  @override
  Future<Result<List<ClubRankingEntry>>> ranking({int limit = 100}) =>
      _guard(() async {
        final rows = await _datasource.ranking(limit: limit);
        return rows
            .map((row) => ClubRankingEntry(
                  userId: row['user_id'].toString(),
                  displayName:
                      (row['display_name'] as String?) ?? 'Atleta',
                  avatarUrl: row['avatar_url'] as String?,
                  xpTotal: (row['xp_total'] as num?)?.toInt() ?? 0,
                  currentLevel: (row['current_level'] as num?)?.toInt() ?? 1,
                ))
            .toList();
      });

  @override
  Future<Result<List<Duel>>> myDuels({int limit = 20}) => _guard(() async {
        final myId = _requireUser();
        final rows = await _datasource.myDuels(myId, limit: limit);

        final duels = <Duel>[];
        for (final row in rows) {
          final isSender = row['sender_id'] == myId;
          final opponentId =
              (isSender ? row['receiver_id'] : row['sender_id']).toString();
          final opponentProfile = await _datasource.profileById(opponentId);

          final status = row['status'] as String? ?? 'pending';

          // Progresso só é buscado em duelos aceitos (como no original).
          var myProgress = 0;
          var oppProgress = 0;
          if (status == 'accepted') {
            try {
              myProgress = await _datasource.rankingXp(myId);
              oppProgress = await _datasource.rankingXp(opponentId);
            } catch (_) {}
          }

          duels.add(Duel(
            id: row['id'].toString(),
            opponentName:
                (opponentProfile?['full_name'] as String?) ?? 'Atleta',
            opponentAvatar: opponentProfile?['avatar_url'] as String?,
            targetXp: (row['target_xp'] as num?)?.toInt() ?? 500,
            status: status,
            isSender: isSender,
            myProgress: myProgress,
            opponentProgress: oppProgress,
            winnerId: row['winner_id']?.toString(),
            createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
            expiresAt: DateTime.tryParse(row['expires_at']?.toString() ?? ''),
          ));
        }
        return duels;
      });

  @override
  Future<Result<void>> respondDuel(String duelId, {required bool accept}) =>
      _guard(() => _datasource.respondDuel(duelId, accept));

  @override
  Future<Result<List<CollectiveChallenge>>> collectiveChallenges(
          {int limit = 10}) =>
      _guard(() async {
        final rows = await _datasource.collectiveChallenges(limit: limit);
        if (rows.isEmpty) return <CollectiveChallenge>[];

        final ids = rows.map((c) => c['id'].toString()).toList();
        final counts = await _datasource.participantCounts(ids);

        var joined = <String>{};
        final uid = _currentUserId();
        if (uid != null) {
          joined = await _datasource.joinedChallengeIds(uid, ids);
        }

        final now = DateTime.now();
        return rows.map((c) {
          final id = c['id'].toString();
          return CollectiveChallenge(
            id: id,
            title: (c['title'] as String?) ?? '',
            description: c['description'] as String?,
            challengeType: c['challenge_type'] as String?,
            targetValue: c['target_value'] as num?,
            currentValue: c['current_value'] as num?,
            rewardXp: (c['reward_xp'] as num?)?.toInt(),
            rewardBadge: c['reward_badge'] as String?,
            coverImageUrl: c['cover_image_url'] as String?,
            endsAt: DateTime.tryParse(c['ends_at']?.toString() ?? ''),
            status: (c['status'] as String?) ?? 'active',
            createdBy: c['created_by']?.toString(),
            isOfficial: c['is_official'] as bool? ?? false,
            participantCount: counts[id] ?? 0,
            joined: joined.contains(id),
          );
        }).where((c) => c.endsAt == null || c.endsAt!.isAfter(now)).toList();
      });

  @override
  Future<Result<void>> joinChallenge(String challengeId) =>
      _guard(() => _datasource.joinChallenge(_requireUser(), challengeId));

  @override
  Future<Result<void>> leaveChallenge(String challengeId) =>
      _guard(() => _datasource.leaveChallenge(_requireUser(), challengeId));

  @override
  Future<Result<List<ClubNotification>>> notifications({int limit = 50}) =>
      _guard(() async {
        final rows =
            await _datasource.notifications(_requireUser(), limit: limit);
        return rows
            .map((n) => ClubNotification(
                  id: n['id'].toString(),
                  title: (n['title'] as String?) ?? '',
                  message: (n['message'] as String?) ?? '',
                  type: (n['type'] as String?) ?? 'info',
                  isRead: n['is_read'] as bool? ?? false,
                  createdAt:
                      DateTime.tryParse(n['created_at']?.toString() ?? ''),
                  actionType: n['action_type'] as String?,
                  actionData: n['action_data'] is Map
                      ? Map<String, dynamic>.from(n['action_data'] as Map)
                      : null,
                ))
            .toList();
      });

  @override
  Future<Result<void>> markAllNotificationsRead() =>
      _guard(() => _datasource.markAllNotificationsRead(_requireUser()));

  @override
  Future<Result<void>> markNotificationRead(String id) =>
      _guard(() => _datasource.markNotificationRead(id));

  @override
  Future<Result<PublicClubProfile>> publicProfile(String userId) =>
      _guard(() async {
        final raw = await _datasource.publicProfileRaw(userId);
        final profile = Map<String, dynamic>.from(raw['profile'] as Map);
        final rank = raw['rank'] == null
            ? null
            : Map<String, dynamic>.from(raw['rank'] as Map);
        final allRanking = raw['all_ranking'] as List;
        final workouts = raw['workouts'] as List;
        final duels = raw['duels'] as List;
        final events = raw['events'] as List;

        var pos = 0;
        for (var i = 0; i < allRanking.length; i++) {
          if (allRanking[i]['user_id'] == userId) {
            pos = i + 1;
            break;
          }
        }

        var wins = 0, losses = 0;
        for (final d in duels) {
          if (d['winner_id'] == userId) {
            wins++;
          } else {
            losses++;
          }
        }

        return PublicClubProfile(
          userId: userId,
          fullName: (profile['full_name'] as String?) ?? '',
          avatarUrl: profile['avatar_url'] as String?,
          email: profile['email'] as String?,
          xpTotal: (rank?['xp_total'] as num?)?.toInt() ?? 0,
          currentLevel: (rank?['current_level'] as num?)?.toInt() ?? 1,
          rankPosition: pos,
          totalWorkouts: workouts.length,
          duelWins: wins,
          duelLosses: losses,
          recentActivity: events
              .map((e) => XpFeedItem(
                    id: e['id'].toString(),
                    userId: userId,
                    userName: '',
                    reason: e['reason'] as String?,
                    createdAt:
                        DateTime.tryParse(e['created_at']?.toString() ?? ''),
                    xp: (e['delta'] as num?)?.toInt() ?? 0,
                  ))
              .toList(),
        );
      });

  @override
  Future<Result<ClubRankingEntry?>> myRankingEntry() => _guard(() async {
        final myId = _requireUser();
        final row = await _datasource.myRankingRowOrNull(myId);
        if (row == null) return null;
        return ClubRankingEntry(
          userId: myId,
          displayName: 'Eu',
          xpTotal: (row['xp_total'] as num?)?.toInt() ?? 0,
          currentLevel: (row['current_level'] as num?)?.toInt() ?? 1,
        );
      });

  @override
  Future<Result<DuelInvite?>> pendingDuelInvite() => _guard(() async {
        final row = await _datasource.pendingDuelInvite(_requireUser());
        if (row == null) return null;
        final sender =
            await _datasource.profileById(row['sender_id'].toString());
        return DuelInvite(
          id: row['id'].toString(),
          senderName: (sender?['full_name'] as String?) ?? 'Rival',
          senderAvatar: sender?['avatar_url'] as String?,
        );
      });

  @override
  Future<Result<ActiveDuelStatus?>> checkActiveDuel() => _guard(() async {
        final myId = _requireUser();
        final duel = await _datasource.acceptedDuel(myId);
        if (duel == null) return null;

        final isMeSender = duel['sender_id'] == myId;
        final opponentId =
            (isMeSender ? duel['receiver_id'] : duel['sender_id']).toString();
        final target = (duel['target_xp'] as num?)?.toInt() ?? 500;
        final duelId = duel['id'].toString();

        final myData = await _datasource.rankingRow(myId);
        final oppData = await _datasource.rankingRow(opponentId);
        final myXp = (myData['xp_total'] as num?)?.toInt() ?? 0;
        final oppXp = (oppData['xp_total'] as num?)?.toInt() ?? 0;

        // ── Fim de jogo: fecha o duelo e notifica os dois lados ──
        if (myXp >= target || oppXp >= target) {
          final iWon = myXp >= target;
          final winnerId = iWon ? myId : opponentId;
          final loserId = iWon ? opponentId : myId;

          await _datasource.finishDuel(duelId, winnerId);
          await _datasource.insertNotification(
            userId: winnerId,
            title: 'VITÓRIA! 🏆',
            message: 'Você atingiu a meta de $target XP e venceu o duelo!',
            type: 'success',
          );
          await _datasource.insertNotification(
            userId: loserId,
            title: 'Duelo Finalizado 💀',
            message: 'O rival atingiu a meta de $target XP antes de você.',
            type: 'info',
          );

          return ActiveDuelStatus(
              finished: true, wonByMe: iWon, targetXp: target);
        }

        return ActiveDuelStatus(
          targetXp: target,
          opponentName:
              (oppData['display_name'] as String?) ?? 'Rival',
          opponentAvatar: oppData['avatar_url'] as String?,
          opponentXp: oppXp,
          myXp: myXp,
        );
      });

  @override
  Future<Result<void>> sendDuelInvite({
    required String opponentId,
    required int targetXp,
    required DateTime expiresAt,
  }) =>
      _guard(() => _datasource.insertDuel(
            senderId: _requireUser(),
            receiverId: opponentId,
            targetXp: targetXp,
            expiresAtIso: expiresAt.toUtc().toIso8601String(),
          ));

  @override
  Future<Result<CollectiveChallenge?>> challengeDetail(String challengeId) =>
      _guard(() async {
        final c = await _datasource.challengeById(challengeId);
        if (c == null) return null;

        var count = 0;
        try {
          count = (await _datasource.participantUserIds(challengeId)).length;
        } catch (_) {}

        return CollectiveChallenge(
          id: c['id'].toString(),
          title: (c['title'] as String?) ?? '',
          description: c['description'] as String?,
          challengeType: c['challenge_type'] as String?,
          targetValue: c['target_value'] as num?,
          currentValue: c['current_value'] as num?,
          rewardXp: (c['reward_xp'] as num?)?.toInt(),
          rewardBadge: c['reward_badge'] as String?,
          coverImageUrl: c['cover_image_url'] as String?,
          endsAt: DateTime.tryParse(c['ends_at']?.toString() ?? ''),
          status: (c['status'] as String?) ?? 'active',
          createdBy: c['created_by']?.toString(),
          isOfficial: c['is_official'] as bool? ?? false,
          participantCount: count,
          createdAt: DateTime.tryParse(c['created_at']?.toString() ?? ''),
          allowedSources:
              (c['allowed_sources'] as List?)?.map((e) => e.toString()).toList(),
        );
      });

  @override
  Future<Result<ChallengeParticipation>> myParticipation(String challengeId) =>
      _guard(() async {
        final row = await _datasource.myParticipation(
            challengeId, _requireUser());
        return ChallengeParticipation(
          joined: row != null,
          contribution: (row?['contribution'] as num?)?.toInt() ?? 0,
        );
      });

  @override
  Future<Result<List<ChallengeContributor>>> topContributors(
          String challengeId, {int limit = 10}) =>
      _guard(() async {
        final participants =
            await _datasource.topContributors(challengeId, limit: limit);
        if (participants.isEmpty) return <ChallengeContributor>[];

        final userIds =
            participants.map((p) => p['user_id'].toString()).toList();
        final profiles = await _datasource.profilesByIds(userIds);
        final profileMap = {
          for (final p in profiles) p['id'].toString(): p,
        };

        return participants.map((p) {
          final uid = p['user_id'].toString();
          final profile = profileMap[uid];
          final rawName = (profile?['full_name'] as String?) ?? '';
          return ChallengeContributor(
            userId: uid,
            name: rawName.isNotEmpty ? rawName : 'Atleta BLDR',
            avatarUrl: profile?['avatar_url'] as String?,
            contribution: (p['contribution'] as num?)?.toInt() ?? 0,
          );
        }).toList();
      });

  @override
  Future<Result<List<ChallengeFeedItem>>> challengeFeed(String challengeId,
          {DateTime? since}) =>
      _guard(() async {
        final userIds = await _datasource.participantUserIds(challengeId);
        if (userIds.isEmpty) return <ChallengeFeedItem>[];

        final sinceIso = since?.toIso8601String();
        final events = await _datasource.xpEventsForUsers(userIds,
            sinceIso: sinceIso, limit: 30);
        final profiles = await _datasource.profilesByIds(userIds);
        final profileMap = {
          for (final p in profiles) p['id'].toString(): p,
        };

        // Treinos concluídos para correlação por timestamp (opcional).
        var workouts = <Map<String, dynamic>>[];
        try {
          workouts = await _datasource.completedClubWorkoutsForUsers(userIds,
              sinceIso: sinceIso, limit: 100);
        } catch (_) {}
        final workoutsByUser = <String, List<Map<String, dynamic>>>{};
        for (final w in workouts) {
          workoutsByUser
              .putIfAbsent((w['user_id'] ?? '').toString(), () => [])
              .add(w);
        }

        return events.map((e) {
          final uid = (e['user_id'] ?? '').toString();
          final profile = profileMap[uid];
          final rawName = (profile?['full_name'] as String?) ?? '';

          // Correlaciona o evento com um treino (janela de ±30 s).
          String? activityLabel;
          final eventTime =
              DateTime.tryParse((e['created_at'] ?? '').toString());
          if (eventTime != null) {
            for (final w in workoutsByUser[uid] ?? []) {
              final completedAt =
                  DateTime.tryParse((w['completed_at'] as String?) ?? '');
              if (completedAt == null) continue;
              if (eventTime.difference(completedAt).abs().inSeconds <= 30) {
                final wName = (w['name'] as String? ?? '').trim();
                final durMin =
                    (((w['total_duration_seconds'] as num?)?.toInt() ?? 0) /
                            60)
                        .round();
                if (wName.isNotEmpty && durMin > 0) {
                  activityLabel = '$wName · $durMin min';
                }
                break;
              }
            }
          }

          return ChallengeFeedItem(
            userId: uid,
            userName: rawName.isNotEmpty ? rawName : 'Atleta BLDR',
            reason: e['reason'] as String?,
            delta: (e['delta'] as num?)?.toInt() ?? 0,
            createdAt: eventTime,
            activityLabel: activityLabel,
          );
        }).toList();
      });

  @override
  Future<Result<List<ChallengeMilestone>>> milestones(String challengeId) =>
      _guard(() async {
        final rows = await _datasource.milestones(challengeId);
        return rows
            .map((m) => ChallengeMilestone(
                  milestonePct: m['milestone_pct'] as num? ?? 0,
                  reachedAt:
                      DateTime.tryParse(m['reached_at']?.toString() ?? ''),
                ))
            .toList();
      });

  @override
  Future<Result<List<ChallengeComment>>> comments(String challengeId,
          {int limit = 30}) =>
      _guard(() async {
        final rows = await _datasource.comments(challengeId, limit: limit);
        if (rows.isEmpty) return <ChallengeComment>[];

        final userIds =
            rows.map((c) => c['user_id'].toString()).toSet().toList();
        final profiles = await _datasource.profilesByIds(userIds);
        final profileMap = {
          for (final p in profiles) p['id'].toString(): p,
        };

        return rows.map((c) {
          final uid = c['user_id'].toString();
          final profile = profileMap[uid];
          final rawName = (profile?['full_name'] as String?) ?? '';
          return ChallengeComment(
            id: c['id'].toString(),
            userId: uid,
            userName: rawName.isNotEmpty ? rawName : 'Atleta BLDR',
            avatarUrl: profile?['avatar_url'] as String?,
            content: (c['content'] as String?) ?? '',
            createdAt: DateTime.tryParse(c['created_at']?.toString() ?? ''),
          );
        }).toList();
      });

  @override
  Future<Result<void>> addComment(String challengeId, String content) =>
      _guard(() =>
          _datasource.insertComment(challengeId, _requireUser(), content));

  @override
  Future<Result<void>> reportChallenge(String challengeId, String reason) =>
      _guard(() =>
          _datasource.insertReport(challengeId, _requireUser(), reason));

  @override
  Future<Result<void>> updateChallengeSettings(
    String challengeId, {
    required List<String>? allowedSources,
    num? targetValue,
  }) =>
      _guard(() => _datasource.updateChallenge(challengeId, {
            'allowed_sources':
                (allowedSources?.isEmpty ?? true) ? null : allowedSources,
            if (targetValue != null) 'target_value': targetValue,
          }));

  @override
  Future<Result<void>> createCollectiveChallenge(
          NewCollectiveChallenge data) =>
      _guard(() async {
        final uid = _requireUser();

        String? coverUrl;
        if (data.coverImagePath != null) {
          coverUrl = await _datasource.uploadChallengeCover(
              uid, data.coverImagePath!);
        }

        await _datasource.insertCollectiveChallenge({
          'title': data.title,
          'description': data.description,
          'challenge_type': data.challengeType,
          'target_value': data.targetValue,
          'reward_xp': data.rewardXp,
          'reward_badge':
              (data.rewardBadge?.isNotEmpty ?? false) ? data.rewardBadge : null,
          'cover_image_url': coverUrl,
          'ends_at': data.endsAt.toIso8601String(),
          'created_by': uid,
          'allowed_sources': (data.allowedSources?.isEmpty ?? true)
              ? null
              : data.allowedSources,
        });
      });

  @override
  Future<Result<List<PastChallengeEntry>>> pastChallenges(
          {int limit = 20}) =>
      _guard(() async {
        final uid = _requireUser();
        final rows = await _datasource.pastChallenges(uid, limit: limit);
        return rows.map((r) {
          final challenge = CollectiveChallenge(
            id: r['id'].toString(),
            title: (r['title'] as String?) ?? '',
            description: r['description'] as String?,
            challengeType: r['challenge_type'] as String?,
            rewardXp: (r['reward_xp'] as num?)?.toInt(),
            coverImageUrl: r['cover_image_url'] as String?,
            endsAt: DateTime.tryParse(r['ends_at']?.toString() ?? ''),
            status: (r['status'] as String?) ?? 'completed',
          );
          return PastChallengeEntry(
            challenge: challenge,
            myContribution: (r['my_contribution'] as num?)?.toInt() ?? 0,
          );
        }).toList();
      });
}
