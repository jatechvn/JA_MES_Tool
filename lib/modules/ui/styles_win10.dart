import 'package:flutter/material.dart';

// Windows 10 styles need higher opacity to show above Aero Blur smoothly
Color getWin10SidebarBg(bool isDark) {
  return isDark ? const Color(0xB31E1E1E) : const Color(0xB3F0F0F0); // 70% opacity
}

Color getWin10CardBg(bool isDark) {
  return isDark ? const Color(0xD9252526) : const Color(0xD9FFFFFF); // 85% opacity
}
