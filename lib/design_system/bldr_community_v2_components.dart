import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Componentes da Comunidade v2 (Figma UAUhuDakeseJsEfb8ynv5h).

/// Iniciais de até 2 letras ("Pedro Lima" → "PL", "pedro" → "PE").
String bldrInitials(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final p = parts.first;
    return (p.length >= 2 ? p.substring(0, 2) : p).toUpperCase();
  }
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

/// Avatar circular com anel dourado e iniciais (9:3 / 82:827).
class BldrCommunityAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final bool muted;
  final TextStyle? initialsStyle;

  const BldrCommunityAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = BldrCommunityV2.avatar,
    this.muted = false,
    this.initialsStyle,
  });

  @override
  Widget build(BuildContext context) {
    final initials = Center(
      child: Text(
        bldrInitials(name),
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: initialsStyle ??
            (muted
                ? BldrCommunityTextV2.plusLabel
                : BldrCommunityTextV2.initials),
      ),
    );
    final url = imageUrl;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: muted
            ? BldrCommunityColorsV2.moreBg
            : BldrCommunityColorsV2.avatarBg,
        border: Border.all(
          color: muted
              ? BldrCommunityColorsV2.moreBorder
              : BldrCommunityColorsV2.gold,
          width: BldrCommunityV2.avatarRing,
        ),
      ),
      child: url == null || url.isEmpty
          ? initials
          : ClipOval(
              child: Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => initials,
              ),
            ),
    );
  }
}

/// Botão SEGUIR em pílula (9:7).
class BldrFollowPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const BldrFollowPill({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Center(
            child: Container(
              height: BldrCommunityV2.followHeight,
              constraints: const BoxConstraints(minWidth: 64),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: BldrCommunityColorsV2.surface,
                borderRadius:
                    BorderRadius.circular(BldrCommunityV2.followHeight / 2),
                border: Border.all(
                  color: active
                      ? BldrCommunityColorsV2.divider
                      : BldrCommunityColorsV2.gold,
                  width: 0.8,
                ),
              ),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  maxLines: 1,
                  style: active
                      ? BldrCommunityTextV2.follow
                          .copyWith(color: BldrCommunityColorsV2.muted)
                      : BldrCommunityTextV2.follow,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Atalho redondo do cabeçalho (5:14): círculo 22, ícone 14, badge opcional.
class BldrCommunityShortcut extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;
  final int badge;

  const BldrCommunityShortcut({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    const size = BldrCommunityV2.shortcut;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: size + BldrCommunityV2.shortcutGap,
          height: 44,
          child: Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: BldrCommunityColorsV2.shortcutFill,
                    border: Border.all(
                        color: BldrCommunityColorsV2.shortcutBorder,
                        width: 0.35),
                  ),
                  child: Icon(icon,
                      size: BldrCommunityV2.shortcutIcon,
                      color: BldrCommunityColorsV2.muted),
                ),
                if (badge > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: BldrCommunityColorsV2.badge,
                      ),
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

/// FAB com contorno dourado e ícone pencil-plus (19:52).
class BldrCommunityFab extends StatelessWidget {
  final String semanticLabel;
  final VoidCallback onTap;

  const BldrCommunityFab(
      {super.key, required this.semanticLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: BldrCommunityV2.fab,
          height: BldrCommunityV2.fab,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: BldrCommunityColorsV2.surface,
            border: Border.all(color: BldrCommunityColorsV2.gold),
          ),
          child: const Icon(TablerIcons.pencil_plus,
              size: 24, color: BldrCommunityColorsV2.gold),
        ),
      ),
    );
  }
}

/// Linha de métricas centralizadas com divisórias verticais (80:869–80:876).
class BldrCommunityMetricRow extends StatelessWidget {
  final List<({String value, String label})> items;

  const BldrCommunityMetricRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        children.add(Container(
            width: 1, height: 42, color: BldrCommunityColorsV2.metricDivider));
      }
      children.add(Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(items[i].value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BldrCommunityTextV2.metricValue),
            const SizedBox(height: 2),
            Text(items[i].label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: BldrCommunityTextV2.metricLabel),
          ],
        ),
      ));
    }
    return Row(
        crossAxisAlignment: CrossAxisAlignment.center, children: children);
  }
}

/// Linha de ação de sheet (6:74–6:77): ícone, título, subtítulo e divisória.
class BldrCommunitySheetRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool destructive;
  final VoidCallback onTap;

  const BldrCommunitySheetRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        destructive ? BldrCommunityColorsV2.danger : BldrCommunityColorsV2.text;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 46,
                height: 46,
                child: Icon(icon, size: 17, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(top: 4, bottom: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom:
                            BorderSide(color: BldrCommunityColorsV2.divider)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: destructive
                              ? BldrCommunityTextV2.rowTitleDanger
                              : BldrCommunityTextV2.rowTitle),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: BldrCommunityTextV2.rowSub),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Divisória dos sheets de conteúdo (22:265).
class BldrCommunitySheetDivider extends StatelessWidget {
  const BldrCommunitySheetDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: BldrCommunityColorsV2.divider);
}

/// Linha de até 3 métricas alinhadas à esquerda (22:259–22:264).
class BldrCommunitySheetMetrics extends StatelessWidget {
  final List<(String, String)> items;

  const BldrCommunitySheetMetrics({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < 3; i++)
          Expanded(
            child: i >= items.length
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(items[i].$1,
                              maxLines: 1,
                              style: BldrCommunityTextV2.sheetMetric),
                        ),
                        Text(items[i].$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BldrCommunityTextV2.valueLabel),
                      ],
                    ),
                  ),
          ),
      ],
    );
  }
}

/// Voltar das telas da Comunidade (52:804).
class BldrCommunityBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const BldrCommunityBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: const SizedBox(
          width: 54,
          height: 44,
          child: Icon(TablerIcons.chevron_left,
              size: 24, color: BldrCommunityColorsV2.text),
        ),
      ),
    );
  }
}
