import 'dart:convert';
import 'dart:io';
import 'constants.dart';
import 'package:logging/logging.dart';

final _logger = Logger('ConfigService');

class ConfigService {
  static Future<Map<String, dynamic>> loadConfig() async {
    try {
      final file = File(configFileName);
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = json.decode(content);
        List<String> snList = [];
        if (data['sns'] is List) {
          snList = List<String>.from(data['sns'].map((e) => e.toString()));
        } else if (data['sn'] != null) {
          snList = [data['sn'].toString()];
        }
        return {
          'token': data['token']?.toString() ?? '',
          'sns': snList,
          'lang': data['lang']?.toString() ?? 'en',
          'operationId': data['operationId']?.toString() ?? defaultOperationId,
          'uuid': data['uuid']?.toString() ?? defaultUuid,
          'cookie': data['cookie']?.toString() ?? '',
          'bgBlur': data['bgBlur'],
          'bgOpacity': data['bgOpacity'],
          'dialogBlur': data['dialogBlur'],
          'dialogOpacity': data['dialogOpacity'],
        };
      }
    } catch (e) {
      _logger.warning('Failed to load config: $e');
    }
    return {
      'token': '',
      'sns': <String>[],
      'lang': 'en',
      'operationId': defaultOperationId,
      'uuid': defaultUuid,
      'cookie': '',
      'bgBlur': null,
      'bgOpacity': null,
      'dialogBlur': null,
      'dialogOpacity': null,
    };
  }

  static Future<void> saveConfig(Map<String, dynamic> config) async {
    try {
      final file = File(configFileName);
      await file.writeAsString(json.encode(config));
    } catch (e) {
      _logger.warning('Failed to save config: $e');
    }
  }
}
