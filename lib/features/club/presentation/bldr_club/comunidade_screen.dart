import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/design_system/bldr_community_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';
import 'package:bldr_fitness/features/club/domain/repositories/arena_repository.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/create_collective_challenge_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/notifications_screen.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_post.dart';
import 'package:bldr_fitness/features/community/domain/repositories/community_feed_repository.dart';
import 'package:bldr_fitness/features/community/presentation/community_comments_sheet.dart';
import 'package:bldr_fitness/features/community/presentation/community_profile_search_screen.dart';
import 'package:bldr_fitness/features/community/presentation/create_post_screen.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_post_card_v2.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_squads_tab_v2.dart';
import 'package:bldr_fitness/features/community/presentation/ranking_screen.dart';
import 'package:bldr_fitness/features/community/presentation/workout_detail_sheet.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Hub da Comunidade v2 (Figma UAUhuDakeseJsEfb8ynv5h — 4:2, 4:57, 4:108).
class ComunidadeScreen extends StatefulWidget {
  /// Mantido por compatibilidade com o dashboard; o mockup não tem "voltar".
  final VoidCallback? onBack;

  const ComunidadeScreen({super.key, this.onBack});

  @override
  State<ComunidadeScreen> createState() => _ComunidadeScreenState();
}

class _ComunidadeScreenState extends State<ComunidadeScreen> {
  late final CommunityFeedRepository _repo;

  // ── Tab state ──────────────────────────────────────────────────────────────
  int _activeTab = 0;

  // ── Explorar / Seguindo: feed compartilhado ────────────────────────────────
  List<CommunityPost> _posts = [];
  bool _loading = true;
  bool _loadingMore = false;
  Failure? _feedError;
  DateTime? _cursor;
  bool _hasMore = true;

  List<CommunityPost> _followingPosts = [];
  bool _followingLoading = true;
  Failure? _followingError;

  // ── Squads ─────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _squads = [];
  bool _squadsLoading = true;
  Failure? _squadsError;
  int _unreadNotifications = 0;

  // ── New posts realtime ──────────────────────────────────────────────────────
  RealtimeChannel? _feedChannel;
  bool _hasNewPosts = false;

  @override
  void initState() {
    super.initState();
    _repo = getIt<CommunityFeedRepository>();
    _loadFeed();
    _loadFollowingFeed();
    _loadSquads();
    _loadUnreadNotifications();
    _subscribeFeedRealtime();
  }

  void _subscribeFeedRealtime() {
    final currentUid = Supabase.instance.client.auth.currentUser?.id;
    _feedChannel?.unsubscribe();
    _feedChannel = Supabase.instance.client.channel('community_feed_new_posts')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'community_feed',
        callback: (payload) {
          if (!mounted) return;
          // Only indicate new posts from other users
          final postUserId = payload.newRecord['user_id'] as String?;
          if (postUserId != null &&
              postUserId != currentUid &&
              _activeTab == 0) {
            setState(() => _hasNewPosts = true);
          }
        },
      )
      ..subscribe();
  }

  @override
  void dispose() {
    _feedChannel?.unsubscribe();
    _feedChannel = null;
    super.dispose();
  }

  // ── Feed ───────────────────────────────────────────────────────────────────

  Future<void> _loadFeed({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _posts = [];
        _cursor = null;
        _hasMore = true;
        _feedError = null;
        _loading = true;
        _hasNewPosts = false;
      });
    }
    final result = await _repo.fetchFeed(limit: 20, before: _cursor);
    if (!mounted) return;
    result.fold(
      onSuccess: (posts) => setState(() {
        _posts.addAll(posts);
        if (posts.isNotEmpty) _cursor = posts.last.createdAt;
        _hasMore = posts.length == 20;
        _feedError = null;
        _loading = false;
        _loadingMore = false;
      }),
      onFailure: (failure) => setState(() {
        _feedError = failure;
        _loading = false;
        _loadingMore = false;
      }),
    );
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore || _loading) return;
    setState(() => _loadingMore = true);
    await _loadFeed();
  }

  Future<void> _loadFollowingFeed() async {
    setState(() {
      _followingLoading = true;
      _followingError = null;
    });
    final result = await _repo.fetchFollowingFeed();
    if (!mounted) return;
    result.fold(
      onSuccess: (posts) => setState(() {
        _followingPosts = posts;
        _followingLoading = false;
      }),
      onFailure: (failure) => setState(() {
        _followingError = failure;
        _followingLoading = false;
      }),
    );
  }

  void _onScroll(ScrollNotification n) {
    if (n is ScrollUpdateNotification) {
      final m = n.metrics;
      if (m.pixels >= m.maxScrollExtent * 0.85) _loadMore();
    }
  }

  // ── Squads ─────────────────────────────────────────────────────────────────

  Future<void> _loadSquads() async {
    setState(() {
      _squadsLoading = true;
      _squadsError = null;
    });
    final result = await getIt<ArenaRepository>().mySquads();
    if (!mounted) return;
    result.fold(
      onSuccess: (squads) => setState(() {
        _squads = squads;
        _squadsLoading = false;
      }),
      onFailure: (failure) => setState(() {
        _squadsError = failure;
        _squadsLoading = false;
      }),
    );
  }

  Future<void> _loadUnreadNotifications() async {
    final result = await getIt<GetClubNotifications>()(limit: 50);
    if (!mounted) return;
    final notifications = result.valueOrNull;
    if (notifications == null) return;
    setState(() {
      _unreadNotifications = notifications.where((item) => !item.isRead).length;
    });
  }

  // ── Reactions ──────────────────────────────────────────────────────────────

  /// Uma reação por usuário: tocar no mesmo emoji remove; outro emoji troca.
  CommunityPost _applyReaction(CommunityPost p, String emoji) {
    final previous = p.myReactionEmoji;
    final reactions = List<CommunityReaction>.from(p.reactions);
    void bump(String e, int delta) {
      final i = reactions.indexWhere((r) => r.emoji == e);
      final count = (i == -1 ? 0 : reactions[i].count) + delta;
      if (i != -1) reactions.removeAt(i);
      if (count > 0) {
        reactions.insert(i == -1 ? reactions.length : i,
            CommunityReaction(emoji: e, count: count));
      }
    }

    if (previous != null) bump(previous, -1);
    if (previous == emoji) {
      return p.copyWith(reactions: reactions, clearMyReaction: true);
    }
    bump(emoji, 1);
    return p.copyWith(reactions: reactions, myReactionEmoji: emoji);
  }

  Future<void> _toggleReaction(CommunityPost post, String emoji) async {
    setState(() {
      for (final list in [_posts, _followingPosts]) {
        final idx = list.indexWhere((p) => p.id == post.id);
        if (idx != -1) list[idx] = _applyReaction(list[idx], emoji);
      }
    });
    final result = await _repo.toggleReaction(feedId: post.id, emoji: emoji);
    if (result.isFailure) {
      _loadFeed(refresh: true);
      _loadFollowingFeed();
    }
  }

  void _openWorkoutDetail(CommunityPost post) {
    final workoutId = post.payload['workout_id'] as String?;
    if (workoutId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WorkoutDetailSheet(
        workoutId: workoutId,
        source: post.payload['source'] as String? ?? 'free',
        workoutName: post.workoutName,
      ),
    );
  }

  void _openComments(CommunityPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .62),
      builder: (_) => CommunityCommentsSheet(feedId: post.id),
    ).then((_) {
      _loadFeed(refresh: true);
      _loadFollowingFeed();
    });
  }

  Future<void> _toggleFollow(CommunityPost post) async {
    final result = post.isFollowing
        ? await _repo.unfollowUser(post.userId)
        : await _repo.followUser(post.userId);
    if (!mounted) return;
    if (result.isFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.failureOrNull!.message)),
      );
      return;
    }
    setState(() {
      _posts = _posts
          .map((item) => item.userId == post.userId
              ? item.copyWith(isFollowing: !post.isFollowing)
              : item)
          .toList();
      _followingPosts = post.isFollowing
          ? _followingPosts.where((item) => item.userId != post.userId).toList()
          : _followingPosts;
    });
    if (!post.isFollowing) await _loadFollowingFeed();
  }

  // ── Ações do post (6:8 — D2) ───────────────────────────────────────────────

  Future<void> _showPostActions(CommunityPost post) async {
    final l10n = AppLocalizations.of(context);
    final action = await BldrV2Sheet.show<String>(
      context,
      title: l10n.comm_actions_title,
      child: Builder(
        builder: (ctx) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (post.username != null)
              Text('@${post.username}',
                  textAlign: TextAlign.center,
                  style: BldrCommunityTextV2.sheetHandle),
            const SizedBox(height: 8),
            if (post.isOwnPost)
              BldrCommunitySheetRow(
                icon: TablerIcons.trash,
                title: l10n.comm_action_delete,
                subtitle: l10n.comm_action_delete_sub,
                destructive: true,
                onTap: () => Navigator.pop(ctx, 'delete'),
              )
            else ...[
              BldrCommunitySheetRow(
                icon: TablerIcons.ban,
                title: l10n.comm_action_block,
                subtitle: l10n.comm_action_block_sub,
                onTap: () => Navigator.pop(ctx, 'block'),
              ),
              BldrCommunitySheetRow(
                icon: TablerIcons.flag,
                title: l10n.comm_action_report,
                subtitle: l10n.comm_action_report_sub,
                destructive: true,
                onTap: () => Navigator.pop(ctx, 'report'),
              ),
            ],
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'delete') await _confirmDelete(post);
    if (action == 'block') await _confirmBlock(post);
    if (action == 'report') await _reportPost(post);
  }

  Future<void> _confirmDelete(CommunityPost post) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await BldrV2ConfirmDialog.show(
      context,
      title: l10n.comm_delete_title,
      message: l10n.comm_delete_msg,
      confirmLabel: l10n.comm_delete_confirm,
      cancelLabel: l10n.comm_cancel,
      destructive: true,
    );
    if (!confirmed) return;
    final result = await _repo.deletePost(post.id);
    if (!mounted) return;
    _showActionResult(result, success: l10n.comm_deleted);
    if (result.isSuccess) {
      setState(() {
        _posts.removeWhere((item) => item.id == post.id);
        _followingPosts.removeWhere((item) => item.id == post.id);
      });
    }
  }

  Future<void> _confirmBlock(CommunityPost post) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await BldrV2ConfirmDialog.show(
      context,
      title: l10n.comm_block_title(post.authorName),
      message: l10n.comm_block_msg,
      confirmLabel: l10n.comm_block_confirm,
      cancelLabel: l10n.comm_cancel,
      destructive: true,
    );
    if (!confirmed) return;
    final result = await _repo.blockUser(post.userId);
    if (!mounted) return;
    _showActionResult(result, success: l10n.comm_blocked);
    if (result.isSuccess) {
      setState(() {
        _posts.removeWhere((item) => item.userId == post.userId);
        _followingPosts.removeWhere((item) => item.userId == post.userId);
      });
    }
  }

  Future<void> _reportPost(CommunityPost post) async {
    final l10n = AppLocalizations.of(context);
    final reasons = [
      ('spam', l10n.comm_report_spam, l10n.comm_report_spam_sub),
      (
        'harassment',
        l10n.comm_report_harassment,
        l10n.comm_report_harassment_sub
      ),
      (
        'inappropriate_content',
        l10n.comm_report_inappropriate,
        l10n.comm_report_inappropriate_sub
      ),
      ('false_information', l10n.comm_report_false, l10n.comm_report_false_sub),
      ('other', l10n.comm_report_other, l10n.comm_report_other_sub),
    ];
    final reason = await BldrV2Sheet.show<String>(
      context,
      title: l10n.comm_report_title,
      child: Builder(
        builder: (ctx) => Column(
          children: [
            for (final r in reasons)
              BldrCommunitySheetRow(
                icon: TablerIcons.flag,
                title: r.$2,
                subtitle: r.$3,
                onTap: () => Navigator.pop(ctx, r.$1),
              ),
          ],
        ),
      ),
    );
    if (!mounted || reason == null) return;
    final result = await _repo.reportUser(
      userId: post.userId,
      feedId: post.id,
      reason: reason,
    );
    if (!mounted) return;
    _showActionResult(result, success: l10n.comm_reported);
  }

  void _showActionResult(Result<void> result, {required String success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.failureOrNull?.message ?? success)),
    );
  }

  /// Toque longo na reação: escolher entre os emojis existentes.
  Future<void> _pickReaction(CommunityPost post) async {
    final l10n = AppLocalizations.of(context);
    final emoji = await BldrV2Sheet.show<String>(
      context,
      title: l10n.comm_react_title,
      child: Builder(
        builder: (ctx) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final e in communityReactionEmojis)
              Semantics(
                button: true,
                selected: post.myReactionEmoji == e,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, e),
                  child: Container(
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: post.myReactionEmoji == e
                            ? BldrCommunityColorsV2.gold
                            : BldrCommunityColorsV2.divider,
                      ),
                    ),
                    child: Text(e, style: BldrCommunityTextV2.emoji),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (!mounted || emoji == null) return;
    await _toggleReaction(post, emoji);
  }

  /// Compartilhar (6:90 adiado): abre direto o share nativo do sistema.
  Future<void> _sharePost(CommunityPost post) async {
    final l10n = AppLocalizations.of(context);
    final detail = switch (post.eventType) {
      CommunityEventType.workoutCompleted => post.workoutName,
      CommunityEventType.prBeaten => post.exerciseName,
      _ => post.caption,
    };
    final text = detail == null || detail.trim().isEmpty
        ? l10n.comm_share_text_simple(post.authorName)
        : l10n.comm_share_text(post.authorName, detail.trim());
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(ShareParams(
      text: text,
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    ));
  }

  void _openSearch() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CommunityProfileSearchScreen()),
    );
    _loadFollowingFeed();
  }

  // ── Build (4:2 / 4:57 / 4:108) ─────────────────────────────────────────────

  CommunityPostCardV2 _card(CommunityPost post,
          {Future<void> Function(CommunityPost)? onMore}) =>
      CommunityPostCardV2(
        post: post,
        now: DateTime.now(),
        onReaction: _toggleReaction,
        onLongReact: _pickReaction,
        onOpenWorkout: _openWorkoutDetail,
        onComments: _openComments,
        onFollow: _toggleFollow,
        onMore: onMore ?? _showPostActions,
        onShare: _sharePost,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BldrBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        floatingActionButton: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom + 72, right: 4),
          child: BldrCommunityFab(
            semanticLabel: l10n.comm_create_post,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreatePostScreen()),
              ).then((_) => _loadFeed(refresh: true));
            },
          ),
        ),
        body: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top),
            _buildHeader(l10n),
            _buildTabRow(l10n),
            if (_hasNewPosts && _activeTab == 0)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: GestureDetector(
                  onTap: () => _loadFeed(refresh: true),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                    decoration: BoxDecoration(
                      color: BldrCommunityColorsV2.surface,
                      border: Border.all(color: BldrCommunityColorsV2.gold),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(l10n.comm_new_posts,
                        style: BldrCommunityTextV2.cta),
                  ),
                ),
              ),
            Expanded(
              child: IndexedStack(
                index: _activeTab,
                children: [
                  _FeedList(
                    posts: _posts,
                    loading: _loading,
                    loadingMore: _loadingMore,
                    error: _feedError,
                    onScroll: _onScroll,
                    onRefresh: () => _loadFeed(refresh: true),
                    cardBuilder: _card,
                    empty: _FeedMessage(
                      title: l10n.comm_empty_title,
                      body: l10n.comm_empty_body,
                    ),
                  ),
                  _FeedList(
                    posts: _followingPosts,
                    loading: _followingLoading,
                    loadingMore: false,
                    error: _followingError,
                    onRefresh: _loadFollowingFeed,
                    cardBuilder: _card,
                    empty: _FeedMessage(
                      title: l10n.comm_following_empty_title,
                      body: l10n.comm_following_empty_body,
                      action: l10n.comm_following_empty_cta,
                      onAction: _openSearch,
                    ),
                  ),
                  CommunitySquadsTabV2(
                    squads: _squads,
                    loading: _squadsLoading,
                    error: _squadsError,
                    onRefresh: _loadSquads,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BldrCommunityV2.pageX, 20, BldrCommunityV2.pageX - 4, 0),
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(l10n.club_community_title,
                  maxLines: 1, style: BldrCommunityTextV2.title),
            ),
          ),
          BldrCommunityShortcut(
            icon: TablerIcons.search,
            semanticLabel: l10n.comm_shortcut_search,
            onTap: _openSearch,
          ),
          BldrCommunityShortcut(
            icon: TablerIcons.lock,
            semanticLabel: l10n.comm_shortcut_private,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _PrivatePostsScreen(
                  repository: _repo,
                  cardBuilder: _card,
                  onMore: _showPostActions,
                ),
              ),
            ),
          ),
          BldrCommunityShortcut(
            icon: TablerIcons.target_arrow,
            semanticLabel: l10n.comm_shortcut_challenges,
            onTap: () async {
              final created = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateCollectiveChallengeScreen(),
                ),
              );
              if (created == true) _loadFeed(refresh: true);
            },
          ),
          BldrCommunityShortcut(
            icon: TablerIcons.trophy,
            semanticLabel: l10n.comm_shortcut_ranking,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RankingScreen())),
          ),
          BldrCommunityShortcut(
            icon: TablerIcons.bell,
            semanticLabel: l10n.comm_shortcut_notifications,
            badge: _unreadNotifications,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
              _loadUnreadNotifications();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabRow(AppLocalizations l10n) {
    final tabs = [
      l10n.comm_tab_explore,
      l10n.comm_tab_following,
      l10n.comm_tab_squads,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BldrCommunityV2.pageX, 12, BldrCommunityV2.pageX, 0),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < tabs.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: _activeTab == i,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _activeTab = i),
                      child: SizedBox(
                        height: 36,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(tabs[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _activeTab == i
                                    ? BldrCommunityTextV2.tabOn
                                    : BldrCommunityTextV2.tabOff),
                            const SizedBox(height: 8),
                            Container(
                              width: 60,
                              height: 2,
                              decoration: BoxDecoration(
                                color: _activeTab == i
                                    ? BldrCommunityColorsV2.gold
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Container(height: 1, color: BldrCommunityColorsV2.divider),
        ],
      ),
    );
  }
}

typedef _CardBuilder = Widget Function(CommunityPost post,
    {Future<void> Function(CommunityPost)? onMore});

// ── Lista de posts (Explorar / Seguindo) ─────────────────────────────────────

class _FeedList extends StatelessWidget {
  final List<CommunityPost> posts;
  final bool loading;
  final bool loadingMore;
  final Failure? error;
  final void Function(ScrollNotification)? onScroll;
  final Future<void> Function() onRefresh;
  final _CardBuilder cardBuilder;
  final Widget empty;

  const _FeedList({
    required this.posts,
    required this.loading,
    required this.loadingMore,
    required this.error,
    required this.onRefresh,
    required this.cardBuilder,
    required this.empty,
    this.onScroll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final err = error;
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        onScroll?.call(n);
        return false;
      },
      child: RefreshIndicator(
        color: BldrCommunityColorsV2.gold,
        backgroundColor: BldrCommunityColorsV2.surface,
        onRefresh: onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 22)),
            if (loading && posts.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(
                      color: BldrCommunityColorsV2.gold, strokeWidth: 2),
                ),
              )
            else if (err != null && posts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _FeedMessage(
                  title: l10n.comm_error_title,
                  body: err.message,
                  action: l10n.comm_retry,
                  onAction: onRefresh,
                ),
              )
            else if (posts.isEmpty)
              SliverFillRemaining(hasScrollBody: false, child: empty)
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => cardBuilder(posts[i]),
                  childCount: posts.length,
                ),
              ),
            if (loadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: BldrCommunityColorsV2.gold, strokeWidth: 2),
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(
                child: SizedBox(height: BldrSpacing.navClearance + 40)),
          ],
        ),
      ),
    );
  }
}

/// Estado vazio/erro do feed no visual v2.
class _FeedMessage extends StatelessWidget {
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;

  const _FeedMessage({
    required this.title,
    required this.body,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              textAlign: TextAlign.center,
              style: BldrCommunityTextV2.discoverTitle),
          const SizedBox(height: 6),
          Text(body,
              textAlign: TextAlign.center,
              style: BldrCommunityTextV2.discoverSub),
          if (action != null) ...[
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(BldrCommunityV2.ctaRadius),
                  border:
                      Border.all(color: BldrCommunityColorsV2.gold, width: 0.8),
                ),
                child: Text(action!, style: BldrCommunityTextV2.cta),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Posts privados (tela atual; 121:827 fora do escopo — D12) ────────────────

class _PrivatePostsScreen extends StatefulWidget {
  final CommunityFeedRepository repository;
  final _CardBuilder cardBuilder;
  final Future<void> Function(CommunityPost) onMore;

  const _PrivatePostsScreen({
    required this.repository,
    required this.cardBuilder,
    required this.onMore,
  });

  @override
  State<_PrivatePostsScreen> createState() => _PrivatePostsScreenState();
}

class _PrivatePostsScreenState extends State<_PrivatePostsScreen> {
  List<CommunityPost> _posts = [];
  bool _loading = true;
  Failure? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await widget.repository.fetchPrivatePosts();
    if (!mounted) return;
    result.fold(
      onSuccess: (posts) => setState(() {
        _posts = posts;
        _loading = false;
      }),
      onFailure: (failure) => setState(() {
        _error = failure;
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BldrBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text('Posts privados', style: BldrText.screenTitle),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: TextButton(
                      onPressed: _load,
                      child: Text('${_error!.message}\nTentar novamente'),
                    ),
                  )
                : _posts.isEmpty
                    ? Center(
                        child: Text(
                          'Você ainda não publicou posts privados.',
                          style: BldrText.description,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 16),
                          itemCount: _posts.length,
                          itemBuilder: (_, index) => widget.cardBuilder(
                            _posts[index],
                            onMore: (post) async {
                              await widget.onMore(post);
                              await _load();
                            },
                          ),
                        ),
                      ),
      ),
    );
  }
}
