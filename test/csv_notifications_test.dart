import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ja_mes_tool/modules/logic.dart';
import 'package:ja_mes_tool/modules/translations.dart';
import 'package:ja_mes_tool/modules/ui/main_window.dart';
import 'package:ja_mes_tool/theme/theme_provider.dart';

void main() {
  late Directory temp;
  setUp(
    () async => temp = await Directory.systemTemp.createTemp('ja_csv_test_'),
  );
  tearDown(() async => temp.delete(recursive: true));

  final operations = <String, Future<void> Function(AppLogic)>{
    'template': (app) => app.downloadTemplateCsv(),
    'trace template': (app) => app.downloadTraceTemplateCsv(),
    'export': (app) => app.exportCsv(),
    'barcode export': (app) => app.exportBarcodeHistoryCsv(),
    'wip export': (app) => app.exportWipComponentsCsv(),
    'trace export': (app) => app.exportTraceCsv(),
    'import': (app) => app.importCsv(),
    'trace import': (app) => app.importTraceCsv(),
  };

  for (final entry in operations.entries) {
    test(
      '${entry.key} success is localized and not an error; cancel clears it',
      () async {
        String? path = '${temp.path}/file.csv';
        await File(path).writeAsString('');
        final app = AppLogic(
          initialize: false,
          saveConfig: (_) async {},
          filePicker: (_) async => path,
        );
        addTearDown(app.dispose);
        await entry.value(app);
        final key = entry.key.contains('template')
            ? 'csv_template_success'
            : entry.key.contains('import')
            ? 'csv_import_success'
            : 'csv_export_success';
        for (final lang in ['vn', 'en', 'cn']) {
          app.setLanguage(lang);
          expect(
            app.globalError,
            Translations.get(key, lang).replaceAll('{path}', path),
          );
          expect(app.globalMessageIsError, isFalse);
        }
        path = null;
        await entry.value(app);
        expect(app.globalError, isEmpty);
        expect(app.globalMessageIsError, isFalse);
      },
    );

    test('${entry.key} failure uses localized error message', () async {
      final app = AppLogic(
        initialize: false,
        saveConfig: (_) async {},
        filePicker: (_) async => throw StateError('test failure'),
      );
      addTearDown(app.dispose);
      await entry.value(app);
      final key = entry.key.contains('template')
          ? 'csv_template_error'
          : entry.key.contains('import')
          ? 'csv_import_error'
          : 'csv_export_error';
      for (final lang in ['vn', 'en', 'cn']) {
        app.setLanguage(lang);
        expect(app.globalMessageIsError, isTrue);
        expect(
          app.globalError,
          Translations.get(
            key,
            lang,
          ).replaceAll('{error}', 'Bad state: test failure'),
        );
      }
    });
  }

  for (final mode in ['light', 'dark']) {
    testWidgets(
      '$mode banner is green on success and red on missing import file',
      (tester) async {
        tester.view.physicalSize = const Size(1266, 680);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('window_manager'),
              (_) async => false,
            );
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(
                const MethodChannel('window_manager'),
                null,
              ),
        );
        var path = '${temp.path}/output.csv';
        final app = AppLogic(
          initialize: false,
          saveConfig: (_) async {},
          filePicker: (_) async => path,
        );
        final theme = ThemeProvider(initialMode: mode);
        addTearDown(app.dispose);
        addTearDown(theme.dispose);
        app.isConnectionValid = true;
        app.setLanguage('vn');
        await tester.runAsync(app.exportCsv);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AppLogic>.value(value: app),
              ChangeNotifierProvider<ThemeProvider>.value(value: theme),
            ],
            child: const MaterialApp(home: MainWindow()),
          ),
        );
        await tester.pump();
        final success = find.byIcon(Icons.check_circle_outline_rounded);
        expect(success, findsOneWidget);
        expect(tester.widget<Icon>(success).color, theme.colors.accentEmerald);
        expect(
          tester.widget<Text>(find.text(app.globalError)).style!.color,
          theme.colors.accentEmerald,
        );
        app.setLanguage('cn');
        await tester.pump();
        expect(
          find.text(
            Translations.get(
              'csv_export_success',
              'cn',
            ).replaceAll('{path}', path),
          ),
          findsOneWidget,
        );
        path = '${temp.path}/missing.csv';
        await tester.runAsync(app.importCsv);
        await tester.pump();
        final error = find.byIcon(Icons.error_outline_rounded);
        expect(error, findsOneWidget);
        expect(tester.widget<Icon>(error).color, theme.colors.accentRose);
        expect(
          tester.widget<Text>(find.text(app.globalError)).style!.color,
          theme.colors.accentRose,
        );
        expect(app.globalError, Translations.get('csv_file_not_found', 'cn'));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
