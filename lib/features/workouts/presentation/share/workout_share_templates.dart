import 'package:flutter/material.dart';

import 'package:bldr_fitness/features/workouts/domain/entities/bldr_muscle.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_share_data.dart';
import 'package:bldr_fitness/shared/presentation/widgets/bldr_muscle_map.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Sombra sutil para o texto ficar legível sobre qualquer foto/vídeo de
/// fundo no Stories — o canvas é transparente, então não há garantia de
/// contraste como havia com o fundo opaco anterior.
List<Shadow> _shareTextShadow([double scale = 1]) => [
      Shadow(
        color: Colors.black.withValues(alpha: 0.55),
        blurRadius: 6 * scale,
        offset: Offset(0, 1 * scale),
      ),
    ];

class WorkoutShareTemplate extends StatelessWidget {
  final WorkoutShareData data;
  final WorkoutShareStyle style;

  const WorkoutShareTemplate({
    super.key,
    required this.data,
    required this.style,
  });

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: 9 / 16,
        // Overlay/sticker de Stories: fundo transparente — o exporter captura
        // via RenderRepaintBoundary preservando o canal alpha. Nunca pintar
        // uma cor opaca aqui, senão o PNG cobre a foto/vídeo do usuário.
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Colors.transparent),
          child: LayoutBuilder(builder: (context, box) {
            final scale = box.maxWidth / 360;
            return Padding(
              padding: EdgeInsets.fromLTRB(28, 44, 28, 44).multiply(scale),
              child: switch (style) {
                WorkoutShareStyle.performance =>
                  PerformanceShareTemplate(data: data, scale: scale),
                WorkoutShareStyle.muscleMap =>
                  MuscleMapShareTemplate(data: data, scale: scale),
                WorkoutShareStyle.minimal =>
                  MinimalShareTemplate(data: data, scale: scale),
              },
            );
          }),
        ),
      );
}

class PerformanceShareTemplate extends StatelessWidget {
  final WorkoutShareData data;
  final double scale;

  const PerformanceShareTemplate({
    super.key,
    required this.data,
    this.scale = 1,
  });

  @override
  Widget build(BuildContext context) => _CompactComposition(
        key: const ValueKey('share-performance'),
        data: data,
        scale: scale,
      );
}

class MuscleMapShareTemplate extends StatelessWidget {
  final WorkoutShareData data;
  final double scale;

  const MuscleMapShareTemplate({
    super.key,
    required this.data,
    this.scale = 1,
  });

  @override
  Widget build(BuildContext context) => _CompactComposition(
        key: const ValueKey('share-muscle-map'),
        data: data,
        scale: scale,
      );
}

class MinimalShareTemplate extends StatelessWidget {
  final WorkoutShareData data;
  final double scale;

  const MinimalShareTemplate({
    super.key,
    required this.data,
    this.scale = 1,
  });

  @override
  Widget build(BuildContext context) => _CompactComposition(
        key: const ValueKey('share-minimal'),
        data: data,
        scale: scale,
      );
}

class _CompactComposition extends StatelessWidget {
  final WorkoutShareData data;
  final double scale;

  const _CompactComposition({
    super.key,
    required this.data,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final muscles = data.muscleMapData?.muscles ?? const <BldrMuscle, double>{};
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Brand(scale: scale),
          SizedBox(height: 12 * scale),
          SizedBox(
            height: 208 * scale,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _ShareMuscleMap(
                  key: const ValueKey('share-muscle-front'),
                  muscles: muscles,
                  view: BldrMuscleMapView.front,
                  scale: scale,
                ),
                SizedBox(width: 10 * scale),
                SizedBox(
                  width: 76 * scale,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Metrics(data: data, scale: scale),
                      if (data.handle case final handle?) ...[
                        SizedBox(height: 10 * scale),
                        Text(
                          handle,
                          key: const ValueKey('share-username'),
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          textAlign: TextAlign.center,
                          style: BldrText.body.copyWith(
                            color: BldrColors.textPrimary,
                            fontSize: 10 * scale,
                            shadows: _shareTextShadow(scale),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 10 * scale),
                _ShareMuscleMap(
                  key: const ValueKey('share-muscle-back'),
                  muscles: muscles,
                  view: BldrMuscleMapView.back,
                  scale: scale,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  final double scale;
  const _Brand({required this.scale});

  @override
  Widget build(BuildContext context) => SizedOverflowBox(
        size: Size(76 * scale, 28 * scale),
        alignment: Alignment.center,
        child: ClipRect(
          child: SizedBox(
            key: const ValueKey('share-bldr-logo'),
            width: 86 * scale,
            height: 28 * scale,
            child: Transform.scale(
              scale: 5,
              child: Image.asset(
                'assets/images/BLDR_CLEAN_BGLESS.png',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      );
}

class _ShareMuscleMap extends StatelessWidget {
  final Object muscles;
  final BldrMuscleMapView view;
  final double scale;

  const _ShareMuscleMap({
    super.key,
    required this.muscles,
    required this.view,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 104 * scale,
        height: 208 * scale,
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.center,
          child: SizedBox(
            width: BldrMuscleMapSize.summary.singleViewWidth,
            height: BldrMuscleMapSize.summary.height,
            child: BldrMuscleMap(
              muscles: muscles,
              view: view,
              size: BldrMuscleMapSize.summary,
            ),
          ),
        ),
      );
}

class _Metrics extends StatelessWidget {
  final WorkoutShareData data;
  final double scale;

  const _Metrics({required this.data, required this.scale});

  @override
  Widget build(BuildContext context) {
    final values = <(String, String)>[
      if (data.durationSeconds case final value?) (_duration(value), 'DURAÇÃO'),
      if (data.totalVolume case final value?) (_volume(value), 'VOLUME'),
      if (data.totalSets case final value?) ('$value', 'SÉRIES'),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < values.length; index++) ...[
          if (index > 0) SizedBox(height: 7 * scale),
          SizedBox(
            width: 76 * scale,
            child: Column(
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    values[index].$1,
                    maxLines: 1,
                    style: BldrText.kpiMd.copyWith(
                      color: BldrColors.goldBright,
                      fontSize: 15 * scale,
                      shadows: _shareTextShadow(scale),
                    ),
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  values[index].$2,
                  style: BldrText.label.copyWith(
                    color: BldrColors.textTertiary,
                    fontSize: 6.5 * scale,
                    letterSpacing: .7 * scale,
                    shadows: _shareTextShadow(scale),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static String _duration(int seconds) {
    final minutes = seconds ~/ 60;
    return minutes > 0 ? '$minutes MIN' : '$seconds S';
  }

  static String _volume(double kg) => kg >= 1000
      ? '${(kg / 1000).toStringAsFixed(1)} T'
      : '${kg.toStringAsFixed(0)} KG';
}

extension on EdgeInsets {
  EdgeInsets multiply(double value) => EdgeInsets.fromLTRB(
        left * value,
        top * value,
        right * value,
        bottom * value,
      );
}
