import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:bldr_fitness/core/app_export.dart';
import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/auth/domain/usecases/auth_usecases.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/food_item.dart';
import 'package:bldr_fitness/features/integrations/data/widget_data_service.dart';
import 'package:bldr_fitness/features/achievements/domain/usecases/achievement_usecases.dart';
import 'package:bldr_fitness/features/club/domain/usecases/club_usecases.dart';
import 'package:bldr_fitness/features/nutrition/domain/usecases/nutrition_usecases.dart';
import 'package:bldr_fitness/features/nutrition/presentation/mappers/legacy_ui_maps.dart';
import 'package:bldr_fitness/services/iqd_calculator_service.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/widgets/firebase_nutrition_search_widget.dart';

// ─────────────────────────────────────────────────────────────
// Campo de formulário — N19 (label acima, não como placeholder) /
// N20 (sem ícone decorativo).
// ─────────────────────────────────────────────────────────────
class _FormInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final TextInputType keyboardType;
  final bool isOptional;
  final VoidCallback? onEditComplete;
  final FocusNode? focusNode;

  const _FormInputWidget({
    Key? key,
    required this.controller,
    required this.label,
    required this.suffix,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
    this.isOptional = false,
    this.onEditComplete,
    this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext buildContext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: BldrText.label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: BldrText.body,
          keyboardType: keyboardType,
          inputFormatters: keyboardType == TextInputType.text
              ? []
              : [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))],
          decoration: InputDecoration(
            suffixText: suffix.isEmpty ? null : suffix,
            suffixStyle: BldrText.description,
            filled: true,
            fillColor: BldrColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: BldrColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: BldrColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: BldrColors.goldBright, width: 2),
            ),
          ),
          validator: (value) {
            if (!isOptional && (value == null || value.isEmpty)) {
              return AppLocalizations.of(buildContext).common_required_field;
            }
            if (keyboardType != TextInputType.text &&
                value != null &&
                value.isNotEmpty &&
                double.tryParse(value) == null) {
              return AppLocalizations.of(buildContext).common_invalid_value;
            }
            return null;
          },
          onEditingComplete: onEditComplete,
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }
}

class FirebaseAddFoodModalWidget extends StatefulWidget {
  final String mealType;
  final VoidCallback onFoodAdded;
  final DateTime selectedDate;
  final bool isClub;
  final Map<String, dynamic>? itemToEdit;
  final bool isEditing;
  final String? selectedCategory;

  const FirebaseAddFoodModalWidget({
    Key? key,
    required this.mealType,
    required this.onFoodAdded,
    required this.selectedDate,
    this.isClub = false,
    this.itemToEdit,
    this.isEditing = false,
    this.selectedCategory,
  }) : super(key: key);

  @override
  State<FirebaseAddFoodModalWidget> createState() => _AddFoodModalWidgetState();
}

class _AddFoodModalWidgetState extends State<FirebaseAddFoodModalWidget> with SingleTickerProviderStateMixin {

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _portionController = TextEditingController();
  final _sodiumController = TextEditingController();
  final _fiberController = TextEditingController();
  final _addedSugarController = TextEditingController();
  bool _saveToFavorites = false;
  bool _isSavingManual = false;
  bool _manualCalories = false;

  // N17 — acordeão "Dados de qualidade (IQD)" recolhido por padrão.
  bool _iqdAccordionExpanded = false;

  final _caloriesFocus = FocusNode();
  final _proteinFocus = FocusNode();
  final _carbsFocus = FocusNode();
  final _fatFocus = FocusNode();
  final _portionFocus = FocusNode();
  final _sodiumFocus = FocusNode();
  final _fiberFocus = FocusNode();
  final _addedSugarFocus = FocusNode();

  // Navegação por chips (0=Recentes, 1=Favoritos, 2=Manual)
  int _selectedTab = 0;
  final _searchController = TextEditingController();
  double _hypotheticalIqdScore = 60.0;
  double? _currentDayIqd; // null until day totals are loaded
  double _currentDayFiber = 0;
  double _currentDaySodium = 0;
  double _currentDaySugar = 0;

  List<Map<String, dynamic>> _favoriteFoods = [];
  bool _isLoadingFavorites = true;
  List<Map<String, dynamic>> _recentFoods = [];
  bool _isLoading = true;
  List<Map<String, dynamic>> _categoryFoods = [];
  bool _isLoadingCategory = false;


  @override
  void initState() {
    super.initState();
    _loadRecentFoods();
    _loadFavoriteFoods();
    if (widget.selectedCategory != null) {
      _loadCategoryFoods(widget.selectedCategory!);
    }
    _proteinController.addListener(_calculateCalories);
    _carbsController.addListener(_calculateCalories);
    _fatController.addListener(_calculateCalories);
    _caloriesController.addListener(_checkManualCalories);
    _sodiumController.addListener(_updateHypotheticalIqd);
    _fiberController.addListener(_updateHypotheticalIqd);
    _addedSugarController.addListener(_updateHypotheticalIqd);
    _loadCurrentDayIqd();

    if (widget.isEditing && widget.itemToEdit != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPortionSelector(widget.itemToEdit!, isEditingFlow: true);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _caloriesController.removeListener(_checkManualCalories); _caloriesController.dispose();
    _proteinController.removeListener(_calculateCalories); _proteinController.dispose();
    _carbsController.removeListener(_calculateCalories); _carbsController.dispose();
    _fatController.removeListener(_calculateCalories); _fatController.dispose();
    _portionController.dispose();
    _sodiumController.dispose();
    _fiberController.dispose();
    _addedSugarController.dispose();
    _caloriesFocus.dispose(); _proteinFocus.dispose(); _carbsFocus.dispose(); _fatFocus.dispose(); _portionFocus.dispose();
    _sodiumFocus.dispose(); _fiberFocus.dispose(); _addedSugarFocus.dispose();
    _sodiumController.removeListener(_updateHypotheticalIqd);
    _fiberController.removeListener(_updateHypotheticalIqd);
    _addedSugarController.removeListener(_updateHypotheticalIqd);

    super.dispose();
  }

  // F17 — carrega totais do dia atual para calcular IQD projetado real.
  Future<void> _loadCurrentDayIqd() async {
    try {
      final result = await getIt<GetDailySummary>()(DateTime.now());
      final summary = result.valueOrNull;
      if (summary == null || !mounted) return;
      final map = summaryToLegacyMap(summary);
      final fiber = ((map['total_fiber'] as num?) ?? 0).toDouble();
      final sodium = ((map['total_sodium'] as num?) ?? 0).toDouble();
      final sugar = ((map['total_added_sugar'] as num?) ?? 0).toDouble();
      final iqd = IqdCalculatorService.calculate(
        fiberGrams: fiber, sodiumMg: sodium, addedSugarGrams: sugar,
      );
      if (mounted) {
        setState(() {
          _currentDayFiber = fiber;
          _currentDaySodium = sodium;
          _currentDaySugar = sugar;
          _currentDayIqd = iqd;
        });
        _updateHypotheticalIqd();
      }
    } catch (_) {}
  }

  // ── IQD hipotético (F17: projetado = dia atual + formulário) ────
  void _updateHypotheticalIqd() {
    final fiber      = _currentDayFiber + (double.tryParse(_fiberController.text)      ?? 0.0);
    final sodium     = _currentDaySodium + (double.tryParse(_sodiumController.text)     ?? 0.0);
    final addedSugar = _currentDaySugar + (double.tryParse(_addedSugarController.text) ?? 0.0);
    final score = IqdCalculatorService.calculate(
      fiberGrams: fiber, sodiumMg: sodium, addedSugarGrams: addedSugar,
    );
    if (mounted) setState(() => _hypotheticalIqdScore = score);
  }

  // ── Mapeamento categoria → emoji (N13 — uma vez no cabeçalho) ───
  String _categoryEmoji(String? category) {
    if (category == null || category.isEmpty) return '🍽';
    final c = category.toUpperCase();
    if (c.contains('CARNE') || c.contains('AVE'))              return '🥩';
    if (c.contains('PEIXE') || c.contains('FRUTO'))            return '🐟';
    if (c.contains('OVO'))                                     return '🥚';
    if (c.contains('LATICIN') || c.contains('LATICÍN'))        return '🥛';
    if (c.contains('FRUTA'))                                   return '🍓';
    if (c.contains('LEGUME') || c.contains('VERDURA'))         return '🥦';
    if (c.contains('GRÃO') || c.contains('GRAO') || c.contains('CEREAL')) return '🌾';
    if (c.contains('GORDURA') || c.contains('ÓLEO') || c.contains('OLEO')) return '🫒';
    if (c.contains('OLEAGINOSA') || c.contains('SEMENTE'))     return '🥜';
    if (c.contains('DOCE') || c.contains('SOBREMESA'))         return '🍰';
    if (c.contains('BEBIDA'))                                  return '🥤';
    if (c.contains('FAST') || c.contains('LANCHE'))            return '🍔';
    if (c.contains('INDUSTRIALI'))                             return '📦';
    if (c.contains('REFEIÇÃO') || c.contains('REFEICAO') || c.contains('PRONTA')) return '🍱';
    if (c.contains('MOLHO') || c.contains('TEMPERO'))          return '🧂';
    if (c.contains('SUPLEMENTO'))                              return '💊';
    return '🍽';
  }


  void _checkManualCalories() {
    if (_caloriesFocus.hasFocus && _caloriesController.text.isNotEmpty) _manualCalories = true;
    if (_caloriesController.text.isEmpty) _manualCalories = false;
  }

  void _calculateCalories() {
    if (_manualCalories && !_caloriesFocus.hasFocus) return;

    final p = double.tryParse(_proteinController.text) ?? 0.0;
    final c = double.tryParse(_carbsController.text) ?? 0.0;
    final f = double.tryParse(_fatController.text) ?? 0.0;

    if ((p > 0 || c > 0 || f > 0) && !_manualCalories) {
      final calcCals = (p * 4) + (c * 4) + (f * 9);
      _caloriesController.removeListener(_checkManualCalories);
      _caloriesController.text = calcCals.toStringAsFixed(0);
      _caloriesController.addListener(_checkManualCalories);
    } else if (p == 0 && c == 0 && f == 0 && !_manualCalories) {
      _caloriesController.removeListener(_checkManualCalories);
      _caloriesController.text = '';
      _caloriesController.addListener(_checkManualCalories);
    }
  }

  String _getDatabaseMealType(String displayMealType) {
    switch (displayMealType.toLowerCase()) {
      case 'café da manhã': return 'breakfast';
      case 'almoço': return 'lunch';
      case 'jantar': return 'dinner';
      case 'lanche': case 'snack': return 'snack';
      case 'pré-treino': return 'pre_workout';
      case 'pós-treino': return 'post_workout';
      default: return 'snack';
    }
  }

  Future<void> _loadRecentFoods() async {
    final userId = getIt<GetCurrentUser>()()?.id;

    if (userId == null) {
      if(mounted) setState(() { _recentFoods = []; _isLoading = false; });
      return;
    }

    try {
      if(mounted) setState(() => _isLoading = true);

      final result = await getIt<GetRecentFoods>()(userId);
      final foods =
          (result.valueOrNull ?? []).map(foodItemToLegacyMap).toList();

      if(mounted) setState(() { _recentFoods = foods; _isLoading = false; });
    } catch (error) {
      debugPrint('Erro ao carregar comidas recentes: $error');
      if(mounted) setState(() { _recentFoods = []; _isLoading = false; });
    }
  }

  Future<void> _loadFavoriteFoods() async {
    final userId = getIt<GetCurrentUser>()()?.id;
    if (userId == null) { if(mounted) setState(() => _isLoadingFavorites = false); return; }
    try {
      if(mounted) setState(() => _isLoadingFavorites = true);
      final result = await getIt<GetFavoriteFoods>()(userId);
      final favorites = result.fold(
        onSuccess: (items) => items.map(foodItemToLegacyMap).toList(),
        onFailure: (failure) => throw Exception(failure.message),
      );
      if (mounted) setState(() { _favoriteFoods = favorites; _isLoadingFavorites = false; });
    } catch (error) {
      debugPrint('Erro ao carregar comidas favoritas: $error');
      if (mounted) { setState(() { _favoriteFoods = []; _isLoadingFavorites = false; }); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).nutrition_favorites_load_error), backgroundColor: AppTheme.errorRed, behavior: SnackBarBehavior.floating)); }
    }
  }

  void _openSearch({String? hint}) {
    if (hint != null && hint.isNotEmpty) { /* ... */ }
    showModalBottomSheet(
      context: context, backgroundColor: BldrColors.sheetBg, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => FirebaseNutritionSearchWidget(
        onFoodSelected: (foodItem) {
          if (mounted) Navigator.pop(context);
          _showPortionSelector(foodItem);
        },
      ),
    );
  }

  Future<void> _saveManualFood() async {
    // Garante que campos obrigatórios dentro do acordeão fiquem visíveis
    // caso a validação abaixo falhe — não altera o resultado da validação,
    // só a visibilidade (os campos já fazem parte do Form mesmo recolhidos).
    setState(() => _iqdAccordionExpanded = true);

    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_proteinController.text.isEmpty && _carbsController.text.isEmpty && _fatController.text.isEmpty && _caloriesController.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).nutrition_fill_one_macro), backgroundColor: AppTheme.errorRed, behavior: SnackBarBehavior.floating)); return; }
    setState(() => _isSavingManual = true);

    final userId = getIt<GetCurrentUser>()()?.id;
    if (userId == null) { /* ... handle error ... */ return; }

    try {
      final name = _nameController.text.trim();
      final calories = double.tryParse(_caloriesController.text) ?? 0.0;
      final protein = double.tryParse(_proteinController.text) ?? 0.0;
      final carbs = double.tryParse(_carbsController.text) ?? 0.0;
      final fat = double.tryParse(_fatController.text) ?? 0.0;
      final sodium = double.tryParse(_sodiumController.text) ?? 0.0;
      final fiber = double.tryParse(_fiberController.text) ?? 0.0;
      final addedSugar = double.tryParse(_addedSugarController.text) ?? 0.0;

      final saveResult = await getIt<SaveFavoriteFood>()(
        FoodItem(
          name: name,
          caloriesPer100g: calories,
          proteinPer100g: protein,
          carbsPer100g: carbs,
          fatPer100g: fat,
          sodiumPer100g: sodium,
          fiberPer100g: fiber,
          addedSugarPer100g: addedSugar,
        ),
        userId,
      );
      final savedItem = saveResult.valueOrNull;
      if (savedItem == null || savedItem.id == null) throw Exception(saveResult.failureOrNull?.message ?? 'Falha ao criar item.');
      final foodItem = foodItemToLegacyMap(savedItem);

      if (_saveToFavorites) await _loadFavoriteFoods();

      if (mounted) Navigator.pop(context); // Fecha modal principal
      _showPortionSelector(foodItem);

    } catch (e) {
      debugPrint('Falha ao salvar comida manual: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).nutrition_save_error(e.toString().replaceFirst('Exception: ', ''))), backgroundColor: AppTheme.errorRed, behavior: SnackBarBehavior.floating));
      if(mounted) setState(() => _isSavingManual = false);
    }
  }

  // ============== UI ==============

  String _formatMealType(String mealType) {
    if (mealType.isEmpty) return '';
    return mealType[0].toUpperCase() + mealType.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.9,
        color: BldrColors.sheetBg,
        child: const Center(child: CircularProgressIndicator(color: BldrColors.goldBright)),
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.9,
      child: Scaffold(
        backgroundColor: BldrColors.sheetBg,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alça
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: BldrColors.textMuted, borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // N10 — cabeçalho indicando a refeição de destino.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: BldrSpacing.pageX),
              child: Text(AppLocalizations.of(context).nutrition_add_to_meal(_formatMealType(widget.mealType)),
                  style: BldrText.cardTitleLg),
            ),
            const SizedBox(height: 14),

            // Barra de busca fixa
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: BldrSpacing.pageX),
              child: GestureDetector(
                onTap: _openSearch,
                child: AbsorbPointer(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).nutrition_search_db_hint,
                      hintStyle: BldrText.description,
                      prefixIcon: const Icon(Icons.search, color: BldrColors.goldBright, size: 20),
                      filled: true,
                      fillColor: BldrColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: BldrColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: BldrColors.border)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Chips de navegação — N12: neutros até serem selecionados.
            // Quando uma categoria está ativa, o badge de categoria abaixo
            // já comunica o estado — "Recentes" não deve parecer também
            // ativo ao mesmo tempo (dois sinais conflitantes).
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: BldrSpacing.pageX),
              child: Row(
                children: [
                  _buildNavChip(AppLocalizations.of(context).nutrition_tab_recent, 0, Icons.history,
                      forceNeutral: widget.selectedCategory != null),
                  const SizedBox(width: 8),
                  _buildNavChip(AppLocalizations.of(context).nutrition_tab_favorites, 1, Icons.star_outline),
                  const SizedBox(width: 8),
                  _buildNavChip(AppLocalizations.of(context).nutrition_tab_manual, 2, Icons.edit_note),
                ],
              ),
            ),

            // Chip de categoria ativa
            if (widget.selectedCategory != null && _selectedTab == 0) ...[
              const SizedBox(height: 10),
              Center(
                child: BldrChip(
                  label: '${_categoryEmoji(widget.selectedCategory)}  ${widget.selectedCategory}',
                  active: true,
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(color: BldrColors.borderSubtle, height: 1),

            // Conteúdo principal
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  // ── Chip de navegação ───────────────────────────────
  Widget _buildNavChip(String label, int index, IconData icon, {bool forceNeutral = false}) {
    final bool isSelected = _selectedTab == index && !forceNeutral;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? BldrColors.goldTintChip : BldrColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? BldrColors.goldBorderChip : BldrColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? BldrColors.goldBright : BldrColors.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              fontFamily: BldrText.family,
              fontSize: 12,
              color: isSelected ? BldrColors.goldBright : BldrColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            )),
          ],
        ),
      ),
    );
  }

  // ── Roteador de conteúdo ────────────────────────────
  Widget _buildContent() {
    switch (_selectedTab) {
      case 0: return _buildRecentOrCategoryContent();
      case 1: return _buildFavoritesContent();
      case 2: return _buildManualTab();
      default: return const SizedBox.shrink();
    }
  }

  // ── Aba Manual — N21: conteúdo rolável + rodapé fixo ────────
  Widget _buildManualTab() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(BldrSpacing.pageX, 12, BldrSpacing.pageX, 16),
            child: _buildManualForm(),
          ),
        ),
        _buildManualFooter(),
      ],
    );
  }

  // ── Lista Recentes / Categoria ──────────────────────
  Widget _buildRecentOrCategoryContent() {
    if (widget.selectedCategory != null) {
      if (_isLoadingCategory) return const Center(child: CircularProgressIndicator(color: BldrColors.goldBright));
      if (_categoryFoods.isEmpty) return Center(child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(AppLocalizations.of(context).nutrition_category_empty, textAlign: TextAlign.center,
            style: BldrText.description),
      ));
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(BldrSpacing.pageX, 0, BldrSpacing.pageX, 16),
        itemCount: _categoryFoods.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _buildFoodRow(_categoryFoods[i]),
      );
    }
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: BldrColors.goldBright));
    if (_recentFoods.isEmpty) return Center(child: Text(AppLocalizations.of(context).nutrition_recent_empty, style: BldrText.description));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(BldrSpacing.pageX, 0, BldrSpacing.pageX, 16),
      itemCount: _recentFoods.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _buildFoodRow(_recentFoods[i]),
    );
  }

  // ── Lista Favoritos ─────────────────────────────────
  Widget _buildFavoritesContent() {
    if (_isLoadingFavorites) return const Center(child: CircularProgressIndicator(color: BldrColors.goldBright));
    if (_favoriteFoods.isEmpty) return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.star_outline, size: 48, color: BldrColors.textMuted),
        const SizedBox(height: 12),
        Text(AppLocalizations.of(context).nutrition_favorites_empty, style: BldrText.body),
        const SizedBox(height: 6),
        Text(AppLocalizations.of(context).nutrition_favorites_hint, textAlign: TextAlign.center,
            style: BldrText.description),
      ],
    ));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(BldrSpacing.pageX, 0, BldrSpacing.pageX, 16),
      itemCount: _favoriteFoods.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _buildFoodRow(_favoriteFoods[i]),
    );
  }

  // ── Linha de alimento — N13/N14/N15 ─────────────────
  Widget _buildFoodRow(Map<String, dynamic> food) {
    final protein  = (food['protein_per_100g']  as num?)?.toInt() ?? 0;
    final carbs    = (food['carbs_per_100g']     as num?)?.toInt() ?? 0;
    final fat      = (food['fat_per_100g']       as num?)?.toInt() ?? 0;
    final calories = (food['calories_per_100g']  as num?)?.toInt() ?? 0;
    final name     = food['name'] as String? ?? food['food_name'] as String? ?? '';

    return BldrFoodItemRow(
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      onTap: () {
        if (Navigator.canPop(context)) Navigator.pop(context);
        _showPortionSelector(food);
      },
    );
  }

  // ── Preview do IQD hipotético — dourado único (G4) ──
  Widget _buildIqdImpactPreview() {
    final projected = _hypotheticalIqdScore;
    final info = IqdCalculatorService.getScoreLabel(projected);
    final current = _currentDayIqd;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BldrColors.goldTint,
        borderRadius: BldrRadius.all(BldrRadius.cardSm),
        border: Border.all(color: BldrColors.goldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context).nutrition_iqd_impact_label, style: BldrText.label),
              if (current != null) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${current.toInt()}', style: BldrText.meta),
                    const SizedBox(width: 4),
                    Icon(
                      projected >= current ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                      color: BldrColors.goldBright,
                    ),
                    const SizedBox(width: 4),
                    Text('${projected.toInt()}/100',
                        style: BldrText.body.copyWith(
                            color: BldrColors.goldBright, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ] else
                Text('${projected.toInt()}/100 — ${info['label']}',
                    style: BldrText.body.copyWith(color: BldrColors.goldBright, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          BldrProgressBar(value: projected / 100.0),
        ],
      ),
    );
  }

  // N21 — rodapé fixo (fora do scroll da aba Manual).
  Widget _buildManualFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(BldrSpacing.pageX, 12, BldrSpacing.pageX, 16),
      decoration: const BoxDecoration(
        color: BldrColors.sheetBg,
        border: Border(top: BorderSide(color: BldrColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIqdImpactPreview(),
          const SizedBox(height: 12),
          BldrPrimaryButton(
            label: _isSavingManual ? AppLocalizations.of(context).nutrition_saving : AppLocalizations.of(context).nutrition_add_meal_btn(_formatMealType(widget.mealType)),
            onPressed: _isSavingManual ? null : _saveManualFood,
          ),
        ],
      ),
    );
  }

  Widget _buildManualForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormInputWidget(
            controller: _nameController,
            label: AppLocalizations.of(context).nutrition_food_name_label,
            suffix: '',
            keyboardType: TextInputType.text,
            isOptional: false,
            onEditComplete: () => FocusScope.of(context).requestFocus(_caloriesFocus),
          ),
          const SizedBox(height: 20),

          // N17 — "Essencial": calorias + 3 macros, sempre visíveis.
          Text(AppLocalizations.of(context).nutrition_essential_label, style: BldrText.sectionTitle),
          const SizedBox(height: 12),
          _FormInputWidget(
            controller: _caloriesController, focusNode: _caloriesFocus,
            label: AppLocalizations.of(context).nutrition_calories, suffix: 'kcal', isOptional: true,
            onEditComplete: () { _manualCalories = _caloriesController.text.isNotEmpty; FocusScope.of(context).requestFocus(_proteinFocus); },
          ),
          const SizedBox(height: 14),

          // N18 — macros em 3 colunas, labels curtos.
          Row(children: [
            Expanded(child: _FormInputWidget(controller: _proteinController, focusNode: _proteinFocus, label: AppLocalizations.of(context).nutrition_protein, suffix: 'g', isOptional: true, onEditComplete: () => FocusScope.of(context).requestFocus(_carbsFocus))),
            const SizedBox(width: 10),
            Expanded(child: _FormInputWidget(controller: _carbsController, focusNode: _carbsFocus, label: AppLocalizations.of(context).nutrition_carbs_short, suffix: 'g', isOptional: true, onEditComplete: () => FocusScope.of(context).requestFocus(_fatFocus))),
            const SizedBox(width: 10),
            Expanded(child: _FormInputWidget(controller: _fatController, focusNode: _fatFocus, label: AppLocalizations.of(context).nutrition_fat, suffix: 'g', isOptional: true, onEditComplete: () => FocusScope.of(context).requestFocus(_sodiumFocus))),
          ]),

          const SizedBox(height: 20),

          // N17 — acordeão recolhido "Dados de qualidade (IQD)". Os campos
          // continuam SEMPRE no Form (Visibility + maintainState), então a
          // validação de obrigatoriedade não muda — só a apresentação.
          GestureDetector(
            onTap: () => setState(() => _iqdAccordionExpanded = !_iqdAccordionExpanded),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Expanded(child: Text(AppLocalizations.of(context).nutrition_iqd_quality_data, style: BldrText.sectionTitle)),
                Icon(
                  _iqdAccordionExpanded ? Icons.expand_less : Icons.expand_more,
                  color: BldrColors.textSecondary,
                ),
              ],
            ),
          ),
          Visibility(
            visible: _iqdAccordionExpanded,
            maintainState: true,
            maintainAnimation: true,
            maintainSize: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FormInputWidget(controller: _sodiumController, focusNode: _sodiumFocus, label: AppLocalizations.of(context).nutrition_sodium, suffix: 'mg', isOptional: false, onEditComplete: () => FocusScope.of(context).requestFocus(_fiberFocus)),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: _FormInputWidget(controller: _fiberController, focusNode: _fiberFocus, label: AppLocalizations.of(context).nutrition_fibers, suffix: 'g', isOptional: false, onEditComplete: () => FocusScope.of(context).requestFocus(_addedSugarFocus))),
                    const SizedBox(width: 10),
                    Expanded(child: _FormInputWidget(controller: _addedSugarController, focusNode: _addedSugarFocus, label: AppLocalizations.of(context).nutrition_sugars, suffix: 'g', isOptional: false, onEditComplete: () => FocusScope.of(context).unfocus())),
                  ]),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _saveToFavorites = !_saveToFavorites),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(
                  _saveToFavorites ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  color: _saveToFavorites ? BldrColors.goldBright : BldrColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(AppLocalizations.of(context).nutrition_save_favorites, style: BldrText.body),
              ],
            ),
          ),
        ],
      ),
    );
  }

    Future<void> _loadCategoryFoods(String category) async {
      if (mounted) setState(() => _isLoadingCategory = true);
      try {
        final result = await getIt<GetCategoryFoods>()(category);
        final foods = result.fold(
          onSuccess: (items) => items.map(foodItemToLegacyMap).toList(),
          onFailure: (failure) => throw Exception(failure.message),
        );
        if (mounted) setState(() { _categoryFoods = foods; _isLoadingCategory = false; });
      } catch (e) {
        debugPrint('Erro ao carregar categoria: $e');
        if (mounted) setState(() { _categoryFoods = []; _isLoadingCategory = false; });
      }
    }

  // ====== _showPortionSelector (g, mL, unidade) ======
  void _showPortionSelector(Map<String, dynamic> foodItem, {bool isEditingFlow = false}) {

    if (!isEditingFlow) {
      if (mounted && _isSavingManual) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if(mounted) setState(() => _isSavingManual = false);
        });
      }
    }

    double initialQuantity = isEditingFlow
        ? (foodItem['quantity_grams'] as num?)?.toDouble() ?? 100.0
        : 100.0;

    double quantity = initialQuantity;
    String selectedUnit = 'g';
    TextEditingController unitWeightController = TextEditingController(text: '50');

    double minQty = 10.0;
    double maxQty = 500.0;
    int divisions = 49;
    int decimals = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: BldrColors.sheetBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (modalBuilderContext) => StatefulBuilder(
        builder: (context, setModalState) {

          if (selectedUnit == 'un') {
            minQty = 0.5;
            maxQty = 10.0;
            divisions = 19;
            decimals = 1;
            if (quantity > maxQty) quantity = 1.0;
          } else {
            minQty = 10.0;
            maxQty = 500.0;
            divisions = 49;
            decimals = 0;
            if (quantity < minQty) quantity = 100.0;
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 32, left: 20, right: 20, top: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container( width: 36, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration( color: BldrColors.textMuted, borderRadius: BorderRadius.circular(2)))),
                Text(isEditingFlow ? AppLocalizations.of(context).nutrition_edit_quantity : AppLocalizations.of(context).nutrition_set_portion, style: BldrText.cardTitleLg),
                const SizedBox(height: 4),
                Text((foodItem['food_name'] ?? foodItem['name'] ?? AppLocalizations.of(context).nutrition_food_label) as String, style: BldrText.description),

                const SizedBox(height: 20),
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: BldrColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: BldrColors.border),
                  ),
                  child: Row(
                    children: [
                      _buildUnitToggleOptionSimple(AppLocalizations.of(context).nutrition_grams, 'g', selectedUnit, (val) {
                        setModalState(() => selectedUnit = val);
                      }),
                      const VerticalDivider(width: 1, color: BldrColors.border),
                      _buildUnitToggleOptionSimple('mL', 'mL', selectedUnit, (val) {
                        setModalState(() => selectedUnit = val);
                      }),
                      const VerticalDivider(width: 1, color: BldrColors.border),
                      _buildUnitToggleOptionSimple(AppLocalizations.of(context).nutrition_unit, 'un', selectedUnit, (val) {
                        setModalState(() => selectedUnit = val);
                      }),
                    ],
                  ),
                ),

                if (selectedUnit == 'un') ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(AppLocalizations.of(context).nutrition_unit_weight_label, style: BldrText.description),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: unitWeightController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontFamily: BldrText.family, color: BldrColors.goldBright, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            suffixText: 'g',
                            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: BldrColors.border)),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: BldrColors.goldBright)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final qty in [50.0, 100.0, 150.0, 200.0, 300.0])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setModalState(() {
                              selectedUnit = 'g';
                              quantity = qty.clamp(minQty, maxQty);
                            }),
                            child: BldrChip(
                              label: '${qty.toInt()}g',
                              active: quantity == qty && selectedUnit == 'g',
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTap: () => setModalState(() {
                          selectedUnit = 'un';
                          quantity = 1.0.clamp(minQty, maxQty);
                        }),
                        child: BldrChip(label: AppLocalizations.of(context).nutrition_unit_short, active: selectedUnit == 'un'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                Row(children: [
                  Text(AppLocalizations.of(context).nutrition_quantity_label, style: BldrText.body),
                  const Spacer(),
                  Text(
                    '${quantity.toStringAsFixed(decimals)} $selectedUnit',
                    style: BldrText.cardTitleLg.copyWith(color: BldrColors.goldBright),
                  ),
                ]),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: BldrColors.goldBright,
                    inactiveTrackColor: BldrColors.border,
                    thumbColor: BldrColors.goldBright,
                  ),
                  child: Slider(
                    value: quantity, min: minQty, max: maxQty, divisions: divisions,
                    label: quantity.toStringAsFixed(decimals),
                    onChanged: (value) { setModalState(() { quantity = value; }); },
                  ),
                ),
                const SizedBox(height: 20),
                BldrPrimaryButton(
                  label: isEditingFlow ? AppLocalizations.of(context).nutrition_update_quantity : AppLocalizations.of(context).nutrition_add_food_btn,
                  onPressed: () async {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final onFoodAddedCallback = widget.onFoodAdded;
                    final mealType = widget.mealType;
                    final selectedDate = widget.selectedDate;

                    try {
                      final dbMealType = _getDatabaseMealType(mealType);

                      double finalQuantityGrams = quantity;
                      if (selectedUnit == 'un') {
                        double unitWeight = double.tryParse(unitWeightController.text) ?? 50.0;
                        finalQuantityGrams = quantity * unitWeight;
                      }

                      if (isEditingFlow) {
                        final result = await getIt<UpdateMealQuantity>()(
                          entry: legacyMapToMealEntry(foodItem),
                          newQuantityGrams: finalQuantityGrams,
                        );
                        final failure = result.failureOrNull;
                        if (failure != null) throw Exception(failure.message);
                      } else {
                        final userId = getIt<GetCurrentUser>()()?.id;
                        if (userId == null) throw Exception(AppLocalizations.of(context).common_unauthenticated);
                        final result = await getIt<LogMeal>()(
                          userId: userId,
                          mealType: dbMealType,
                          mealDate: selectedDate,
                          food: legacyMapToFoodItem(foodItem),
                          quantityGrams: finalQuantityGrams,
                        );
                        final failure = result.failureOrNull;
                        if (failure != null) throw Exception(failure.message);
                        unawaited(getIt<CheckAndUnlockAchievements>()('nutrition'));
                        // F21: verificar se meta calórica foi atingida
                        final userId2 = userId;
                        final date2 = selectedDate;
                        unawaited(() async {
                          final summary = await getIt<GetDailySummary>()(date2);
                          final goals = await getIt<GetNutritionGoals>()(userId2);
                          final totalCal =
                              summary.valueOrNull?.totals.calories ?? 0;
                          final goalCal =
                              goals.valueOrNull?.calories ?? 0;
                          if (goalCal > 0 && totalCal >= goalCal) {
                            await getIt<TryIncrementOperation>()(
                                'calorie_goal', 1);
                          }
                        }());
                      }

                      unawaited(WidgetDataService.updateAll());
                      scaffoldMessenger.showSnackBar(SnackBar(content: Text(isEditingFlow ? AppLocalizations.of(context).nutrition_item_updated : AppLocalizations.of(context).nutrition_food_added), backgroundColor: AppTheme.successGreen, behavior: SnackBarBehavior.floating));
                      if (Navigator.canPop(modalBuilderContext)) Navigator.pop(modalBuilderContext);
                      if (isEditingFlow && Navigator.canPop(context)) Navigator.pop(context);
                      onFoodAddedCallback();

                    } catch (e) {
                      debugPrint('Falha ao adicionar/atualizar: $e');
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(SnackBar(
                          content: Text(AppLocalizations.of(context).nutrition_fail(e.toString().replaceFirst('Exception: ', ''))),
                          backgroundColor: AppTheme.errorRed, behavior: SnackBarBehavior.floating,
                        ));
                      }
                      if(Navigator.canPop(modalBuilderContext)) Navigator.pop(modalBuilderContext);
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnitToggleOptionSimple(String label, String value, String currentSelection, Function(String) onChanged) {
    bool isSelected = value == currentSelection;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(value),
        child: Container(
          alignment: Alignment.center,
          color: isSelected ? BldrColors.goldTintChip : Colors.transparent,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: BldrText.family,
              color: isSelected ? BldrColors.goldBright : BldrColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

} // Fim da classe _AddFoodModalWidgetState

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({Key? key}) : super(key: key);
  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  bool _handled = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BldrColors.bgBase,
      appBar: AppBar(backgroundColor: BldrColors.bgBase, title: Text(AppLocalizations.of(context).nutrition_scan_title)),
      body: Stack(children: [
        MobileScanner(onDetect: (capture) {
          if (_handled) return;
          final code = capture.barcodes.isNotEmpty ? capture.barcodes.first.rawValue : null;
          if (code != null && code.isNotEmpty) {
            _handled = true;
            if (mounted) Navigator.pop(context, code);
          }
        },
        ),
        Align(alignment: Alignment.bottomCenter, child: Padding(padding: const EdgeInsets.all(16), child: Text(AppLocalizations.of(context).nutrition_scan_hint_qr, style: BldrText.description))),
      ]),
    );
  }
}
