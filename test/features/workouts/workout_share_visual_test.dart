import 'dart:ui' as ui;

import 'package:bldr_fitness/features/workouts/domain/entities/bldr_muscle.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/muscle_normalizer.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_share_data.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_summary_data.dart';
import 'package:bldr_fitness/features/workouts/presentation/share/workout_share_templates.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/workout_summary_screen.dart';
import 'package:bldr_fitness/shared/presentation/widgets/bldr_muscle_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final visualSummary = WorkoutSummaryData(
  workoutId: 'visual-completed',
  workoutName: 'Push Performance',
  source: 'free',
  durationSeconds: 3120,
  volumeKg: 8420,
  setsCompleted: 18,
  exerciseCount: 6,
  muscleGroups: const ['chest', 'front delts', 'triceps', 'lats'],
  muscleMapData: const BldrMuscleMapData(
    muscles: {
      BldrMuscle.chest: 1,
      BldrMuscle.frontDelts: .8,
      BldrMuscle.triceps: .65,
      BldrMuscle.lats: .55,
    },
    view: BldrMuscleMapView.front,
  ),
  newPRs: const [
    PersonalRecordData(exerciseName: 'Supino reto', newWeightKg: 100),
  ],
  xpEarned: 240,
  completedAt: DateTime(2026, 8, 24, 18, 42),
);

void main() {
  setUpAll(() async {
    final loader = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'));
    await loader.load();
  });

  final shareData = WorkoutShareData.fromSummary(
    visualSummary,
    username: 'pedro',
  );

  testWidgets('warm-up visual assets', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: WorkoutShareTemplate(
        data: shareData,
        style: WorkoutShareStyle.muscleMap,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
  });

  const visualStyles = [
    WorkoutShareStyle.performance,
    WorkoutShareStyle.muscleMap,
    WorkoutShareStyle.minimal,
  ];
  for (final style in visualStyles) {
    testWidgets('preview visual ${style.name}', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Inter'),
        home: RepaintBoundary(
          key: ValueKey('share-capture-${style.name}'),
          child: WorkoutShareTemplate(data: shareData, style: style),
        ),
      ));
      final context = tester.element(find.byType(WorkoutShareTemplate));
      await tester.runAsync(() async {
        await BldrMuscleMap.precache(context);
        await precacheImage(
            const AssetImage('assets/images/BLDR_CLEAN_BGLESS.png'), context);
      });
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        find.byKey(ValueKey('share-capture-${style.name}')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(WorkoutShareTemplate),
        matchesGoldenFile('goldens/workout_share_${style.name}.png'),
      );
    });
  }

  testWidgets('export visual mantém 1080x1920 e cantos transparentes',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: RepaintBoundary(
        key: boundaryKey,
        child: WorkoutShareTemplate(
          data: shareData,
          style: WorkoutShareStyle.performance,
        ),
      ),
    ));
    final context = tester.element(find.byType(WorkoutShareTemplate));
    await tester.runAsync(() async {
      await BldrMuscleMap.precache(context);
      await precacheImage(
          const AssetImage('assets/images/BLDR_CLEAN_BGLESS.png'), context);
    });
    await tester.pumpAndSettle();

    final boundary =
        boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 3));
    expect(image, isNotNull);
    expect(image!.width, 1080);
    expect(image.height, 1920);
    final bytes = await tester
        .runAsync(() => image.toByteData(format: ui.ImageByteFormat.rawRgba));
    expect(bytes, isNotNull);
    expect(bytes!.getUint8(3), 0);
  });

  testWidgets('preview visual workout summary', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Inter'),
      ),
      home: WorkoutSummaryScreen(data: visualSummary),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(WorkoutSummaryScreen),
      matchesGoldenFile('goldens/workout_summary.png'),
    );
  });
}
