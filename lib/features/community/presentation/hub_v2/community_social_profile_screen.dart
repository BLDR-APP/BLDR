import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_community_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_post.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_social_profile.dart';
import 'package:bldr_fitness/features/community/domain/repositories/community_feed_repository.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_post_tile_v2.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_v2_format.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Perfil social (Figma 56:855). Nível, modalidades e duelo ficam ocultos.
class CommunitySocialProfileScreen extends StatefulWidget {
  final String userId;
  const CommunitySocialProfileScreen({super.key, required this.userId});

  @override
  State<CommunitySocialProfileScreen> createState() =>
      _CommunitySocialProfileScreenState();
}

class _CommunitySocialProfileScreenState
    extends State<CommunitySocialProfileScreen> {
  final _repo = getIt<CommunityFeedRepository>();

  bool _loading = true;
  bool _failed = false;
  CommunitySocialProfile? _profile;
  CommunityFollowCounts _counts = const CommunityFollowCounts();
  List<CommunityPost> _posts = [];
  CommunityProfileStats? _stats;
  int? _workouts;
  int _rank = 0;

  bool get _isMe => getIt<GetCurrentUser>()()?.id == widget.userId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final id = widget.userId;
    final profile = await _repo.fetchSocialProfile(id);
    final counts = await _repo.fetchFollowCounts(id);
    final posts = await _repo.fetchUserPosts(id);
    final club = await getIt<GetPublicClubProfile>()(id);
    final stats = await _repo.fetchProfileStats(id);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failed = profile.isFailure;
      _profile = profile.valueOrNull;
      _counts = counts.valueOrNull ?? const CommunityFollowCounts();
      _posts = posts.valueOrNull ?? [];
      _workouts = club.valueOrNull?.totalWorkouts;
      _rank = club.valueOrNull?.rankPosition ?? 0;
      _stats = stats.valueOrNull;
    });
  }

  Future<void> _toggleFollow() async {
    final profile = _profile;
    if (profile == null) return;
    final ok = await CommunityPostActions.toggleFollow(
        context, profile.id, profile.isFollowing);
    if (ok && mounted) _setFollowing(!profile.isFollowing);
  }

  void _setFollowing(bool following) {
    final profile = _profile;
    if (profile == null || profile.isFollowing == following) return;
    setState(() {
      _profile = profile.copyWith(isFollowing: following);
      _counts = _counts.withFollower(added: following);
      _posts = [for (final p in _posts) p.copyWith(isFollowing: following)];
    });
  }

  Future<void> _more() async {
    final profile = _profile;
    if (profile == null) return;
    final l10n = AppLocalizations.of(context);
    final block = await BldrV2Sheet.show<bool>(
      context,
      title: l10n.comm_profile_actions,
      child: Builder(
        builder: (ctx) => BldrCommunitySheetRow(
          icon: TablerIcons.ban,
          title: l10n.comm_action_block,
          subtitle: l10n.comm_action_block_sub,
          onTap: () => Navigator.pop(ctx, true),
        ),
      ),
    );
    if (block != true || !mounted) return;
    final outcome = await CommunityPostActions.confirmBlock(
        context, profile.id, profile.displayName);
    if (outcome != null && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = _profile;
    return BldrBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: Row(
                  children: [
                    BldrCommunityBackButton(
                        onTap: () => Navigator.maybePop(context)),
                    Expanded(
                      child: Text(
                        profile?.username == null
                            ? profile?.displayName ?? ''
                            : '@${profile!.username}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BldrCommunityTextV2.profileHandle,
                      ),
                    ),
                    if (!_isMe && profile != null)
                      Semantics(
                        button: true,
                        label: l10n.comm_more_label,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _more,
                          child: SizedBox(
                            width: 60,
                            height: 44,
                            child: Center(
                              child:
                                  Text('•••', style: BldrCommunityTextV2.more),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(child: _body(l10n, profile)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n, CommunitySocialProfile? profile) {
    if (_loading && profile == null) {
      return const Center(
        child: CircularProgressIndicator(
            color: BldrCommunityColorsV2.gold, strokeWidth: 2),
      );
    }
    if (_failed || profile == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.comm_profile_error, style: BldrCommunityTextV2.sheetSub),
            TextButton(
              onPressed: _load,
              child: Text(l10n.comm_retry, style: BldrCommunityTextV2.cta),
            ),
          ],
        ),
      );
    }
    final bio = profile.bio?.trim();
    final city = profile.city?.trim();
    final stats = _stats;
    final achievements = stats?.achievements ?? const <String>[];
    const pad = EdgeInsets.symmetric(horizontal: BldrCommunityV2.pageX);
    return RefreshIndicator(
      color: BldrCommunityColorsV2.gold,
      backgroundColor: BldrCommunityColorsV2.surface,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 120),
        children: [
          Padding(
            padding: pad,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    BldrCommunityAvatar(
                      name: profile.displayName,
                      imageUrl: profile.avatarUrl,
                      size: 72,
                      initialsStyle: BldrCommunityTextV2.profileInitials,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(profile.displayName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: BldrCommunityTextV2.profileName),
                              ),
                              if (profile.isClubMember) ...[
                                const SizedBox(width: 6),
                                const Icon(TablerIcons.rosette_discount_check,
                                    size: 14,
                                    color: BldrCommunityColorsV2.goldBrand),
                              ],
                            ],
                          ),
                          if (profile.username != null)
                            Text('@${profile.username}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: BldrCommunityTextV2.meta),
                        ],
                      ),
                    ),
                    if (!_isMe) ...[
                      const SizedBox(width: 8),
                      BldrFollowPill(
                        label: profile.isFollowing
                            ? l10n.comm_following_btn
                            : l10n.comm_follow,
                        active: profile.isFollowing,
                        onTap: _toggleFollow,
                      ),
                    ],
                  ],
                ),
                if (_rank > 0) ...[
                  const SizedBox(height: 8),
                  Text(l10n.comm_rank_status(_rank),
                      style: BldrCommunityTextV2.type),
                ],
                if (bio != null && bio.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(bio, style: BldrCommunityTextV2.body),
                ],
                if (city != null && city.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(city, style: BldrCommunityTextV2.meta),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 22,
                  runSpacing: 4,
                  children: [
                    Text(l10n.comm_followers(_counts.followers),
                        style: BldrCommunityTextV2.profileFollowers),
                    Text(l10n.comm_following_count(_counts.following),
                        style: BldrCommunityTextV2.profileFollowing),
                  ],
                ),
                if (_workouts != null || stats != null) ...[
                  const SizedBox(height: 22),
                  Text(l10n.comm_section_performance,
                      style: BldrCommunityTextV2.section),
                  const SizedBox(height: 8),
                  _PerformanceCard(workouts: _workouts, stats: stats),
                ],
                if (achievements.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Text(l10n.comm_section_achievements,
                      style: BldrCommunityTextV2.section),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: i < achievements.length
                              ? _AchievementCard(name: achievements[i])
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                Text(l10n.comm_section_posts,
                    style: BldrCommunityTextV2.section),
                const SizedBox(height: 8),
                const BldrCommunitySheetDivider(),
                const SizedBox(height: 18),
              ],
            ),
          ),
          if (_posts.isEmpty)
            Padding(
              padding: pad,
              child: Text(l10n.comm_profile_no_posts,
                  style: BldrCommunityTextV2.sheetSub),
            ),
          for (final post in _posts)
            CommunityPostTileV2(
              key: ValueKey(post.id),
              post: post,
              opensProfile: false,
              onUpdated: (p) => setState(() {
                _posts = [
                  for (final item in _posts) item.id == p.id ? p : item
                ];
              }),
              onDeleted: (p) => setState(() {
                _posts = _posts.where((item) => item.id != p.id).toList();
              }),
              onAuthorBlocked: (_) => Navigator.maybePop(context),
              onFollowChanged: (_, following) => _setFollowing(following),
            ),
        ],
      ),
    );
  }
}

/// Card de performance (76:853): números e melhores marcas.
class _PerformanceCard extends StatelessWidget {
  final int? workouts;
  final CommunityProfileStats? stats;

  const _PerformanceCard({required this.workouts, required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final prs = stats?.bestPrs ?? const <CommunityProfilePr>[];
    final numbers = <(String, String)>[
      if (workouts != null) ('$workouts', l10n.comm_label_workouts),
      if (stats != null)
        ('${stats!.activeWeeks}', l10n.comm_label_active_weeks),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BldrCommunityColorsV2.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BldrCommunityColorsV2.goldBrand, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                for (var i = 0; i < numbers.length; i++) ...[
                  if (i > 0)
                    Container(
                        width: 1, color: BldrCommunityColorsV2.metricDivider),
                  Expanded(
                    child: Column(
                      children: [
                        Text(numbers[i].$1,
                            maxLines: 1, style: BldrCommunityTextV2.perfValue),
                        Text(numbers[i].$2,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: BldrCommunityTextV2.valueLabel),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (prs.isNotEmpty) ...[
            const SizedBox(height: 12),
            const BldrCommunitySheetDivider(),
            const SizedBox(height: 12),
            Text(l10n.comm_section_best_prs, style: BldrCommunityTextV2.type),
            const SizedBox(height: 4),
            for (final pr in prs)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(pr.exercise,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BldrCommunityTextV2.detailLabel),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${CommunityV2Format.kg(pr.weightKg, locale)} × ${pr.reps}',
                      maxLines: 1,
                      style: BldrCommunityTextV2.detailValue,
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final String name;
  const _AchievementCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: BldrCommunityColorsV2.goldBrand, width: 0.8),
      ),
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: BldrCommunityColorsV2.gold, width: 0.8),
            ),
            child: const Icon(TablerIcons.star_filled,
                size: 14, color: BldrCommunityColorsV2.gold),
          ),
          const SizedBox(height: 8),
          Text(name,
              maxLines: 3,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: BldrCommunityTextV2.achievement),
        ],
      ),
    );
  }
}
