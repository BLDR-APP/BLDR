import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/community/domain/entities/ranking_entry.dart';
import 'package:bldr_fitness/features/community/domain/repositories/community_feed_repository.dart';
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

class _RankingScreenState extends State<RankingScreen> {
  late final CommunityFeedRepository _repo;

  _Period _period = _Period.week;
  _Category _category = _Category.volume;

  bool _loading = true;
  bool _hasError = false;
  String _errorMessage = '';
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
    final sub = (await getIt<subUc.GetCurrentSubscription>()()).valueOrNull;
    _isClub = sub?.planId == 'club' || sub?.planId == 'club_annual';
    await _load();
  }

  // D3: usa p_period (correto) em vez de p_start (incorreto)
  // D5: valores de period são 'week', 'month', 'all' — requer confirmação
  String _periodValue() => switch (_period) {
        _Period.week => 'week',
        _Period.month => 'month',
        _Period.all => 'all',
      };

  String _categoryValue() => switch (_category) {
        _Category.volume => 'volume',
        _Category.consistency => 'consistency',
        _Category.progression => 'progression',
      };

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _hasError = false;
    });

    final result = await _repo.fetchRanking(
      category: _categoryValue(),
      period: _periodValue(),
    );

    if (!mounted) return;
    result.fold(
      onSuccess: (entries) {
        final limit = _isClub ? 50 : 10;
        final visible = entries.where((e) => e.position <= limit).toList();
        final mine = entries.where((e) => e.isMe).firstOrNull;
        setState(() {
          _entries = visible;
          _myEntry = mine;
          _loading = false;
          _hasError = false;
        });
      },
      onFailure: (failure) => setState(() {
        _loading = false;
        _hasError = true;
        _errorMessage = failure.message;
      }),
    );
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
              Expanded(
        child: _loading
            ? _buildLoader()
            : _hasError
                ? _buildError()
                : _buildBody(),
      ),
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

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(TablerIcons.trophy_off,
                size: 48, color: BldrColors.textTertiary),
            const SizedBox(height: 16),
            Text('Erro ao carregar o ranking', style: BldrText.sectionTitle),
            const SizedBox(height: 8),
            Text(_errorMessage,
                style: BldrText.description, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _load,
              style: TextButton.styleFrom(
                backgroundColor: BldrColors.goldSolid,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  Widget _buildMyPositionCard(RankingEntry entry) {
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

  Widget _buildPodium(List<RankingEntry> top) {
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

  Widget _buildListEntry(RankingEntry entry) {
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

  Widget _buildAvatar(RankingEntry entry, {required double size}) {
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
