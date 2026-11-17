import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/theme/bldr_tokens.dart';

// ─────────────────────────────────────────────────────────────
// HUB DE TREINOS — revisão (Figma 305:1656 / 310:195)
// Botão da Workout Library, menu flutuante, carrossel "Meus treinos".
// ─────────────────────────────────────────────────────────────

/// Botão flutuante da Workout Library (Figma 300:910): círculo de 70 px,
/// borda dourada de 1 px e `layout-grid-add`. Diferente do botão do HAVOK
/// na navbar (esfera dourada preenchida): aqui só o contorno.
/// O fundo é a cor da página para continuar legível sobre o conteúdo.
class BldrWorkoutLibraryFab extends StatelessWidget {
  final VoidCallback onTap;
  final String semanticLabel;

  static const double size = 70;

  const BldrWorkoutLibraryFab(
      {super.key, required this.onTap, required this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: BldrColorsV2.bg,
            border: Border.all(color: BldrWorkoutColorsV2.goldBrand),
          ),
          alignment: Alignment.center,
          child: const Icon(TablerIcons.layout_grid_add,
              size: 24, color: BldrWorkoutColorsV2.goldBrand),
        ),
      ),
    );
  }
}

/// Item do [BldrWorkoutLibraryMenu].
class BldrLibraryMenuItem {
  /// Ícone Tabler 24 px dourado (Icon ou SVG do mockup).
  final Widget icon;
  final String title;
  final String description;

  /// Palavra final da descrição em dourado (ex.: "construa").
  final String? highlight;
  final bool locked;
  final VoidCallback onTap;

  const BldrLibraryMenuItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    this.highlight,
    this.locked = false,
  });
}

/// Menu flutuante da Workout Library (Figma 310:428): caixa `#060606`,
/// borda `#C9A227` 0,8, raio 28, sem título. Cada linha: ícone, divisor
/// vertical em gradiente, título e descrição.
class BldrWorkoutLibraryMenu extends StatelessWidget {
  final List<BldrLibraryMenuItem> items;
  final double width;

  const BldrWorkoutLibraryMenu(
      {super.key, required this.items, required this.width});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: width,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: BldrWorkoutColorsV2.libraryMenuBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color: BldrWorkoutColorsV2.libraryMenuBorder, width: 0.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [for (final item in items) _MenuRow(item: item)],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final BldrLibraryMenuItem item;
  const _MenuRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: item.title,
      child: GestureDetector(
        onTap: item.onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: SizedBox.square(dimension: 24, child: item.icon)),
                const SizedBox(width: 2),
                const _VerticalGoldDivider(),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: BldrWorkoutTextV2.menuTitle),
                        ),
                        if (item.locked) ...[
                          const SizedBox(width: 4),
                          const Icon(TablerIcons.lock,
                              size: 12, color: BldrWorkoutColorsV2.goldBrand),
                        ],
                      ]),
                      Text.rich(
                        TextSpan(children: [
                          TextSpan(text: item.description),
                          if (item.highlight != null) ...[
                            const TextSpan(text: ' '),
                            TextSpan(
                                text: item.highlight,
                                style: const TextStyle(
                                    color: BldrWorkoutColorsV2.goldBrand)),
                            const TextSpan(text: '.'),
                          ],
                        ]),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: BldrWorkoutTextV2.menuDesc,
                      ),
                    ],
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

class _VerticalGoldDivider extends StatelessWidget {
  const _VerticalGoldDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x00353535),
            BldrWorkoutColorsV2.goldBrand,
            Color(0x00353535),
          ],
          stops: [0, 0.49, 1],
        ),
      ),
    );
  }
}

/// Balão da dica de primeiro uso, apontando para o botão abaixo.
class BldrLibraryTip extends StatelessWidget {
  final String text;
  const BldrLibraryTip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: BldrWorkoutColorsV2.libraryMenuBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BldrWorkoutColorsV2.libraryMenuBorder),
        ),
        child: Text(text, style: BldrWorkoutTextV2.tip),
      ),
    );
  }
}

/// Ação do menu de três pontos do card de "Meus treinos".
enum BldrMyWorkoutAction { edit, delete }

/// Card de "Meus treinos" (Figma 309:496, proporção ajustada para o mapa
/// muscular ficar legível). Sem fundo, borda dourada, raio 16.
class BldrMyWorkoutCard extends StatelessWidget {
  final String name;
  final String groups;
  final String exercises;
  final String minutes;
  final Widget muscleMap;
  final double mapWidth;
  final VoidCallback onTap;
  final ValueChanged<BldrMyWorkoutAction> onAction;
  final String editLabel;
  final String deleteLabel;
  final String optionsLabel;

  const BldrMyWorkoutCard({
    super.key,
    required this.name,
    required this.groups,
    required this.exercises,
    required this.minutes,
    required this.muscleMap,
    required this.mapWidth,
    required this.onTap,
    required this.onAction,
    required this.editLabel,
    required this.deleteLabel,
    required this.optionsLabel,
  });

  static const double pad = 12;
  static double mapHeight(double mapWidth) => mapWidth * 1.3;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BldrWorkoutColorsV2.goldBrand),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mapa muscular é o elemento principal; nome e grupos
                  // embaixo, na largura toda do card (legível em 320 px).
                  Container(
                    width: mapWidth,
                    height: mapHeight(mapWidth),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: BldrWorkoutColorsV2.myCardMapBg,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: muscleMap,
                  ),
                  const SizedBox(height: 8),
                  Text(name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrWorkoutTextV2.myCardName),
                  const SizedBox(height: 2),
                  Text(groups,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrWorkoutTextV2.myCardGroups),
                  const Spacer(),
                  Container(
                      height: 1, color: BldrWorkoutColorsV2.myCardDivider),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: Text(exercises,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BldrWorkoutTextV2.myCardStats),
                    ),
                    const SizedBox(width: 6),
                    Text(minutes,
                        maxLines: 1, style: BldrWorkoutTextV2.myCardMinutes),
                  ]),
                ],
              ),
            ),
            // Três pontos: alvo próprio, não dispara o toque do card.
            Positioned(
              top: 2,
              right: 0,
              child: PopupMenuButton<BldrMyWorkoutAction>(
                tooltip: optionsLabel,
                padding: EdgeInsets.zero,
                color: BldrWorkoutColorsV2.libraryMenuBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(
                      color: BldrWorkoutColorsV2.libraryMenuBorder, width: 0.8),
                ),
                onSelected: onAction,
                itemBuilder: (_) => [
                  _item(BldrMyWorkoutAction.edit, TablerIcons.pencil, editLabel,
                      Colors.white),
                  _item(BldrMyWorkoutAction.delete, TablerIcons.trash,
                      deleteLabel, BldrColors.danger),
                ],
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(TablerIcons.dots_vertical,
                      size: 18, color: BldrWorkoutColorsV2.myCardMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<BldrMyWorkoutAction> _item(
          BldrMyWorkoutAction value, IconData icon, String label, Color c) =>
      PopupMenuItem(
        value: value,
        height: 40,
        child: Row(children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 10),
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BldrWorkoutTextV2.menuTitle.copyWith(color: c)),
          ),
        ]),
      );
}

/// Paginação do carrossel: até [perPage] itens por página.
List<List<T>> paginateMyWorkouts<T>(List<T> items, {int perPage = 4}) => [
      for (var i = 0; i < items.length; i += perPage)
        items.sublist(i, math.min(i + perPage, items.length)),
    ];

/// Carrossel paginado de "Meus treinos": grade 2×2 por página, altura
/// constante (sempre 2 linhas), pontos só com mais de uma página.
class BldrMyWorkoutsCarousel extends StatefulWidget {
  final int itemCount;

  /// Constrói o card do índice global, com a largura do mapa calculada.
  final Widget Function(BuildContext, int index, double mapWidth) itemBuilder;

  const BldrMyWorkoutsCarousel(
      {super.key, required this.itemCount, required this.itemBuilder});

  static const double hGap = 7;
  static const double vGap = 9;

  @override
  State<BldrMyWorkoutsCarousel> createState() => _BldrMyWorkoutsCarouselState();
}

class _BldrMyWorkoutsCarouselState extends State<BldrMyWorkoutsCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final indices = List<int>.generate(widget.itemCount, (i) => i);
    final pages = paginateMyWorkouts(indices);
    final ts = MediaQuery.textScalerOf(context);
    return LayoutBuilder(builder: (context, c) {
      final cardW = (c.maxWidth - BldrMyWorkoutsCarousel.hGap) / 2;
      final mapW = (cardW * 0.3).clamp(40.0, 58.0);
      // pad + mapa + nome + grupos + divisor + rodapé + pad
      final cardH = BldrMyWorkoutCard.pad * 2 +
          BldrMyWorkoutCard.mapHeight(mapW) +
          8 +
          ts.scale(15) * 1.25 +
          2 +
          ts.scale(11) * 1.25 +
          10 +
          1 +
          10 +
          ts.scale(11) * 1.25;
      final gridH = cardH * 2 + BldrMyWorkoutsCarousel.vGap;
      final page = _page.clamp(0, math.max(0, pages.length - 1));
      return Column(
        children: [
          SizedBox(
            height: gridH,
            child: PageView.builder(
              controller: _controller,
              itemCount: pages.length,
              onPageChanged: (p) => setState(() => _page = p),
              itemBuilder: (context, p) {
                final ids = pages[p];
                Widget cell(int slot) => SizedBox(
                      width: cardW,
                      height: cardH,
                      child: slot < ids.length
                          ? widget.itemBuilder(context, ids[slot], mapW)
                          : null,
                    );
                return Column(children: [
                  Row(children: [
                    cell(0),
                    const SizedBox(width: BldrMyWorkoutsCarousel.hGap),
                    cell(1),
                  ]),
                  const SizedBox(height: BldrMyWorkoutsCarousel.vGap),
                  Row(children: [
                    cell(2),
                    const SizedBox(width: BldrMyWorkoutsCarousel.hGap),
                    cell(3),
                  ]),
                ]);
              },
            ),
          ),
          if (pages.length > 1) ...[
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages.length; i++)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == page
                          ? BldrWorkoutColorsV2.goldBrand
                          : BldrWorkoutColorsV2.pageDotIdle,
                    ),
                  ),
              ],
            ),
          ],
        ],
      );
    });
  }
}
