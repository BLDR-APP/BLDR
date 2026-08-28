/// Modelo muscular canônico do BLDR, independente da ExerciseDB e de SDKs.
enum BldrMuscle {
  chest,
  frontDelts,
  sideDelts,
  rearDelts,
  biceps,
  triceps,
  forearms,
  abs,
  obliques,
  traps,
  lats,
  lowerBack,
  glutes,
  quads,
  hamstrings,
  calves,
  adductors,
}

enum BldrMuscleMapView { front, back, both }

enum BldrMuscleMapSize { card, hero, summary }

extension BldrMuscleMapSizeDimension on BldrMuscleMapSize {
  double get height => switch (this) {
        BldrMuscleMapSize.card => 64,
        BldrMuscleMapSize.hero => 140,
        BldrMuscleMapSize.summary => 220,
      };

  double get singleViewWidth => height / 2;
  double get width => singleViewWidth;
  double get gap => switch (this) {
        BldrMuscleMapSize.card => 3,
        BldrMuscleMapSize.hero => 6,
        BldrMuscleMapSize.summary => 10,
      };

  double widthFor(BldrMuscleMapView view) => view == BldrMuscleMapView.both
      ? singleViewWidth * 2 + gap
      : singleViewWidth;
}
