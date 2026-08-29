import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/community/data/repositories/community_feed_repository_impl.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_post.dart';
import 'package:bldr_fitness/features/community/domain/repositories/community_feed_repository.dart';
import 'package:bldr_fitness/features/community/presentation/create_post_screen.dart';
import 'package:bldr_fitness/features/community/presentation/ranking_screen.dart';
import 'package:bldr_fitness/features/community/presentation/workout_detail_sheet.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

class ComunidadeScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ComunidadeScreen({super.key, this.onBack});

  @override
  State<ComunidadeScreen> createState() => _ComunidadeScreenState();
}

class _ComunidadeScreenState extends State<ComunidadeScreen> {
  late final CommunityFeedRepository _repo;

  List<CommunityPost> _posts = [];
  bool _loading = true;
  bool _loadingMore = false;
  DateTime? _cursor;
  bool _hasMore = true;
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _repo = getIt<CommunityFeedRepository>();
    _loadFeed();
  }

  Future<void> _loadFeed({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _posts = [];
        _cursor = null;
        _hasMore = true;
        _loading = true;
      });
    }
    try {
      final posts = await _repo.fetchFeed(limit: 20, before: _cursor);
      if (!mounted) return;
      setState(() {
        _posts.addAll(posts);
        if (posts.isNotEmpty) _cursor = posts.last.createdAt;
        _hasMore = posts.length == 20;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore || _loading) return;
    setState(() => _loadingMore = true);
    await _loadFeed();
  }

  void _onScroll(ScrollNotification n) {
    if (n is ScrollUpdateNotification) {
      final metrics = n.metrics;
      if (metrics.pixels >= metrics.maxScrollExtent * 0.85) {
        _loadMore();
      }
    }
  }

  Future<void> _toggleReaction(CommunityPost post, String emoji) async {
    // Otimista: atualizar estado localmente
    setState(() {
      final idx = _posts.indexWhere((p) => p.id == post.id);
      if (idx == -1) return;
      final p = _posts[idx];
      final isActive = p.myReactionEmoji == emoji;

      final newReactions = List<CommunityReaction>.from(p.reactions);
      final rxIdx = newReactions.indexWhere((r) => r.emoji == emoji);

      if (isActive) {
        // Remover reação
        if (rxIdx != -1) {
          final r = newReactions[rxIdx];
          if (r.count > 1) {
            newReactions[rxIdx] = CommunityReaction(emoji: emoji, count: r.count - 1);
          } else {
            newReactions.removeAt(rxIdx);
          }
        }
        _posts[idx] = CommunityPost(
          id: p.id, userId: p.userId, username: p.username,
          userFullName: p.userFullName, userAvatarUrl: p.userAvatarUrl,
          eventType: p.eventType, payload: p.payload,
          visibility: p.visibility, createdAt: p.createdAt,
          reactions: newReactions, commentCount: p.commentCount,
          myReactionEmoji: null,
        );
      } else {
        // Adicionar reação
        if (rxIdx != -1) {
          final r = newReactions[rxIdx];
          newReactions[rxIdx] = CommunityReaction(emoji: emoji, count: r.count + 1);
        } else {
          newReactions.add(CommunityReaction(emoji: emoji, count: 1));
        }
        _posts[idx] = CommunityPost(
          id: p.id, userId: p.userId, username: p.username,
          userFullName: p.userFullName, userAvatarUrl: p.userAvatarUrl,
          eventType: p.eventType, payload: p.payload,
          visibility: p.visibility, createdAt: p.createdAt,
          reactions: newReactions, commentCount: p.commentCount,
          myReactionEmoji: emoji,
        );
      }
    });

    try {
      await _repo.toggleReaction(feedId: post.id, emoji: emoji);
    } catch (_) {
      // Em caso de falha, recarregar o feed
      _loadFeed(refresh: true);
    }
  }

  void _openWorkoutDetail(CommunityPost post) {
    final workoutId = post.payload['workout_id'] as String?;
    if (workoutId == null) return;
    final source = post.payload['source'] as String? ?? 'free';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WorkoutDetailSheet(
        workoutId: workoutId,
        source: source,
        workoutName: post.workoutName,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BldrBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        floatingActionButton: _activeTab == 0 ? _buildFab() : null,
        body: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            _onScroll(n);
            return false;
          },
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(child: _buildTabRow()),
              SliverToBoxAdapter(child: _buildSearchBar()),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: BldrColors.goldBright,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (_posts.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                _buildFeedList(),
              if (_loadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: BldrColors.goldBright,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: BldrSpacing.navClearance),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: BldrSpacing.pageX),
        child: Row(
          children: [
            if (widget.onBack != null)
              GestureDetector(
                onTap: widget.onBack,
                child: const Icon(TablerIcons.chevron_left,
                    color: BldrColors.textPrimary, size: 24),
              ),
            Expanded(
              child: Text('Comunidade', style: BldrText.screenTitle),
            ),
            _iconBtn(TablerIcons.trophy, onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RankingScreen()),
              );
            }),
            const SizedBox(width: 8),
            _iconBtn(TablerIcons.bell, onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notificações em breve')),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: BldrColors.surface,
          border: Border.all(color: BldrColors.border),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 17, color: BldrColors.textSecondary),
      ),
    );
  }

  Widget _buildTabRow() {
    const tabs = ['Explorar', 'Seguindo', 'Squads'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BldrSpacing.pageX, 4, BldrSpacing.pageX, 12),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = _activeTab == i;
          return GestureDetector(
            onTap: () {
              if (i != 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Em breve')),
                );
                return;
              }
              setState(() => _activeTab = i);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 24),
              padding: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active
                        ? BldrColors.goldBright
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                tabs[i],
                style: BldrText.body.copyWith(
                  color: active
                      ? BldrColors.goldBright
                      : BldrColors.textTertiary,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BldrSpacing.pageX, 0, BldrSpacing.pageX, 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: BldrColors.surface,
          border: Border.all(color: BldrColors.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(TablerIcons.search, size: 15,
                color: BldrColors.textTertiary),
            const SizedBox(width: 8),
            Text('Buscar na comunidade', style: BldrText.body.copyWith(
              color: BldrColors.textTertiary,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedList() {
    // Inserir rivalry card após o 2º post (índice 2)
    final items = <Widget>[];
    for (int i = 0; i < _posts.length; i++) {
      items.add(_buildFeedCard(_posts[i]));
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => items[index],
        childCount: items.length,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(TablerIcons.users, size: 48, color: BldrColors.textTertiary),
          const SizedBox(height: 16),
          Text('Nenhum post ainda', style: BldrText.sectionTitle),
          const SizedBox(height: 8),
          Text('Seja o primeiro a compartilhar!',
              style: BldrText.description),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreatePostScreen()),
        ).then((_) => _loadFeed(refresh: true));
      },
      backgroundColor: BldrColors.goldSolid,
      child: const Icon(TablerIcons.plus, color: Colors.black),
    );
  }

  // ── Feed cards ─────────────────────────────────────────────────────────────

  Widget _buildFeedCard(CommunityPost post) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BldrSpacing.pageX, 0, BldrSpacing.pageX, 12),
      child: BldrGlassCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(post),
            const SizedBox(height: 12),
            _buildCardBody(post),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(CommunityPost post) {
    return Row(
      children: [
        _buildAvatar(post),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post.authorName, style: BldrText.cardTitle),
              Row(
                children: [
                  Text(post.displayName,
                      style: BldrText.description.copyWith(
                          color: BldrColors.goldBright)),
                  const SizedBox(width: 6),
                  Text('·', style: BldrText.meta),
                  const SizedBox(width: 6),
                  Text(_relativeTime(post.createdAt), style: BldrText.meta),
                ],
              ),
            ],
          ),
        ),
        if (post.eventType == CommunityEventType.prBeaten)
          _eventBadge('🏆 NOVO PR', const Color(0xFFE0B830),
              const Color(0x47C9A227), const Color(0x47C9A227)),
        if (post.eventType == CommunityEventType.streakMilestone)
          _eventBadge('🔥 STREAK', const Color(0xFFFF6432),
              const Color(0x14FF6432), const Color(0x40FF6432)),
      ],
    );
  }

  Widget _buildAvatar(CommunityPost post) {
    final initials = (post.authorName.isNotEmpty
            ? post.authorName[0]
            : '?')
        .toUpperCase();
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: BldrColors.goldTint,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(initials,
            style: BldrText.cardTitle.copyWith(
                color: BldrColors.goldBright, fontSize: 13)),
      ),
    );
  }

  Widget _eventBadge(
      String text, Color textColor, Color bg, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: BldrText.metaSm.copyWith(
              color: textColor, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildCardBody(CommunityPost post) {
    switch (post.eventType) {
      case CommunityEventType.workoutCompleted:
        return _buildWorkoutCard(post);
      case CommunityEventType.prBeaten:
        return _buildPrCard(post);
      case CommunityEventType.streakMilestone:
        return _buildStreakCard(post);
      default:
        return _buildManualCard(post);
    }
  }

  Widget _buildWorkoutCard(CommunityPost post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(post.workoutName, style: BldrText.cardTitleLg),
        if (post.caption != null) ...[
          const SizedBox(height: 4),
          Text(post.caption!, style: BldrText.body),
        ],
        if (post.photoUrl != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              post.photoUrl!,
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ],
        const SizedBox(height: 10),
        _buildStatsRow(post),
        if (post.muscleGroups.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildMuscleTags(post.muscleGroups),
        ],
        const SizedBox(height: 10),
        _buildViewWorkoutBtn(post),
        const SizedBox(height: 2),
        _buildReactionsRow(post),
      ],
    );
  }

  Widget _buildPrCard(CommunityPost post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: BldrColors.goldTint,
            border: Border.all(color: BldrColors.goldBorder),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (post.exerciseName != null)
                      Text(post.exerciseName!.toUpperCase(),
                          style: BldrText.meta.copyWith(
                              color: BldrColors.textSecondary,
                              letterSpacing: 0.6)),
                    Text(
                      post.prWeightKg != null
                          ? '${post.prWeightKg!.toStringAsFixed(1)} kg'
                          : '—',
                      style: BldrText.kpiMd.copyWith(
                          color: BldrColors.goldBright),
                    ),
                    if (post.prReps != null)
                      Text('${post.prReps} reps',
                          style: BldrText.description),
                    if (post.e1rm != null)
                      Text(
                          'e1RM: ${post.e1rm!.toStringAsFixed(1)} kg',
                          style: BldrText.meta),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildReactionsRow(post),
      ],
    );
  }

  Widget _buildStreakCard(CommunityPost post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${post.streakDays ?? 0}',
              style: BldrText.kpiLg.copyWith(
                  color: const Color(0xFFFF6432), fontSize: 48),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('dias consecutivos', style: BldrText.body),
                Text('de treino', style: BldrText.description),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildReactionsRow(post),
      ],
    );
  }

  Widget _buildManualCard(CommunityPost post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (post.caption != null)
          Text(post.caption!, style: BldrText.body),
        if (post.photoUrl != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              post.photoUrl!,
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ],
        if (post.payload['workout_id'] != null) ...[
          const SizedBox(height: 10),
          _buildViewWorkoutBtn(post),
        ],
        const SizedBox(height: 10),
        _buildReactionsRow(post),
      ],
    );
  }

  Widget _buildStatsRow(CommunityPost post) {
    final chips = <(String val, String lbl)>[];
    if (post.durationSeconds != null) {
      final min = (post.durationSeconds! / 60).round();
      chips.add(('${min}min', 'DURAÇÃO'));
    }
    if (post.volumeKg != null) {
      chips.add(('${post.volumeKg!.toStringAsFixed(0)}kg', 'VOLUME'));
    }
    if (post.payload['sets_completed'] != null) {
      chips.add(('${post.payload['sets_completed']}', 'SÉRIES'));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Row(
      children: chips
          .map((c) => Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0x08FFFFFF),
                  border: Border.all(color: const Color(0x0DFFFFFF)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(c.$1,
                        style: BldrText.body.copyWith(
                            color: BldrColors.goldBright,
                            fontWeight: FontWeight.w600)),
                    Text(c.$2, style: BldrText.metaSm),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildMuscleTags(List<String> muscles) {
    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: muscles
          .map((m) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x0AFFFFFF),
                  border:
                      Border.all(color: const Color(0x0FFFFFFF)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(m, style: BldrText.meta),
              ))
          .toList(),
    );
  }

  Widget _buildViewWorkoutBtn(CommunityPost post) {
    return GestureDetector(
      onTap: () => _openWorkoutDetail(post),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: BldrColors.surface,
          border: Border.all(color: BldrColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(TablerIcons.barbell, size: 14,
                color: BldrColors.textSecondary),
            const SizedBox(width: 6),
            Text('Ver treino →', style: BldrText.body),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionsRow(CommunityPost post) {
    const emojis = ['🔥', '💪', '⚡', '🏆'];
    return Row(
      children: [
        ...emojis.map((emoji) {
          final isActive = post.myReactionEmoji == emoji;
          final rx = post.reactions
              .where((r) => r.emoji == emoji)
              .firstOrNull;
          final count = rx?.count ?? 0;
          return GestureDetector(
            onTap: () => _toggleReaction(post, emoji),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0x1FC9A227)
                    : const Color(0x08FFFFFF),
                border: Border.all(
                  color: isActive
                      ? const Color(0x4DC9A227)
                      : const Color(0x0DFFFFFF),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                count > 0 ? '$emoji $count' : emoji,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          );
        }),
        const Spacer(),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Comentários disponíveis para membros Club'),
              ),
            );
          },
          child: Row(
            children: [
              const Icon(TablerIcons.message_circle, size: 13,
                  color: BldrColors.textTertiary),
              const SizedBox(width: 4),
              Text('${post.commentCount}',
                  style: BldrText.meta),
            ],
          ),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    return 'há ${diff.inDays}d';
  }
}
