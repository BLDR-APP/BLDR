// BLDR — Componentes do rebranding v2 (Figma Bn5NBPkg7Yr1shm5F7vmb0)
//
// Elementos repetidos dos mockups v2: card sólido, chip de stat, barra,
// anel de métrica, CTA com borda, pilha de wearable e navbar.
// Valores em `BldrColorsV2` / `BldrTextV2` / `BldrSpacingV2` / `BldrRadiusV2`.
// Os componentes da fase 1 (bldr_components.dart) não foram alterados.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

// ─────────────────────────────────────────────────────────────
// GLOW ELÍPTICO
// ─────────────────────────────────────────────────────────────

/// Gradiente radial desenhado numa ELIPSE (o `RadialGradient` do Flutter é
/// sempre circular). Reproduz os ellipses "BG GLOW" do Figma.
class BldrEllipseGlowPainter extends CustomPainter {
  /// Centro e raios em coordenadas do canvas.
  final Offset center;
  final Size radii;
  final List<Color> colors;
  final List<double> stops;

  const BldrEllipseGlowPainter({
    required this.center,
    required this.radii,
    required this.colors,
    required this.stops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(radii.width, radii.height);
    final rect = Rect.fromCircle(center: Offset.zero, radius: 1);
    final paint = Paint()
      ..shader = RadialGradient(colors: colors, stops: stops).createShader(rect);
    canvas.drawCircle(Offset.zero, 1, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(BldrEllipseGlowPainter old) =>
      old.center != center || old.radii != radii;
}

/// Fundo v2 da tela: #050505 + dois glows elípticos (SVG "Background" do
/// frame). As posições são do frame de 440 px e escalam com a largura.
class BldrBackgroundV2Painter extends CustomPainter {
  const BldrBackgroundV2Painter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / BldrSpacingV2.frameWidth;
    canvas.drawRect(Offset.zero & size, Paint()..color = BldrColorsV2.bg);
    BldrEllipseGlowPainter(
      center: Offset(220 * s, 40 * s),
      radii: Size(310 * s, 210 * s),
      colors: BldrColorsV2.glowColors,
      stops: BldrColorsV2.glowStops,
    ).paint(canvas, size);
    BldrEllipseGlowPainter(
      center: Offset(445 * s, 335 * s),
      radii: Size(260 * s, 280 * s),
      colors: BldrColorsV2.glowSecondaryColors,
      stops: BldrColorsV2.glowSecondaryStops,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(BldrBackgroundV2Painter old) => false;
}

// ─────────────────────────────────────────────────────────────
// CARD SÓLIDO
// ─────────────────────────────────────────────────────────────

/// Card v2: fundo sólido (ou gradiente), borda opcional, sem blur.
/// Substitui o glass da fase 1 nas telas com mockup v2.
class BldrSolidCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  const BldrSolidCard({
    super.key,
    required this.child,
    this.color,
    this.gradient,
    this.borderColor,
    this.radius = BldrRadiusV2.tile,
    this.padding = EdgeInsets.zero,
    this.width,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      height: height,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TILE DO GRID
// ─────────────────────────────────────────────────────────────

/// Tile do grid 2×2 da Home v2: card sólido #181818, raio 17, altura 96.
/// Posições do mockup: label 11, valor 30, legenda 60, barra 82 (4 px).
class BldrTileV2 extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;
  final String? caption;
  final double? progress;
  final VoidCallback? onTap;

  const BldrTileV2({
    super.key,
    required this.label,
    required this.value,
    this.valueStyle,
    this.caption,
    this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BldrSolidCard(
      onTap: onTap,
      color: BldrColorsV2.tileBg,
      radius: BldrRadiusV2.tile,
      height: BldrSpacingV2.tileHeight,
      padding: const EdgeInsets.fromLTRB(BldrSpacingV2.tilePad, 11, 13, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BldrTextV2.tileLabel),
          const SizedBox(height: 6.9),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: valueStyle ?? BldrTextV2.tileValue),
          const SizedBox(height: 2.2),
          Text(caption ?? ' ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BldrTextV2.tileLabel),
          if (progress != null) ...[
            const Spacer(),
            BldrBarV2(value: progress!),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CHIP DE STAT
// ─────────────────────────────────────────────────────────────

/// Chip de consistência 81×78: ícone (18) → valor → label.
/// [iconAsset] é um SVG de `assets/images/v2/icons/` (já na cor do mockup).
class BldrStatChip extends StatelessWidget {
  final String iconAsset;
  final String value;
  final String label;
  final Color? valueColor;
  final VoidCallback? onTap;

  const BldrStatChip({
    super.key,
    required this.iconAsset,
    required this.value,
    required this.label,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BldrSolidCard(
      width: BldrSpacingV2.chipWidth,
      height: BldrSpacingV2.chipHeight,
      color: BldrColorsV2.chipBg,
      borderColor: BldrColorsV2.gold,
      radius: BldrRadiusV2.chip,
      onTap: onTap,
      // Posições verticais do mockup: ícone 8, valor 27, label 49.
      child: Stack(
        children: [
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: SvgPicture.asset(iconAsset, width: 18, height: 18),
            ),
          ),
          Positioned(
            top: 26,
            left: 4,
            right: 4,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: BldrTextV2.statValue.copyWith(color: valueColor),
              ),
            ),
          ),
          Positioned(
            top: 49,
            left: 2,
            right: 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, maxLines: 1, style: BldrTextV2.statLabel),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BARRA
// ─────────────────────────────────────────────────────────────

/// Barra de progresso v2 (trilho + preenchimento), com cor sólida ou
/// gradiente e borda opcional (faixa de nível).
class BldrBarV2 extends StatelessWidget {
  final double value;
  final double height;
  final double radius;
  final Color trackColor;
  final Color fillColor;
  final Gradient? fillGradient;
  final Color? borderColor;

  const BldrBarV2({
    super.key,
    required this.value,
    this.height = 4,
    this.radius = BldrRadiusV2.tileBar,
    this.trackColor = BldrColorsV2.tileTrack,
    this.fillColor = BldrColorsV2.goldBright,
    this.fillGradient,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    final border = borderColor == null
        ? null
        : Border.all(color: borderColor!, width: 0.5);
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, c) => Stack(
          children: [
            Container(
              width: c.maxWidth,
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(radius),
                border: border,
              ),
            ),
            if (v > 0)
              Container(
                width: c.maxWidth * v,
                decoration: BoxDecoration(
                  color: fillGradient == null ? fillColor : null,
                  gradient: fillGradient,
                  borderRadius: BorderRadius.circular(radius),
                  border: border,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ANEL DE MÉTRICA
// ─────────────────────────────────────────────────────────────

/// Anel 73×73 com traço de 8 e ponta reta (cunha do Figma), trilho
/// `ringTrack`, miolo `ringInner` e o valor centralizado na cor do anel.
/// [value] null desenha só o trilho (skeleton).
class BldrMetricRing extends StatelessWidget {
  final double? value;
  final Color color;
  final String display;
  final double size;

  const BldrMetricRing({
    super.key,
    required this.value,
    required this.color,
    required this.display,
    this.size = 73,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MetricRingPainter(value: value, color: color),
        child: Center(
          child: Text(
            display,
            maxLines: 1,
            style: BldrTextV2.ringValue.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}

class _MetricRingPainter extends CustomPainter {
  final double? value;
  final Color color;

  const _MetricRingPainter({required this.value, required this.color});

  static const double _stroke = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    canvas.drawCircle(center, outer, Paint()..color = BldrColorsV2.ringTrack);

    final v = value?.clamp(0.0, 1.0) ?? 0.0;
    if (v > 0) {
      final rect = Rect.fromCircle(center: center, radius: outer);
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * v,
        true,
        Paint()..color = color,
      );
    }
    canvas.drawCircle(
        center, outer - _stroke, Paint()..color = BldrColorsV2.ringInner);
  }

  @override
  bool shouldRepaint(_MetricRingPainter old) =>
      old.value != value || old.color != color;
}

// ─────────────────────────────────────────────────────────────
// CTA COM BORDA
// ─────────────────────────────────────────────────────────────

/// Variante visual do [BldrOutlineCta].
enum BldrCtaVariant {
  /// Borda e texto dourados, sem fundo (padrão).
  gold,

  /// Fundo e borda cinza, texto claro (ex.: "VER MEU PLANO", dia de
  /// descanso — Figma 57:386).
  neutral,
}

/// CTA v2: borda de 1 px, raio 15, altura 42, texto em caixa alta (já vem
/// assim do .arb). Por padrão ▶ no início; com [trailingChevron] a seta "›"
/// vai no fim e o ícone inicial some.
class BldrOutlineCta extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final BldrCtaVariant variant;
  final bool trailingChevron;

  const BldrOutlineCta({
    super.key,
    required this.label,
    this.onPressed,
    this.icon = Icons.play_arrow_rounded,
    this.variant = BldrCtaVariant.gold,
    this.trailingChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final neutral = variant == BldrCtaVariant.neutral;
    final fg = neutral ? BldrTrainColorsV2.ctaNeutralText : BldrColorsV2.gold;
    final style = BldrTextV2.cta.copyWith(color: fg);
    final leading = trailingChevron ? null : icon;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: neutral ? BldrTrainColorsV2.ctaNeutralBg : null,
              borderRadius: BorderRadius.circular(BldrRadiusV2.cta),
              border: Border.all(
                  color: neutral
                      ? BldrTrainColorsV2.ctaNeutralBorder
                      : BldrColorsV2.gold),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  Icon(leading, size: 18, color: fg),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    trailingChevron ? '$label   ›' : label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CARD "TREINO DE HOJE"
// ─────────────────────────────────────────────────────────────

/// Casca dos estados do "Treino de hoje" (planejado, descanso, sem plano,
/// em andamento, concluído — Figma 57:387/386/385/380/379). Card 386 × 189
/// só com borda e glow no canto superior direito. Linhas na geometria do
/// mockup: rótulo 16, título 40, detalhe 73, meta 97, CTA 130 (42).
/// [stats] substitui meta + CTA (concluído); [corner] fica no canto
/// superior direito (check do concluído).
class BldrTrainCardV2 extends StatelessWidget {
  final String label;
  final String title;
  final String detail;
  final String meta;
  final Widget? cta;
  final Widget? stats;
  final Widget? corner;

  const BldrTrainCardV2({
    super.key,
    required this.label,
    required this.title,
    required this.detail,
    this.meta = '',
    this.cta,
    this.stats,
    this.corner,
  });

  @override
  Widget build(BuildContext context) {
    return BldrSolidCard(
      height: 189,
      borderColor: BldrColorsV2.trainBorder,
      radius: BldrRadiusV2.train,
      child: Stack(
        children: [
          const Positioned(
            right: 0,
            top: 8,
            child: CustomPaint(
              size: Size(162.333, 109.968),
              painter: BldrEllipseGlowPainter(
                center: Offset(81.1667, 54.9839),
                radii: Size(81.1667, 54.9839),
                colors: BldrColorsV2.glowColors,
                stops: BldrColorsV2.glowStops,
              ),
            ),
          ),
          if (corner != null) Positioned(top: 10, right: 14, child: corner!),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                BldrSpacingV2.trainPad - 1, 15, BldrSpacingV2.trainPad - 1, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: BldrTextV2.trainLabel),
                const SizedBox(height: 10.7),
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BldrTextV2.trainTitle),
                const SizedBox(height: 2.75),
                Text(detail.isEmpty ? ' ' : detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BldrTextV2.trainMuscles),
                if (stats != null) ...[
                  const SizedBox(height: 19.7),
                  Center(child: stats),
                ] else ...[
                  const SizedBox(height: 10.7),
                  Text(meta.isEmpty ? ' ' : meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrTextV2.trainMeta),
                  const Spacer(),
                  if (cta != null) cta!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Métrica do concluído v2: ícone 17 dourado → valor → rótulo (57:379).
class BldrDoneStatV2 extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const BldrDoneStatV2({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(icon, width: 17, height: 17),
        const SizedBox(height: 0.5),
        Text(value,
            style: BldrTextV2.doneStat
                .copyWith(color: BldrTrainColorsV2.doneValue)),
        const SizedBox(height: 3.7),
        Text(label,
            style: BldrTextV2.doneStat
                .copyWith(color: BldrTrainColorsV2.doneLabel)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PILHA DE WEARABLE
// ─────────────────────────────────────────────────────────────

/// Ordem cíclica da pilha: índices dos cards reais por camada, da frente
/// para trás, a partir do card da frente [front]. Pura — testada.
List<int> wearableStackOrder(int count, int front) =>
    [for (var i = 0; i < count; i++) (front + i) % count];

/// Quantas camadas a pilha mostra: no mínimo 3 (mockup), 4 com 4+ cards.
int wearableStackLayerCount(int cardCount) => cardCount >= 4 ? 4 : 3;

/// Pilha de wearables rolável (estilo Carteira). Genérica: recebe a lista
/// de [cards] (o da frente primeiro). O card "Conectar" deve vir por
/// último — quem compõe a lista decide.
///
/// - Sempre 3 camadas visíveis; com 4+ cards, 4 (as demais ficam ocultas).
///   Camadas sem card real são decorativas. Camadas de trás mostram só a
///   superfície neutra da pilha; o conteúdo aparece ao chegar à frente.
/// - Arrastar na horizontal leva o card da frente para trás e sobe os
///   demais. Funciona com qualquer número de cards (com 1, ele volta).
/// - Pontos de posição só com 2+ cards reais.
/// - Altura fixa de 188 — a 4ª camada não move o layout.
class WearableStack extends StatefulWidget {
  final List<Widget> cards;
  final ValueChanged<int>? onFrontChanged;

  const WearableStack({
    super.key,
    required this.cards,
    this.onFrontChanged,
  }) : assert(cards.length > 0);

  @override
  State<WearableStack> createState() => _WearableStackState();
}

class _WearableStackState extends State<WearableStack>
    with TickerProviderStateMixin {
  int _front = 0;
  double _dx = 0;
  double _width = 1;

  late final AnimationController _swipe =
      AnimationController.unbounded(vsync: this)..addListener(_onSwipeTick);

  // 0 = geometria de 3 camadas, 1 = de 4 camadas.
  late final AnimationController _layout = AnimationController(
    vsync: this,
    duration: BldrStackV2.animation,
    value: wearableStackLayerCount(widget.cards.length) == 4 ? 1 : 0,
  );

  static const _backColors = [
    BldrColorsV2.stackMid,
    BldrColorsV2.stackBack,
    BldrStackV2.layer4,
  ];
  static const _backBorders = [
    BldrColorsV2.stackMidBorder,
    BldrColorsV2.stackBackBorder,
    BldrStackV2.layer4Border,
  ];

  int get _count => widget.cards.length;

  @override
  void didUpdateWidget(WearableStack old) {
    super.didUpdateWidget(old);
    if (_front >= _count) _front = 0;
    final target = wearableStackLayerCount(_count) == 4 ? 1.0 : 0.0;
    if (_layout.value != target) {
      _layout.animateTo(target, curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _swipe.dispose();
    _layout.dispose();
    super.dispose();
  }

  void _onSwipeTick() => setState(() => _dx = _swipe.value);

  double get _progress => (_dx.abs() / _width).clamp(0.0, 1.0);

  void _onDragUpdate(DragUpdateDetails d) {
    _swipe.stop();
    setState(() => _dx += d.delta.dx);
  }

  void _onDragEnd(DragEndDetails d) {
    final v = d.velocity.pixelsPerSecond.dx;
    final passed = _progress > 0.3 || v.abs() > 700;
    if (passed && _dx != 0) {
      final target = _dx.sign * _width;
      _swipe.value = _dx;
      _swipe
          .animateTo(target,
              duration: BldrStackV2.animation, curve: Curves.easeOutCubic)
          .whenComplete(_commit);
    } else {
      _swipe.value = _dx;
      _swipe.animateWith(SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 300, damping: 26),
        _dx,
        0,
        v,
      ));
    }
  }

  void _commit() {
    if (!mounted) return;
    setState(() {
      _front = (_front + 1) % _count;
      _dx = 0;
    });
    _swipe.value = 0;
    widget.onFrontChanged?.call(_front);
  }

  // Geometria interpolada de uma posição contínua [slot] (0 = frente).
  ({double top, double inset, double bottom}) _geom(double slot) {
    final v = _layout.value;
    double at(List<double> t3, List<double> t4, int i) {
      final a = i < t3.length ? t3[i] : t3.last;
      final b = i < t4.length ? t4[i] : t4.last;
      return a + (b - a) * v;
    }

    double pick(List<double> t3, List<double> t4) {
      final lo = slot.floor().clamp(0, 3);
      final hi = slot.ceil().clamp(0, 3);
      final f = slot - slot.floor();
      return at(t3, t4, lo) + (at(t3, t4, hi) - at(t3, t4, lo)) * f;
    }

    return (
      top: pick(BldrStackV2.tops3, BldrStackV2.tops4),
      inset: pick(BldrStackV2.insets3, BldrStackV2.insets4),
      bottom: pick(BldrStackV2.bottoms3, BldrStackV2.bottoms4),
    );
  }

  Color _lerpBack(List<Color> colors, double backSlot) {
    final lo = backSlot.floor().clamp(0, colors.length - 1);
    final hi = backSlot.ceil().clamp(0, colors.length - 1);
    return Color.lerp(colors[lo], colors[hi], backSlot - backSlot.floor())!;
  }

  Widget _surface(double slot, double opacity) {
    final g = _geom(slot);
    final back = (slot - 1).clamp(0.0, 2.0);
    return Positioned(
      top: g.top,
      left: g.inset,
      right: g.inset,
      bottom: g.bottom,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _lerpBack(_backColors, back),
            borderRadius: BorderRadius.circular(BldrRadiusV2.wearableCard),
            border: Border.all(color: _lerpBack(_backBorders, back)),
          ),
        ),
      ),
    );
  }

  Widget _content(Widget card, double slot, double opacity,
      {double dx = 0, double turns = 0}) {
    final g = _geom(slot);
    return Positioned(
      top: g.top,
      left: g.inset,
      right: g.inset,
      child: Transform.translate(
        offset: Offset(dx, 0),
        child: Transform.rotate(
          angle: turns,
          child: Opacity(opacity: opacity.clamp(0.0, 1.0), child: card),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final order = wearableStackOrder(_count, _front);
    final layers = 3 + _layout.value; // 3 → 4 contínuo
    final t = _progress;
    final next = widget.cards[order.length > 1 ? order[1] : order[0]];

    // Camadas de trás (superfície neutra), desenhadas do fundo para a frente.
    // Durante o arraste cada uma sobe uma posição (slot - t); uma camada
    // nova entra no fundo com fade.
    final backs = <Widget>[];
    final lastSlot = layers.ceil() - 1; // 2 ou 3
    for (var s = lastSlot + 1; s >= 1; s--) {
      final slot = s - t;
      double op;
      if (s == lastSlot + 1) {
        op = t; // camada que entra no fundo
      } else if (s == 3) {
        op = _layout.value; // 4ª camada aparece com a animação de layout
      } else {
        op = 1;
      }
      if (slot < 1) {
        // A camada 1 vira a frente: a superfície some enquanto o conteúdo
        // do próximo card aparece por cima.
        backs.add(_surface(slot, 1 - t));
      } else {
        backs.add(_surface(slot, op));
      }
    }

    final stack = LayoutBuilder(builder: (context, c) {
      _width = c.maxWidth;
      return SizedBox(
        height: BldrStackV2.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ...backs,
            if (t > 0) _content(next, 1 - t, t),
            _content(
              widget.cards[order[0]],
              0,
              1 - t,
              dx: _dx,
              turns: (_dx / _width) * (4 * math.pi / 180),
            ),
          ],
        ),
      );
    });

    return Semantics(
      label: _count > 1
          ? l10n.wearable_stack_position(_front + 1, _count)
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: stack,
          ),
          if (_count > 1) ...[
            const SizedBox(height: 8),
            _Dots(count: _count, active: _front),
          ],
        ],
      ),
    );
  }
}

/// Indicador de posição: pílula 14×5 dourada no ativo, pontos 5×5 nos
/// demais, gap 4 (proposta aprovada — o Figma não define).
class _Dots extends StatelessWidget {
  final int count;
  final int active;

  const _Dots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: BldrStackV2.animation,
            curve: Curves.easeOutCubic,
            margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
            width: i == active ? 14 : 5,
            height: 5,
            decoration: BoxDecoration(
              color: i == active ? BldrStackV2.dotActive : BldrStackV2.dotIdle,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NAVBAR v2
// ─────────────────────────────────────────────────────────────

/// Navbar v2: pílula dourada translúcida com 5 ícones + botão do HAVOK
/// separado à direita. O mockup não define estado ativo; o item ativo fica
/// com o ícone em `gold` (decisão aprovada).
///
/// NavBar: 0=Home, 1=Treinos, 2=Comunidade, 3=Nutrição, 4=Perfil.
class BldrNavBarV2 extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onChanged;
  final VoidCallback? onHavokTap;

  const BldrNavBarV2({
    super.key,
    required this.selectedIndex,
    this.onChanged,
    this.onHavokTap,
  });

  static const _icons = [
    'assets/images/v2/icons/nav_home.svg',
    'assets/images/v2/icons/nav_barbell.svg',
    'assets/images/v2/icons/nav_users.svg',
    'assets/images/v2/icons/nav_tools_kitchen_2.svg',
    'assets/images/v2/icons/nav_user.svg',
  ];

  // Geometria do mockup: pílula 151 × 42, botão HAVOK 39.76 × 42, gap 9.
  static const double _pillWidth = 151;
  static const double _havokWidth = 39.76;
  static const double _gap = 9;
  static const double _iconSize = 24;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.nav_tab_dashboard,
      l10n.nav_tab_workouts,
      l10n.nav_tab_community,
      l10n.nav_tab_nutrition,
      l10n.nav_tab_profile,
    ];
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final gap = math.max(BldrSpacingV2.navBottom, bottomInset);

    // Como bottomNavigationBar, a altura precisa ser finita (ver BldrNavBar).
    return SizedBox(
      height: gap + BldrSpacingV2.navHeight,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.only(bottom: gap),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: _pillWidth,
                height: BldrSpacingV2.navHeight,
                padding: const EdgeInsets.only(left: 6, right: 8),
                decoration: BoxDecoration(
                  color: BldrColorsV2.goldFill,
                  borderRadius: BorderRadius.circular(BldrRadiusV2.navPill),
                  border: Border.all(color: BldrColorsV2.gold),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                      _icons.length, (i) => _item(i, labels[i])),
                ),
              ),
              const SizedBox(width: _gap),
              Semantics(
                label: l10n.havok_entry_semantics,
                button: true,
                child: GestureDetector(
                  onTap: onHavokTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: _havokWidth,
                    height: BldrSpacingV2.navHeight,
                    decoration: BoxDecoration(
                      color: BldrColorsV2.goldFill,
                      borderRadius:
                          BorderRadius.circular(BldrRadiusV2.navHavok),
                      border: Border.all(color: BldrColorsV2.gold),
                    ),
                    alignment: Alignment.center,
                    // Pantera 21.5 × 24.4 no mockup — mesmo vetor do
                    // HavokEntryIcon.
                    child: SvgPicture.asset(
                      'assets/images/havok_vector.svg',
                      width: 21.5,
                      height: 24.4,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int index, String label) {
    final active = index == selectedIndex;
    return Semantics(
      label: label,
      selected: active,
      button: true,
      child: GestureDetector(
        onTap: () => onChanged?.call(index),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: _iconSize,
          height: BldrSpacingV2.navHeight,
          child: Center(
            child: SvgPicture.asset(
              _icons[index],
              width: _iconSize,
              height: _iconSize,
              colorFilter: active
                  ? const ColorFilter.mode(BldrColorsV2.gold, BlendMode.srcIn)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
