import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const _key = 'app_locale';
  static const supportedLanguageCodes = {'pt', 'en', 'it'};
  static const selectableLanguageCodes = {'pt', 'en'};

  Locale _locale = const Locale('pt');
  Locale get locale => _locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null && selectableLanguageCodes.contains(code)) {
      _locale = Locale(code);
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (!selectableLanguageCodes.contains(locale.languageCode)) return;
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }

  Future<void> reset() async {
    await setLocale(const Locale('pt'));
  }
}
