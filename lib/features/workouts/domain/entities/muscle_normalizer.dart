import 'package:bldr_fitness/features/workouts/domain/entities/bldr_muscle.dart';
import 'package:bldr_fitness/features/workouts/domain/entities/workout_template.dart';

class BldrMuscleContribution {
  final Iterable<String> primary;
  final Iterable<String> secondary;
  const BldrMuscleContribution(
      {this.primary = const [], this.secondary = const []});
}

class BldrMuscleMapData {
  final Map<BldrMuscle, double> muscles;
  final BldrMuscleMapView view;

  const BldrMuscleMapData({required this.muscles, required this.view});
}

abstract final class MuscleNormalizer {
  static const _frontViewMuscles = <BldrMuscle>{
    BldrMuscle.chest,
    BldrMuscle.frontDelts,
    BldrMuscle.sideDelts,
    BldrMuscle.abs,
    BldrMuscle.obliques,
    BldrMuscle.quads,
    BldrMuscle.adductors,
  };

  static const _backViewMuscles = <BldrMuscle>{
    BldrMuscle.traps,
    BldrMuscle.rearDelts,
    BldrMuscle.lats,
    BldrMuscle.lowerBack,
    BldrMuscle.glutes,
    BldrMuscle.hamstrings,
  };

  static const _map = <String, BldrMuscle>{
    'chest': BldrMuscle.chest,
    'pectorals': BldrMuscle.chest,
    'pectoralis major': BldrMuscle.chest,
    'peito': BldrMuscle.chest,
    'front delts': BldrMuscle.frontDelts,
    'front deltoid': BldrMuscle.frontDelts,
    'anterior deltoid': BldrMuscle.frontDelts,
    'deltoide anterior': BldrMuscle.frontDelts,
    'side delts': BldrMuscle.sideDelts,
    'lateral deltoid': BldrMuscle.sideDelts,
    'medial deltoid': BldrMuscle.sideDelts,
    'shoulders': BldrMuscle.sideDelts,
    'deltoid': BldrMuscle.sideDelts,
    'delts': BldrMuscle.sideDelts,
    'ombros': BldrMuscle.sideDelts,
    'rear delts': BldrMuscle.rearDelts,
    'rear deltoid': BldrMuscle.rearDelts,
    'rear deltoids': BldrMuscle.rearDelts,
    'posterior deltoid': BldrMuscle.rearDelts,
    'biceps': BldrMuscle.biceps,
    'biceps brachii': BldrMuscle.biceps,
    'upper arm': BldrMuscle.biceps,
    'triceps': BldrMuscle.triceps,
    'triceps brachii': BldrMuscle.triceps,
    'forearms': BldrMuscle.forearms,
    'forearm': BldrMuscle.forearms,
    'brachioradialis': BldrMuscle.forearms,
    'abs': BldrMuscle.abs,
    'abdominals': BldrMuscle.abs,
    'rectus abdominis': BldrMuscle.abs,
    'core': BldrMuscle.abs,
    'obliques': BldrMuscle.obliques,
    'oblique': BldrMuscle.obliques,
    'serratus anterior': BldrMuscle.obliques,
    'traps': BldrMuscle.traps,
    'trapezius': BldrMuscle.traps,
    'upper back': BldrMuscle.traps,
    'rhomboid': BldrMuscle.traps,
    'rhomboids': BldrMuscle.traps,
    'lats': BldrMuscle.lats,
    'latissimus dorsi': BldrMuscle.lats,
    'back': BldrMuscle.lats,
    'costas': BldrMuscle.lats,
    'lower back': BldrMuscle.lowerBack,
    'erector spinae': BldrMuscle.lowerBack,
    'spinal erectors': BldrMuscle.lowerBack,
    'glutes': BldrMuscle.glutes,
    'glute': BldrMuscle.glutes,
    'gluteus maximus': BldrMuscle.glutes,
    'quads': BldrMuscle.quads,
    'quadriceps': BldrMuscle.quads,
    'rectus femoris': BldrMuscle.quads,
    'hamstrings': BldrMuscle.hamstrings,
    'hamstring': BldrMuscle.hamstrings,
    'biceps femoris': BldrMuscle.hamstrings,
    'calves': BldrMuscle.calves,
    'calf': BldrMuscle.calves,
    'gastrocnemius': BldrMuscle.calves,
    'soleus': BldrMuscle.calves,
    'adductors': BldrMuscle.adductors,
    'inner thigh': BldrMuscle.adductors,
    'groin': BldrMuscle.adductors,
  };

  static BldrMuscle? fromString(String raw) => _map[_key(raw)];

  static List<BldrMuscle> fromList(Iterable<String> values) =>
      values.map(fromString).whereType<BldrMuscle>().toSet().toList();

  static List<BldrMuscle> fromDynamic(dynamic value) {
    if (value is String) return fromList([value]);
    if (value is Iterable) return fromList(value.whereType<String>());
    return const [];
  }

  /// Primários pesam 1 e secundários 0,55; o maior score vira 1.
  static Map<BldrMuscle, double> aggregate(
      Iterable<BldrMuscleContribution> exercises) {
    final scores = <BldrMuscle, double>{};
    for (final exercise in exercises) {
      for (final muscle in fromList(exercise.primary)) {
        scores.update(muscle, (value) => value + 1, ifAbsent: () => 1);
      }
      for (final muscle in fromList(exercise.secondary)) {
        scores.update(muscle, (value) => value + .55, ifAbsent: () => .55);
      }
    }
    if (scores.isEmpty) return const {};
    final maxScore = scores.values.reduce((a, b) => a > b ? a : b);
    return {
      for (final e in scores.entries) e.key: (e.value / maxScore).clamp(0, 1)
    };
  }

  static Map<BldrMuscle, double> aggregateTemplate(WorkoutTemplate template) {
    return aggregate(template.exercises.map((row) {
      final exercise = row.exercise;
      return BldrMuscleContribution(
        primary:
            exercise == null ? const [] : _strings(exercise.primaryMuscleGroup),
        secondary: exercise?.secondaryMuscleGroups ?? const [],
      );
    }));
  }

  /// Soma somente grandes grupos estruturais exclusivos de cada vista.
  /// Bíceps, tríceps, antebraços e panturrilhas continuam renderizados, mas são
  /// neutros para orientação. Empate e mapa vazio usam front como fallback.
  static BldrMuscleMapView dominantView(Map<BldrMuscle, double> muscles) {
    var frontScore = 0.0;
    var backScore = 0.0;
    for (final entry in muscles.entries) {
      if (_frontViewMuscles.contains(entry.key)) frontScore += entry.value;
      if (_backViewMuscles.contains(entry.key)) backScore += entry.value;
    }
    return backScore > frontScore
        ? BldrMuscleMapView.back
        : BldrMuscleMapView.front;
  }

  static ({double front, double back}) viewScores(
      Map<BldrMuscle, double> muscles) {
    var front = 0.0;
    var back = 0.0;
    for (final entry in muscles.entries) {
      if (_frontViewMuscles.contains(entry.key)) front += entry.value;
      if (_backViewMuscles.contains(entry.key)) back += entry.value;
    }
    return (front: front, back: back);
  }

  static BldrMuscleMapData mapDataForTemplate(WorkoutTemplate template) {
    final muscles = aggregateTemplate(template);
    return BldrMuscleMapData(
      muscles: muscles,
      view: dominantView(muscles),
    );
  }

  static Iterable<String> _strings(dynamic value) {
    if (value is String) return [value];
    if (value is Iterable) return value.map((e) => e.toString());
    return const [];
  }

  static String _key(String raw) => raw
      .trim()
      .toLowerCase()
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
}
