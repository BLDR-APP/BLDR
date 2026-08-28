// lib/screens/bldr_club/esportes_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/services/user_service.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/havok/havok_sheet.dart';
// import 'package:bldr_fitness/features/club/presentation/bldr_club/plano_performance_detail_screen.dart'; // DESABILITADO — ver TODO acima
import 'package:bldr_fitness/features/club/presentation/bldr_club/corrida/run_card_widget.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/trackers/round_timer_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/trackers/match_tracker_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/trackers/tracker_storage.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

// ===================================================================
// MODELO (Mantido)
// ===================================================================
class PerformancePlan {
  final String id;
  final String sport;
  final String title;
  final String subtitle;
  final String sportContextTag;
  final Map<String, dynamic> planJson;

  PerformancePlan({
    required this.id,
    required this.sport,
    required this.title,
    required this.subtitle,
    required this.sportContextTag,
    required this.planJson,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sport': sport,
      'title': title,
      'subtitle': subtitle,
      'sportContextTag': sportContextTag,
      'planJson': planJson,
    };
  }

  factory PerformancePlan.fromJson(Map<String, dynamic> json) {
    return PerformancePlan(
      id: json['id'],
      sport: json['sport'],
      title: json['title'],
      subtitle: json['subtitle'],
      sportContextTag: json['sportContextTag'],
      planJson: json['planJson'] as Map<String, dynamic>,
    );
  }

  int get totalDays => planJson.keys.where((k) => k.startsWith('dia_')).length;
}

class EsportesScreen extends StatefulWidget {
  const EsportesScreen({super.key});

  @override
  State<EsportesScreen> createState() => _EsportesScreenState();
}

class _EsportesScreenState extends State<EsportesScreen> {
  bool _isLoading = true;
  bool _isGeneratingPlan = false;

  List<String> _userSports = [];
  List<PerformancePlan> _generatedPlans = [];

  // Protocol day progress cache: planId -> currentDay
  final Map<String, int> _protocolDays = {};

  @override
  void initState() {
    super.initState();
    _loadDataFromSupabase();
  }

  // ===================================================================
  // Lógica de Carregamento (Mantida)
  // ===================================================================
  Future<void> _loadDataFromSupabase() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final user = getIt<GetCurrentUser>()();
      if (user == null) throw Exception('Nenhum usuário logado.');

      final profileData = await getIt<UserService>().getSportsProfileData();
      if (profileData == null) throw Exception('Perfil não encontrado.');

      List<String> sports = [];
      if (profileData['onboarding_data'] != null) {
        final onboardingData = profileData['onboarding_data'] as Map<String, dynamic>;
        if (onboardingData.containsKey('activity_details')) {
          final activityDetailsMap = onboardingData['activity_details'] as Map<String, dynamic>?;
          if (activityDetailsMap != null) {
            sports = activityDetailsMap.keys
                .where((s) => s.toLowerCase() != 'musculação')
                .toList();
          }
        }
      }

      List<PerformancePlan> savedPlans = [];
      if (profileData['performance_plans'] != null) {
        final plansData = profileData['performance_plans'] as List;
        savedPlans = plansData
            .map((planJson) => PerformancePlan.fromJson(planJson as Map<String, dynamic>))
            .toList();
      }

      // Cache active sports so trackers can check without Supabase
      await TrackerStorage.saveActiveSports(
          savedPlans.map((p) => p.sport).toList());

      // Load protocol days for all plans
      final Map<String, int> days = {};
      for (final plan in savedPlans) {
        days[plan.id] = await TrackerStorage.getProtocolCurrentDay(plan.id);
      }

      if (mounted) {
        setState(() {
          _userSports = sports;
          _generatedPlans = savedPlans;
          _protocolDays.addAll(days);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro loadData: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  // ===================================================================
  // Lógica de Geração e Salvamento (Mantida)
  // ===================================================================
  Future<void> _handleGeneratePerformancePlan(String sport) async {
    final sportName = sport.trim();
    if (sportName.isEmpty) return;

    setState(() => _isGeneratingPlan = true);

    try {
      final data =
          await getIt<UserService>().generatePerformancePlan(sportName);

      final newPlan = PerformancePlan.fromJson(data);
      await _savePlanToSupabase(newPlan);

      if (mounted) {
        setState(() {
          _generatedPlans.add(newPlan);
          _protocolDays[newPlan.id] = 1;
          _isGeneratingPlan = false;
        });
      }
    } catch (e) {
      debugPrint('Erro gerar plano: $e');
      if (mounted) {
        setState(() => _isGeneratingPlan = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _savePlanToSupabase(PerformancePlan newPlan) async {
    try {
      final user = getIt<GetCurrentUser>()();
      if (user == null) return;

      final List<PerformancePlan> currentPlans = List.from(_generatedPlans);
      if (!currentPlans.any((p) => p.id == newPlan.id)) {
        currentPlans.add(newPlan);
      }

      final List<Map<String, dynamic>> jsonData =
          currentPlans.map((p) => p.toJson()).toList();

      await getIt<UserService>().updatePerformancePlans(jsonData);
    } catch (e) {
      debugPrint('Erro salvar plano: $e');
    }
  }

  // ===================================================================
  // BUILD PRINCIPAL
  // ===================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BldrColors.bgBase,
      // G1 — fundo decorativo virou BldrBackground.
      body: BldrBackground(
        child: Stack(
          children: [
            SafeArea(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: BldrColors.goldBright))
                  : CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // Header — logo mantida como está (asset), só o
                        // fundo ao redor virou BldrBackground.
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: _Header(
                              logoPath: 'assets/images/BLDR CLUB_ESPORTES.png',
                              logoHeight: 160,
                              showBackButton: true,
                            ),
                          ),
                        ),
                        // Conteúdo
                        ..._buildContentSlivers(_userSports),
                      ],
                    ),
            ),
            if (_isGeneratingPlan) _buildLoadingModal(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContentSlivers(List<String> userSports) {
    final List<Widget> slivers = [];

    // 1. Título da seção
    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Center(
            child: Text(
              AppLocalizations.of(context).sports_title,
              textAlign: TextAlign.center,
              style: BldrText.screenTitle,
            ),
          ),
        ),
      ),
    );

    // 2. BLOCO 1 — BLDR RUN (RunCardWidget). Card em si vive em outro
    // arquivo (corrida/run_card_widget.dart), fora do escopo desta tarefa.
    slivers.add(
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: RunCardWidget(),
        ),
      ),
    );

    // 2b. F20 — resumo semanal
    slivers.add(
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: _WeeklySummaryCard(),
        ),
      ),
    );

    // ─── PROTOCOLOS HAVOK — TEMPORARIAMENTE DESABILITADO ──────────────────────
    // TODO: Refatorar antes de reativar. Problemas conhecidos:
    // 1. Estado do checklist (_checked) é local e não persistido — reseta ao sair
    // 2. TrackerStorage usa SharedPreferences sem verificação de data — dia atual
    //    não reseta com o calendário
    // 3. Sem tabela de progresso no Supabase — impossível sincronizar entre
    //    dispositivos ou recuperar após reinstall
    // 4. Checklist "conclui tudo" ao abrir — bug de estado
    //
    // Para reativar: criar tabela protocol_progress no Supabase, persistir
    // _checked por exercício, adicionar reset diário automático.
    // slivers.add(_buildProtocolosSectionSliver());

    // 4. BLOCO 3 — TRACKERS (novo)
    slivers.add(_buildTrackersSectionSliver());

    // 5. BLOCO 4 — DESAFIE O HAVOK (expandido)
    if (userSports.isEmpty) {
      slivers.add(_buildHavokSliver(context));
    } else if (userSports.length == 1) {
      slivers.add(_buildScenarioBSliver(context, userSports));
    } else {
      slivers.add(_buildScenarioASliver(context, userSports));
    }

    return slivers;
  }

  // ===================================================================
  // BLOCO 2 — PROTOCOLOS ATIVOS
  // ===================================================================
  // CE2 — carrossel horizontal, só aparece quando há protocolo ativo
  // (elemento sem dado fica oculto, não removido).
  Widget _buildProtocolosSectionSliver() {
    if (_generatedPlans.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(AppLocalizations.of(context).sports_active_protocols, style: BldrText.sectionTitle),
            ),
            const SizedBox(height: 12),
            BldrCarousel(
              height: 128,
              itemWidth: 215,
              children: _generatedPlans.map(_buildPerformanceCard).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // CE2 — card compacto de carrossel (~215×120): nome, "Dia X de Y · Z%"
  // (dinâmico) com BldrProgressBar, tint dourado (protocolo ativo).
  Widget _buildPerformanceCard(PerformancePlan plan) {
    final currentDay = _protocolDays[plan.id] ?? 1;
    final totalDays = plan.totalDays > 0 ? plan.totalDays : 4;
    final progress = currentDay / totalDays;
    final trackerLabel = _trackerLabelForSport(plan.sport);

    return BldrGlassCard(
      background: BldrColors.goldTintStrong,
      borderColor: BldrColors.goldBorder,
      // onTap desabilitado — PlanoPerformanceDetailScreen fora de serviço (ver TODO)
      onTap: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _sportIconWidget(plan.sport, size: 14, color: BldrColors.goldBright),
              const SizedBox(width: 6),
              Expanded(
                child: Text(plan.sport,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BldrText.cardTitle),
              ),
              GestureDetector(
                onTap: () async {
                  final confirm = await _confirmDelete(plan);
                  if (confirm == true) await _deletePlan(plan);
                },
                child: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            trackerLabel ?? plan.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BldrText.meta,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dia $currentDay de $totalDays', style: BldrText.metaSm),
              Text('${(progress * 100).round()}%', style: BldrText.metaSm),
            ],
          ),
          const SizedBox(height: 6),
          BldrProgressBar(value: progress),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(PerformancePlan plan) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Excluir protocolo?',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Text(
          'O protocolo "${plan.title}" será removido permanentemente.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePlan(PerformancePlan plan) async {
    setState(() {
      _generatedPlans.removeWhere((p) => p.id == plan.id);
      _protocolDays.remove(plan.id);
    });
    await Future.wait([
      getIt<UserService>().updatePerformancePlans(
        _generatedPlans.map((p) => p.toJson()).toList(),
      ),
      TrackerStorage.clearProtocolState(plan.id),
    ]);
  }

  String? _trackerLabelForSport(String sport) {
    final s = sport.toLowerCase();
    if (['boxe', 'mma', 'jiu jitsu', 'muay thai'].any((e) => s.contains(e))) {
      return 'Round Timer';
    }
    if (['tênis', 'padel'].any((e) => s.contains(e))) return 'Match Tracker';
    if (s.contains('natação')) return 'Pool Tracker';
    if (s.contains('crossfit')) return 'WOD Timer';
    if (s.contains('yoga')) return 'Yoga Tracker';
    return null;
  }

  /// Returns a correctly-themed FA icon for a given sport name.
  Widget _sportIconWidget(String sport,
      {double size = 16, Color color = const Color(0xFFD4AF37)}) {
    final s = sport.toLowerCase();
    FaIconData icon;
    if (s.contains('boxe') || s.contains('muay')) {
      icon = FontAwesomeIcons.handFist;
    } else if (s.contains('mma') || s.contains('jiu')) {
      icon = FontAwesomeIcons.personFalling;
    } else if (s.contains('tênis') || s.contains('padel') ||
        s.contains('beach tennis')) {
      icon = FontAwesomeIcons.tableTennisPaddleBall;
    } else if (s.contains('natação')) {
      icon = FontAwesomeIcons.personSwimming;
    } else if (s.contains('crossfit')) {
      icon = FontAwesomeIcons.dumbbell;
    } else if (s.contains('yoga')) {
      icon = FontAwesomeIcons.spa;
    } else if (s.contains('corrida') || s.contains('atletismo')) {
      icon = FontAwesomeIcons.personRunning;
    } else if (s.contains('ciclismo') || s.contains('bike')) {
      icon = FontAwesomeIcons.personBiking;
    } else if (s.contains('escalada')) {
      icon = FontAwesomeIcons.mountain;
    } else if (s.contains('futebol')) {
      icon = FontAwesomeIcons.futbol;
    } else if (s.contains('basquete') || s.contains('basketball')) {
      icon = FontAwesomeIcons.basketball;
    } else if (s.contains('vôlei') || s.contains('volei')) {
      icon = FontAwesomeIcons.volleyball;
    } else if (s.contains('musculação') || s.contains('academia')) {
      icon = FontAwesomeIcons.dumbbell;
    } else {
      icon = FontAwesomeIcons.trophy;
    }
    return FaIcon(icon, color: color, size: size);
  }

  // ===================================================================
  // BLOCO 3 — TRACKERS (novo)
  // ===================================================================
  Widget _buildTrackersSectionSliver() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(AppLocalizations.of(context).sports_trackers, style: BldrText.sectionTitle),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTrackerCard(
                iconWidget: const FaIcon(FontAwesomeIcons.handFist,
                    color: BldrColors.goldBright, size: 22),
                title: 'Round Timer',
                subtitle: AppLocalizations.of(context).sports_round_timer_subtitle,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RoundTimerScreen()),
                ),
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildTrackerCard(
                iconWidget: const FaIcon(FontAwesomeIcons.tableTennisPaddleBall,
                    color: BldrColors.goldBright, size: 22),
                title: 'Match Tracker',
                subtitle: AppLocalizations.of(context).sports_match_tracker_subtitle,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MatchTrackerScreen()),
                ),
              )),
            ],
          ),
        ]),
      ),
    );
  }

  // CE3 — card inteiro clicável, sem botão "ACESSAR" solto.
  Widget _buildTrackerCard({
    required Widget iconWidget,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return BldrGlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: BldrColors.goldTint,
              borderRadius: BldrRadius.all(BldrRadius.iconBox),
            ),
            child: Center(child: iconWidget),
          ),
          const SizedBox(height: 12),
          Text(title, style: BldrText.cardTitle),
          const SizedBox(height: 4),
          Text(subtitle, style: BldrText.meta),
        ],
      ),
    );
  }

  // ===================================================================
  // BLOCO 4 — CENÁRIOS COM HAVOK (expandido)
  // ===================================================================
  Widget _buildScenarioASliver(BuildContext context, List<String> userSports) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(AppLocalizations.of(context).sports_detected, style: BldrText.label),
          const SizedBox(height: 12),
          ...userSports.map((sport) {
            if (sport == 'Outro') return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildSportButton(context, sport),
            );
          }),
          const SizedBox(height: 24),
          HavokInputWidget(onGenerate: _handleGeneratePerformancePlan),
        ]),
      ),
    );
  }

  Widget _buildScenarioBSliver(BuildContext context, List<String> userSports) {
    final sport = userSports.first;
    if (sport == 'Outro') return _buildHavokSliver(context);

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(AppLocalizations.of(context).sports_recommended, style: BldrText.label),
          const SizedBox(height: 12),
          _buildSportButton(context, sport),
          const SizedBox(height: 32),
          HavokInputWidget(onGenerate: _handleGeneratePerformancePlan),
        ]),
      ),
    );
  }

  Widget _buildHavokSliver(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          HavokInputWidget(onGenerate: _handleGeneratePerformancePlan),
        ]),
      ),
    );
  }

  Widget _buildSportButton(BuildContext context, String sport) {
    // G8 — sentence case ("Gerar protocolo", não "Gerar Protocolo").
    return BldrPrimaryButton(
      label: 'Gerar protocolo para $sport',
      onPressed: () => _handleGeneratePerformancePlan(sport),
    );
  }

  Widget _buildLoadingModal() {
    return Container(
      color: Colors.black.withOpacity(0.90),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: BldrColors.goldBright),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).sports_havok_processing,
              textAlign: TextAlign.center,
              style: BldrText.cardTitleLg,
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).sports_creating_strategy,
              textAlign: TextAlign.center,
              style: BldrText.description,
            ),
          ],
        ),
      ),
    );
  }
}

// ===================================================================
// WIDGET HAVOK INPUT — expandido
// ===================================================================
class HavokInputWidget extends StatefulWidget {
  final Function(String) onGenerate;

  const HavokInputWidget({super.key, required this.onGenerate});

  @override
  State<HavokInputWidget> createState() => _HavokInputWidgetState();
}

class _HavokInputWidgetState extends State<HavokInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _suggestions = [
    'Natação', 'Crossfit', 'Jiu Jitsu', 'Yoga', 'Atletismo', 'Escalada'
  ];
  String? _selectedSuggestion;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) widget.onGenerate(text);
  }

  @override
  Widget build(BuildContext context) {
    return BldrGlassCard(
      radius: BldrRadius.cardLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              BldrIconBox(icon: Icons.star),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context).sports_challenge_havok, style: BldrText.cardTitleLg),
                    const SizedBox(height: 2),
                    Text(AppLocalizations.of(context).sports_generate_workout,
                        style: BldrText.meta.copyWith(
                            color: BldrColors.goldBright,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context).sports_select_sport, style: BldrText.description),
          const SizedBox(height: 16),

          // CE4 — chips via BldrChip.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((sport) {
              final isSelected = _selectedSuggestion == sport;
              return BldrChip(
                label: sport,
                active: isSelected,
                onTap: () {
                  setState(() {
                    _selectedSuggestion = sport;
                    _controller.text = sport;
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Campo de texto
          Container(
            decoration: BoxDecoration(
              color: BldrColors.surfaceInset,
              borderRadius: BldrRadius.all(BldrRadius.input),
              border: Border.all(color: BldrColors.border),
            ),
            child: TextField(
              controller: _controller,
              style: BldrText.body,
              cursorColor: BldrColors.goldBright,
              onChanged: (val) {
                if (_selectedSuggestion != null && val != _selectedSuggestion) {
                  setState(() => _selectedSuggestion = null);
                }
              },
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).sports_other_sport_hint,
                hintStyle: BldrText.body.copyWith(color: BldrColors.textMuted),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward,
                      color: BldrColors.goldBright),
                  onPressed: _submit,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Botão principal — G8 sentence case ("Gerar estratégia").
          BldrPrimaryButton(
            label: AppLocalizations.of(context).sports_generate_strategy,
            icon: Icons.bolt,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

// ====================== UI COMPONENTES AUXILIARES (Mantidos) ======================

class _Header extends StatelessWidget {
  const _Header(
      {required this.logoPath,
      this.logoHeight = 56,
      this.showBackButton = false});
  final String logoPath;
  final double logoHeight;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: logoHeight + 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showBackButton)
            Positioned(
              left: 0,
              child: BldrCircleButton(
                icon: Icons.chevron_left,
                size: 38,
                filled: false,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          Center(
              child: Image.asset(logoPath,
                  height: logoHeight, fit: BoxFit.contain)),
          Positioned(
            right: 0,
            child: HavokEntryIcon(
              onTap: () => showHavokSheet(context, originScreen: 'club_esportes'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── F20 — Resumo semanal ─────────────────────────────────────────────────────

class _WeeklySummaryCard extends StatefulWidget {
  const _WeeklySummaryCard();

  @override
  State<_WeeklySummaryCard> createState() => _WeeklySummaryCardState();
}

class _WeeklySummaryCardState extends State<_WeeklySummaryCard> {
  bool _loading = true;
  int _runCount = 0;
  int _runActiveSeconds = 0;
  double _bestRunKm = 0;
  int _matchCount = 0;
  int _matchActiveSeconds = 0;
  int _roundCount = 0;
  int _roundActiveSeconds = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final weekStart = _startOfWeek(DateTime.now());

    // Corridas do Supabase
    try {
      final result = await getIt<GetRunActivities>()(limit: 50);
      final runs = result.valueOrNull ?? [];
      final weekRuns = runs.where((r) {
        final d = r.createdAt;
        return d != null && !d.isBefore(weekStart);
      }).toList();
      int runSec = 0;
      double bestKm = 0;
      for (final r in weekRuns) {
        runSec += r.durationSeconds ?? 0;
        final km = ((r.distanceMeters ?? 0) / 1000);
        if (km > bestKm) bestKm = km;
      }
      _runCount = weekRuns.length;
      _runActiveSeconds = runSec;
      _bestRunKm = bestKm;
    } catch (_) {}

    // Dados locais de outros trackers
    Future<_TrackerStats> _readLocal(String key) async {
      final history = await TrackerStorage.getHistory(key);
      final weekSessions = history.where((s) {
        final raw = s['savedAt'] as String?;
        if (raw == null) return false;
        final d = DateTime.tryParse(raw);
        return d != null && !d.isBefore(weekStart);
      }).toList();
      final totalSec = weekSessions.fold<int>(
        0,
        (acc, s) => acc + ((s['elapsedSeconds'] as num?)?.toInt() ?? 0),
      );
      return _TrackerStats(count: weekSessions.length, seconds: totalSec);
    }

    final matchStats = await _readLocal('match_Tênis');
    final matchStats2 = await _readLocal('match_Padel');
    final matchStats3 = await _readLocal('match_Beach Tennis');
    final roundStats = await _readLocal('round_Boxe');
    final roundStats2 = await _readLocal('round_MMA');

    if (mounted) {
      setState(() {
        _matchCount = matchStats.count + matchStats2.count + matchStats3.count;
        _matchActiveSeconds = matchStats.seconds + matchStats2.seconds + matchStats3.seconds;
        _roundCount = roundStats.count + roundStats2.count;
        _roundActiveSeconds = roundStats.seconds + roundStats2.seconds;
        _loading = false;
      });
    }
  }

  DateTime _startOfWeek(DateTime d) {
    // Monday as first day
    final weekday = d.weekday; // 1=Mon, 7=Sun
    return DateTime(d.year, d.month, d.day - (weekday - 1));
  }

  String _fmtTime(int sec) {
    if (sec == 0) return '0min';
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    if (h > 0) return '${h}h${m > 0 ? ' ${m}min' : ''}';
    return '${m}min';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    final totalSec = _runActiveSeconds + _matchActiveSeconds + _roundActiveSeconds;
    final hasSomething =
        _runCount > 0 || _matchCount > 0 || _roundCount > 0;

    if (!hasSomething) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  color: BldrColors.goldBright, size: 18),
              const SizedBox(width: 10),
              Text(AppLocalizations.of(context).sports_weekly, style: BldrText.cardTitle),
            ],
          ),
          const SizedBox(height: 14),
          // Total time
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.white38, size: 14),
              const SizedBox(width: 6),
              Text('Tempo ativo: ${_fmtTime(totalSec)}',
                  style: BldrText.body.copyWith(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 10),
          // Sessions by type
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (_runCount > 0)
                _sessionChip(Icons.directions_run, '$_runCount corrida${_runCount == 1 ? '' : 's'}'),
              if (_matchCount > 0)
                _sessionChip(Icons.sports_tennis, '$_matchCount partida${_matchCount == 1 ? '' : 's'}'),
              if (_roundCount > 0)
                _sessionChip(Icons.sports_mma, '$_roundCount round${_roundCount == 1 ? '' : 's'}'),
            ],
          ),
          if (_bestRunKm > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.emoji_events_outlined,
                    color: BldrColors.goldBright, size: 14),
                const SizedBox(width: 6),
                Text('Recorde: ${_bestRunKm.toStringAsFixed(2)} km',
                    style: BldrText.meta.copyWith(color: BldrColors.goldBright)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context).sports_corridas_sync,
            style: BldrText.metaSm.copyWith(color: Colors.white.withOpacity(0.25)),
          ),
        ],
      ),
    );
  }

  Widget _sessionChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white54, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _TrackerStats {
  final int count;
  final int seconds;
  const _TrackerStats({required this.count, required this.seconds});
}

