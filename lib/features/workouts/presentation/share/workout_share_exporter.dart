import 'dart:io';
import 'dart:ui' as ui;

import 'package:bldr_fitness/features/workouts/domain/entities/bldr_muscle.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_share_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

enum WorkoutShareStage { prepare, boundary, render, encode, write }

class WorkoutShareExportException implements Exception {
  final WorkoutShareStage stage;
  final Object cause;
  const WorkoutShareExportException(this.stage, this.cause);

  @override
  String toString() => 'WorkoutShareExportException(${stage.name}, $cause)';
}

const _shareLogoAsset = 'assets/images/BLDR_CLEAN_BGLESS.png';
const _shareMuscleRoot = 'assets/images/muscle_map';

Set<String> workoutShareAssetPaths(WorkoutShareData data) {
  final result = <String>{
    _shareLogoAsset,
    '$_shareMuscleRoot/base/body_front_base.png',
    '$_shareMuscleRoot/base/body_back_base.png',
  };
  final muscles = data.muscleMapData?.muscles.keys ?? const <BldrMuscle>[];
  const front = <BldrMuscle, String>{
    BldrMuscle.chest: 'chest',
    BldrMuscle.frontDelts: 'front_delts',
    BldrMuscle.sideDelts: 'side_delts',
    BldrMuscle.biceps: 'biceps',
    BldrMuscle.triceps: 'triceps',
    BldrMuscle.forearms: 'forearms',
    BldrMuscle.abs: 'abs',
    BldrMuscle.obliques: 'obliques',
    BldrMuscle.quads: 'quads',
    BldrMuscle.adductors: 'adductors',
    BldrMuscle.calves: 'calves',
  };
  const back = <BldrMuscle, String>{
    BldrMuscle.traps: 'traps',
    BldrMuscle.rearDelts: 'rear_delts',
    BldrMuscle.lats: 'lats',
    BldrMuscle.triceps: 'triceps',
    BldrMuscle.forearms: 'forearms',
    BldrMuscle.lowerBack: 'lower_back',
    BldrMuscle.glutes: 'glutes',
    BldrMuscle.hamstrings: 'hamstrings',
    BldrMuscle.calves: 'calves',
  };
  for (final muscle in muscles) {
    if (front[muscle] case final file?) {
      result.add('$_shareMuscleRoot/front_masks/$file.png');
    }
    if (back[muscle] case final file?) {
      result.add('$_shareMuscleRoot/back_masks/$file.png');
    }
  }
  return result;
}

Future<void> prepareWorkoutShareAssets(
  BuildContext context,
  WorkoutShareData data,
) async {
  await Future.wait(workoutShareAssetPaths(data)
      .map((path) => precacheImage(AssetImage(path), context)));
}

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
    ValueChanged<WorkoutShareStage>? onStage,
  }) {
    return controller.runAfterPrepared(
      prepare: () async {
        onStage?.call(WorkoutShareStage.prepare);
        try {
          await prepareAssets(context);
        } catch (error) {
          throw WorkoutShareExportException(WorkoutShareStage.prepare, error);
        }
      },
      operation: () async {
        var currentStage = WorkoutShareStage.boundary;
        WidgetsBinding.instance.scheduleFrame();
        await WidgetsBinding.instance.endOfFrame;
        var boundary = boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary?.debugNeedsPaint == true) {
          WidgetsBinding.instance.scheduleFrame();
          await WidgetsBinding.instance.endOfFrame;
          boundary = boundaryKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
        }
        onStage?.call(WorkoutShareStage.boundary);
        if (boundary == null || boundary.debugNeedsPaint) {
          throw WorkoutShareExportException(
            WorkoutShareStage.boundary,
            StateError('Template ainda não está pronto para exportação'),
          );
        }
        final logicalWidth = boundary.size.width;
        if (logicalWidth <= 0) {
          throw WorkoutShareExportException(
            WorkoutShareStage.boundary,
            StateError('Template sem largura para exportação'),
          );
        }
        final ratio = 1080 / logicalWidth;
        try {
          currentStage = WorkoutShareStage.render;
          onStage?.call(WorkoutShareStage.render);
          final image = await boundary.toImage(pixelRatio: ratio);
          currentStage = WorkoutShareStage.encode;
          onStage?.call(WorkoutShareStage.encode);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          if (bytes == null) throw StateError('Falha ao codificar PNG');
          currentStage = WorkoutShareStage.write;
          onStage?.call(WorkoutShareStage.write);
          final dir = await getTemporaryDirectory();
          final file = File(
              '${dir.path}/bldr_workout_story_${DateTime.now().microsecondsSinceEpoch}.png');
          await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
          if (!await file.exists() || await file.length() == 0) {
            throw StateError('Arquivo PNG ausente ou vazio');
          }
          return file;
        } on WorkoutShareExportException {
          rethrow;
        } catch (error) {
          throw WorkoutShareExportException(currentStage, error);
        }
      },
    );
  }
}
