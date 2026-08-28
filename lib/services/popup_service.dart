import 'package:shared_preferences/shared_preferences.dart';

class PopupService {
  PopupService._();

  static const _notifGranted = 'popup_notif_granted';
  static const _notifCount = 'popup_notif_count';
  static const _notifLastShown = 'popup_notif_last_shown';

  static const _reviewRated = 'popup_review_rated';
  static const _reviewCount = 'popup_review_count';
  static const _reviewLastShown = 'popup_review_last_shown';

  static const _anyLastShown = 'popup_any_last_shown';

  static Future<bool> shouldShowNotificationPopup({
    required DateTime userCreatedAt,
    required bool osPermissionGranted,
  }) async {
    if (osPermissionGranted) return false;

    final daysSinceCreation = DateTime.now().difference(userCreatedAt).inDays;
    if (daysSinceCreation < 3) return false;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_notifGranted) ?? false) return false;

    final count = prefs.getInt(_notifCount) ?? 0;
    if (count >= 3) return false;

    if (_anyPopupShownToday(prefs)) return false;

    final lastShownStr = prefs.getString(_notifLastShown);
    if (lastShownStr != null) {
      final lastShown = DateTime.parse(lastShownStr);
      final now = DateTime.now();
      if (_isSameDay(lastShown, now)) return false;
      if (count > 0 && now.difference(lastShown).inDays < 7) return false;
    }

    return true;
  }

  static Future<bool> shouldShowReviewPopup() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_reviewRated) ?? false) return false;

    final count = prefs.getInt(_reviewCount) ?? 0;
    if (count >= 2) return false;

    if (_anyPopupShownToday(prefs)) return false;

    final lastShownStr = prefs.getString(_reviewLastShown);
    if (lastShownStr != null) {
      final lastShown = DateTime.parse(lastShownStr);
      if (count > 0 && DateTime.now().difference(lastShown).inDays < 15) {
        return false;
      }
    }

    return true;
  }

  static Future<void> markNotificationGranted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifGranted, true);
    await _markAnyShownToday(prefs);
  }

  static Future<void> markNotificationDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_notifCount) ?? 0) + 1;
    await prefs.setInt(_notifCount, count);
    await prefs.setString(_notifLastShown, DateTime.now().toIso8601String());
    await _markAnyShownToday(prefs);
  }

  static Future<void> markReviewRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reviewRated, true);
    await _markAnyShownToday(prefs);
  }

  static Future<void> markReviewDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_reviewCount) ?? 0) + 1;
    await prefs.setInt(_reviewCount, count);
    await prefs.setString(_reviewLastShown, DateTime.now().toIso8601String());
    await _markAnyShownToday(prefs);
  }

  static bool _anyPopupShownToday(SharedPreferences prefs) {
    final lastStr = prefs.getString(_anyLastShown);
    if (lastStr == null) return false;
    return _isSameDay(DateTime.parse(lastStr), DateTime.now());
  }

  static Future<void> _markAnyShownToday(SharedPreferences prefs) async {
    await prefs.setString(_anyLastShown, DateTime.now().toIso8601String());
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
