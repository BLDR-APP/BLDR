import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/design_system/bldr_community_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_post.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_comments_panel_v2.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_content_sheets_v2.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_post_card_v2.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_post_tile_v2.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_social_profile_screen.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_v2_format.dart';
import 'package:bldr_fitness/features/community/presentation/workout_detail_sheet.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// O que aconteceu com o post enquanto o detalhe estava aberto.
sealed class CommunityPostDetailResult {
  const CommunityPostDetailResult();
}

class DetailClosed extends CommunityPostDetailResult {
  final CommunityPost post;
  const DetailClosed(this.post);
}

class DetailPostDeleted extends CommunityPostDetailResult {
  const DetailPostDeleted();
}

class DetailAuthorBlocked extends CommunityPostDetailResult {
  const DetailAuthorBlocked();
}

/// Detalhe da publicação (Figma 52:802).
class CommunityPostDetailScreen extends StatefulWidget {
  final CommunityPost post;
  const CommunityPostDetailScreen({super.key, required this.post});

  @override
  State<CommunityPostDetailScreen> createState() =>
      _CommunityPostDetailScreenState();
}

class _CommunityPostDetailScreenState extends State<CommunityPostDetailScreen> {
  late CommunityPost _post = widget.post;

  void _close([CommunityPostDetailResult? result]) =>
      Navigator.pop(context, result ?? DetailClosed(_post));

  Future<void> _react(String emoji) async {
    final before = _post;
    setState(() => _post = CommunityPostActions.applyReaction(before, emoji));
    final ok = await CommunityPostActions.persistReaction(before, emoji);
    if (!ok && mounted) setState(() => _post = before);
  }

  Future<void> _more() async {
    final outcome = await CommunityPostActions.showMenu(context, _post);
    if (!mounted) return;
    switch (outcome) {
      case PostEdited(:final post):
        setState(() => _post = post);
      case PostDeleted():
        _close(const DetailPostDeleted());
      case AuthorBlocked():
        _close(const DetailAuthorBlocked());
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: BldrBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _header(l10n),
                Expanded(
                  child: CommunityCommentsPanelV2(
                    feedId: _post.id,
                    onCountChanged: (count) {
                      if (count != _post.commentCount) {
                        setState(
                            () => _post = _post.copyWith(commentCount: count));
                      }
                    },
                    header: _content(l10n),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(AppLocalizations l10n) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          BldrCommunityBackButton(onTap: _close),
          Expanded(
            child: Text(l10n.comm_post_title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BldrCommunityTextV2.detailTitle),
          ),
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
                  child: Text('•••', style: BldrCommunityTextV2.more),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(AppLocalizations l10n) {
    final post = _post;
    final meta = [
      if (post.username != null) '@${post.username}',
      communityAgo(l10n, post.createdAt, DateTime.now()),
    ].join(' · ');
    final total = post.reactions.fold<int>(0, (s, r) => s + r.count);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Semantics(
          button: true,
          label: l10n.comm_open_profile(post.authorName),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CommunitySocialProfileScreen(userId: post.userId),
              ),
            ),
            child: Row(
              children: [
                BldrCommunityAvatar(
                    name: post.authorName,
                    imageUrl: post.userAvatarUrl,
                    size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(post.authorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: BldrCommunityTextV2.detailAuthor),
                          ),
                          if (post.isClubMember) ...[
                            const SizedBox(width: 6),
                            const Icon(TablerIcons.rosette_discount_check,
                                size: 14,
                                color: BldrCommunityColorsV2.goldBrand),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BldrCommunityTextV2.meta),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (post.caption case final c? when c.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(c, style: BldrCommunityTextV2.body),
        ],
        const SizedBox(height: 14),
        _contentCard(l10n),
        SizedBox(
          height: 48,
          child: Row(
            children: [
              Semantics(
                button: true,
                label: l10n.comm_react_label,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _react(
                      post.myReactionEmoji ?? communityReactionEmojis.first),
                  onLongPress: () async {
                    final emoji =
                        await CommunityPostActions.pickReaction(context, _post);
                    if (emoji != null) await _react(emoji);
                  },
                  child: SizedBox(
                    width: 88,
                    height: 48,
                    child: Row(
                      children: [
                        const SizedBox(width: 2),
                        Icon(TablerIcons.flame,
                            size: 16,
                            color: post.myReactionEmoji != null
                                ? BldrCommunityColorsV2.gold
                                : BldrCommunityColorsV2.icon),
                        const SizedBox(width: 6),
                        Text('$total', style: BldrCommunityTextV2.countOn),
                      ],
                    ),
                  ),
                ),
              ),
              const Icon(TablerIcons.message_circle,
                  size: 16, color: BldrCommunityColorsV2.icon),
              const SizedBox(width: 6),
              Text('${post.commentCount}', style: BldrCommunityTextV2.countOn),
              const Spacer(),
              Semantics(
                button: true,
                label: l10n.comm_share_label,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => CommunityPostActions.share(context, post),
                  child: const SizedBox(
                    width: 44,
                    height: 48,
                    child: Icon(TablerIcons.upload,
                        size: 16, color: BldrCommunityColorsV2.icon),
                  ),
                ),
              ),
            ],
          ),
        ),
        const BldrCommunitySheetDivider(),
      ],
    );
  }

  Widget _contentCard(AppLocalizations l10n) {
    final post = _post;
    if (post.eventType != CommunityEventType.workoutCompleted) {
      return CommunityPostBodyV2(
        post: post,
        onOpenWorkout: (p) => WorkoutDetailSheet.show(context, p),
        onOpenActivity: (p) => CommunityActivitySheetV2.show(context, p),
        onOpenEvolution: (p) => CommunityPrSheetV2.show(context, p),
      );
    }
    final locale = Localizations.localeOf(context).toString();
    final photo = post.photoUrl;
    final prs = post.typedPayload.prs.length;
    final meta = [
      CommunityV2Format.shortDate(post.createdAt.toLocal(), locale),
      if (post.durationSeconds case final d?) CommunityV2Format.duration(d),
    ].join(' · ');
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: BldrCommunityColorsV2.contentBg,
        borderRadius: BorderRadius.circular(BldrCommunityV2.photoRadius),
        border: Border.all(color: BldrCommunityColorsV2.goldBrand, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.comm_type_workout, style: BldrCommunityTextV2.type),
          const SizedBox(height: 6),
          Text(post.workoutName.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: BldrCommunityTextV2.contentTitle),
          const SizedBox(height: 2),
          Text(meta, style: BldrCommunityTextV2.meta),
          const SizedBox(height: 16),
          Row(
            children: [
              _metric(
                  post.volumeKg == null
                      ? '—'
                      : CommunityV2Format.thousands(post.volumeKg!, locale),
                  l10n.comm_label_kg_volume),
              _metric('${post.completedSetCount ?? '—'}', l10n.comm_label_sets),
              _metric('$prs', l10n.comm_label_prs),
            ],
          ),
          if (photo != null && photo.isNotEmpty) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.network(
                photo,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 108,
                  color: BldrCommunityColorsV2.photoPlaceholder,
                ),
              ),
            ),
          ],
          if (post.payload['workout_id'] is String)
            Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => WorkoutDetailSheet.show(context, post),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 2),
                    child: Text(l10n.comm_view_workout_cta,
                        style: BldrCommunityTextV2.type),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _metric(String value, String label) => Expanded(
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  maxLines: 1, style: BldrCommunityTextV2.contentMetric),
            ),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BldrCommunityTextV2.valueLabel),
          ],
        ),
      );
}
