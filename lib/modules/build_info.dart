import 'dart:io';
import 'package:flutter/foundation.dart';
import 'constants.dart';

/// CLI flags parser, debug mode indicator & build timestamp.
///
/// `debug.bat` launches the compiled exe with `-debug` so testers can tell a
/// debug-flagged run apart from a normal one without needing `flutter run`.
class BuildInfo {
  static bool isCliDebug = false;
  static final String debugTimestamp = _generateBuildTimestamp();

  static String _generateBuildTimestamp() {
    try {
      final exeFile = File(Platform.resolvedExecutable);
      final exeDir = exeFile.parent.path;
      final sep = Platform.pathSeparator;

      // 1. Primary target: data/app.so next to executable
      final appSoFile = File('$exeDir${sep}data${sep}app.so');
      if (appSoFile.existsSync()) {
        return _formatDateTime(appSoFile.lastModifiedSync());
      }

      // 2. Secondary target: app.so in current build directories
      final buildPaths = [
        'build${sep}windows${sep}x64${sep}runner${sep}Debug${sep}data${sep}app.so',
        'build${sep}windows${sep}x64${sep}runner${sep}Release${sep}data${sep}app.so',
        'build${sep}windows${sep}runner${sep}Debug${sep}data${sep}app.so',
        'build${sep}windows${sep}runner${sep}Release${sep}data${sep}app.so',
        'dist${sep}data${sep}app.so',
      ];
      for (final p in buildPaths) {
        final f = File(p);
        if (f.existsSync()) {
          return _formatDateTime(f.lastModifiedSync());
        }
      }

      // 3. Executable itself
      if (exeFile.existsSync()) {
        return _formatDateTime(exeFile.lastModifiedSync());
      }
    } catch (_) {}
    return _formatDateTime(DateTime.now());
  }

  static String _formatDateTime(DateTime dt) {
    final y = dt.year;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min:$s';
  }

  static bool get isDebug => kDebugMode || isCliDebug;
  static const String version = appVersion;
}
