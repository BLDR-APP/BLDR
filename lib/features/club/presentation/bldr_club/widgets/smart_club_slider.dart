import 'package:flutter/material.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/domain/repositories/arena_repository.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
// AJUSTE OS IMPORTES PARA ONDE ESTÃO SUAS TELAS REAIS
import 'package:bldr_fitness/features/club/presentation/bldr_club/competition_hub_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/arena_details_screen.dart';

// =========================================================
// 1. O CÉREBRO (CONECTOR) - VERSÃO BAZUCA (SEM FILTRO DE STATUS NO BANCO)
// =========================================================
class ClubDashboardConnector extends StatelessWidget {
  const ClubDashboardConnector({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = getIt<GetCurrentUser>()()?.id;
    if (userId == null) return const SizedBox();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: getIt<ArenaRepository>().myParticipationStream(),
      builder: (context, squadSnap) {
        if (squadSnap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 90,
              child: Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFFD4AF37))));
        }

        // Collect all active participation arena IDs (may be >1)
        final activeParticipations = (squadSnap.data ?? [])
            .where((p) => (p['status'] ?? '').toString().toLowerCase() == 'active')
            .toList();

        // Fetch full arena data for each active participation
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: activeParticipations.isEmpty
              ? Future.value([])
              : Future.wait(
                  activeParticipations.map((p) async {
                    final arenaId = p['arena_id'] as String?;
                    if (arenaId == null) return null;
                    final result = await getIt<ArenaRepository>().arenaById(arenaId);
                    final arena = result.valueOrNull;
                    if (arena == null) return null;
                    return <String, dynamic>{
                      ...arena,
                      'name': arena['title'],
                      'is_danger': false,
                    };
                  }),
                ).then((list) => list.whereType<Map<String, dynamic>>().toList()),
          builder: (context, arenaSnap) {
            final squads = arenaSnap.data ?? [];

            return SmartClubSlider(
              activeSquads: squads,
              onTapSquad: (arenaId) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArenaDetailsScreen(arenaId: arenaId),
                  ),
                );
              },
              onTapCreate: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CompetitionHubScreen()),
              ),
            );
          },
        );
      },
    );
  }
}

// =========================================================
// 2. O ROSTO (VISUAL)
// =========================================================
class SmartClubSlider extends StatefulWidget {
  /// All active squads the user participates in (may be empty).
  final List<Map<String, dynamic>> activeSquads;
  final void Function(String arenaId) onTapSquad;
  final VoidCallback onTapCreate;

  const SmartClubSlider({
    Key? key,
    required this.activeSquads,
    required this.onTapSquad,
    required this.onTapCreate,
  }) : super(key: key);

  @override
  State<SmartClubSlider> createState() => _SmartClubSliderState();
}

class _SmartClubSliderState extends State<SmartClubSlider> {
  final PageController _controller = PageController();
  int _currentIndex = 0;
  List<Widget> _pages = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buildPages();
  }

  @override
  void didUpdateWidget(covariant SmartClubSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    _buildPages();
  }

  void _buildPages() {
    final List<Widget> pages = [];

    // One page per active squad
    for (final squad in widget.activeSquads) {
      final isDanger = squad['is_danger'] == true;
      pages.add(_buildSquadCard(squad: squad, isDanger: isDanger));
    }

    // Empty state when no squads
    if (pages.isEmpty) {
      pages.add(_buildEmptyState());
    }

    setState(() {
      _pages = pages;
      if (_currentIndex >= pages.length) _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          // C4 — altura maior + sem margem lateral nas páginas: o card
          // ocupa a largura inteira do viewport (`viewportFraction: 1`,
          // ver initState) para não ficar cortado na borda da tela.
          height: 92,
          child: PageView(
            controller: _controller,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            children: _pages,
          ),
        ),
        if (_pages.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                final bool isActive = _currentIndex == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 4,
                  width: isActive ? 16 : 4,
                  decoration: BoxDecoration(
                    color: isActive ? BldrColors.goldBright : BldrColors.track,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  // C4 + G4/G8 — cartão sem corte na borda (padding consistente com o resto
  // da tela, não mais `margin: 4`) e sem vermelho: "risco de eliminação" é
  // um estado informativo, não punitivo (mesma regra já aplicada a "Não
  // feito" em Meu Plano). A distinção do estado de risco vem do ícone e do
  // badge, nunca só da cor — regra de acessibilidade do design system.
  Widget _buildSquadCard({
    required Map<String, dynamic> squad,
    required bool isDanger,
  }) {
    final arenaId = (squad['id'] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BldrSpacing.pageX),
      child: BldrGlassCard(
        onTap: () => widget.onTapSquad(arenaId),
        borderColor: isDanger ? BldrColors.goldBorder : null,
        child: Row(
          children: [
            BldrIconBox(
              icon: isDanger ? Icons.warning_amber_rounded : Icons.shield_outlined,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDanger ? 'Risco de eliminação' : 'Squad operante',
                    style: BldrText.label,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (squad['name'] ?? 'Squad').toString(),
                    style: BldrText.cardTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isDanger) const BldrBadge(label: 'Treine!'),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BldrSpacing.pageX),
      child: BldrGlassCard(
        onTap: widget.onTapCreate,
        child: Row(
          children: [
            const BldrIconBox(icon: Icons.add),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sem operação ativa', style: BldrText.cardTitle),
                  const SizedBox(height: 2),
                  Text('Crie ou junte-se a um squad', style: BldrText.meta),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: BldrColors.textMuted, size: 12),
          ],
        ),
      ),
    );
  }
}