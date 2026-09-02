String resolveExerciseDisplayName({
  String? internalName,
  String? exerciseDbName,
  String fallback = 'Exercício',
}) {
  final localized = internalName?.trim();
  if (localized != null && localized.isNotEmpty) return localized;

  final external = exerciseDbName?.trim();
  if (external != null && external.isNotEmpty) return external;

  return fallback;
}
