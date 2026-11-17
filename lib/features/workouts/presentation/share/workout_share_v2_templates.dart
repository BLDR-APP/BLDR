import 'package:flutter/material.dart';

import 'package:bldr_fitness/design_system/bldr_v2_components.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/bldr_muscle.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_share_data.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/summary_v2_format.dart';
import 'package:bldr_fitness/l10n/app_localizations.dart';
import 'package:bldr_fitness/shared/presentation/dashboard/home_v2_formatters.dart';
import 'package:bldr_fitness/shared/presentation/widgets/bldr_muscle_map.dart';
import 'package:bldr_fitness/theme/bldr_tokens.dart';

/// Formatos do compartilhar v2 (241:12891 / 241:12890). Enum de
/// apresentação: o `WorkoutShareStyle` do domínio não muda.
enum WorkoutShareFormatV2 { overlay, card }

/// Texto da imagem exportada: proporções do mockup, escaladas pela largura
/// do canvas (é conteúdo de imagem, não UI — ver TREINOS_V2.md, etapa 7).
TextStyle _img(double size, FontWeight w, Color c, double scale,
        {double? letterSpacing}) =>
    TextStyle(
      fontFamily: 'Inter',
      fontSize: size * scale,
      fontWeight: w,
      color: c,
      height: 1.2,
      letterSpacing: letterSpacing == null ? null : letterSpacing * scale,
      decoration: TextDecoration.none,
    );

/// Logo "BL / DR" empilhado (mockup usa CODEX; aqui Montserrat Bold).
class _StackedLogo extends StatelessWidget {
  final double size;
  const _StackedLogo({required this.size});
  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.w700,
      fontSize: size,
      height: 0.8,
      color: BldrShareColorsV2.gold,
      decoration: TextDecoration.none,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text('BL', style: style), Text('DR', style: style)],
    );
  }
}

class _MapView extends StatelessWidget {
  final WorkoutShareData data;
  final BldrMuscleMapView view;
  final double width;
  final double height;
  const _MapView(
      {required this.data,
      required this.view,
      required this.width,
      required this.height});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: height,
        child: FittedBox(
          fit: BoxFit.contain,
          child: BldrMuscleMap(
            muscles:
                data.muscleMapData?.muscles ?? const <BldrMuscle, double>{},
            view: view,
            size: BldrMuscleMapSize.summary,
          ),
        ),
      );
}

({String? duration, String? volume, String? sets}) _metrics(
    BuildContext context, WorkoutShareData data) {
  final locale = Localizations.localeOf(context).toString();
  return (
    duration: data.durationSeconds == null
        ? null
        : SummaryV2Format.clock(data.durationSeconds!),
    volume: data.totalVolume == null
        ? null
        : HomeV2Format.thousands(data.totalVolume!, locale),
    sets: data.totalSets?.toString(),
  );
}

/// Overlay (218:97): canvas 9:16 transparente; composição central com
/// logo, mapa frente/costas, métricas no meio e @usuário. Referência de
/// largura: 324 (canvas da prévia do mockup).
class WorkoutShareOverlayV2 extends StatelessWidget {
  final WorkoutShareData data;
  const WorkoutShareOverlayV2({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final m = _metrics(context, data);
    return AspectRatio(
      aspectRatio: 9 / 16,
      // Nunca pintar fundo opaco: o PNG vai sobre a foto/vídeo do Story.
      child: LayoutBuilder(builder: (context, box) {
        final s = box.maxWidth / 324;
        Widget metric(String value, String label, Color color) => Padding(
              padding: EdgeInsets.only(bottom: 7 * s),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(value,
                    maxLines: 1, style: _img(13, FontWeight.w700, color, s)),
                Text(label,
                    maxLines: 1,
                    style:
                        _img(6, FontWeight.w600, BldrShareColorsV2.label, s)),
              ]),
            );
        return Center(
          child: SizedBox(
            width: 288 * s,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _StackedLogo(size: 13 * s),
              SizedBox(height: 12 * s),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MapView(
                      data: data,
                      view: BldrMuscleMapView.front,
                      width: 100 * s,
                      height: 100 * s),
                  Expanded(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (m.duration != null)
                        metric(m.duration!, l10n.sh_duration,
                            BldrShareColorsV2.text),
                      if (m.volume != null)
                        metric(m.volume!, l10n.sh_volume,
                            BldrShareColorsV2.goldBright),
                      if (m.sets != null)
                        metric(m.sets!, l10n.sh_sets, BldrShareColorsV2.text),
                    ]),
                  ),
                  _MapView(
                      data: data,
                      view: BldrMuscleMapView.back,
                      width: 100 * s,
                      height: 100 * s),
                ],
              ),
              if (data.handle case final h?) ...[
                SizedBox(height: 4 * s),
                Text(h,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        _img(7, FontWeight.w600, BldrShareColorsV2.label, s)),
              ],
            ]),
          ),
        );
      }),
    );
  }
}

/// Card editorial (220:33): 9:16 opaco, referência de largura 216.
class WorkoutShareCardV2 extends StatelessWidget {
  final WorkoutShareData data;
  const WorkoutShareCardV2({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final m = _metrics(context, data);
    final date = data.summary.completedAtLabel.toUpperCase();
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: LayoutBuilder(builder: (context, box) {
        final s = box.maxWidth / 216;
        Widget metric(String value, String label, Color color) => Expanded(
              child: Column(children: [
                Text(value,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: _img(9, FontWeight.w700, color, s)),
                SizedBox(height: 9 * s),
                Text(label,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style:
                        _img(5, FontWeight.w600, BldrShareColorsV2.label, s)),
              ]),
            );
        return ClipRRect(
          borderRadius: BorderRadius.circular(20 * s),
          child: CustomPaint(
            painter: const BldrBackgroundV2Painter(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16 * s, 20 * s, 16 * s, 0),
              child: Column(children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StackedLogo(size: 11.87 * s),
                    const Spacer(),
                    if (data.handle case final h?)
                      Padding(
                        padding: EdgeInsets.only(top: 3 * s),
                        child: Text(h,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _img(7, FontWeight.w600,
                                BldrShareColorsV2.label, s)),
                      ),
                  ],
                ),
                SizedBox(height: 17 * s),
                Text(l10n.sh_completed,
                    textAlign: TextAlign.center,
                    style: _img(
                        7, FontWeight.w700, BldrShareColorsV2.goldBright, s)),
                SizedBox(height: 9 * s),
                Text(date,
                    textAlign: TextAlign.center,
                    style:
                        _img(6, FontWeight.w600, BldrShareColorsV2.label, s)),
                SizedBox(height: 21 * s),
                SizedBox(
                  height: 125 * s,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _MapView(
                          data: data,
                          view: BldrMuscleMapView.front,
                          width: 78 * s,
                          height: 125 * s),
                      _MapView(
                          data: data,
                          view: BldrMuscleMapView.back,
                          width: 78 * s,
                          height: 125 * s),
                    ],
                  ),
                ),
                SizedBox(height: 33 * s),
                Row(children: [
                  if (m.duration != null)
                    metric(
                        m.duration!, l10n.sh_duration, BldrShareColorsV2.text),
                  if (m.volume != null)
                    metric('${m.volume!} KG', l10n.sh_volume,
                        BldrShareColorsV2.goldBright),
                  if (m.sets != null)
                    metric(m.sets!, l10n.sh_sets, BldrShareColorsV2.text),
                ]),
                SizedBox(height: 22 * s),
                Container(height: 1 * s, color: BldrShareColorsV2.divider),
                SizedBox(height: 18 * s),
                _StackedLogo(size: 6.78 * s),
              ]),
            ),
          ),
        );
      }),
    );
  }
}
