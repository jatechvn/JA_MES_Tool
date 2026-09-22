import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_mes_tool/modules/logic.dart';
import 'package:ja_mes_tool/modules/translations.dart';
import 'package:ja_mes_tool/modules/ui/dialogs/settings_dialog.dart';
import 'package:ja_mes_tool/theme/theme_provider.dart';

import 'package:provider/provider.dart';

void main() {
  test('Settings localization entries exist in every supported language', () {
    const keys = [
      'perf_auto_title',
      'perf_auto_desc',
      'tier_ultra_desc',
      'tier_balanced_desc',
      'tier_lite_desc',
      'hardware_tier_ultra',
      'hardware_tier_balanced',
      'hardware_tier_lite',
      'connection_failed',
      'build_label',
      'system_engine',
      'system_architecture',
      'system_cdp_interceptor',
      'system_hardware_profile',
      'system_license',
      'hardware_profile_value',
      'open_logs_folder',
    ];

    for (final lang in ['en', 'vn', 'cn']) {
      for (final key in keys) {
        expect(Translations.get(key, lang), isNot(equals(key)));
      }
    }
  });

  testWidgets(
    'Settings dialog renders 3 consolidated tabs and navigates cleanly',
    (tester) async {
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
                    onPressed: () =>
                        showAppSettingsDialog(context, logic, theme),
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
      expect(
        find.text(Translations.get('settings', logic.lang)),
        findsOneWidget,
      );

      // Verify 3 tabs are present
      expect(
        find.text(Translations.get('tab_mes_api', logic.lang)),
        findsOneWidget,
      );
      expect(
        find.text(Translations.get('tab_display_glass', logic.lang)),
        findsOneWidget,
      );
      expect(
        find.text(Translations.get('tab_about_updates', logic.lang)),
        findsOneWidget,
      );

      // Tab 0: MES API & CDP content
      expect(
        find.text(Translations.get('cdp_sync_title', logic.lang)),
        findsOneWidget,
      );

      // Switch to Tab 1: Display & Glassmorphism
      await tester.tap(
        find.text(Translations.get('tab_display_glass', logic.lang)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(Translations.get('language', logic.lang)),
        findsOneWidget,
      );
      expect(find.text('Tiếng Việt'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('中文'), findsOneWidget);
      expect(
        find.text(Translations.get('perf_tooltip', logic.lang)),
        findsOneWidget,
      );
      await tester.tap(find.text('中文'));
      await tester.pumpAndSettle();

      expect(logic.lang, 'cn');
      expect(
        find.text(Translations.get('tier_ultra_desc', logic.lang)),
        findsOneWidget,
      );

      // Scroll down to reveal Glassmorphism Live-Tuning card
      await tester.drag(find.byType(ListView), const Offset(0, -350));
      await tester.pumpAndSettle();

      expect(
        find.text(Translations.get('glass_settings_title', logic.lang)),
        findsOneWidget,
      );
      expect(
        find.text(Translations.get('card_blur_label', logic.lang)),
        findsOneWidget,
      );

      // Switch to Tab 2: About & Updates
      await tester.tap(
        find.text(Translations.get('tab_about_updates', logic.lang)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(Translations.get('check_updates_now', logic.lang)),
        findsOneWidget,
      );
      expect(
        find.text(Translations.get('server_path', logic.lang)),
        findsOneWidget,
      );
      expect(
        find.text(Translations.get('check_interval', logic.lang)),
        findsOneWidget,
      );
      expect(
        find.text(Translations.get('interval_startup', logic.lang)),
        findsOneWidget,
      );
      expect(
        find.text(Translations.get('interval_daily', logic.lang)),
        findsOneWidget,
      );
      expect(
        find.text(Translations.get('interval_weekly', logic.lang)),
        findsOneWidget,
      );
      expect(
        find.text(Translations.get('interval_disabled', logic.lang)),
        findsOneWidget,
      );

      // Tap quick interval button
      await tester.tap(
        find.text(Translations.get('interval_daily', logic.lang)),
      );
      await tester.pumpAndSettle();

      // Scroll down to reveal System Specs card
      await tester.drag(find.byType(ListView), const Offset(0, -350));
      await tester.pumpAndSettle();

      expect(
        find.text(Translations.get('system_engine', logic.lang)),
        findsOneWidget,
      );
      expect(
        find.text(Translations.get('system_architecture', logic.lang)),
        findsOneWidget,
      );

      // Close dialog
      await tester.tap(find.text(Translations.get('cancel', logic.lang)));
      await tester.pumpAndSettle();

      expect(find.text(Translations.get('settings', logic.lang)), findsNothing);
    },
  );

  testWidgets('Selecting a graphic tier refreshes its live glass values', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final logic = AppLogic(initialize: false, saveConfig: (_) async {});
    final theme = ThemeProvider(initialMode: 'light');
    theme.setLiveGlassmorphism(
      cardBlur: 7,
      cardOpacity: 0.4,
      dialogBlur: 9,
      dialogOpacity: 0.8,
      dropdownBlur: 11,
      dropdownOpacity: 0.7,
    );

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

    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(Translations.get('tab_display_glass', logic.lang)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(Translations.get('tier_balanced', logic.lang)));
    await tester.pumpAndSettle();

    expect(theme.perfMode, PerfTierMode.balanced);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    final sliderValues = tester
        .widgetList<Slider>(find.byType(Slider))
        .map((slider) => slider.value)
        .toList();
    expect(sliderValues, [14.0, 0.35, 16.0, 0.92, 14.0, 0.96]);

    await tester.tap(find.text(Translations.get('cancel', logic.lang)));
    await tester.pumpAndSettle();

    expect(theme.perfMode, PerfTierMode.auto);
    expect(theme.cardBlur, 7);
    expect(theme.cardOpacity, 0.4);
    expect(theme.dialogBlur, 9);
    expect(theme.dialogOpacity, 0.8);
    expect(theme.dropdownBlur, 11);
    expect(theme.dropdownOpacity, 0.7);
  });
}
