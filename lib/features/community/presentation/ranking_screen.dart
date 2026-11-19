import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_challenge_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_community_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/community/domain/entities/ranking_entry.dart';
import 'package:bldr_fitness/features/community/domain/repositories/community_feed_repository.dart';
import 'package:bldr_fitness/features/community/presentation/hub_v2/community_v2_format.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/resolve_club_access.dart';
import 'package:bldr_fitness/features/subscription/presentation/paywall/club_paywall_sheet.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Ranking (Figma 121:1041). Aba Amigos e variação de posição ficam ocultas
/// (sem dados); FREE vê o top 10 e um card com cadeado (D11).
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

enum _Period { week, month, all }

enum _Category { volume, consistency, progression }

class _RankingScreenState extends State<RankingScreen> {
  static const _freeLimit = 10;
  static const _clubLimit = 50;

  late final CommunityFeedRepository _repo;

  _Period _period = _Period.week;
  _Category _category = _Category.volume;

  bool _loading = true;
  bool _hasError = false;
  bool _isClub = false;
  List<RankingEntry> _entries = [];
  RankingEntry? _myEntry;

  @override
  void initState() {
    super.initState();
    _repo = getIt<CommunityFeedRepository>();
    _init();
  }

  Future<void> _init() async {
    _isClub = (await getIt<ResolveClubAccess>()()).valueOrNull ?? false;
    await _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _hasError = false;
    });
    final result = await _repo.fetchRanking(
      category: _category.name,
      period: _period.name,
    );
    if (!mounted) return;
    result.fold(
      onSuccess: (entries) {
        final limit = _isClub ? _clubLimit : _freeLimit;
        setState(() {
          _entries = entries.where((e) => e.position <= limit).toList();
          _myEntry = entries.where((e) => e.isMe).firstOrNull;
          _loading = false;
        });
      },
      onFailure: (_) => setState(() {
        _loading = false;
        _hasError = true;
      }),
    );
  }

  Future<void> _upgrade() async {
    await ClubPaywallSheet.show(context);
    final club = (await getIt<ResolveClubAccess>()()).valueOrNull ?? false;
    if (mounted && club != _isClub) {
      _isClub = club;
      _load();
    }
  }

  String _value(AppLocalizations l10n, double value) {
    final locale = l10n.localeName;
    return switch (_category) {
      _Category.volume => value >= 1000
          ? '${CommunityV2Format.decimal(value / 1000, locale, digits: 1)} t'
          : '${CommunityV2Format.thousands(value, locale)} kg',
      _Category.consistency =>
        l10n.rank_workouts(CommunityV2Format.thousands(value, locale)),
      _Category.progression =>
        '+${CommunityV2Format.decimal(value, locale, digits: 1)} kg',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BldrBackground(
      v2: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: BldrCommunityColorsV2.gold,
            backgroundColor: BldrCommunityColorsV2.surface,
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  BldrCommunityV2.pageX, 8, BldrCommunityV2.pageX, 48),
              children: [
                _header(l10n),
                const SizedBox(height: 18),
                Text(l10n.rank_period, style: BldrRankingTextV2.label),
                const SizedBox(height: 6),
                _chips([
                  for (final p in _Period.values)
                    (
                      switch (p) {
                        _Period.week => l10n.rank_week,
                        _Period.month => l10n.rank_month,
                        _Period.all => l10n.rank_all,
                      },
                      p == _period,
                      () {
                        setState(() => _period = p);
                        _load();
                      },
                    ),
                ]),
                const SizedBox(height: 16),
                Text(l10n.rank_metric, style: BldrRankingTextV2.label),
                const SizedBox(height: 6),
                _chips([
                  for (final c in _Category.values)
                    (
                      switch (c) {
                        _Category.volume => l10n.rank_volume,
                        _Category.consistency => l10n.rank_consistency,
                        _Category.progression => l10n.rank_progression,
                      },
                      c == _category,
                      () {
                        setState(() => _category = c);
                        _load();
                      },
                    ),
                ]),
                const SizedBox(height: 20),
                ..._body(l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(AppLocalizations l10n) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Transform.translate(
                offset: const Offset(-18, 0),
                child: BldrCommunityBackButton(
                    onTap: () => Navigator.maybePop(context)),
              ),
              Expanded(
                child: Transform.translate(
                  offset: const Offset(-24, 0),
                  child: Text(l10n.rank_title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrRankingTextV2.heading),
                ),
              ),
            ],
          ),
          Text(l10n.rank_subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: BldrRankingTextV2.subtitle),
          const SizedBox(height: 10),
          // Só a aba Global: Amigos depende de RPC que ainda não existe.
          IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 86),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(l10n.rank_tab_global,
                        textAlign: TextAlign.center,
                        style: BldrRankingTextV2.tabOn),
                  ),
                ),
                Container(height: 2, color: BldrCommunityColorsV2.goldBrand),
              ],
            ),
          ),
        ],
      );

  Widget _chips(List<(String, bool, VoidCallback)> items) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (label, on, onTap) in items)
            Semantics(
              button: true,
              selected: on,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: Container(
                  // Sem `alignment`: no Wrap o chip ocuparia a linha inteira.
                  constraints: const BoxConstraints(minWidth: 72),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: on
                        ? BldrRankingColorsV2.chipOnBg
                        : BldrCommunityColorsV2.surface,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: on
                          ? BldrRankingColorsV2.chipOnBorder
                          : BldrRankingColorsV2.chipOffBorder,
                    ),
                  ),
                  child: Text(label,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: on
                          ? BldrRankingTextV2.chipOn
                          : BldrRankingTextV2.chipOff),
                ),
              ),
            ),
        ],
      );

  List<Widget> _body(AppLocalizations l10n) {
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 48),
          child: Center(
            child: CircularProgressIndicator(
                color: BldrCommunityColorsV2.gold, strokeWidth: 2),
          ),
        ),
      ];
    }
    if (_hasError) {
      return [
        const SizedBox(height: 32),
        Text(l10n.rank_error,
            textAlign: TextAlign.center, style: BldrRankingTextV2.subtitle),
        const SizedBox(height: 16),
        BldrChallengeCta(label: l10n.chal_retry, onTap: _load),
      ];
    }
    if (_entries.isEmpty) {
      return [
        const SizedBox(height: 48),
        Text(l10n.rank_empty,
            textAlign: TextAlign.center, style: BldrRankingTextV2.subtitle),
      ];
    }
    final podium = _entries.where((e) => e.position <= 3).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    final rest = _entries.where((e) => e.position > 3).toList();
    final mine = _myEntry;
    final mineOutside = mine != null && !_entries.any((e) => e.isMe);
    return [
      if (mine != null) _mineCard(l10n, mine),
      const SizedBox(height: 20),
      Text(l10n.rank_top3, style: BldrRankingTextV2.label),
      const SizedBox(height: 8),
      _podium(l10n, podium),
      if (rest.isNotEmpty || mineOutside) ...[
        const SizedBox(height: 14),
        Text(l10n.rank_list, style: BldrRankingTextV2.label),
        const SizedBox(height: 8),
        for (final e in rest) _row(l10n, e),
        if (mineOutside) _row(l10n, mine),
      ],
      if (!_isClub) ...[
        const SizedBox(height: 4),
        _lockCard(l10n),
      ],
    ];
  }

  Widget _mineCard(AppLocalizations l10n, RankingEntry e) => Container(
        padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: BldrRankingColorsV2.mineBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.rank_mine, style: BldrRankingTextV2.mineLabel),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('#${e.position}', style: BldrRankingTextV2.minePos),
                const SizedBox(width: 18),
                Flexible(
                  child: Text(_value(l10n, e.value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrRankingTextV2.mineValue),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _podium(AppLocalizations l10n, List<RankingEntry> top) {
    Widget column(int index) {
      if (index >= top.length) return const Expanded(child: SizedBox.shrink());
      final e = top[index];
      final first = index == 0;
      final size = first ? 62.0 : 52.0;
      return Expanded(
        flex: first ? 136 : 116,
        child: Padding(
          padding: EdgeInsets.only(top: first ? 0 : 16),
          child: Column(
            children: [
              SizedBox(
                width: size + 10,
                height: size + 6,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      bottom: 0,
                      child: BldrCommunityAvatar(
                        name: e.displayName,
                        imageUrl: e.avatarUrl,
                        size: size,
                        initialsStyle: BldrRankingTextV2.initials,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: first
                              ? BldrCommunityColorsV2.goldBrand
                              : BldrRankingColorsV2.badgeOff,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('#${e.position}',
                              style: first
                                  ? BldrRankingTextV2.badgeFirst
                                  : BldrRankingTextV2.badge),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(e.displayName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: first
                      ? BldrRankingTextV2.podiumNameFirst
                      : BldrRankingTextV2.podiumName),
              if (e.username != null)
                Text('@${e.username}',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BldrRankingTextV2.handle),
              const SizedBox(height: 6),
              Text(_value(l10n, e.value),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: first
                      ? BldrRankingTextV2.podiumValueFirst
                      : BldrRankingTextV2.podiumValue),
              if (first)
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                  height: 3,
                  decoration: BoxDecoration(
                    color: BldrCommunityColorsV2.goldBrand,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [column(1), column(0), column(2)],
      ),
    );
  }

  Widget _row(AppLocalizations l10n, RankingEntry e) {
    final mine = e.isMe;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(minHeight: 62),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color:
            mine ? BldrRankingColorsV2.mineBg : BldrCommunityColorsV2.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: mine
              ? BldrRankingColorsV2.mineBorder
              : BldrCommunityColorsV2.divider,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('#${e.position}',
                  style: mine
                      ? BldrRankingTextV2.rowPosMine
                      : BldrRankingTextV2.rowPos),
            ),
          ),
          BldrCommunityAvatar(
            name: e.displayName,
            imageUrl: e.avatarUrl,
            size: 36,
            initialsStyle: BldrRankingTextV2.initialsSm,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mine ? '${e.displayName}  · ${l10n.rank_you}' : e.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BldrRankingTextV2.rowName,
                ),
                if (e.username != null)
                  Text('@${e.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrRankingTextV2.handle),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(_value(l10n, e.value),
              style: mine
                  ? BldrRankingTextV2.rowValueMine
                  : BldrRankingTextV2.rowValue),
        ],
      ),
    );
  }

  Widget _lockCard(AppLocalizations l10n) => Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _upgrade,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: BldrCommunityColorsV2.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BldrRankingColorsV2.mineBorder),
            ),
            child: Row(
              children: [
                const Icon(TablerIcons.lock,
                    size: 18, color: BldrCommunityColorsV2.goldBrand),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(l10n.rank_lock, style: BldrRankingTextV2.lock),
                ),
                const Icon(TablerIcons.chevron_right,
                    size: 18, color: BldrCommunityColorsV2.goldBrand),
              ],
            ),
          ),
        ),
      );
}
