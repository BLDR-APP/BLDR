String resolveActiveWorkoutName({
  String? templateName,
  required String? snapshotName,
}) {
  final current = templateName?.trim();
  if (current != null && current.isNotEmpty) return current;
  final snapshot = snapshotName?.trim();
  return snapshot == null || snapshot.isEmpty ? 'Treino' : snapshot;
}
