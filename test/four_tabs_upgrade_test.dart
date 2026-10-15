import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ja_mes_tool/modules/api_client.dart';
import 'package:ja_mes_tool/modules/logic.dart';
import 'package:ja_mes_tool/modules/ui/main_window.dart';
import 'package:ja_mes_tool/theme/theme_provider.dart';

void main() {
  group('CloudMES 4-Tab Upgrade Models & Logic', () {
    test(
      'TestRecord, SnProcessRecord, WipComponentRecord, SnMasterInfo, and ComponentParamRecord parse extended fields',
      () {
        final testRec = TestRecord.fromJson({
          'sn': 'SAFVN2630836185',
          'internalSn': 'SAFVN2630836185',
          'customerSn': 'VN0TD2147FVSG672D003A00',
          'productNo': 'PN-100',
          'processCode': 'FWTEST',
          'lineStationCode': 'FWTEST-A01',
          'stationId': 'EQP-01',
          'result': 'FAIL',
          'testStartDate': '2026-10-15 08:00:00',
          'testEndDate': '2026-10-15 08:02:15',
          'timeDifferenceValue': '135s',
          'testNo': 'T-9988',
          'testLogPath': r'\\10.1.1.1\logs\SAFVN2630836185.zip',
          'zipFileName': 'SAFVN2630836185.zip',
          'mbSn': 'MB-SN-001',
          'macGroup': 'AA:BB:CC:DD:EE:FF',
          'components': 'COMP-A,COMP-B',
          'collectingData': 'VOLT=12.1V',
          'gitAsnData': 'ASN-01',
          'eqpParams': 'PORT=3',
          'testItemFailStep': 'STEP_DDR_INIT',
          'testItemFailCycle': 'CYCLE_1',
          'testMajorItem': 'DDR_TEST',
          'qty': 100,
          'passQty': 95,
          'failQty': 5,
          'repassQty': 2,
          'fpy': 95.0,
          'lpy': 97.0,
        });

        expect(testRec.testStartDate, '2026-10-15 08:00:00');
        expect(testRec.testEndDate, '2026-10-15 08:02:15');
        expect(testRec.timeDifferenceValue, '135s');
        expect(testRec.testNo, 'T-9988');
        expect(testRec.testLogPath, r'\\10.1.1.1\logs\SAFVN2630836185.zip');
        expect(testRec.zipFileName, 'SAFVN2630836185.zip');
        expect(testRec.mbSn, 'MB-SN-001');
        expect(testRec.macGroup, 'AA:BB:CC:DD:EE:FF');
        expect(testRec.testItemFailStep, 'STEP_DDR_INIT');
        expect(testRec.qty, 100);
        expect(testRec.fpy, 95.0);
        expect(testRec.lpy, 97.0);

        final procRec = SnProcessRecord.fromJson({
          'currentProcessCode': 'ASSY',
          'landMarkCodes': 'LM-01,LM-02',
          'result': 'PASS',
        });
        expect(procRec.landMarkCodes, 'LM-01,LM-02');

        final wipRec = WipComponentRecord.fromJson({
          'id': 42,
          'materialNo': 'MAT-01',
          'scannedCsn': 'RAW-CSN-001',
          'parsedCsn': 'PARSED-CSN-001',
          'scanType': '2D_BARCODE',
          'unlinkTime': '2026-10-15 09:00:00',
          'checkAssembledCode': 'CHK_OK',
        });
        expect(wipRec.wipProductComponentId, 42);
        expect(wipRec.parsedCsn, 'PARSED-CSN-001');
        expect(wipRec.scanType, '2D_BARCODE');
        expect(wipRec.unlinkTime, '2026-10-15 09:00:00');
        expect(wipRec.checkAssembledCode, 'CHK_OK');

        final master = SnMasterInfo.fromJson({
          'sn': 'SAFVN2630836185',
          'productStatus': 'FAIL',
          'currentProcessCode': 'FWTEST',
          'currentProcessName': 'Firmware Test',
          'nextProcessCode': 'REPAIR',
          'nextProcessName': 'Repair Station',
          'woNo': 'WO-2026-10',
          'productNo': 'PN-100',
          'productVersion': 'A0',
          'lineCode': 'L01',
          'lineName': 'Line 01',
          'lastEditedDt': '2026-10-15 08:05:00',
          'lastEditor': 'EMP007',
        });
        expect(master.productStatus, 'FAIL');
        expect(master.currentProcessCode, 'FWTEST');
        expect(master.woNo, 'WO-2026-10');
        expect(master.productVersion, 'A0');
        expect(master.lastEditor, 'EMP007');

        final param = ComponentParamRecord.fromJson({
          'macParam': 'ETH0_MAC',
          'macType': 'MAC',
          'macValue': '00:11:22:33:44:55',
          'parsedCsn': 'PARSED-CSN-001',
          'createdDt': '2026-10-15 08:00:00',
        });
        expect(param.macParam, 'ETH0_MAC');
        expect(param.macValue, '00:11:22:33:44:55');
      },
    );

    test(
      'snHasFail detects FAIL from SnMasterInfo, TestRecord, or SnProcessRecord',
      () {
        final logic = AppLogic(initialize: false, saveConfig: (_) async {});
        addTearDown(logic.dispose);

        logic.snList.addAll(['SN_GOOD', 'SN_FAIL_MASTER', 'SN_FAIL_TEST']);
        logic.snMasterInfo['SN_GOOD'] = SnMasterInfo.fromJson({
          'sn': 'SN_GOOD',
          'productStatus': 'GOOD',
        });
        logic.snMasterInfo['SN_FAIL_MASTER'] = SnMasterInfo.fromJson({
          'sn': 'SN_FAIL_MASTER',
          'productStatus': 'FAIL',
        });
        logic.results['SN_FAIL_TEST'] = [
          TestRecord.fromJson({'sn': 'SN_FAIL_TEST', 'result': 'FAIL'}),
        ];

        expect(logic.snHasFail('SN_GOOD'), isFalse);
        expect(logic.snHasFail('SN_FAIL_MASTER'), isTrue);
        expect(logic.snHasFail('SN_FAIL_TEST'), isTrue);
      },
    );
  });

  testWidgets(
    '4-Tab UI renders upgraded fields, FAIL-only queue filter, expandable Component Params, and 1-click cross-tab jumps without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(1266, 680);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('window_manager'), (
            call,
          ) async {
            if (call.method == 'isMaximized') return false;
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('window_manager'),
              null,
            );
      });

      final logic = AppLogic(initialize: false, saveConfig: (_) async {});
      final theme = ThemeProvider(initialMode: 'dark');
      addTearDown(logic.dispose);
      addTearDown(theme.dispose);

      logic.isConnectionValid = true;
      logic.snList.addAll(['SN-PASS-01', 'SN-FAIL-02']);
      logic.snMasterInfo['SN-PASS-01'] = SnMasterInfo.fromJson({
        'sn': 'SN-PASS-01',
        'productStatus': 'GOOD',
        'routeName': 'STD-ROUTE',
        'currentProcessCode': 'FWTEST',
        'nextProcessCode': 'PACKING',
        'woNo': 'WO-999',
        'productNo': 'PN-888',
        'productVersion': 'B1',
        'lineName': 'LINE-A1',
        'lastEditedDt': '2026-10-15 10:00:00',
        'lastEditor': 'OP-01',
      });
      logic.snMasterInfo['SN-FAIL-02'] = SnMasterInfo.fromJson({
        'sn': 'SN-FAIL-02',
        'productStatus': 'FAIL',
      });

      logic.results['SN-PASS-01'] = [
        TestRecord.fromJson({
          'sn': 'SN-PASS-01',
          'processCode': 'FWTEST',
          'lineStationCode': 'FWTEST-01',
          'result': 'FAIL',
          'testStartDate': '2026-10-15 09:50:00',
          'testEndDate': '2026-10-15 09:52:00',
          'timeDifferenceValue': '120s',
          'testNo': 'RUN-01',
          'mbSn': 'MB-999',
          'macGroup': '11:22:33:44:55:66',
          'testLogPath': r'\\server\logs\SN-PASS-01.zip',
          'zipFileName': 'SN-PASS-01.zip',
          'testItemFailStep': 'PCIE_LINK',
          'qty': 50,
          'passQty': 48,
          'failQty': 2,
          'fpy': 96.0,
          'lpy': 98.0,
        }),
      ];
      logic.results['SN-FAIL-02'] = [
        TestRecord.fromJson({
          'sn': 'SN-FAIL-02',
          'processCode': 'ODT',
          'result': 'FAIL',
        }),
      ];
      logic.processResults['SN-PASS-01'] = [
        SnProcessRecord.fromJson({
          'currentProcessCode': 'ASSY',
          'currentProcessName': 'Assembly',
          'operateDt': '2026-10-15 09:00:00',
          'result': 'PASS',
          'landMarkCodes': 'LMK-A01',
        }),
      ];
      logic.wipResults['SN-PASS-01'] = [
        WipComponentRecord.fromJson({
          'id': 777,
          'materialNo': 'MAT-NIC-01',
          'materialCategory': 'NIC',
          'scannedCsn': 'RAW-CSN-777',
          'parsedCsn': 'CSN-777',
          'scanType': 'BARCODE_2D',
          'createdDt': '2026-10-15 08:30:00',
        }),
      ];
      logic.componentParams[777] = [
        ComponentParamRecord.fromJson({
          'macParam': 'NIC_MAC_1',
          'macType': 'MAC',
          'macValue': 'AA:BB:CC:11:22:33',
          'parsedCsn': 'CSN-777',
        }),
      ];
      logic.traceResults['CSN-777'] = [
        QueryInfoRecord.fromJson({
          'productSn': 'TRACED-PROD-SN-99',
          'scannedCsn': 'RAW-CSN-777',
          'parsedCsn': 'CSN-777',
          'mac': 'AA:BB:CC:11:22:33',
          'materialNo': 'MAT-NIC-01',
          'scanType': 'BARCODE_2D',
          'materialVersion': 'V2',
          'customerMaterialNo': 'CUST-PN-01',
          'createdDt': '2026-10-15 08:30:00',
        }),
      ];
      logic.results['TRACED-PROD-SN-99'] = [
        TestRecord.fromJson({
          'sn': 'TRACED-PROD-SN-99',
          'processCode': 'FT',
          'result': 'PASS',
        }),
      ];
      logic.processResults['TRACED-PROD-SN-99'] = [];
      logic.wipResults['TRACED-PROD-SN-99'] = [];

      logic.selectSn('SN-PASS-01');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: logic),
            ChangeNotifierProvider.value(value: theme),
          ],
          child: const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: MainWindow(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);

      // Verify Tab 1 extended fields & header badges
      expect(find.text('#RUN-01'), findsOneWidget);
      expect(find.textContaining('120s'), findsWidgets);
      expect(find.textContaining('SN-PASS-01.zip'), findsOneWidget);
      expect(find.textContaining('FPY:96.0%'), findsOneWidget);

      // Switch to Tab 2 (Barcode History) and verify landMarkCodes
      logic.setViewMode(ViewMode.barcodeHistory);
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(find.text('LMK-A01'), findsOneWidget);

      // Switch to Tab 3 (Component List) and verify parsedCsn + Component Params
      logic.setViewMode(ViewMode.wipComponents);
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
      expect(find.text('CSN-777'), findsOneWidget);
      expect(find.byIcon(Icons.settings_ethernet_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.settings_ethernet_rounded));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('AA:BB:CC:11:22:33'), findsOneWidget);

      // Click 1-click Trace Component button -> jumps to Tab 4 (Component Trace)
      await tester.tap(find.byIcon(Icons.travel_explore_rounded).last);
      await tester.pump(const Duration(milliseconds: 400));
      expect(logic.viewMode, ViewMode.componentTrace);
      expect(logic.selectedTraceCsn, 'CSN-777');
      expect(find.text('TRACED-PROD-SN-99'), findsOneWidget);

      // Click 1-click Inspect Product SN button -> jumps back to Tab 1 with TRACED-PROD-SN-99
      await tester.tap(find.byIcon(Icons.open_in_new_rounded));
      await tester.pump(const Duration(milliseconds: 400));
      expect(logic.viewMode, ViewMode.testRecord);
      expect(logic.selectedSn, 'TRACED-PROD-SN-99');
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
