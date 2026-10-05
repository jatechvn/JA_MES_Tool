import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ja_mes_tool/modules/api_client.dart';
import 'package:ja_mes_tool/modules/logic.dart';
import 'package:ja_mes_tool/modules/translations.dart';
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
      addTearDown(logic.dispose);
      addTearDown(theme.dispose);
      String? copiedSn;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              copiedSn = (call.arguments as Map)['text'] as String;
            }
            return null;
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('window_manager'),
              null,
            );
      });

      const longSn = 'QPH3AMX072631V00162_VERY_LONG_SERIAL_NUMBER';
      const longAltSn = 'VN0NP0W07FVSG6830004A00_EXTRA_LONG_CUSTOMER_SN';
      const longStation = 'VERY_LONG_NEXT_STATION_ODTTEST_V001';

      logic.snList.add(longSn);
      logic.snList.add('NEW_LOADING_SN');
      logic.loadingStatus['NEW_LOADING_SN'] = true;
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
      expect(find.byIcon(Icons.copy_rounded), findsNWidgets(2));
      expect(find.byIcon(Icons.refresh_rounded), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('copy_sn_NEW_LOADING_SN')));
      await tester.pump();
      expect(copiedSn, 'NEW_LOADING_SN');
      expect(logic.selectedSn, longSn);
      await tester.tap(find.byKey(const ValueKey('copy_sn_$longSn')));
      await tester.pump();
      expect(copiedSn, longSn);
      expect(logic.selectedSn, longSn);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  test('copy SN tooltip is localized', () {
    for (final lang in ['en', 'vn', 'cn']) {
      expect(Translations.get('copy_sn', lang), isNot('copy_sn'));
    }
  });
}
