import 'package:flutter_test/flutter_test.dart';
import 'package:ja_mes_tool/modules/api_client.dart';
import 'package:ja_mes_tool/modules/logic.dart';

void main() {
  const internal = 'SAFVN2630836185';
  const customer = 'VN0TD2147FVSG672D003A00';

  for (final barcodeOnly in [false, true]) {
    group(barcodeOnly ? 'Barcode History aliases' : 'Test Record aliases', () {
      late AppLogic logic;
      setUp(() {
        logic = AppLogic(initialize: false, saveConfig: (_) async {});
      });
      tearDown(() => logic.dispose());

      void records(String input, String internalSn, String customerSn) {
        final json = {'internalSn': internalSn, 'customerSn': customerSn};
        if (barcodeOnly) {
          logic.processResults[input] = [SnProcessRecord.fromJson(json)];
        } else {
          logic.results[input] = [TestRecord.fromJson(json)];
        }
      }

      for (final input in ['DHL2700003', 'OTHER-PRODUCT-ID', customer]) {
        test('$input shows internal SN rather than customer SN', () {
          records(input, internal, customer);
          expect(logic.alternateSnFor(input), internal);
        });
      }

      test('internal input retains customer counterpart', () {
        records(internal, internal, 'DHL2700003');
        expect(logic.alternateSnFor(internal), 'DHL2700003');
      });
      test('comparison ignores casing and surrounding whitespace', () {
        records(internal.toLowerCase(), ' $internal ', ' $customer ');
        expect(logic.alternateSnFor(internal.toLowerCase()), customer);
      });
      test('missing internal falls back to customer', () {
        records('DHL2700003', '', customer);
        expect(logic.alternateSnFor('DHL2700003'), customer);
      });
      test('missing customer still shows internal for product input', () {
        records('DHL2700003', internal, '');
        expect(logic.alternateSnFor('DHL2700003'), internal);
      });
      test('empty or duplicate aliases are not displayed', () {
        records('DHL2700003', ' dhl2700003 ', 'DHL2700003');
        expect(logic.alternateSnFor('DHL2700003'), isNull);
        records('DHL2700003', '', '  ');
        expect(logic.alternateSnFor('DHL2700003'), isNull);
      });
    });
  }

  test('Barcode History supplies alias when test records have none', () {
    final logic = AppLogic(initialize: false, saveConfig: (_) async {});
    addTearDown(logic.dispose);
    logic.results['DHL2700003'] = [TestRecord.fromJson({})];
    logic.processResults['DHL2700003'] = [
      SnProcessRecord.fromJson({
        'internalSn': internal,
        'customerSn': customer,
      }),
    ];
    expect(logic.alternateSnFor('DHL2700003'), internal);
    expect(logic.alternateSnFor('UNKNOWN'), isNull);
  });
}
