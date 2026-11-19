import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:share_plus/share_plus.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_community_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_post.dart';
import 'package:bldr_fitness/features/community/domain/repositories/community_feed_repository.dart';
import 'package:bldr_fitness/features/community/domain/usecases/edit_community_post.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_content_sheets_v2.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_post_card_v2.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_post_detail_screen.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_social_profile_screen.dart';
import 'package:bldr_fitness/features/community/presentation/workout_detail_sheet.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Resultado do menu "•••" de um post.
sealed class CommunityPostOutcome {
  const CommunityPostOutcome();
}

class PostEdited extends CommunityPostOutcome {
  final CommunityPost post;
  const PostEdited(this.post);
}

class PostDeleted extends CommunityPostOutcome {
  const PostDeleted();
}

class AuthorBlocked extends CommunityPostOutcome {
  const AuthorBlocked();
}

/// Ações de um post usadas pelo feed, pelo detalhe e pelo perfil.
abstract final class CommunityPostActions {
  static CommunityFeedRepository get _repo => getIt<CommunityFeedRepository>();

  /// Uma reação por usuário: o mesmo emoji remove; outro emoji troca.
  static CommunityPost applyReaction(CommunityPost p, String emoji) {
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

  static Future<bool> persistReaction(CommunityPost post, String emoji) async =>
      (await _repo.toggleReaction(feedId: post.id, emoji: emoji)).isSuccess;

  static void _snack(BuildContext context, String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  static Future<bool> toggleFollow(
      BuildContext context, String userId, bool following) async {
    final result = following
        ? await _repo.unfollowUser(userId)
        : await _repo.followUser(userId);
    if (result.isFailure && context.mounted) {
      _snack(context, result.failureOrNull!.message);
    }
    return result.isSuccess;
  }

  static Future<String?> pickReaction(
      BuildContext context, CommunityPost post) {
    return BldrV2Sheet.show<String>(
      context,
      title: AppLocalizations.of(context).comm_react_title,
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
  }

  /// Compartilhar abre direto o share nativo do sistema.
  static Future<void> share(BuildContext context, CommunityPost post) async {
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

  /// Menu "•••" (6:8 — D2).
  static Future<CommunityPostOutcome?> showMenu(
      BuildContext context, CommunityPost post) async {
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
            if (post.isOwnPost) ...[
              BldrCommunitySheetRow(
                icon: TablerIcons.pencil,
                title: l10n.comm_action_edit,
                subtitle: l10n.comm_action_edit_sub,
                onTap: () => Navigator.pop(ctx, 'edit'),
              ),
              BldrCommunitySheetRow(
                icon: TablerIcons.trash,
                title: l10n.comm_action_delete,
                subtitle: l10n.comm_action_delete_sub,
                destructive: true,
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
            ] else ...[
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
    if (!context.mounted || action == null) return null;
    return switch (action) {
      'edit' => _edit(context, post),
      'delete' => _delete(context, post),
      'block' => confirmBlock(context, post.userId, post.authorName),
      _ => _report(context, post),
    };
  }

  static Future<CommunityPostOutcome?> _edit(
      BuildContext context, CommunityPost post) async {
    final l10n = AppLocalizations.of(context);
    final text =
        await CommunityEditPostSheetV2.show(context, post.caption ?? '');
    if (!context.mounted || text == null) return null;
    final result = await getIt<EditCommunityPost>()(post, text);
    if (!context.mounted) return null;
    _snack(context, result.failureOrNull?.message ?? l10n.comm_edited);
    final updated = result.valueOrNull;
    return updated == null ? null : PostEdited(updated);
  }

  static Future<CommunityPostOutcome?> _delete(
      BuildContext context, CommunityPost post) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await BldrV2ConfirmDialog.show(
      context,
      title: l10n.comm_delete_title,
      message: l10n.comm_delete_msg,
      confirmLabel: l10n.comm_delete_confirm,
      cancelLabel: l10n.comm_cancel,
      destructive: true,
    );
    if (!confirmed) return null;
    final result = await _repo.deletePost(post.id);
    if (!context.mounted) return null;
    _snack(context, result.failureOrNull?.message ?? l10n.comm_deleted);
    return result.isSuccess ? const PostDeleted() : null;
  }

  static Future<CommunityPostOutcome?> confirmBlock(
      BuildContext context, String userId, String name) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await BldrV2ConfirmDialog.show(
      context,
      title: l10n.comm_block_title(name),
      message: l10n.comm_block_msg,
      confirmLabel: l10n.comm_block_confirm,
      cancelLabel: l10n.comm_cancel,
      destructive: true,
    );
    if (!confirmed) return null;
    final result = await _repo.blockUser(userId);
    if (!context.mounted) return null;
    _snack(context, result.failureOrNull?.message ?? l10n.comm_blocked);
    return result.isSuccess ? const AuthorBlocked() : null;
  }

  static Future<CommunityPostOutcome?> _report(
      BuildContext context, CommunityPost post) async {
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
    if (!context.mounted || reason == null) return null;
    final result = await _repo.reportUser(
      userId: post.userId,
      feedId: post.id,
      reason: reason,
    );
    if (context.mounted) {
      _snack(context, result.failureOrNull?.message ?? l10n.comm_reported);
    }
    return null;
  }
}

/// Card de post já ligado às ações. Quem usa só reflete as mudanças na lista.
class CommunityPostTileV2 extends StatelessWidget {
  final CommunityPost post;
  final ValueChanged<CommunityPost> onUpdated;
  final ValueChanged<CommunityPost> onDeleted;
  final ValueChanged<String> onAuthorBlocked;
  final void Function(String userId, bool following) onFollowChanged;

  /// Falso dentro do próprio perfil, para não abrir o perfil de novo.
  final bool opensProfile;

  const CommunityPostTileV2({
    super.key,
    required this.post,
    required this.onUpdated,
    required this.onDeleted,
    required this.onAuthorBlocked,
    required this.onFollowChanged,
    this.opensProfile = true,
  });

  Future<void> _react(CommunityPost p, String emoji) async {
    onUpdated(CommunityPostActions.applyReaction(p, emoji));
    final ok = await CommunityPostActions.persistReaction(p, emoji);
    if (!ok) onUpdated(p);
  }

  Future<void> _openDetail(BuildContext context) async {
    final result = await Navigator.push<CommunityPostDetailResult>(
      context,
      MaterialPageRoute(builder: (_) => CommunityPostDetailScreen(post: post)),
    );
    switch (result) {
      case DetailClosed(:final post):
        onUpdated(post);
      case DetailPostDeleted():
        onDeleted(post);
      case DetailAuthorBlocked():
        onAuthorBlocked(post.userId);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CommunityPostCardV2(
      post: post,
      now: DateTime.now(),
      onReaction: _react,
      onLongReact: (p) async {
        final emoji = await CommunityPostActions.pickReaction(context, p);
        if (emoji != null) await _react(p, emoji);
      },
      onOpenWorkout: (p) {
        if (p.payload['workout_id'] is String) {
          WorkoutDetailSheet.show(context, p);
        }
      },
      onOpenActivity: (p) => CommunityActivitySheetV2.show(context, p),
      onOpenEvolution: (p) => CommunityPrSheetV2.show(context, p),
      onComments: (_) => _openDetail(context),
      onOpenDetail: (_) => _openDetail(context),
      onOpenProfile: opensProfile
          ? (p) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CommunitySocialProfileScreen(userId: p.userId),
                ),
              )
          : null,
      onFollow: (p) async {
        final ok = await CommunityPostActions.toggleFollow(
            context, p.userId, p.isFollowing);
        if (ok) onFollowChanged(p.userId, !p.isFollowing);
      },
      onMore: (p) async {
        final outcome = await CommunityPostActions.showMenu(context, p);
        switch (outcome) {
          case PostEdited(:final post):
            onUpdated(post);
          case PostDeleted():
            onDeleted(p);
          case AuthorBlocked():
            onAuthorBlocked(p.userId);
          case null:
            break;
        }
      },
      onShare: (p) => CommunityPostActions.share(context, p),
    );
  }
}
