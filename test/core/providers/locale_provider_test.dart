import 'package:bldr_fitness/core/providers/locale_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocaleProvider', () {
    test('uses Portuguese when Italian is persisted from an earlier build',
        () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'it'});
      final provider = LocaleProvider();

      await provider.load();

      expect(provider.locale, const Locale('pt'));
    });

    test('does not persist Italian while it is temporarily unavailable',
        () async {
      SharedPreferences.setMockInitialValues({});
      final provider = LocaleProvider();

      await provider.setLocale(const Locale('it'));

      final preferences = await SharedPreferences.getInstance();
      expect(provider.locale, const Locale('pt'));
      expect(preferences.getString('app_locale'), isNull);
    });

    test('keeps Portuguese and English selectable', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = LocaleProvider();

      await provider.setLocale(const Locale('en'));

      final preferences = await SharedPreferences.getInstance();
      expect(provider.locale, const Locale('en'));
      expect(preferences.getString('app_locale'), 'en');
    });
  });
}
