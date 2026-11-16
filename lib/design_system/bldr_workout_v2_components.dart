// BLDR — Componentes de Treinos v2 (Figma guqp4TpJiiCKjhSgzqxSjg)
//
// Criar treino (179:981), Montar treino (179:1015) e o sheet de exercícios
// (179:1117). Tamanhos exatamente os do mockup; cores e textos em
// `BldrWorkoutColorsV2` / `BldrWorkoutTextV2`.

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Cabeçalho das telas de Treinos: "‹", rótulo dourado, título e (opcional)
/// subtítulo; [trailing] fica à direita (contador / botão compacto).
class BldrWorkoutHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final Widget? trailing;
  final TextStyle? eyebrowStyle;

  const BldrWorkoutHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.onBack,
    this.subtitle,
    this.trailing,
    this.eyebrowStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: MaterialLocalizations.of(context).backButtonTooltip,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack,
            child: SizedBox(
              width: 36,
              height: 34,
              child: Text('‹', style: BldrWorkoutTextV2.back),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: eyebrowStyle ?? BldrWorkoutTextV2.eyebrow),
                const SizedBox(height: 4),
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BldrWorkoutTextV2.title),
                if (subtitle != null) ...[
                  Text(subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrWorkoutTextV2.subtitle),
                ],
              ],
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Resumo de métricas (HUD): até 4 colunas valor dourado + rótulo.
class BldrHudStats extends StatelessWidget {
  final List<({String value, String label})> items;

  const BldrHudStats({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: BldrWorkoutColorsV2.hudBg,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: BldrWorkoutColorsV2.hudBorder),
      ),
      child: Row(
        children: [
          for (final it in items)
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 24,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(it.value,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: BldrWorkoutTextV2.hudValue),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(it.label,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: BldrWorkoutTextV2.hudLabel),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// CTA com borda dourada: "＋  RÓTULO  ›".
class BldrGoldRowCta extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double height;
  final double radius;
  final TextStyle? labelStyle;
  final Widget? trailing;

  const BldrGoldRowCta({
    super.key,
    required this.label,
    this.onTap,
    this.height = 62,
    this.radius = 22,
    this.labelStyle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.5 : 1,
          child: Container(
            height: height,
            padding: const EdgeInsets.only(left: 16, right: 22),
            decoration: BoxDecoration(
              color: BldrWorkoutColorsV2.ctaBg,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: BldrWorkoutColorsV2.ctaBorder),
            ),
            child: Row(
              children: [
                // "＋" do mockup como ícone (o glifo não existe na Inter).
                const SizedBox(
                    width: 28,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(TablerIcons.plus,
                          size: 18, color: BldrWorkoutColorsV2.gold),
                    )),
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: labelStyle ?? BldrWorkoutTextV2.cta),
                ),
                trailing ?? Text('›', style: BldrWorkoutTextV2.ctaArrow),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão compacto com borda dourada (ex.: "CRIAR" no cabeçalho).
class BldrCompactGoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const BldrCompactGoldButton({
    super.key,
    required this.label,
    this.onTap,
    this.width = 84,
    this.height = 30,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.5 : 1,
          child: Container(
            width: width,
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: BldrWorkoutColorsV2.ctaBg,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: BldrWorkoutColorsV2.ctaBorder),
            ),
            child: Text(label, style: BldrWorkoutTextV2.compactCta),
          ),
        ),
      ),
    );
  }
}

/// Chip de tipo de treino (46 de altura, raio 18). [soonLabel] desabilita o
/// chip e mostra o texto numa segunda linha (decisão aprovada).
class BldrTypeChip extends StatelessWidget {
  final String label;
  final double width;
  final bool selected;
  final String? soonLabel;
  final VoidCallback? onTap;

  const BldrTypeChip({
    super.key,
    required this.label,
    required this.width,
    this.selected = false,
    this.soonLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = soonLabel != null;
    return Semantics(
      button: true,
      selected: selected,
      enabled: !disabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: disabled ? null : onTap,
        child: Container(
          width: width,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? BldrWorkoutColorsV2.typeChipSelBg
                : BldrWorkoutColorsV2.typeChipBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: selected
                    ? BldrWorkoutColorsV2.typeChipSelBorder
                    : BldrWorkoutColorsV2.typeBoxBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: BldrWorkoutTextV2.typeChip.copyWith(
                        color: selected ? BldrWorkoutColorsV2.gold : null)),
              ),
              if (disabled)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(soonLabel!,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: BldrWorkoutTextV2.soon),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Caixa de valor editável (Séries / Reps / Desc.): valor + rótulo.
class BldrValueBox extends StatelessWidget {
  final String value;
  final String label;
  final double width;
  final VoidCallback? onTap;

  const BldrValueBox({
    super.key,
    required this.value,
    required this.label,
    required this.width,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$label $value',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: width,
          height: 40,
          decoration: BoxDecoration(
            color: BldrWorkoutColorsV2.valueBg,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: BldrWorkoutColorsV2.valueBorder),
          ),
          child: Column(
            children: [
              const SizedBox(height: 3),
              SizedBox(
                height: 17,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(value,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: BldrWorkoutTextV2.valueBox),
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: BldrWorkoutTextV2.valueLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Moldura da mídia do exercício (GIF atual): tamanho, raio e borda do
/// mockup. O conteúdo ([child]) é o GIF/fallback que o app já usa.
class BldrExerciseMediaFrame extends StatelessWidget {
  final double size;
  final Widget child;
  final Color background;
  final Color border;

  const BldrExerciseMediaFrame({
    super.key,
    required this.size,
    required this.child,
    this.background = BldrWorkoutColorsV2.thumbBg,
    this.border = BldrWorkoutColorsV2.thumbBorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: child,
    );
  }
}

/// Chip de filtro (32 de altura, raio 14).
class BldrFilterChipV2 extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const BldrFilterChipV2({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? BldrWorkoutColorsV2.filterSelBg
                : BldrWorkoutColorsV2.filterBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: selected
                    ? BldrWorkoutColorsV2.filterSelBorder
                    : BldrWorkoutColorsV2.filterBorder),
          ),
          child: Text(label,
              style: BldrWorkoutTextV2.filter.copyWith(
                  color: selected ? BldrWorkoutColorsV2.gold : null)),
        ),
      ),
    );
  }
}

/// Campo de busca (46 de altura, raio 16).
class BldrSearchFieldV2 extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const BldrSearchFieldV2({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: BldrWorkoutColorsV2.searchBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BldrWorkoutColorsV2.searchBorder),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 46,
            child: Icon(TablerIcons.search,
                size: 16, color: BldrWorkoutColorsV2.muted),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: BldrWorkoutTextV2.search
                  .copyWith(color: BldrWorkoutColorsV2.text),
              cursorColor: BldrWorkoutColorsV2.gold,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: BldrWorkoutTextV2.search,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Item da biblioteca no sheet (96 de altura): mídia 76, nome, músculos,
/// equipamento e o botão de seleção (+ / ✓).
class BldrLibraryExerciseTile extends StatelessWidget {
  final Widget media;
  final String name;
  final String muscles;
  final String? equipment;
  final bool selected;
  final bool alreadyAdded;
  final VoidCallback? onToggle;

  const BldrLibraryExerciseTile({
    super.key,
    required this.media,
    required this.name,
    required this.muscles,
    this.equipment,
    this.selected = false,
    this.alreadyAdded = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final marked = selected || alreadyAdded;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: alreadyAdded ? null : onToggle,
      child: Opacity(
        opacity: alreadyAdded ? 0.5 : 1,
        child: Container(
          height: 96,
          padding: const EdgeInsets.fromLTRB(9, 9, 18, 9),
          decoration: BoxDecoration(
            color: BldrWorkoutColorsV2.itemBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: marked
                    ? BldrWorkoutColorsV2.itemSelBorder
                    : BldrWorkoutColorsV2.itemBorder),
          ),
          child: Row(
            children: [
              BldrExerciseMediaFrame(
                size: 76,
                background: BldrWorkoutColorsV2.itemThumbBg,
                border: BldrWorkoutColorsV2.itemThumbBorder,
                child: media,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BldrWorkoutTextV2.itemName),
                    const SizedBox(height: 4),
                    Text(muscles,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BldrWorkoutTextV2.exMuscles),
                    if (equipment != null && equipment!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        constraints: const BoxConstraints(minWidth: 90),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: BldrWorkoutColorsV2.equipBg,
                          borderRadius: BorderRadius.circular(9),
                          border:
                              Border.all(color: BldrWorkoutColorsV2.equipBorder),
                        ),
                        child: Text(equipment!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BldrWorkoutTextV2.equip),
                      ),
                    ],
                  ],
                ),
              ),
              Semantics(
                button: true,
                selected: marked,
                child: Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: marked
                        ? BldrWorkoutColorsV2.pickSelBg
                        : BldrWorkoutColorsV2.pickBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: marked
                            ? BldrWorkoutColorsV2.pickSelBorder
                            : BldrWorkoutColorsV2.pickBorder),
                  ),
                  child: Icon(marked ? TablerIcons.check : TablerIcons.plus,
                      size: 16,
                      color: marked
                          ? BldrWorkoutColorsV2.gold
                          : BldrWorkoutColorsV2.text),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// HUB DE TREINOS (249:18901 / 179:2)
// ═════════════════════════════════════════════════════════════

/// Abas "Treino / Esportes": ativa em dourado com sublinhado 49×2.
class BldrHubTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const BldrHubTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 40),
          Semantics(
            button: true,
            selected: i == selected,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(labels[i],
                        maxLines: 1,
                        style: i == selected
                            ? BldrWorkoutTextV2.hubTabActive
                            : BldrWorkoutTextV2.hubTab),
                    const SizedBox(height: 10),
                    Container(
                      height: 2,
                      color: i == selected
                          ? BldrWorkoutColorsV2.gold
                          : Colors.transparent,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Botão circular dourado de 49 (busca do hub).
class BldrGoldCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  const BldrGoldCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 49,
          height: 49,
          decoration: const BoxDecoration(
            color: BldrWorkoutColorsV2.goldBrand,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 24, color: BldrWorkoutColorsV2.weekIcon),
        ),
      ),
    );
  }
}

/// Pílula pequena com borda dourada: ícone opcional + texto.
class BldrSmallGoldPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final double? width;
  final double height;
  final bool loading;
  final bool vertical;

  const BldrSmallGoldPill({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.width,
    this.height = 30,
    this.loading = false,
    this.vertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconW = loading
        ? const SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(
                strokeWidth: 1.5, color: BldrWorkoutColorsV2.gold))
        : (icon == null
            ? null
            : Icon(icon, size: vertical ? 13 : 18, color: BldrWorkoutColorsV2.gold));
    final text = Flexible(
      child: Text(label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: BldrWorkoutTextV2.pillLabel),
    );
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: loading ? null : onTap,
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: BldrWorkoutColorsV2.ctaBg,
            borderRadius: BorderRadius.circular(33),
            border: Border.all(color: BldrWorkoutColorsV2.pillBorder),
          ),
          child: vertical
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (iconW != null) iconW,
                    const SizedBox(height: 2),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [text]),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (iconW != null) ...[iconW, const SizedBox(width: 6)],
                    text,
                  ],
                ),
        ),
      ),
    );
  }
}

/// Card "Treino de hoje" (383×200, raio 33, borda dourada com glow).
/// [muscleMap] é o componente de muscle map atual (só o container vem do
/// mockup). [action] é o botão (iniciar) ou a pílula de concluído.
class BldrTodayWorkoutCard extends StatelessWidget {
  final String label;
  final String name;
  final String hint;
  final String meta;
  final Widget action;
  final Widget muscleMap;
  final VoidCallback? onTap;

  const BldrTodayWorkoutCard({
    super.key,
    required this.label,
    required this.name,
    required this.hint,
    required this.meta,
    required this.action,
    required this.muscleMap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 200),
        padding: const EdgeInsets.fromLTRB(26, 22, 16, 14),
        decoration: BoxDecoration(
          color: BldrColorsV2.bg,
          borderRadius: BorderRadius.circular(33),
          border: Border.all(color: BldrWorkoutColorsV2.todayBorder),
          gradient: const RadialGradient(
            radius: 1.2,
            colors: [Color(0x33C9A227), Color(0x00C9A227)],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 7),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrWorkoutTextV2.todayLabel),
                  const SizedBox(height: 6),
                  Text(name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrWorkoutTextV2.todayName),
                  const SizedBox(height: 6),
                  Text(hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrWorkoutTextV2.todayHint),
                  const SizedBox(height: 22),
                  action,
                  const SizedBox(height: 6),
                  Text(meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrWorkoutTextV2.metaWhite),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 116 × 174 em 440 px; encolhe em telas estreitas para não
            // espremer os textos.
            LayoutBuilder(builder: (context, c) {
              final w = (MediaQuery.sizeOf(context).width * 0.264)
                  .clamp(72.0, 116.0);
              return SizedBox(width: w, height: w * 1.5, child: muscleMap);
            }),
          ],
        ),
      ),
    );
  }
}

/// Estado visual de um dia na faixa da semana (decisão aprovada).
enum BldrWeekDayState { workoutDone, extraDone, lost, pending, rest }

/// Círculo 44×42 da semana.
class BldrWeekDayCircle extends StatelessWidget {
  final BldrWeekDayState state;
  final VoidCallback? onTap;

  const BldrWeekDayCircle({super.key, required this.state, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dashed = state == BldrWeekDayState.lost ||
        state == BldrWeekDayState.rest;
    final icon = switch (state) {
      BldrWeekDayState.workoutDone => TablerIcons.barbell,
      BldrWeekDayState.extraDone => TablerIcons.check,
      BldrWeekDayState.lost => TablerIcons.barbell_off,
      _ => null,
    };
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 42,
        child: CustomPaint(
          painter: _WeekCirclePainter(dashed: dashed),
          child: icon == null
              ? null
              : Icon(icon,
                  size: 22,
                  color: dashed
                      ? BldrWorkoutColorsV2.goldBrand
                      : BldrWorkoutColorsV2.weekIcon),
        ),
      ),
    );
  }
}

class _WeekCirclePainter extends CustomPainter {
  final bool dashed;
  const _WeekCirclePainter({required this.dashed});

  static const double _dash = 4;
  static const double _gap = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = BldrWorkoutColorsV2.goldBrand;
    if (!dashed) {
      canvas.drawOval(
          rect.deflate(1), Paint()..color = BldrWorkoutColorsV2.weekCircle);
      canvas.drawOval(rect.deflate(0.5), stroke);
      return;
    }
    // Tracejado medido no mockup (249:18901): traço 1 px #D4AF37,
    // segmentos de 4 px com intervalos de 1 px. Igual para descanso
    // (vazio) e dia perdido (com halter riscado).
    final path = Path()..addOval(rect.deflate(0.5));
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + _dash), stroke);
        d += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_WeekCirclePainter old) => old.dashed != dashed;
}

/// Card em pílula de "Meus treinos" (371×76, raio 60, borda dourada).
/// [muscleMap] é o mini muscle map atual.
class BldrPillWorkoutCard extends StatelessWidget {
  final String name;
  final String muscles;
  final String stats;
  final Widget muscleMap;
  final VoidCallback? onTap;

  const BldrPillWorkoutCard({
    super.key,
    required this.name,
    required this.muscles,
    required this.stats,
    required this.muscleMap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 76,
        padding: const EdgeInsets.only(left: 6, right: 20),
        decoration: BoxDecoration(
          color: BldrWorkoutColorsV2.listCardBg,
          borderRadius: BorderRadius.circular(60),
          border: Border.all(
              color: BldrWorkoutColorsV2.listCardBorder, width: 1.264),
        ),
        child: Row(
          children: [
            SizedBox(width: 50, height: 64, child: muscleMap),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrWorkoutTextV2.cardName),
                  Text(muscles,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrWorkoutTextV2.cardMuscles),
                  const SizedBox(height: 3),
                  Text(stats,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrWorkoutTextV2.cardStats),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card do "Explorar" (cinza #353535, borda dourada, raio 10,7).
class BldrExploreCard extends StatelessWidget {
  final IconData? icon;
  /// Marca no lugar do ícone (ex.: logo do BLDR Club, como no mockup).
  final Widget? leading;
  final String title;
  final String subtitle;
  final bool locked;
  final VoidCallback onTap;

  const BldrExploreCard({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: BldrWorkoutColorsV2.exploreBg,
            borderRadius: BorderRadius.circular(10.747),
            border: Border.all(
                color: BldrWorkoutColorsV2.goldBrand, width: 0.827),
          ),
          child: Row(
            children: [
              leading ??
                  Icon(icon, size: 13, color: BldrWorkoutColorsV2.goldBrand),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BldrWorkoutTextV2.exploreTitle),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BldrWorkoutTextV2.exploreSub),
                  ],
                ),
              ),
              if (locked)
                const Icon(TablerIcons.lock,
                    size: 11, color: BldrWorkoutColorsV2.goldBrand),
            ],
          ),
        ),
      ),
    );
  }
}

/// Separador dourado em gradiente (202 de largura, centralizado).
class BldrGoldDivider extends StatelessWidget {
  const BldrGoldDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 202,
        height: 1,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [
            Color(0x00D4AF37),
            BldrWorkoutColorsV2.divider,
            Color(0x00D4AF37),
          ]),
        ),
      ),
    );
  }
}

/// Caixa tracejada do estado vazio (raio 33, traço #6F6F6F).
class BldrDashedEmptyBox extends StatelessWidget {
  final Widget child;
  final double height;

  const BldrDashedEmptyBox(
      {super.key, required this.child, this.height = 106});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _DashedRRectPainter(),
      child: SizedBox(height: height, child: Center(child: child)),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  const _DashedRRectPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = BldrWorkoutColorsV2.secondary;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.5), const Radius.circular(33)));
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter old) => false;
}
