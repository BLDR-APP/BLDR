import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bldr_fitness/features/achievements/presentation/achievements/achievement_provider.dart';
import 'package:bldr_fitness/features/achievements/presentation/achievements/widgets/achievement_toast.dart';

/// Envolve o app via MaterialApp.builder.
/// Usa um Stack para exibir o toast sobre o conteúdo, evitando
/// dependência do Overlay do Navigator (que fica abaixo na árvore).
class AchievementOverlay extends StatefulWidget {
  final Widget child;

  const AchievementOverlay({Key? key, required this.child}) : super(key: key);

  @override
  State<AchievementOverlay> createState() => _AchievementOverlayState();
}

class _AchievementOverlayState extends State<AchievementOverlay> {
  Map<String, dynamic>? _current;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AchievementProvider>();

    // Agenda _sync fora do build para evitar setState durante a fase de build.
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync(provider));

    return Stack(
      children: [
        widget.child,
        if (_current != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: AchievementToast(
              key: ValueKey(_current!['name']),
              achievement: _current!,
              queueLength: provider.queue.length,
              onDismiss: _onDismiss,
            ),
          ),
      ],
    );
  }

  void _sync(AchievementProvider provider) {
    if (!mounted) return;
    final next        = provider.hasPending ? provider.current : null;
    final nextName    = next?['name']     as String?;
    final currentName = _current?['name'] as String?;
    if (nextName != currentName) {
      setState(() => _current = next);
    }
  }

  void _onDismiss() {
    setState(() => _current = null);
    final provider = context.read<AchievementProvider>();
    provider.dismissCurrent();
    // Se há mais na fila, aguarda o slide de saída terminar antes de exibir o próximo
    if (provider.hasPending) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _current = provider.current);
      });
    }
  }
}
