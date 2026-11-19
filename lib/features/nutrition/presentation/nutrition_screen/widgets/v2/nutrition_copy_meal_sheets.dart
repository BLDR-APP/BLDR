import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:intl/intl.dart';

import 'package:bldr_fitness/design_system/bldr_nutrition_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';
import 'package:bldr_fitness/features/nutrition/domain/entities/meal_entry.dart';
import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/widgets/v2/nutrition_hub_sections.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Destino escolhido no primeiro passo da cópia.
class CopyDestination {
  final DateTime date;
  final NutritionMealSlot slot;
  const CopyDestination(this.date, this.slot);
}

/// Copiar refeição (Figma 102:313 destino → 102:314 revisão → 102:315
/// sucesso). Três [BldrV2Sheet] em sequência; a gravação fica com a tela.
abstract final class NutritionCopyMealSheets {
  static String _kcal(AppLocalizations l, num v) =>
      NumberFormat.decimalPattern(l.localeName).format(v.round());

  static Future<CopyDestination?> destination(
    BuildContext context, {
    required NutritionMealSlot source,
    required List<MealEntry> entries,
    required DateTime today,
  }) {
    final l = AppLocalizations.of(context);
    final kcal = entries.fold<double>(0, (a, e) => a + e.macros.calories);
    return BldrV2Sheet.show<CopyDestination>(
      context,
      eyebrow: l.nutri2_copy_eyebrow,
      title: l.nutri2_copy_dest_title,
      closeLabel: l.nutri2_close,
      child: _DestinationBody(
        description: l.nutri2_copy_desc(
            source.label(l).toUpperCase(), _kcal(l, kcal), entries.length),
        initial: CopyDestination(today, source),
        today: today,
      ),
    );
  }

  static Future<bool> review(
    BuildContext context, {
    required CopyDestination dest,
    required List<MealEntry> entries,
    required DateTime today,
  }) async {
    final l = AppLocalizations.of(context);
    final ok = await BldrV2Sheet.show<bool>(
      context,
      eyebrow: l.nutri2_copy_eyebrow,
      title: l.nutri2_copy_review_title,
      closeLabel: l.nutri2_close,
      child: Builder(
        builder: (ctx) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${NutritionHubHeader.dateLine(l, dest.date, today)}  ›  ${dest.slot.label(l)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: BldrNutritionTextV2.copyRoute,
            ),
            const SizedBox(height: 30),
            Text(l.nutri2_copy_list_label,
                style: BldrNutritionTextV2.copyLabel),
            const SizedBox(height: 10),
            for (final e in entries)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                constraints: const BoxConstraints(minHeight: 60),
                decoration: BoxDecoration(
                  color: BldrNutritionColorsV2.rowBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(e.foodName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BldrNutritionTextV2.copyFood),
                    const SizedBox(height: 4),
                    Text(
                        l.nutri2_qty_kcal(
                            '${e.quantityGrams.round()}${e.isLiquid ? ' ml' : 'g'}',
                            _kcal(l, e.macros.calories)),
                        style: BldrNutritionTextV2.copyFoodMeta),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            Text(l.nutri2_copy_behavior, style: BldrNutritionTextV2.copyDesc),
            const SizedBox(height: 40),
            BldrNutritionCta(
              compact: true,
              label: l.nutri2_copy_confirm,
              onTap: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );
    return ok ?? false;
  }

  static Future<void> success(
    BuildContext context, {
    required int count,
    required NutritionMealSlot slot,
  }) {
    final l = AppLocalizations.of(context);
    return BldrV2Sheet.show<void>(
      context,
      eyebrow: l.nutri2_copy_eyebrow,
      title: l.nutri2_copy_done_title,
      closeLabel: l.nutri2_close,
      child: Builder(
        builder: (ctx) => Column(
          children: [
            const SizedBox(height: 60),
            const Icon(TablerIcons.check,
                size: 44, color: BldrNutritionColorsV2.goldBright),
            const SizedBox(height: 28),
            Text(l.nutri2_copy_done_text(count, slot.label(l)),
                textAlign: TextAlign.center,
                style: BldrNutritionTextV2.copyDone),
            const SizedBox(height: 14),
            Text(l.nutri2_copy_done_sub,
                textAlign: TextAlign.center,
                style: BldrNutritionTextV2.copyDesc),
            const SizedBox(height: 120),
            BldrNutritionCta(
              compact: true,
              label: l.nutri2_copy_finish,
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationBody extends StatefulWidget {
  final String description;
  final CopyDestination initial;
  final DateTime today;
  const _DestinationBody(
      {required this.description, required this.initial, required this.today});

  @override
  State<_DestinationBody> createState() => _DestinationBodyState();
}

class _DestinationBodyState extends State<_DestinationBody> {
  late DateTime _date = widget.initial.date;
  late NutritionMealSlot _slot = widget.initial.slot;

  Future<void> _pickDate() async {
    final l = AppLocalizations.of(context);
    final d = await BldrV2Sheet.show<DateTime>(
      context,
      title: l.nutri2_date_sheet_title,
      child: Builder(
        builder: (ctx) => NutritionDateSheetList(
          selected: _date,
          today: widget.today,
          onSelect: (v) => Navigator.pop(ctx, v),
        ),
      ),
    );
    if (d != null && mounted) setState(() => _date = d);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: BldrNutritionTextV2.copyDesc),
        const SizedBox(height: 32),
        Text(l.nutri2_copy_date_label, style: BldrNutritionTextV2.copyLabel),
        const SizedBox(height: 10),
        Semantics(
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _pickDate,
            child: Container(
              constraints: const BoxConstraints(minHeight: 59),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: BldrNutritionColorsV2.rowBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                Expanded(
                  child: Text(
                      NutritionHubHeader.dateLine(l, _date, widget.today),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrNutritionTextV2.copyDate),
                ),
                const Icon(TablerIcons.chevron_right,
                    size: 16, color: BldrNutritionColorsV2.text),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(l.nutri2_copy_meal_label, style: BldrNutritionTextV2.copyLabel),
        const SizedBox(height: 10),
        for (final s in NutritionMealSlot.all)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Semantics(
              button: true,
              selected: s.dbKey == _slot.dbKey,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _slot = s),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 36),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                  decoration: BoxDecoration(
                    color: s.dbKey == _slot.dbKey
                        ? BldrNutritionColorsV2.chipActiveBg
                        : BldrNutritionColorsV2.rowBg,
                    borderRadius: BorderRadius.circular(9),
                    border: s.dbKey == _slot.dbKey
                        ? Border.all(color: BldrNutritionColorsV2.gold)
                        : null,
                  ),
                  child: Row(children: [
                    Expanded(
                      child: Text(s.label(l),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: s.dbKey == _slot.dbKey
                              ? BldrNutritionTextV2.copyOptionOn
                              : BldrNutritionTextV2.copyOption),
                    ),
                    if (s.dbKey == _slot.dbKey)
                      const Icon(TablerIcons.check,
                          size: 14, color: BldrNutritionColorsV2.goldBright),
                  ]),
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        BldrNutritionCta(
          compact: true,
          label: l.nutri2_copy_continue,
          onTap: () => Navigator.pop(context, CopyDestination(_date, _slot)),
        ),
      ],
    );
  }
}
