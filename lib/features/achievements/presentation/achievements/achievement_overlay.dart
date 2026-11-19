import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bldr_fitness/core/toast/toast_controller.dart';
import 'package:bldr_fitness/features/achievements/presentation/achievements/achievement_provider.dart';
import 'package:bldr_fitness/features/achievements/presentation/achievements/widgets/achievement_modal.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/main.dart' show appNavigatorKey;

/// T4: liga a fila de conquistas ([AchievementProvider]) ao Toast v2.
///
/// Não desenha nada: cada conquista vira um toast Achievement (compact que
/// expande, Figma 58:29 / 59:3) de prioridade alta. A fila continua no
/// provider: o próximo item só entra quando o atual é dispensado
/// ([ToastRequest.onDismissed] → [AchievementProvider.dismissCurrent]).
/// "VER DETALHES" abre o mesmo [AchievementModal] de antes.
class AchievementOverlay extends StatefulWidget {
  final Widget child;
  final ToastController controller;

  const AchievementOverlay(
      {super.key, required this.child, required this.controller});

  @override
  State<AchievementOverlay> createState() => _AchievementOverlayState();
}

class _AchievementOverlayState extends State<AchievementOverlay> {
  /// Nome da conquista já entregue ao controller (evita repetir).
  String? _shown;

  static String _key(String name) => 'achievement:$name';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AchievementProvider>();
    // Fora do build para não notificar durante a fase de build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync(provider));
    return widget.child;
  }

  void _sync(AchievementProvider provider) {
    if (!mounted) return;
    final current = provider.current;
    final name = current?['name'] as String?;
    if (name == null) {
      _shown = null;
      return;
    }
    if (name == _shown) return;
    _shown = name;
    final l = AppLocalizations.of(context);
    final description = (current!['description'] as String?)?.trim() ?? '';
    widget.controller.show(ToastRequest(
      variant: ToastVariant.achievement,
      message: name,
      title: l.toast_achievement_title,
      description: description.isEmpty ? name : '$name · $description',
      actionLabel: l.toast_achievement_details,
      onAction: () => _openModal(current),
      startCompact: true,
      dedupeKey: _key(name),
      priority: ToastPriority.high,
      duration: const Duration(seconds: 5),
      onDismissed: () {
        if (!mounted) return;
        final p = context.read<AchievementProvider>();
        if (p.current?['name'] == name) p.dismissCurrent();
      },
    ));
  }

  void _openModal(Map<String, dynamic> achievement) {
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) return;
    showDialog(
      context: ctx,
      barrierColor: Colors.black87,
      builder: (_) =>
          AchievementModal(achievement: achievement, onDismiss: () {}),
    );
  }
}
