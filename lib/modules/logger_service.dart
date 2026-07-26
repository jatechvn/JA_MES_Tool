import 'dart:io';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

class LoggerService {
  static Future<void> init() async {
    Logger.root.level = Level.ALL;
    
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final logDir = Directory('$exeDir/logs');
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    
    // Clean old logs
    final now = DateTime.now();
    try {
      final files = logDir.listSync();
      for (var file in files) {
        if (file is File && file.path.endsWith('.txt')) {
          final stat = await file.stat();
          if (now.difference(stat.modified).inDays > 7) {
            try {
              await file.delete();
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error cleaning logs: $e');
    }

    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final logFile = File('${logDir.path}/mes_log_$dateStr.txt');
    
    Logger.root.onRecord.listen((record) async {
      final msg = '${record.time}: [${record.level.name}] ${record.loggerName}: ${record.message}';
      if (kDebugMode) {
        print(msg);
        if (record.error != null) print(record.error);
        if (record.stackTrace != null) print(record.stackTrace);
      }
      
      try {
        await logFile.writeAsString('$msg\n', mode: FileMode.append);
        if (record.error != null) {
          await logFile.writeAsString('${record.error}\n', mode: FileMode.append);
        }
        if (record.stackTrace != null) {
          await logFile.writeAsString('${record.stackTrace}\n', mode: FileMode.append);
        }
      } catch (_) {}
    });
  }
}
