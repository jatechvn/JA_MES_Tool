import 'package:flutter_test/flutter_test.dart';
import 'package:ja_mes_tool/modules/api_client.dart';
import 'package:ja_mes_tool/modules/logic.dart';
import 'package:ja_mes_tool/modules/translations.dart';

void main() {
  group('Barcode History and WIP fields verification', () {
    test('SnProcessRecord parses all newly added fields from MES API JSON', () {
      final json = {
        'productSn': 'SAFVN263683630F',
        'internalSn': 'SAFVN263683630F',
        'customerSn': 'FVB060001M',
        'currentProcessCode': 'FWTEST',
        'currentProcessName': '固件测试',
        'lineStation': 'FWTEST01',
        'lineCode': 'A03-4F-T03',
        'lineName': 'A03-4F-T03',
        'result': 'PASS',
        'operateDt': '2026-03-05 14:11:47',
        'woNo': 'W0123456',
        'planNo': '000400003692',
        'productNo': '600-00123',
        'productVersion': 'D',
        'operatorName': 'V123456',
        'eqpId': 'FWTEST-A03T03',
        'errorCode': 'ERR01',
        'testResultMsg': 'Test fail at step 3',
        'remark': '条码退站：From FWTEST To TPO-IN',
        'firstFlag': 1,
        'packId': 999,
      };

      final record = SnProcessRecord.fromJson(json);

      expect(record.productSn, 'SAFVN263683630F');
      expect(record.internalSn, 'SAFVN263683630F');
      expect(record.customerSn, 'FVB060001M');
      expect(record.lineCode, 'A03-4F-T03');
      expect(record.lineName, 'A03-4F-T03');
      expect(record.eqpId, 'FWTEST-A03T03');
      expect(record.productVersion, 'D');
      expect(record.planNo, '000400003692');
      expect(record.remark, '条码退站：From FWTEST To TPO-IN');
      expect(record.firstFlag, 1);
      expect(record.packId, 999);
      expect(record.operatorName, 'V123456');
    });

    test('WipComponentRecord parses location field from MES API JSON', () {
      final json = {
        'materialNo': '100-0001',
        'materialName': 'Resistor',
        'materialCategory': 'SMD',
        'scannedCsn': 'CSN12345',
        'mfgName': 'Murata',
        'mfgPn': 'MUR-01',
        'dateCode': '2603',
        'pkgId': 'PKG1',
        'installedQty': '2',
        'stationCode': 'ST01',
        'processCode': 'SMT',
        'creator': 'User1',
        'createdDt': '2026-03-05 10:00:00',
        'location': 'HS1,HS2',
      };

      final record = WipComponentRecord.fromJson(json);

      expect(record.materialNo, '100-0001');
      expect(record.materialName, 'Resistor');
      expect(record.location, 'HS1,HS2');
    });

    test('csvField preserves commas, quotes, line breaks and empty cells', () {
      expect(csvField('HS1,HS2'), '"HS1,HS2"');
      expect(csvField('say "ok"'), '"say ""ok"""');
      expect(csvField('line 1\nline 2'), '"line 1\nline 2"');
      expect(csvField(''), isEmpty);
    });

    test(
      'Translations dictionary contains all required keys for all languages',
      () {
        final keys = [
          'equipment_no',
          'line',
          'remark',
          'plan_no',
          'location',
          'version',
        ];
        for (final lang in ['en', 'vn', 'cn']) {
          for (final key in keys) {
            final translated = Translations.get(key, lang);
            expect(
              translated,
              isNotEmpty,
              reason: 'Key "$key" should have a translation in "$lang"',
            );
            expect(
              translated,
              isNot(equals(key)),
              reason: 'Key "$key" was not found in dictionary for "$lang"',
            );
          }
        }
      },
    );
  });
}
