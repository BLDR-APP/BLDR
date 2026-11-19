import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_challenge_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_community_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/club/domain/entities/challenge_hub_rules.dart';
import 'package:bldr_fitness/features/club/domain/entities/challenges.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/challenges_v2/challenge_detail_sheet_v2.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/challenges_v2/challenge_v2_labels.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/collective_challenge_detail_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/create_collective_challenge_screen.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Hub de Desafios (121:893, 141:941, 141:990).
class ChallengesHubScreen extends StatefulWidget {
  const ChallengesHubScreen({super.key});

  @override
  State<ChallengesHubScreen> createState() => _ChallengesHubScreenState();
}

class _ChallengesHubScreenState extends State<ChallengesHubScreen> {
  int _tab = 0;
  bool _loading = true;
  bool _failed = false;
  List<CollectiveChallenge> _challenges = const [];
  List<PastChallengeEntry> _past = const [];
  Map<String, ChallengeStanding> _standings = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      getIt<GetCollectiveChallenges>()(limit: 50),
      getIt<GetPastChallenges>()(limit: 20),
    ]);
    final active = results[0].valueOrNull as List<CollectiveChallenge>?;
    final past = results[1].valueOrNull as List<PastChallengeEntry>?;
    final ids = [
      ...?active?.where((c) => c.joined).map((c) => c.id),
      ...?past?.map((e) => e.challenge.id),
    ];
    final standings = await getIt<GetChallengeStandings>()(ids);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failed = active == null;
      _challenges = active ?? const [];
      _past = past ?? const [];
      _standings = standings.valueOrNull ?? const {};
    });
  }

  Future<void> _create() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => const CreateCollectiveChallengeScreen()),
    );
    if (created == true) _load();
  }

  Future<void> _open(CollectiveChallenge c) async {
    final changed = await ChallengeDetailSheetV2.show(context, c);
    if (changed) _load();
  }

  Future<void> _openPast(CollectiveChallenge c) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CollectiveChallengeDetailScreen(challengeId: c.id),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BldrBackground(
      v2: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(l10n),
              if (_tab != 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      BldrCommunityV2.pageX, 4, BldrCommunityV2.pageX, 0),
                  child: Text(l10n.chal_subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: BldrChallengeTextV2.subtitle),
                ),
              const SizedBox(height: 12),
              _tabs(l10n),
              Expanded(child: _body(l10n)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(AppLocalizations l10n) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, BldrCommunityV2.pageX, 0),
        child: Row(
          children: [
            BldrCommunityBackButton(onTap: () => Navigator.maybePop(context)),
            Expanded(
              child: Text(l10n.chal_title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BldrChallengeTextV2.heading),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _create,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 74, minHeight: 32),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: BldrCommunityColorsV2.goldBrand, width: 1.2),
                  ),
                  child: Text(l10n.chal_create,
                      maxLines: 1, style: BldrChallengeTextV2.create),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _tabs(AppLocalizations l10n) {
    final labels = [
      l10n.chal_tab_active,
      l10n.chal_tab_discover,
      l10n.chal_tab_done,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BldrCommunityV2.pageX),
      child: Align(
        alignment: Alignment.centerLeft,
        // Reduz as três abas juntas, mantendo o mesmo tamanho entre elas.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                if (i > 0) const SizedBox(width: 52),
                Semantics(
                  button: true,
                  selected: _tab == i,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _tab = i),
                    child: IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(labels[i],
                                maxLines: 1,
                                style: _tab == i
                                    ? BldrChallengeTextV2.tabOn
                                    : BldrChallengeTextV2.tabOff),
                          ),
                          Container(
                            height: 2,
                            color: _tab == i
                                ? BldrChallengeColorsV2.fill
                                : Colors.transparent,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
            color: BldrCommunityColorsV2.gold, strokeWidth: 2),
      );
    }
    if (_failed) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(BldrCommunityV2.pageX),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.chal_load_error,
                  textAlign: TextAlign.center,
                  style: BldrChallengeTextV2.subtitle),
              const SizedBox(height: 16),
              BldrChallengeCta(
                label: l10n.chal_retry,
                onTap: () {
                  setState(() => _loading = true);
                  _load();
                },
              ),
            ],
          ),
        ),
      );
    }
    final children = switch (_tab) {
      0 => _active(l10n),
      1 => _discover(l10n),
      _ => _done(l10n),
    };
    return RefreshIndicator(
      color: BldrCommunityColorsV2.gold,
      backgroundColor: BldrCommunityColorsV2.surface,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            BldrCommunityV2.pageX, 0, BldrCommunityV2.pageX, 48),
        children: children,
      ),
    );
  }

  Widget _empty(String text) => Padding(
        padding: const EdgeInsets.only(top: 64),
        child: Text(text,
            textAlign: TextAlign.center, style: BldrChallengeTextV2.subtitle),
      );

  /// Dois cards por linha, com a mesma altura. Em largura efetiva estreita
  /// (tela pequena com fonte ampliada) empilha, para não partir palavras.
  List<Widget> _pairs(List<Widget> cards) {
    final media = MediaQuery.of(context);
    if (media.size.width / media.textScaler.scale(1) < 280) {
      return [
        for (var i = 0; i < cards.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 16),
            child: cards[i],
          ),
      ];
    }
    return [
      for (var i = 0; i < cards.length; i += 2)
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[i]),
                const SizedBox(width: 16),
                Expanded(
                  child: i + 1 < cards.length
                      ? cards[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
    ];
  }

  List<Widget> _active(AppLocalizations l10n) {
    final s = ChallengeHubRules.active(_challenges, DateTime.now());
    final featured = s.featured;
    if (featured == null) return [_empty(l10n.chal_empty_active)];
    return [
      BldrChallengeSection(l10n.chal_sec_featured),
      _FeaturedCard(
        challenge: featured,
        standing: _standings[featured.id],
        onTap: () => _open(featured),
      ),
      if (s.others.isNotEmpty) ...[
        BldrChallengeSection(l10n.chal_sec_others),
        ..._pairs([
          for (final c in s.others)
            _ActiveTile(
                challenge: c,
                standing: _standings[c.id],
                onTap: () => _open(c)),
        ]),
      ],
      if (s.endingSoon.isNotEmpty) ...[
        BldrChallengeSection(l10n.chal_sec_ending),
        for (final c in s.endingSoon)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _EndingRow(challenge: c, onTap: () => _open(c)),
          ),
      ],
    ];
  }

  List<Widget> _discover(AppLocalizations l10n) {
    final s = ChallengeHubRules.discover(
      _challenges,
      myTypes: [
        ..._challenges.where((c) => c.joined).map((c) => c.challengeType),
        ..._past.map((e) => e.challenge.challengeType),
      ],
    );
    final recommended = s.recommended;
    if (recommended == null) return [_empty(l10n.chal_empty_discover)];
    return [
      BldrChallengeSection(l10n.chal_sec_recommended),
      _DiscoverCard(challenge: recommended, onTap: () => _open(recommended)),
      if (s.trending.isNotEmpty) ...[
        BldrChallengeSection(l10n.chal_sec_trending),
        ..._pairs([
          for (final c in s.trending)
            _DiscoverCard(challenge: c, onTap: () => _open(c)),
        ]),
      ],
      if (s.newest.isNotEmpty) ...[
        BldrChallengeSection(l10n.chal_sec_new),
        ..._pairs([
          for (final c in s.newest)
            _DiscoverCard(challenge: c, onTap: () => _open(c)),
        ]),
      ],
    ];
  }

  List<Widget> _done(AppLocalizations l10n) {
    if (_past.isEmpty) return [_empty(l10n.chal_empty_done)];
    final last = _past.first.challenge;
    final history = _past.skip(1).map((e) => e.challenge).toList();
    return [
      BldrChallengeSection(l10n.chal_sec_last),
      _DoneCard(
        challenge: last,
        standing: _standings[last.id],
        large: true,
        onTap: () => _openPast(last),
      ),
      if (history.isNotEmpty) ...[
        BldrChallengeSection(l10n.chal_sec_history),
        ..._pairs([
          for (final c in history)
            _DoneCard(
              challenge: c,
              standing: _standings[c.id],
              large: false,
              onTap: () => _openPast(c),
            ),
        ]),
      ],
    ];
  }
}

class _FeaturedCard extends StatelessWidget {
  final CollectiveChallenge challenge;
  final ChallengeStanding? standing;
  final VoidCallback onTap;
  const _FeaturedCard(
      {required this.challenge, required this.standing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = challenge;
    final days = ChallengeHubRules.daysLeft(c.endsAt, DateTime.now());
    final position = standing?.position;
    return BldrChallengeCard(
      radius: 20,
      semanticLabel: c.title,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BldrChallengeCover(imageUrl: c.coverImageUrl, height: 110),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.title.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: BldrChallengeTextV2.featured),
                if (days != null) ...[
                  const SizedBox(height: 4),
                  Text(
                      days <= 1
                          ? l10n.chal_last_day
                          : l10n.chal_days_left(days),
                      style: BldrChallengeTextV2.meta),
                ],
                const SizedBox(height: 10),
                BldrChallengeProgressBar(value: ChallengeHubRules.progress(c)),
                const SizedBox(height: 8),
                Text(ChallengeV2Labels.progress(l10n, c),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BldrChallengeTextV2.progress),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.chal_participants(
                            ChallengeV2Labels.number(l10n, c.participantCount)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BldrChallengeTextV2.meta,
                      ),
                    ),
                    if (position != null)
                      Text('#$position', style: BldrChallengeTextV2.rank),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveTile extends StatelessWidget {
  final CollectiveChallenge challenge;
  final ChallengeStanding? standing;
  final VoidCallback onTap;
  const _ActiveTile(
      {required this.challenge, required this.standing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = challenge;
    final position = standing?.position;
    return BldrChallengeCard(
      radius: 16,
      semanticLabel: c.title,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BldrChallengeCover(imageUrl: c.coverImageUrl, height: 78),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.title.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: BldrChallengeTextV2.smallTitle),
                const SizedBox(height: 6),
                Text(ChallengeV2Labels.progress(l10n, c),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BldrChallengeTextV2.meta),
                const SizedBox(height: 8),
                BldrChallengeProgressBar(
                    value: ChallengeHubRules.progress(c), height: 5),
                if (position != null) ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('#$position', style: BldrChallengeTextV2.rank),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EndingRow extends StatelessWidget {
  final CollectiveChallenge challenge;
  final VoidCallback onTap;
  const _EndingRow({required this.challenge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = challenge;
    final days = ChallengeHubRules.daysLeft(c.endsAt, DateTime.now()) ?? 0;
    final pct = (ChallengeHubRules.progress(c) * 100).round();
    return BldrChallengeCard(
      radius: 16,
      borderColor: BldrChallengeColorsV2.rowBorder,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.title.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: BldrChallengeTextV2.smallTitle),
                  const SizedBox(height: 4),
                  Text(
                      days <= 1
                          ? l10n.chal_last_day
                          : l10n.chal_ends_in(days, pct),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: BldrChallengeTextV2.meta),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 96, maxWidth: 126),
                child: BldrChallengeCta(
                    label: l10n.chal_view, minHeight: 42, onTap: onTap),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverCard extends StatelessWidget {
  final CollectiveChallenge challenge;
  final VoidCallback onTap;
  const _DiscoverCard({required this.challenge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = challenge;
    final days = ChallengeHubRules.daysLeft(c.endsAt, DateTime.now());
    final participants = l10n
        .chal_participants(ChallengeV2Labels.number(l10n, c.participantCount));
    final goal = ChallengeV2Labels.goal(l10n, c.challengeType, c.targetValue);
    return BldrChallengeCard(
      semanticLabel: c.title,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BldrChallengeCover(imageUrl: c.coverImageUrl, height: 88),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.title.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: BldrChallengeTextV2.cardTitle),
                const SizedBox(height: 4),
                Text(
                  days == null
                      ? participants
                      : '${days <= 1 ? l10n.chal_last_day : l10n.chal_duration_days(days)} · $participants',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: BldrChallengeTextV2.meta,
                ),
                const SizedBox(height: 6),
                Text(l10n.chal_goal(goal).toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: BldrChallengeTextV2.goal),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneCard extends StatelessWidget {
  final CollectiveChallenge challenge;
  final ChallengeStanding? standing;
  final bool large;
  final VoidCallback onTap;
  const _DoneCard({
    required this.challenge,
    required this.standing,
    required this.large,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = challenge;
    final s = standing;
    final total = ChallengeV2Labels.number(l10n, s?.total ?? 0);
    final endsAt = c.endsAt;
    final ended = endsAt == null
        ? null
        : l10n.chal_ended_on(
            DateFormat('d MMM', l10n.localeName).format(endsAt.toLocal()));
    final participants = l10n.chal_participants(total);
    final reached = ChallengeHubRules.progress(c) >= 1;
    return BldrChallengeCard(
      radius: 18,
      semanticLabel: c.title,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BldrChallengeCover(
              imageUrl: c.coverImageUrl, height: large ? 108 : 72),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (reached)
                      const Icon(TablerIcons.circle_check,
                          size: 22, color: BldrChallengeColorsV2.done),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: BldrChallengePill(l10n.chal_ended),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(c.title.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: large
                        ? BldrChallengeTextV2.featured
                        : BldrChallengeTextV2.smallTitle),
                const SizedBox(height: 3),
                Text(
                  large && ended != null
                      ? '$ended · $participants'
                      : participants,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: BldrChallengeTextV2.meta,
                ),
                if (s != null) ...[
                  const SizedBox(height: 8),
                  Text(l10n.chal_position, style: BldrChallengeTextV2.pill),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(
                        text: '#${s.position}',
                        style: large
                            ? BldrChallengeTextV2.position
                            : BldrChallengeTextV2.positionSm,
                      ),
                      if (large)
                        TextSpan(
                          text: '  ${l10n.chal_of_total(total)}',
                          style: BldrChallengeTextV2.meta,
                        ),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
