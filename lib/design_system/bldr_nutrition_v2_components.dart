import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Componentes do Nutrition Hub v2 (Figma z6plKSVOCah3uDI1Abaxbe, 102:312 e
/// 14:2). Só visual: textos e valores chegam prontos de quem usa.

double _ratio(double value, double goal) =>
    goal <= 0 ? 0 : (value / goal).clamp(0.0, 1.0);

// ── Pílula de data ("HOJE ›") ───────────────────────────────────────────────
class BldrDatePill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const BldrDatePill({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(
                minWidth: BldrNutritionV2.datePillW,
                minHeight: BldrNutritionV2.datePillH),
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: BldrNutritionColorsV2.fabBg,
              borderRadius:
                  BorderRadius.circular(BldrNutritionV2.datePillRadius),
              border: Border.all(color: BldrNutritionColorsV2.gold),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, maxLines: 1, style: BldrNutritionTextV2.datePill),
                const SizedBox(width: 8),
                Text('›', style: BldrNutritionTextV2.datePillChevron),
              ],
            ),
          ),
        ),
      );
}

// ── Anel de calorias ────────────────────────────────────────────────────────
class BldrKcalRing extends StatelessWidget {
  final double consumed;
  final double goal;
  final String valueText;
  final String goalText;
  const BldrKcalRing({
    super.key,
    required this.consumed,
    required this.goal,
    required this.valueText,
    required this.goalText,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: BldrNutritionV2.kcalRingW,
        height: BldrNutritionV2.kcalRingH,
        child: CustomPaint(
          painter: _KcalRingPainter(_ratio(consumed, goal)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(valueText,
                      maxLines: 1, style: BldrNutritionTextV2.kcalValue),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(goalText,
                      maxLines: 1, style: BldrNutritionTextV2.kcalGoal),
                ),
              ],
            ),
          ),
        ),
      );
}

class _KcalRingPainter extends CustomPainter {
  final double progress;
  _KcalRingPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const track = BldrNutritionV2.kcalTrackStroke;
    const stroke = BldrNutritionV2.kcalStroke;
    final rect = Offset.zero & size;
    canvas.drawOval(
        rect.deflate(track / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = track
          ..color = BldrNutritionColorsV2.kcalTrack);
    if (progress <= 0) return;
    canvas.drawArc(
        rect.deflate(stroke / 2),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = BldrNutritionColorsV2.goldBright);
  }

  @override
  bool shouldRepaint(_KcalRingPainter old) => old.progress != progress;
}

// ── Anéis de macro ──────────────────────────────────────────────────────────
class BldrMacroRingData {
  final String label;
  final String valueText;
  final String goalText;
  final double value;
  final double goal;
  const BldrMacroRingData({
    required this.label,
    required this.valueText,
    required this.goalText,
    required this.value,
    required this.goal,
  });
  bool get over => goal > 0 && value > goal;
}

/// Três anéis ligados por traços dourados (P · C · G).
class BldrMacroRings extends StatelessWidget {
  final List<BldrMacroRingData> macros;
  const BldrMacroRings({super.key, required this.macros});

  /// Centro a centro = anel (44) + traço (18) no mockup; cresce com o
  /// textScaler (até caber em 1/3 da largura) para os rótulos não espremerem.
  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    // 62 no mockup; 70 para "Carboidratos" caber no mínimo de 11 px.
    const base = 70.0;
    return LayoutBuilder(builder: (context, c) {
      final maxCol = c.maxWidth.isFinite ? c.maxWidth / macros.length : base;
      final column = (base * scale).clamp(base, maxCol < base ? base : maxCol);
      final gap = column - BldrNutritionV2.macroRing;
      return Stack(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final m in macros)
                SizedBox(width: column, child: _MacroRing(data: m)),
            ],
          ),
          for (var i = 1; i < macros.length; i++)
            Positioned(
              left: column * i - gap / 2,
              top: BldrNutritionV2.macroRing / 2,
              width: gap,
              child: const ColoredBox(
                  color: BldrNutritionColorsV2.gold,
                  child: SizedBox(height: 0.8)),
            ),
        ],
      );
    });
  }
}

class _MacroRing extends StatelessWidget {
  final BldrMacroRingData data;
  const _MacroRing({required this.data});

  @override
  Widget build(BuildContext context) => SizedBox(
        child: Column(
          children: [
            SizedBox.square(
              dimension: BldrNutritionV2.macroRing,
              child: CustomPaint(
                painter: _MacroRingPainter(
                    data.over ? 1 : _ratio(data.value, data.goal), data.over),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(data.valueText,
                          maxLines: 1, style: BldrNutritionTextV2.macroValue),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(data.label,
                  maxLines: 1, style: BldrNutritionTextV2.macroLabel),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(data.goalText,
                  maxLines: 1, style: BldrNutritionTextV2.macroGoal),
            ),
          ],
        ),
      );
}

class _MacroRingPainter extends CustomPainter {
  final double progress;
  final bool over;
  _MacroRingPainter(this.progress, this.over);

  @override
  void paint(Canvas canvas, Size size) {
    const track = BldrNutritionV2.macroTrackStroke;
    const stroke = BldrNutritionV2.macroStroke;
    final rect = Offset.zero & size;
    canvas.drawOval(
        rect.deflate(track / 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = track
          ..color = BldrNutritionColorsV2.macroTrack);
    if (progress <= 0) return;
    canvas.drawArc(
        rect.deflate(stroke / 2),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color =
              over ? BldrNutritionColorsV2.over : BldrNutritionColorsV2.gold);
  }

  @override
  bool shouldRepaint(_MacroRingPainter old) =>
      old.progress != progress || old.over != over;
}

// ── Barra de métrica (IQD / hidratação) ─────────────────────────────────────
class BldrMetricBar extends StatelessWidget {
  /// 0–1.
  final double progress;
  final Gradient gradient;
  final bool showDot;
  const BldrMetricBar({
    super.key,
    required this.progress,
    required this.gradient,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    return SizedBox(
      height: BldrNutritionV2.barTrackH,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth * p;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: BldrNutritionColorsV2.barTrack,
                  borderRadius:
                      BorderRadius.circular(BldrNutritionV2.barRadius),
                ),
              ),
            ),
            if (w > 0)
              Positioned(
                left: 0,
                top: 1,
                width: w,
                height: BldrNutritionV2.barFillH,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius:
                        BorderRadius.circular(BldrNutritionV2.barRadius),
                  ),
                ),
              ),
            if (showDot && w > 0)
              Positioned(
                left: (w - BldrNutritionV2.barDot).clamp(0, c.maxWidth),
                top: 1,
                child: Container(
                  width: BldrNutritionV2.barDot,
                  height: BldrNutritionV2.barDot,
                  decoration: BoxDecoration(
                    color: BldrNutritionColorsV2.gold,
                    shape: BoxShape.circle,
                    border: Border.all(width: 0.5),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

// ── Botão "+" pequeno (hidratação) ──────────────────────────────────────────
class BldrSmallAddButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String semanticLabel;
  const BldrSmallAddButton(
      {super.key, this.onTap, required this.semanticLabel});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: semanticLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8), // área de toque
            child: Container(
              width: BldrNutritionV2.waterAddW,
              height: BldrNutritionV2.waterAddH,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border:
                    Border.all(color: BldrNutritionColorsV2.gold, width: 0.65),
              ),
              child: const Icon(TablerIcons.plus,
                  size: 14, color: BldrNutritionColorsV2.gold),
            ),
          ),
        ),
      );
}

// ── Pílula de refeição (recolhida) ──────────────────────────────────────────
class BldrMealPill extends StatelessWidget {
  final IconData icon;
  final String name;
  final String kcalText;
  final String detail;
  final VoidCallback? onTap;
  const BldrMealPill({
    super.key,
    required this.icon,
    required this.name,
    required this.kcalText,
    required this.detail,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            constraints:
                const BoxConstraints(minHeight: BldrNutritionV2.mealPillH),
            padding: const EdgeInsets.fromLTRB(11, 3, 11, 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(BldrNutritionV2.mealRadius),
              border: Border.all(
                  color: BldrNutritionColorsV2.gold,
                  width: BldrNutritionV2.mealBorder),
            ),
            child: Row(
              children: [
                Icon(icon,
                    size: BldrNutritionV2.mealIcon,
                    color: BldrNutritionColorsV2.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: BldrNutritionTextV2.mealName),
                        ),
                        const SizedBox(width: 6),
                        Text(kcalText,
                            maxLines: 1, style: BldrNutritionTextV2.mealKcal),
                      ]),
                      Text(detail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BldrNutritionTextV2.mealDetail),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// Largura da pílula recolhida: 261/396 do conteúdo no frame de 440; em
/// telas estreitas ou com texto maior, cresce até a largura toda.
double bldrMealPillWidth(BuildContext context, double available) {
  final scale = MediaQuery.textScalerOf(context).scale(1);
  final w = available * BldrNutritionV2.mealPillWidthFactor;
  final min = 230 * scale;
  return min >= available ? available : w.clamp(min, available).toDouble();
}

// ── Refeição expandida ──────────────────────────────────────────────────────
class BldrMealExpandedCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String kcalText;
  final String detail;
  final List<(String, String)> macros;
  final List<Widget> foods;

  /// Estado vazio (102:297): sem cards de macro, só a mensagem.
  final String? emptyText;
  final String addLabel;
  final VoidCallback? onAdd;
  final VoidCallback? onCollapse;

  /// Ex.: menu "⋯" (só quando Copiar refeição existir).
  final Widget? menu;
  const BldrMealExpandedCard({
    super.key,
    required this.icon,
    required this.name,
    required this.kcalText,
    required this.detail,
    required this.macros,
    required this.foods,
    required this.addLabel,
    this.emptyText,
    this.onAdd,
    this.onCollapse,
    this.menu,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: BldrNutritionColorsV2.mealCardBg,
          borderRadius: BorderRadius.circular(BldrNutritionV2.mealRadius),
          border: Border.all(
              color: BldrNutritionColorsV2.gold,
              width: BldrNutritionV2.mealExpandedBorder),
        ),
        padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onCollapse,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(icon,
                        size: BldrNutritionV2.mealIcon,
                        color: BldrNutritionColorsV2.gold),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: BldrNutritionTextV2.mealName.copyWith(
                                    color: BldrNutritionColorsV2.text)),
                          ),
                          const SizedBox(width: 6),
                          Text(kcalText,
                              maxLines: 1, style: BldrNutritionTextV2.mealKcal),
                        ]),
                        const SizedBox(height: 2),
                        Text(emptyText ?? detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BldrNutritionTextV2.mealDetail),
                      ],
                    ),
                  ),
                  if (menu != null) ...[const SizedBox(width: 6), menu!],
                  const SizedBox(width: 8),
                  const Icon(TablerIcons.chevron_up,
                      size: 14, color: BldrNutritionColorsV2.goldBright),
                ],
              ),
            ),
            if (emptyText == null) ...[
              const SizedBox(height: 12),
              LayoutBuilder(builder: (context, c) {
                final scale = MediaQuery.textScalerOf(context).scale(1);
                // Card estreito demais para o rótulo em 11 px → empilha.
                final cardW = (c.maxWidth - 16) / 3;
                if (cardW < 92 * scale) {
                  return Column(children: [
                    for (var i = 0; i < macros.length; i++) ...[
                      if (i > 0) const SizedBox(height: 6),
                      _MacroCard(macros[i].$1, macros[i].$2, inline: true),
                    ],
                  ]);
                }
                return Row(children: [
                  for (var i = 0; i < macros.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: _MacroCard(macros[i].$1, macros[i].$2)),
                  ],
                ]);
              }),
              const SizedBox(height: 4),
              ...foods,
            ],
            const SizedBox(height: 6),
            const Divider(
                height: 1, thickness: 1, color: BldrNutritionColorsV2.divider),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAdd,
              child: Padding(
                padding: const EdgeInsets.only(top: 7, bottom: 2),
                child: Row(children: [
                  const Icon(TablerIcons.plus,
                      size: 12, color: BldrNutritionColorsV2.goldBright),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(addLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BldrNutritionTextV2.addFood),
                  ),
                ]),
              ),
            ),
          ],
        ),
      );
}

class _MacroCard extends StatelessWidget {
  final String label;
  final String value;

  /// Rótulo e valor na mesma linha (layout empilhado das telas estreitas).
  final bool inline;
  const _MacroCard(this.label, this.value, {this.inline = false});

  @override
  Widget build(BuildContext context) {
    final l = Text(label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: BldrNutritionTextV2.macroCardLabel);
    final v = Text(value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: BldrNutritionTextV2.macroCardValue);
    return Container(
      constraints:
          BoxConstraints(minHeight: inline ? 30 : BldrNutritionV2.macroCardH),
      padding: const EdgeInsets.fromLTRB(9, 5, 9, 5),
      decoration: BoxDecoration(
        color: BldrNutritionColorsV2.macroCardBg,
        borderRadius: BorderRadius.circular(BldrNutritionV2.macroCardRadius),
        border: Border.all(
            color: BldrNutritionColorsV2.macroCardBorder, width: 0.7),
      ),
      child: inline
          ? Row(children: [Expanded(child: l), const SizedBox(width: 8), v])
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [l, v],
            ),
    );
  }
}

/// Linha de alimento da refeição expandida. [actions] aparece no modo de
/// edição (editar / remover).
class BldrFoodRow extends StatelessWidget {
  final String name;
  final String quantity;
  final String macros;
  final Widget? actions;
  final bool showDivider;
  const BldrFoodRow({
    super.key,
    required this.name,
    required this.quantity,
    required this.macros,
    this.actions,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(builder: (context, c) {
      // Abaixo de ~300 px (×textScaler) os macros descem para a 2ª linha.
      // Com as ações do modo de edição, sempre em duas linhas.
      final stacked = actions != null || c.maxWidth < 300 * scale;
      final nameRow = Row(children: [
        Expanded(
          flex: 5,
          child: Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BldrNutritionTextV2.foodName),
        ),
        const SizedBox(width: 6),
        Text(quantity, maxLines: 1, style: BldrNutritionTextV2.foodQty),
        if (!stacked) ...[
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Text(macros,
                maxLines: 1,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: BldrNutritionTextV2.foodMacros),
          ),
        ],
        if (actions != null) ...[const SizedBox(width: 6), actions!],
      ]);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      nameRow,
                      const SizedBox(height: 2),
                      Text(macros,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BldrNutritionTextV2.foodMacros),
                    ],
                  )
                : nameRow,
          ),
          if (showDivider)
            const Divider(
                height: 1, thickness: 1, color: BldrNutritionColorsV2.divider),
        ],
      );
    });
  }
}

// ── FAB "+" ─────────────────────────────────────────────────────────────────
/// Some com refeição expandida ou sheet aberto ([visible] = false): fade +
/// escala em 200 ms, sem receber toques enquanto oculto; com movimento
/// reduzido, troca sem animação.
class BldrNutritionFab extends StatelessWidget {
  final bool visible;
  final VoidCallback? onTap;
  final String semanticLabel;
  const BldrNutritionFab({
    super.key,
    required this.visible,
    required this.semanticLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final d = reduce ? Duration.zero : BldrNutritionV2.fabFade;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: d,
        curve: Curves.easeOut,
        child: AnimatedScale(
          scale: visible ? 1 : 0.85,
          duration: d,
          curve: Curves.easeOut,
          child: Semantics(
            button: true,
            label: semanticLabel,
            excludeSemantics: !visible,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Container(
                width: BldrNutritionV2.fab,
                height: BldrNutritionV2.fab,
                decoration: BoxDecoration(
                  color: BldrNutritionColorsV2.fabBg,
                  borderRadius:
                      BorderRadius.circular(BldrNutritionV2.fabRadius),
                  border: Border.all(
                      color: BldrNutritionColorsV2.gold,
                      width: BldrNutritionV2.fabBorder),
                ),
                child: const Icon(TablerIcons.plus,
                    size: BldrNutritionV2.fabIcon,
                    color: BldrNutritionColorsV2.gold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sheets de Nutrição (102:311 / 102:308) ──────────────────────────────────

/// Card de quantidade − valor + (água, porção). Tocar no valor permite
/// digitar.
class BldrQuantityCard extends StatefulWidget {
  final int value;
  final String unit;
  final int step;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String decreaseLabel;
  final String increaseLabel;
  const BldrQuantityCard({
    super.key,
    required this.value,
    required this.unit,
    required this.onChanged,
    required this.decreaseLabel,
    required this.increaseLabel,
    this.step = 50,
    this.min = 1,
    this.max = 5000,
  });

  @override
  State<BldrQuantityCard> createState() => BldrQuantityCardState();
}

class BldrQuantityCardState extends State<BldrQuantityCard> {
  bool _editing = false;
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && _editing) _commit();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _set(int v) => widget.onChanged(v.clamp(widget.min, widget.max));

  /// Abre a digitação do valor (ex.: chip "PERSONALIZADO").
  void startEditing() {
    if (_editing) return;
    _ctrl.text = '${widget.value}';
    _ctrl.selection =
        TextSelection(baseOffset: 0, extentOffset: _ctrl.text.length);
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _commit() {
    final v = int.tryParse(_ctrl.text.trim());
    setState(() => _editing = false);
    if (v != null) _set(v);
  }

  Widget _button(String glyph, String label, int delta) => Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _set(widget.value + delta),
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: BldrNutritionColorsV2.stepButtonBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: BldrNutritionColorsV2.gold, width: 0.7),
            ),
            child: Text(glyph, style: BldrNutritionTextV2.stepGlyph),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 84),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: BldrNutritionColorsV2.quantityCardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: BldrNutritionColorsV2.quantityCardBorder, width: 0.8),
        ),
        child: Row(children: [
          _button('−', widget.decreaseLabel, -widget.step),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _editing ? null : startEditing,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                  height: 40,
                  child: _editing
                      ? TextField(
                          controller: _ctrl,
                          focusNode: _focus,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: BldrNutritionTextV2.amount,
                          cursorColor: BldrNutritionColorsV2.gold,
                          onSubmitted: (_) => _commit(),
                          decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('${widget.value}',
                              maxLines: 1, style: BldrNutritionTextV2.amount),
                        ),
                ),
                Text(widget.unit, style: BldrNutritionTextV2.amountUnit),
              ]),
            ),
          ),
          _button('+', widget.increaseLabel, widget.step),
        ]),
      );
}

/// Chip de seleção dos sheets (presets de água, tipo de porção, refeição).
class BldrNutritionChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const BldrNutritionChip(
      {super.key, required this.label, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: active,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 38),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: active
                  ? BldrNutritionColorsV2.chipActiveBg
                  : BldrNutritionColorsV2.chipBg,
              borderRadius: BorderRadius.circular(19),
              border: active
                  ? Border.all(color: BldrNutritionColorsV2.gold, width: 1.2)
                  : null,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  maxLines: 1,
                  style: active
                      ? BldrNutritionTextV2.chipActive
                      : BldrNutritionTextV2.chip),
            ),
          ),
        ),
      );
}

/// CTA dos sheets de Nutrição: borda dourada, raio 20, altura 52.
class BldrNutritionCta extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  /// Altura 44 e raio 16 (CTAs dos sheets de cópia, 102:313–315).
  final bool compact;
  const BldrNutritionCta(
      {super.key,
      required this.label,
      this.onTap,
      this.color,
      this.compact = false});

  @override
  Widget build(BuildContext context) {
    final c = color ?? BldrNutritionColorsV2.gold;
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.4 : 1,
          child: Container(
            constraints: BoxConstraints(minHeight: compact ? 44 : 52),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(compact ? 16 : 20),
              border: Border.all(color: c),
            ),
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BldrNutritionTextV2.cta.copyWith(color: c)),
          ),
        ),
      ),
    );
  }
}
