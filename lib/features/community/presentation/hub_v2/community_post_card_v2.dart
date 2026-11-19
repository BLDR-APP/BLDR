import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/design_system/bldr_community_v2_components.dart';
import 'package:bldr_fitness/features/community/domain/entities/community_post.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_v2_format.dart';
import 'package:bldr_fitness/features/integrations/presentation/widgets/bldr_whoop_card.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Emojis de reação existentes (a reação principal é a primeira).
const communityReactionEmojis = ['🔥', '💪', '⚡', '🏆'];

/// Tempo relativo localizado ("agora", "18 min", "1 h").
String communityAgo(AppLocalizations l10n, DateTime created, DateTime now) {
  final a = CommunityV2Format.ago(created, now);
  return switch (a.unit) {
    CommunityAgoUnit.now => l10n.comm_time_now,
    CommunityAgoUnit.minutes => l10n.comm_time_min(a.value),
    CommunityAgoUnit.hours => l10n.comm_time_hour(a.value),
    CommunityAgoUnit.days => l10n.comm_time_day(a.value),
  };
}

/// Card de post da Comunidade v2 (4:2 — 9:2 treino, 12:2 foto, 12:24
/// atividade importada). Sem fundo: só a divisória antes das ações.
class CommunityPostCardV2 extends StatelessWidget {
  final CommunityPost post;
  final DateTime now;

  /// Alterna a reação: (post, emoji).
  final Future<void> Function(CommunityPost, String) onReaction;
  final void Function(CommunityPost) onLongReact;
  final void Function(CommunityPost) onOpenWorkout;
  final void Function(CommunityPost) onOpenActivity;
  final void Function(CommunityPost) onOpenEvolution;
  final void Function(CommunityPost) onComments;
  final Future<void> Function(CommunityPost) onFollow;
  final Future<void> Function(CommunityPost) onMore;
  final void Function(CommunityPost) onShare;
  final void Function(CommunityPost) onOpenDetail;
  final void Function(CommunityPost)? onOpenProfile;

  const CommunityPostCardV2({
    super.key,
    required this.post,
    required this.now,
    required this.onReaction,
    required this.onLongReact,
    required this.onOpenWorkout,
    required this.onOpenActivity,
    required this.onOpenEvolution,
    required this.onComments,
    required this.onFollow,
    required this.onMore,
    required this.onShare,
    required this.onOpenDetail,
    this.onOpenProfile,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final body = _body(l10n, locale);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          BldrCommunityV2.pageX, 0, BldrCommunityV2.pageX, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(l10n),
          if (post.caption case final c? when c.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onOpenDetail(post),
              child: Text(c, style: BldrCommunityTextV2.body),
            ),
          ],
          if (post.photoUrl case final url? when url.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => onOpenDetail(post),
              child: _photo(url),
            ),
          ],
          if (body != null) ...[
            const SizedBox(height: 8),
            Padding(padding: const EdgeInsets.only(left: 4), child: body),
          ],
          const SizedBox(height: 6),
          Container(height: 1, color: BldrCommunityColorsV2.divider),
          _actions(l10n),
        ],
      ),
    );
  }

  Widget _header(AppLocalizations l10n) {
    final handle = post.username != null ? '@${post.username}' : null;
    final meta = [
      if (handle != null) handle,
      communityAgo(l10n, post.createdAt, now),
    ].join('  ·  ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onOpenProfile == null ? null : () => onOpenProfile!(post),
          child: BldrCommunityAvatar(
              name: post.authorName, imageUrl: post.userAvatarUrl),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onOpenProfile == null ? null : () => onOpenProfile!(post),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(post.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BldrCommunityTextV2.name),
                    ),
                    if (post.isClubMember) ...[
                      const SizedBox(width: 4),
                      const Icon(TablerIcons.rosette_discount_check,
                          size: 14, color: BldrCommunityColorsV2.goldBrand),
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
        ),
        if (!post.isOwnPost) ...[
          const SizedBox(width: 8),
          BldrFollowPill(
            label:
                post.isFollowing ? l10n.comm_following_btn : l10n.comm_follow,
            active: post.isFollowing,
            onTap: () => onFollow(post),
          ),
        ],
        Semantics(
          button: true,
          label: l10n.comm_more_label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onMore(post),
            child: SizedBox(
              width: 40,
              height: 44,
              child: Align(
                alignment: const Alignment(0.6, -0.3),
                child: Text('•••', style: BldrCommunityTextV2.more),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _photo(String url) {
    return Container(
      height: BldrCommunityV2.photoHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BldrCommunityV2.photoRadius),
        border: Border.all(color: BldrCommunityColorsV2.goldBrand, width: 0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BldrCommunityV2.photoRadius),
        child: Image.network(
          url,
          width: double.infinity,
          height: BldrCommunityV2.photoHeight,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const ColoredBox(color: BldrCommunityColorsV2.surface),
        ),
      ),
    );
  }

  Widget? _body(AppLocalizations l10n, String locale) {
    switch (post.eventType) {
      case CommunityEventType.workoutCompleted:
        return _workout(l10n, locale);
      case CommunityEventType.prBeaten:
        return _pr(l10n, locale);
      case CommunityEventType.streakMilestone:
        return _typed(
          type: l10n.comm_type_streak,
          title: l10n.comm_streak_title(post.streakDays ?? 0),
        );
      case CommunityEventType.activityCompleted:
        return _activity(l10n, locale);
      case CommunityEventType.wearableActivity:
        return _wearable(l10n, locale);
      default:
        return post.payload['workout_id'] != null
            ? _typed(
                type: l10n.comm_type_workout,
                title: post.workoutName,
                link: l10n.comm_view_workout,
                onLink: () => onOpenWorkout(post))
            : null;
    }
  }

  Widget _workout(AppLocalizations l10n, String locale) {
    final p = post.typedPayload;
    final title = [
      post.workoutName.toUpperCase(),
      if (post.durationSeconds case final d?) CommunityV2Format.duration(d),
    ].join(' · ');
    final metrics = [
      if (post.volumeKg case final v? when v > 0)
        l10n.comm_metric_volume(CommunityV2Format.thousands(v, locale)),
      if (post.completedSetCount case final s?) l10n.comm_metric_sets(s),
      if (p.prs.isNotEmpty) l10n.comm_metric_prs(p.prs.length),
    ].join('   ·   ');
    return _typed(
      type: l10n.comm_type_workout,
      title: title,
      metrics: metrics.isEmpty ? null : metrics,
      link: post.payload['workout_id'] != null ? l10n.comm_view_workout : null,
      onLink: () => onOpenWorkout(post),
    );
  }

  Widget _pr(AppLocalizations l10n, String locale) {
    String kg(double v) =>
        '${CommunityV2Format.decimal(v, locale, digits: v % 1 == 0 ? 0 : 1)} kg';
    return _valued(
      type: l10n.comm_type_pr,
      title: post.exerciseName ?? l10n.comm_type_pr,
      link: post.exerciseName == null ? null : l10n.comm_view_evolution,
      onLink: () => onOpenEvolution(post),
      values: [
        if (post.prWeightKg case final w?) (kg(w), l10n.comm_label_load),
        if (post.prReps case final r?) ('$r', l10n.comm_label_reps),
        if (post.e1rm case final e?) (kg(e), l10n.comm_label_e1rm),
      ],
    );
  }

  Widget _activity(AppLocalizations l10n, String locale) {
    final p = post.typedPayload;
    final d = p.durationSeconds ?? post.durationSeconds;
    return _valued(
      type: l10n.comm_type_activity,
      title: p.activityType ?? l10n.comm_activity_default,
      link: l10n.comm_view_activity,
      onLink: () => onOpenActivity(post),
      values: [
        if (p.distanceKm case final km?)
          (
            '${CommunityV2Format.decimal(km, locale)} km',
            l10n.comm_label_distance
          ),
        if (d != null) (CommunityV2Format.clock(d), l10n.comm_label_duration),
      ],
      detail: [
        if (CommunityV2Format.pace(d, p.distanceKm) case final pace?)
          '$pace/km',
        if (p.calories case final c?) '$c kcal',
      ].join('  ·  '),
    );
  }

  Widget _wearable(AppLocalizations l10n, String locale) {
    final p = post.typedPayload;
    final name = p.wearableActivityType?.trim();
    final d = p.wearableDurationSeconds;
    final km = p.wearableDistanceKm;
    return _valued(
      type: l10n.comm_type_imported,
      source: CommunityV2Format.providerLabel(p.wearableProvider),
      title: name == null || name.isEmpty
          ? l10n.comm_activity_default
          : CommunityV2Format.activityName(name),
      link: l10n.comm_view_activity,
      onLink: () => onOpenActivity(post),
      whoop: p.wearableProvider?.toLowerCase().trim() == 'whoop',
      values: [
        if (km != null)
          (
            '${CommunityV2Format.decimal(km, locale)} km',
            l10n.comm_label_distance
          ),
        if (d != null) (CommunityV2Format.clock(d), l10n.comm_label_duration),
        if (p.wearableAverageHeartRate case final hr?)
          ('$hr bpm', l10n.comm_label_hr),
        if (km == null && p.wearableStrain != null)
          (
            CommunityV2Format.decimal(p.wearableStrain!, locale, digits: 1),
            l10n.comm_label_strain
          ),
      ].take(3).toList(),
      detail: [
        if (CommunityV2Format.pace(d, km) case final pace?) '$pace/km',
        if (p.wearableCalories case final c?) '$c kcal',
      ].join('  ·  '),
    );
  }

  /// Bloco tipado com métricas em linha (9:11–9:14).
  Widget _typed({
    required String type,
    required String title,
    String? metrics,
    String? link,
    VoidCallback? onLink,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(type, maxLines: 1, style: BldrCommunityTextV2.type),
        const SizedBox(height: 4),
        Text(title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: BldrCommunityTextV2.postTitle),
        if (metrics != null || link != null) ...[
          const SizedBox(height: 2),
          _metricLine(metrics ?? '', link, onLink),
        ],
      ],
    );
  }

  /// Bloco com até 3 valores grandes (12:32–12:42).
  Widget _valued({
    required String type,
    required String title,
    required List<(String, String)> values,
    String? source,
    String? detail,
    String? link,
    VoidCallback? onLink,
    bool whoop = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(type,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BldrCommunityTextV2.type),
            ),
            if (source != null)
              Text(source, maxLines: 1, style: BldrCommunityTextV2.source),
          ],
        ),
        const SizedBox(height: 4),
        Text(title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: BldrCommunityTextV2.postTitle),
        if (values.isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              for (final v in values)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(v.$1,
                              maxLines: 1, style: BldrCommunityTextV2.value),
                        ),
                      ),
                      Text(v.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BldrCommunityTextV2.valueLabel),
                    ],
                  ),
                ),
              for (var i = values.length; i < 3; i++)
                const Expanded(child: SizedBox()),
            ],
          ),
        ],
        if ((detail != null && detail.isNotEmpty) || link != null) ...[
          const SizedBox(height: 6),
          _metricLine(detail ?? '', link, onLink),
        ],
        if (whoop) ...[
          const SizedBox(height: 6),
          const BldrWhoopAttribution(),
        ],
      ],
    );
  }

  Widget _metricLine(String text, String? link, VoidCallback? onLink) {
    return Row(
      children: [
        Expanded(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BldrCommunityTextV2.metrics),
        ),
        if (link != null)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onLink,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 6, bottom: 6),
              child:
                  Text(link, maxLines: 1, style: BldrCommunityTextV2.metrics),
            ),
          ),
      ],
    );
  }

  Widget _actions(AppLocalizations l10n) {
    final total = post.reactions.fold<int>(0, (s, r) => s + r.count);
    final reacted = post.myReactionEmoji != null;
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Semantics(
            button: true,
            label: l10n.comm_react_label,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onReaction(
                  post, post.myReactionEmoji ?? communityReactionEmojis.first),
              onLongPress: () => onLongReact(post),
              child: SizedBox(
                width: 90,
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    reacted && post.myReactionEmoji != '🔥'
                        ? Text(post.myReactionEmoji!,
                            style: BldrCommunityTextV2.count)
                        : Icon(TablerIcons.flame,
                            size: 15,
                            color: reacted
                                ? BldrCommunityColorsV2.gold
                                : BldrCommunityColorsV2.icon),
                    const SizedBox(width: 5),
                    Text('$total',
                        style: reacted
                            ? BldrCommunityTextV2.countOn
                            : BldrCommunityTextV2.count),
                  ],
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: l10n.comm_comments_label,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onComments(post),
              child: Row(
                children: [
                  const Icon(TablerIcons.message_circle,
                      size: 15, color: BldrCommunityColorsV2.icon),
                  const SizedBox(width: 5),
                  Text('${post.commentCount}',
                      style: BldrCommunityTextV2.count),
                  const SizedBox(width: 24),
                ],
              ),
            ),
          ),
          const Spacer(),
          Semantics(
            button: true,
            label: l10n.comm_share_label,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onShare(post),
              child: const SizedBox(
                width: 44,
                height: 40,
                child: Align(
                  alignment: Alignment(0.7, 0),
                  child: Icon(TablerIcons.upload,
                      size: 16, color: BldrCommunityColorsV2.icon),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Conteúdo tipado do post, sem cabeçalho e ações (detalhe de PR e atividade).
class CommunityPostBodyV2 extends StatelessWidget {
  final CommunityPost post;
  final void Function(CommunityPost) onOpenWorkout;
  final void Function(CommunityPost) onOpenActivity;
  final void Function(CommunityPost) onOpenEvolution;

  const CommunityPostBodyV2({
    super.key,
    required this.post,
    required this.onOpenWorkout,
    required this.onOpenActivity,
    required this.onOpenEvolution,
  });

  @override
  Widget build(BuildContext context) {
    final card = CommunityPostCardV2(
      post: post,
      now: DateTime.now(),
      onReaction: (_, __) async {},
      onLongReact: (_) {},
      onOpenWorkout: onOpenWorkout,
      onOpenActivity: onOpenActivity,
      onOpenEvolution: onOpenEvolution,
      onComments: (_) {},
      onFollow: (_) async {},
      onMore: (_) async {},
      onShare: (_) {},
      onOpenDetail: (_) {},
    );
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final body = card._body(l10n, locale);
    final photo = post.photoUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (photo != null && photo.isNotEmpty) card._photo(photo),
        if (photo != null && photo.isNotEmpty && body != null)
          const SizedBox(height: 12),
        if (body != null) body,
      ],
    );
  }
}
