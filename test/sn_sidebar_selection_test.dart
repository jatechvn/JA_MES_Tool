import 'dart:ui' show PointerDeviceKind;
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
  for (final mode in ['light', 'dark']) {
    for (final selection in ['drag', 'double-click']) {
      testWidgets(
        '$mode $selection copies the alternate SN from rows 2 to 4',
        (tester) async {
          tester.view.physicalSize = const Size(1266, 713);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final logic = AppLogic(initialize: false, saveConfig: (_) async {});
          final theme = ThemeProvider(initialMode: mode);
          addTearDown(logic.dispose);
          addTearDown(theme.dispose);
          String? copied;
          final messenger =
              TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
          messenger.setMockMethodCallHandler(
            const MethodChannel('window_manager'),
            (call) async => call.method == 'isMaximized' ? false : null,
          );
          messenger.setMockMethodCallHandler(SystemChannels.platform, (
            call,
          ) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String;
            }
            if (call.method == 'Clipboard.hasStrings') return {'value': false};
            return null;
          });
          addTearDown(() {
            messenger.setMockMethodCallHandler(
              const MethodChannel('window_manager'),
              null,
            );
            messenger.setMockMethodCallHandler(SystemChannels.platform, null);
          });
          for (final index in [4, 3, 2, 1]) {
            final sn = 'SN000$index';
            logic.snList.add(sn);
            logic.results[sn] = [
              TestRecord.fromJson({
                'sn': sn,
                'internalSn': 'ALT000$index',
                'result': 'PASS',
              }),
            ];
            logic.processResults[sn] = [];
            logic.wipResults[sn] = [];
          }
          logic.selectSn('SN0001');
          logic.isConnectionValid = true;
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: logic),
                ChangeNotifierProvider.value(value: theme),
              ],
              child: const MaterialApp(home: MainWindow()),
            ),
          );
          await tester.pump(const Duration(seconds: 1));
          for (final index in [2, 3, 4]) {
            final sn = 'SN000$index';
            final alternate = 'ALT000$index';
            final mainText = find.byWidgetPredicate(
              (w) => w is BounceMarqueeText && w.text == sn,
            );
            await tester.tap(mainText);
            await tester.pump(const Duration(milliseconds: 400));
            expect(logic.selectedSn, sn);
            logic.selectSn('SN0001');
            await tester.pump(const Duration(milliseconds: 400));
            final alternateText = find.byWidgetPredicate(
              (w) => w is BounceMarqueeText && w.text == alternate,
            );
            final rect = tester.getRect(
              find.descendant(
                of: alternateText,
                matching: find.text(alternate),
              ),
            );
            copied = null;
            if (selection == 'drag') {
              final gesture = await tester.startGesture(
                rect.centerLeft + const Offset(1, 0),
                kind: PointerDeviceKind.mouse,
              );
              await gesture.moveTo(rect.centerRight - const Offset(1, 0));
              await gesture.up();
            } else {
              await tester.tapAt(rect.center, kind: PointerDeviceKind.mouse);
              await tester.pump(const Duration(milliseconds: 60));
              await tester.tapAt(rect.center, kind: PointerDeviceKind.mouse);
            }
            await tester.pump(const Duration(milliseconds: 60));
            // Async data notifications must not move/reset the selected text.
            logic.notifyListeners();
            await tester.pump(const Duration(milliseconds: 400));
            await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
            await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
            await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
            await tester.pump();
            expect(
              copied,
              alternate,
              reason: 'Copy must use row $index, not the first row',
            );
            expect(logic.selectedSn, sn);
            await tester.tap(find.byKey(const ValueKey('copy_sn_SN0001')));
            await tester.pump();
            expect(copied, 'SN0001');
            expect(
              logic.selectedSn,
              sn,
              reason: 'Copy icon must not select another row',
            );
          }
          expect(logic.snList, ['SN0004', 'SN0003', 'SN0002', 'SN0001']);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
        variant: TargetPlatformVariant.only(TargetPlatform.windows),
      );
    }
  }
}
