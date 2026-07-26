import 'package:flutter/material.dart';

// Windows 11 styles use lower opacity to allow Acrylic to bleed through cleanly
Color getWin11SidebarBg(bool isDark) {
  return isDark ? const Color(0x661E1E1E) : const Color(0x66F0F0F0); // 40% opacity
}

Color getWin11CardBg(bool isDark) {
  return isDark ? const Color(0x99252526) : const Color(0x99FFFFFF); // 60% opacity
}
