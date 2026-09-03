import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/club/domain/repositories/arena_repository.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/arena_details_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/competition_hub_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/create_arena_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/create_collective_challenge_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/join_squad_sheet.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/notifications_screen.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_post.dart';
import 'package:bldr_fitness/features/community/domain/repositories/community_feed_repository.dart';
import 'package:bldr_fitness/features/community/presentation/create_post_screen.dart';
import 'package:bldr_fitness/features/community/presentation/community_profile_search_screen.dart';
import 'package:bldr_fitness/features/community/presentation/community_comments_sheet.dart';
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

  Future<void> _toggleReaction(CommunityPost post, String emoji) async {
    setState(() {
      final idx = _posts.indexWhere((p) => p.id == post.id);
      if (idx == -1) return;
      final p = _posts[idx];
      final isActive = p.myReactionEmoji == emoji;
      final newReactions = List<CommunityReaction>.from(p.reactions);
      final rxIdx = newReactions.indexWhere((r) => r.emoji == emoji);
      if (isActive) {
        if (rxIdx != -1) {
          final r = newReactions[rxIdx];
          if (r.count > 1) {
            newReactions[rxIdx] =
                CommunityReaction(emoji: emoji, count: r.count - 1);
          } else {
            newReactions.removeAt(rxIdx);
          }
        }
        _posts[idx] = p.copyWith(
          reactions: newReactions,
          clearMyReaction: true,
        );
      } else {
        if (rxIdx != -1) {
          final r = newReactions[rxIdx];
          newReactions[rxIdx] =
              CommunityReaction(emoji: emoji, count: r.count + 1);
        } else {
          newReactions.add(CommunityReaction(emoji: emoji, count: 1));
        }
        _posts[idx] = p.copyWith(
          reactions: newReactions,
          myReactionEmoji: emoji,
        );
      }
    });
    final result = await _repo.toggleReaction(feedId: post.id, emoji: emoji);
    if (result.isFailure) {
      _loadFeed(refresh: true);
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

  Future<void> _showPostActions(CommunityPost post) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: BldrColors.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: post.isOwnPost
              ? [
                  ListTile(
                    leading: const Icon(TablerIcons.trash, color: Colors.red),
                    title: const Text('Excluir post'),
                    onTap: () => Navigator.pop(context, 'delete'),
                  ),
                ]
              : [
                  ListTile(
                    leading: const Icon(TablerIcons.flag),
                    title: const Text('Denunciar'),
                    onTap: () => Navigator.pop(context, 'report'),
                  ),
                  ListTile(
                    leading:
                        const Icon(TablerIcons.user_off, color: Colors.red),
                    title: const Text('Bloquear usuário'),
                    onTap: () => Navigator.pop(context, 'block'),
                  ),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir post?'),
        content: const Text(
          'O post, seus comentários e suas reações serão removidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await _repo.deletePost(post.id);
    if (!mounted) return;
    _showActionResult(result, success: 'Post excluído.');
    if (result.isSuccess) {
      setState(() {
        _posts.removeWhere((item) => item.id == post.id);
        _followingPosts.removeWhere((item) => item.id == post.id);
      });
    }
  }

  Future<void> _confirmBlock(CommunityPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bloquear ${post.authorName}?'),
        content: const Text(
          'Vocês deixarão de ver os posts um do outro na comunidade.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await _repo.blockUser(post.userId);
    if (!mounted) return;
    _showActionResult(result, success: 'Usuário bloqueado.');
    if (result.isSuccess) {
      setState(() {
        _posts.removeWhere((item) => item.userId == post.userId);
        _followingPosts.removeWhere((item) => item.userId == post.userId);
      });
    }
  }

  Future<void> _reportPost(CommunityPost post) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: BldrColors.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _ReportReasonTile(label: 'Spam', value: 'spam'),
            _ReportReasonTile(label: 'Assédio', value: 'harassment'),
            _ReportReasonTile(
              label: 'Conteúdo impróprio',
              value: 'inappropriate_content',
            ),
            _ReportReasonTile(
              label: 'Informação falsa',
              value: 'false_information',
            ),
            _ReportReasonTile(label: 'Outro motivo', value: 'other'),
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
    _showActionResult(result, success: 'Denúncia enviada para análise.');
  }

  void _showActionResult(Result<void> result, {required String success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.failureOrNull?.message ?? success)),
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
        body: Column(
          children: [
            // AppBar + tabs fora do scroll — não recriam ao trocar de tab
            SizedBox(height: MediaQuery.of(context).padding.top),
            _buildHeader(),
            _buildTabRow(),
            // New posts indicator — shown when realtime delivers a new post
            // from another user while the Explorar tab is visible.
            if (_hasNewPosts && _activeTab == 0)
              GestureDetector(
                onTap: () => _loadFeed(refresh: true),
                child: Container(
                  width: double.infinity,
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: BldrColors.goldTintChip,
                        border: Border.all(color: BldrColors.goldBorderChip),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Novas publicações',
                        style: TextStyle(
                          color: BldrColors.goldBright,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Body por tab — IndexedStack mantém estado de scroll de cada tab
            Expanded(
              child: IndexedStack(
                index: _activeTab,
                children: [
                  _ExplorarTab(
                    posts: _posts,
                    loading: _loading,
                    loadingMore: _loadingMore,
                    feedError: _feedError,
                    onScroll: _onScroll,
                    onReaction: _toggleReaction,
                    onOpenWorkout: _openWorkoutDetail,
                    onComments: _openComments,
                    onFollow: _toggleFollow,
                    onMore: _showPostActions,
                    onRefresh: () => _loadFeed(refresh: true),
                    onRetry: () => _loadFeed(refresh: true),
                    relativeTime: _relativeTime,
                  ),
                  _SeguindoTab(
                    posts: _followingPosts,
                    loading: _followingLoading,
                    error: _followingError,
                    onRefresh: _loadFollowingFeed,
                    onReaction: _toggleReaction,
                    onOpenWorkout: _openWorkoutDetail,
                    onComments: _openComments,
                    onFollow: _toggleFollow,
                    onMore: _showPostActions,
                    onExplorar: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CommunityProfileSearchScreen(),
                        ),
                      );
                      _loadFollowingFeed();
                    },
                    relativeTime: _relativeTime,
                  ),
                  _SquadsTab(
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BldrSpacing.pageX, 14, BldrSpacing.pageX, 0),
      child: Row(
        children: [
          if (widget.onBack != null)
            GestureDetector(
              onTap: widget.onBack,
              child: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(TablerIcons.chevron_left,
                    color: BldrColors.textPrimary, size: 24),
              ),
            ),
          Expanded(child: Text('Comunidade', style: BldrText.screenTitle)),
          _iconBtn(TablerIcons.lock, onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => _PrivatePostsScreen(
                  repository: _repo,
                  onReaction: _toggleReaction,
                  onOpenWorkout: _openWorkoutDetail,
                  onComments: _openComments,
                  onFollow: _toggleFollow,
                  onMore: _showPostActions,
                  relativeTime: _relativeTime,
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          _iconBtn(TablerIcons.target_arrow, onTap: () async {
            final created = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => const CreateCollectiveChallengeScreen(),
              ),
            );
            if (created == true) _loadFeed(refresh: true);
          }),
          const SizedBox(width: 8),
          _iconBtn(TablerIcons.trophy, onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const RankingScreen()));
          }),
          const SizedBox(width: 8),
          _iconBtn(
            TablerIcons.bell,
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

  Widget _buildTabRow() {
    const tabs = ['Explorar', 'Seguindo', 'Squads'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BldrSpacing.pageX, 10, BldrSpacing.pageX, 0),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = _activeTab == i;
          return GestureDetector(
            onTap: () => setState(() => _activeTab = i),
            child: Container(
              margin: const EdgeInsets.only(right: 24),
              padding: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active ? BldrColors.goldBright : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                tabs[i],
                style: BldrText.body.copyWith(
                  color:
                      active ? BldrColors.goldBright : BldrColors.textTertiary,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _iconBtn(IconData icon, {required VoidCallback onTap, int badge = 0}) {
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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
                child: Icon(icon, size: 17, color: BldrColors.textSecondary)),
            if (badge > 0)
              Positioned(
                right: -5,
                top: -5,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: Text(badge > 99 ? '99+' : '$badge',
                      style: const TextStyle(color: Colors.white, fontSize: 9)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab() {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 72),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostScreen()),
          ).then((_) => _loadFeed(refresh: true));
        },
        backgroundColor: BldrColors.goldSolid,
        child: const Icon(TablerIcons.plus, color: Colors.black),
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    return 'há ${diff.inDays}d';
  }
}

class _PrivatePostsScreen extends StatefulWidget {
  final CommunityFeedRepository repository;
  final Future<void> Function(CommunityPost, String) onReaction;
  final void Function(CommunityPost) onOpenWorkout;
  final void Function(CommunityPost) onComments;
  final Future<void> Function(CommunityPost) onFollow;
  final Future<void> Function(CommunityPost) onMore;
  final String Function(DateTime) relativeTime;

  const _PrivatePostsScreen({
    required this.repository,
    required this.onReaction,
    required this.onOpenWorkout,
    required this.onComments,
    required this.onFollow,
    required this.onMore,
    required this.relativeTime,
  });

  @override
  State<_PrivatePostsScreen> createState() => _PrivatePostsScreenState();
}

class _ReportReasonTile extends StatelessWidget {
  final String label;
  final String value;

  const _ReportReasonTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(TablerIcons.flag),
      title: Text(label),
      onTap: () => Navigator.pop(context, value),
    );
  }
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
                          itemCount: _posts.length,
                          itemBuilder: (_, index) => _FeedCard(
                            post: _posts[index],
                            onReaction: widget.onReaction,
                            onOpenWorkout: widget.onOpenWorkout,
                            onComments: widget.onComments,
                            onFollow: widget.onFollow,
                            onMore: (post) async {
                              await widget.onMore(post);
                              await _load();
                            },
                            relativeTime: widget.relativeTime,
                          ),
                        ),
                      ),
      ),
    );
  }
}

// ── Tab Explorar ─────────────────────────────────────────────────────────────

class _ExplorarTab extends StatelessWidget {
  final List<CommunityPost> posts;
  final bool loading;
  final bool loadingMore;
  final Failure? feedError;
  final void Function(ScrollNotification) onScroll;
  final Future<void> Function(CommunityPost, String) onReaction;
  final void Function(CommunityPost) onOpenWorkout;
  final void Function(CommunityPost) onComments;
  final Future<void> Function(CommunityPost) onFollow;
  final Future<void> Function(CommunityPost) onMore;
  final VoidCallback onRefresh;
  final VoidCallback onRetry;
  final String Function(DateTime) relativeTime;

  const _ExplorarTab({
    required this.posts,
    required this.loading,
    required this.loadingMore,
    required this.onScroll,
    required this.onReaction,
    required this.onOpenWorkout,
    required this.onComments,
    required this.onFollow,
    required this.onMore,
    required this.onRefresh,
    required this.onRetry,
    required this.relativeTime,
    this.feedError,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        onScroll(n);
        return false;
      },
      child: RefreshIndicator(
        color: BldrColors.goldBright,
        backgroundColor: BldrColors.surface,
        onRefresh: () async => onRefresh(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildSearchBar(context)),
            if (loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                      color: BldrColors.goldBright, strokeWidth: 2),
                ),
              )
            else if (feedError != null)
              SliverFillRemaining(child: _buildError(feedError!.message))
            else if (posts.isEmpty)
              SliverFillRemaining(child: _buildEmpty())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _FeedCard(
                    post: posts[i],
                    onReaction: onReaction,
                    onOpenWorkout: onOpenWorkout,
                    onComments: onComments,
                    onFollow: onFollow,
                    onMore: onMore,
                    relativeTime: relativeTime,
                  ),
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
                          color: BldrColors.goldBright, strokeWidth: 2),
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(
                child: SizedBox(height: BldrSpacing.navClearance)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BldrSpacing.pageX, 12, BldrSpacing.pageX, 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CommunityProfileSearchScreen(),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: BldrColors.surface,
            border: Border.all(color: BldrColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(TablerIcons.search,
                  size: 15, color: BldrColors.textTertiary),
              const SizedBox(width: 8),
              Text('Buscar na comunidade',
                  style:
                      BldrText.body.copyWith(color: BldrColors.textTertiary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(TablerIcons.users,
              size: 48, color: BldrColors.textTertiary),
          const SizedBox(height: 16),
          Text('Nenhum post ainda', style: BldrText.sectionTitle),
          const SizedBox(height: 8),
          Text('Seja o primeiro a compartilhar!', style: BldrText.description),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(TablerIcons.wifi_off,
                size: 48, color: BldrColors.textTertiary),
            const SizedBox(height: 16),
            Text('Erro ao carregar o feed', style: BldrText.sectionTitle),
            const SizedBox(height: 8),
            Text(message,
                style: BldrText.description, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                backgroundColor: BldrColors.goldSolid,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(BldrRadius.button),
                ),
              ),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab Seguindo ─────────────────────────────────────────────────────────────

class _SeguindoTab extends StatelessWidget {
  final List<CommunityPost> posts;
  final bool loading;
  final Failure? error;
  final VoidCallback onRefresh;
  final Future<void> Function(CommunityPost, String) onReaction;
  final void Function(CommunityPost) onOpenWorkout;
  final void Function(CommunityPost) onComments;
  final Future<void> Function(CommunityPost) onFollow;
  final Future<void> Function(CommunityPost) onMore;
  final VoidCallback onExplorar;
  final String Function(DateTime) relativeTime;

  const _SeguindoTab({
    required this.posts,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onReaction,
    required this.onOpenWorkout,
    required this.onComments,
    required this.onFollow,
    required this.onMore,
    required this.onExplorar,
    required this.relativeTime,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!.message, style: BldrText.body),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRefresh,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                BldrSpacing.pageX, 12, BldrSpacing.pageX, 16),
            child: _CtaFollowCard(onExplorar: onExplorar),
          ),
        ),
        if (loading)
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                  color: BldrColors.goldBright, strokeWidth: 2),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _FeedCard(
                post: posts[i],
                onReaction: onReaction,
                onOpenWorkout: onOpenWorkout,
                onComments: onComments,
                onFollow: onFollow,
                onMore: onMore,
                relativeTime: relativeTime,
              ),
              childCount: posts.length,
            ),
          ),
        const SliverToBoxAdapter(
            child: SizedBox(height: BldrSpacing.navClearance)),
      ],
    );
  }
}

class _CtaFollowCard extends StatelessWidget {
  final VoidCallback onExplorar;
  const _CtaFollowCard({required this.onExplorar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BldrColors.goldTint,
        border: Border.all(color: BldrColors.goldBorder),
        borderRadius: BorderRadius.circular(BldrRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0x1FE0B830),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(TablerIcons.users,
                size: 20, color: BldrColors.goldBright),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Siga atletas',
                    style: BldrText.cardTitle
                        .copyWith(color: BldrColors.goldBright)),
                const SizedBox(height: 2),
                Text('Veja o feed personalizado de quem você segue',
                    style: BldrText.description),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onExplorar,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: BldrColors.goldSolid,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Buscar',
                  style: BldrText.meta.copyWith(
                      color: Colors.black, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab Squads ────────────────────────────────────────────────────────────────

class _SquadsTab extends StatelessWidget {
  final List<Map<String, dynamic>> squads;
  final bool loading;
  final Failure? error;
  final VoidCallback onRefresh;

  const _SquadsTab({
    required this.squads,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(
            color: BldrColors.goldBright, strokeWidth: 2),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!.message, style: BldrText.body),
            const SizedBox(height: 8),
            TextButton(
                onPressed: onRefresh, child: const Text('Tentar novamente')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: BldrColors.goldBright,
      backgroundColor: BldrColors.surface,
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          BldrSpacing.pageX,
          12,
          BldrSpacing.pageX,
          BldrSpacing.navClearance,
        ),
        children: [
          // ── Meus Squads ──
          Text('MEUS SQUADS', style: BldrText.label),
          const SizedBox(height: 12),
          if (squads.isEmpty) _buildEmptySquads(context),
          ...squads.map((s) => _SquadCard(squad: s)),

          const SizedBox(height: 24),

          // ── Descobrir ──
          Text('DESCOBRIR', style: BldrText.label),
          const SizedBox(height: 12),
          _ActionCard(
            icon: TablerIcons.key,
            title: 'Tenho um código de convite',
            subtitle: 'Entre em um squad com código',
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const JoinSquadSheet(),
            ),
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: TablerIcons.plus,
            title: 'Criar novo squad',
            subtitle: 'Monte seu grupo e convide atletas',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateArenaScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySquads(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: BldrColors.surface,
            border: Border.all(color: BldrColors.border),
            borderRadius: BorderRadius.circular(BldrRadius.card),
          ),
          child: Column(
            children: [
              const Icon(TablerIcons.shield,
                  size: 40, color: BldrColors.textTertiary),
              const SizedBox(height: 12),
              Text('Você não está em nenhum squad',
                  style: BldrText.cardTitle
                      .copyWith(color: BldrColors.textSecondary),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Crie ou entre em um squad para competir com amigos',
                  style: BldrText.description, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CompetitionHubScreen()),
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: BldrColors.goldSolid,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Criar squad',
                      style: BldrText.body.copyWith(
                          color: Colors.black, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SquadCard extends StatelessWidget {
  final Map<String, dynamic> squad;
  const _SquadCard({required this.squad});

  @override
  Widget build(BuildContext context) {
    final name = squad['title'] as String? ?? 'Squad';
    final gameMode = squad['game_mode'] as String? ?? 'alpha';
    final memberCount = squad['member_count'] as int? ?? 0;
    final activeDays = squad['active_days'] as int?;
    final gameModeLabel = switch (gameMode) {
      'survivor' => 'Survivor',
      'roadrunner' => 'Roadrunner',
      'hustle' => 'Hustle',
      _ => 'Alpha',
    };

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArenaDetailsScreen(arenaId: squad['id'] as String),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: BldrColors.goldTint,
          border: Border.all(color: BldrColors.goldBorder),
          borderRadius: BorderRadius.circular(BldrRadius.card),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0x1FE0B830),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(TablerIcons.shield_filled,
                  size: 22, color: BldrColors.goldBright),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: BldrText.cardTitle
                          .copyWith(color: BldrColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(gameModeLabel, style: BldrText.description),
                      const SizedBox(width: 6),
                      const Text('·',
                          style: TextStyle(
                              color: BldrColors.textTertiary, fontSize: 10)),
                      const SizedBox(width: 6),
                      Text('$memberCount membros', style: BldrText.description),
                      if (activeDays != null) ...[
                        const SizedBox(width: 6),
                        const Text('·',
                            style: TextStyle(
                                color: BldrColors.textTertiary, fontSize: 10)),
                        const SizedBox(width: 6),
                        Text('${activeDays}d ativos',
                            style: BldrText.description),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(TablerIcons.chevron_right,
                size: 16, color: BldrColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: BldrColors.surface,
          border: Border.all(color: BldrColors.border),
          borderRadius: BorderRadius.circular(BldrRadius.card),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: BldrColors.goldTint,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 19, color: BldrColors.goldBright),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: BldrText.cardTitle),
                  const SizedBox(height: 2),
                  Text(subtitle, style: BldrText.description),
                ],
              ),
            ),
            const Icon(TablerIcons.chevron_right,
                size: 16, color: BldrColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ── Feed card (compartilhado entre Explorar e Seguindo) ───────────────────────

class _FeedCard extends StatelessWidget {
  final CommunityPost post;
  final Future<void> Function(CommunityPost, String) onReaction;
  final void Function(CommunityPost) onOpenWorkout;
  final void Function(CommunityPost) onComments;
  final Future<void> Function(CommunityPost) onFollow;
  final Future<void> Function(CommunityPost) onMore;
  final String Function(DateTime) relativeTime;

  const _FeedCard({
    required this.post,
    required this.onReaction,
    required this.onOpenWorkout,
    required this.onComments,
    required this.onFollow,
    required this.onMore,
    required this.relativeTime,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BldrSpacing.pageX, 0, BldrSpacing.pageX, 12),
      child: BldrGlassCard(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildBody(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAvatar(),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post.authorName, style: BldrText.cardTitle),
              Row(
                children: [
                  Text(post.displayName,
                      style: BldrText.description
                          .copyWith(color: BldrColors.goldBright)),
                  const SizedBox(width: 6),
                  Text('·', style: BldrText.meta),
                  const SizedBox(width: 6),
                  Text(relativeTime(post.createdAt), style: BldrText.meta),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_eventBadge() case final badge?) badge,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!post.isOwnPost) _followButton(),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onMore(post),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      TablerIcons.dots_vertical,
                      size: 17,
                      color: BldrColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget? _eventBadge() {
    if (post.eventType == CommunityEventType.prBeaten) {
      return _badge('🏆 NOVO PR', const Color(0xFFE0B830),
          const Color(0x47C9A227), const Color(0x47C9A227));
    }
    if (post.eventType == CommunityEventType.streakMilestone) {
      return _badge('🔥 STREAK', const Color(0xFFFF6432),
          const Color(0x14FF6432), const Color(0x40FF6432));
    }
    if (post.eventType == CommunityEventType.wearableActivity) {
      return _badge(
        'Importado do ${_wearableProviderLabel()}',
        BldrColors.textSecondary,
        const Color(0x0AFFFFFF),
        const Color(0x14FFFFFF),
      );
    }
    return null;
  }

  Widget _followButton() => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onFollow(post),
        child: SizedBox(
          height: 44,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: post.isFollowing
                    ? Colors.transparent
                    : BldrColors.goldSolid,
                border: Border.all(
                  color: post.isFollowing
                      ? BldrColors.goldBorder
                      : BldrColors.goldSolid,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                post.isFollowing ? 'Seguindo' : 'Seguir',
                style: BldrText.meta.copyWith(
                  color:
                      post.isFollowing ? BldrColors.goldBright : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildAvatar() {
    final initial =
        (post.authorName.isNotEmpty ? post.authorName[0] : '?').toUpperCase();
    final avatar = post.userAvatarUrl != null && post.userAvatarUrl!.isNotEmpty
        ? ClipOval(
            child: Image.network(
              post.userAvatarUrl!,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initialAvatar(initial),
            ),
          )
        : _initialAvatar(initial);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        if (post.isClubMember)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: BldrColors.goldBright,
                shape: BoxShape.circle,
                border: Border.all(color: BldrColors.bgBase, width: 1.5),
              ),
              child: const Icon(
                Icons.verified,
                color: Color(0xFF0A0A0A),
                size: 10,
              ),
            ),
          ),
      ],
    );
  }

  Widget _initialAvatar(String initial) => Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
            color: BldrColors.goldTint, shape: BoxShape.circle),
        child: Center(
          child: Text(initial,
              style: BldrText.cardTitle
                  .copyWith(color: BldrColors.goldBright, fontSize: 13)),
        ),
      );

  Widget _badge(String text, Color textColor, Color bg, Color border) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: BldrText.metaSm
              .copyWith(color: textColor, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (post.eventType) {
      case CommunityEventType.workoutCompleted:
        return _buildWorkoutBody(context);
      case CommunityEventType.prBeaten:
        return _buildPrBody(context);
      case CommunityEventType.streakMilestone:
        return _buildStreakBody(context);
      case CommunityEventType.activityCompleted:
        return _buildActivityBody();
      case CommunityEventType.wearableActivity:
        return _buildWearableBody();
      default:
        return _buildManualBody(context);
    }
  }

  Widget _buildWorkoutBody(BuildContext context) {
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
            child: Image.network(post.photoUrl!,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
        ],
        const SizedBox(height: 10),
        _buildStats(),
        if (post.muscleGroups.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildMuscleTags(),
        ],
        if (post.typedPayload.prs.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...post.typedPayload.prs.map(
            (pr) => Text(
              '🏆 ${pr.exerciseName} · ${pr.weightKg.toStringAsFixed(1)} kg',
              style:
                  BldrText.description.copyWith(color: BldrColors.goldBright),
            ),
          ),
        ],
        const SizedBox(height: 10),
        _buildViewWorkoutBtn(context),
        const SizedBox(height: 2),
        _buildReactions(),
      ],
    );
  }

  Widget _buildPrBody(BuildContext context) {
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
                      style:
                          BldrText.kpiMd.copyWith(color: BldrColors.goldBright),
                    ),
                    if (post.prReps != null)
                      Text('${post.prReps} reps', style: BldrText.description),
                    if (post.e1rm != null)
                      Text('e1RM: ${post.e1rm!.toStringAsFixed(1)} kg',
                          style: BldrText.meta),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildReactions(),
      ],
    );
  }

  Widget _buildStreakBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${post.streakDays ?? 0}',
              style: BldrText.kpiLg
                  .copyWith(color: const Color(0xFFFF6432), fontSize: 48),
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
        _buildReactions(),
      ],
    );
  }

  Widget _buildManualBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (post.caption != null) Text(post.caption!, style: BldrText.body),
        if (post.photoUrl != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(post.photoUrl!,
                width: double.infinity,
                height: 160,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
        ],
        if (post.payload['workout_id'] != null) ...[
          const SizedBox(height: 10),
          _buildViewWorkoutBtn(context),
        ],
        const SizedBox(height: 10),
        _buildReactions(),
      ],
    );
  }

  Widget _buildActivityBody() {
    final payload = post.typedPayload;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(payload.activityType ?? 'Atividade', style: BldrText.cardTitleLg),
        if (payload.caption != null)
          Text(payload.caption!, style: BldrText.body),
        const SizedBox(height: 10),
        _buildStats(),
        if (payload.distanceKm != null || payload.calories != null)
          Text(
            [
              if (payload.distanceKm != null) '${payload.distanceKm} km',
              if (payload.calories != null) '${payload.calories} kcal',
            ].join(' · '),
            style: BldrText.description,
          ),
        const SizedBox(height: 10),
        _buildReactions(),
      ],
    );
  }

  Widget _buildWearableBody() {
    final payload = post.typedPayload;
    final activityName = payload.wearableActivityType?.trim();
    final duration = payload.wearableDurationSeconds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          activityName == null || activityName.isEmpty
              ? 'Atividade'
              : _formatWearableActivity(activityName),
          style: BldrText.cardTitleLg,
        ),
        if (payload.caption != null) ...[
          const SizedBox(height: 4),
          Text(payload.caption!, style: BldrText.body),
        ],
        if (duration != null ||
            payload.wearableStrain != null ||
            payload.wearableAverageHeartRate != null ||
            payload.wearableCalories != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              if (duration != null) Text('${duration ~/ 60} min'),
              if (payload.wearableStrain != null)
                Text('Strain ${payload.wearableStrain!.toStringAsFixed(1)}'),
              if (payload.wearableAverageHeartRate != null)
                Text('FC média ${payload.wearableAverageHeartRate} bpm'),
              if (payload.wearableCalories != null)
                Text('${payload.wearableCalories} kcal'),
            ]
                .map((text) => DefaultTextStyle.merge(
                      style: BldrText.description,
                      child: text,
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: 10),
        _buildReactions(),
      ],
    );
  }

  String _wearableProviderLabel() {
    final raw = post.typedPayload.wearableProvider?.toLowerCase().trim();
    return switch (raw) {
      'whoop' => 'WHOOP',
      'garmin' => 'Garmin',
      'apple_health' || 'apple_watch' || 'apple' => 'Apple Watch',
      _ => 'wearable',
    };
  }

  String _formatWearableActivity(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  Widget _buildStats() {
    final chips = <(String, String)>[];
    if (post.durationSeconds != null) {
      chips.add(('${(post.durationSeconds! / 60).round()}min', 'DURAÇÃO'));
    }
    if (post.volumeKg != null) {
      chips.add(('${post.volumeKg!.toStringAsFixed(0)}kg', 'VOLUME'));
    }
    if (post.completedSetCount != null) {
      chips.add(('${post.completedSetCount}', 'SÉRIES'));
    }
    if (chips.isEmpty) return const SizedBox.shrink();
    return Row(
      children: chips
          .map((c) => Container(
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

  Widget _buildMuscleTags() {
    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: post.muscleGroups
          .map((m) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x0AFFFFFF),
                  border: Border.all(color: const Color(0x0FFFFFFF)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(m, style: BldrText.meta),
              ))
          .toList(),
    );
  }

  Widget _buildViewWorkoutBtn(BuildContext context) {
    return GestureDetector(
      onTap: () => onOpenWorkout(post),
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
            const Icon(TablerIcons.barbell,
                size: 14, color: BldrColors.textSecondary),
            const SizedBox(width: 6),
            Text('Ver treino →', style: BldrText.body),
          ],
        ),
      ),
    );
  }

  Widget _buildReactions() {
    const emojis = ['🔥', '💪', '⚡', '🏆'];
    return Builder(builder: (context) {
      return Row(
        children: [
          ...emojis.map((emoji) {
            final isActive = post.myReactionEmoji == emoji;
            final rx =
                post.reactions.where((r) => r.emoji == emoji).firstOrNull;
            final count = rx?.count ?? 0;
            return GestureDetector(
              onTap: () => onReaction(post, emoji),
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
            onTap: () => onComments(post),
            child: Row(
              children: [
                const Icon(TablerIcons.message_circle,
                    size: 13, color: BldrColors.textTertiary),
                const SizedBox(width: 4),
                Text('${post.commentCount}', style: BldrText.meta),
              ],
            ),
          ),
        ],
      );
    });
  }
}
