// Offline Windows UI verification; no configuration or MES access.
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:ja_mes_tool/modules/api_client.dart';
import 'package:ja_mes_tool/modules/logic.dart';
import 'package:ja_mes_tool/modules/ui/main_window.dart';
import 'package:ja_mes_tool/theme/theme_provider.dart';

Future<void> main() => http.runWithClient(
  runPreview,
  () => MockClient((_) async => http.Response('{"data":[]}', 200)),
);

Future<void> runPreview() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await windowManager.setTitle('JA MES Tool — Offline UI Preview');
  await windowManager.setSize(const Size(1266, 713));
  final logic = AppLogic(initialize: false, saveConfig: (_) async {});
  logic.snList.addAll(['DEMO-SN-001', 'DEMO-SN-002']);
  for (final sn in logic.snList) {
    logic.results[sn] = [
      TestRecord.fromJson({
        'sn': sn,
        'internalSn': sn,
        'processCode': 'FWTEST',
        'lineStationCode': 'FWTEST-A03T03',
        'result': 'PASS',
        'lastEditedDt': '2026-09-18 10:00:00',
        'woNo': 'DEMO-WO',
        'productNo': 'DEMO-PN',
      }),
      TestRecord.fromJson({
        'sn': sn,
        'processCode': 'FWTEST',
        'result': 'FAIL',
        'lastEditedDt': '2026-09-18 09:30:00',
        'failureReason': 'Demo failure for visual verification',
      }),
    ];
    logic.processResults[sn] = [];
    logic.wipResults[sn] = [];
  }
  logic.isConnectionValid = true;
  logic.selectSn('DEMO-SN-001');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: logic),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(initialMode: 'light'),
        ),
      ],
      child: Builder(
        builder: (context) {
          final theme = context.watch<ThemeProvider>();
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: theme.isDark ? Brightness.dark : Brightness.light,
              scaffoldBackgroundColor: Colors.transparent,
            ),
            home: const MainWindow(),
          );
        },
      ),
    ),
  );
}
