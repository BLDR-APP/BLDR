import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/core/errors/failure.dart';
import 'package:bldr_fitness/design_system/bldr_community_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/domain/repositories/arena_repository.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/arena_details_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/create_arena_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/join_squad_sheet.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_post_card_v2.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_v2_format.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Aba Squads da Comunidade v2 (4:108). "Meu squad" em destaque (o mais
/// recente de `mySquads`) e, se houver mais, a lista "Meus squads" (D4).
class CommunitySquadsTabV2 extends StatefulWidget {
  final List<Map<String, dynamic>> squads;
  final bool loading;
  final Failure? error;
  final Future<void> Function() onRefresh;

  const CommunitySquadsTabV2({
    super.key,
    required this.squads,
    required this.loading,
    required this.error,
    required this.onRefresh,
  });

  @override
  State<CommunitySquadsTabV2> createState() => _CommunitySquadsTabV2State();
}

class _CommunitySquadsTabV2State extends State<CommunitySquadsTabV2> {
  String? _summaryFor;
  SquadHubSummary? _summary;
  List<Map<String, dynamic>> _participants = const [];

  @override
  void didUpdateWidget(CommunitySquadsTabV2 old) {
    super.didUpdateWidget(old);
    _maybeLoadSummary();
  }

  @override
  void initState() {
    super.initState();
    _maybeLoadSummary();
  }

  void _maybeLoadSummary() {
    if (widget.squads.isEmpty) return;
    final id = widget.squads.first['id']?.toString();
    if (id == null || id == _summaryFor) return;
    _summaryFor = id;
    _loadSummary(widget.squads.first);
  }

  Future<void> _loadSummary(Map<String, dynamic> arena) async {
    final repo = getIt<ArenaRepository>();
    final id = arena['id'].toString();
    final orderBy =
        arena['game_mode'] == 'survivor' ? 'lives_count' : 'current_score';
    final results = await Future.wait([
      repo.participantsCombined(id, orderBy: orderBy),
      repo.tribunalFeed(id),
    ]);
    if (!mounted || _summaryFor != id) return;
    final participants = results[0].valueOrNull ?? const [];
    final posts = results[1].valueOrNull ?? const [];
    setState(() {
      _participants = participants;
      _summary = CommunityV2Format.squad(
        arena: arena,
        participants: participants,
        posts: posts,
        myUserId: getIt<GetCurrentUser>()()?.id,
        now: DateTime.now(),
      );
    });
  }

  Future<void> _refresh() async {
    _summaryFor = null;
    await widget.onRefresh();
    _maybeLoadSummary();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.loading && widget.squads.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
            color: BldrCommunityColorsV2.gold, strokeWidth: 2),
      );
    }
    final error = widget.error;
    return RefreshIndicator(
      color: BldrCommunityColorsV2.gold,
      backgroundColor: BldrCommunityColorsV2.surface,
      onRefresh: _refresh,
      child: ListView(
        padding: EdgeInsets.fromLTRB(BldrCommunityV2.pageX, 20,
            BldrCommunityV2.pageX, BldrSpacing.navClearance + 40),
        children: [
          if (error != null)
            _ErrorBlock(message: error.message, onRetry: _refresh)
          else if (widget.squads.isEmpty)
            _EmptySquad(l10n: l10n)
          else ...[
            _FeaturedSquad(
              arena: widget.squads.first,
              summary: _summary,
              participants: _participants,
            ),
            if (widget.squads.length > 1) ...[
              const SizedBox(height: 22),
              Text(l10n.comm_my_squads, style: BldrCommunityTextV2.section),
              const SizedBox(height: 10),
              for (final s in widget.squads.skip(1)) _SquadRow(arena: s),
            ],
            if (_summary?.latest case final latest?) ...[
              const SizedBox(height: 26),
              Text(l10n.comm_activity_section,
                  style: BldrCommunityTextV2.section),
              const SizedBox(height: 10),
              _ActivityItem(
                post: latest,
                squadName: widget.squads.first['title']?.toString() ?? '',
              ),
            ],
          ],
          const SizedBox(height: 24),
          _CreateOrJoinCta(onCreated: _refresh),
        ],
      ),
    );
  }
}

String _modeLabel(AppLocalizations l10n, String? mode) => switch (mode) {
      'survivor' => l10n.comm_mode_survivor,
      'roadrunner' => l10n.comm_mode_roadrunner,
      'hustle' => l10n.comm_mode_hustle,
      _ => l10n.comm_mode_alpha,
    };

void _openArena(BuildContext context, Map<String, dynamic> arena) {
  Navigator.push(
    context,
    MaterialPageRoute(
        builder: (_) => ArenaDetailsScreen(arenaId: arena['id'].toString())),
  );
}

/// Card "Meu squad" (80:853).
class _FeaturedSquad extends StatelessWidget {
  final Map<String, dynamic> arena;
  final SquadHubSummary? summary;
  final List<Map<String, dynamic>> participants;

  const _FeaturedSquad({
    required this.arena,
    required this.summary,
    required this.participants,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final members =
        (arena['member_count'] as num?)?.toInt() ?? participants.length;
    final meta = [
      l10n.comm_squad_meta(
          _modeLabel(l10n, arena['game_mode'] as String?), members),
      if (summary?.week case final w?) l10n.comm_squad_week(w),
    ].join(' · ');
    const maxAvatars = 5;
    final shown = participants.take(maxAvatars).toList();
    final extra = members - shown.length;

    return GestureDetector(
      onTap: () => _openArena(context, arena),
      child: Container(
        padding: const EdgeInsets.fromLTRB(17, 13, 17, 18),
        decoration: BoxDecoration(
          color: BldrCommunityColorsV2.surface,
          borderRadius: BorderRadius.circular(BldrCommunityV2.squadRadius),
          border:
              Border.all(color: BldrCommunityColorsV2.squadBorder, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.comm_my_squad, style: BldrCommunityTextV2.eyebrow),
            const SizedBox(height: 4),
            Text(arena['title']?.toString() ?? 'Squad',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BldrCommunityTextV2.squadName),
            const SizedBox(height: 2),
            Text(meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BldrCommunityTextV2.squadMeta),
            if (shown.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: BldrCommunityV2.avatar,
                child: Stack(
                  children: [
                    for (var i = 0; i < shown.length; i++)
                      Positioned(
                        left: i * 35.0,
                        child: BldrCommunityAvatar(
                          name: shown[i]['name']?.toString() ?? '?',
                          imageUrl: shown[i]['avatar']?.toString(),
                        ),
                      ),
                    if (extra > 0)
                      Positioned(
                        left: shown.length * 35.0,
                        child:
                            BldrCommunityAvatar(name: '+$extra', muted: true),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            BldrCommunityMetricRow(items: [
              (
                value: summary == null ? '—' : '${summary!.trainedToday}',
                label: l10n.comm_squad_trained_today,
              ),
              (
                value: summary?.myRank == null ? '—' : '#${summary!.myRank}',
                label: l10n.comm_squad_ranking,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

/// Linha compacta para os demais squads (D4).
class _SquadRow extends StatelessWidget {
  final Map<String, dynamic> arena;
  const _SquadRow({required this.arena});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final members = (arena['member_count'] as num?)?.toInt() ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _OutlinedTile(
        title: arena['title']?.toString() ?? 'Squad',
        subtitle: l10n.comm_squad_meta(
            _modeLabel(l10n, arena['game_mode'] as String?), members),
        onTap: () => _openArena(context, arena),
      ),
    );
  }
}

/// Card de borda fina com título, subtítulo e chevron (80:878).
class _OutlinedTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OutlinedTile(
      {required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(17, 14, 17, 16),
        decoration: BoxDecoration(
          color: BldrCommunityColorsV2.surface,
          borderRadius: BorderRadius.circular(BldrCommunityV2.squadRadius),
          border: Border.all(
              color: BldrCommunityColorsV2.discoverBorder, width: 0.7),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrCommunityTextV2.discoverTitle),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: BldrCommunityTextV2.discoverSub),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text('›', style: BldrCommunityTextV2.chevron),
          ],
        ),
      ),
    );
  }
}

/// Item de atividade recente (80:883) — último check-in/prova do squad.
class _ActivityItem extends StatelessWidget {
  final Map<String, dynamic> post;
  final String squadName;

  const _ActivityItem({required this.post, required this.squadName});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = post['user_profiles'] as Map?;
    final name = profile?['full_name']?.toString() ?? 'Atleta';
    final created = DateTime.tryParse(post['created_at']?.toString() ?? '');
    final meta = [
      if (created != null)
        communityAgo(l10n, created.toLocal(), DateTime.now()),
      if (squadName.isNotEmpty) squadName,
    ].join(' · ');
    final caption = post['caption']?.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BldrCommunityAvatar(
                name: name,
                imageUrl: profile?['avatar_url']?.toString(),
                size: 34,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BldrCommunityTextV2.activityName),
                    const SizedBox(height: 2),
                    Text(meta,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BldrCommunityTextV2.activityMeta),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            caption != null && caption.trim().isNotEmpty
                ? caption
                : l10n.comm_activity_checkin,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: BldrCommunityTextV2.activityBody,
          ),
        ],
      ),
    );
  }
}

/// CTA "+ CRIAR OU ENTRAR EM UM SQUAD" (80:889) → sheet com os fluxos atuais.
class _CreateOrJoinCta extends StatelessWidget {
  final Future<void> Function() onCreated;
  const _CreateOrJoinCta({required this.onCreated});

  Future<void> _open(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final choice = await BldrV2Sheet.show<String>(
      context,
      title: l10n.comm_squad_sheet_title,
      child: Column(
        children: [
          Builder(
            builder: (ctx) => BldrV2SheetOption(
              icon: TablerIcons.key,
              label: l10n.comm_squad_code,
              subtitle: l10n.comm_squad_code_sub,
              onTap: () => Navigator.pop(ctx, 'code'),
            ),
          ),
          const SizedBox(height: 10),
          Builder(
            builder: (ctx) => BldrV2SheetOption(
              icon: TablerIcons.plus,
              label: l10n.comm_squad_new,
              subtitle: l10n.comm_squad_new_sub,
              onTap: () => Navigator.pop(ctx, 'create'),
            ),
          ),
        ],
      ),
    );
    if (!context.mounted || choice == null) return;
    if (choice == 'code') {
      // Sheet atual com o aviso de cota FREE (D8/D11).
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const JoinSquadSheet(),
      );
    } else {
      await Navigator.push(context,
          MaterialPageRoute(builder: (_) => const CreateArenaScreen()));
    }
    await onCreated();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: () => _open(context),
        child: Container(
          constraints: const BoxConstraints(minHeight: 46),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(BldrCommunityV2.ctaRadius),
            border: Border.all(color: BldrCommunityColorsV2.gold, width: 0.8),
          ),
          child: Text(l10n.comm_squad_create_join,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: BldrCommunityTextV2.cta),
        ),
      ),
    );
  }
}

class _EmptySquad extends StatelessWidget {
  final AppLocalizations l10n;
  const _EmptySquad({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 18, 17, 20),
      decoration: BoxDecoration(
        color: BldrCommunityColorsV2.surface,
        borderRadius: BorderRadius.circular(BldrCommunityV2.squadRadius),
        border:
            Border.all(color: BldrCommunityColorsV2.squadBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.comm_my_squad, style: BldrCommunityTextV2.eyebrow),
          const SizedBox(height: 6),
          Text(l10n.comm_squad_empty_title,
              style: BldrCommunityTextV2.discoverTitle),
          const SizedBox(height: 4),
          Text(l10n.comm_squad_empty_body,
              style: BldrCommunityTextV2.discoverSub),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorBlock({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Text(message,
            textAlign: TextAlign.center, style: BldrCommunityTextV2.body),
        TextButton(
          onPressed: onRetry,
          child: Text(l10n.comm_retry, style: BldrCommunityTextV2.cta),
        ),
      ],
    );
  }
}
