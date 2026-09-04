import 'package:flutter_test/flutter_test.dart';
import 'package:ja_mes_tool/modules/constants.dart';
import 'package:ja_mes_tool/modules/logic.dart';
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

  group('Initial Language Tests', () {
    test('uses Windows locale when no language is configured', () {
      expect(defaultLanguageForPlatformLocale('vi-VN'), equals('vn'));
      expect(defaultLanguageForPlatformLocale('vi_VN'), equals('vn'));
      expect(defaultLanguageForPlatformLocale('zh-CN'), equals('cn'));
      expect(defaultLanguageForPlatformLocale('en-US'), equals('en'));

      expect(
        initialLanguage(
          configuredLang: 'en',
          hasConfiguredLanguage: false,
          platformLocaleName: 'vi-VN',
        ),
        equals('vn'),
      );
    });

    test('keeps saved app language instead of Windows locale', () {
      expect(
        initialLanguage(
          configuredLang: 'en',
          hasConfiguredLanguage: true,
          platformLocaleName: 'vi-VN',
        ),
        equals('en'),
      );
    });
  });

  group('Test Record fallback Tests', () {
    test('falls back to Barcode History only for missing Test Record data', () {
      expect(shouldFallbackToBarcodeHistory(recordsAreEmpty: true), isTrue);
      expect(
        shouldFallbackToBarcodeHistory(
          recordsAreEmpty: false,
          error: 'API Error: No records found',
        ),
        isTrue,
      );
      expect(
        shouldFallbackToBarcodeHistory(
          recordsAreEmpty: false,
          error: 'Token expired or unauthorized (401)',
        ),
        isFalse,
      );
      expect(shouldFallbackToBarcodeHistory(recordsAreEmpty: false), isFalse);
    });

    test(
      'auto-switches only for fresh load, SN search, or refresh fallback',
      () {
        expect(
          shouldAutoSwitchToBarcodeHistory(
            selectedSn: 'SN001',
            candidateSn: 'SN001',
            viewMode: ViewMode.testRecord,
            hasNoTestRecordData: true,
            fallbackAllowed: false,
          ),
          isFalse,
        );

        expect(
          shouldAutoSwitchToBarcodeHistory(
            selectedSn: 'SN001',
            candidateSn: 'SN001',
            viewMode: ViewMode.testRecord,
            hasNoTestRecordData: true,
            fallbackAllowed: true,
          ),
          isTrue,
        );

        expect(
          shouldAutoSwitchToBarcodeHistory(
            selectedSn: 'SN001',
            candidateSn: 'SN001',
            viewMode: ViewMode.wipComponents,
            hasNoTestRecordData: true,
            fallbackAllowed: true,
          ),
          isFalse,
        );
      },
    );
  });
}
