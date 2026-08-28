/// Single source of truth for the current onboarding version.
///
/// Bump this string whenever the onboarding flow changes in a way that
/// requires existing users to redo it. Use a major.minor format (e.g. "3.0",
/// "4.0"). The gate logic in [LoginScreen] redirects any user whose saved
/// version parses to a value *lower* than this number.
const String kCurrentOnboardingVersion = '3.0';

/// Returns true if the user should be sent back through onboarding.
///
/// Redirect cases:
///   - null / empty  → first-time user, no version saved
///   - "1.0", "2.0" → older flow, must redo
///   - "3.0"         → up-to-date, allow in
///   - "4.0"+ (future) → forward-compatible, allow in
bool shouldRedoOnboarding(String? userOnboardingVersion) {
  if (userOnboardingVersion == null || userOnboardingVersion.isEmpty) return true;
  final saved = double.tryParse(userOnboardingVersion);
  final current = double.tryParse(kCurrentOnboardingVersion);
  if (saved == null || current == null) return true;
  return saved < current;
}
