import 'package:flutter/material.dart';

import 'package:bldr_fitness/design_system/bldr_components.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/bldr_muscle.dart';
import 'package:bldr_fitness/shared/presentation/widgets/bldr_muscle_map.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Galeria isolada para QA visual. Não está registrada nas rotas de produção.
class BldrMuscleMapGallery extends StatelessWidget {
  const BldrMuscleMapGallery({super.key});

  static const push = {
    BldrMuscle.chest: 1.0,
    BldrMuscle.frontDelts: .8,
    BldrMuscle.sideDelts: .6,
    BldrMuscle.triceps: .7,
  };
  static const pull = {
    BldrMuscle.lats: 1.0,
    BldrMuscle.traps: .75,
    BldrMuscle.rearDelts: .65,
    BldrMuscle.biceps: .7,
    BldrMuscle.forearms: .45,
  };
  static const legs = {
    BldrMuscle.quads: 1.0,
    BldrMuscle.adductors: .5,
    BldrMuscle.glutes: .85,
    BldrMuscle.hamstrings: .75,
    BldrMuscle.calves: .6,
  };
  static const teste = {
    BldrMuscle.biceps: 1.0,
    BldrMuscle.traps: .575,
    BldrMuscle.lats: .548,
    BldrMuscle.forearms: .452,
    BldrMuscle.rearDelts: .151,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BldrColors.bgBase,
      appBar: AppBar(title: const Text('Muscle Map QA')),
      body: BldrBackground(
        child: ListView(
          padding: const EdgeInsets.all(BldrSpacing.pageX),
          children: [
            _section('Bases', [
              _sample('Front', const {}, BldrMuscleMapView.front),
              _sample('Back', const {}, BldrMuscleMapView.back),
              _sample('Both', const {}, BldrMuscleMapView.both),
            ]),
            _section('Front masks', [
              _sample('BODY FRONT BASE', const {}, BldrMuscleMapView.front),
              for (final muscle in const [
                BldrMuscle.chest,
                BldrMuscle.frontDelts,
                BldrMuscle.sideDelts,
                BldrMuscle.biceps,
                BldrMuscle.triceps,
                BldrMuscle.forearms,
                BldrMuscle.abs,
                BldrMuscle.obliques,
                BldrMuscle.quads,
                BldrMuscle.adductors,
                BldrMuscle.calves,
              ])
                _sample(muscle.name, {muscle: 1}, BldrMuscleMapView.front),
              _sample('FRONT + PUSH', push, BldrMuscleMapView.front),
            ]),
            _section('Front masks · isolated on black', [
              for (final muscle in const [
                BldrMuscle.chest,
                BldrMuscle.frontDelts,
                BldrMuscle.sideDelts,
                BldrMuscle.biceps,
                BldrMuscle.triceps,
                BldrMuscle.forearms,
                BldrMuscle.abs,
                BldrMuscle.obliques,
                BldrMuscle.quads,
                BldrMuscle.adductors,
                BldrMuscle.calves,
              ])
                _maskSample(muscle, BldrMuscleMapView.front),
            ]),
            _section('Back overlays', [
              _sample('BASE BACK', const {}, BldrMuscleMapView.back),
              for (final muscle in const [
                BldrMuscle.traps,
                BldrMuscle.rearDelts,
                BldrMuscle.lats,
                BldrMuscle.triceps,
                BldrMuscle.forearms,
                BldrMuscle.lowerBack,
                BldrMuscle.glutes,
                BldrMuscle.hamstrings,
                BldrMuscle.calves,
              ])
                _sample(muscle.name, {muscle: 1}, BldrMuscleMapView.back),
              _sample('BACK + TESTE', teste, BldrMuscleMapView.back),
            ]),
            _section('Back masks · isolated on black', [
              for (final muscle in const [
                BldrMuscle.traps,
                BldrMuscle.rearDelts,
                BldrMuscle.lats,
                BldrMuscle.lowerBack,
                BldrMuscle.glutes,
                BldrMuscle.hamstrings,
                BldrMuscle.forearms,
                BldrMuscle.triceps,
                BldrMuscle.calves,
              ])
                _maskSample(muscle, BldrMuscleMapView.back),
            ]),
            _section('Presets', [
              _sample('Push', push, BldrMuscleMapView.both),
              _sample('Pull', pull, BldrMuscleMapView.both),
              _sample('Legs', legs, BldrMuscleMapView.both),
            ]),
            _section('Fundos BLDR', [
              _backgroundSample('Preto', const Color(0xFF000000)),
              _backgroundSample('Card', const Color(0xFF151515)),
              _backgroundSample('Glow', null),
            ]),
            _section('Intensity', [
              for (final value in const [0.0, .25, .5, .75, 1.0])
                _sample('${(value * 100).round()}%', {BldrMuscle.chest: value},
                    BldrMuscleMapView.front),
            ]),
            _section('Sizes', [
              for (final size in BldrMuscleMapSize.values)
                _sample(size.name, push, BldrMuscleMapView.front, size: size),
            ]),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: BldrText.sectionTitle),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: children),
        ]),
      );

  Widget _sample(
      String label, Map<BldrMuscle, double> muscles, BldrMuscleMapView view,
      {BldrMuscleMapSize size = BldrMuscleMapSize.hero}) {
    return BldrGlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        BldrMuscleMap(muscles: muscles, view: view, size: size),
        const SizedBox(height: 7),
        Text(label, style: BldrText.metaSm),
      ]),
    );
  }

  Widget _backgroundSample(String label, Color? color) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          gradient: color == null
              ? const RadialGradient(
                  colors: [Color(0x33C9A227), Color(0xFF050505)])
              : null,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const BldrMuscleMap(
            muscles: push,
            view: BldrMuscleMapView.front,
            size: BldrMuscleMapSize.hero,
          ),
          Text(label, style: BldrText.metaSm),
        ]),
      );

  Widget _maskSample(BldrMuscle muscle, BldrMuscleMapView view) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          BldrMuscleMap(
            muscles: {muscle: 1},
            view: view,
            size: BldrMuscleMapSize.hero,
            showBase: false,
          ),
          const SizedBox(height: 7),
          Text(muscle.name, style: BldrText.metaSm),
        ]),
      );
}
