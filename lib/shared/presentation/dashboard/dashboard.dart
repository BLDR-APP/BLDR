import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/models/subscription_plan.dart';
import 'package:bldr_fitness/models/user_profile.dart';
import 'package:bldr_fitness/services/popup_service.dart';
import 'package:bldr_fitness/services/user_service.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/subscription_usecases.dart'
    as subUc;
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart'
    as clubUc;
import 'package:bldr_fitness/features/workouts/domain/usecases/workout_usecases.dart'
    as uc;
import 'package:bldr_fitness/widgets/review_modal.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/bldr_club_screen.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/comunidade_screen.dart';
import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/nutrition_screen.dart';
import 'package:bldr_fitness/features/profile/presentation/profile_drawer/profile_screen.dart';
import 'package:bldr_fitness/features/subscription/presentation/paywall/club_paywall_sheet.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/workouts_screen.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/widgets/active_workout_card_widget.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/widgets/level_xp_strip_widget.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/widgets/consistency_heatmap_widget.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/widgets/goal_card_widget.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/widgets/greeting_header_widget.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/widgets/havok_insight_widget.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/widgets/whoop_dashboard_widget.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/widgets/nutrition_progress_widget.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/widgets/partnership_widget.dart';
import 'package:bldr_fitness/features/integrations/data/widget_data_service.dart';
import 'package:bldr_fitness/shared/presentation/widgets/bldr_mini_player.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/widgets/today_metrics_widget.dart';
import 'package:bldr_fitness/features/whats_new/domain/usecases/whats_new_usecases.dart';
import 'package:bldr_fitness/features/whats_new/presentation/whats_new_sheet.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  late TabController _tabController;

  UserProfile? _userProfile;
  UserSubscription? _userSubscription; // VARIÁVEL ADICIONADA
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadUserData();
    unawaited(WidgetDataService.updateAll());
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkWhatsNew());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkWhatsNew() async {
    final data = await getIt<GetWhatsNew>()();
    if (data == null || !mounted) return;
    await showWhatsNewSheet(context, data, onDismiss: () {
      getIt<MarkWhatsNewSeen>()(data.id);
    });
  }

  // FUNÇÃO ATUALIZADA PARA BUSCAR PERFIL E ASSINATURA
  Future<void> _loadUserData() async {
    if (!_isLoading) {
      setState(() => _isLoading = true);
    }
    try {
      // Busca o perfil e a assinatura em paralelo para mais performance.
      // Timeout de 8s POR CHAMADA (não no Future.wait): se uma travar, a
      // outra continua valendo e a tela renderiza com o que chegou — nunca
      // fica presa no spinner esperando uma chamada que nunca retorna.
      final results = await Future.wait([
        UserService.instance
            .getCurrentUserProfile()
            .timeout(const Duration(seconds: 8), onTimeout: () => null),
        getIt<subUc.GetCurrentSubscription>()()
            .then((r) => r.valueOrNull)
            .timeout(const Duration(seconds: 8), onTimeout: () => null),
      ]);

      if (mounted) {
        setState(() {
          _userProfile = results[0] as UserProfile?;
          _userSubscription = results[1] as UserSubscription?;
          _isLoading = false;
        });
      }

      // Verifica critérios do pop-up de avaliação após carregamento
      Future.delayed(const Duration(seconds: 2), _checkReviewCriteria);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _checkReviewCriteria() async {
    if (!mounted) return;
    try {
      final shouldShow = await PopupService.shouldShowReviewPopup();
      if (!shouldShow || !mounted) return;

      final workoutsResult = await getIt<clubUc.GetConsolidatedWorkoutHistory>()(
        completedOnly: true,
        limit: 30,
      );
      final workouts = workoutsResult.valueOrNull ?? [];

      // Critério: 3 ou mais treinos concluídos
      if (workouts.length >= 3 && mounted) {
        await ReviewModal.show(context);
        return;
      }

      // Critério: streak de 5 dias seguidos
      final workedDays = workouts
          .map((w) {
            final dt = w.completedAt?.toLocal();
            if (dt == null) return null;
            return DateTime(dt.year, dt.month, dt.day);
          })
          .whereType<DateTime>()
          .toSet();

      int streak = 0;
      var day = DateTime.now();
      day = DateTime(day.year, day.month, day.day);
      while (workedDays.contains(day)) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      }
      if (streak >= 5 && mounted) {
        await ReviewModal.show(context);
        return;
      }

      // Critério: 7 dias distintos de uso ativo
      if (workedDays.length >= 7 && mounted) {
        await ReviewModal.show(context);
      }
    } catch (_) {}
  }

  // NOVO GETTER PARA VERIFICAR SE O USUÁRIO É PREMIUM
  bool get _isPremium {
    if (_userSubscription == null) return false;
    return _userSubscription!.status == 'active';
  }

  // FUNÇÃO ATUALIZADA PARA BLOQUEAR A ABA BLDR CLUB
  void _onTabSelected(int index) {
    // O índice da aba 'BLDR CLUB' é 3 (Comunidade entrou como aba 2, sem
    // paywall — gates de feature ficam dentro da própria CommunityScreen).
    if (index == 3 && !_isPremium) {
      // Se o usuário não for premium e clicar na aba do Club, mostre o paywall
      _showClubPaywall();
      return; // Impede a troca de aba
    }

    setState(() {
      _selectedIndex = index;
    });
    _tabController.animateTo(index);
  }

  /// Paywall do BLDR Club — bottom sheet único (substitui o antigo popup
  /// "Exclusivo para Membros" + tela de Checkout separada).
  void _showClubPaywall() {
    ClubPaywallSheet.show(
      context,
      onSubscribed: () {
        // Assinatura confirmada: recarrega o estado e já leva para a aba.
        _loadUserData().then((_) {
          if (mounted) _onTabSelected(3);
        });
      },
    );
  }

  void _startWorkout() async {
    try {
      final templatesResult =
          await getIt<uc.GetWorkoutTemplates>()(publicOnly: true);
      final workouts = templatesResult.valueOrNull ?? [];
      if (workouts.isNotEmpty) {
        Navigator.pushNamed(context, AppRoutes.workoutsScreen);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).dashboard_no_workouts_available),
            backgroundColor: AppTheme.warningAmber,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar treinos: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  void _logMeal() {
    Navigator.pushNamed(context, AppRoutes.nutritionScreen);
  }

  void _viewProgress() {
    Navigator.pushNamed(context, AppRoutes.progressScreen);
  }

  void _quickLog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.dividerGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              AppLocalizations.of(context).dashboard_quick_log_title,
              style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(
                    child: _buildQuickLogOption(
                        AppLocalizations.of(context).dashboard_quick_log_meal,
                        'restaurant',
                        AppTheme.successGreen,
                        _logMeal)),
                SizedBox(width: 3.w),
                Expanded(
                    child: _buildQuickLogOption(
                        AppLocalizations.of(context)
                            .dashboard_quick_log_workout,
                        'fitness_center',
                        AppTheme.accentGold,
                        _startWorkout)),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildQuickLogOption(
                      AppLocalizations.of(context).dashboard_quick_log_weight,
                      'monitor_weight',
                      AppTheme.warningAmber, () async {
                    Navigator.pop(context);
                    try {
                      Navigator.pushNamed(context, AppRoutes.progressScreen);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Erro ao abrir registro de peso: $e'),
                          backgroundColor: AppTheme.errorRed));
                    }
                  }),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildQuickLogOption(
                      AppLocalizations.of(context).dashboard_quick_log_water,
                      'local_drink',
                      Colors.blue, () async {
                    Navigator.pop(context);
                    try {
                      Navigator.pushNamed(context, AppRoutes.nutritionScreen);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Erro ao abrir registro de água: $e'),
                          backgroundColor: AppTheme.errorRed));
                    }
                  }),
                ),
              ],
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLogOption(
      String title, String icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerGray),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(iconName: icon, color: color, size: 6.w),
            ),
            SizedBox(height: 2.h),
            Text(
              title,
              style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Índice do BldrNavBar (0..4) a partir do índice de aba (0..5).
  /// A aba 3 é o Club, que na nav bar é o botão central — nesse caso
  /// nenhum item lateral fica ativo (-1).
  /// NavBar: 0=Home, 1=Treinos, 2=Comunidade, 3=Nutrição, 4=Perfil.
  int get _navIndex {
    switch (_selectedIndex) {
      case 0:
        return 0; // Home
      case 1:
        return 1; // Treinos
      case 2:
        return 2; // Comunidade
      case 4:
        return 3; // Nutrição
      case 5:
        return 4; // Perfil
      default:
        return -1; // Club (botão central)
    }
  }

  /// Índice de aba (0..5) a partir do índice do BldrNavBar (0..4).
  int _tabFromNav(int navIndex) {
    switch (navIndex) {
      case 0:
        return 0; // Home
      case 1:
        return 1; // Treinos
      case 2:
        return 2; // Comunidade
      case 3:
        return 4; // Nutrição
      default:
        return 5; // Perfil
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: BldrColors.bgBase,
      extendBody: true,
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildDashboardTab(), // 0
              const WorkoutsScreen(), // 1
              ComunidadeScreen(onBack: () => _onTabSelected(0)), // 2
              const BldrClubScreen(), // 3
              const NutritionScreen(), // 4
              const ProfileScreen(), // 5
            ],
          ),
          const BldrMiniPlayer(),
        ],
      ),
      // G5 — tab bar em glass, flutuando sobre o conteúdo rolável.
      bottomNavigationBar: BldrNavBar(
        selectedIndex: _navIndex,
        onChanged: (i) => _onTabSelected(_tabFromNav(i)),
        onClubTap: () => _onTabSelected(3),
        clubLogo: Image.asset(
          'assets/images/BLDR_CLUB.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    // G1 — fundo #050505 com glow radial dourado no topo.
    return BldrBackground(
      child: SafeArea(
        bottom: false,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: BldrColors.goldBright),
              )
            : RefreshIndicator(
                onRefresh: _loadUserData,
                color: BldrColors.goldBright,
                backgroundColor: BldrColors.surface,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(
                    bottom: BldrSpacing.navClearance,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ordem final (REDESIGN_SPEC, seção Dashboard):
                      // header → nível/XP → chips → hero do treino → grid 2×2.

                      // D1 — header compacto: saudação + nome + avatar.
                      const GreetingHeaderWidget(),

                      // D2 — faixa fina de Nível/XP abaixo do nome.
                      const LevelXpStripWidget(),

                      const SizedBox(height: BldrSpacing.gapSection),

                      // D3 — fileira de chips roláveis.
                      const TodayMetricsWidget(),

                      const SizedBox(height: BldrSpacing.gapSection),

                      // Whoop — Recovery/Strain/Sleep (máx. 1x a cada 30min).
                      const WhoopDashboardWidget(),

                      const SizedBox(height: BldrSpacing.gapSection),

                      // D4 — card hero "Treino de hoje" com botão interno.
                      ActiveWorkoutCardWidget(onStartPressed: _startWorkout),

                      const SizedBox(height: BldrSpacing.gapSection),

                      // HAVOK_SPEC.md §3.1 — card de insight (máx. 1 por tela).
                      // Só renderiza quando não foi dispensado hoje; texto
                      // ainda é placeholder estático (sem use case de geração).
                      HavokInsightWidget(onAction: _viewProgress),

                      const SizedBox(height: BldrSpacing.gapSection),

                      // D5 — grid 2×2: Peso alvo · Calorias · Macros · 7 dias.
                      // D6 (macros empilhados) vive dentro do NutritionProgressWidget.
                      Padding(
                        padding: BldrSpacing.pageInsets,
                        child: Column(
                          children: [
                            // IntrinsicHeight: dá à Row uma altura FINITA antes
                            // do stretch agir. Sem isso, o stretch tenta esticar
                            // os cards para a altura do Column/ScrollView, que é
                            // não-limitada — e isso quebra a renderização do
                            // frame inteiro sem lançar exceção (bug encontrado
                            // por bisseção manual em 01/08/2026).
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: GoalCardWidget(
                                      onViewProgressPressed: _viewProgress,
                                      onUpdateProgressPressed: _viewProgress,
                                    ),
                                  ),
                                  const SizedBox(width: BldrSpacing.gapCard),
                                  const Expanded(
                                    child: NutritionProgressWidget(
                                      variant: NutritionTile.calories,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: BldrSpacing.gapCard),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Expanded(
                                    child: NutritionProgressWidget(
                                      variant: NutritionTile.macros,
                                    ),
                                  ),
                                  const SizedBox(width: BldrSpacing.gapCard),
                                  Expanded(
                                    child: ConsistencyHeatmapWidget(
                                      onViewAllPressed: _viewProgress,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // D8 — os cards grandes de "Consistência" e "Conquistas"
                      // saíram daqui: o dado migrou para os chips (D3) e para o
                      // grid (D5). AchievementsWidget permanece no código.

                      const SizedBox(height: BldrSpacing.gapSection),

                      // D9 — Parceiros: o widget já se oculta sozinho
                      // (SizedBox.shrink) enquanto não houver parceiro ativo.
                      PartnershipWidget(
                        onViewAllPressed: () => _onTabSelected(3),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
