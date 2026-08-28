import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class WorkoutShareExportController {
  bool _busy = false;
  bool get isBusy => _busy;

  Future<T?> run<T>(Future<T> Function() operation) async {
    if (_busy) return null;
    _busy = true;
    try {
      return await operation();
    } finally {
      _busy = false;
    }
  }

  Future<T?> runAfterPrepared<T>({
    required Future<void> Function() prepare,
    required Future<T> Function() operation,
  }) =>
      run(() async {
        await prepare();
        return operation();
      });
}

class WorkoutShareExporter {
  final WorkoutShareExportController controller;
  final Future<void> Function(BuildContext context) prepareAssets;

  WorkoutShareExporter({
    WorkoutShareExportController? controller,
    required this.prepareAssets,
  }) : controller = controller ?? WorkoutShareExportController();

  Future<File?> exportPng({
    required BuildContext context,
    required GlobalKey boundaryKey,
  }) {
    return controller.runAfterPrepared(
      prepare: () => prepareAssets(context),
      operation: () async {
        await WidgetsBinding.instance.endOfFrame;
        final boundary = boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary == null || boundary.debugNeedsPaint) {
          throw StateError('Template ainda não está pronto para exportação');
        }
        final logicalWidth = boundary.size.width;
        final ratio = 1080 / logicalWidth;
        final image = await boundary.toImage(pixelRatio: ratio);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes == null) throw StateError('Falha ao codificar PNG');
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/bldr_workout_story.png');
        await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
        return file;
      },
    );
  }
}
