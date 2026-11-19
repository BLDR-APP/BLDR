import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:bldr_fitness/core/toast/toast_controller.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Visual do toast v2 (Figma 53:184): Compact (pílula 45 px) ou Expanded
/// (card até 360 px). Sem estado; a fila e o tempo ficam no
/// [ToastController].
class BldrToast extends StatelessWidget {
  final ToastRequest request;
  final bool expanded;
  final VoidCallback? onAction;
  final VoidCallback? onSecondary;
  final VoidCallback? onToggle;

  const BldrToast({
    super.key,
    required this.request,
    this.expanded = false,
    this.onAction,
    this.onSecondary,
    this.onToggle,
  });

  static Color accentOf(ToastVariant v) => switch (v) {
        ToastVariant.success => BldrToastColorsV2.success,
        ToastVariant.info => BldrToastColorsV2.info,
        ToastVariant.warning => BldrToastColorsV2.warning,
        ToastVariant.error => BldrToastColorsV2.error,
        _ => BldrToastColorsV2.gold,
      };

  static IconData iconOf(ToastVariant v) => switch (v) {
        ToastVariant.success => TablerIcons.checks,
        ToastVariant.info => TablerIcons.info_circle,
        ToastVariant.warning => TablerIcons.alert_triangle,
        ToastVariant.error => TablerIcons.alert_circle,
        ToastVariant.undo => TablerIcons.arrow_back_up,
        ToastVariant.achievement => TablerIcons.trophy,
        ToastVariant.goal => TablerIcons.target_arrow,
        ToastVariant.challenge => TablerIcons.swords,
        ToastVariant.squads => TablerIcons.users,
        ToastVariant.offline => TablerIcons.wifi_off,
        ToastVariant.workout => TablerIcons.stopwatch,
      };

  @override
  Widget build(BuildContext context) {
    final showExpanded =
        request.hasExpanded && (expanded || !request.startCompact);
    return showExpanded ? _expanded() : _compact();
  }

  BoxDecoration _box(double radius) => BoxDecoration(
        color: BldrToastColorsV2.bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
            color: accentOf(request.variant), width: BldrToastV2.border),
      );

  Widget _icon() => Icon(iconOf(request.variant),
      size: BldrToastV2.icon, color: accentOf(request.variant));

  Widget _compact() {
    final undo =
        request.variant == ToastVariant.undo && request.actionLabel != null;
    final expandable = request.hasExpanded && request.startCompact;
    return Container(
      constraints: const BoxConstraints(minHeight: BldrToastV2.compactHeight),
      padding: const EdgeInsets.symmetric(
          horizontal: BldrToastV2.padX, vertical: 10),
      decoration: _box(BldrToastV2.compactRadius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _icon(),
          const SizedBox(width: BldrToastV2.iconGap),
          Flexible(
            // Até 2 linhas: em telas estreitas/texto grande a mensagem não
            // perde a informação principal (ex.: nome da refeição).
            child: Text(request.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: BldrToastTextV2.compact),
          ),
          if (undo) ...[
            const SizedBox(width: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(request.actionLabel!,
                    maxLines: 1, style: BldrToastTextV2.undoAction),
              ),
            ),
          ],
          if (expandable) ...[
            const SizedBox(width: 8),
            const Icon(TablerIcons.chevron_down,
                size: BldrToastV2.chevron, color: BldrToastColorsV2.text),
          ],
        ],
      ),
    );
  }

  Widget _actionText(String label, TextStyle style, VoidCallback? onTap) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text('$label  →',
              maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
        ),
      );

  Widget _expanded() {
    final accent = accentOf(request.variant);
    final actionStyle = BldrToastTextV2.action.copyWith(color: accent);
    final hasSecondary = request.secondaryLabel != null;
    final hasProgress = request.progress != null;
    final collapsible = request.startCompact;

    Widget? actions;
    if (request.actionLabel != null) {
      final primary = _actionText(request.actionLabel!, actionStyle, onAction);
      actions = hasSecondary || hasProgress
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasSecondary)
                  Flexible(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onSecondary,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(request.secondaryLabel!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BldrToastTextV2.secondaryAction),
                      ),
                    ),
                  ),
                if (hasSecondary) const SizedBox(width: 16),
                Flexible(child: primary),
              ],
            )
          : Align(alignment: Alignment.centerLeft, child: primary);
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: BldrToastV2.expandedMaxWidth),
      padding: const EdgeInsets.fromLTRB(
          BldrToastV2.padX, BldrToastV2.expandedPadTop, BldrToastV2.padX, 14),
      decoration: _box(BldrToastV2.expandedRadius),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _icon(),
              const SizedBox(width: BldrToastV2.iconGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(request.title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BldrToastTextV2.title),
                    ),
                    const SizedBox(height: 8),
                    Text(request.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: BldrToastTextV2.description),
                    if (actions != null && !hasSecondary && !hasProgress) ...[
                      const SizedBox(height: 14),
                      actions,
                    ],
                  ],
                ),
              ),
              if (collapsible) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggle,
                  child: const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(TablerIcons.chevron_up,
                        size: BldrToastV2.chevron,
                        color: BldrToastColorsV2.text),
                  ),
                ),
              ],
            ],
          ),
          if (hasProgress) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(request.progressLabel ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BldrToastTextV2.progressLabel),
                ),
                const SizedBox(width: 8),
                Text(request.progressValue ?? '',
                    maxLines: 1,
                    style: BldrToastTextV2.action.copyWith(color: accent)),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: BldrToastV2.progressHeight,
                child: Stack(children: [
                  const Positioned.fill(
                      child:
                          ColoredBox(color: BldrToastColorsV2.progressTrack)),
                  FractionallySizedBox(
                    widthFactor: request.progress!.clamp(0.0, 1.0),
                    heightFactor: 1,
                    child: const DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: BldrToastColorsV2.progressGradient)),
                  ),
                ]),
              ),
            ),
          ],
          if (actions != null && (hasSecondary || hasProgress)) ...[
            SizedBox(height: hasProgress ? 10 : 22),
            actions,
          ],
        ],
      ),
    );
  }
}
