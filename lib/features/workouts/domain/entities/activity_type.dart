import 'package:flutter/material.dart';

enum ActivityType {
  musculacao,
  corrida,
  hiit,
  yoga,
  pilates,
  natacao,
  ciclismo,
  esporte,
  outro;

  static ActivityType fromString(String? value) {
    final v = value?.toLowerCase().trim();
    return ActivityType.values.firstWhere(
      (e) => e.name == v,
      orElse: () => switch (v) {
        'strength' => ActivityType.musculacao,
        'run' || 'running' => ActivityType.corrida,
        'sport' => ActivityType.esporte,
        _ => ActivityType.musculacao,
      },
    );
  }

  IconData get icon => switch (this) {
        ActivityType.musculacao => Icons.fitness_center,
        ActivityType.corrida => Icons.directions_run,
        ActivityType.hiit => Icons.flash_on,
        ActivityType.yoga => Icons.self_improvement,
        ActivityType.pilates => Icons.accessibility_new,
        ActivityType.natacao => Icons.pool,
        ActivityType.ciclismo => Icons.directions_bike,
        ActivityType.esporte => Icons.sports,
        ActivityType.outro => Icons.sports_gymnastics,
      };

  String get label => switch (this) {
        ActivityType.musculacao => 'Musculação',
        ActivityType.corrida => 'Corrida',
        ActivityType.hiit => 'HIIT',
        ActivityType.yoga => 'Yoga',
        ActivityType.pilates => 'Pilates',
        ActivityType.natacao => 'Natação',
        ActivityType.ciclismo => 'Ciclismo',
        ActivityType.esporte => 'Esporte',
        ActivityType.outro => 'Outro',
      };

  String metricLabel(int? durationMinutes, double? distanceKm) =>
      switch (this) {
        ActivityType.corrida || ActivityType.ciclismo => distanceKm != null
            ? '${distanceKm.toStringAsFixed(1)} km'
            : '${durationMinutes ?? 0} min',
        _ => '${durationMinutes ?? 0} min',
      };
}
