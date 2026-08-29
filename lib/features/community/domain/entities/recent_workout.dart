class RecentWorkout {
  final String id;
  final String name;
  final String source; // 'free' | 'club'
  final DateTime? completedAt;
  final double? volumeKg;
  final int? durationSeconds;
  final List<String> muscleGroups;

  const RecentWorkout({
    required this.id,
    required this.name,
    required this.source,
    this.completedAt,
    this.volumeKg,
    this.durationSeconds,
    this.muscleGroups = const [],
  });

  String get dateLabel {
    if (completedAt == null) return '';
    final d = completedAt!.toLocal();
    return '${d.day}/${d.month.toString().padLeft(2, '0')} · treino';
  }
}
