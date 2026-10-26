import 'dart:convert';
import 'dart:io';
import 'constants.dart';
import 'package:logging/logging.dart';

final _logger = Logger('ConfigService');

class ConfigService {
  static const String _pwdPrefix = 'james_v1:';
  static Future<void> _saveQueue = Future.value();

  static String encodePassword(String plain) {
    if (plain.isEmpty) return '';
    final bytes = utf8.encode(plain);
    final reversed = bytes.reversed.toList();
    return '$_pwdPrefix${base64Url.encode(reversed)}';
  }

  static String decodePassword(String raw) {
    if (raw.isEmpty) return '';
    try {
      if (raw.startsWith(_pwdPrefix)) {
        final payload = raw.substring(_pwdPrefix.length);
        final decoded = base64Url.decode(base64Url.normalize(payload));
        return utf8.decode(decoded.reversed.toList());
      }
      return raw;
    } catch (_) {
      return '';
    }
  }

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
        final rawMethod =
            data['loginMethod']?.toString().trim().toUpperCase() ?? 'SSO';
        return {
          'token': data['token']?.toString() ?? '',
          'sns': snList,
          'traceCsns': traceCsns,
          'lang': data['lang']?.toString() ?? 'en',
          'hasConfiguredLang': data.containsKey('lang') && data['lang'] != null,
          'operationId': data['operationId']?.toString() ?? defaultOperationId,
          'uuid': data['uuid']?.toString() ?? defaultUuid,
          'cookie': data['cookie']?.toString() ?? '',
          'username': data['username']?.toString() ?? '',
          'savedPassword': decodePassword(
            data['savedPassword']?.toString() ?? '',
          ),
          'loginMethod': rawMethod == 'CLOUDMES' ? 'CLOUDMES' : 'SSO',
          'copeCode': data['copeCode']?.toString() ?? 'F_VN',
          'rememberPassword': data['rememberPassword'] is bool
              ? data['rememberPassword'] as bool
              : true,
          'autoLogin': data['autoLogin'] is bool
              ? data['autoLogin'] as bool
              : true,
          'bgBlur': data['bgBlur'],
          'bgOpacity': data['bgOpacity'],
          'dialogBlur': data['dialogBlur'],
          'dialogOpacity': data['dialogOpacity'],
          'dropdownBlur': data['dropdownBlur'],
          'dropdownOpacity': data['dropdownOpacity'],
          'perfMode': data['perfMode']?.toString() ?? 'auto',
          'enableIdleSleep': data['enableIdleSleep'] is bool
              ? data['enableIdleSleep'] as bool
              : true,
          'idleTimeoutSeconds': data['idleTimeoutSeconds'] is num
              ? (data['idleTimeoutSeconds'] as num).toInt()
              : 12,
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
      'username': '',
      'savedPassword': '',
      'loginMethod': 'SSO',
      'copeCode': 'F_VN',
      'rememberPassword': true,
      'autoLogin': true,
      'bgBlur': null,
      'bgOpacity': null,
      'dialogBlur': null,
      'dialogOpacity': null,
      'dropdownBlur': null,
      'dropdownOpacity': null,
      'perfMode': 'auto',
      'enableIdleSleep': true,
      'idleTimeoutSeconds': 12,
    };
  }

  static Future<void> saveConfig(Map<String, dynamic> config) {
    final snapshot = Map<String, dynamic>.from(config);
    _saveQueue = _saveQueue.then((_) async {
      try {
        if (snapshot.containsKey('savedPassword')) {
          final rawPwd = snapshot['savedPassword']?.toString() ?? '';
          snapshot['savedPassword'] = rawPwd.startsWith(_pwdPrefix)
              ? rawPwd
              : encodePassword(rawPwd);
        }
        final file = File(configFileName);
        await file.writeAsString(json.encode(snapshot), flush: true);
      } catch (e) {
        _logger.warning('Failed to save config: $e');
      }
    });
    return _saveQueue;
  }
}
