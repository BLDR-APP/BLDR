// lib/presentation/bldr_club/ranking_screen.dart
import 'package:flutter/material.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

const _gold = Color(0xFFD4AF37);

class RankingEntry {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int xp;
  final int level;
  final int position;

  const RankingEntry({
    required this.userId,
    required this.displayName,
    required this.xp,
    required this.level,
    required this.position,
    this.avatarUrl,
  });
}

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  List<RankingEntry>? _rankingData;

  bool _isLoading = true;
  String? _myUserId;

  @override
  void initState() {
    super.initState();
    _myUserId = getIt<GetCurrentUser>()()?.id;
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await _loadRanking();
    if (mounted) setState(() => _isLoading = false);
  }

  // 1. Busca Ranking
  Future<void> _loadRanking() async {
    try {
      final result = await getIt<GetClubRanking>()(limit: 100);
      final entries = result.valueOrNull;
      if (entries == null) throw Exception(result.failureOrNull?.message);

      final List<RankingEntry> loaded = [];
      int pos = 1;
      for (final row in entries) {
        loaded.add(RankingEntry(
          userId: row.userId,
          displayName: row.displayName,
          avatarUrl: row.avatarUrl,
          xp: row.xpTotal,
          level: row.currentLevel,
          position: pos++,
        ));
      }

      if (mounted) setState(() => _rankingData = loaded);
    } catch (e) {
      debugPrint('Erro buscando ranking: $e');
    }
  }

  void _openPublicProfile(RankingEntry entry) {
    if (entry.userId == _myUserId) return;
    Navigator.pushNamed(context, '/bldr-club/perfil-publico', arguments: {
      'userId': entry.userId,
      'displayName': entry.displayName,
    });
  }

  @override
  Widget build(BuildContext context) {
    final top3 = _rankingData?.take(3).toList() ?? [];
    final rest = _rankingData?.skip(3).toList() ?? [];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const _GoldRadialBackground(),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Image.asset(
                            'assets/images/BLDR CLUB_RANKING.png',
                            height: 140,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                if (_isLoading)
                  const Expanded(child: Center(child: CircularProgressIndicator(color: _gold)))
                else
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadAllData,
                      color: _gold,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // PODIO
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 24, top: 16),
                              child: _PodiumWidget(top3: top3, onTap: _openPublicProfile),
                            ),
                          ),

                          // 4. LISTA
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                final user = rest[index];
                                return _RankingListItem(
                                  user: user,
                                  isMe: user.userId == _myUserId,
                                  onTap: () => _openPublicProfile(user),
                                );
                              },
                              childCount: rest.length,
                            ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 40)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


/* ================== WIDGETS DO PÓDIO ================== */

class _PodiumWidget extends StatelessWidget {
  final List<RankingEntry> top3;
  final Function(RankingEntry) onTap;
  const _PodiumWidget({required this.top3, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (top3.isEmpty) return const SizedBox();
    final first = top3[0];
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    // <<< NOVO: FittedBox envolvendo toda a Row do pódio!
    return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.bottomCenter, // Mantém o pódio ancorado no chão
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (second != null) _PodiumColumn(entry: second, size: 90, height: 120, color: Colors.grey.shade400, onTap: onTap),
            _PodiumColumn(entry: first, size: 110, height: 160, color: _gold, isFirst: true, onTap: onTap),
            if (third != null) _PodiumColumn(entry: third, size: 90, height: 100, color: const Color(0xFFCD7F32), onTap: onTap),
          ],
        ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final RankingEntry entry;
  final double size; final double height; final Color color; final bool isFirst; final Function(RankingEntry) onTap;
  const _PodiumColumn({required this.entry, required this.size, required this.height, required this.color, this.isFirst = false, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(entry),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Stack(alignment: Alignment.topCenter, children: [
              Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2), boxShadow: isFirst ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 20)] : []),
                child: CircleAvatar(radius: isFirst ? 35 : 25, backgroundImage: entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null, backgroundColor: Colors.grey[900], child: entry.avatarUrl == null ? Text(entry.displayName[0], style: const TextStyle(color: Colors.white)) : null),
              ),
              if (isFirst) Transform.translate(offset: const Offset(0, -18), child: const Icon(Icons.emoji_events, color: _gold, size: 24)),
            ]),
            const SizedBox(height: 8),
            SizedBox(width: size, child: Text(entry.displayName.split(' ')[0], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)),
            Text('${entry.xp} XP', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Container(width: size, height: height, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color.withOpacity(0.3), color.withOpacity(0.05)]), borderRadius: const BorderRadius.vertical(top: Radius.circular(8)), border: Border.all(color: color.withOpacity(0.3))), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('${entry.position}', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold))])),
          ],
        ),
      ),
    );
  }
}

class _RankingListItem extends StatelessWidget {
  final RankingEntry user; final bool isMe; final VoidCallback onTap;
  const _RankingListItem({required this.user, required this.isMe, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: isMe ? _gold.withOpacity(0.1) : const Color(0xFF101010), borderRadius: BorderRadius.circular(12), border: Border.all(color: isMe ? _gold.withOpacity(0.5) : Colors.white10)), child: Row(children: [SizedBox(width: 30, child: Text('#${user.position}', style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold))), CircleAvatar(radius: 18, backgroundColor: Colors.grey[800], backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null, child: user.avatarUrl == null ? Text(user.displayName.isNotEmpty ? user.displayName[0] : '?', style: const TextStyle(color: Colors.white, fontSize: 12)) : null), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(user.displayName + (isMe ? AppLocalizations.of(context).ranking_you_suffix : ''), style: TextStyle(color: isMe ? _gold : Colors.white, fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis), Text(AppLocalizations.of(context).club_level(user.level), style: TextStyle(color: Colors.grey[600], fontSize: 11))])), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)), child: Text('${user.xp} XP', style: const TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 12)))]))));
  }
}


class _GoldRadialBackground extends StatelessWidget {
  const _GoldRadialBackground();
  @override
  Widget build(BuildContext context) { return const PositionedFill(); }
}

class PositionedFill extends StatelessWidget {
  const PositionedFill({super.key});
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(child: IgnorePointer(child: Stack(children: const [
      _RadialBlob(top: -180, opacity: 0.30, radiusFactor: 1.8),
      _RadialBlob(bottom: -140, opacity: 0.18, radiusFactor: 1.6),
    ])));
  }
}

class _RadialBlob extends StatelessWidget {
  final double? top; final double? bottom; final double opacity; final double radiusFactor;
  const _RadialBlob({this.top, this.bottom, required this.opacity, required this.radiusFactor});
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width * radiusFactor;
    final c = const Color(0xFFD4AF37).withOpacity(opacity);
    final blob = Center(child: Container(width: w, height: w, decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: RadialGradient(colors: [c, c.withOpacity(0)], radius: 0.75))));
    if (top != null) return Positioned(top: top, left: 0, right: 0, child: blob);
    if (bottom != null) return Positioned(bottom: bottom, left: 0, right: 0, child: blob);
    return Positioned.fill(child: blob);
  }
}