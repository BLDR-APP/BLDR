import 'package:flutter/widgets.dart';

import 'package:bldr_fitness/core/di/injection.dart';
import 'package:bldr_fitness/core/toast/toast_controller.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// API de uso nas telas: `context.toast.success('...')`.
/// Só in-app. Textos sempre vindos dos `.arb`.
class BldrToaster {
  BldrToaster(this._controller, this._l10n);

  final ToastController _controller;
  final AppLocalizations _l10n;

  void show(ToastRequest request) => _controller.show(request);

  void success(String message, {String? dedupeKey}) => show(ToastRequest(
      variant: ToastVariant.success, message: message, dedupeKey: dedupeKey));

  void info(String message, {String? dedupeKey}) => show(ToastRequest(
      variant: ToastVariant.info, message: message, dedupeKey: dedupeKey));

  void warning(String message, {String? dedupeKey}) => show(ToastRequest(
      variant: ToastVariant.warning, message: message, dedupeKey: dedupeKey));

  /// Erro compact; com [title] + [description] vira Expanded, e
  /// [retryLabel]/[onRetry] mostram a ação "TENTAR NOVAMENTE →".
  void error(String message,
          {String? title,
          String? description,
          String? retryLabel,
          VoidCallback? onRetry,
          String? dedupeKey}) =>
      show(ToastRequest(
        variant: ToastVariant.error,
        message: message,
        title: title,
        description: description,
        actionLabel: onRetry == null ? null : retryLabel,
        onAction: onRetry,
        dedupeKey: dedupeKey,
        priority: ToastPriority.high,
      ));

  /// Ação desfazível (58:23). [onUndo] roda ao tocar em "Desfazer".
  void undo(String message,
          {required VoidCallback onUndo, String? dedupeKey}) =>
      show(ToastRequest(
        variant: ToastVariant.undo,
        message: message,
        actionLabel: _l10n.toast_undo,
        onAction: onUndo,
        dedupeKey: dedupeKey,
        duration: BldrToastV2.undoDuration,
      ));

  void goal(String message,
          {String? title,
          String? description,
          String? progressLabel,
          String? progressValue,
          double? progress,
          String? dedupeKey}) =>
      show(ToastRequest(
        variant: ToastVariant.goal,
        message: message,
        title: title,
        description: description,
        progressLabel: progressLabel,
        progressValue: progressValue,
        progress: progress,
        dedupeKey: dedupeKey,
        startCompact: title != null,
      ));

  void dismiss({String? dedupeKey}) =>
      _controller.dismiss(dedupeKey: dedupeKey);
}

extension BldrToastContext on BuildContext {
  BldrToaster get toast =>
      BldrToaster(getIt<ToastController>(), AppLocalizations.of(this));
}
