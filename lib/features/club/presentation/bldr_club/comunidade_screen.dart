// lib/presentation/bldr_club/comunidade_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/domain/entities/challenges.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/havok/havok_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/ranking_screen.dart' show RankingEntry;
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

class ComunidadeScreen extends StatefulWidget {
  const ComunidadeScreen({super.key});

  @override
  State<ComunidadeScreen> createState() => _ComunidadeScreenState();
}

class _ComunidadeScreenState extends State<ComunidadeScreen>
    with SingleTickerProviderStateMixin {
  static const gold = Color(0xFFD4AF37);

  late final TabController _tabController;

  // Feed data
  List<Map<String, dynamic>> _feedData = [];
  bool _feedLoading = true;

  // Ranking data (for compact podium)
  List<RankingEntry> _rankingData = [];
  bool _rankingLoading = true;
  String? _myUserId;
  int _myRankPosition = 0;
  int _myXp = 0;

  // Reactions state (eventId -> count)
  final Map<String, int> _reactionCounts = {};
  final Map<String, bool> _reacted = {};

  // Collective challenges
  List<Map<String, dynamic>> _collectiveChallenges = [];
  bool _collectiveLoading = true;
  Set<String> _joinedChallengeIds = {};

  // Past challenges (histórico)
  List<Map<String, dynamic>> _pastChallenges = [];
  bool _pastLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _myUserId = getIt<GetCurrentUser>()()?.id;
    _fetchCommunityFeed();
    _fetchRanking();
    _fetchCollectiveChallenges();
    _fetchPastChallenges();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Feed ──────────────────────────────────────────────────────────────────
  Future<void> _fetchCommunityFeed() async {
    setState(() => _feedLoading = true);
    try {
      final result = await getIt<GetXpFeed>()(limit: 50);
      final items = result.valueOrNull;
      if (items == null) throw Exception(result.failureOrNull?.message);

      if (items.isEmpty) {
        if (mounted) setState(() => _feedLoading = false);
        return;
      }

      final counts = {
        for (final item in items)
          if (item.reactionCount > 0) item.id: item.reactionCount,
      };

      // F7: carrega estado persistido de reações do usuário atual
      final eventIds = items.map((e) => e.id).toList();
      final myReactionsResult = await getIt<GetMyReactions>()(eventIds);
      final myReacted = myReactionsResult.valueOrNull ?? <String>{};

      if (mounted) {
        setState(() {
          _reactionCounts.addAll(counts);
          // Sobrescreve estado local volátil com o persistido
          for (final id in myReacted) {
            _reacted[id] = true;
          }
        });
      }

      final processed = items.map((item) {
        final name = item.userName;
        String initials = 'BL';
        if (name != 'Atleta BLDR') {
          final parts = name.trim().split(' ');
          initials = parts.length >= 2
              ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
              : parts[0][0].toUpperCase();
        }
        return {
          'id': item.id,
          'user': name,
          'avatar_text': initials,
          'avatar_url': item.avatarUrl,
          'reason_raw': item.reason,
          'time_raw': item.createdAt?.toIso8601String(),
          'xp': item.xp,
        };
      }).toList();

      if (mounted) setState(() {
        _feedData = _diversifyFeed(processed.cast<Map<String, dynamic>>());
        _feedLoading = false;
      });
    } catch (e) {
      debugPrint('[COMUNIDADE] Erro feed: $e');
      if (mounted) setState(() => _feedLoading = false);
    }
  }

  /// §12.2 — Keeps feed in strict chronological order (most recent first) while
  /// doing minimal local swaps so no two consecutive items share the same user
  /// AND activity type. Items are never moved more than [_kSwapWindow] positions
  /// from their original chronological slot, preserving the time-order feel.
  static const int _kSwapWindow = 4;

  List<Map<String, dynamic>> _diversifyFeed(List<Map<String, dynamic>> items) {
    if (items.length <= 2) return items;

    // 1. Sort strictly by time descending (most recent first)
    final sorted = List<Map<String, dynamic>>.from(items)
      ..sort((a, b) {
        final tA = a['time_raw'] as String? ?? '';
        final tB = b['time_raw'] as String? ?? '';
        return tB.compareTo(tA); // descending
      });

    // 2. Light local-swap pass: look ahead up to _kSwapWindow positions to
    //    break same-user+same-type runs without moving items far from their
    //    original chronological position.
    for (int i = 1; i < sorted.length; i++) {
      final prev = sorted[i - 1];
      final cur  = sorted[i];
      final sameUser = cur['user'] == prev['user'];
      final sameType = _activityType(cur['reason_raw']) == _activityType(prev['reason_raw']);

      if (sameUser && sameType) {
        // Try to find a swap candidate within the lookahead window
        final limit = (i + _kSwapWindow).clamp(i + 1, sorted.length);
        for (int j = i + 1; j < limit; j++) {
          final candidate = sorted[j];
          final cSameUser = candidate['user'] == prev['user'];
          final cSameType = _activityType(candidate['reason_raw']) == _activityType(prev['reason_raw']);
          if (!cSameUser || !cSameType) {
            // Swap candidate into position i
            sorted[j] = sorted[i];
            sorted[i] = candidate;
            break;
          }
        }
        // If no suitable candidate found, leave as-is (chronological order wins)
      }
    }

    return sorted;
  }

  // ── Ranking ───────────────────────────────────────────────────────────────
  Future<void> _fetchRanking() async {
    setState(() => _rankingLoading = true);
    try {
      final result = await getIt<GetClubRanking>()(limit: 100);
      final entries = result.valueOrNull;
      if (entries == null) throw Exception(result.failureOrNull?.message);

      final List<RankingEntry> loaded = [];
      int pos = 1;
      for (final row in entries) {
        loaded.add(RankingEntry(
          userId: row.userId,
          displayName: row.displayName,
          avatarUrl: row.avatarUrl,
          xp: row.xpTotal,
          level: row.currentLevel,
          position: pos++,
        ));
      }

      int myPos = 0;
      int myXp = 0;
      if (_myUserId != null) {
        final myEntry = loaded.where((e) => e.userId == _myUserId).firstOrNull;
        if (myEntry != null) {
          myPos = myEntry.position;
          myXp = myEntry.xp;
        }
      }

      if (mounted) {
        setState(() {
          _rankingData = loaded;
          _myRankPosition = myPos;
          _myXp = myXp;
          _rankingLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[COMUNIDADE] Erro ranking: $e');
      if (mounted) setState(() => _rankingLoading = false);
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────
  // F7: toggle de reação com estado otimista + reversão em caso de erro.
  Future<void> _sendMotivation(String eventId, String userName) async {
    if (_myUserId == null) return;

    final alreadyReacted = _reacted[eventId] == true;

    // Estado otimista
    setState(() {
      _reacted[eventId] = !alreadyReacted;
      _reactionCounts[eventId] =
          (_reactionCounts[eventId] ?? 0) + (alreadyReacted ? -1 : 1);
    });

    if (!alreadyReacted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).club_morale_sent(userName)),
        backgroundColor: gold,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    }

    // Persiste — reverte estado otimista se falhar
    final result = alreadyReacted
        ? await getIt<RemoveReactionFromXpEvent>()(eventId)
        : await getIt<ReactToXpEvent>()(eventId);

    if (result.failureOrNull != null && mounted) {
      setState(() {
        _reacted[eventId] = alreadyReacted;
        _reactionCounts[eventId] =
            (_reactionCounts[eventId] ?? 0) + (alreadyReacted ? 1 : -1);
      });
    }
  }

  // ── Collective Challenges ─────────────────────────────────────────────────
  Future<void> _fetchCollectiveChallenges() async {
    setState(() => _collectiveLoading = true);
    try {
      final result = await getIt<GetCollectiveChallenges>()(limit: 10);
      final challenges = result.valueOrNull;
      if (challenges == null) throw Exception(result.failureOrNull?.message);

      if (mounted) {
        _joinedChallengeIds =
            challenges.where((c) => c.joined).map((c) => c.id).toSet();
      }

      final processed = challenges
          .map((c) => {
                'id': c.id,
                'title': c.title,
                'description': c.description,
                'challenge_type': c.challengeType,
                'target_value': c.targetValue,
                'current_value': c.currentValue,
                'reward_xp': c.rewardXp,
                'reward_badge': c.rewardBadge,
                'cover_image_url': c.coverImageUrl,
                'ends_at': c.endsAt?.toIso8601String(),
                'status': c.status,
                'created_by': c.createdBy,
                'is_official': c.isOfficial,
                'participant_count': c.participantCount,
              })
          .toList();

      if (mounted) {
        setState(() {
          _collectiveChallenges = processed;
          _collectiveLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[COLETIVO] Erro: $e');
      if (mounted) setState(() => _collectiveLoading = false);
    }
  }

  Future<void> _joinCollectiveChallenge(String challengeId) async {
    if (_myUserId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await getIt<JoinCollectiveChallenge>()(challengeId);
      final failure = result.failureOrNull;
      if (failure != null) throw Exception(failure.message);

      setState(() => _joinedChallengeIds.add(challengeId));

      messenger.showSnackBar(const SnackBar(
        content: Text('✅ Você entrou no desafio coletivo!'),
        backgroundColor: Color(0xFFD4AF37),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Erro ao entrar no desafio: $e'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _leaveCollectiveChallenge(String challengeId) async {
    if (_myUserId == null) return;

    // Confirmação antes de sair
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sair do desafio?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Seu progresso individual será perdido e você não receberá a recompensa caso o grupo conclua.',
          style: TextStyle(color: Colors.white60, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await getIt<LeaveCollectiveChallenge>()(challengeId);
      final failure = result.failureOrNull;
      if (failure != null) throw Exception(failure.message);

      setState(() => _joinedChallengeIds.remove(challengeId));

      messenger.showSnackBar(const SnackBar(
        content: Text('Você saiu do desafio.'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Erro ao sair do desafio: $e'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _fetchPastChallenges() async {
    if (_myUserId == null) {
      if (mounted) setState(() => _pastLoading = false);
      return;
    }
    setState(() => _pastLoading = true);
    try {
      final result = await getIt<GetPastChallenges>()(limit: 20);
      final entries = result.valueOrNull;
      if (entries == null) throw Exception(result.failureOrNull?.message);

      final processed = entries
          .map((e) => {
                'id': e.challenge.id,
                'title': e.challenge.title,
                'ends_at': e.challenge.endsAt?.toIso8601String(),
                'status': e.challenge.status,
                'reward_xp': e.challenge.rewardXp,
                'my_contribution': e.myContribution,
                'cover_image_url': e.challenge.coverImageUrl,
              })
          .toList();

      if (mounted) {
        setState(() {
          _pastChallenges = processed;
          _pastLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[HISTORICO] Erro: $e');
      if (mounted) setState(() => _pastLoading = false);
    }
  }

  void _showCreateChallengeModal() {
    if (_myUserId == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CreateChallengeModal(
        myUserId: _myUserId!,
        onCreated: _fetchCollectiveChallenges,
      ),
    );
  }

  void _openPublicProfile(RankingEntry entry) {
    if (entry.userId == (_myUserId ?? '')) return;
    Navigator.pushNamed(context, '/bldr-club/perfil-publico', arguments: {
      'userId': entry.userId,
      'displayName': entry.displayName,
    });
  }

  Future<void> _openWhatsApp() async {
    const url = 'https://chat.whatsapp.com/Et29Dgr9uWa1Bc3wAu77ED';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _formatAction(String? raw, int xp) {
    final r = (raw ?? '').toLowerCase();
    // F6: mapeamento de reason para descrição real da atividade
    if (r == 'workout_completed' || r == 'treino_completo') return 'concluiu um treino de musculação';
    if (r == 'club_workout_completed') return 'concluiu um treino no BLDR Club';
    if (r == 'free_workout_completed') return 'concluiu um treino livre';
    if (r == 'hiit_workout_completed') return 'concluiu um treino HIIT';
    if (r == 'extra_activity') return 'registrou uma atividade extra';
    if (r == 'nutrition_logged' || r == 'meal_logged') return 'registrou uma refeição';
    if (r == 'calorie_goal_reached') return 'atingiu a meta calórica do dia';
    if (r == 'macro_goal_reached') return 'atingiu as metas de macros';
    if (r == 'streak_milestone') return 'manteve o streak ativo';
    if (r == 'progress_photo') return 'adicionou foto de progresso';
    if (r == 'achievement_unlocked') return 'desbloqueou uma conquista';
    if (r == 'duel_won') return 'venceu um duelo de XP';
    if (r.contains('treino') || r.contains('workout')) return 'concluiu um treino';
    if (r.contains('run') || r.contains('corrida')) return 'completou uma corrida';
    if (r.contains('hidrata') || r.contains('hydration')) return 'registrou hidratação';
    if (r.contains('pr') || r.contains('record')) return 'bateu um recorde pessoal';
    if (r.contains('week')) return 'fechou a semana com tudo';
    if (r.isEmpty) return 'ganhou +$xp XP';
    return raw ?? '';
  }

  _ActivityType _activityType(String? raw) {
    final r = (raw ?? '').toLowerCase();
    if (r.contains('pr') || r.contains('record')) return _ActivityType.pr;
    if (r.contains('streak') || r.contains('dias')) return _ActivityType.streak;
    if (r.contains('foto') || r.contains('progress')) return _ActivityType.photo;
    return _ActivityType.workout;
  }

  String _timeAgo(String dateString) {
    final date = DateTime.parse(dateString).toLocal();
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    return '${diff.inDays}d atrás';
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BldrColors.bgBase,
      body: BldrBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildComunidadeTab(),
                    _buildDesafiosTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Image.asset(
              'assets/images/BLDR CLUB_COMUNIDADE.png',
              height: 120,
              fit: BoxFit.contain,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/bldr-club/notificacoes'),
            child: Stack(
              children: [
                const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: gold, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          HavokEntryIcon(
            onTap: () => showHavokSheet(context, originScreen: 'club_comunidade'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gold.withOpacity(0.2)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: gold.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: gold.withOpacity(0.5)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: gold,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
        tabs: [
          Tab(text: AppLocalizations.of(context).club_community_tab),
          Tab(text: AppLocalizations.of(context).club_challenges_tab),
        ],
      ),
    );
  }

  // ── Comunidade Tab ────────────────────────────────────────────────────────
  Widget _buildComunidadeTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([_fetchCommunityFeed(), _fetchRanking()]);
      },
      color: gold,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Ranking Compacto
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _buildCompactRanking(),
            ),
          ),

          // Banner VIP
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _WhatsAppBanner(onTap: _openWhatsApp),
            ),
          ),

          // Título feed
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                children: [
                  const Icon(Icons.flash_on, color: gold, size: 18),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context).club_recent_activity,
                      style: BldrText.label.copyWith(color: gold)),
                ],
              ),
            ),
          ),

          // Feed
          if (_feedLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator(color: gold)),
              ),
            )
          else if (_feedData.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                    child: Text(AppLocalizations.of(context).club_no_recent_activity,
                        style: TextStyle(color: Colors.white54))),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final item = _feedData[i];
                  final eid = item['id'].toString();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: _ActivityCard(
                      name: item['user'],
                      avatarText: item['avatar_text'],
                      action: _formatAction(item['reason_raw'], item['xp']),
                      time: _timeAgo(item['time_raw']),
                      xp: item['xp'],
                      activityType: _activityType(item['reason_raw']),
                      reactionCount: _reactionCounts[eid] ?? 0,
                      hasReacted: _reacted[eid] ?? false,
                      onReact: () => _sendMotivation(eid, item['user']),
                    ),
                  );
                },
                childCount: _feedData.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildCompactRanking() {
    if (_rankingLoading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator(color: gold, strokeWidth: 2)),
      );
    }

    final top3 = _rankingData.take(3).toList();
    if (top3.isEmpty) return const SizedBox.shrink();

    final myEntry = _myUserId != null
        ? _rankingData.where((e) => e.userId == _myUserId).firstOrNull
        : null;
    final nextEntry = myEntry != null && myEntry.position > 1
        ? _rankingData.firstWhere((e) => e.position == myEntry.position - 1,
            orElse: () => myEntry)
        : null;

    return BldrGlassCard(
      borderColor: BldrColors.goldBorder,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: gold, size: 16),
              const SizedBox(width: 6),
              Text(AppLocalizations.of(context).club_ranking_week, style: BldrText.label.copyWith(color: gold)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/bldr-club/ranking'),
                child: Text(AppLocalizations.of(context).club_see_all,
                    style: BldrText.metaSm.copyWith(color: gold.withOpacity(0.7))),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pódio compacto — coroas em vez de troféu (CC2)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (top3.length > 1)
                _CompactPodiumItem(
                    entry: top3[1],
                    color: const Color(0xB3C8C8C8), // prata fosca
                    size: 36,
                    onTap: _openPublicProfile),
              const SizedBox(width: 8),
              _CompactPodiumItem(
                  entry: top3[0],
                  color: const Color(0xFFE0B830), // ouro sólido
                  size: 44,
                  isFirst: true,
                  onTap: _openPublicProfile),
              const SizedBox(width: 8),
              if (top3.length > 2)
                _CompactPodiumItem(
                    entry: top3[2],
                    color: const Color(0x8CC9A227), // dourado fosco
                    size: 36,
                    onTap: _openPublicProfile),
            ],
          ),

          // Card posição do usuário (CC3) — XP e diferença dinâmicos
          if (myEntry != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: BldrColors.goldTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BldrColors.goldBorder),
              ),
              child: Row(
                children: [
                  Text('#${myEntry.position}',
                      style: BldrText.cardTitle.copyWith(color: gold, fontSize: 16)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      myEntry.displayName.split(' ')[0],
                      style: BldrText.body.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('${myEntry.xp} xp', style: BldrText.meta.copyWith(color: gold)),
                  if (nextEntry != null && nextEntry.userId != myEntry.userId) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: gold,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '+${nextEntry.xp - myEntry.xp} XP para o #${nextEntry.position}',
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Desafios Tab ──────────────────────────────────────────────────────────
  Widget _buildDesafiosTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          _fetchCollectiveChallenges(),
          _fetchPastChallenges(),
        ]);
      },
      color: gold,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Desafios Coletivos
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.groups, color: gold, size: 16),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context).club_collective_challenges,
                      style: const TextStyle(
                          color: gold,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: 12)),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showCreateChallengeModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: gold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: gold.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, color: gold, size: 13),
                          const SizedBox(width: 4),
                          Text(AppLocalizations.of(context).club_create,
                              style: const TextStyle(
                                  color: gold, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(child: _buildCollectiveChallengesSection()),

          // Histórico
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.history, color: gold, size: 16),
                  const SizedBox(width: 8),
                  const Text('HISTÓRICO',
                      style: TextStyle(
                          color: gold,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: 12)),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(child: _buildPastChallengesSection()),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildCollectiveChallengesSection() {
    if (_collectiveLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(color: gold, strokeWidth: 2)),
      );
    }

    if (_collectiveChallenges.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F0F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: gold.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Icon(Icons.emoji_events_outlined, color: gold.withOpacity(0.4), size: 36),
              const SizedBox(height: 12),
              Text(AppLocalizations.of(context).club_no_collective_challenge,
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(AppLocalizations.of(context).club_create_first_challenge,
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _collectiveChallenges
            .map((c) => _CollectiveChallengeCard(
                  challenge: c,
                  isJoined: _joinedChallengeIds.contains(c['id'].toString()),
                  onJoin: () => _joinCollectiveChallenge(c['id'].toString()),
                  onLeave: () => _leaveCollectiveChallenge(c['id'].toString()),
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/bldr-club/desafio-coletivo',
                    arguments: {'challengeId': c['id'].toString()},
                  ).then((_) => _fetchCollectiveChallenges()),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildPastChallengesSection() {
    if (_pastLoading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator(color: gold, strokeWidth: 2)),
      );
    }

    if (_pastChallenges.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: const Center(
            child: Text('Sem histórico ainda',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _pastChallenges.map((c) {
          final name = c['name'] as String? ?? 'Desafio';
          final contribution = c['my_contribution'] as int? ?? 0;
          final endDate = DateTime.tryParse(c['ends_at'] as String? ?? '')?.toLocal();
          final dateStr = endDate != null
              ? '${endDate.day.toString().padLeft(2, '0')}/${endDate.month.toString().padLeft(2, '0')}/${endDate.year}'
              : '';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: gold.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.emoji_events_outlined,
                      color: gold.withOpacity(0.7), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (dateStr.isNotEmpty)
                        Text('Encerrado em $dateStr',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 11)),
                    ],
                  ),
                ),
                if (contribution > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: gold.withOpacity(0.3)),
                    ),
                    child: Text('+$contribution pts',
                        style: const TextStyle(
                            color: gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 11)),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ENUMS & CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────

enum _ActivityType { workout, pr, streak, photo }

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _CompactPodiumItem extends StatelessWidget {
  const _CompactPodiumItem({
    required this.entry,
    required this.color,
    required this.size,
    required this.onTap,
    this.isFirst = false,
  });

  final RankingEntry entry;
  final Color color;
  final double size;
  final bool isFirst;
  final void Function(RankingEntry) onTap;

  static const gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(entry),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(TablerIcons.crown, color: color, size: isFirst ? 18 : 14),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
              boxShadow: isFirst
                  ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)]
                  : [],
            ),
            child: CircleAvatar(
              radius: size / 2,
              backgroundColor: Colors.grey[900],
              backgroundImage:
                  entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null,
              child: entry.avatarUrl == null
                  ? Text(
                      entry.displayName.isNotEmpty ? entry.displayName[0] : '?',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: size * 0.35),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: size + 16,
            child: Text(
              entry.displayName.split(' ')[0],
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: isFirst ? 12 : 10,
                  fontWeight: FontWeight.w600),
            ),
          ),
          Text('${entry.xp} xp',
              style: TextStyle(
                  color: color, fontSize: 9, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.name,
    required this.avatarText,
    required this.action,
    required this.time,
    required this.xp,
    required this.activityType,
    required this.reactionCount,
    required this.hasReacted,
    required this.onReact,
  });

  final String name;
  final String avatarText;
  final String action;
  final String time;
  final int xp;
  final _ActivityType activityType;
  final int reactionCount;
  final bool hasReacted;
  final VoidCallback onReact;

  static const gold = Color(0xFFD4AF37);

  Color get _badgeBg {
    switch (activityType) {
      case _ActivityType.workout:
        return const Color(0xFF0A2614);
      case _ActivityType.pr:
        return const Color(0xFF2A1800);
      case _ActivityType.streak:
        return const Color(0xFF2A0A0A);
      case _ActivityType.photo:
        return const Color(0xFF0A1A2A);
    }
  }

  Color get _badgeColor {
    switch (activityType) {
      case _ActivityType.workout:
        return const Color(0xFF4CAF50);
      case _ActivityType.pr:
        return const Color(0xFFFFB300);
      case _ActivityType.streak:
        return Colors.redAccent;
      case _ActivityType.photo:
        return const Color(0xFF2196F3);
    }
  }

  String get _badgeLabel {
    switch (activityType) {
      case _ActivityType.workout:
        return 'T';
      case _ActivityType.pr:
        return 'PR';
      case _ActivityType.streak:
        return '🔥';
      case _ActivityType.photo:
        return '📷';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: gold, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF2A2A2A),
                  child: Text(avatarText,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _badgeBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: _badgeColor, width: 1),
                  ),
                  child: Center(
                    child: Text(_badgeLabel,
                        style: TextStyle(
                            color: _badgeColor,
                            fontSize: 7,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(action,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                const SizedBox(height: 2),
                Text(time,
                    style: const TextStyle(color: Colors.white24, fontSize: 10)),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: gold.withOpacity(0.3)),
                ),
                child: Text('+$xp XP',
                    style: const TextStyle(
                        color: gold, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: onReact,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasReacted
                        ? gold.withOpacity(0.2)
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: hasReacted
                        ? Border.all(color: gold.withOpacity(0.6))
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('👊', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 4),
                      Text(
                        reactionCount > 0 ? '$reactionCount' : '',
                        style: TextStyle(
                            color: hasReacted ? gold : Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WhatsAppBanner extends StatelessWidget {
  const _WhatsAppBanner({required this.onTap});
  final VoidCallback onTap;

  // Verde do WhatsApp (#25D366) é cor de marca de terceiro — exceção válida
  // ao G4, mas só dentro do ícone. O card em si é BldrGlassCard neutro.
  static const _whatsAppGreen = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    return BldrGlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _whatsAppGreen.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat, color: _whatsAppGreen, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Grupo VIP Oficial', style: BldrText.cardTitle),
                const SizedBox(height: 2),
                Text('Clique para acessar a comunidade exclusiva', style: BldrText.meta),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: BldrColors.textMuted, size: 14),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COLLECTIVE CHALLENGE CARD
// ─────────────────────────────────────────────────────────────────────────────

class _CollectiveChallengeCard extends StatelessWidget {
  const _CollectiveChallengeCard({
    required this.challenge,
    required this.isJoined,
    required this.onJoin,
    required this.onLeave,
    required this.onTap,
  });

  final Map<String, dynamic> challenge;
  final bool isJoined;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final VoidCallback onTap;

  static const gold = Color(0xFFD4AF37);

  String _timeLeft() {
    final endsAt = DateTime.tryParse(challenge['ends_at'] ?? '')?.toLocal();
    if (endsAt == null) return '';
    final diff = endsAt.difference(DateTime.now());
    if (diff.isNegative) return 'Encerrado';
    if (diff.inDays > 0) return 'Termina em ${diff.inDays}d';
    if (diff.inHours > 0) return 'Termina em ${diff.inHours}h';
    return 'Termina em breve';
  }

  IconData _typeIcon() {
    switch (challenge['challenge_type']) {
      case 'workouts': return Icons.fitness_center;
      case 'streak': return Icons.local_fire_department;
      default: return Icons.bolt;
    }
  }

  String _typeLabel() {
    switch (challenge['challenge_type']) {
      case 'workouts': return 'Treinos';
      case 'streak': return 'Streak';
      default: return 'XP Total';
    }
  }

  String _targetSuffix() {
    switch (challenge['challenge_type']) {
      case 'workouts': return 'treinos';
      case 'streak': return 'dias';
      default: return 'XP';
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = (challenge['target_value'] as num?)?.toInt() ?? 1;
    final current = (challenge['current_value'] as num?)?.toInt() ?? 0;
    final progress = (current / target).clamp(0.0, 1.0);
    final participantCount = challenge['participant_count'] as int? ?? 0;
    final rewardXp = (challenge['reward_xp'] as num?)?.toInt() ?? 0;
    final badge = challenge['reward_badge'] as String? ?? '';
    final isCompleted = (challenge['status'] as String?) == 'completed';
    final coverUrl = challenge['cover_image_url'] as String?;
    final isOfficial = challenge['is_official'] == true;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF4CAF50).withOpacity(0.4)
              : gold.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          if (coverUrl != null && coverUrl.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                coverUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

          // --- conteúdo original começa aqui ---
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_typeIcon(), color: gold, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isOfficial) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: gold.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.verified, color: gold, size: 10),
                            SizedBox(width: 3),
                            Text('OFICIAL BLDR',
                                style: TextStyle(
                                    color: gold,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8)),
                          ],
                        ),
                      ),
                    ],
                    Text(challenge['title'] ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(_typeLabel(),
                        style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                  ],
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4)),
                  ),
                  child: const Text('Concluído',
                      style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                )
              else
                Text(_timeLeft(),
                    style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),

          if ((challenge['description'] as String? ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(challenge['description'],
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$current / $target ${_targetSuffix()}',
                  style: const TextStyle(
                      color: gold, fontSize: 11, fontWeight: FontWeight.bold)),
              Text('${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey[900],
              valueColor: AlwaysStoppedAnimation(
                  isCompleted ? const Color(0xFF4CAF50) : gold),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(Icons.group, color: Colors.white38, size: 13),
              const SizedBox(width: 4),
              Text('$participantCount participantes',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11)),
              const SizedBox(width: 10),
              const Icon(Icons.bolt, color: gold, size: 13),
              const SizedBox(width: 2),
              Text('+$rewardXp XP',
                  style: const TextStyle(
                      color: gold, fontSize: 11, fontWeight: FontWeight.bold)),
              if (badge.isNotEmpty) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text('· $badge',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
              const Spacer(),
              if (!isCompleted)
                GestureDetector(
                  onTap: isJoined ? onLeave : onJoin,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isJoined
                          ? Colors.redAccent.withOpacity(0.12)
                          : gold,
                      borderRadius: BorderRadius.circular(8),
                      border: isJoined
                          ? Border.all(color: Colors.redAccent.withOpacity(0.35))
                          : null,
                    ),
                    child: Text(
                      isJoined ? 'Sair' : 'Participar',
                      style: TextStyle(
                          color: isJoined ? Colors.redAccent : Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),

              ], // Column children
            ), // Column
          ), // Padding
        ],
      ),
    ), // Container
    ); // GestureDetector
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATE CHALLENGE MODAL — 4 STEPS
// ─────────────────────────────────────────────────────────────────────────────

class _CreateChallengeModal extends StatefulWidget {
  const _CreateChallengeModal({required this.myUserId, required this.onCreated});
  final String myUserId;
  final VoidCallback onCreated;

  @override
  State<_CreateChallengeModal> createState() => _CreateChallengeModalState();
}

class _CreateChallengeModalState extends State<_CreateChallengeModal> {
  static const gold = Color(0xFFD4AF37);

  final _pageController = PageController();
  int _currentStep = 0;

  // Step 1
  String _selectedType = 'xp_total';
  XFile? _coverImage;
  final _nameController = TextEditingController();
  // Step 2
  int _selectedTarget = 5000;
  int _selectedRewardXp = 100;
  final _badgeController = TextEditingController();
  // Step 3
  int _selectedDays = 7;

  bool _isSubmitting = false;
  bool _useCustomTarget = false;
  final _customTargetController = TextEditingController();

  static const _typeOptions = [
    {'value': 'xp_total', 'label': 'XP Total', 'icon': Icons.bolt, 'desc': 'Comunidade acumula XP juntos'},
    {'value': 'workouts', 'label': 'Treinos', 'icon': Icons.fitness_center, 'desc': 'Comunidade completa treinos'},
    {'value': 'streak', 'label': 'Streak', 'icon': Icons.local_fire_department, 'desc': 'Todos mantêm sequência de dias'},
  ];

  // Grupos de fontes de XP para filtro do desafio coletivo
  static const _sourceGroups = [
    {
      'key': 'bldr_club',
      'label': 'BLDR CLUB',
      'icon': Icons.bolt,
      'criteria': ['club_workout_completed', 'consecutive_club_workouts', 'monthly_club_workouts'],
    },
    {
      'key': 'bldr_run',
      'label': 'BLDR RUN',
      'icon': Icons.directions_run,
      'criteria': ['run_tracker'],
    },
    {
      'key': 'nutrition',
      'label': 'Nutrição',
      'icon': Icons.restaurant,
      'criteria': ['meal_logged', 'daily_meals_bonus', 'hydration_log'],
    },
    {
      'key': 'free_workouts',
      'label': 'Treinos Livres',
      'icon': Icons.fitness_center,
      'criteria': ['free_workout_completed'],
    },
  ];

  // Fontes selecionadas — vazio = todas contam (null no banco)
  Set<String> _selectedSources = {};

  Map<String, List<int>> get _targetOptions => {
        'xp_total': [1000, 5000, 10000, 25000],
        'workouts': [10, 25, 50, 100],
        'streak': [3, 7, 14, 30],
      };

  static const _rewardOptions = [50, 100, 200, 500];
  static const _daysOptions = [3, 7, 14, 30];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _badgeController.dispose();
    _customTargetController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < 3) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    }
  }

  String _buildTitle() {
    final custom = _nameController.text.trim();
    if (custom.isNotEmpty) return custom;
    switch (_selectedType) {
      case 'workouts': return '💪 Desafio de $_selectedTarget Treinos';
      case 'streak': return '🔥 Streak de $_selectedDays Dias';
      default: return '⚡ Desafio de $_selectedTarget XP';
    }
  }

  String _buildDescription() {
    switch (_selectedType) {
      case 'workouts':
        return 'A comunidade precisa completar $_selectedTarget treinos em $_selectedDays dias. Cada treino conta!';
      case 'streak':
        return 'Todos os participantes precisam manter uma sequência de $_selectedDays dias consecutivos de treino.';
      default:
        return 'A comunidade precisa acumular $_selectedTarget XP em $_selectedDays dias. Cada treino e conquista conta!';
    }
  }

  String _targetSuffix() {
    switch (_selectedType) {
      case 'workouts': return 'treinos';
      case 'streak': return 'dias';
      default: return 'XP';
    }
  }


  Future<void> _submit() async {
    // Capture messenger and navigator BEFORE any async gap — context may be
    // invalid after await or Navigator.pop.
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    setState(() => _isSubmitting = true);
    try {
      final badge = _badgeController.text.trim();

      final result = await getIt<CreateCollectiveChallenge>()(
        NewCollectiveChallenge(
          title: _buildTitle(),
          description: _buildDescription(),
          challengeType: _selectedType,
          targetValue: _selectedTarget,
          rewardXp: _selectedRewardXp,
          rewardBadge: badge.isNotEmpty ? badge : null,
          endsAt: DateTime.now().add(Duration(days: _selectedDays)).toUtc(),
          coverImagePath: _coverImage?.path,
          allowedSources: _selectedSources.isEmpty
              ? null
              : _selectedSources.toList(),
        ),
      );
      final failure = result.failureOrNull;
      if (failure != null) throw Exception(failure.message);

      widget.onCreated();
      nav.pop();
      messenger.showSnackBar(const SnackBar(
        content: Text('🏆 Desafio coletivo publicado!'),
        backgroundColor: gold,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      debugPrint('[COLETIVO] Erro ao publicar desafio: $e');
      messenger.showSnackBar(SnackBar(
        content: Text('Erro ao criar desafio: $e'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating, // garante visível sobre o modal
        duration: const Duration(seconds: 5),
      ));
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF151515),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: gold, width: 1)),
      ),
      child: Column(
        children: [
          _buildModalHeader(),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
                _buildStep4(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalHeader() {
    const stepLabels = ['Tipo', 'Meta', 'Prazo', 'Revisão'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[800], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: _currentStep > 0 ? _prev : () => Navigator.pop(context),
                child: Icon(
                  _currentStep > 0 ? Icons.arrow_back_ios : Icons.close,
                  color: Colors.white54,
                  size: 18,
                ),
              ),
              const Expanded(
                child: Text('CRIAR DESAFIO COLETIVO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1)),
              ),
              const SizedBox(width: 18),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(4, (i) => Expanded(
              child: Container(
                height: 3,
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i <= _currentStep ? gold : Colors.grey[800],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: stepLabels
                .map((label) => Text(label,
                    style: TextStyle(
                        color: stepLabels.indexOf(label) <= _currentStep
                            ? gold
                            : Colors.grey[700],
                        fontSize: 10,
                        fontWeight: FontWeight.bold)))
                .toList(),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Qual é o tipo do desafio?',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Define como o progresso coletivo será medido',
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 20),
          // Cover image picker
          GestureDetector(
            onTap: () async {
              final picked = await ImagePicker()
                  .pickImage(source: ImageSource.gallery, imageQuality: 85);
              if (picked != null) setState(() => _coverImage = picked);
            },
            child: Container(
              height: 130,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _coverImage != null
                      ? gold.withOpacity(0.6)
                      : Colors.white10,
                  width: _coverImage != null ? 1.5 : 1,
                ),
                image: _coverImage != null
                    ? DecorationImage(
                        image: FileImage(File(_coverImage!.path)),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.35), BlendMode.darken),
                      )
                    : null,
              ),
              child: Center(
                child: _coverImage != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: gold, size: 18),
                          const SizedBox(width: 6),
                          const Text('Imagem selecionada',
                              style: TextStyle(
                                  color: gold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => setState(() => _coverImage = null),
                            child: const Icon(Icons.close,
                                color: Colors.white54, size: 16),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              color: Colors.white38, size: 32),
                          const SizedBox(height: 8),
                          const Text('Adicionar imagem de capa',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('opcional',
                              style: TextStyle(
                                  color: Colors.grey[700], fontSize: 11)),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Nome do desafio ──────────────────────────────────────────────
          TextField(
            controller: _nameController,
            maxLength: 50,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Nome do desafio (opcional)',
              hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
              counterStyle: TextStyle(color: Colors.grey[700], fontSize: 10),
              prefixIcon: const Icon(Icons.edit_outlined, color: Colors.white38, size: 18),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: gold.withOpacity(0.6)),
              ),
            ),
            onChanged: (_) => setState(() {}), // atualiza preview em tempo real
          ),
          const SizedBox(height: 16),

          ..._typeOptions.map((t) {
            final selected = _selectedType == t['value'];
            return GestureDetector(
              onTap: () => setState(() {
                _selectedType = t['value'] as String;
                _selectedTarget = _targetOptions[_selectedType]![1];
                _useCustomTarget = false;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selected ? gold.withOpacity(0.07) : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: selected ? gold : Colors.white10,
                      width: selected ? 1.5 : 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: selected ? gold.withOpacity(0.15) : Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(t['icon'] as IconData,
                          color: selected ? gold : Colors.white54, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t['label'] as String,
                              style: TextStyle(
                                  color: selected ? gold : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          const SizedBox(height: 3),
                          Text(t['desc'] as String,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                    ),
                    if (selected) const Icon(Icons.check_circle, color: gold, size: 20),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          _buildSourcesSection(),
          const SizedBox(height: 20),
          _primaryButton('Próximo', _next),
        ],
      ),
    );
  }

  Widget _buildSourcesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _sectionLabel('O QUE CONTA PARA ESTE DESAFIO?'),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _selectedSources.isEmpty
              ? 'Nenhuma seleção = todas as atividades contam'
              : '${_selectedSources.length} fonte(s) selecionada(s)',
          style: TextStyle(color: Colors.grey[600], fontSize: 11),
        ),
        const SizedBox(height: 12),
        ..._sourceGroups.map((g) {
          final criteria = (g['criteria'] as List).cast<String>();
          final isOn = criteria.any((c) => _selectedSources.contains(c));
          return GestureDetector(
            onTap: () => setState(() {
              if (isOn) {
                _selectedSources.removeAll(criteria);
              } else {
                _selectedSources.addAll(criteria);
              }
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isOn ? gold.withOpacity(0.07) : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isOn ? gold : Colors.white10,
                    width: isOn ? 1.5 : 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isOn ? gold.withOpacity(0.15) : Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(g['icon'] as IconData,
                        color: isOn ? gold : Colors.white54, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(g['label'] as String,
                        style: TextStyle(
                            color: isOn ? gold : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                  Icon(
                    isOn ? Icons.toggle_on : Icons.toggle_off,
                    color: isOn ? gold : Colors.white30,
                    size: 32,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStep2() {
    final targets = _targetOptions[_selectedType]!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Meta e recompensa',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          _sectionLabel('META (${_targetSuffix().toUpperCase()})'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...targets.map((t) => _chip(
                    '$t ${_targetSuffix()}',
                    _selectedTarget == t && !_useCustomTarget,
                    () => setState(() {
                      _selectedTarget = t;
                      _useCustomTarget = false;
                    }),
                  )),
              if (_selectedType == 'xp_total')
                _chip(
                  'Personalizado',
                  _useCustomTarget,
                  () => setState(() {
                    _useCustomTarget = true;
                    _customTargetController.text = _selectedTarget.toString();
                  }),
                ),
            ],
          ),
          if (_useCustomTarget && _selectedType == 'xp_total') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customTargetController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ex: 100000',
                hintStyle:
                    TextStyle(color: Colors.grey[600], fontSize: 14),
                prefixIcon:
                    const Icon(Icons.bolt, color: gold, size: 18),
                suffixText: 'XP',
                suffixStyle: const TextStyle(
                    color: gold, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: gold.withOpacity(0.6)),
                ),
              ),
              onChanged: (v) {
                final parsed = int.tryParse(v.trim());
                if (parsed != null && parsed > 0) {
                  setState(() => _selectedTarget = parsed);
                }
              },
            ),
          ],

          const SizedBox(height: 20),
          _sectionLabel('RECOMPENSA (XP)'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _rewardOptions.map((r) => _chip(
              '+$r XP',
              _selectedRewardXp == r,
              () => setState(() => _selectedRewardXp = r),
            )).toList(),
          ),

          const SizedBox(height: 20),
          _sectionLabel('BADGE (opcional)'),
          const SizedBox(height: 10),
          TextField(
            controller: _badgeController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'ex: Guerreiro Coletivo',
              hintStyle: TextStyle(color: Colors.grey[700]),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: gold.withOpacity(0.5))),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),

          const SizedBox(height: 28),
          _primaryButton('Próximo', _next),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Qual é o prazo?',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('O desafio começa imediatamente ao publicar',
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 20),

          ..._daysOptions.map((d) {
            final selected = _selectedDays == d;
            final endsAt = DateTime.now().add(Duration(days: d));
            final dateStr =
                '${endsAt.day.toString().padLeft(2, '0')}/${endsAt.month.toString().padLeft(2, '0')}/${endsAt.year}';
            final dLabel =
                d == 3 ? '3 dias' : d == 7 ? '1 semana' : d == 14 ? '2 semanas' : '1 mês';

            return GestureDetector(
              onTap: () => setState(() => _selectedDays = d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? gold.withOpacity(0.07) : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: selected ? gold : Colors.white10,
                      width: selected ? 1.5 : 1),
                ),
                child: Row(
                  children: [
                    Text(dLabel,
                        style: TextStyle(
                            color: selected ? gold : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const Spacer(),
                    Text('até $dateStr',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    if (selected) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.check_circle, color: gold, size: 18),
                    ],
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 28),
          _primaryButton('Revisar', _next),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    final endsAt = DateTime.now().add(Duration(days: _selectedDays));
    final dateStr =
        '${endsAt.day.toString().padLeft(2, '0')}/${endsAt.month.toString().padLeft(2, '0')}';
    final typeLabel =
        (_typeOptions.firstWhere((t) => t['value'] == _selectedType)['label']) as String;
    final typeIcon =
        (_typeOptions.firstWhere((t) => t['value'] == _selectedType)['icon']) as IconData;
    final badge = _badgeController.text.trim();
    final dLabel = _selectedDays == 3
        ? '3 dias'
        : _selectedDays == 7
            ? '1 semana'
            : _selectedDays == 14
                ? '2 semanas'
                : '1 mês';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tudo certo?',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Confira antes de publicar para a comunidade',
              style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 20),

          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: gold.withOpacity(0.3)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cover image preview ──────────────────────────────────────
                if (_coverImage != null)
                  Stack(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 140,
                        child: Image.file(
                          File(_coverImage!.path),
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Gradient overlay so the title below stays readable
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                const Color(0xFF0F0F0F).withOpacity(0.85),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                // ── Text content ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(typeIcon, color: gold, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_buildTitle(),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(_buildDescription(),
                          style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      const Divider(color: Colors.white10, height: 24),
                      _reviewRow('Tipo', typeLabel),
                      const SizedBox(height: 8),
                      _reviewRow('Meta', '$_selectedTarget ${_targetSuffix()}'),
                      const SizedBox(height: 8),
                      _reviewRow('Prazo', '$dLabel (até $dateStr)'),
                      const SizedBox(height: 8),
                      _reviewRow('Recompensa',
                          '+$_selectedRewardXp XP${badge.isNotEmpty ? ' · $badge' : ''}'),
                      const SizedBox(height: 8),
                      _reviewRow(
                        'Atividades',
                        _selectedSources.isEmpty
                            ? 'Todas contam'
                            : _sourceGroups
                                .where((g) => (g['criteria'] as List)
                                    .cast<String>()
                                    .any((c) => _selectedSources.contains(c)))
                                .map((g) => g['label'] as String)
                                .join(' · '),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.public, color: Colors.black),
              label: Text(
                _isSubmitting ? 'Publicando...' : 'PUBLICAR DESAFIO',
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? gold.withOpacity(0.12) : Colors.grey[900],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? gold : Colors.grey[800]!,
              width: selected ? 1.5 : 1),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? gold : Colors.white70,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13)),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: TextStyle(
          color: Colors.white54, fontSize: 10, letterSpacing: 1.5));

  Widget _reviewRow(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      );
}

class _GoldRadialBg extends StatelessWidget {
  const _GoldRadialBg();
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: const [
            _Blob(top: -180, opacity: 0.25, factor: 1.8),
            _Blob(bottom: -140, opacity: 0.15, factor: 1.6),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({this.top, this.bottom, required this.opacity, required this.factor});
  final double? top;
  final double? bottom;
  final double opacity;
  final double factor;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width * factor;
    final c = const Color(0xFFD4AF37).withOpacity(opacity);
    final blob = Center(
      child: Container(
        width: w,
        height: w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: RadialGradient(colors: [c, c.withOpacity(0)], radius: 0.75),
        ),
      ),
    );
    if (top != null) return Positioned(top: top, left: 0, right: 0, child: blob);
    if (bottom != null) return Positioned(bottom: bottom, left: 0, right: 0, child: blob);
    return Positioned.fill(child: blob);
  }
}
