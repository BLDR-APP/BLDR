import 'dart:io';

import 'package:flutter/material.dart';

import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Componentes dos Desafios v2 (Figma 121:893 e relacionados).

/// Capa com imagem de rede, arquivo local ou placeholder.
class BldrChallengeCover extends StatelessWidget {
  final String? imageUrl;
  final File? file;
  final double height;
  final BorderRadius radius;

  const BldrChallengeCover({
    super.key,
    this.imageUrl,
    this.file,
    required this.height,
    this.radius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    const placeholder = ColoredBox(color: BldrChallengeColorsV2.cover);
    final url = imageUrl;
    final Widget child = file != null
        ? Image.file(file!, fit: BoxFit.cover)
        : url != null && url.isNotEmpty
            ? Image.network(url,
                fit: BoxFit.cover, errorBuilder: (_, __, ___) => placeholder)
            : placeholder;
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(height: height, width: double.infinity, child: child),
    );
  }
}

/// Barra de progresso dos desafios.
class BldrChallengeProgressBar extends StatelessWidget {
  final double value;
  final double height;
  const BldrChallengeProgressBar(
      {super.key, required this.value, this.height = 6});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: BldrChallengeColorsV2.track),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value.clamp(0, 1).toDouble(),
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      BldrChallengeColorsV2.fillStart,
                      BldrCommunityColorsV2.goldBrand,
                    ]),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

/// Superfície sólida dos cards de desafio.
class BldrChallengeCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double radius;
  final Color borderColor;
  final String? semanticLabel;

  const BldrChallengeCard({
    super.key,
    required this.child,
    this.onTap,
    this.radius = 17,
    this.borderColor = BldrChallengeColorsV2.cardBorder,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: onTap != null,
        label: semanticLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: BldrCommunityColorsV2.surface,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: borderColor),
            ),
            child: child,
          ),
        ),
      );
}

/// CTA com borda dourada; sem [onTap] fica esmaecido.
class BldrChallengeCta extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final double minHeight;

  const BldrChallengeCta({
    super.key,
    required this.label,
    this.onTap,
    this.minHeight = 46,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: onTap != null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Opacity(
            opacity: onTap == null ? 0.45 : 1,
            child: Container(
              constraints: BoxConstraints(minHeight: minHeight),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border:
                    Border.all(color: BldrCommunityColorsV2.gold, width: 1.1),
              ),
              child: Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: BldrChallengeTextV2.cta),
            ),
          ),
        ),
      );
}

/// Rótulo de seção.
class BldrChallengeSection extends StatelessWidget {
  final String label;
  const BldrChallengeSection(this.label, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 10),
        child: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BldrChallengeTextV2.section),
      );
}

/// Pílula "ENCERRADO".
class BldrChallengePill extends StatelessWidget {
  final String label;
  const BldrChallengePill(this.label, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: BldrChallengeColorsV2.pillBg,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: BldrChallengeColorsV2.pillBorder),
        ),
        child: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BldrChallengeTextV2.pill),
      );
}
