import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_mes_tool/modules/logic.dart';
import 'package:ja_mes_tool/modules/translations.dart';
import 'package:ja_mes_tool/modules/ui/dialogs/settings_dialog.dart';
import 'package:ja_mes_tool/theme/theme_provider.dart';

import 'package:provider/provider.dart';

void main() {
  testWidgets('Settings dialog renders 3 consolidated tabs and navigates cleanly', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final logic = AppLogic(initialize: false, saveConfig: (_) async {});
    final theme = ThemeProvider(initialMode: 'light');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppLogic>.value(value: logic),
          ChangeNotifierProvider<ThemeProvider>.value(value: theme),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => showAppSettingsDialog(context, logic, theme),
                  child: const Text('Open Settings'),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Open settings dialog
    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();

    // Verify dialog title
    expect(find.text(Translations.get('settings', logic.lang)), findsOneWidget);

    // Verify 3 tabs are present
    expect(find.text(Translations.get('tab_mes_api', logic.lang)), findsOneWidget);
    expect(find.text(Translations.get('tab_display_glass', logic.lang)), findsOneWidget);
    expect(find.text(Translations.get('tab_about_updates', logic.lang)), findsOneWidget);

    // Tab 0: MES API & CDP content
    expect(find.text(Translations.get('cdp_sync_title', logic.lang)), findsOneWidget);

    // Switch to Tab 1: Display & Glassmorphism
    await tester.tap(find.text(Translations.get('tab_display_glass', logic.lang)));
    await tester.pumpAndSettle();

    expect(find.text(Translations.get('language', logic.lang)), findsOneWidget);
    expect(find.text('Tiếng Việt'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('中文'), findsOneWidget);
    expect(find.text(Translations.get('perf_tooltip', logic.lang)), findsOneWidget);

    // Scroll down to reveal Glassmorphism Live-Tuning card
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pumpAndSettle();

    expect(find.text(Translations.get('glass_settings_title', logic.lang)), findsOneWidget);
    expect(find.text(Translations.get('card_blur_label', logic.lang)), findsOneWidget);

    // Switch to Tab 2: About & Updates
    await tester.tap(find.text(Translations.get('tab_about_updates', logic.lang)));
    await tester.pumpAndSettle();

    expect(find.text(Translations.get('check_updates_now', logic.lang)), findsOneWidget);
    expect(find.text(Translations.get('server_path', logic.lang)), findsOneWidget);

    // Scroll down to reveal System Specs card
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pumpAndSettle();

    expect(find.text('Engine'), findsOneWidget);
    expect(find.text('Architecture'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text(Translations.get('cancel', logic.lang)));
    await tester.pumpAndSettle();

    expect(find.text(Translations.get('settings', logic.lang)), findsNothing);
  });
}
