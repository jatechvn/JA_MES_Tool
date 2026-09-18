import 'dart:io';
import 'package:flutter/material.dart';
import '../../logic.dart';
import '../../logger_service.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/glass_terminal.dart';
import '../../constants.dart';

class TerminalView extends StatelessWidget {
  final AppLogic logic;
  final ThemeProvider theme;

  const TerminalView({super.key, required this.logic, required this.theme});

  @override
  Widget build(BuildContext context) {
    return GlassTerminalPanel(
      terminalTitle: 'JA MES Tool • Live Diagnostic Terminal',
      initialWelcomeText:
          '''
   ██╗ █████╗     ███╗   ███╗███████╗███████╗
   ██║██╔══██╗    ████╗ ████║██╔════╝██╔════╝
   ██║███████║    ██╔████╔██║█████╗  ███████╗
██ ██║██╔══██║    ██║╚██╔╝██║██╔══╝  ╚════██║
╚████║██║  ██║    ██║ ╚═╝ ██║███████╗███████║
 ╚═══╝╚═╝  ╚═╝    ╚═╝     ╚═╝╚══════╝╚══════╝
 Foxconn CloudMES Diagnostic & Stream Monitor v$appVersion
 Type "help" to see available terminal commands.
''',
      onCommand: (command) async {
        final cmd = command.trim().toLowerCase();
        if (cmd == 'help') {
          return '''
Available Commands:
  help       - Show this command reference
  status     - Display current MES connection status & queue count
  token      - Verify CloudMES authentication token
  refresh    - Re-query all records in current queue
  clear      - Clear terminal logs
  logs       - Display recent system log records
  cdp        - Launch CDP browser login session
  os         - Display OS & Hardware profile information
''';
        } else if (cmd == 'status') {
          return '''
[Connection Status]
  Valid: ${logic.isConnectionValid ?? false}
  Server: Foxconn CloudMES
  Queue Count: ${logic.snList.length} SNs
  Selected SN: ${logic.selectedSn.isEmpty ? 'None' : logic.selectedSn}
  Mode: ${logic.viewMode.name}
''';
        } else if (cmd == 'token') {
          final ok = await logic.testConnection();
          return ok
              ? '✓ CloudMES Token is VALID & ACTIVE.'
              : '✗ CloudMES Token is EXPIRED or INVALID (${logic.connectionError})';
        } else if (cmd == 'refresh') {
          logic.refetchAllSns();
          return 'Triggered full refresh of ${logic.snList.length} SNs.';
        } else if (cmd == 'clear') {
          LoggerService.clearLogs();
          return 'Logs cleared.';
        } else if (cmd == 'logs') {
          if (LoggerService.recentLogs.isEmpty) {
            return 'No recent log records found.';
          }
          final count = LoggerService.recentLogs.length;
          final take = count > 25 ? 25 : count;
          return LoggerService.recentLogs.skip(count - take).join('\n');
        } else if (cmd == 'os') {
          return '''
[OS & Hardware Diagnostics]
  Platform: ${Platform.operatingSystem} (${Platform.operatingSystemVersion})
  CPU Cores: ${theme.cpuCores}
  Graphic Tier: ${theme.effectiveTier.label} (${theme.hardwareScore}/100)
  Glass Blur: Card ${theme.cardBlur.toInt()}px, Dialog ${theme.dialogBlur.toInt()}px, Dropdown ${theme.dropdownBlur.toInt()}px
''';
        }
        return 'Unknown command: "$command". Type "help" for a list of commands.';
      },
    );
  }
}
