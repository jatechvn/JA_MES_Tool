import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_mes_tool/modules/api_client.dart';
import 'package:ja_mes_tool/modules/config_service.dart';
import 'package:ja_mes_tool/modules/logic.dart';
import 'package:ja_mes_tool/modules/translations.dart';
import 'package:ja_mes_tool/modules/ui/dialogs/login_dialog.dart';
import 'package:ja_mes_tool/theme/theme_provider.dart';

String _buildSampleJwt(String userAccount) {
  final header = base64Url.encode(utf8.encode(json.encode({'alg': 'HS512'})));
  final payload = base64Url.encode(
    utf8.encode(
      json.encode({
        'sub': '2035',
        'user_account': userAccount,
        'cope_code': 'F_VN',
      }),
    ),
  );
  return '$header.$payload.signature';
}

void main() {
  test('extractAccountFromJwt decodes user_account from CloudMES JWT', () {
    final jwt = _buildSampleJwt('V1801179');
    expect(ApiClient.extractAccountFromJwt(jwt), 'V1801179');
    expect(ApiClient.extractAccountFromJwt('bearer $jwt'), 'V1801179');
    expect(ApiClient.extractAccountFromJwt('invalid-token'), isEmpty);
  });

  test('ConfigService encodePassword and decodePassword round-trip', () {
    const raw = 'MySecret#2026!';
    final encoded = ConfigService.encodePassword(raw);
    expect(encoded, isNot(equals(raw)));
    expect(encoded.startsWith('james_v1:'), isTrue);
    expect(ConfigService.decodePassword(encoded), equals(raw));
  });

  testWidgets(
    'MesLoginDialog supports SSO/CloudMES toggle, remember/auto-login, and logout account switch',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Map<String, dynamic> savedMap = {};
      final jwt = _buildSampleJwt('V1801179');
      final logic = AppLogic(
        initialize: false,
        saveConfig: (cfg) async {
          savedMap = Map<String, dynamic>.from(cfg);
        },
      );
      await logic.updateCredentials(
        token: jwt,
        uuid: 'test-uuid',
        operationId: '',
        cookie: 'CloudMES-token=$jwt',
      );
      logic.isConnectionValid = true;

      final theme = ThemeProvider(initialMode: 'dark');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MesLoginDialog(logic: logic, colors: theme.colors),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Active account V1801179 and Logout button should be visible
      expect(find.text('V1801179'), findsWidgets);
      expect(find.byKey(const ValueKey('mes_logout_btn')), findsOneWidget);

      // Switch login method from SSO to CloudMES
      await tester.tap(find.byKey(const ValueKey('login_method_cloudmes')));
      await tester.pumpAndSettle();
      expect(logic.loginMethod, 'CLOUDMES');
      expect(savedMap['loginMethod'], 'CLOUDMES');

      // Switch back to SSO
      await tester.tap(find.byKey(const ValueKey('login_method_sso')));
      await tester.pumpAndSettle();
      expect(logic.loginMethod, 'SSO');

      // Click Logout / Switch Account
      await tester.tap(find.byKey(const ValueKey('mes_logout_btn')));
      await tester.pumpAndSettle();

      expect(logic.isConnectionValid, isFalse);
      expect(logic.token, isEmpty);
      expect(find.byKey(const ValueKey('mes_logout_btn')), findsNothing);
      expect(find.textContaining('9222'), findsNothing);

      for (final lang in ['en', 'vn', 'cn']) {
        expect(
          Translations.get('or_browser_sync', lang).contains('9222'),
          isFalse,
        );
      }

      logic.dispose();
      theme.dispose();
    },
  );
}
