import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_mes_tool/modules/logic.dart';
import 'package:ja_mes_tool/modules/services/ota_update_service.dart';
import 'package:ja_mes_tool/modules/translations.dart';
import 'package:ja_mes_tool/modules/ui/dialogs/login_dialog.dart';
import 'package:ja_mes_tool/modules/ui/dialogs/settings_dialog.dart';
import 'package:ja_mes_tool/modules/services/app_power_manager.dart';
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
      'idle_sleep_title',
      'idle_sleep_desc',
      'idle_sleep_enable',
      'idle_timeout_label',
      'idle_12s',
      'idle_30s',
      'idle_60s',
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

      // Tab 0: MES API & CDP content - verify hidden by default, expandable on tap
      expect(
        find.text(Translations.get('show_advanced', logic.lang)),
        findsOneWidget,
      );
      expect(
        find.text(Translations.get('cdp_sync_title', logic.lang)),
        findsNothing,
      );
      // Tap to expand advanced token settings
      await tester.tap(
        find.text(Translations.get('show_advanced', logic.lang)),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(Translations.get('cdp_sync_title', logic.lang)),
        findsOneWidget,
      );
      expect(
        find.text(Translations.get('hide_advanced', logic.lang)),
        findsOneWidget,
      );
      // Tap again to collapse back
      await tester.tap(
        find.text(Translations.get('hide_advanced', logic.lang)),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(Translations.get('cdp_sync_title', logic.lang)),
        findsNothing,
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

  testWidgets(
    'Idle sleep mode renders, toggles switch, selects timeout, and rollback/save work',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(AppPowerManager.instance.resetForTesting);

      Map<String, dynamic>? savedConfig;
      final logic = AppLogic(
        initialize: false,
        saveConfig: (cfg) async {
          savedConfig = cfg;
        },
      );
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

      // Switch to Tab 1: Display & Appearance
      await tester.tap(
        find.text(Translations.get('tab_display_glass', logic.lang)),
      );
      await tester.pumpAndSettle();

      // Scroll down to reveal Idle Power Saving BentoCard
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(
        find.text(Translations.get('idle_sleep_title', logic.lang)),
        findsOneWidget,
      );
      expect(
        find.text(Translations.get('idle_timeout_label', logic.lang)),
        findsOneWidget,
      );
      expect(
        find.text(Translations.get('idle_12s', logic.lang)),
        findsOneWidget,
      );
      expect(
        find.text(Translations.get('idle_30s', logic.lang)),
        findsOneWidget,
      );
      expect(
        find.text(Translations.get('idle_60s', logic.lang)),
        findsOneWidget,
      );

      // Select 30s timeout
      await tester.tap(find.text(Translations.get('idle_30s', logic.lang)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(AppPowerManager.instance.enableIdleSleep, isFalse);
      expect(logic.enableIdleSleep, isTrue);

      // Tap Cancel - should rollback and NOT save
      await tester.tap(find.text(Translations.get('cancel', logic.lang)));
      await tester.pumpAndSettle();

      expect(savedConfig, isNull);
      expect(logic.idleTimeoutSeconds, 12);
      expect(AppPowerManager.instance.enableIdleSleep, isTrue);
      expect(AppPowerManager.instance.idleTimeout, const Duration(seconds: 12));

      // Reopen dialog, change to 60s and tap Save
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.text(Translations.get('tab_display_glass', logic.lang)),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      await tester.tap(find.text(Translations.get('idle_60s', logic.lang)));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      await tester.tap(find.text(Translations.get('save', logic.lang)));
      await tester.pumpAndSettle();

      expect(savedConfig, isNotNull);
      expect(savedConfig!['idleTimeoutSeconds'], 60);
      expect(savedConfig!['enableIdleSleep'], isFalse);
      expect(logic.enableIdleSleep, isFalse);
      expect(AppPowerManager.instance.enableIdleSleep, isFalse);
      expect(logic.idleTimeoutSeconds, 60);
      expect(AppPowerManager.instance.idleTimeout, const Duration(seconds: 60));

      AppPowerManager.instance.setEnableIdleSleep(true);
      AppPowerManager.instance.setIdleTimeout(const Duration(seconds: 12));
      AppPowerManager.instance.resetForTesting();
    },
  );

  testWidgets(
    'Settings dialog disposes text controllers cleanly on Cancel and Save',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(AppPowerManager.instance.resetForTesting);

      final tempDir = Directory.systemTemp.createTempSync(
        'ja_mes_settings_test',
      );
      final tempOtaConfig = File('${tempDir.path}\\update_config.json');
      OtaUpdateService().setCustomConfigFileForTesting(tempOtaConfig);
      addTearDown(() async {
        OtaUpdateService().setCustomConfigFileForTesting(null);
        for (var i = 0; i < 10; i++) {
          if (!tempDir.existsSync()) break;
          try {
            tempDir.deleteSync(recursive: true);
            break;
          } catch (_) {
            await Future<void>.delayed(const Duration(milliseconds: 30));
          }
        }
      });

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

      // Cycle 1: Open, enter text in Tab 0 and Tab 2, then Cancel.
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('toggle_advanced_token_btn')));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), 'TEMP_OP_ID');
      await tester.tap(
        find.text(Translations.get('tab_about_updates', logic.lang)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, r'\\server\ota');
      await tester.tap(find.text(Translations.get('cancel', logic.lang)));
      await tester.pumpAndSettle();

      expect(logic.operationId, isNot('TEMP_OP_ID'));
      expect(find.text(Translations.get('settings', logic.lang)), findsNothing);
      expect(tester.takeException(), isNull);

      // Cycle 2: Open, edit Operation ID, then Save and settle disk I/O + pop.
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('toggle_advanced_token_btn')));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(1), 'SAVED_OP_ID');
      await tester.tap(find.text(Translations.get('save', logic.lang)));
      for (var i = 0; i < 40; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await tester.pump();
        if (find
            .text(Translations.get('settings', logic.lang))
            .evaluate()
            .isEmpty) {
          break;
        }
      }
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));

      expect(logic.operationId, 'SAVED_OP_ID');
      expect(find.text(Translations.get('settings', logic.lang)), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Settings MES Account card renders a single account action button and preserves logout on Save',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(AppPowerManager.instance.resetForTesting);

      final tempDir = Directory.systemTemp.createTempSync(
        'ja_mes_settings_logout_test',
      );
      final tempOtaConfig = File('${tempDir.path}\\update_config.json');
      OtaUpdateService().setCustomConfigFileForTesting(tempOtaConfig);
      addTearDown(() async {
        OtaUpdateService().setCustomConfigFileForTesting(null);
        for (var i = 0; i < 10; i++) {
          if (!tempDir.existsSync()) break;
          try {
            tempDir.deleteSync(recursive: true);
            break;
          } catch (_) {
            await Future<void>.delayed(const Duration(milliseconds: 30));
          }
        }
      });

      final header = base64Url.encode(
        utf8.encode(json.encode({'alg': 'HS512'})),
      );
      final payload = base64Url.encode(
        utf8.encode(json.encode({'sub': '2035', 'user_account': 'V1801179'})),
      );
      final jwt = '$header.$payload.signature';

      final logic = AppLogic(initialize: false, saveConfig: (_) async {});
      logic.setLoginPreferences(rememberPassword: true, autoLogin: true);
      await logic.updateCredentials(
        token: jwt,
        uuid: 'test-uuid',
        operationId: 'op-1',
        cookie: 'CloudMES-token=$jwt',
      );
      logic.isConnectionValid = true;
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

      // Open Settings dialog while logged in.
      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      expect(
        find.text(Translations.get('logout_btn', logic.lang)),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('settings_account_action_btn')),
        findsOneWidget,
      );
      expect(
        find.text(Translations.get('switch_account_btn', logic.lang)),
        findsOneWidget,
      );

      // Open MesLoginDialog from the unified Settings button and log out.
      await tester.tap(
        find.byKey(const ValueKey('settings_account_action_btn')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('mes_logout_btn')));
      await tester.pumpAndSettle();

      expect(logic.token, isEmpty);
      expect(logic.isConnectionValid, isFalse);
      expect(logic.manualLogoutInSession, isTrue);

      // Close MesLoginDialog to return to Settings.
      await tester.tap(
        find.descendant(
          of: find.byType(MesLoginDialog),
          matching: find.byIcon(Icons.close_rounded),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(Translations.get('login_btn', logic.lang)),
        findsOneWidget,
      );
      expect(
        find.text(Translations.get('switch_account_btn', logic.lang)),
        findsNothing,
      );

      // Save Settings while logged out: manualLogoutInSession must stay true.
      await tester.tap(find.text(Translations.get('save', logic.lang)));
      for (var i = 0; i < 40; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await tester.pump();
        if (find
            .text(Translations.get('settings', logic.lang))
            .evaluate()
            .isEmpty) {
          break;
        }
      }
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));

      expect(find.text(Translations.get('settings', logic.lang)), findsNothing);
      expect(logic.token, isEmpty);
      expect(logic.isConnectionValid, isFalse);
      expect(logic.manualLogoutInSession, isTrue);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      logic.dispose();
      theme.dispose();
    },
  );
}
