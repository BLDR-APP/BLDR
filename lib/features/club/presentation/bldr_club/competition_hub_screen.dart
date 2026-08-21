import 'package:flutter/material.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/domain/repositories/arena_repository.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/create_arena_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/join_squad_sheet.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/arena_details_screen.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

class CompetitionHubScreen extends StatefulWidget {
  const CompetitionHubScreen({super.key});

  @override
  State<CompetitionHubScreen> createState() => _CompetitionHubScreenState();
}

class _CompetitionHubScreenState extends State<CompetitionHubScreen> {
  static const gold = Color(0xFFD4AF37);

  bool _isLoading = true;
  List<Map<String, dynamic>> _mySquads = [];

  @override
  void initState() {
    super.initState();
    _fetchMySquads();
  }

  Future<void> _fetchMySquads() async {
    final userId = getIt<GetCurrentUser>()()?.id;
    if (userId == null) return;
    try {
      final result = await getIt<ArenaRepository>().mySquads();
      final squads = result.valueOrNull ?? <Map<String, dynamic>>[];
      if (mounted) {
        setState(() {
          _mySquads = squads;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData _getModeIcon(String mode) {
    switch (mode) {
      case 'survivor':   return Icons.dangerous;
      case 'hustle':     return Icons.bolt;
      case 'roadrunner': return Icons.directions_run;
      default:           return Icons.emoji_events; // alfa
    }
  }

  String _getModeLabel(String mode) {
    switch (mode) {
      case 'survivor':   return AppLocalizations.of(context).club_game_mode_survivor;
      case 'hustle':     return AppLocalizations.of(context).club_game_mode_hustle;
      case 'roadrunner': return AppLocalizations.of(context).club_game_mode_roadrunner;
      default:           return AppLocalizations.of(context).club_game_mode_alfa;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          AppLocalizations.of(context).club_competition_hub_title,
          style: const TextStyle(color: gold, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        centerTitle: true,
        leading: const BackButton(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CQ1 + CQ2: cards de ação
            Row(
              children: [
                // CRIAR (gold tint — CQ2)
                Expanded(
                  child: _ActionCard(
                    title: AppLocalizations.of(context).club_create_operation,
                    subtitle: AppLocalizations.of(context).club_be_the_leader,
                    icon: Icons.add_circle_outline,
                    borderColor: gold,
                    gradientColor: gold.withOpacity(0.12),
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateArenaScreen()));
                      _fetchMySquads();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // ALISTAR-SE (CQ1: neutro com gold border)
                Expanded(
                  child: _ActionCard(
                    title: AppLocalizations.of(context).club_join_now,
                    subtitle: AppLocalizations.of(context).club_enter_code,
                    icon: Icons.login,
                    borderColor: gold.withOpacity(0.4),
                    gradientColor: Colors.white.withOpacity(0.03),
                    onTap: () async {
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const JoinSquadSheet(),
                      );
                      _fetchMySquads();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 36),

            // CQ4: seção descritiva dos modos com ícones
            Text(
              AppLocalizations.of(context).club_game_modes_header,
              style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _ModeInfoCard(
              icon: Icons.dangerous,
              name: AppLocalizations.of(context).club_game_mode_survivor,
              description: AppLocalizations.of(context).club_survivor_description,
            ),
            _ModeInfoCard(
              icon: Icons.emoji_events,
              name: AppLocalizations.of(context).club_game_mode_alfa,
              description: AppLocalizations.of(context).club_alfa_description,
            ),
            _ModeInfoCard(
              icon: Icons.directions_run,
              name: AppLocalizations.of(context).club_game_mode_roadrunner,
              description: AppLocalizations.of(context).club_roadrunner_description,
            ),
            _ModeInfoCard(
              icon: Icons.bolt,
              name: AppLocalizations.of(context).club_game_mode_hustle,
              description: AppLocalizations.of(context).club_hustle_description,
            ),

            const SizedBox(height: 36),

            // CQ3: ranking interno — lista de squads (oculta se vazia com estado adequado)
            Text(
              AppLocalizations.of(context).club_my_active_squads,
              style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: gold))
            else if (_mySquads.isEmpty)
              _buildEmptyList()
            else
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _mySquads.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final squad = _mySquads[i];
                  final mode = squad['game_mode'] ?? 'alpha';
                  return _SquadListCard(
                    data: squad,
                    modeIcon: _getModeIcon(mode),
                    modeLabel: _getModeLabel(mode),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ArenaDetailsScreen(arenaId: squad['id']),
                      ));
                    },
                  );
                },
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox, color: Colors.white24, size: 40),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context).club_no_active_operation, style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color borderColor;
  final Color gradientColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.borderColor,
    required this.gradientColor,
    required this.onTap,
  });

  static const gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF121212), gradientColor],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: gold.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: gold, size: 24),
            ),
            const Spacer(),
            Flexible(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: gold,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeInfoCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String description;

  const _ModeInfoCard({
    required this.icon,
    required this.name,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(description,
                    style: const TextStyle(color: Colors.white54, fontSize: 11, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SquadListCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final IconData modeIcon;
  final String modeLabel;
  final VoidCallback onTap;

  const _SquadListCard({
    required this.data,
    required this.modeIcon,
    required this.modeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF101010),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Icon(modeIcon, color: Colors.white54, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(modeLabel,
                      style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                  const SizedBox(height: 4),
                  Text(data['title'] ?? 'Sem Nome',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}
