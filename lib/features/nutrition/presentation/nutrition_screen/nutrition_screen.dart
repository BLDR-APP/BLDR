import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/features/achievements/presentation/achievements/achievement_provider.dart';
import 'package:bldr_fitness/features/club/presentation/bldr_club/havok/havok_sheet.dart';
import 'package:bldr_fitness/services/popup_service.dart';
import 'package:bldr_fitness/services/user_service.dart';
import 'package:bldr_fitness/widgets/custom_error_widget.dart';
import 'package:bldr_fitness/widgets/notification_permission_modal.dart';

import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/widgets/daily_nutrition_overview_widget.dart';
import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/widgets/meal_timeline_widget.dart';
import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/widgets/water_intake_widget.dart';

import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/widgets/Firebase/firebase_add_food_modal_widget.dart';
import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/widgets/food_categories_modal.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/subscription_usecases.dart'
    as subUc;
import 'package:bldr_fitness/features/nutrition/domain/entities/daily_nutrition_summary.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/nutrition_goals.dart';
import 'package:bldr_fitness/features/nutrition/domain/usecases/nutrition_usecases.dart';
import 'package:bldr_fitness/features/nutrition/presentation/mappers/legacy_ui_maps.dart';
import 'package:bldr_fitness/services/firebase_auth_service.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({Key? key}) : super(key: key);

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  List<Map<String, dynamic>> _meals = [];
  Map<String, dynamic> _nutritionSummary = {};
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  bool _hasError = false;
  int _waterIntake = 0;
  bool _isClubMember = false;
  NutritionGoals _goals = NutritionGoals.defaults;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // >>> FUNÇÃO _loadData: UNIFICADA E CORRIGIDA <<<
  Future<void> _loadData({bool silent = false}) async {
    try {
      if (mounted && !silent) {
        setState(() {
          _isLoading = true;
          _hasError = false;
        });
      }

      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId != null) {
        try {
          // 1. O serviço tenta obter o token customizado. Retorna String?
          final String? firebaseToken =
              await FirebaseAuthService().getFirebaseCustomToken();

          // 2. Só faz login se um token for retornado (ou seja, se o usuário não estava no cache)
          if (firebaseToken != null) {
            await FirebaseAuthService().signInWithCustomToken(firebaseToken);
            print(
                "Login no Firebase com sucesso! UID: ${FirebaseAuthService().currentFirebaseUser?.uid}");
          } else {
            print("Autenticação Firebase: Usuário já logado via cache.");
          }
        } catch (e) {
          print("Erro fatal de autenticação no Firebase: $e");
          if (mounted)
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          return;
        }
      }

      // 2. Busca Metas (fonte única, mesma do Dashboard e do Progresso)
      if (userId != null) {
        final goalsResult = await getIt<GetNutritionGoals>()(userId);
        if (!mounted) return;
        _goals = goalsResult.valueOrNull ?? NutritionGoals.defaults;
      } else {
        print("Aviso: Usuário não autenticado em _loadData.");
        _goals = NutritionGoals.defaults;
      }

      // 3. Checagem de Membro (Lógica Original)
      final subscription =
          (await getIt<subUc.GetCurrentSubscription>()()).valueOrNull;
      if (!mounted) return;
      if (subscription != null &&
          subscription.status == 'active' &&
          subscription.planId == 'd082af8c-216a-4499-a1f6-1fb84ac08a5f') {
        _isClubMember = true;
      } else {
        _isClubMember = false;
      }

      // 4. Busca Dados de Nutrição (Totais Consumidos - Firebase)
      // TODO: Adicionar busca do waterIntake
      final mealsResult =
          await getIt<GetMealsForDate>()(_selectedDate, userId: userId);

      if (!mounted) return;

      final mealEntries = mealsResult.valueOrNull;
      if (mealEntries == null) {
        throw Exception(mealsResult.failureOrNull?.message ??
            'Falha ao carregar refeições.');
      }

      // O resumo do dia é derivado localmente das refeições carregadas
      // (mesmos totais do summary legado, sem query duplicada).
      final summary =
          DailyNutritionSummary.fromEntries(_selectedDate, mealEntries);

      setState(() {
        _meals = mealEntries.map(mealEntryToLegacyMap).toList();
        _nutritionSummary = summaryToLegacyMap(summary);
        _isLoading = false;
      });
    } catch (error) {
      print("Erro em _loadData: $error");
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }
  // --- FIM DA FUNÇÃO DE CARREGAMENTO CENTRALIZADA ---

  // NOVO MÉTODO: Abre o modal para edição de um item existente
  void _showEditFoodModal(Map<String, dynamic> meal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      // Chamamos o mesmo modal de adição, mas injetamos os dados de edição
      builder: (context) => FirebaseAddFoodModalWidget(
        mealType: meal['meal_type'] ?? 'lanche', // Reusa o tipo de refeição
        selectedDate: _selectedDate,
        onFoodAdded: () => _loadData(silent: true),
        isClub: _isClubMember,

        // >>> NOVOS PARÂMETROS PARA EDIÇÃO (Usados no Modal) <<<
        itemToEdit: meal,
        isEditing: true,
      ),
    );
  }

  // >>> NOVO MÉTODO: LIDA COM A DELEÇÃO DE UM ITEM LOGADO <<<
  void _handleDeleteFoodLog(String foodLogId) async {
    final result = await getIt<DeleteMealEntry>()(foodLogId);

    if (!mounted) return;

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).nutrition_food_removed),
          backgroundColor: AppTheme.successGreen));
      await _loadData(silent: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).nutrition_remove_error),
          backgroundColor: AppTheme.errorRed));
    }
  }

  // Função _showAddFoodModal (Mantida para o botão de Adição)
  void _showAddFoodModal(String mealType) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FoodCategoriesModal(
        mealType: mealType,
        onFoodAdded: () async {
          await _loadData(silent: true);
          await _maybeTriggerNotificationPopup();
          if (!mounted) return;
          final ap = context.read<AchievementProvider>();
          ap.checkAchievements('nutrition');
        },
        selectedDate: _selectedDate,
        isClub: _isClubMember,
      ),
    );
  }

  Future<void> _maybeTriggerNotificationPopup() async {
    if (!mounted) return;
    try {
      final fcmSettings =
          await FirebaseMessaging.instance.getNotificationSettings();
      final permGranted =
          fcmSettings.authorizationStatus == AuthorizationStatus.authorized;
      final profile = await UserService.instance.getCurrentUserProfile();
      if (profile == null || !mounted) return;
      final shouldShow = await PopupService.shouldShowNotificationPopup(
        userCreatedAt: profile.createdAt,
        osPermissionGranted: permGranted,
      );
      if (shouldShow && mounted) {
        await NotificationPermissionModal.show(context);
      }
    } catch (_) {}
  }

  // Funções Auxiliares (Não precisam de alteração)
  void _onDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
      _isLoading = true;
    });
    _loadData();
  }

  void _incrementWater() {
    setState(() {
      _waterIntake += 250;
      // TODO: Salvar _waterIntake
    });
  }

  Widget _buildHeader() {
    final bool isToday = _selectedDate.day == DateTime.now().day &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.year == DateTime.now().year;

    final Widget dateButton = GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 30)),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: BldrColors.goldBright,
                surface: Color(0xFF1a1a1a),
              ),
            ),
            child: child!,
          ),
        );
        if (date != null) _onDateChanged(date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: BldrColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: BldrColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isToday ? AppLocalizations.of(context).common_today : '${_selectedDate.day}/${_selectedDate.month}',
              style: BldrText.body
                  .copyWith(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.calendar_today_rounded,
                color: BldrColors.goldBright, size: 15),
          ],
        ),
      ),
    );

    final trailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HavokEntryIcon(
            onTap: () => showHavokSheet(context, originScreen: 'nutrition')),
        const SizedBox(width: 8),
        dateButton,
      ],
    );

    // Phantom invisível à esquerda para manter o wordmark centralizado.
    return Row(
      children: [
        Opacity(opacity: 0, child: trailing),
        Expanded(
          child: Center(
            child: Text(
              'BLDR',
              style: TextStyle(
                fontFamily: BldrText.family,
                color: BldrColors.goldBright,
                fontWeight: FontWeight.w600,
                fontSize: 18,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ),
        trailing,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: BldrColors.bgBase,
        body: Center(
            child: CircularProgressIndicator(color: BldrColors.goldBright)),
      );
    }

    if (_hasError) {
      return const Scaffold(
        backgroundColor: BldrColors.bgBase,
        body: Center(child: CustomErrorWidget()),
      );
    }

    return Scaffold(
      backgroundColor: BldrColors.bgBase,
      body: BldrBackground(
        // Sem SafeArea o header (ícone do HAVOK + data) ficava embaixo da
        // status bar/notch, fora da área de toque.
        child: SafeArea(
            child: RefreshIndicator(
                onRefresh: _loadData,
                color: BldrColors.goldBright,
                backgroundColor: BldrColors.surface,
                child: CustomScrollView(slivers: [
                  SliverAppBar(
                      backgroundColor: Colors.transparent,
                      floating: false,
                      pinned: false,
                      elevation: 0,
                      automaticallyImplyLeading: false,
                      flexibleSpace: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: BldrSpacing.pageX, vertical: 8),
                        child: Center(child: _buildHeader()),
                      ),
                      expandedHeight: 76),
                  SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: BldrSpacing.pageX),
                          child: DailyNutritionOverviewWidget(
                            nutritionSummary:
                                _nutritionSummary, // Totais Consumidos
                            selectedDate: _selectedDate,
                            goals: _goals, // Metas Diárias
                            isClub: _isClubMember,
                          ))),
                  SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: BldrSpacing.pageX,
                              vertical: BldrSpacing.gapSection),
                          child: MealTimelineWidget(
                            meals: _meals,
                            onAddMeal: _showAddFoodModal,
                            onEditMeal:
                                _showEditFoodModal, // <<< AGORA CONECTADO AO NOVO HANDLER
                            onDeleteFoodLog: _handleDeleteFoodLog,
                          ))),
                  SliverToBoxAdapter(
                      child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: BldrSpacing.pageX),
                    child: WaterIntakeWidget(
                        intake: _waterIntake.toDouble(),
                        onIncrement: _incrementWater),
                  )),
                  const SliverToBoxAdapter(child: SizedBox(height: 90)),
                ]))),
      ),
    );
  }
}
