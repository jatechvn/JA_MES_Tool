import 'package:flutter/material.dart';
import '../../logic.dart';
import '../../../theme/theme_provider.dart';
import 'login_dialog.dart';

Future<void> showTokenExpiredWarningDialog(
  BuildContext context,
  AppLogic logic,
  ThemeProvider theme, {
  required VoidCallback onOpenSettings,
}) {
  return showMesLoginDialog(
    context,
    logic: logic,
    colors: theme.colors,
    onOpenFullSettings: onOpenSettings,
  );
}
