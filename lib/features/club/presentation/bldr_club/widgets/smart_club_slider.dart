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

        String? arenaId;
        if (squadSnap.hasData && squadSnap.data!.isNotEmpty) {
          final part = squadSnap.data!.first;
          final status = (part['status'] ?? '').toString().toLowerCase();
          if (status == 'active') arenaId = part['arena_id'];
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: arenaId != null
              ? getIt<ArenaRepository>()
                  .arenaById(arenaId)
                  .then((r) => r.valueOrNull)
              : Future.value(null),
          builder: (context, arenaSnap) {
            Map<String, dynamic>? finalSquad;
            if (arenaSnap.hasData && arenaSnap.data != null) {
              finalSquad = {
                ...arenaSnap.data!,
                'name': arenaSnap.data!['title'],
                'is_danger': false,
              };
            }

            return SmartClubSlider(
              activeSquad: finalSquad,
              onTapSquad: () {
                if (arenaId != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ArenaDetailsScreen(arenaId: arenaId!)),
                  );
                }
              },
              onTapCreate: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CompetitionHubScreen())),
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
  final Map<String, dynamic>? activeSquad;
  final VoidCallback onTapSquad;
  final VoidCallback onTapCreate;

  const SmartClubSlider({
    Key? key,
    this.activeSquad,
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

    // 1. Squad em Risco
    if (widget.activeSquad != null &&
        widget.activeSquad!['is_danger'] == true) {
      pages.add(_buildSquadCard(isDanger: true));
    }

    // 2. Squad Normal
    if (widget.activeSquad != null &&
        widget.activeSquad!['is_danger'] != true) {
      pages.add(_buildSquadCard(isDanger: false));
    }

    // 4. Vazio
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
  Widget _buildSquadCard({required bool isDanger}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BldrSpacing.pageX),
      child: BldrGlassCard(
        onTap: widget.onTapSquad,
        borderColor: isDanger ? BldrColors.goldBorder : null,
        child: Row(
          children: [
            BldrIconBox(
                icon: isDanger ? Icons.warning_amber_rounded : Icons.shield_outlined),
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
                    widget.activeSquad!['name'] ?? 'Squad',
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