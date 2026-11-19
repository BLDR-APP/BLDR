import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';

import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/design_system/bldr_nutrition_v2_components.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/daily_nutrition_summary.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/meal_entry.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/nutrition_goals.dart';
import 'package:bldr_fitness/features/nutrition/domain/services/iqd_calculator.dart';
import 'package:bldr_fitness/features/nutrition/domain/usecases/nutrition_usecases.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Seções do Nutrition Hub v2 (Figma 102:312 / 102:309 / 14:2 / 102:297).
/// Só apresentação: dados chegam prontos da tela.

/// Tipo de refeição do hub. [dbKey] é o valor gravado em `meal_type`;
/// [legacyName] é o nome que o modal de adição atual entende.
class NutritionMealSlot {
  final String dbKey;
  final String legacyName;
  final IconData icon;
  const NutritionMealSlot(this.dbKey, this.legacyName, this.icon);

  String label(AppLocalizations l) => switch (dbKey) {
        'breakfast' => l.nutrition_breakfast,
        'snack' => l.nutrition_snack,
        'lunch' => l.nutrition_lunch,
        'pre_workout' => l.nutrition_pre_workout,
        'post_workout' => l.nutrition_post_workout,
        _ => l.nutrition_dinner,
      };

  /// Ordem e ícones do mockup (Tabler, conforme as camadas).
  static const all = [
    NutritionMealSlot('breakfast', 'café da manhã', TablerIcons.sunrise),
    NutritionMealSlot('snack', 'lanche', TablerIcons.coffee),
    NutritionMealSlot('lunch', 'almoço', TablerIcons.sunset_2),
    NutritionMealSlot('pre_workout', 'pré-treino', TablerIcons.bolt),
    NutritionMealSlot('post_workout', 'pós-treino', TablerIcons.barbell),
    NutritionMealSlot('dinner', 'jantar', TablerIcons.moon),
  ];

  /// Sugestão pelo horário (FAB).
  static NutritionMealSlot suggested(DateTime now) {
    final h = now.hour;
    if (h < 10) return all[0];
    if (h < 14) return all[2];
    if (h < 18) return all[1];
    return all[5];
  }
}

String _fmtInt(num v, String locale) =>
    NumberFormat.decimalPattern(locale).format(v.round());

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// ── Header ──────────────────────────────────────────────────────────────────
class NutritionHubHeader extends StatelessWidget {
  final DateTime date;
  final DateTime today;
  final VoidCallback onDateTap;
  const NutritionHubHeader({
    super.key,
    required this.date,
    required this.today,
    required this.onDateTap,
  });

  static String dateLine(AppLocalizations l, DateTime date, DateTime today) {
    final md = DateFormat.MMMMd(l.localeName).format(date);
    if (_isSameDay(date, today)) return l.nutri2_date_today(md);
    final y = DateTime(today.year, today.month, today.day - 1);
    if (_isSameDay(date, y)) return l.nutri2_date_yesterday(md);
    final full = DateFormat.MMMMEEEEd(l.localeName).format(date);
    return full[0].toUpperCase() + full.substring(1);
  }

  static String pillLabel(AppLocalizations l, DateTime date, DateTime today) {
    if (_isSameDay(date, today)) return l.nutri2_pill_today;
    return DateFormat('d MMM', l.localeName)
        .format(date)
        .replaceAll('.', '')
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.nutri2_eyebrow, style: BldrNutritionTextV2.eyebrow),
              const SizedBox(height: 8),
              Text(l.nutri2_title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BldrNutritionTextV2.title),
              const SizedBox(height: 2),
              Text(dateLine(l, date, today),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BldrNutritionTextV2.date),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child:
              BldrDatePill(label: pillLabel(l, date, today), onTap: onDateTap),
        ),
      ],
    );
  }
}

// ── Anéis ───────────────────────────────────────────────────────────────────
class NutritionHubRings extends StatelessWidget {
  final DailyNutritionSummary summary;
  final NutritionGoals goals;
  const NutritionHubRings(
      {super.key, required this.summary, required this.goals});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final loc = l.localeName;
    final t = summary.totals;
    BldrMacroRingData m(String label, double v, int g) => BldrMacroRingData(
          label: label,
          valueText: '${v.round()}g',
          goalText: l.nutri2_macro_goal('$g'),
          value: v,
          goal: g.toDouble(),
        );
    return Column(children: [
      BldrKcalRing(
        consumed: t.calories,
        goal: goals.calories.toDouble(),
        valueText: _fmtInt(t.calories, loc),
        goalText: l.nutri2_kcal_goal(_fmtInt(goals.calories, loc)),
      ),
      const SizedBox(height: 7),
      BldrMacroRings(macros: [
        m(l.nutri2_protein, t.protein, goals.protein),
        m(l.nutri2_carbs, t.carbs, goals.carbs),
        m(l.nutri2_fat, t.fat, goals.fat),
      ]),
    ]);
  }
}

// ── IQD ─────────────────────────────────────────────────────────────────────
class NutritionIqdCard extends StatelessWidget {
  final IqdWeeklyComparison? iqd;
  final bool locked;
  final VoidCallback? onUnlock;
  const NutritionIqdCard(
      {super.key, required this.iqd, required this.locked, this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final score = iqd?.score ?? 60;
    final band = switch (IqdCalculator.bandOf(score)) {
      IqdBand.veryGood => l.nutri2_iqd_very_good,
      IqdBand.regular => l.nutri2_iqd_regular,
      IqdBand.poor => l.nutri2_iqd_poor,
    };
    final delta = iqd?.delta;
    Widget? deltaLine;
    if (delta != null) {
      final up = delta > 0;
      final text = delta == 0
          ? l.nutri2_iqd_delta_same
          : (up
              ? l.nutri2_iqd_delta_up(delta.abs())
              : l.nutri2_iqd_delta_down(delta.abs()));
      deltaLine = Text.rich(
        TextSpan(children: [
          if (delta != 0)
            TextSpan(
                text: up ? '↑ ' : '↓ ',
                style: TextStyle(
                    color: up
                        ? BldrNutritionColorsV2.positive
                        : BldrNutritionColorsV2.over)),
          TextSpan(text: text),
        ]),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: BldrNutritionTextV2.iqdDelta,
      );
    }
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.nutri2_iqd_title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BldrNutritionTextV2.sectionLabel),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(band, maxLines: 1, style: BldrNutritionTextV2.iqdBand),
                  if (deltaLine != null) ...[
                    const SizedBox(height: 14),
                    deltaLine,
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text('${score.round()}', style: BldrNutritionTextV2.iqdScore),
          ],
        ),
        const SizedBox(height: 14),
        BldrMetricBar(
          progress: (score - 60) / 40,
          gradient: BldrNutritionColorsV2.iqdGradient,
          showDot: true,
        ),
        const SizedBox(height: 4),
        Row(children: [
          Text('60', style: BldrNutritionTextV2.barScale),
          const Spacer(),
          Text('100', style: BldrNutritionTextV2.barScale),
        ]),
      ],
    );
    if (!locked) return content;
    // FREE: mesmo blur + cadeado de antes; toque leva ao checkout.
    return Semantics(
      button: true,
      label: l.nutri2_iqd_locked,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onUnlock,
        child: Stack(children: [
          ExcludeSemantics(
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: content,
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(TablerIcons.lock,
                    size: 16, color: BldrNutritionColorsV2.gold),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(l.nutri2_iqd_locked,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrNutritionTextV2.iqdBand),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Hidratação ──────────────────────────────────────────────────────────────
class NutritionHydrationCard extends StatelessWidget {
  final int intakeMl;
  final int goalMl;

  /// `null` desabilita o "+" (dias passados: o registro de água é sempre de
  /// hoje).
  final VoidCallback? onAdd;
  const NutritionHydrationCard({
    super.key,
    required this.intakeMl,
    required this.goalMl,
    this.onAdd,
  });

  static String liters(int ml, String locale) =>
      NumberFormat('0.0#', locale).format(ml / 1000);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ratio = goalMl <= 0 ? 0.0 : intakeMl / goalMl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.nutri2_hydration,
                      style: BldrNutritionTextV2.sectionLabel),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: '${liters(intakeMl, l.localeName)} L  ',
                          style: BldrNutritionTextV2.waterValue),
                      TextSpan(
                          text:
                              l.nutri2_water_goal(liters(goalMl, l.localeName)),
                          style: BldrNutritionTextV2.waterGoal),
                    ]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Opacity(
              opacity: onAdd == null ? 0.35 : 1,
              child: Transform.translate(
                offset: const Offset(8, -8),
                child: BldrSmallAddButton(
                    semanticLabel: l.nutri2_water_add, onTap: onAdd),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        BldrMetricBar(
            progress: ratio, gradient: BldrNutritionColorsV2.waterGradient),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text('${(ratio * 100).round()}%',
              style: BldrNutritionTextV2.barScale),
        ),
      ],
    );
  }
}

// ── Refeições ───────────────────────────────────────────────────────────────
class NutritionMealsSection extends StatelessWidget {
  final bool isToday;
  final List<MealEntry> entries;
  final String? expandedKey;
  final bool editMode;
  final ValueChanged<NutritionMealSlot> onToggle;
  final ValueChanged<NutritionMealSlot> onAdd;
  final VoidCallback onToggleEdit;
  final ValueChanged<MealEntry> onEditFood;
  final ValueChanged<MealEntry> onRemoveFood;

  /// "⋯" da refeição expandida → Copiar refeição (N5). Só aparece em
  /// refeições com alimentos.
  final ValueChanged<NutritionMealSlot>? onCopy;
  const NutritionMealsSection({
    super.key,
    required this.isToday,
    required this.entries,
    required this.expandedKey,
    required this.editMode,
    required this.onToggle,
    required this.onAdd,
    required this.onToggleEdit,
    required this.onEditFood,
    required this.onRemoveFood,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final loc = l.localeName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(
            child: Text(isToday ? l.nutri2_meals_today : l.nutri2_meals_day,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BldrNutritionTextV2.mealsTitle),
          ),
          // Lápis: liga/desliga o modo de edição (decisão aprovada).
          Semantics(
            button: true,
            toggled: editMode,
            label: editMode ? l.nutri2_edit_done : l.nutri2_edit_meals,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onToggleEdit,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(editMode ? TablerIcons.check : TablerIcons.edit,
                    size: 14, color: BldrNutritionColorsV2.gold),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, c) {
          final pillW = bldrMealPillWidth(context, c.maxWidth);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final slot in NutritionMealSlot.all) ...[
                _meal(context, l, loc, slot, pillW),
                const SizedBox(height: BldrNutritionV2.mealGap),
              ],
            ],
          );
        }),
      ],
    );
  }

  Widget _meal(BuildContext context, AppLocalizations l, String loc,
      NutritionMealSlot slot, double pillW) {
    final items = entries.where((e) => e.mealType == slot.dbKey).toList();
    var kcal = 0.0, p = 0.0, c = 0.0, f = 0.0;
    for (final e in items) {
      kcal += e.macros.calories;
      p += e.macros.protein;
      c += e.macros.carbs;
      f += e.macros.fat;
    }
    final names =
        items.map((e) => e.foodName.trim()).where((n) => n.isNotEmpty);
    final detail = names.isEmpty ? l.nutri2_meal_empty : names.join(', ');
    final kcalText = '${_fmtInt(kcal, loc)} kcal';
    final name = slot.label(l).toUpperCase();

    if (expandedKey != slot.dbKey) {
      return SizedBox(
        width: pillW,
        child: BldrMealPill(
          icon: slot.icon,
          name: name,
          kcalText: kcalText,
          detail: detail,
          onTap: () => onToggle(slot),
        ),
      );
    }
    return BldrMealExpandedCard(
      icon: slot.icon,
      name: name,
      kcalText: kcalText,
      detail: detail,
      emptyText: items.isEmpty ? l.nutri2_meal_empty : null,
      macros: [
        (l.nutri2_macro_protein, '${p.round()}g'),
        (l.nutri2_macro_carbs, '${c.round()}g'),
        (l.nutri2_macro_fat, '${f.round()}g'),
      ],
      foods: [
        for (var i = 0; i < items.length; i++)
          BldrFoodRow(
            name: items[i].foodName,
            quantity:
                '${items[i].quantityGrams.round()}${items[i].isLiquid ? ' ml' : 'g'}',
            macros: l.nutri2_food_macros(
              _fmtInt(items[i].macros.calories, loc),
              '${items[i].macros.protein.round()}',
              '${items[i].macros.carbs.round()}',
              '${items[i].macros.fat.round()}',
            ),
            showDivider: i < items.length - 1,
            actions: editMode ? _foodActions(l, items[i]) : null,
          ),
      ],
      addLabel: l.nutri2_add_food,
      onAdd: () => onAdd(slot),
      onCollapse: () => onToggle(slot),
      menu: onCopy == null || items.isEmpty
          ? null
          : Semantics(
              button: true,
              label: l.nutri2_meal_menu_title,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onCopy!(slot),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(TablerIcons.dots,
                      size: 18, color: BldrNutritionColorsV2.goldBright),
                ),
              ),
            ),
    );
  }

  Widget _foodActions(AppLocalizations l, MealEntry e) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconButton(TablerIcons.pencil, l.nutri2_edit_food,
              BldrNutritionColorsV2.gold, () => onEditFood(e)),
          _iconButton(TablerIcons.trash, l.nutri2_remove_food,
              BldrNutritionColorsV2.over, () => onRemoveFood(e)),
        ],
      );

  Widget _iconButton(
          IconData icon, String label, Color color, VoidCallback onTap) =>
      Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Icon(icon, size: 16, color: color),
          ),
        ),
      );
}

// ── Seletor de data (só dias passados) ──────────────────────────────────────
class NutritionDateSheetList extends StatelessWidget {
  final DateTime selected;
  final DateTime today;
  final int days;
  final ValueChanged<DateTime> onSelect;
  const NutritionDateSheetList({
    super.key,
    required this.selected,
    required this.today,
    required this.onSelect,
    this.days = 30,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      children: [
        for (var i = 0; i <= days; i++)
          Builder(builder: (context) {
            final d = DateTime(today.year, today.month, today.day - i);
            final active = _isSameDay(d, selected);
            final title = i == 0
                ? l.nutri2_today
                : i == 1
                    ? l.nutri2_yesterday
                    : () {
                        final s = DateFormat.EEEE(l.localeName).format(d);
                        return s[0].toUpperCase() + s.substring(1);
                      }();
            return Semantics(
              button: true,
              selected: active,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelect(d),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 50),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: BldrSheetV2Colors.button,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: active
                            ? BldrSheetV2Colors.border
                            : BldrSheetV2Colors.buttonBorder),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BldrSheetV2Text.option),
                    ),
                    const SizedBox(width: 8),
                    Text(DateFormat.MMMd(l.localeName).format(d),
                        style: BldrSheetV2Text.label),
                    if (active) ...[
                      const SizedBox(width: 10),
                      const Icon(TablerIcons.check,
                          size: 18, color: BldrSheetV2Colors.border),
                    ],
                  ]),
                ),
              ),
            );
          }),
      ],
    );
  }
}

// ── Corpo da tela (sem dependências: a tela injeta dados e ações) ──────────
class NutritionHubView extends StatelessWidget {
  final DateTime date;
  final DateTime today;
  final DailyNutritionSummary summary;
  final NutritionGoals goals;
  final IqdWeeklyComparison? iqd;
  final bool iqdLocked;
  final int waterMl;
  final List<MealEntry> entries;
  final String? expandedKey;
  final bool editMode;
  final bool fabVisible;
  final Future<void> Function() onRefresh;
  final VoidCallback onDateTap;
  final VoidCallback onUnlockIqd;
  final VoidCallback? onAddWater;
  final ValueChanged<NutritionMealSlot> onToggleMeal;
  final ValueChanged<NutritionMealSlot> onAddFood;
  final VoidCallback onToggleEdit;
  final ValueChanged<MealEntry> onEditFood;
  final ValueChanged<MealEntry> onRemoveFood;
  final VoidCallback onFab;
  final ValueChanged<NutritionMealSlot>? onCopyMeal;

  const NutritionHubView({
    super.key,
    required this.date,
    required this.today,
    required this.summary,
    required this.goals,
    required this.iqd,
    required this.iqdLocked,
    required this.waterMl,
    required this.entries,
    required this.expandedKey,
    required this.editMode,
    required this.fabVisible,
    required this.onRefresh,
    required this.onDateTap,
    required this.onUnlockIqd,
    required this.onAddWater,
    required this.onToggleMeal,
    required this.onAddFood,
    required this.onToggleEdit,
    required this.onEditFood,
    required this.onRemoveFood,
    required this.onFab,
    this.onCopyMeal,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pageX = BldrSpacingV2.pageX(MediaQuery.sizeOf(context).width);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return BldrBackground(
      v2: true,
      child: Stack(children: [
        SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: onRefresh,
            color: BldrColors.goldBright,
            backgroundColor: BldrColors.surface,
            child: ListView(
              padding: EdgeInsets.fromLTRB(pageX, 10, pageX, bottomInset + 110),
              children: [
                NutritionHubHeader(
                    date: date, today: today, onDateTap: onDateTap),
                const SizedBox(height: 4),
                NutritionHubRings(summary: summary, goals: goals),
                const SizedBox(height: 10),
                NutritionIqdCard(
                    iqd: iqd, locked: iqdLocked, onUnlock: onUnlockIqd),
                const SizedBox(height: 14),
                NutritionHydrationCard(
                    intakeMl: waterMl,
                    goalMl: goals.waterMl,
                    onAdd: onAddWater),
                const SizedBox(height: 26),
                NutritionMealsSection(
                  isToday: _isSameDay(date, today),
                  entries: entries,
                  expandedKey: expandedKey,
                  editMode: editMode,
                  onToggle: onToggleMeal,
                  onAdd: onAddFood,
                  onToggleEdit: onToggleEdit,
                  onEditFood: onEditFood,
                  onRemoveFood: onRemoveFood,
                  onCopy: onCopyMeal,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: pageX,
          bottom: bottomInset + 84,
          child: BldrNutritionFab(
            visible: fabVisible,
            semanticLabel: l.nutri2_add_food_a11y,
            onTap: onFab,
          ),
        ),
      ]),
    );
  }
}
