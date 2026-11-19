import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';

import 'package:bldr_fitness/design_system/bldr_nutrition_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/macro_nutrients.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/saved_meal.dart';
import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/widgets/v2/nutrition_hub_sections.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

String _n(num v) => '${v.round()}';
String _kcal(AppLocalizations l, num v) =>
    NumberFormat.decimalPattern(l.localeName).format(v.round());

/// Ação escolhida no "⋯" da refeição expandida.
enum MealMenuAction { copy, save }

/// Resultado do detalhe (102:319): adicionar, voltar à lista ou excluir.
enum SavedMealDetailAction { add, back, delete }

/// Refeições salvas (N7): menu do "⋯", salvar com nome, lista (102:318),
/// detalhe (102:319) e confirmação (102:320).
abstract final class NutritionSavedMealSheets {
  /// "⋯": Copiar refeição (N5) ou Salvar como refeição (N7).
  static Future<MealMenuAction?> menu(BuildContext context) {
    final l = AppLocalizations.of(context);
    return BldrV2Sheet.show<MealMenuAction>(
      context,
      title: l.nutri2_meal_menu_title,
      child: Builder(
        builder: (ctx) => Column(children: [
          BldrV2SheetOption(
            icon: TablerIcons.copy,
            label: l.nutri2_copy_menu,
            onTap: () => Navigator.pop(ctx, MealMenuAction.copy),
          ),
          BldrV2SheetOption(
            icon: TablerIcons.bookmark,
            label: l.nutri2_save_meal_menu,
            onTap: () => Navigator.pop(ctx, MealMenuAction.save),
          ),
        ]),
      ),
    );
  }

  /// Nome da refeição a salvar. Devolve o nome digitado.
  static Future<String?> name(BuildContext context,
      {required String initial, required int count, required double kcal}) {
    final l = AppLocalizations.of(context);
    return BldrV2Sheet.show<String>(
      context,
      eyebrow: l.nutri2_saved_eyebrow,
      title: l.nutri2_save_meal_title,
      subtitle: l.nutri2_save_meal_desc(count, _kcal(l, kcal)),
      closeLabel: l.nutri2_close,
      child: _NameBody(initial: initial),
    );
  }

  /// Lista (102:318). Devolve a refeição tocada.
  static Future<SavedMeal?> list(BuildContext context,
      {required Future<List<SavedMeal>> Function() load}) {
    final l = AppLocalizations.of(context);
    return BldrV2Sheet.show<SavedMeal>(
      context,
      eyebrow: l.nutri2_saved_eyebrow,
      title: l.nutri2_saved_title,
      closeLabel: l.nutri2_close,
      child: _ListBody(load: load),
    );
  }

  /// Detalhe (102:319): adicionar, voltar ou excluir (ação destrutiva no
  /// mesmo estilo de "Remover alimento").
  static Future<SavedMealDetailAction?> detail(BuildContext context,
      {required SavedMeal meal}) {
    final l = AppLocalizations.of(context);
    return BldrV2Sheet.show<SavedMealDetailAction>(
      context,
      eyebrow: l.nutri2_saved_detail_eyebrow,
      title: meal.name,
      closeLabel: l.nutri2_close,
      child: Builder(
        builder: (ctx) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BackLine(
              text: l.nutri2_saved_detail_sub(
                  meal.description, meal.items.length),
              onBack: () => Navigator.pop(ctx, SavedMealDetailAction.back),
            ),
            const SizedBox(height: 14),
            _SummaryCard(totals: meal.totals),
            const SizedBox(height: 20),
            Text(l.nutri2_saved_items, style: BldrNutritionTextV2.savedLabel),
            const SizedBox(height: 10),
            for (final i in meal.items)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                constraints: const BoxConstraints(minHeight: 58),
                decoration: BoxDecoration(
                  color: BldrNutritionColorsV2.savedCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(i.foodName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BldrNutritionTextV2.savedFood),
                    const SizedBox(height: 4),
                    Text(
                        l.nutri2_qty_kcal(
                            '${_n(i.quantityGrams)}${i.unit == 'ml' ? ' ml' : 'g'}',
                            _kcal(l, i.macros.calories)),
                        style: BldrNutritionTextV2.savedFoodMeta),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            BldrNutritionCta(
              label: l.nutri2_saved_add,
              onTap: () => Navigator.pop(ctx, SavedMealDetailAction.add),
            ),
            Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.pop(ctx, SavedMealDetailAction.delete),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(l.nutri2_saved_delete,
                      style: BldrNutritionTextV2.removeCta),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Confirmação (102:320): refeição de destino no dia do hub.
  static Future<NutritionMealSlot?> confirm(BuildContext context,
      {required SavedMeal meal, required NutritionMealSlot initial}) {
    final l = AppLocalizations.of(context);
    return BldrV2Sheet.show<NutritionMealSlot>(
      context,
      eyebrow: l.nutri2_saved_confirm_eyebrow,
      title: l.nutri2_saved_confirm_title,
      closeLabel: l.nutri2_close,
      child: _ConfirmBody(meal: meal, initial: initial),
    );
  }
}

class _BackLine extends StatelessWidget {
  final String text;
  final VoidCallback onBack;
  const _BackLine({required this.text, required this.onBack});

  @override
  Widget build(BuildContext context) => Row(children: [
        Semantics(
          button: true,
          label: AppLocalizations.of(context).nutri2_back,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack,
            child: const Padding(
              padding: EdgeInsets.fromLTRB(0, 4, 14, 4),
              child: Icon(TablerIcons.chevron_left,
                  size: 20, color: BldrNutritionColorsV2.goldBright),
            ),
          ),
        ),
        Expanded(
          child: Text(text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: BldrNutritionTextV2.savedSub),
        ),
      ]);
}

class _SummaryCard extends StatelessWidget {
  final MacroNutrients totals;
  const _SummaryCard({required this.totals});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: BldrNutritionColorsV2.savedCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${_kcal(l, totals.calories)} kcal',
              style: BldrNutritionTextV2.savedKcal),
          const SizedBox(height: 6),
          Text(
              l.nutri2_saved_macros(
                  _n(totals.protein), _n(totals.carbs), _n(totals.fat)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BldrNutritionTextV2.savedMacros),
        ],
      ),
    );
  }
}

class _NameBody extends StatefulWidget {
  final String initial;
  const _NameBody({required this.initial});
  @override
  State<_NameBody> createState() => _NameBodyState();
}

class _NameBodyState extends State<_NameBody> {
  late final _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.nutri2_save_meal_name, style: BldrNutritionTextV2.fieldLabel),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: BldrNutritionColorsV2.summaryBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: BldrNutritionColorsV2.summaryBorder, width: 0.8),
          ),
          child: TextField(
            controller: _c,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            style: BldrNutritionTextV2.inputValue,
            cursorColor: BldrNutritionColorsV2.gold,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: l.nutri2_save_meal_hint,
              hintStyle: BldrNutritionTextV2.inputHint,
            ),
          ),
        ),
        const SizedBox(height: 28),
        BldrNutritionCta(
          label: l.nutri2_save_meal_cta,
          onTap: _c.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _c.text.trim()),
        ),
      ],
    );
  }
}

class _ListBody extends StatefulWidget {
  final Future<List<SavedMeal>> Function() load;
  const _ListBody({required this.load});
  @override
  State<_ListBody> createState() => _ListBodyState();
}

class _ListBodyState extends State<_ListBody> {
  final _q = TextEditingController();
  List<SavedMeal>? _meals;

  @override
  void initState() {
    super.initState();
    widget.load().then((m) {
      if (mounted) setState(() => _meals = m);
    });
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final q = _q.text.trim().toLowerCase();
    final list = _meals
        ?.where((m) => q.isEmpty || m.name.toLowerCase().contains(q))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
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
                controller: _q,
                onChanged: (_) => setState(() {}),
                style: BldrNutritionTextV2.searchInput,
                cursorColor: BldrNutritionColorsV2.gold,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: l.nutri2_saved_search,
                  hintStyle: BldrNutritionTextV2.searchHint,
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        Text(l.nutri2_saved_list, style: BldrNutritionTextV2.mealsTitle),
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
            child: Text(l.nutri2_saved_empty,
                textAlign: TextAlign.center, style: BldrNutritionTextV2.hint),
          )
        else
          for (final m in list) _row(l, m),
      ],
    );
  }

  Widget _row(AppLocalizations l, SavedMeal m) {
    final t = m.totals;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context, m),
        child: Container(
          constraints: const BoxConstraints(minHeight: 74),
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
                  Text(m.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrNutritionTextV2.rowName),
                  const SizedBox(height: 4),
                  Text(m.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrNutritionTextV2.rowMeta),
                  const SizedBox(height: 4),
                  Text(
                      l.nutri2_saved_macros(
                          _n(t.protein), _n(t.carbs), _n(t.fat)),
                      maxLines: 1,
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
                Text('${_kcal(l, t.calories)} kcal',
                    style: BldrNutritionTextV2.rowKcal),
                const SizedBox(height: 14),
                const Icon(TablerIcons.chevron_right,
                    size: 16, color: BldrNutritionColorsV2.goldBright),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}

class _ConfirmBody extends StatefulWidget {
  final SavedMeal meal;
  final NutritionMealSlot initial;
  const _ConfirmBody({required this.meal, required this.initial});
  @override
  State<_ConfirmBody> createState() => _ConfirmBodyState();
}

class _ConfirmBodyState extends State<_ConfirmBody> {
  late NutritionMealSlot _slot = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final m = widget.meal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BackLine(
          text: l.nutri2_saved_detail_sub(m.name, m.items.length),
          onBack: () => Navigator.pop(context),
        ),
        const SizedBox(height: 14),
        _SummaryCard(totals: m.totals),
        const SizedBox(height: 20),
        Text(l.nutri2_add_in, style: BldrNutritionTextV2.fieldLabel),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final s in NutritionMealSlot.all)
            IntrinsicWidth(
              child: BldrNutritionChip(
                label: s.label(l).toUpperCase(),
                active: s.dbKey == _slot.dbKey,
                onTap: () => setState(() => _slot = s),
              ),
            ),
        ]),
        const SizedBox(height: 12),
        Text(l.nutri2_saved_confirm_note(m.items.length),
            style: BldrNutritionTextV2.hint),
        const SizedBox(height: 26),
        BldrNutritionCta(
          label: l.nutri2_saved_confirm_cta,
          onTap: () => Navigator.pop(context, _slot),
        ),
      ],
    );
  }
}
