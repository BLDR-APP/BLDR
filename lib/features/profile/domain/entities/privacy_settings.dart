/// Preferências de privacidade do usuário no BLDR.
class PrivacySettings {
  final String? displayName;
  final String photoVisibility; // 'public' | 'squad'
  final bool feedVisible;
  final bool reactionsEnabled;
  final bool rankingVisible;

  const PrivacySettings({
    this.displayName,
    this.photoVisibility = 'public',
    this.feedVisible = true,
    this.reactionsEnabled = true,
    this.rankingVisible = true,
  });

  static const defaults = PrivacySettings();
}
