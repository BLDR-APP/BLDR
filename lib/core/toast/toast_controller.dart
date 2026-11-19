import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Variantes do Toast System v2 (Figma i7tNK50cQOCmGJkVQvjLoN, 53:184).
/// DM e HAVOK estão reservados (fora desta rodada).
enum ToastVariant {
  success,
  info,
  warning,
  error,
  undo,
  achievement,
  goal,
  challenge,
  squads,
  offline,
  workout,
}

/// Prioridade na fila: maior passa à frente dos menores já enfileirados
/// (nunca interrompe o toast atual).
enum ToastPriority { low, normal, high }

/// Pedido de toast. Com [title] + [description] o toast é Expanded; só com
/// [message], Compact. [startCompact] mostra o compact com chevron e expande
/// ao toque (política híbrida).
@immutable
class ToastRequest {
  final ToastVariant variant;
  final String message;
  final String? title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final VoidCallback? onTap;
  final String? progressLabel;
  final String? progressValue;

  /// 0–1. Só no Goal expandido.
  final double? progress;
  final bool startCompact;

  /// Toasts com a mesma chave não se repetem enquanto um deles estiver
  /// visível ou na fila.
  final String? dedupeKey;
  final ToastPriority priority;

  /// `null` → persistente (só sai por [ToastController.dismiss] ou swipe).
  final Duration? duration;

  const ToastRequest({
    required this.variant,
    required this.message,
    this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.onTap,
    this.progressLabel,
    this.progressValue,
    this.progress,
    this.startCompact = false,
    this.dedupeKey,
    this.priority = ToastPriority.normal,
    this.duration = BldrToastV2.compactDuration,
  });

  bool get hasExpanded => title != null && description != null;
}

/// Fila global de toasts: um por vez, ordem de chegada dentro da mesma
/// prioridade, dedupe por chave, pausa enquanto outro overlay (conquistas)
/// ocupa o topo.
class ToastController extends ChangeNotifier {
  ToastController({this.gap = BldrToastV2.enter});

  /// Intervalo entre um toast sair e o próximo entrar (animação de saída).
  final Duration gap;

  final List<ToastRequest> _queue = [];
  ToastRequest? _current;
  Timer? _timer;
  Timer? _gapTimer;
  bool _paused = false;

  ToastRequest? get current => _current;
  List<ToastRequest> get pending => List.unmodifiable(_queue);
  bool get paused => _paused;

  void show(ToastRequest request) {
    final key = request.dedupeKey;
    if (key != null &&
        (_current?.dedupeKey == key || _queue.any((r) => r.dedupeKey == key))) {
      return;
    }
    var index = _queue.length;
    while (index > 0 &&
        _queue[index - 1].priority.index < request.priority.index) {
      index--;
    }
    _queue.insert(index, request);
    _advance();
  }

  /// Remove o toast atual (ou o da chave dada, visível ou na fila).
  void dismiss({String? dedupeKey}) {
    if (dedupeKey != null && _current?.dedupeKey != dedupeKey) {
      _queue.removeWhere((r) => r.dedupeKey == dedupeKey);
      return;
    }
    if (_current == null) return;
    _timer?.cancel();
    _current = null;
    notifyListeners();
    _gapTimer?.cancel();
    _gapTimer = Timer(gap, _advance);
  }

  /// Executa a ação principal (ex.: Desfazer) e fecha o toast.
  void triggerAction() {
    final action = _current?.onAction;
    dismiss();
    action?.call();
  }

  void triggerSecondary() {
    final action = _current?.onSecondary;
    dismiss();
    action?.call();
  }

  /// Segura o próximo toast (o atual continua) — usado enquanto a fila de
  /// conquistas ocupa o topo.
  void setPaused(bool value) {
    if (_paused == value) return;
    _paused = value;
    if (!value) _advance();
  }

  /// Reinicia o tempo do toast atual (ex.: usuário expandiu).
  void restartTimer() {
    final r = _current;
    _timer?.cancel();
    if (r == null) return;
    final d = r.duration == null ? null : BldrToastV2.expandedDuration;
    if (d != null) _timer = Timer(d, dismiss);
  }

  void _advance() {
    if (_current != null || _paused || _queue.isEmpty) return;
    if (_gapTimer?.isActive ?? false) return;
    _current = _queue.removeAt(0);
    notifyListeners();
    final d = _effectiveDuration(_current!);
    if (d != null) _timer = Timer(d, dismiss);
  }

  /// Expanded sem pedido explícito fica 5 s (compact, 3 s).
  static Duration? _effectiveDuration(ToastRequest r) {
    if (r.duration == null) return null;
    if (r.hasExpanded &&
        !r.startCompact &&
        r.duration == BldrToastV2.compactDuration) {
      return BldrToastV2.expandedDuration;
    }
    return r.duration;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gapTimer?.cancel();
    super.dispose();
  }
}
