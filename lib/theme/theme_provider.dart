import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'app_colors.dart';
import 'styles_win10.dart';
import 'styles_win11.dart';

class ThemeProvider extends ChangeNotifier with WidgetsBindingObserver {
  String _themeMode = 'system';
  bool _isWin11 = false;

  ThemeProvider({String initialMode = 'system'}) {
    _themeMode = initialMode;
    _detectWindowsVersion();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangePlatformBrightness() {
    // Only the 'system' mode depends on OS brightness — an explicit
    // light/dark choice must never be overridden by an OS-level change.
    if (_themeMode == 'system') notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _detectWindowsVersion() {
    if (!Platform.isWindows) return;
    try {
      final versionStr = Platform.operatingSystemVersion;
      final match = RegExp(r'Build\s+(\d+)').firstMatch(versionStr);
      if (match != null) {
        final buildNumber = int.tryParse(match.group(1) ?? '') ?? 0;
        _isWin11 = buildNumber >= 22000;
      }
    } catch (_) {}
  }

  String get themeMode => _themeMode;

  bool get isDark {
    if (_themeMode == 'dark') return true;
    if (_themeMode == 'light') return false;
    final brightness =
        SchedulerBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark;
  }

  bool get isWin11 => _isWin11;

  AppColors get colors {
    if (isDark) {
      return _isWin11 ? win11DarkColors : win10DarkColors;
    } else {
      return _isWin11 ? win11LightColors : win10LightColors;
    }
  }

  void toggleTheme() {
    _themeMode = isDark ? 'light' : 'dark';
    notifyListeners();
  }

  void setThemeMode(String mode) {
    _themeMode = mode;
    notifyListeners();
  }

  // Backward compatibility getters
  Color get textPrimary => colors.textPrimary;
  Color get textSecondary => colors.textSecondary;
  Color get borderTheme => colors.borderDefault;
  Color get scaffoldBackgroundColor => colors.bgPrimary;
  Color get mainBg => colors.bgSecondary;
  Color get sidebarBg => colors.sidebarBg;
  Color get cardBg => colors.cardBg;
  Color get passColor => colors.accentEmerald;
  Color get failColor => colors.accentRose;
}

extension ThemeExtension on BuildContext {
  AppColors get appColors => watch<ThemeProvider>().colors;
}
