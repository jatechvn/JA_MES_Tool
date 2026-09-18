import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ja_mes_tool/modules/api_client.dart';
import 'package:ja_mes_tool/modules/logic.dart';
import 'package:ja_mes_tool/modules/ui/main_window.dart';
import 'package:ja_mes_tool/theme/theme_provider.dart';
import 'package:ja_mes_tool/widgets/glass_widgets.dart';

void main() {
  testWidgets(
    'SN queue list renders BounceMarqueeText for long SN and alternate SN without overflow',
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

      final logic = AppLogic(initialize: false, saveConfig: (_) async {});
      final theme = ThemeProvider(initialMode: 'light');

      const longSn = 'QPH3AMX072631V00162_VERY_LONG_SERIAL_NUMBER';
      const longAltSn = 'VN0NP0W07FVSG6830004A00_EXTRA_LONG_CUSTOMER_SN';
      const longStation = 'VERY_LONG_NEXT_STATION_ODTTEST_V001';

      logic.snList.add(longSn);
      logic.snMasterInfo[longSn] = SnMasterInfo.fromJson({
        'sn': longSn,
        'nextProcessName': longStation,
      });
      logic.results[longSn] = [
        TestRecord.fromJson({
          'sn': longSn,
          'customerSn': longAltSn,
          'processCode': 'FWTEST',
          'lineStationCode': 'FWTEST-A03T03',
          'result': 'PASS',
          'lastEditedDt': '2026-09-18 10:00:00',
        }),
      ];
      logic.processResults[longSn] = [];
      logic.wipResults[longSn] = [];
      logic.selectSn(longSn);
      logic.isConnectionValid = true;

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

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);

      // Verify BounceMarqueeText instances exist for longSn and longAltSn
      final marqueeFinder = find.byType(BounceMarqueeText);
      expect(marqueeFinder, findsAtLeastNWidgets(2));

      // Verify PillBadge with marquee exists for nextStation
      final pillBadgeFinder = find.byWidgetPredicate(
        (w) =>
            w is PillBadge &&
            w.label.contains(longStation) &&
            w.useMarquee == true,
      );
      expect(pillBadgeFinder, findsOneWidget);
    },
  );
}
