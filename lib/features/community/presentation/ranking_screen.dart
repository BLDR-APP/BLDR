import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/subscription_usecases.dart'
    as subUc;
import 'package:bldr_fitness/theme/bldr_tokens.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

enum _Period { week, month, all }

enum _Category { volume, consistency, progression }

class _RankingEntry {
  final int position;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final double value;
  final bool isMe;

  const _RankingEntry({
    required this.position,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.value,
    this.isMe = false,
  });
}

class _RankingScreenState extends State<RankingScreen> {
  _Period _period = _Period.week;
  _Category _category = _Category.volume;

  bool _loading = true;
  bool _isClub = false;
  List<_RankingEntry> _entries = [];
  _RankingEntry? _myEntry;

  final _client = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final sub = (await getIt<subUc.GetCurrentSubscription>()()).valueOrNull;
    _isClub = sub?.planId == 'club' || sub?.planId == 'club_annual';
    await _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final uid = _client.auth.currentUser?.id;
      final rpcName = _rpcName();
      final params = _rpcParams();

      final rows = await _client.rpc(rpcName, params: params) as List;

      final limit = _isClub ? 50 : 10;
      final all = <_RankingEntry>[];
      _RankingEntry? mine;

      for (final row in rows) {
        final pos = (row['position'] as num).toInt();
        final userId = row['user_id'] as String;
        final isMe = userId == uid;
        final entry = _RankingEntry(
          position: pos,
          userId: userId,
          displayName: (row['display_name'] as String?) ?? 'Atleta',
          avatarUrl: row['avatar_url'] as String?,
          value: (row['value'] as num).toDouble(),
          isMe: isMe,
        );
        if (isMe) mine = entry;
        if (pos <= limit) all.add(entry);
      }

      if (!mounted) return;
      setState(() {
        _entries = all;
        _myEntry = mine;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _rpcName() {
    switch (_category) {
      case _Category.volume:
        return 'ranking_volume';
      case _Category.consistency:
        return 'ranking_consistency';
      case _Category.progression:
        return 'ranking_progression';
    }
  }

  Map<String, dynamic> _rpcParams() {
    final now = DateTime.now();
    switch (_period) {
      case _Period.week:
        final start = now.subtract(const Duration(days: 7));
        return {'p_start': start.toUtc().toIso8601String()};
      case _Period.month:
        final start = DateTime(now.year, now.month, 1);
        return {'p_start': start.toUtc().toIso8601String()};
      case _Period.all:
        return {'p_start': '2020-01-01T00:00:00Z'};
    }
  }

  String _valueLabel(double value) {
    switch (_category) {
      case _Category.volume:
        return value >= 1000
            ? '${(value / 1000).toStringAsFixed(1)}t'
            : '${value.toStringAsFixed(0)}kg';
      case _Category.consistency:
        return '${value.toInt()} treinos';
      case _Category.progression:
        return '+${value.toStringAsFixed(1)}kg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BldrBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildPeriodSelector(),
              _buildCategoryChips(),
              Expanded(child: _loading ? _buildLoader() : _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(TablerIcons.chevron_left,
                color: BldrColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Text('Ranking', style: BldrText.screenTitle),
          const Spacer(),
          if (!_isClub)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: BldrColors.goldTint,
                border: Border.all(color: BldrColors.goldBorder),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text('TOP 10',
                  style: BldrText.label
                      .copyWith(color: BldrColors.goldBright, fontSize: 10)),
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    const labels = {
      _Period.week: 'Semana',
      _Period.month: 'Mês',
      _Period.all: 'Geral',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: _Period.values.map((p) {
          final selected = p == _period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _period = p);
                _load();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      selected ? BldrColors.goldSolid : BldrColors.surface,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: selected
                        ? BldrColors.goldSolid
                        : BldrColors.border,
                  ),
                ),
                child: Text(
                  labels[p]!,
                  style: BldrText.label.copyWith(
                    color: selected
                        ? BldrColors.bgBase
                        : BldrColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryChips() {
    const labels = {
      _Category.volume: 'Volume',
      _Category.consistency: 'Consistência',
      _Category.progression: 'Progressão',
    };
    const icons = {
      _Category.volume: TablerIcons.barbell,
      _Category.consistency: TablerIcons.calendar_check,
      _Category.progression: TablerIcons.trending_up,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: _Category.values.map((c) {
          final selected = c == _category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _category = c);
                _load();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: selected
                      ? BldrColors.goldTint
                      : BldrColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected
                        ? BldrColors.goldBorder
                        : BldrColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icons[c],
                        size: 14,
                        color: selected
                            ? BldrColors.goldBright
                            : BldrColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      labels[c]!,
                      style: BldrText.meta.copyWith(
                        color: selected
                            ? BldrColors.goldBright
                            : BldrColors.textSecondary,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLoader() {
    return const Center(
      child: CircularProgressIndicator(
          color: BldrColors.goldBright, strokeWidth: 2),
    );
  }

  Widget _buildBody() {
    if (_entries.isEmpty) {
      return Center(
        child: Text('Nenhum dado disponível.',
            style: BldrText.body.copyWith(color: BldrColors.textSecondary)),
      );
    }

    // Pódio: posições 1–3, ordenadas, pode ter menos de 3 entradas
    final podium = _entries.where((e) => e.position <= 3).toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    // Lista 4+: só renderizar se existirem entradas além do pódio
    final rest = _entries.where((e) => e.position > 3).toList();

    final myPos = _myEntry;
    final myInList = _entries.any((e) => e.isMe);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        // "Minha posição" — exibe normalmente mesmo que o usuário seja o único
        if (myPos != null) ...[
          _buildMyPositionCard(myPos),
          const SizedBox(height: 16),
        ],
        // Pódio: só mostra se houver ao menos 1 entrada; colunas vazias viram SizedBox.shrink
        if (podium.isNotEmpty) ...[
          _buildPodium(podium),
          const SizedBox(height: 16),
        ],
        // Posições 4+ (lista)
        if (rest.isNotEmpty) ...rest.map(_buildListEntry),
        // Se o usuário não aparece no top e está fora da lista visible, mostrar abaixo
        if (!_isClub && !myInList && myPos != null) ...[
          const SizedBox(height: 8),
          _buildDivider(),
          const SizedBox(height: 8),
          _buildListEntry(myPos),
        ],
        if (!_isClub) ...[
          const SizedBox(height: 16),
          _buildUpgradeHint(),
        ],
      ],
    );
  }

  Widget _buildMyPositionCard(_RankingEntry entry) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BldrColors.goldTint,
        border: Border.all(color: BldrColors.goldBorder),
        borderRadius: BorderRadius.circular(BldrRadius.card),
      ),
      child: Row(
        children: [
          const Icon(TablerIcons.trophy, color: BldrColors.goldBright, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sua posição',
                    style: BldrText.meta
                        .copyWith(color: BldrColors.goldBright)),
                Text('#${entry.position} · ${_valueLabel(entry.value)}',
                    style: BldrText.cardTitle
                        .copyWith(color: BldrColors.goldBright)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<_RankingEntry> top) {
    // Sempre renderiza exatamente 3 colunas para manter o layout estável.
    // Posições sem dados ficam como SizedBox.shrink().
    const medals = ['🥇', '🥈', '🥉'];
    const heights = [100.0, 80.0, 65.0];

    Widget podiumColumn(int idx) {
      if (idx >= top.length) return const Expanded(child: SizedBox.shrink());
      final entry = top[idx];
      final isFirst = idx == 0;
      return Expanded(
        child: Column(
          children: [
            Text(medals[idx], style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            _buildAvatar(entry, size: isFirst ? 44 : 36),
            const SizedBox(height: 6),
            Text(
              entry.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BldrText.meta.copyWith(
                color: entry.isMe ? BldrColors.goldBright : BldrColors.textPrimary,
                fontWeight: isFirst ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Text(_valueLabel(entry.value),
                style: BldrText.metaSm.copyWith(color: BldrColors.textSecondary)),
            const SizedBox(height: 8),
            Container(
              height: heights[idx],
              decoration: BoxDecoration(
                color: idx == 0 ? BldrColors.goldTint : BldrColors.surface,
                border: Border.all(
                    color: idx == 0 ? BldrColors.goldBorder : BldrColors.border),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Center(
                child: Text('#${entry.position}',
                    style: BldrText.label.copyWith(
                        color: idx == 0
                            ? BldrColors.goldBright
                            : BldrColors.textSecondary)),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        podiumColumn(1), // 🥈 esquerda
        podiumColumn(0), // 🥇 centro
        podiumColumn(2), // 🥉 direita
      ],
    );
  }

  Widget _buildListEntry(_RankingEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isMe ? BldrColors.goldTint : BldrColors.surface,
        border: Border.all(
            color:
                entry.isMe ? BldrColors.goldBorder : BldrColors.border),
        borderRadius: BorderRadius.circular(BldrRadius.cardSm),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('#${entry.position}',
                style: BldrText.label.copyWith(
                    color: entry.isMe
                        ? BldrColors.goldBright
                        : BldrColors.textSecondary)),
          ),
          const SizedBox(width: 10),
          _buildAvatar(entry, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Text(entry.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BldrText.body.copyWith(
                    color: entry.isMe
                        ? BldrColors.goldBright
                        : BldrColors.textPrimary)),
          ),
          Text(_valueLabel(entry.value),
              style: BldrText.label.copyWith(
                  color: entry.isMe
                      ? BldrColors.goldBright
                      : BldrColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildAvatar(_RankingEntry entry, {required double size}) {
    if (entry.avatarUrl != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(entry.avatarUrl!),
        backgroundColor: BldrColors.surface,
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: entry.isMe ? BldrColors.goldTint : BldrColors.surface,
      child: Text(
        entry.displayName.isNotEmpty
            ? entry.displayName[0].toUpperCase()
            : '?',
        style: BldrText.label.copyWith(
            color: entry.isMe
                ? BldrColors.goldBright
                : BldrColors.textSecondary,
            fontSize: size * 0.4),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: BldrColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('···',
              style: BldrText.meta
                  .copyWith(color: BldrColors.textSecondary)),
        ),
        Expanded(child: Container(height: 1, color: BldrColors.border)),
      ],
    );
  }

  Widget _buildUpgradeHint() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BldrColors.surface,
        border: Border.all(color: BldrColors.border),
        borderRadius: BorderRadius.circular(BldrRadius.cardSm),
      ),
      child: Row(
        children: [
          const Icon(TablerIcons.lock, size: 16, color: BldrColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Faça upgrade para Club e veja o ranking completo (top 50)',
              style: BldrText.meta.copyWith(color: BldrColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
