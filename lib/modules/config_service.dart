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
        List<String> traceCsns = [];
        if (data['traceCsns'] is List) {
          traceCsns = List<String>.from(
            data['traceCsns'].map((e) => e.toString()),
          );
        }
        return {
          'token': data['token']?.toString() ?? '',
          'sns': snList,
          'traceCsns': traceCsns,
          'lang': data['lang']?.toString() ?? 'en',
          'hasConfiguredLang': data.containsKey('lang') && data['lang'] != null,
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
      'traceCsns': <String>[],
      'lang': 'en',
      'hasConfiguredLang': false,
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
