import 'dart:async';

import 'package:bldr_fitness/features/workouts/domain/entities/bldr_muscle.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/muscle_normalizer.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_share_data.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_summary_data.dart';
import 'package:bldr_fitness/features/workouts/presentation/share/workout_share_exporter.dart';
import 'package:bldr_fitness/features/workouts/presentation/share/workout_share_templates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutSummaryData fixture({
  String name = 'Push Performance',
  BldrMuscleMapData? muscleMapData,
  bool includeMuscleMap = true,
}) =>
    WorkoutSummaryData(
      workoutId: 'completed-1',
      workoutName: name,
      source: 'free',
      durationSeconds: 3120,
      volumeKg: 8420,
      setsCompleted: 18,
      exerciseCount: 6,
      muscleGroups: const ['chest', 'front delts', 'triceps'],
      muscleMapData: includeMuscleMap
          ? muscleMapData ??
              const BldrMuscleMapData(
                muscles: {
                  BldrMuscle.chest: 1,
                  BldrMuscle.frontDelts: .8,
                  BldrMuscle.triceps: .65,
                },
                view: BldrMuscleMapView.front,
              )
          : null,
      newPRs: const [
        PersonalRecordData(exerciseName: 'Supino reto', newWeightKg: 100),
      ],
      xpEarned: 240,
      completedAt: DateTime(2026, 8, 24, 18, 42),
    );

void main() {
  test('WorkoutShareData completo normaliza username', () {
    final data = WorkoutShareData.fromSummary(fixture(), username: '@pedro');
    expect(data.handle, '@pedro');
    expect(data.durationSeconds, 3120);
    expect(data.totalVolume, 8420);
    expect(data.totalSets, 18);
    expect(data.exerciseCount, 6);
  });

  test('WorkoutShareData normaliza espaços e qualquer prefixo de arrobas', () {
    expect(
      WorkoutShareData.fromSummary(fixture(), username: '  pedro  ').handle,
      '@pedro',
    );
    expect(
      WorkoutShareData.fromSummary(fixture(), username: '@pedro').handle,
      '@pedro',
    );
    expect(
      WorkoutShareData.fromSummary(fixture(), username: '@@pedro').handle,
      '@pedro',
    );
  });

  test('WorkoutShareData sem username omite handle', () {
    expect(WorkoutShareData.fromSummary(fixture()).handle, isNull);
    expect(
      WorkoutShareData.fromSummary(fixture(), username: '   ').handle,
      isNull,
    );
  });

  test('WorkoutShareData sem Muscle Map usa fallback seguro', () {
    final data = WorkoutShareData.fromSummary(fixture(includeMuscleMap: false));
    expect(data.muscleMapData, isNull);
    expect(data.shareMuscleView, BldrMuscleMapView.front);
  });

  test('métricas zero são opcionais e não viram placeholders', () {
    final summary = WorkoutSummaryData(
      workoutId: 'x',
      workoutName: 'Curto',
      source: 'free',
      durationSeconds: 0,
      volumeKg: 0,
      setsCompleted: 0,
      muscleGroups: const [],
      newPRs: const [],
      xpEarned: 0,
      completedAt: DateTime(2026),
    );
    final data = WorkoutShareData.fromSummary(summary);
    expect(data.durationSeconds, isNull);
    expect(data.totalVolume, isNull);
    expect(data.totalSets, isNull);
    expect(data.xpEarned, isNull);
  });

  for (final style in WorkoutShareStyle.values) {
    testWidgets('${style.name} omite títulos e nome do conteúdo exportado',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: WorkoutShareTemplate(
          data: WorkoutShareData.fromSummary(fixture(
            name: 'Treino muito longo de performance para membros superiores',
          )),
          style: style,
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
          find.byKey(ValueKey(
              'share-${style == WorkoutShareStyle.muscleMap ? 'muscle-map' : style.name}')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('share-bldr-logo')), findsOneWidget);
      expect(find.byKey(const ValueKey('share-muscle-front')), findsOneWidget);
      expect(find.byKey(const ValueKey('share-muscle-back')), findsOneWidget);
      expect(find.textContaining('TREINO CONCLUÍDO'), findsNothing);
      expect(find.textContaining('PERFORMANCE'), findsNothing);
      expect(find.textContaining('MUSCLE MAP'), findsNothing);
      expect(find.textContaining('MINIMAL'), findsNothing);
      expect(find.textContaining('TREINO MUITO LONGO'), findsNothing);
    });
  }

  testWidgets('username vazio não renderiza linha nem placeholder',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: WorkoutShareTemplate(
        data: WorkoutShareData.fromSummary(fixture(), username: '  '),
        style: WorkoutShareStyle.performance,
      ),
    ));
    expect(find.byKey(const ValueKey('share-username')), findsNothing);
    expect(find.text('@'), findsNothing);
  });

  for (final view in BldrMuscleMapView.values) {
    testWidgets('template suporta Muscle Map ${view.name}', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final muscles = switch (view) {
        BldrMuscleMapView.front => const {BldrMuscle.chest: 1.0},
        BldrMuscleMapView.back => const {BldrMuscle.lats: 1.0},
        BldrMuscleMapView.both => const {
            BldrMuscle.chest: 1.0,
            BldrMuscle.lats: .8
          },
      };
      final map = BldrMuscleMapData(
        muscles: muscles,
        view: view,
      );
      await tester.pumpWidget(MaterialApp(
        home: WorkoutShareTemplate(
          data: WorkoutShareData.fromSummary(fixture(muscleMapData: map)),
          style: WorkoutShareStyle.performance,
        ),
      ));
      await tester.pump();
      expect(find.byKey(const ValueKey('bldr-muscle-map')), findsNWidgets(2));
      expect(
          find.byKey(const ValueKey('bldr-muscle-map-front')), findsOneWidget);
      expect(
          find.byKey(const ValueKey('bldr-muscle-map-back')), findsOneWidget);
    });
  }

  test('exportação aguarda assets antes de capturar', () async {
    final controller = WorkoutShareExportController();
    final events = <String>[];
    await controller.runAfterPrepared(
      prepare: () async => events.add('assets'),
      operation: () async {
        events.add('capture');
        return true;
      },
    );
    expect(events, ['assets', 'capture']);
  });

  test('previne múltiplas exportações simultâneas', () async {
    final controller = WorkoutShareExportController();
    final gate = Completer<void>();
    final first = controller.run(() async {
      await gate.future;
      return 1;
    });
    final second = await controller.run(() async => 2);
    expect(second, isNull);
    gate.complete();
    expect(await first, 1);
  });

  test('preparação do Share inclui logo, bases e máscaras utilizadas', () {
    final paths = workoutShareAssetPaths(WorkoutShareData.fromSummary(
      fixture(
        muscleMapData: const BldrMuscleMapData(
          muscles: {
            BldrMuscle.biceps: 1,
            BldrMuscle.glutes: .8,
          },
          view: BldrMuscleMapView.both,
        ),
      ),
    ));
    expect(paths, contains('assets/images/BLDR_CLEAN_BGLESS.png'));
    expect(paths,
        contains('assets/images/muscle_map/base/body_front_base.png'));
    expect(paths,
        contains('assets/images/muscle_map/base/body_back_base.png'));
    expect(paths,
        contains('assets/images/muscle_map/front_masks/biceps.png'));
    expect(paths,
        contains('assets/images/muscle_map/back_masks/glutes.png'));
    expect(paths, isNot(contains(
        'assets/images/muscle_map/front_masks/chest.png')));
  });
}
