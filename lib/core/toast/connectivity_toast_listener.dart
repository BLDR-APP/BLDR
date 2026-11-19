import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:bldr_fitness/core/connectivity/connectivity_repository.dart';
import 'package:bldr_fitness/core/toast/toast_controller.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';

/// Liga a conectividade ao Toast v2: offline → toast persistente (64:3);
/// voltou → some e mostra "Conexão restabelecida" (info, 3 s).
class ConnectivityToastListener extends StatefulWidget {
  final ConnectivityRepository repository;
  final ToastController controller;
  final Widget child;

  /// Oscilações mais curtas que isso não geram toast.
  final Duration debounce;

  const ConnectivityToastListener({
    super.key,
    required this.repository,
    required this.controller,
    required this.child,
    this.debounce = const Duration(seconds: 2),
  });

  static const offlineKey = 'connectivity.offline';
  static const onlineKey = 'connectivity.online';

  @override
  State<ConnectivityToastListener> createState() =>
      _ConnectivityToastListenerState();
}

class _ConnectivityToastListenerState extends State<ConnectivityToastListener> {
  StreamSubscription<bool>? _sub;
  Timer? _debounce;
  bool _offlineShown = false;

  @override
  void initState() {
    super.initState();
    _sub = widget.repository.onlineChanges().listen(_onChange);
    widget.repository.isOnline().then((online) {
      if (mounted && !online) _onChange(false);
    });
  }

  void _onChange(bool online) {
    _debounce?.cancel();
    _debounce = Timer(widget.debounce, () => _apply(online));
  }

  void _apply(bool online) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final c = widget.controller;
    if (!online && !_offlineShown) {
      _offlineShown = true;
      c.dismiss(dedupeKey: ConnectivityToastListener.onlineKey);
      c.show(ToastRequest(
        variant: ToastVariant.offline,
        message: l10n.toast_offline,
        dedupeKey: ConnectivityToastListener.offlineKey,
        priority: ToastPriority.high,
        duration: null,
      ));
    } else if (online && _offlineShown) {
      _offlineShown = false;
      c.dismiss(dedupeKey: ConnectivityToastListener.offlineKey);
      c.show(ToastRequest(
        variant: ToastVariant.info,
        message: l10n.toast_back_online,
        dedupeKey: ConnectivityToastListener.onlineKey,
      ));
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
