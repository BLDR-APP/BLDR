import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Supabase mantido apenas pelo canal realtime de XP (dívida 6c).
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/domain/entities/club_community.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/havok/widgets/panther_fab.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/competition_hub_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/widgets/level_up_modal.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/widgets/smart_club_slider.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

class BldrClubScreen extends StatefulWidget {
  const BldrClubScreen({super.key});

  @override
  State<BldrClubScreen> createState() => _BldrClubScreenState();
}

class _BldrClubScreenState extends State<BldrClubScreen> {
  int _survivorRefreshKey = 0;

  String? _userId;
  RealtimeChannel? _xpChannel;
  int _totalXpState = 0;
  // C2 — posição no ranking, mesma fonte/lógica que `ranking_screen.dart`
  // já usa (posição = índice na lista ordenada). Null enquanto carrega ou
  // se o usuário não aparece no recorte (nunca mostramos um número falso).
  int? _myPosition;
  // Nível anterior — usado apenas para detectar level up em tempo real.
  // Inicia em 0 para indicar que ainda não foi inicializado (evita falso
  // positivo no primeiro carregamento).
  int _prevLevel = 0;

  List<Map<String, dynamic>> _ann = [];
  List<Map<String, dynamic>> _events = [];
  bool _communityDataLoading = true;
  final PageController _billboardCtrl = PageController();
  Timer? _billboardTimer;
  int _billboardIndex = 0;

  List<Map<String, dynamic>> get _annWithImages {
    return _ann.where((a) {
      final url = (a['image_url'] ?? '').toString().trim();
      return url.isNotEmpty;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _initGamification();
    _loadCommunitySectionData();
  }

  Future<void> _loadCommunitySectionData() async {
    setState(() => _communityDataLoading = true);
    try {
      final ann = ((await getIt<GetClubAnnouncements>()()).valueOrNull ?? [])
          .map((a) => {
                'id': a.id,
                'title': a.title,
                'image_url': a.imageUrl,
                'image_url_main': a.imageUrlMain,
                'link_url': a.linkUrl,
                'created_at': a.createdAt?.toIso8601String(),
              })
          .toList();
      final evs = ((await getIt<GetClubEvents>()(limit: 5)).valueOrNull ?? [])
          .map((e) => {
                'id': e.id,
                'title': e.title,
                'image_url': e.imageUrl,
                'link_url': e.linkUrl,
                'created_at': e.createdAt?.toIso8601String(),
              })
          .toList();

      _stopBillboard();
      if (ann.any((a) => (a['image_url'] ?? '').toString().trim().isNotEmpty)) {
        _startBillboard();
      }

      if (mounted) {
        setState(() {
          _ann = ann;
          _events = evs;
        });
      }
    } catch (e) {
      debugPrint('[BLDR CLUB] Erro ao carregar dados da comunidade: $e');
    } finally {
      if (mounted) setState(() => _communityDataLoading = false);
    }
  }

  void _startBillboard() {
    if (_annWithImages.isEmpty) return;
    _billboardTimer?.cancel();
    _billboardTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_billboardCtrl.hasClients) return;
      _billboardIndex = (_billboardIndex + 1) % _annWithImages.length;
      _billboardCtrl.animateToPage(
        _billboardIndex,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _stopBillboard() {
    _billboardTimer?.cancel();
    _billboardTimer = null;
  }

  Widget _sectionTitle(BuildContext context, String t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t, style: BldrText.sectionTitle),
        const SizedBox(height: 4),
        Container(
          height: 2,
          width: 38,
          decoration: BoxDecoration(
            color: BldrColors.goldBright,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ],
    );
  }

  Future<void> _initGamification() async {
    try {
      _userId = getIt<GetCurrentUser>()()?.id;
      if (_userId == null) return;

      await _fetchTotalXpForUser();
      _subscribeToXpChanges();
      _fetchMyRankingPosition();
    } catch (e) {
      debugPrint('[BLDR CLUB] Erro init gamificação: $e');
    }
  }

  /// Calcula o nível a partir do XP total — fonte única de verdade para a UI.
  /// Evita depender de `current_level` do banco, que pode chegar defasado
  /// quando o trigger do Supabase ainda não rodou no momento do evento realtime.
  static int _levelFromXp(int xp) {
    const thresholds = {1: 0, 2: 1000, 3: 2500, 4: 5000, 5: 10000};
    int result = 1;
    for (final entry in thresholds.entries) {
      if (xp >= entry.value) result = entry.key;
    }
    return result;
  }

  Future<void> _fetchTotalXpForUser() async {
    final uid = _userId;
    if (uid == null) return;

    try {
      final result = await getIt<GetMyRankingEntry>()();
      final total = result.valueOrNull?.xpTotal ?? 0;

      if (mounted) {
        setState(() {
          _totalXpState = total;
          // Estabelece o nível base na inicialização — sem disparar modal.
          if (_prevLevel == 0) _prevLevel = _levelFromXp(total);
        });
      }
    } catch (e) {
      debugPrint('[BLDR CLUB] Erro ao buscar club_ranking: $e.');
    }
  }

  /// C2 — mesma abordagem de `ranking_screen.dart`: busca o recorte
  /// ordenado e deriva a posição pelo índice (não há campo `position`
  /// pronto no domínio).
  Future<void> _fetchMyRankingPosition() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final result = await getIt<GetClubRanking>()(limit: 100);
      final entries = result.valueOrNull;
      if (entries == null || !mounted) return;
      final idx = entries.indexWhere((e) => e.userId == uid);
      setState(() => _myPosition = idx == -1 ? null : idx + 1);
    } catch (e) {
      debugPrint('[BLDR CLUB] Erro ao buscar posição no ranking: $e');
    }
  }

  void _subscribeToXpChanges() {
    final uid = _userId;
    if (uid == null) return;

    _xpChannel?.unsubscribe();

    _xpChannel = Supabase.instance.client.channel('realtime_bldr_ranking_$uid')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'bldr_club',
        table: 'club_ranking',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: uid,
        ),
        callback: (payload) {
          // xp_total pode vir nulo se o evento foi gerado por outro campo
          // (ex: trigger atualizando current_level). Nesses casos, re-fetch.
          final xpRaw = (payload.newRecord['xp_total'] as num?)?.toInt();
          if (xpRaw != null) {
            if (mounted) {
              final newLevel = _levelFromXp(xpRaw);
              final oldLevel = _prevLevel;
              setState(() {
                _totalXpState = xpRaw;
                _prevLevel = newLevel;
              });
              // Mostra o modal apenas quando há um level up real
              // e o nível base já foi inicializado (oldLevel > 0).
              if (oldLevel > 0 && newLevel > oldLevel) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    LevelUpModal.show(
                      context,
                      fromLevel: oldLevel,
                      toLevel: newLevel,
                    );
                  }
                });
              }
            }
          } else {
            _fetchTotalXpForUser();
          }
        },
      )
      ..subscribe();
  }

  @override
  void dispose() {
    _xpChannel?.unsubscribe();
    _xpChannel = null;
    _stopBillboard();
    _billboardCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalXp = _totalXpState;
    // Nível sempre derivado do XP para garantir consistência na UI,
    // mesmo que _currentLevelState ainda não tenha sido atualizado.
    final level = _levelFromXp(totalXp);
    const Map<int, int> levelThresholds = { 1: 0, 2: 1000, 3: 2500, 4: 5000, 5: 10000 };
    final int xpStartOfLevel = levelThresholds[level] ?? 0;
    final int xpNextLevelTarget = levelThresholds[level + 1] ?? (xpStartOfLevel + 10000);
    final int xpGainedInThisLevel = totalXp - xpStartOfLevel;
    final int xpNeededForThisLevel = xpNextLevelTarget - xpStartOfLevel;
    double progress = 0.0;
    if (xpNeededForThisLevel > 0) {
      progress = (xpGainedInThisLevel / xpNeededForThisLevel).clamp(0.0, 1.0);
    }

    final hasActiveEvent = !_communityDataLoading && _events.isNotEmpty;
    final hasActiveAnn = !_communityDataLoading && _annWithImages.isNotEmpty;

    return Scaffold(
      backgroundColor: BldrColors.bgBase,
      floatingActionButton: const PantherFab(),
      body: BldrBackground(
        child: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Header/Hero — logo mantida como está (asset + glow do
                // próprio asset). Só o fundo decorativo ao redor virou
                // BldrBackground (C1).
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _Header(logoPath: 'assets/images/BLDR_CLUB.png', logoHeight: 200),
                  ),
                ),

                // 2. XP / Nível + posição no ranking (C2)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _LevelProgressCard(
                      level: level,
                      currentXP: totalXp,
                      xpPerLevel: xpNextLevelTarget,
                      progress: progress,
                      position: _myPosition,
                    ),
                  ),
                ),

                // 3. Eventos — só renderiza se houver conteúdo ativo
                if (hasActiveEvent)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(context, AppLocalizations.of(context).club_events_title),
                          const SizedBox(height: 8),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _events.length > 2 ? 2 : _events.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) => _EventCard(data: _events[i]),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 4. Anúncios — só renderiza se houver conteúdo ativo
                if (hasActiveAnn)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, hasActiveEvent ? 16 : 24, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle(context, AppLocalizations.of(context).club_announcements_title),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 180,
                            child: Container(
                              decoration: BoxDecoration(
                                color: BldrColors.surface,
                                borderRadius: BldrRadius.all(BldrRadius.cardLg),
                                border: Border.all(color: BldrColors.border),
                              ),
                              child: ClipRRect(
                                borderRadius: BldrRadius.all(BldrRadius.cardLg),
                                child: Listener(
                                  onPointerDown: (_) => _stopBillboard(),
                                  onPointerUp: (_) => _startBillboard(),
                                  child: PageView.builder(
                                    controller: _billboardCtrl,
                                    onPageChanged: (i) => _billboardIndex = i,
                                    itemCount: _annWithImages.length,
                                    itemBuilder: (_, i) => _BillboardItem(data: _annWithImages[i]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // 5. Grid 2x2 — C3: ícone alinhado à esquerda (BldrListRow,
                // componente 7.7), não mais centralizado.
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: BldrListRow(
                                icon: Icons.fitness_center_outlined,
                                title: AppLocalizations.of(context).club_workouts_title,
                                subtitle: AppLocalizations.of(context).club_workouts_subtitle,
                                onTap: () => Navigator.of(context).pushNamed('/bldr-club/treinos'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: BldrListRow(
                                icon: Icons.sports_soccer_outlined,
                                title: AppLocalizations.of(context).club_sports_title,
                                subtitle: AppLocalizations.of(context).club_sports_subtitle,
                                onTap: () => Navigator.of(context).pushNamed('/bldr-club/esportes'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: BldrListRow(
                                icon: Icons.groups_2_outlined,
                                title: AppLocalizations.of(context).club_community_title,
                                subtitle: AppLocalizations.of(context).club_community_subtitle,
                                onTap: () => Navigator.of(context).pushNamed('/bldr-club/comunidade'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: BldrListRow(
                                icon: Icons.sports_kabaddi,
                                title: AppLocalizations.of(context).club_competition_title,
                                subtitle: AppLocalizations.of(context).club_competition_subtitle,
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const CompetitionHubScreen()),
                                  );
                                  setState(() => _survivorRefreshKey++);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 6. Operação da semana (F21)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _WeeklyOperationCard(),
                  ),
                ),

                // 7. Squad row — Operação ativa / CTA criar squad
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    child: ClubDashboardConnector(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}

// -----------------------------------------------------------
// ---------------- WIDGETS AUXILIARES -----------------------
// -----------------------------------------------------------

class _EventCard extends StatelessWidget {
  const _EventCard({required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final title = (data['title'] ?? '').toString();
    final createdAt = DateTime.tryParse((data['created_at'] ?? '').toString())?.toLocal();
    final when = createdAt == null ? '' : '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    return BldrGlassCard(
      radius: BldrRadius.cardLg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: BldrText.cardTitle),
        const SizedBox(height: 4),
        Row(children: [
          const Icon(Icons.watch_later_outlined, size: 14, color: BldrColors.goldBright),
          const SizedBox(width: 4),
          Expanded(child: Text(when, maxLines: 1, overflow: TextOverflow.ellipsis, style: BldrText.meta)),
        ]),
      ]),
    );
  }
}

class _BillboardItem extends StatelessWidget {
  const _BillboardItem({required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final img = (data['image_url_main'] ?? data['image_url'] ?? '').toString().trim();
    final link = (data['link_url'] ?? '').toString().trim();
    final imageContent = SizedBox.expand(
      child: Image.network(img, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(alignment: Alignment.center, color: BldrColors.surfaceInset, child: const Icon(Icons.image, color: BldrColors.textMuted))),
    );
    if (link.isNotEmpty) {
      return InkWell(
        onTap: () async {
          final uri = Uri.tryParse(link);
          if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: imageContent,
      );
    }
    return imageContent;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.logoPath, this.logoHeight = 56});
  final String logoPath;
  final double logoHeight;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: logoHeight + 28,
    child: Center(child: Image.asset(logoPath, height: logoHeight, fit: BoxFit.contain)),
  );
}

// ── Operação da Semana (F21) ────────────────────────────────────────────────

class _WeeklyOperationCard extends StatefulWidget {
  const _WeeklyOperationCard();

  @override
  State<_WeeklyOperationCard> createState() => _WeeklyOperationCardState();
}

class _WeeklyOperationCardState extends State<_WeeklyOperationCard> {
  WeeklyOperation? _operation;
  OperationProgress? _progress;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final opResult = await getIt<GetCurrentOperation>()();
    final op = opResult.valueOrNull;
    if (op == null) {
      if (mounted) setState(() => _loaded = true);
      return;
    }
    final progResult = await getIt<GetOperationProgress>()(op.id);
    if (mounted) {
      setState(() {
        _operation = op;
        _progress = progResult.valueOrNull;
        _loaded = true;
      });
    }
  }

  String _unitLabel(String goalType) {
    switch (goalType) {
      case 'run_distance':
        return 'km';
      case 'calorie_goal':
        return 'kcal';
      default:
        return AppLocalizations.of(context).club_workouts_title.toLowerCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _operation == null) return const SizedBox.shrink();

    final op = _operation!;
    final current = _progress?.currentValue ?? 0;
    final completed = _progress?.completed ?? false;
    final ratio = op.goalValue > 0
        ? (current / op.goalValue).clamp(0.0, 1.0)
        : 0.0;
    final unit = _unitLabel(op.goalType);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BldrRadius.all(BldrRadius.cardLg),
        border: Border.all(color: BldrColors.goldBright, width: 1.5),
      ),
      child: BldrGlassCard(
        radius: BldrRadius.cardLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BldrBadge(label: AppLocalizations.of(context).club_weekly_operation),
                if (completed) ...[
                  const SizedBox(width: 8),
                  BldrBadge(label: AppLocalizations.of(context).club_operation_completed),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(op.title,
                style: BldrText.cardTitle.copyWith(fontSize: 16)),
            if (op.description != null && op.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(op.description!,
                  style: BldrText.meta
                      .copyWith(color: BldrColors.textMuted)),
            ],
            const SizedBox(height: 12),
            BldrProgressBar(value: ratio.toDouble(), gradient: !completed),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context).club_operation_progress(current, op.goalValue, unit),
                    style: BldrText.meta),
                Text(AppLocalizations.of(context).club_operation_xp_reward(op.xpReward),
                    style: BldrText.meta
                        .copyWith(color: BldrColors.goldBright)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelProgressCard extends StatelessWidget {
  const _LevelProgressCard({
    required this.level,
    required this.currentXP,
    required this.xpPerLevel,
    required this.progress,
    this.position,
  });
  final int level;
  final int currentXP;
  final int xpPerLevel;
  final double progress;
  // C2 — posição no ranking, no mesmo card do nível. Null enquanto carrega
  // ou se o usuário não aparece no recorte — não exibe número inventado.
  final int? position;

  @override
  Widget build(BuildContext context) {
    return BldrGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context).club_level(level), style: BldrText.cardTitleLg),
              if (position != null) BldrBadge(label: AppLocalizations.of(context).club_ranking_badge(position!)),
            ],
          ),
          const SizedBox(height: 12),
          BldrProgressBar(value: progress, gradient: true),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context).club_xp_progress(currentXP, xpPerLevel), style: BldrText.meta),
        ],
      ),
    );
  }
}

