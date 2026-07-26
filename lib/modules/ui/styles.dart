import 'dart:io';
import 'package:flutter/material.dart';
import 'styles_win10.dart';
import 'styles_win11.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;
  bool _isWin11 = false;

  bool get isDark => _isDark;
  bool get isWin11 => _isWin11;

  ThemeProvider() {
    _detectWindowsVersion();
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

  void toggleTheme() {
    _isDark = !_isDark;
    // In a full implementation, you'd call a MethodChannel to update the native window theme
    notifyListeners();
  }

  // Common styles
  Color get textPrimary => _isDark ? Colors.white : Colors.black87;
  Color get textSecondary => _isDark ? Colors.white70 : Colors.black54;
  Color get borderTheme => _isDark ? Colors.white10 : Colors.black12;

  // OS Specific transparent styles
  Color get scaffoldBackgroundColor => Colors.transparent;
  
  Color get mainBg => _isDark 
      ? const Color(0xF0181818) 
      : const Color(0xF0F8F9FA);

  Color get sidebarBg => _isWin11 
      ? getWin11SidebarBg(_isDark) 
      : getWin10SidebarBg(_isDark);
      
  Color get cardBg => _isWin11 
      ? getWin11CardBg(_isDark) 
      : getWin10CardBg(_isDark);

  Color get passColor => Colors.green.shade600;
  Color get failColor => Colors.red.shade600;
}
