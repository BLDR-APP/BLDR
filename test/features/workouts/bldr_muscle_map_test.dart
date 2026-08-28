import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bldr_fitness/features/workouts/domain/entities/bldr_muscle.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/muscle_normalizer.dart';
import 'package:bldr_fitness/features/workouts/data/models/workout_models.dart';
import 'package:bldr_fitness/features/workouts/presentation/mappers/legacy_ui_maps.dart';
import 'package:bldr_fitness/shared/presentation/widgets/bldr_muscle_map.dart';

void main() {
  test('normaliza aliases e ignora músculo desconhecido', () {
    expect(MuscleNormalizer.fromString('Pectoralis Major'), BldrMuscle.chest);
    expect(MuscleNormalizer.fromString('latissimus_dorsi'), BldrMuscle.lats);
    expect(MuscleNormalizer.fromString('rhomboids'), BldrMuscle.traps);
    expect(MuscleNormalizer.fromString('rear deltoids'), BldrMuscle.rearDelts);
    expect(
        MuscleNormalizer.fromString('posterior deltoid'), BldrMuscle.rearDelts);
    expect(MuscleNormalizer.fromString('upper back'), BldrMuscle.traps);
    expect(MuscleNormalizer.fromString('músculo inventado'), isNull);
  });

  test('agrega primários e secundários deterministicamente', () {
    final result = MuscleNormalizer.aggregate(const [
      BldrMuscleContribution(primary: ['chest'], secondary: ['triceps']),
      BldrMuscleContribution(primary: ['front delts'], secondary: ['triceps']),
    ]);
    expect(result[BldrMuscle.chest], closeTo(.909, .001));
    expect(result[BldrMuscle.frontDelts], closeTo(.909, .001));
    expect(result[BldrMuscle.triceps], closeTo(1, .001));
  });

  group('dominantView', () {
    test('chest dominante usa front', () {
      expect(
        MuscleNormalizer.dominantView(const {BldrMuscle.chest: 1}),
        BldrMuscleMapView.front,
      );
    });

    test('lats dominante usa back', () {
      expect(
        MuscleNormalizer.dominantView(const {BldrMuscle.lats: 1}),
        BldrMuscleMapView.back,
      );
    });

    test('lats + biceps usa back', () {
      expect(
        MuscleNormalizer.dominantView(const {
          BldrMuscle.lats: .6,
          BldrMuscle.biceps: 1,
        }),
        BldrMuscleMapView.back,
      );
    });

    test('lats + traps + biceps + forearms usa back', () {
      expect(
        MuscleNormalizer.dominantView(const {
          BldrMuscle.lats: .55,
          BldrMuscle.traps: .58,
          BldrMuscle.biceps: 1,
          BldrMuscle.forearms: .45,
        }),
        BldrMuscleMapView.back,
      );
    });

    test('chest + triceps usa front', () {
      expect(
        MuscleNormalizer.dominantView(const {
          BldrMuscle.chest: .7,
          BldrMuscle.triceps: 1,
        }),
        BldrMuscleMapView.front,
      );
    });

    test('quads + calves usa front', () {
      expect(
        MuscleNormalizer.dominantView(const {
          BldrMuscle.quads: .8,
          BldrMuscle.calves: 1,
        }),
        BldrMuscleMapView.front,
      );
    });

    test('glúteos e posteriores usam back', () {
      expect(
        MuscleNormalizer.dominantView(const {
          BldrMuscle.glutes: 1,
          BldrMuscle.hamstrings: .8,
        }),
        BldrMuscleMapView.back,
      );
    });

    test('glúteos + posteriores + panturrilhas usa back', () {
      expect(
        MuscleNormalizer.dominantView(const {
          BldrMuscle.glutes: .7,
          BldrMuscle.hamstrings: .8,
          BldrMuscle.calves: 1,
        }),
        BldrMuscleMapView.back,
      );
    });

    test('quadríceps dominante usa front', () {
      expect(
        MuscleNormalizer.dominantView(const {BldrMuscle.quads: 1}),
        BldrMuscleMapView.front,
      );
    });

    test('misto soma intensidades e músculos neutros não decidem', () {
      final muscles = const <BldrMuscle, double>{
        BldrMuscle.chest: .4,
        BldrMuscle.lats: .7,
        BldrMuscle.triceps: 1,
        BldrMuscle.forearms: 1,
      };
      expect(MuscleNormalizer.viewScores(muscles), (front: .4, back: .7));
      expect(MuscleNormalizer.dominantView(muscles), BldrMuscleMapView.back);
    });

    test('mapa vazio usa front com segurança', () {
      expect(MuscleNormalizer.dominantView(const {}), BldrMuscleMapView.front);
    });

    test('apenas bíceps usa fallback front', () {
      expect(
        MuscleNormalizer.dominantView(const {BldrMuscle.biceps: 1}),
        BldrMuscleMapView.front,
      );
    });

    test('apenas tríceps usa fallback front', () {
      expect(
        MuscleNormalizer.dominantView(const {BldrMuscle.triceps: 1}),
        BldrMuscleMapView.front,
      );
    });

    test('dados reais do treino Teste resultam em back estrutural', () {
      final muscles = MuscleNormalizer.aggregate(const [
        BldrMuscleContribution(
          primary: ['lats'],
          secondary: ['biceps', 'rhomboids'],
        ),
        BldrMuscleContribution(
          primary: ['lats'],
          secondary: ['biceps', 'rhomboids', 'rear deltoids'],
        ),
        BldrMuscleContribution(
          primary: ['upper back'],
          secondary: ['biceps', 'forearms'],
        ),
        BldrMuscleContribution(
          primary: ['biceps'],
          secondary: ['forearms'],
        ),
        BldrMuscleContribution(
          primary: ['biceps'],
          secondary: ['forearms'],
        ),
      ]);
      final scores = MuscleNormalizer.viewScores(muscles);
      expect(scores.front, 0);
      expect(scores.back, closeTo(1.274, .001));
      expect(MuscleNormalizer.dominantView(muscles), BldrMuscleMapView.back);
    });
  });

  test('template ExerciseDB completo chega ao agregador e ao mapper legacy',
      () {
    final template = WorkoutModels.templateFromMap({
      'id': 'ppl-push',
      'name': 'PPL - Push',
      'workout_template_exercises': [
        {
          'order_index': 0,
          'exercise_db_id': 'ex-supino',
          'exercises': {
            'exercise_db_id': 'ex-supino',
            'name': 'Barbell Bench Press',
            'primary_muscle_group': ['pectorals'],
            'secondary_muscle_groups': ['triceps', 'front deltoid'],
          },
        },
        {
          'order_index': 1,
          'exercise_db_id': 'ex-shoulder-press',
          'exercises': {
            'exercise_db_id': 'ex-shoulder-press',
            'name': 'Shoulder Press',
            'primary_muscle_group': ['front deltoid'],
            'secondary_muscle_groups': ['triceps'],
          },
        },
      ],
    });

    expect(template.exercises, hasLength(2));
    expect(
        template.exercises.first.exercise!.primaryMuscleGroup, ['pectorals']);
    expect(template.exercises.first.exercise!.secondaryMuscleGroups,
        ['triceps', 'front deltoid']);

    final muscles = MuscleNormalizer.aggregateTemplate(template);
    expect(
        muscles.keys,
        containsAll([
          BldrMuscle.chest,
          BldrMuscle.frontDelts,
          BldrMuscle.triceps,
        ]));
    expect(muscles[BldrMuscle.frontDelts], 1);
    expect(muscles[BldrMuscle.triceps], closeTo(.71, .01));
    expect(muscles[BldrMuscle.chest], closeTo(.65, .01));

    final legacy = templateToLegacyMap(template);
    final first = (legacy['workout_template_exercises'] as List).first as Map;
    expect((first['exercises'] as Map)['secondary_muscle_groups'],
        ['triceps', 'front deltoid']);
  });

  test('Hero e MiniCard derivam o mesmo mapa e vista do mesmo template', () {
    final template = WorkoutModels.templateFromMap({
      'id': 'pull-id',
      'name': 'Qualquer nome',
      'workout_template_exercises': [
        {
          'exercise_db_id': 'pulldown-id',
          'exercises': {
            'name': 'Pulldown',
            'primary_muscle_group': ['lats'],
            'secondary_muscle_groups': ['biceps'],
          },
        },
      ],
    });
    final hero = MuscleNormalizer.mapDataForTemplate(template);
    final miniCard = MuscleNormalizer.mapDataForTemplate(template);
    expect(hero.muscles, miniCard.muscles);
    expect(hero.view, miniCard.view);
    expect(hero.view, BldrMuscleMapView.back);
  });

  for (final view in BldrMuscleMapView.values) {
    for (final size in BldrMuscleMapSize.values) {
      testWidgets('renderiza ${view.name}/${size.name}', (tester) async {
        await tester.pumpWidget(_host(BldrMuscleMap(
          muscles: const {
            BldrMuscle.chest: 1,
            BldrMuscle.lats: .5,
            BldrMuscle.calves: .25,
          },
          view: view,
          size: size,
        )));
        await tester.pump();
        expect(find.byKey(const ValueKey('bldr-muscle-map')), findsOneWidget);
      });
    }
  }

  testWidgets('sem músculos mantém base visível', (tester) async {
    await tester.pumpWidget(_host(const BldrMuscleMap(
      muscles: <BldrMuscle, double>{},
      view: BldrMuscleMapView.both,
    )));
    expect(find.byKey(const ValueKey('base-front')), findsOneWidget);
    expect(find.byKey(const ValueKey('base-back')), findsOneWidget);
    expect(find.byKey(const ValueKey('overlay-front-chest')), findsNothing);
  });

  testWidgets('view back seleciona base e overlays traseiros', (tester) async {
    await tester.pumpWidget(_host(const BldrMuscleMap(
      muscles: {
        BldrMuscle.lats: 1,
        BldrMuscle.traps: .8,
      },
      view: BldrMuscleMapView.back,
    )));
    expect(find.byKey(const ValueKey('base-back')), findsOneWidget);
    expect(find.byKey(const ValueKey('base-front')), findsNothing);
    expect(find.byKey(const ValueKey('overlay-back-lats')), findsOneWidget);
    expect(find.byKey(const ValueKey('overlay-back-traps')), findsOneWidget);
    expect(find.byKey(const ValueKey('overlay-front-lats')), findsNothing);
  });

  testWidgets('view back nunca solicita assets front', (tester) async {
    final loadedPaths = <String>[];
    await tester.pumpWidget(_host(BldrMuscleMap(
      muscles: const {
        BldrMuscle.traps: 1,
        BldrMuscle.rearDelts: 1,
        BldrMuscle.lats: 1,
        BldrMuscle.triceps: 1,
        BldrMuscle.forearms: 1,
        BldrMuscle.lowerBack: 1,
        BldrMuscle.glutes: 1,
        BldrMuscle.hamstrings: 1,
        BldrMuscle.calves: 1,
      },
      view: BldrMuscleMapView.back,
      onAssetPath: loadedPaths.add,
    )));

    expect(loadedPaths,
        contains('assets/images/muscle_map/base/body_back_base.png'));
    final overlays = loadedPaths.where((path) => !path.contains('/base/'));
    expect(overlays, hasLength(9));
    expect(
        overlays.every(
            (path) => path.startsWith('assets/images/muscle_map/back_masks/')),
        isTrue);
    expect(loadedPaths.any((path) => path.contains('front_masks')), isFalse);
    expect(
        loadedPaths.any((path) => path.contains('body_front_base')), isFalse);
  });

  testWidgets('view front seleciona base e overlays frontais', (tester) async {
    await tester.pumpWidget(_host(const BldrMuscleMap(
      muscles: {
        BldrMuscle.chest: 1,
        BldrMuscle.quads: .8,
      },
      view: BldrMuscleMapView.front,
    )));
    expect(find.byKey(const ValueKey('base-front')), findsOneWidget);
    expect(find.byKey(const ValueKey('base-back')), findsNothing);
    expect(find.byKey(const ValueKey('overlay-front-chest')), findsOneWidget);
    expect(find.byKey(const ValueKey('overlay-front-quads')), findsOneWidget);
  });

  testWidgets('view front usa somente máscaras full-canvas frontais',
      (tester) async {
    final loadedPaths = <String>[];
    await tester.pumpWidget(_host(BldrMuscleMap(
      muscles: const {
        BldrMuscle.chest: 1,
        BldrMuscle.frontDelts: 1,
        BldrMuscle.sideDelts: 1,
        BldrMuscle.biceps: 1,
        BldrMuscle.triceps: 1,
        BldrMuscle.forearms: 1,
        BldrMuscle.abs: 1,
        BldrMuscle.obliques: 1,
        BldrMuscle.quads: 1,
        BldrMuscle.adductors: 1,
        BldrMuscle.calves: 1,
      },
      view: BldrMuscleMapView.front,
      onAssetPath: loadedPaths.add,
    )));

    expect(loadedPaths,
        contains('assets/images/muscle_map/base/body_front_base.png'));
    final overlays = loadedPaths.where((path) => !path.contains('/base/'));
    expect(overlays, hasLength(11));
    expect(
        overlays.every(
            (path) => path.startsWith('assets/images/muscle_map/front_masks/')),
        isTrue);
    expect(loadedPaths.any((path) => path.contains('back_masks')), isFalse);
    expect(loadedPaths.any((path) => path.contains('body_back_base')), isFalse);
  });

  testWidgets('intensidade zero oculta e um exibe overlay', (tester) async {
    await tester.pumpWidget(_host(const BldrMuscleMap(
      muscles: {BldrMuscle.chest: 0},
    )));
    expect(find.byKey(const ValueKey('overlay-front-chest')), findsNothing);

    await tester.pumpWidget(_host(const BldrMuscleMap(
      muscles: {BldrMuscle.chest: 1},
    )));
    expect(find.byKey(const ValueKey('overlay-front-chest')), findsOneWidget);
  });

  testWidgets('asset ausente não lança exceção', (tester) async {
    await tester.pumpWidget(_host(const BldrMuscleMap(
      muscles: {BldrMuscle.chest: 1},
      assetRoot: 'assets/images/inexistente',
    )));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('bldr-muscle-map')), findsOneWidget);
  });
}

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: child),
      ),
    );
