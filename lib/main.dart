import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'modules/build_info.dart';
import 'modules/constants.dart';
import 'modules/logic.dart';
import 'modules/ui/styles.dart';
import 'modules/logger_service.dart';
import 'modules/ui/main_window.dart';

void main(List<String> args) async {
  if (args.contains('-debug') ||
      args.contains('--debug') ||
      args.contains('-d')) {
    BuildInfo.isCliDebug = true;
  }
  WidgetsFlutterBinding.ensureInitialized();
  // Only used for maximize/resize state (isMaximized + WindowListener) — never
  // set titleBarStyle/backgroundColor via WindowOptions here, that resets the
  // native glass composition set up in windows/runner/theme_win10.cpp &
  // theme_win11.cpp (see flutter-windows-themer skill notes).
  await windowManager.ensureInitialized();
  await LoggerService.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppLogic()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return MaterialApp(
      title: '$appName v$appVersion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: theme.isDark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor:
            Colors.transparent, // Required for Aero/Acrylic
        // In a real app we'd load Outfit font here: fontFamily: 'Outfit'
      ),
      home: const MainWindow(),
    );
  }
}
