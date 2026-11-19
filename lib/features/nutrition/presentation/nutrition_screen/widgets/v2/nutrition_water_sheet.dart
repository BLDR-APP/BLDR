import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/design_system/bldr_nutrition_v2_components.dart';
import 'package:bldr_fitness/design_system/bldr_v2_sheet.dart';
import 'package:bldr_fitness/features/nutrition/presentation/nutrition_screen/widgets/v2/nutrition_hub_sections.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Resultado do sheet de água: adicionar [addMl] ou abrir a remoção.
class WaterSheetResult {
  final int? addMl;
  final bool remove;
  const WaterSheetResult.add(int ml)
      : addMl = ml,
        remove = false;
  const WaterSheetResult.remove()
      : addMl = null,
        remove = true;
}

/// Sheet "Adicionar água" (Figma 102:311). Barra azul (decisão aprovada);
/// sem o texto de "configurações de Nutrição"; link pequeno para remover
/// registro (mantido do app atual).
abstract final class NutritionWaterSheet {
  static Future<WaterSheetResult?> show(
    BuildContext context, {
    required int intakeMl,
    required int goalMl,
  }) {
    final l = AppLocalizations.of(context);
    return BldrV2Sheet.show<WaterSheetResult>(
      context,
      eyebrow: l.nutri2_water_sheet_eyebrow,
      title: l.nutri2_water_sheet_title,
      subtitle: l.nutri2_water_sheet_subtitle,
      child: NutritionWaterSheetBody(intakeMl: intakeMl, goalMl: goalMl),
    );
  }

  /// Remoção (mesmas quantidades do app atual: 150/250/350/500 ≤ total).
  static Future<int?> showRemove(BuildContext context,
      {required int intakeMl}) {
    final l = AppLocalizations.of(context);
    final amounts = [150, 250, 350, 500].where((a) => a <= intakeMl).toList();
    return BldrV2Sheet.show<int>(
      context,
      title: l.nutri2_water_remove_title,
      child: Builder(
        builder: (ctx) => Column(children: [
          if (amounts.isEmpty)
            Text(intakeMl <= 0 ? l.hydration_no_data : l.hydration_too_small,
                textAlign: TextAlign.center, style: BldrSheetV2Text.body)
          else
            for (final a in amounts)
              BldrV2SheetOption(
                icon: TablerIcons.arrow_back_up,
                label: '− $a ml',
                onTap: () => Navigator.pop(ctx, a),
              ),
        ]),
      ),
    );
  }
}

class NutritionWaterSheetBody extends StatefulWidget {
  final int intakeMl;
  final int goalMl;
  const NutritionWaterSheetBody(
      {super.key, required this.intakeMl, required this.goalMl});

  @override
  State<NutritionWaterSheetBody> createState() =>
      _NutritionWaterSheetBodyState();
}

class _NutritionWaterSheetBodyState extends State<NutritionWaterSheetBody> {
  static const _presets = [200, 300, 500];
  int _amount = 300;
  bool _custom = false;
  final _card = GlobalKey<BldrQuantityCardState>();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final loc = l.localeName;
    final ratio = widget.goalMl <= 0 ? 0.0 : widget.intakeMl / widget.goalMl;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BldrQuantityCard(
            key: _card,
            value: _amount,
            unit: 'ml',
            step: 50,
            min: 50,
            max: 3000,
            decreaseLabel: l.nutri2_water_less,
            increaseLabel: l.nutri2_water_more,
            onChanged: (v) => setState(() {
              _amount = v;
              _custom = !_presets.contains(v);
            }),
          ),
          const SizedBox(height: 22),
          Text(l.nutri2_water_quick, style: BldrNutritionTextV2.sectionLabel),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, c) {
            final scale = MediaQuery.textScalerOf(context).scale(1);
            Widget preset(int p) => BldrNutritionChip(
                  label: '$p ml',
                  active: !_custom && _amount == p,
                  onTap: () => setState(() {
                    _amount = p;
                    _custom = false;
                  }),
                );
            final custom = BldrNutritionChip(
              label: l.nutri2_water_custom,
              active: _custom,
              onTap: () {
                setState(() => _custom = true);
                _card.currentState?.startEditing();
              },
            );
            // Estreito: presets numa linha, PERSONALIZADO embaixo.
            if (c.maxWidth < 380 * scale) {
              return Column(children: [
                Row(children: [
                  for (var i = 0; i < _presets.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(child: preset(_presets[i])),
                  ],
                ]),
                const SizedBox(height: 6),
                SizedBox(width: double.infinity, child: custom),
              ]);
            }
            return Row(children: [
              for (final p in _presets) ...[
                Expanded(flex: 88, child: preset(p)),
                const SizedBox(width: 6),
              ],
              Expanded(flex: 114, child: custom),
            ]);
          }),
          const SizedBox(height: 30),
          Text(l.nutri2_water_today, style: BldrNutritionTextV2.sectionLabel),
          const SizedBox(height: 6),
          Text(
            l.nutri2_water_today_value(
                NutritionHydrationCard.liters(widget.intakeMl, loc),
                NutritionHydrationCard.liters(widget.goalMl, loc)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BldrNutritionTextV2.sheetValue,
          ),
          const SizedBox(height: 10),
          BldrMetricBar(
              progress: ratio, gradient: BldrNutritionColorsV2.waterGradient),
          const SizedBox(height: 60),
          BldrNutritionCta(
            label: l.nutri2_water_cta,
            onTap: () => Navigator.pop(context, WaterSheetResult.add(_amount)),
          ),
          const SizedBox(height: 6),
          Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  Navigator.pop(context, const WaterSheetResult.remove()),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(TablerIcons.arrow_back_up,
                      size: 13, color: BldrNutritionColorsV2.muted),
                  const SizedBox(width: 6),
                  Text(l.hydration_remove_last,
                      style: BldrNutritionTextV2.link),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
