import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';

import 'package:bldr_fitness/design_system/bldr_nutrition_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/food_item.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/meal_entry.dart';
import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/widgets/v2/nutrition_hub_sections.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Fonte de dados do sheet de adicionar (a tela injeta os casos de uso).
class AddFoodCatalog {
  final Future<List<FoodItem>> Function(String query) search;
  final Future<List<FoodItem>> Function(String category) byCategory;
  final Future<List<FoodItem>> Function() recents;
  final Future<List<FoodItem>> Function() favorites;
  const AddFoodCatalog({
    required this.search,
    required this.byCategory,
    required this.recents,
    required this.favorites,
  });
}

/// O que o sheet de adicionar devolve: um alimento escolhido ou o pedido
/// de cadastro manual (formulário atual, até a N4).
class AddFoodPick {
  final FoodItem? food;
  final bool createManual;

  /// Atalho "Refeições salvas" (N7).
  final bool savedMeals;
  const AddFoodPick.food(FoodItem this.food)
      : createManual = false,
        savedMeals = false;
  const AddFoodPick.manual()
      : food = null,
        createManual = true,
        savedMeals = false;
  const AddFoodPick.savedMeals()
      : food = null,
        createManual = false,
        savedMeals = true;
}

/// Categorias reais da base `alimentos` (valor gravado + rótulo). O carrossel
/// do Figma usa nomes ilustrativos; aqui ficam os que existem no dado.
class NutritionFoodCategory {
  final String firestoreValue;
  final String Function(AppLocalizations) label;
  const NutritionFoodCategory(this.firestoreValue, this.label);

  static final all = <NutritionFoodCategory>[
    NutritionFoodCategory('CARNES E AVES', (l) => l.nutrition_cat_meat),
    NutritionFoodCategory(
        'PEIXES E FRUTOS DO MAR', (l) => l.nutrition_cat_fish),
    NutritionFoodCategory('OVOS', (l) => l.nutrition_cat_eggs),
    NutritionFoodCategory('LATICÍNIOS', (l) => l.nutrition_cat_dairy),
    NutritionFoodCategory('GRÃOS E CEREAIS', (l) => l.nutrition_cat_grains),
    NutritionFoodCategory('FRUTAS', (l) => l.nutrition_cat_fruits),
    NutritionFoodCategory(
        'LEGUMES E VERDURAS (HORTALIÇAS)', (l) => l.nutrition_cat_vegetables),
    NutritionFoodCategory(
        'OLEAGINOSAS E SEMENTES', (l) => l.nutrition_cat_nuts),
    NutritionFoodCategory('GORDURAS E ÓLEOS', (l) => l.nutrition_cat_fats),
    NutritionFoodCategory('BEBIDAS', (l) => l.nutrition_cat_drinks),
    NutritionFoodCategory('DOCES E SOBREMESAS', (l) => l.nutrition_cat_sweets),
    NutritionFoodCategory(
        'REFEIÇÕES PRONTAS', (l) => l.nutrition_cat_readymeals),
    NutritionFoodCategory('ITENS DE FAST FOOD (MÉDIA DE MERCADO)',
        (l) => l.nutrition_cat_fastfood),
    NutritionFoodCategory(
        'PRODUTOS INDUSTRIALIZADOS (COMUNS)', (l) => l.nutrition_cat_processed),
    NutritionFoodCategory(
        'MOLHOS, TEMPEROS E CONDIMENTOS', (l) => l.nutrition_cat_sauces),
    NutritionFoodCategory('SUPLEMENTOS', (l) => l.nutrition_cat_supplements),
  ];
}

String _n(num v) => '${v.round()}';

/// Linha de alimento dos sheets (102:316/317): nome, base, kcal e "+".
class NutritionFoodPickRow extends StatelessWidget {
  final FoodItem food;
  final VoidCallback onTap;
  const NutritionFoodPickRow(
      {super.key, required this.food, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = food.macrosFor(100);
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
          decoration: BoxDecoration(
            color: BldrNutritionColorsV2.mealCardBg,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
                color: BldrNutritionColorsV2.foodRowBorder, width: 0.7),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(food.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrNutritionTextV2.rowName),
                  const SizedBox(height: 4),
                  Text(
                      food.isLiquid
                          ? l.nutri2_food_meta_ml(
                              '100', _n(m.protein), _n(m.carbs), _n(m.fat))
                          : l.nutri2_food_meta(
                              '100', _n(m.protein), _n(m.carbs), _n(m.fat)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: BldrNutritionTextV2.rowMeta),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${_n(m.calories)} kcal',
                    style: BldrNutritionTextV2.rowKcal),
                Text('+', style: BldrNutritionTextV2.rowAdd),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  const _SearchField(
      {required this.controller, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 46),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: BldrNutritionColorsV2.searchBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BldrNutritionColorsV2.gold),
        ),
        child: Row(children: [
          const Icon(TablerIcons.search,
              size: 16, color: BldrNutritionColorsV2.goldBright),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: BldrNutritionTextV2.searchInput,
              cursorColor: BldrNutritionColorsV2.gold,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: BldrNutritionTextV2.searchHint,
              ),
            ),
          ),
        ]),
      );
}

// ── Adicionar Alimentos (102:316) ───────────────────────────────────────────
abstract final class NutritionAddFoodSheet {
  static Future<AddFoodPick?> show(BuildContext context,
      {required AddFoodCatalog catalog}) {
    final l = AppLocalizations.of(context);
    return BldrV2Sheet.show<AddFoodPick>(
      context,
      eyebrow: l.nutri2_eyebrow,
      title: l.nutri2_add_title,
      closeLabel: l.nutri2_close,
      child: _AddFoodBody(catalog: catalog),
    );
  }
}

class _AddFoodBody extends StatefulWidget {
  final AddFoodCatalog catalog;
  const _AddFoodBody({required this.catalog});

  @override
  State<_AddFoodBody> createState() => _AddFoodBodyState();
}

class _AddFoodBodyState extends State<_AddFoodBody> {
  final _query = TextEditingController();
  Timer? _debounce;
  NutritionFoodCategory? _category;
  List<FoodItem> _recents = const [];
  List<FoodItem>? _results;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    widget.catalog.recents().then((r) {
      if (mounted) setState(() => _recents = r);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onQuery(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final text = q.trim();
      if (text.length < 2) {
        if (!mounted) return;
        if (_category == null) setState(() => _results = null);
        if (_category != null) {
          _loadCategory(_category!);
        }
        return;
      }
      setState(() => _loading = true);
      final r = await widget.catalog.search(text);
      if (mounted && _query.text.trim() == text) {
        setState(() {
          _results = r;
          _loading = false;
        });
      }
    });
  }

  Future<void> _loadCategory(NutritionFoodCategory c) async {
    setState(() => _loading = true);
    final r = await widget.catalog.byCategory(c.firestoreValue);
    if (mounted && _category == c) {
      setState(() {
        _results = r;
        _loading = false;
      });
    }
  }

  void _selectCategory(NutritionFoodCategory? c) {
    _query.clear();
    setState(() {
      _category = c;
      _results = null;
    });
    if (c != null) _loadCategory(c);
  }

  Future<void> _openUnified() async {
    final food = await NutritionRecentFavoritesSheet.show(context,
        catalog: widget.catalog);
    if (food != null && mounted) {
      Navigator.pop(context, AddFoodPick.food(food));
    }
  }

  void _pick(FoodItem f) => Navigator.pop(context, AddFoodPick.food(f));

  Widget _tile(IconData icon, String label, {VoidCallback? onTap}) {
    final l = AppLocalizations.of(context);
    final soon = onTap == null;
    return Semantics(
      button: true,
      enabled: !soon,
      label: soon ? '$label · ${l.nutri2_coming_soon}' : label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: BldrNutritionColorsV2.tileBg,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: BldrNutritionColorsV2.tileBorder, width: 0.8),
          ),
          child: ExcludeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: soon ? 0.45 : 1,
                  child: Icon(icon,
                      size: 20, color: BldrNutritionColorsV2.goldBright),
                ),
                const SizedBox(height: 6),
                Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: BldrNutritionTextV2.tileLabel),
                if (soon) ...[
                  const SizedBox(height: 2),
                  Text(l.nutri2_coming_soon,
                      maxLines: 1, style: BldrNutritionTextV2.soon),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _catChip(String label, bool on, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Semantics(
          button: true,
          selected: on,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 28),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 13),
              decoration: BoxDecoration(
                color: on ? null : BldrNutritionColorsV2.tileBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: on
                        ? BldrNutritionColorsV2.gold
                        : BldrNutritionColorsV2.catBorder,
                    width: 0.8),
              ),
              child: Text(label,
                  maxLines: 1,
                  style: on
                      ? BldrNutritionTextV2.catChipOn
                      : BldrNutritionTextV2.catChip),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final showingResults = _results != null || _loading;
    final list = _results ?? _recents.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SearchField(
            controller: _query,
            hint: l.nutri2_search_hint,
            onChanged: _onQuery),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, c) {
          final scale = MediaQuery.textScalerOf(context).scale(1);
          final tiles = [
            _tile(TablerIcons.history, l.nutri2_sc_recent_fav,
                onTap: _openUnified),
            _tile(TablerIcons.list_details, l.nutri2_sc_saved_meals,
                onTap: () =>
                    Navigator.pop(context, const AddFoodPick.savedMeals())),
            _tile(TablerIcons.barcode, l.nutri2_sc_barcode),
            _tile(TablerIcons.camera, l.nutri2_sc_photo),
          ];
          // Estreito: 2 × 2 para os rótulos não espremerem.
          if (c.maxWidth < 360 * scale) {
            return Column(children: [
              Row(children: [
                Expanded(child: tiles[0]),
                const SizedBox(width: 9),
                Expanded(child: tiles[1]),
              ]),
              const SizedBox(height: 9),
              Row(children: [
                Expanded(child: tiles[2]),
                const SizedBox(width: 9),
                Expanded(child: tiles[3]),
              ]),
            ]);
          }
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const SizedBox(width: 9),
                  Expanded(child: tiles[i]),
                ],
              ],
            ),
          );
        }),
        const SizedBox(height: 15),
        SizedBox(
          height: 30,
          child: ShaderMask(
            shaderCallback: (r) => const LinearGradient(
              colors: [Colors.white, Colors.white, Colors.transparent],
              stops: [0, 0.92, 1],
            ).createShader(r),
            blendMode: BlendMode.dstIn,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _catChip(l.nutri2_cat_all, _category == null,
                    () => _selectCategory(null)),
                for (final cat in NutritionFoodCategory.all)
                  _catChip(cat.label(l).toUpperCase(), _category == cat,
                      () => _selectCategory(cat)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(
            child: Text(
                _category != null
                    ? _category!.label(l).toUpperCase()
                    : showingResults
                        ? l.nutri2_results
                        : l.nutri2_recent,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BldrNutritionTextV2.mealsTitle),
          ),
          if (!showingResults && _category == null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _openUnified,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child:
                    Text(l.nutri2_view_all, style: BldrNutritionTextV2.viewAll),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: BldrNutritionColorsV2.gold),
              ),
            ),
          )
        else if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(l.nutri2_empty_list,
                textAlign: TextAlign.center, style: BldrNutritionTextV2.hint),
          )
        else
          for (final f in list)
            NutritionFoodPickRow(food: f, onTap: () => _pick(f)),
        // Cadastro manual (formulário atual) mantido até a N4.
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context, const AddFoodPick.manual()),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(TablerIcons.plus,
                    size: 13, color: BldrNutritionColorsV2.goldBright),
                const SizedBox(width: 6),
                Text(l.nutri2_create_food, style: BldrNutritionTextV2.viewAll),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Recentes e Favoritos (102:317) ──────────────────────────────────────────
abstract final class NutritionRecentFavoritesSheet {
  static Future<FoodItem?> show(BuildContext context,
      {required AddFoodCatalog catalog}) {
    final l = AppLocalizations.of(context);
    return BldrV2Sheet.show<FoodItem>(
      context,
      eyebrow: l.nutri2_add_food_eyebrow,
      title: l.nutri2_add_title,
      closeLabel: l.nutri2_close,
      child: _RecentFavBody(catalog: catalog),
    );
  }
}

class _RecentFavBody extends StatefulWidget {
  final AddFoodCatalog catalog;
  const _RecentFavBody({required this.catalog});

  @override
  State<_RecentFavBody> createState() => _RecentFavBodyState();
}

class _RecentFavBodyState extends State<_RecentFavBody> {
  final _query = TextEditingController();
  int _tab = 0;
  List<FoodItem>? _recents;
  List<FoodItem>? _favorites;

  @override
  void initState() {
    super.initState();
    widget.catalog.recents().then((r) {
      if (mounted) setState(() => _recents = r);
    });
    widget.catalog.favorites().then((r) {
      if (mounted) setState(() => _favorites = r);
    });
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Widget _tabButton(String label, int index) {
    final on = _tab == index;
    return Expanded(
      child: Semantics(
        button: true,
        selected: on,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _tab = index),
          child: Column(children: [
            Text(label,
                maxLines: 1,
                style: on
                    ? BldrNutritionTextV2.tabOn
                    : BldrNutritionTextV2.tabOff),
            const SizedBox(height: 6),
            Container(
              width: 76,
              height: 2,
              color: on ? BldrNutritionColorsV2.goldBright : Colors.transparent,
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final source = _tab == 0 ? _recents : _favorites;
    final q = _query.text.trim().toLowerCase();
    final list = source
        ?.where((f) => q.isEmpty || f.name.toLowerCase().contains(q))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SearchField(
          controller: _query,
          hint: l.nutri2_search_list_hint,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        Row(children: [
          _tabButton(l.nutri2_tab_recent, 0),
          _tabButton(l.nutri2_tab_favorites, 1),
        ]),
        const SizedBox(height: 22),
        Text(_tab == 0 ? l.nutri2_last_foods : l.nutri2_fav_foods,
            style: BldrNutritionTextV2.mealsTitle),
        const SizedBox(height: 12),
        if (list == null)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: BldrNutritionColorsV2.gold),
              ),
            ),
          )
        else if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
                _tab == 0
                    ? l.nutrition_recent_empty
                    : l.nutrition_favorites_empty,
                textAlign: TextAlign.center,
                style: BldrNutritionTextV2.hint),
          )
        else
          for (final f in list)
            NutritionFoodPickRow(
                food: f, onTap: () => Navigator.pop(context, f)),
      ],
    );
  }
}

// ── Porção (102:308) e edição (102:301) ─────────────────────────────────────

/// Resultado do sheet de porção/edição.
class PortionResult {
  final double grams;
  final NutritionMealSlot slot;
  final bool remove;
  const PortionResult(this.grams, this.slot) : remove = false;
  const PortionResult.remove(this.slot)
      : grams = 0,
        remove = true;
}

abstract final class NutritionPortionSheet {
  /// Novo alimento: quantidade, tipo de porção, medida, info e refeição.
  static Future<PortionResult?> add(BuildContext context,
      {required FoodItem food, required NutritionMealSlot slot}) {
    final l = AppLocalizations.of(context);
    return BldrV2Sheet.show<PortionResult>(
      context,
      eyebrow: l.nutri2_eyebrow,
      title: food.name,
      closeLabel: l.nutri2_close,
      child: _PortionBody(food: food, slot: slot, initialGrams: 100),
    );
  }

  /// Alimento registrado: mesma medida, salvar ou remover.
  static Future<PortionResult?> edit(BuildContext context,
      {required MealEntry entry, required NutritionMealSlot slot}) {
    final l = AppLocalizations.of(context);
    final p = entry.per100g;
    final food = FoodItem(
      id: entry.foodItemId,
      name: entry.foodName,
      caloriesPer100g: p.calories,
      proteinPer100g: p.protein,
      carbsPer100g: p.carbs,
      fatPer100g: p.fat,
      sodiumPer100g: p.sodium,
      fiberPer100g: p.fiber,
      addedSugarPer100g: p.addedSugar,
      isLiquid: entry.isLiquid,
    );
    return BldrV2Sheet.show<PortionResult>(
      context,
      eyebrow: l.nutri2_eyebrow,
      title: entry.foodName,
      subtitle: l.nutri2_edit_subtitle(slot.label(l)),
      closeLabel: l.nutri2_close,
      child: _PortionBody(
          food: food,
          slot: slot,
          initialGrams: entry.quantityGrams,
          editing: true),
    );
  }
}

class _PortionBody extends StatefulWidget {
  final FoodItem food;
  final NutritionMealSlot slot;
  final double initialGrams;
  final bool editing;
  const _PortionBody({
    required this.food,
    required this.slot,
    required this.initialGrams,
    this.editing = false,
  });

  @override
  State<_PortionBody> createState() => _PortionBodyState();
}

class _PortionBodyState extends State<_PortionBody> {
  /// Alimento com peso de unidade cadastrado (N4) abre em "Unidade".
  late final double? _savedUnit = widget.food.unitWeight;
  late bool _byUnit = !widget.editing && _savedUnit != null;
  late double _unitWeight = _savedUnit ?? 50;
  late double _qty = _byUnit ? 1 : widget.initialGrams.roundToDouble();
  late NutritionMealSlot _slot = widget.slot;
  late final _unitCtrl =
      TextEditingController(text: NumberFormat('0.#').format(_unitWeight));

  double get _grams => _byUnit ? _qty * _unitWeight : _qty;

  @override
  void dispose() {
    _unitCtrl.dispose();
    super.dispose();
  }

  void _setByUnit(bool v) {
    if (v == _byUnit) return;
    setState(() {
      _byUnit = v;
      _qty = v ? 1 : (_qty * _unitWeight).roundToDouble();
    });
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BldrNutritionTextV2.fieldLabel),
      );

  Widget _segment(String label, bool on, VoidCallback? onTap,
          {double height = 48, double radius = 16}) =>
      Semantics(
        button: true,
        selected: on,
        enabled: onTap != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Opacity(
            opacity: onTap == null && !on ? 0.45 : 1,
            child: Container(
              constraints: BoxConstraints(minHeight: height),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: on ? null : BldrNutritionColorsV2.quantityCardBg,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                    color: on
                        ? BldrNutritionColorsV2.gold
                        : BldrNutritionColorsV2.quantityCardBorder,
                    width: on ? 1 : 0.8),
              ),
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: on
                      ? BldrNutritionTextV2.segmentOn
                      : BldrNutritionTextV2.segment),
            ),
          ),
        ),
      );

  Widget _qtyField(AppLocalizations l) {
    final step = _byUnit ? 1.0 : 10.0;
    final min = _byUnit ? 1.0 : 1.0;
    final fmt = NumberFormat('0.#', l.localeName);
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: BldrNutritionColorsV2.chipActiveBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BldrNutritionColorsV2.gold, width: 0.8),
      ),
      child: Row(children: [
        Semantics(
          button: true,
          label: l.nutri2_water_less,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(
                () => _qty = (_qty - step).clamp(min, 9999).toDouble()),
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Text('−', style: BldrNutritionTextV2.qtyMinus),
            ),
          ),
        ),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(fmt.format(_qty),
                maxLines: 1, style: BldrNutritionTextV2.qtyValue),
          ),
        ),
        Semantics(
          button: true,
          label: l.nutri2_water_more,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(
                () => _qty = (_qty + step).clamp(min, 9999).toDouble()),
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Text('+', style: BldrNutritionTextV2.qtyPlus),
            ),
          ),
        ),
      ]),
    );
  }

  /// Resumo "por X g". [narrow]: kcal numa linha e macros embaixo, para os
  /// rótulos ficarem em 11 px.
  Widget _summary(AppLocalizations l, dynamic m, {required bool narrow}) {
    final kcal = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_n(m.calories), style: BldrNutritionTextV2.sumKcal),
        Text('kcal', style: BldrNutritionTextV2.sumUnit),
      ],
    );
    final macros = <Widget>[
      for (final (label, value) in [
        (l.nutri2_p_short, m.protein as double),
        (l.nutri2_c_short, m.carbs as double),
        (l.nutri2_f_short, m.fat as double),
      ]) ...[
        Container(
            width: 0.6, height: 38, color: BldrNutritionColorsV2.summaryBorder),
        const SizedBox(width: 10),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BldrNutritionTextV2.sumLabel),
              const SizedBox(height: 6),
              Text('${_n(value)} g',
                  maxLines: 1, style: BldrNutritionTextV2.sumValue),
            ],
          ),
        ),
      ],
    ];
    return Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: BldrNutritionColorsV2.summaryBg,
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: BldrNutritionColorsV2.summaryBorder, width: 0.7),
      ),
      child: narrow
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              kcal,
              const SizedBox(height: 10),
              // Sem divisórias no estreito: mais espaço para os rótulos.
              Row(
                  children: macros
                      .whereType<Expanded>()
                      .expand((e) => [e, const SizedBox(width: 8)])
                      .toList()),
            ])
          : Row(children: [Expanded(flex: 6, child: kcal), ...macros]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = widget.food.macrosFor(_grams);
    final gramsText = NumberFormat('0.#', l.localeName).format(_grams);
    final scale = MediaQuery.textScalerOf(context).scale(1);

    final portionType = Row(children: [
      Expanded(
          child: _segment(l.nutri2_portion, !_byUnit, () => _setByUnit(false))),
      const SizedBox(width: 4),
      Expanded(child: _segment(l.nutri2_unit, _byUnit, () => _setByUnit(true))),
    ]);

    return LayoutBuilder(builder: (context, c) {
      // Na edição a quantidade ocupa a linha toda (102:301); em telas
      // estreitas, também no novo alimento.
      final stackQty = widget.editing || c.maxWidth < 360 * scale;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (stackQty) ...[
            _label(l.nutri2_qty),
            _qtyField(l),
            const SizedBox(height: 16),
            _label(l.nutri2_portion_type),
            portionType,
          ] else
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: c.maxWidth * 126 / 396,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [_label(l.nutri2_qty), _qtyField(l)],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [_label(l.nutri2_portion_type), portionType],
                ),
              ),
            ]),
          if (_byUnit) ...[
            const SizedBox(height: 14),
            _label(widget.food.isLiquid
                ? l.nutri2_unit_weight_ml
                : l.nutri2_unit_weight),
            if (widget.food.unitDescription != null) ...[
              Text(widget.food.unitDescription!,
                  style: BldrNutritionTextV2.hint),
              const SizedBox(height: 6),
            ],
            Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: BldrNutritionColorsV2.quantityCardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: BldrNutritionColorsV2.quantityCardBorder,
                    width: 0.8),
              ),
              alignment: Alignment.centerLeft,
              child: TextField(
                controller: _unitCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: BldrNutritionTextV2.searchInput,
                cursorColor: BldrNutritionColorsV2.gold,
                decoration: const InputDecoration(
                    isDense: true, border: InputBorder.none),
                onChanged: (v) => setState(() =>
                    _unitWeight = (double.tryParse(v) ?? 50).clamp(1, 5000)),
              ),
            ),
          ],
          const SizedBox(height: 18),
          _label(l.nutri2_measure),
          Row(children: [
            // Base de cálculo do alimento: g (sólido) ou ml (líquido, N4).
            SizedBox(
                width: 88,
                child: _segment('g', !widget.food.isLiquid, null,
                    height: 38, radius: 14)),
            const SizedBox(width: 8),
            SizedBox(
                width: 88,
                child: _segment('ml', widget.food.isLiquid, null,
                    height: 38, radius: 14)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(l.nutri2_measure_hint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: BldrNutritionTextV2.hint),
            ),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: _label(l.nutri2_nutrition_info)),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                  widget.food.isLiquid
                      ? l.nutri2_per_ml(gramsText)
                      : l.nutri2_per_grams(gramsText),
                  style: BldrNutritionTextV2.perGrams),
            ),
          ]),
          _summary(l, m,
              narrow: stackQty && !widget.editing || c.maxWidth < 360 * scale),
          if (!widget.editing) ...[
            const SizedBox(height: 18),
            _label(l.nutri2_add_in),
            if (c.maxWidth < 360 * scale)
              // Estreito: chips quebram em linhas (todas as refeições à vista).
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in NutritionMealSlot.all)
                  IntrinsicWidth(
                    child: _segment(s.label(l).toUpperCase(),
                        s.dbKey == _slot.dbKey, () => setState(() => _slot = s),
                        height: 34, radius: 17),
                  ),
              ])
            else
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final s in NutritionMealSlot.all)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _segment(
                            s.label(l).toUpperCase(),
                            s.dbKey == _slot.dbKey,
                            () => setState(() => _slot = s),
                            height: 34,
                            radius: 17),
                      ),
                  ],
                ),
              ),
            if (c.maxWidth >= 360 * scale) ...[
              const SizedBox(height: 8),
              Text(l.nutri2_add_in_hint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: BldrNutritionTextV2.hint),
            ],
          ],
          const SizedBox(height: 28),
          BldrNutritionCta(
            label: widget.editing ? l.nutri2_save_changes : l.nutri2_add_cta,
            onTap: _grams > 0
                ? () => Navigator.pop(context, PortionResult(_grams, _slot))
                : null,
          ),
          if (widget.editing)
            Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    Navigator.pop(context, PortionResult.remove(_slot)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(l.nutri2_remove_cta,
                      style: BldrNutritionTextV2.removeCta),
                ),
              ),
            ),
        ],
      );
    });
  }
}

// ── Remover (102:300) ───────────────────────────────────────────────────────
abstract final class NutritionRemoveFoodSheet {
  static Future<bool> show(BuildContext context,
      {required MealEntry entry, required NutritionMealSlot slot}) async {
    final l = AppLocalizations.of(context);
    final ok = await BldrV2Sheet.show<bool>(
      context,
      eyebrow: l.nutri2_eyebrow,
      title: l.nutri2_remove_title,
      subtitle: l.nutri2_remove_subtitle(entry.foodName, slot.label(l)),
      closeLabel: l.nutri2_close,
      child: Builder(
        builder: (ctx) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 18),
            Text(l.nutri2_remove_warning,
                textAlign: TextAlign.center,
                style: BldrNutritionTextV2.removeWarning),
            const SizedBox(height: 36),
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(ctx, true),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 50),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: BldrNutritionColorsV2.removeBg,
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(color: BldrNutritionColorsV2.removeRed),
                  ),
                  child: Text(l.nutri2_remove_cta,
                      style: BldrNutritionTextV2.removeCta),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(ctx, false),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: BldrNutritionColorsV2.summaryBg,
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(
                        color: BldrNutritionColorsV2.summaryBorder, width: 0.8),
                  ),
                  child: Text(l.nutri2_cancel,
                      style: BldrNutritionTextV2.cancelCta),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return ok ?? false;
  }
}
