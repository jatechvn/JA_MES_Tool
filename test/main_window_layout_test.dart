import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ja_mes_tool/modules/api_client.dart';
import 'package:ja_mes_tool/modules/logic.dart';
import 'package:ja_mes_tool/modules/ui/main_window.dart';
import 'package:ja_mes_tool/theme/theme_provider.dart';

void main() {
  setUpAll(() async {
    if (Platform.environment['JA_UI_CAPTURE'] != '1') return;
    final font = File('C:/Windows/Fonts/segoeui.ttf');
    if (await font.exists()) {
      for (final family in ['UiVerification', 'JetBrains Mono']) {
        await (FontLoader(family)..addFont(
              Future.value(ByteData.sublistView(await font.readAsBytes())),
            ))
            .load();
      }
    }
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final mode in ['light', 'dark']) {
    testWidgets('restored main window layout $mode', (tester) async {
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
      final theme = ThemeProvider(initialMode: mode);
      logic.snList.add('DEMO-SN-001');
      logic.results['DEMO-SN-001'] = [
        TestRecord.fromJson({
          'sn': 'DEMO-SN-001',
          'internalSn': 'DEMO-INTERNAL',
          'processCode': 'FWTEST',
          'lineStationCode': 'FWTEST-A03T03',
          'result': 'PASS',
          'lastEditedDt': '2026-09-18 10:00:00',
          'woNo': 'DEMO-WO',
          'productNo': 'DEMO-PN',
        }),
      ];
      logic.processResults['DEMO-SN-001'] = [];
      logic.wipResults['DEMO-SN-001'] = [];
      logic.selectSn('DEMO-SN-001');
      logic.isConnectionValid = true;
      final key = GlobalKey();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: logic),
            ChangeNotifierProvider.value(value: theme),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: Platform.environment['JA_UI_CAPTURE'] == '1'
                  ? 'UiVerification'
                  : null,
              brightness: mode == 'dark' ? Brightness.dark : Brightness.light,
            ),
            home: RepaintBoundary(key: key, child: const MainWindow()),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      expect(find.text('JA'), findsOneWidget);
      expect(find.text('Terminal & Logs'), findsNothing);
      expect(find.byIcon(Icons.minimize_rounded), findsNothing);
      expect(find.byIcon(Icons.crop_square_rounded), findsNothing);
      if (Platform.environment['JA_UI_CAPTURE'] == '1') {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final dir = Directory('build/ui_verification')
            ..createSync(recursive: true);
          File(
            '${dir.path}/restored_$mode.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox.shrink());
      logic.dispose();
      theme.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('window_manager'),
            null,
          );
    });
  }
}
