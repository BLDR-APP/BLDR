# BLDR Muscle Map

O renderer oficial está em `lib/shared/presentation/widgets/bldr_muscle_map.dart`.
Ele compõe uma base raster com máscaras PNG transparentes full-canvas,
pixel-aligned à anatomia correspondente. Não usa presets prontos nem
bibliotecas anatômicas.

```dart
BldrMuscleMap(
  muscles: const {
    BldrMuscle.chest: 1,
    BldrMuscle.frontDelts: .8,
    BldrMuscle.triceps: .6,
  },
  view: BldrMuscleMapView.front,
  size: BldrMuscleMapSize.hero,
)
```

`view` aceita `front`, `back` e `both`; `size` aceita `card`, `hero` e
`summary`. Uma lista de `BldrMuscle` continua aceita por compatibilidade e
equivale a intensidade 1 para todos os itens.

## Assets e cache

Os arquivos ficam em `assets/images/muscle_map/`. `Image.asset` usa o cache
global do Flutter. `BldrMuscleMap.precache(context)` aquece as duas bases e as
máscaras mais comuns sem bloquear a construção do widget.

As máscaras de `front_masks/` têm o mesmo canvas `202×472` da base frontal; as
de `back_masks/`, o mesmo canvas `240×472` da base posterior. Todas usam origem
`(0,0)` e Rect normalizado `(0,0,1,1)`. O dourado é modulado pela luminância da
própria anatomia para preservar volume, linhas e sombras. O manifest está em
`muscle_map_manifest.source.json`; os specs ficam como constantes no renderer,
evitando parse de JSON por build.

## Extensão

Para adicionar um músculo: inclua o enum, crie o PNG full-canvas em
`front_masks/` ou `back_masks/`, registre seu `_OverlaySpec` com Rect completo e acrescente aliases ao
`MuscleNormalizer`. A galeria em
`lib/features/workouts/presentation/debug/bldr_muscle_map_gallery.dart` permite
validar base, máscaras, presets, intensidade e tamanhos; ela não possui rota de
produção.
