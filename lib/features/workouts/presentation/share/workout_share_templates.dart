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
        mapHeight: 124,
        metricScale: 1,
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
        mapHeight: 148,
        metricScale: .92,
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
        mapHeight: 76,
        metricScale: .88,
      );
}

class _CompactComposition extends StatelessWidget {
  final WorkoutShareData data;
  final double scale;
  final double mapHeight;
  final double metricScale;

  const _CompactComposition({
    super.key,
    required this.data,
    required this.scale,
    required this.mapHeight,
    required this.metricScale,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const _Brand(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Metrics(data: data, scale: scale * metricScale),
                  if (data.muscleMapData != null) ...[
                    SizedBox(height: 30 * scale),
                    LayoutBuilder(
                      builder: (context, constraints) => SizedBox(
                        width: constraints.maxWidth,
                        height: mapHeight * scale,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          child: BldrMuscleMap(
                            muscles: data.muscleMapData!.muscles,
                            view: data.shareMuscleView,
                            size: BldrMuscleMapSize.summary,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (data.handle case final handle?) ...[
                    SizedBox(height: 22 * scale),
                    Text(
                      handle,
                      textAlign: TextAlign.center,
                      style: BldrText.body.copyWith(
                        color: BldrColors.textPrimary,
                        fontSize: 11 * scale,
                        shadows: _shareTextShadow(scale),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 20 * scale),
        ],
      );
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: Text(
          'BLDR',
          style: TextStyle(
            color: BldrColors.goldBright,
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            shadows: _shareTextShadow(),
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < values.length; index++) ...[
          if (index > 0) SizedBox(width: 17 * scale),
          SizedBox(
            width: 82 * scale,
            child: Column(
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    values[index].$1,
                    maxLines: 1,
                    style: BldrText.kpiMd.copyWith(
                      color: BldrColors.goldBright,
                      fontSize: 17 * scale,
                      shadows: _shareTextShadow(scale),
                    ),
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  values[index].$2,
                  style: BldrText.label.copyWith(
                    color: BldrColors.textTertiary,
                    fontSize: 7 * scale,
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
