import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'modules/constants.dart';
import 'modules/logic.dart';
import 'modules/ui/styles.dart';
import 'modules/logger_service.dart';
import 'modules/ui/main_window.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        scaffoldBackgroundColor: Colors.transparent, // Required for Aero/Acrylic
        // In a real app we'd load Outfit font here: fontFamily: 'Outfit'
      ),
      home: const MainWindow(),
    );
  }
}
