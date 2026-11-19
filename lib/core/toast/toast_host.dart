import 'package:flutter/material.dart';

import 'package:bldr_fitness/core/toast/toast_controller.dart';
import 'package:bldr_fitness/design_system/bldr_toast.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Host global do Toast System. Fica no `MaterialApp.builder`, acima do
/// Navigator: aparece sobre rotas, sheets e diálogos, no topo central abaixo
/// da safe area. Só o próprio toast recebe toques.
class ToastHost extends StatefulWidget {
  final ToastController controller;
  final Widget child;

  /// Segura a fila (ex.: conquista visível no topo).
  final bool paused;

  const ToastHost({
    super.key,
    required this.controller,
    required this.child,
    this.paused = false,
  });

  @override
  State<ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<ToastHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: BldrToastV2.enter);
  ToastRequest? _shown;
  bool _expanded = false;
  double _drag = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
    widget.controller.setPaused(widget.paused);
    // Toast já ativo ao montar: mostra depois do 1º frame (MediaQuery pronto).
    WidgetsBinding.instance.addPostFrameCallback((_) => _onChange());
  }

  @override
  void didUpdateWidget(ToastHost old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
    }
    if (old.paused != widget.paused) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => widget.controller.setPaused(widget.paused));
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    _anim.dispose();
    super.dispose();
  }

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  void _onChange() {
    if (!mounted) return;
    final next = widget.controller.current;
    if (next != null) {
      setState(() {
        _shown = next;
        _expanded = false;
        _drag = 0;
      });
      if (_reduceMotion) {
        _anim.value = 1;
      } else {
        _anim.forward(from: 0);
      }
    } else if (_shown != null) {
      if (_reduceMotion) {
        setState(() => _shown = null);
        _anim.value = 0;
      } else {
        _anim.reverse().whenComplete(() {
          if (mounted && widget.controller.current == null) {
            setState(() => _shown = null);
          }
        });
      }
    }
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    widget.controller.restartTimer();
  }

  @override
  Widget build(BuildContext context) {
    final r = _shown;
    final top = MediaQuery.paddingOf(context).top + BldrToastV2.topGap;
    return Stack(
      children: [
        widget.child,
        if (r != null)
          Positioned(
            top: top,
            left: 16,
            right: 16,
            child: Align(
              alignment: Alignment.topCenter,
              child: AnimatedBuilder(
                animation: _anim,
                builder: (context, child) {
                  final t = Curves.easeOutCubic.transform(_anim.value);
                  return Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, (1 - t) * -24 + _drag),
                      child: child,
                    ),
                  );
                },
                child: _toastBody(context, r),
              ),
            ),
          ),
      ],
    );
  }

  Widget _toastBody(BuildContext context, ToastRequest r) {
    final c = widget.controller;
    final l10n = AppLocalizations.of(context);
    final expandable = r.hasExpanded && r.startCompact;
    return Semantics(
      container: true,
      liveRegion: true,
      hint: l10n.toast_dismiss_hint,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: expandable
            ? _toggle
            : (r.onTap == null
                ? null
                : () {
                    c.dismiss();
                    r.onTap!();
                  }),
        onVerticalDragUpdate: (d) {
          if (d.delta.dy < 0 || _drag < 0) {
            setState(() => _drag = (_drag + d.delta.dy).clamp(-80.0, 0.0));
          }
        },
        onVerticalDragEnd: (d) {
          if (_drag < -24 || (d.primaryVelocity ?? 0) < -300) {
            c.dismiss();
          } else {
            setState(() => _drag = 0);
          }
        },
        child: Material(
          type: MaterialType.transparency,
          child: BldrToast(
            request: r,
            expanded: _expanded,
            onAction: c.triggerAction,
            onSecondary: c.triggerSecondary,
            onToggle: _toggle,
          ),
        ),
      ),
    );
  }
}
