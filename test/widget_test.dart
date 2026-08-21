import 'package:flutter_test/flutter_test.dart';
import 'package:ja_mes_tool/modules/constants.dart';
import 'package:ja_mes_tool/modules/translations.dart';

void main() {
  group('App Info & Constants Tests', () {
    test('appVersion is defined and follows semantic versioning', () {
      expect(appVersion, matches(RegExp(r'^\d+\.\d+\.\d+$')));
      expect(appName, equals('JA MES Tool'));
    });
  });

  group('Translations Tests', () {
    test('returns correct translation for key across supported languages', () {
      expect(Translations.get('settings', 'en'), equals('Settings'));
      expect(Translations.get('settings', 'vn'), equals('Cài đặt'));
      expect(Translations.get('settings', 'cn'), equals('设置'));
    });

    test('returns key or fallback when key is not found', () {
      expect(
        Translations.get('non_existing_key', 'en'),
        equals('non_existing_key'),
      );
    });

    test('tab titles exist in all languages', () {
      for (final lang in ['en', 'vn', 'cn']) {
        expect(Translations.get('tab_test_record', lang), isNotEmpty);
        expect(Translations.get('tab_barcode_history', lang), isNotEmpty);
        expect(Translations.get('tab_wip_components', lang), isNotEmpty);
      }
    });
  });
}
