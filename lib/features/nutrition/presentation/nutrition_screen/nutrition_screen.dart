import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/core/toast/bldr_toaster.dart';
import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';
import 'package:bldr_fitness/features/achievements/presentation/achievements/achievement_provider.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/daily_nutrition_summary.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/meal_entry.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/nutrition_goals.dart';
import 'package:bldr_fitness/features/nutrition/domain/usecases/nutrition_usecases.dart';
import 'package:bldr_fitness/core/errors/result.dart';
import 'package:bldr_fitness/features/achievements/domain/usecases/achievement_usecases.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/integrations/data/widget_data_service.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/food_item.dart';
import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/widgets/v2/nutrition_add_food_sheets.dart';
import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/widgets/v2/nutrition_copy_meal_sheets.dart';
import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/widgets/v2/nutrition_create_food_sheets.dart';
import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/widgets/v2/nutrition_saved_meal_sheets.dart';
import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/widgets/v2/nutrition_hub_sections.dart';
import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/widgets/v2/nutrition_water_sheet.dart';
import 'package:bldr_fitness/features/progress/domain/usecases/progress_usecases.dart';
import 'package:bldr_fitness/features/subscription/domain/usecases/resolve_club_access.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/services/firebase_auth_service.dart';
import 'package:bldr_fitness/services/popup_service.dart';
import 'package:bldr_fitness/services/user_service.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/widgets/custom_error_widget.dart';
import 'package:bldr_fitness/widgets/notification_permission_modal.dart';

/// Nutrition Hub v2 (Figma z6plKSVOCah3uDI1Abaxbe, 102:312 / 102:309).
/// O acesso ao HAVOK é pelo botão da NavBar (mesmo `showHavokSheet`).
class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  List<MealEntry> _entries = const [];
  DailyNutritionSummary? _summary;
  IqdWeeklyComparison? _iqd;
  DateTime _selectedDate = _today();
  bool _isLoading = true;
  bool _hasError = false;
  bool _isClubMember = false;
  NutritionGoals _goals = NutritionGoals.defaults;
  int _waterMl = 0;

  /// Refeição expandida (uma por vez) e modo de edição do lápis.
  String? _expanded;
  bool _editMode = false;

  /// Sheets/diálogos abertos pela tela (o FAB some enquanto > 0).
  int _overlays = 0;

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool get _isToday => _selectedDate == _today();
  String? get _userId => getIt<GetCurrentUser>()()?.id;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (mounted && !silent) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    try {
      final userId = _userId;
      if (userId != null) {
        // Sessão do Firebase (diário no Firestore) a partir do token custom.
        final token = await FirebaseAuthService().getFirebaseCustomToken();
        if (token != null) {
          await FirebaseAuthService().signInWithCustomToken(token);
        }
        final goals = await getIt<GetNutritionGoals>()(userId);
        _goals = goals.valueOrNull ?? NutritionGoals.defaults;
      } else {
        _goals = NutritionGoals.defaults;
      }
      _isClubMember = (await getIt<ResolveClubAccess>()()).valueOrNull ?? false;

      final date = _selectedDate;
      final results = await Future.wait([
        getIt<GetMealsForDate>()(date, userId: userId),
        getIt<GetIqdWeeklyComparison>()(date, userId: userId),
        getIt<GetDailyWaterIntake>()(date),
      ]);
      if (!mounted || date != _selectedDate) return;
      final meals = results[0].valueOrNull as List<MealEntry>?;
      if (meals == null) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _entries = meals;
        _summary = DailyNutritionSummary.fromEntries(date, meals);
        _iqd = results[1].valueOrNull as IqdWeeklyComparison?;
        _waterMl = (results[2].valueOrNull as dynamic)?.totalAmountMl ?? 0;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  /// Abre sheet/diálogo escondendo o FAB enquanto estiver aberto.
  Future<T?> _overlay<T>(Future<T?> Function() open) async {
    setState(() => _overlays++);
    try {
      return await open();
    } finally {
      if (mounted) setState(() => _overlays--);
    }
  }

  // ── Ações ────────────────────────────────────────────────────────────────

  AddFoodCatalog get _catalog {
    final uid = _userId;
    Future<List<FoodItem>> unwrap(Future<Result<List<FoodItem>>> f) async =>
        (await f).valueOrNull ?? const [];
    return AddFoodCatalog(
      search: (q) => unwrap(getIt<SearchFoods>()(q)),
      byCategory: (c) => unwrap(getIt<GetCategoryFoods>()(c)),
      recents: () async =>
          uid == null ? const [] : unwrap(getIt<GetRecentFoods>()(uid)),
      favorites: () async =>
          uid == null ? const [] : unwrap(getIt<GetFavoriteFoods>()(uid)),
    );
  }

  /// N2: Adicionar Alimentos (102:316) → porção (102:308) → LogMeal.
  Future<void> _showAddFoodModal(NutritionMealSlot slot) async {
    final pick = await _overlay(
        () => NutritionAddFoodSheet.show(context, catalog: _catalog));
    if (pick == null || !mounted) return;
    if (pick.createManual) return _showManualCreate(slot);
    if (pick.savedMeals) return _addSavedMeal(slot);
    await _logFood(pick.food!, slot);
  }

  /// Porção (102:308) → LogMeal → toast e efeitos.
  Future<void> _logFood(FoodItem food, NutritionMealSlot slot) async {
    final portion = await _overlay(
        () => NutritionPortionSheet.add(context, food: food, slot: slot));
    if (portion == null || !mounted) return;
    final l = AppLocalizations.of(context);
    final uid = _userId;
    if (uid == null) {
      context.toast.error(l.common_unauthenticated);
      return;
    }
    final date = _selectedDate;
    final r = await getIt<LogMeal>()(
      userId: uid,
      mealType: portion.slot.dbKey,
      mealDate: date,
      food: food,
      quantityGrams: portion.grams,
    );
    if (!mounted) return;
    if (r.isFailure) {
      context.toast.error(l.nutri2_toast_save_error);
      return;
    }
    // T3: meal.added.
    context.toast.success(l.nutri2_toast_added(portion.slot.label(l)));
    await _afterFoodLogged(uid, date);
  }

  /// Efeitos colaterais que o modal antigo já disparava após registrar.
  Future<void> _afterFoodLogged(String uid, DateTime date) async {
    unawaited(getIt<CheckAndUnlockAchievements>()('nutrition'));
    unawaited(WidgetDataService.updateAll());
    final proteinBefore = _summary?.totals.protein ?? 0;
    final kcalBefore = _summary?.totals.calories ?? 0;
    await _loadData(silent: true);
    if (!mounted) return;
    _checkProteinGoal(proteinBefore);
    final kcal = _summary?.totals.calories ?? 0;
    if (_goals.calories > 0 && kcal >= _goals.calories) {
      unawaited(getIt<TryIncrementOperation>()('calorie_goal', 1));
    }
    // T4: Goal da meta calórica (mesmo evento `calorie_goal`), só ao cruzar.
    if (_isToday &&
        nutritionGoalCrossed(
            before: kcalBefore, after: kcal, goal: _goals.calories)) {
      final l = AppLocalizations.of(context);
      final fmt = NumberFormat.decimalPattern(l.localeName);
      context.toast.goal(
        l.nutri2_toast_kcal_goal,
        title: l.nutri2_toast_goal_title,
        description: l.nutri2_toast_kcal_goal_desc,
        progressLabel: l.nutri2_toast_kcal_goal_label,
        progressValue:
            '${fmt.format(kcal.round())} / ${fmt.format(_goals.calories)} kcal',
        progress: 1,
        dedupeKey: 'nutrition.calorie_goal',
      );
    }
    await _maybeTriggerNotificationPopup();
    if (!mounted) return;
    context.read<AchievementProvider>().checkAchievements('nutrition');
  }

  /// N4: cadastro manual em 2 passos (102:296 → 102:167). Salva em
  /// user_favorites (per 100 g) e segue para a porção.
  Future<void> _showManualCreate(NutritionMealSlot slot) async {
    var draft = const CreateFoodDraft();
    while (mounted) {
      final basic = await _overlay(
          () => NutritionCreateFoodSheets.step1(context, draft: draft));
      if (basic == null || !mounted) return;
      draft = basic;
      final r = await _overlay(
          () => NutritionCreateFoodSheets.step2(context, draft: draft));
      if (r == null || !mounted) return;
      draft = r.draft;
      if (r.food == null) continue; // ← VOLTAR
      final l = AppLocalizations.of(context);
      final uid = _userId;
      if (uid == null) {
        context.toast.error(l.common_unauthenticated);
        return;
      }
      final saved = await getIt<SaveFavoriteFood>()(r.food!, uid);
      if (!mounted) return;
      final food = saved.valueOrNull;
      if (food == null) {
        context.toast.error(l.nutri2_toast_save_error);
        return;
      }
      context.toast.success(l.nutri2_toast_food_created);
      await _logFood(food, slot);
      return;
    }
  }

  /// N2: editar (102:301) → salvar (UpdateMealQuantity) ou remover (102:300).
  Future<void> _showEditFoodModal(MealEntry entry) async {
    final slot = NutritionMealSlot.all.firstWhere(
        (s) => s.dbKey == entry.mealType,
        orElse: () => NutritionMealSlot.all[1]);
    final r = await _overlay(
        () => NutritionPortionSheet.edit(context, entry: entry, slot: slot));
    if (r == null || !mounted) return;
    if (r.remove) return _removeFood(entry);
    final l = AppLocalizations.of(context);
    final res = await getIt<UpdateMealQuantity>()(
        entry: entry, newQuantityGrams: r.grams);
    if (!mounted) return;
    if (res.isFailure) {
      context.toast.error(l.nutri2_toast_save_error);
      return;
    }
    context.toast.success(l.nutri2_toast_updated);
    await _loadData(silent: true);
  }

  Future<void> _removeFood(MealEntry entry) async {
    final l = AppLocalizations.of(context);
    final slot = NutritionMealSlot.all.firstWhere(
        (s) => s.dbKey == entry.mealType,
        orElse: () => NutritionMealSlot.all[1]);
    final ok = await _overlay(
        () => NutritionRemoveFoodSheet.show(context, entry: entry, slot: slot));
    if (ok != true || entry.id == null || !mounted) return;
    final result = await getIt<DeleteMealEntry>()(entry.id!);
    if (!mounted) return;
    if (result.isSuccess) {
      // T3: meal.removed com Desfazer (regrava o mesmo registro, sem XP).
      context.toast.undo(l.nutri2_toast_removed, onUndo: () async {
        final r = await getIt<RestoreMealEntry>()(entry);
        if (!mounted) return;
        if (r.isFailure) context.toast.error(l.nutri2_toast_save_error);
        await _loadData(silent: true);
      });
      await _loadData(silent: true);
    } else {
      context.toast.error(l.nutri2_toast_remove_error);
    }
  }

  /// Sheet de água (102:311): adiciona via LogWater ou remove via
  /// RemoveWater (link mantido do app atual).
  Future<void> _addWater() async {
    final r = await _overlay(() => NutritionWaterSheet.show(context,
        intakeMl: _waterMl, goalMl: _goals.waterMl));
    if (r == null || !mounted) return;
    final l = AppLocalizations.of(context);
    final before = _waterMl;
    if (r.addMl != null) {
      final res = await getIt<LogWater>()(r.addMl!);
      if (!mounted) return;
      if (res.isFailure) {
        context.toast.error(l.nutri2_toast_water_error);
        return;
      }
      context.toast.success(l.nutri2_toast_water_added('${r.addMl}'));
    } else if (r.remove) {
      final amount = await _overlay(
          () => NutritionWaterSheet.showRemove(context, intakeMl: _waterMl));
      if (amount == null || !mounted) return;
      final res = await getIt<RemoveWater>()(amount);
      if (!mounted) return;
      if (res.isFailure) {
        context.toast.error(l.hydration_remove_error);
        return;
      }
      context.toast.success(l.nutri2_toast_water_removed('$amount'));
    }
    await _loadData(silent: true);
    if (!mounted) return;
    // T3: hydration.goal_reached (uma vez por cruzamento da meta).
    if (nutritionGoalCrossed(
        before: before, after: _waterMl, goal: _goals.waterMl)) {
      final loc = l.localeName;
      context.toast.goal(
        l.nutri2_toast_water_goal,
        title: l.nutri2_toast_goal_title,
        description: l.nutri2_toast_water_goal_desc,
        progressLabel: l.nutri2_toast_water_goal_label,
        progressValue:
            '${NumberFormat.decimalPattern(loc).format(_waterMl)} / ${NumberFormat.decimalPattern(loc).format(_goals.waterMl)} ml',
        progress: 1,
        dedupeKey: 'nutrition.hydration_goal',
      );
    }
  }

  /// "⋯" da refeição expandida: Copiar (N5) ou Salvar como refeição (N7).
  Future<void> _mealMenu(NutritionMealSlot slot) async {
    final action = await _overlay(() => NutritionSavedMealSheets.menu(context));
    if (action == null || !mounted) return;
    if (action == MealMenuAction.copy) return _copyMeal(slot);
    final items = _entries.where((e) => e.mealType == slot.dbKey).toList();
    if (items.isEmpty) return;
    final l = AppLocalizations.of(context);
    final kcal = items.fold<double>(0, (a, e) => a + e.macros.calories);
    final name = await _overlay(() => NutritionSavedMealSheets.name(context,
        initial: slot.label(l), count: items.length, kcal: kcal));
    if (name == null || !mounted) return;
    final uid = _userId;
    if (uid == null) {
      context.toast.error(l.common_unauthenticated);
      return;
    }
    final r = await getIt<SaveMealFromEntries>()(
        name: name, entries: items, userId: uid);
    if (!mounted) return;
    if (r.isFailure) {
      context.toast
          .error(r.failureOrNull?.message ?? l.nutri2_toast_save_error);
      return;
    }
    context.toast.success(l.nutri2_toast_meal_saved);
  }

  /// N7: Refeições salvas → detalhe → confirmação → diário.
  Future<void> _addSavedMeal(NutritionMealSlot slot) async {
    final uid = _userId;
    if (uid == null) return;
    while (mounted) {
      final meal = await _overlay(() => NutritionSavedMealSheets.list(context,
          load: () async =>
              (await getIt<GetSavedMeals>()(uid)).valueOrNull ?? const []));
      if (meal == null || !mounted) return;
      final go = await _overlay(
          () => NutritionSavedMealSheets.detail(context, meal: meal));
      if (go == null || !mounted) return;
      if (!go) continue; // ‹ volta para a lista
      final dest = await _overlay(() =>
          NutritionSavedMealSheets.confirm(context, meal: meal, initial: slot));
      if (dest == null || !mounted) return;
      final l = AppLocalizations.of(context);
      final date = _selectedDate;
      final r = await getIt<AddSavedMealToDiary>()(
          meal: meal, userId: uid, date: date, mealType: dest.dbKey);
      if (!mounted) return;
      final count = r.valueOrNull;
      if (count == null) {
        context.toast.error(l.nutri2_toast_save_error);
        return;
      }
      context.toast.success(l.nutri2_toast_saved_added(count, dest.label(l)));
      await _afterFoodLogged(uid, date);
      return;
    }
  }

  /// N5: Copiar refeição (destino → revisão → grava → sucesso).
  Future<void> _copyMeal(NutritionMealSlot slot) async {
    final items = _entries.where((e) => e.mealType == slot.dbKey).toList();
    if (items.isEmpty) return;
    final dest = await _overlay(() => NutritionCopyMealSheets.destination(
        context,
        source: slot,
        entries: items,
        today: _today()));
    if (dest == null || !mounted) return;
    final ok = await _overlay(() => NutritionCopyMealSheets.review(context,
        dest: dest, entries: items, today: _today()));
    if (ok != true || !mounted) return;
    final r = await getIt<CopyMeal>()(
        entries: items, toDate: dest.date, toMealType: dest.slot.dbKey);
    if (!mounted) return;
    final count = r.valueOrNull;
    if (count == null) {
      context.toast.error(AppLocalizations.of(context).nutri2_copy_error);
      return;
    }
    await _loadData(silent: true);
    if (!mounted) return;
    await _overlay(() => NutritionCopyMealSheets.success(context,
        count: count, slot: dest.slot));
  }

  /// T3: protein.goal_reached depois de adicionar alimento (só hoje).
  void _checkProteinGoal(double before) {
    if (!_isToday || !mounted) return;
    final after = _summary?.totals.protein ?? 0;
    if (!nutritionGoalCrossed(
        before: before, after: after, goal: _goals.protein)) {
      return;
    }
    final l = AppLocalizations.of(context);
    context.toast.goal(
      l.nutri2_toast_protein_goal,
      title: l.nutri2_toast_goal_title,
      description: l.nutri2_toast_protein_goal_desc,
      progressLabel: l.nutri2_toast_protein_goal_label,
      progressValue: '${after.round()} / ${_goals.protein} g',
      progress: 1,
      dedupeKey: 'nutrition.protein_goal',
    );
  }

  Future<void> _pickDate() async {
    final l = AppLocalizations.of(context);
    final picked = await _overlay(() => BldrV2Sheet.show<DateTime>(
          context,
          title: l.nutri2_date_sheet_title,
          child: Builder(
            builder: (ctx) => NutritionDateSheetList(
              selected: _selectedDate,
              today: _today(),
              onSelect: (d) => Navigator.pop(ctx, d),
            ),
          ),
        ));
    if (picked == null || picked == _selectedDate || !mounted) return;
    setState(() {
      _selectedDate = picked;
      _expanded = null;
    });
    _loadData();
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

  // ── UI ───────────────────────────────────────────────────────────────────

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
      body: NutritionHubView(
        date: _selectedDate,
        today: _today(),
        summary: _summary ??
            DailyNutritionSummary.fromEntries(_selectedDate, const []),
        goals: _goals,
        iqd: _iqd,
        iqdLocked: !_isClubMember,
        waterMl: _waterMl,
        entries: _entries,
        expandedKey: _expanded,
        editMode: _editMode,
        fabVisible: _expanded == null && _overlays == 0,
        onRefresh: _loadData,
        onDateTap: _pickDate,
        onUnlockIqd: () =>
            Navigator.pushNamed(context, AppRoutes.checkoutScreen),
        onAddWater: _isToday ? _addWater : null,
        onToggleMeal: (s) =>
            setState(() => _expanded = _expanded == s.dbKey ? null : s.dbKey),
        onAddFood: _showAddFoodModal,
        onToggleEdit: () => setState(() => _editMode = !_editMode),
        onEditFood: _showEditFoodModal,
        onRemoveFood: _removeFood,
        onCopyMeal: _mealMenu,
        onFab: () =>
            _showAddFoodModal(NutritionMealSlot.suggested(DateTime.now())),
      ),
    );
  }
}
