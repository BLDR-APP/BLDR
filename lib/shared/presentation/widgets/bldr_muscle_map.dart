import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:bldr_fitness/features/workouts/domain/entities/bldr_muscle.dart';

const _defaultAssetRoot = 'assets/images/muscle_map';

class _OverlaySpec {
  final String file;
  final Rect rect;
  const _OverlaySpec(this.file, this.rect);
}

/// Renderer oficial do Muscle Map BLDR: base raster + overlays transparentes.
///
/// `muscles` aceita a API nova (`Map<BldrMuscle, double>`) e, por
/// compatibilidade, `Iterable<BldrMuscle>` com intensidade 1.
class BldrMuscleMap extends StatelessWidget {
  final Object muscles;
  final BldrMuscleMapView view;
  final BldrMuscleMapSize size;

  /// Disponível para testes de fallback e previews isolados.
  @visibleForTesting
  final String assetRoot;

  /// Registra exatamente os paths entregues a `Image.asset` em testes.
  @visibleForTesting
  final ValueChanged<String>? onAssetPath;

  /// Permite inspecionar apenas as máscaras na gallery de desenvolvimento.
  @visibleForTesting
  final bool showBase;

  const BldrMuscleMap({
    super.key,
    required this.muscles,
    this.view = BldrMuscleMapView.front,
    this.size = BldrMuscleMapSize.card,
    this.assetRoot = _defaultAssetRoot,
    this.onAssetPath,
    this.showBase = true,
  });

  Map<BldrMuscle, double> get intensities {
    final value = muscles;
    if (value is Map) {
      return {
        for (final e in value.entries)
          if (e.key is BldrMuscle && e.value is num)
            e.key as BldrMuscle: (e.value as num).toDouble().clamp(0, 1),
      };
    }
    if (value is Iterable<BldrMuscle>) {
      return {for (final muscle in value) muscle: 1};
    }
    assert(false,
        'muscles deve ser Map<BldrMuscle, double> ou Iterable<BldrMuscle>');
    return const {};
  }

  static Future<void> precache(BuildContext context) async {
    const common = [
      'base/body_front_base.png',
      'base/body_back_base.png',
      'front_masks/chest.png',
      'front_masks/front_delts.png',
      'front_masks/triceps.png',
      'back_masks/lats.png',
      'front_masks/quads.png',
    ];
    await Future.wait(common.map((path) async {
      try {
        await precacheImage(AssetImage('$_defaultAssetRoot/$path'), context);
      } catch (error) {
        if (kDebugMode) {
          debugPrint('BldrMuscleMap precache ignorado: $path ($error)');
        }
      }
    }));
  }

  @override
  Widget build(BuildContext context) {
    final maps = switch (view) {
      BldrMuscleMapView.front => [_body(BldrMuscleMapView.front)],
      BldrMuscleMapView.back => [_body(BldrMuscleMapView.back)],
      BldrMuscleMapView.both => [
          _body(BldrMuscleMapView.front),
          _body(BldrMuscleMapView.back),
        ],
    };

    return RepaintBoundary(
      child: SizedBox(
        key: const ValueKey('bldr-muscle-map'),
        width: size.widthFor(view),
        height: size.height,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < maps.length; i++) ...[
              if (i > 0) SizedBox(width: size.gap),
              maps[i],
            ],
          ],
        ),
      ),
    );
  }

  Widget _body(BldrMuscleMapView bodyView) {
    final isFront = bodyView == BldrMuscleMapView.front;
    final specs = isFront ? _frontSpecs : _backSpecs;
    final base = isFront ? 'body_front_base.png' : 'body_back_base.png';
    if (kDebugMode) {
      debugPrint('[MuscleMapView] Renderer selected base=$base '
          'overlays=${isFront ? 'front_masks' : 'back_masks'} '
          'requestedView=${view.name} bodyView=${bodyView.name}');
    }
    return SizedBox(
      key: ValueKey('bldr-muscle-map-${bodyView.name}'),
      width: size.singleViewWidth,
      height: size.height,
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          if (showBase)
            _asset('$assetRoot/base/$base',
                key: ValueKey('base-${bodyView.name}')),
          for (final entry in specs.entries)
            if ((intensities[entry.key] ?? 0) > 0)
              Positioned.fromRect(
                rect: _scaled(
                    entry.value.rect, size.singleViewWidth, size.height),
                child: Opacity(
                  opacity: intensities[entry.key]!.clamp(0, 1),
                  child: _asset('$assetRoot/${entry.value.file}',
                      key: ValueKey(
                          'overlay-${bodyView.name}-${entry.key.name}')),
                ),
              ),
        ],
      ),
    );
  }

  Widget _asset(String path, {Key? key}) {
    onAssetPath?.call(path);
    return Image.asset(
      path,
      key: key,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (_, error, __) {
        if (kDebugMode) {
          debugPrint('BldrMuscleMap asset ausente: $path ($error)');
        }
        return const SizedBox.expand();
      },
    );
  }

  static Rect _scaled(Rect rect, double width, double height) => Rect.fromLTWH(
        rect.left * width,
        rect.top * height,
        rect.width * width,
        rect.height * height,
      );
}

const _frontSpecs = <BldrMuscle, _OverlaySpec>{
  BldrMuscle.chest:
      _OverlaySpec('front_masks/chest.png', Rect.fromLTWH(0, 0, 1, 1)),
  BldrMuscle.frontDelts:
      _OverlaySpec('front_masks/front_delts.png', Rect.fromLTWH(0, 0, 1, 1)),
  BldrMuscle.sideDelts:
      _OverlaySpec('front_masks/side_delts.png', Rect.fromLTWH(0, 0, 1, 1)),
  BldrMuscle.biceps:
      _OverlaySpec('front_masks/biceps.png', Rect.fromLTWH(0, 0, 1, 1)),
  BldrMuscle.triceps:
      _OverlaySpec('front_masks/triceps.png', Rect.fromLTWH(0, 0, 1, 1)),
  BldrMuscle.forearms:
      _OverlaySpec('front_masks/forearms.png', Rect.fromLTWH(0, 0, 1, 1)),
  BldrMuscle.abs:
      _OverlaySpec('front_masks/abs.png', Rect.fromLTWH(0, 0, 1, 1)),
  BldrMuscle.obliques:
      _OverlaySpec('front_masks/obliques.png', Rect.fromLTWH(0, 0, 1, 1)),
  BldrMuscle.quads:
      _OverlaySpec('front_masks/quads.png', Rect.fromLTWH(0, 0, 1, 1)),
  BldrMuscle.adductors:
      _OverlaySpec('front_masks/adductors.png', Rect.fromLTWH(0, 0, 1, 1)),
  BldrMuscle.calves:
      _OverlaySpec('front_masks/calves.png', Rect.fromLTWH(0, 0, 1, 1)),
};

const _backSpecs = <BldrMuscle, _OverlaySpec>{
  BldrMuscle.traps:
      _OverlaySpec('back_masks/traps.png', Rect.fromLTWH(0, 0, 1, 1)),
  BldrMuscle.rearDelts:
      _OverlaySpec('back_masks/rear_delts.png', Rect.fromLTWH(0, 0, 1, 1)),
  BldrMuscle.lats:
      _OverlaySpec('back_masks/lats.png', Rect.fromLTWH(0, 0, 1, 1)),
  BldrMuscle.triceps:
      _OverlaySpec('back_masks/triceps.png', Rect.fromLTWH(0, 0, 1, 1)),
  BldrMuscle.forearms:
      _OverlaySpec('back_masks/forearms.png', Rect.fromLTWH(0, 0, 1, 1)),
  BldrMuscle.lowerBack:
      _OverlaySpec('back_masks/lower_back.png', Rect.fromLTWH(0, 0, 1, 1)),
  BldrMuscle.glutes:
      _OverlaySpec('back_masks/glutes.png', Rect.fromLTWH(0, 0, 1, 1)),
  BldrMuscle.hamstrings:
      _OverlaySpec('back_masks/hamstrings.png', Rect.fromLTWH(0, 0, 1, 1)),
  BldrMuscle.calves:
      _OverlaySpec('back_masks/calves.png', Rect.fromLTWH(0, 0, 1, 1)),
};
