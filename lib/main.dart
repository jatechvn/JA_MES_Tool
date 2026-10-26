import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'modules/build_info.dart';
import 'modules/constants.dart';
import 'modules/logic.dart';
import 'modules/logger_service.dart';
import 'modules/window_helper.dart';
import 'modules/ui/main_window.dart';
import 'theme/theme_provider.dart';

import 'theme/language_provider.dart';
import 'modules/services/app_power_manager.dart';
import 'modules/services/power_binding.dart';

final _rootLogger = Logger('GlobalError');

void main(List<String> args) async {
  PowerWidgetsBinding();

  if (args.contains('-debug') ||
      args.contains('--debug') ||
      args.contains('-d')) {
    BuildInfo.isCliDebug = true;
  }

  await LoggerService.init();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _rootLogger.severe(
      'FlutterError: ${details.exceptionAsString()}',
      details.exception,
      details.stack,
    );
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    _rootLogger.severe('Uncaught Platform Error: $error', error, stack);
    return true;
  };

  await initGlassWindow(
    title: appName,
    size: const Size(1280, 840),
    minSize: const Size(840, 560),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AppLogic()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: theme.isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor:
            Colors.transparent, // Required for Aero/Acrylic
      ),
      builder: (context, child) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) {
            final power = AppPowerManager.instance;
            if (power.isWindowVisible && !power.isWindowFocused) {
              power.onWindowFocus();
            }
            power.recordUserInteraction();
          },
          onPointerMove: (_) =>
              AppPowerManager.instance.recordUserInteraction(),
          onPointerHover: (_) =>
              AppPowerManager.instance.recordUserInteraction(),
          onPointerSignal: (_) =>
              AppPowerManager.instance.recordUserInteraction(),
          child: Focus(
            autofocus: false,
            onKeyEvent: (_, _) {
              final power = AppPowerManager.instance;
              if (power.isWindowVisible && !power.isWindowFocused) {
                power.onWindowFocus();
              }
              power.recordUserInteraction();
              return KeyEventResult.ignored;
            },
            child: PowerTickerGate(child: child ?? const SizedBox.shrink()),
          ),
        );
      },
      home: const MainWindow(),
    );
  }
}
