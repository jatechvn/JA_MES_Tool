import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'modules/build_info.dart';
import 'modules/constants.dart';
import 'modules/logic.dart';
import 'modules/logger_service.dart';
import 'modules/window_helper.dart';
import 'modules/ui/main_window.dart';
import 'theme/theme_provider.dart';

import 'theme/language_provider.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (args.contains('-debug') ||
      args.contains('--debug') ||
      args.contains('-d')) {
    BuildInfo.isCliDebug = true;
  }

  await initGlassWindow(
    title: '$appName v$appVersion',
    size: const Size(1280, 840),
    minSize: const Size(840, 560),
  );

  await LoggerService.init();

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
      title: '$appName v$appVersion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: theme.isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor:
            Colors.transparent, // Required for Aero/Acrylic
      ),
      home: const MainWindow(),
    );
  }
}
