import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'constants.dart';
import 'models/mes_models.dart';

export 'models/mes_models.dart';

final _logger = Logger('ApiClient');

String _cleanHeader(String value) {
  String clean = value.replaceAll('\r', '').replaceAll('\n', '').trim();
  if (clean.startsWith('"') && clean.endsWith('"')) {
    clean = clean.substring(1, clean.length - 1).trim();
  }
  return clean;
}

class ApiClient {
  static Future<List<TestRecord>> fetchTestRecords({
    required String sn,
    required String token,
    required String lang,
    required String operationId,
    required String uuid,
    required String cookie,
  }) async {
    final page = await _fetchTestRecordPage(
      sn: sn,
      woNo: '',
      pageIndex: 1,
      pageSize: 100,
      token: token,
      lang: lang,
      operationId: operationId,
      uuid: uuid,
      cookie: cookie,
    );
    return page.records;
  }

  static Future<TestRecordPage> fetchWorkOrderPage({
    required String woNo,
    int pageIndex = 1,
    int pageSize = 100,
    required String token,
    required String lang,
    required String operationId,
    required String uuid,
    required String cookie,
  }) {
    if (woNo.trim().isEmpty) throw ArgumentError.value(woNo, 'woNo');
    if (pageIndex < 1 || pageSize < 1 || pageSize > 100) {
      throw ArgumentError('Invalid pagination');
    }
    return _fetchTestRecordPage(
      sn: '',
      woNo: woNo.trim(),
      pageIndex: pageIndex,
      pageSize: pageSize,
      token: token,
      lang: lang,
      operationId: operationId,
      uuid: uuid,
      cookie: cookie,
    );
  }

  static Future<TestRecordPage> _fetchTestRecordPage({
    required String sn,
    required String woNo,
    required int pageIndex,
    required int pageSize,
    required String token,
    required String lang,
    required String operationId,
    required String uuid,
    required String cookie,
  }) async {
    final cleanToken = _cleanHeader(
      token,
    ).replaceFirst(RegExp(r'^[bB][eE][aA][rR][eE][rR]\s+'), '').trim();
    final cleanLang = _cleanHeader(lang);
    final cleanOpId = _cleanHeader(operationId);
    final cleanUuid = _cleanHeader(uuid);
    final cleanCookie = _cleanHeader(cookie);

    final uri =
        Uri.parse(
          'https://vncmes.ces.myfiinet.com/api/cloudmes-report-mes/equipmentRecord/pageTestRecordLists',
        ).replace(
          queryParameters: {
            'pageIndex': '$pageIndex',
            'pageSize': '$pageSize',
            'productNo': '',
            'testStartDate': '',
            'testEndDate': '',
            'processCode': '',
            'woNo': woNo,
            'sn': sn,
            'stationId': '',
            'testTime': '',
            'productSeries': '',
            'orgCode': defaultOrgCode,
          },
        );

    final headers = {
      'Host': 'vncmes.ces.myfiinet.com',
      'Authorization': 'bearer $cleanToken',
      'factoryid': '13',
      'lang': cleanLang,
      'operation-id': cleanOpId,
      'org-code': defaultOrgCode,
      'timezone': '+07:00',
      'uuid': cleanUuid,
      'Cookie': cleanCookie.isNotEmpty
          ? cleanCookie
          : 'CloudMES-token=$cleanToken',
    };

    _logger.info('Fetching test records page $pageIndex');

    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception(
          'Token expired or unauthorized (401). Please update the token.',
        );
      }
      throw Exception('Server error: ${response.statusCode}');
    }

    final data = json.decode(response.body);

    final code = data['code'];
    final msg = data['msg'] ?? data['message'] ?? '';

    if (code != 200 &&
        code != 0 &&
        code.toString() != '200' &&
        code.toString() != '0') {
      if (code.toString() == '401' || msg.toString().contains('401')) {
        throw Exception(
          'Token expired or unauthorized (401). Please update the token.',
        );
      }
      throw Exception('API Error [$code]: $msg');
    }

    final responseData = data['data'];
    List<dynamic> recordsList = [];
    if (responseData is Map) {
      recordsList =
          responseData['list'] ??
          responseData['records'] ??
          responseData['rows'] ??
          [];
    } else if (responseData is List) {
      recordsList = responseData;
    }

    final total = responseData is Map
        ? responseData['totalCount'] ??
              responseData['total'] ??
              responseData['count']
        : null;
    return TestRecordPage(
      records: recordsList.map((e) => TestRecord.fromJson(e)).toList(),
      pageIndex: pageIndex,
      pageSize: pageSize,
      totalCount: int.tryParse('$total'),
    );
  }

  static Future<List<SnProcessRecord>> fetchSnProcessHistory({
    required String sn,
    required String token,
    required String lang,
    required String operationId,
    required String uuid,
    required String cookie,
  }) async {
    final cleanToken = _cleanHeader(
      token,
    ).replaceFirst(RegExp(r'^[bB][eE][aA][rR][eE][rR]\s+'), '').trim();
    final cleanLang = _cleanHeader(lang);
    final cleanOpId = _cleanHeader(operationId);
    final cleanUuid = _cleanHeader(uuid);
    final cleanCookie = _cleanHeader(cookie);

    final uri = Uri.parse(
      'https://vncmes.ces.myfiinet.com/api/cloudmes-report-mes/snProcess/querySnProcessDetailPageList',
    );

    final headers = {
      'Host': 'vncmes.ces.myfiinet.com',
      'Content-Type': 'application/json;charset=UTF-8',
      'Authorization': 'bearer $cleanToken',
      'factoryid': '13',
      'lang': cleanLang,
      'operation-id': cleanOpId,
      'org-code': defaultOrgCode,
      'timezone': '+07:00',
      'uuid': cleanUuid,
      'Cookie': cleanCookie.isNotEmpty
          ? cleanCookie
          : 'CloudMES-token=$cleanToken',
    };

    _logger.info('Fetching process history for SN: $sn');

    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode({'sn': sn, 'orgCode': defaultOrgCode}),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception(
          'Token expired or unauthorized (401). Please update the token.',
        );
      }
      throw Exception('Server error: ${response.statusCode}');
    }

    final data = json.decode(response.body);

    final code = data['code'];
    final msg = data['msg'] ?? data['message'] ?? '';

    if (code != 200 &&
        code != 0 &&
        code.toString() != '200' &&
        code.toString() != '0') {
      if (code.toString() == '401' || msg.toString().contains('401')) {
        throw Exception(
          'Token expired or unauthorized (401). Please update the token.',
        );
      }
      throw Exception('API Error [$code]: $msg');
    }

    final responseData = data['data'];
    List<dynamic> recordsList = [];
    if (responseData is Map) {
      recordsList = responseData['list'] ?? [];
    } else if (responseData is List) {
      recordsList = responseData;
    }

    return recordsList.map((e) => SnProcessRecord.fromJson(e)).toList();
  }

  static Future<List<WipComponentRecord>> fetchWipComponents({
    required String sn,
    required String token,
    required String lang,
    required String operationId,
    required String uuid,
    required String cookie,
  }) async {
    final cleanToken = _cleanHeader(
      token,
    ).replaceFirst(RegExp(r'^[bB][eE][aA][rR][eE][rR]\s+'), '').trim();
    final cleanLang = _cleanHeader(lang);
    final cleanOpId = _cleanHeader(operationId);
    final cleanUuid = _cleanHeader(uuid);
    final cleanCookie = _cleanHeader(cookie);

    final uri = Uri.parse(
      'https://vncmes.ces.myfiinet.com/api/cloudmes-report-mes/snProcess/pageWipProductComponentLists',
    );

    final headers = {
      'Host': 'vncmes.ces.myfiinet.com',
      'Content-Type': 'application/json;charset=UTF-8',
      'Authorization': 'bearer $cleanToken',
      'factoryid': '13',
      'lang': cleanLang,
      'operation-id': cleanOpId,
      'org-code': defaultOrgCode,
      'timezone': '+07:00',
      'uuid': cleanUuid,
      'Cookie': cleanCookie.isNotEmpty
          ? cleanCookie
          : 'CloudMES-token=$cleanToken',
    };

    _logger.info('Fetching WIP components for SN: $sn');

    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode({
        'pageIndex': 1,
        'pageSize': 100,
        'sn': sn,
        'orgCode': defaultOrgCode,
      }),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception(
          'Token expired or unauthorized (401). Please update the token.',
        );
      }
      throw Exception('Server error: ${response.statusCode}');
    }

    final data = json.decode(response.body);

    final code = data['code'];
    final msg = data['msg'] ?? data['message'] ?? '';

    if (code != 200 &&
        code != 0 &&
        code.toString() != '200' &&
        code.toString() != '0') {
      if (code.toString() == '401' || msg.toString().contains('401')) {
        throw Exception(
          'Token expired or unauthorized (401). Please update the token.',
        );
      }
      throw Exception('API Error [$code]: $msg');
    }

    final responseData = data['data'];
    List<dynamic> recordsList = [];
    if (responseData is Map) {
      recordsList = responseData['list'] ?? [];
    } else if (responseData is List) {
      recordsList = responseData;
    }

    return recordsList.map((e) => WipComponentRecord.fromJson(e)).toList();
  }

  static Future<List<ComponentParamRecord>> fetchComponentParams({
    required int wipProductComponentId,
    required String token,
    required String lang,
    required String operationId,
    required String uuid,
    required String cookie,
  }) async {
    final cleanToken = _cleanHeader(
      token,
    ).replaceFirst(RegExp(r'^[bB][eE][aA][rR][eE][rR]\s+'), '').trim();
    final cleanLang = _cleanHeader(lang);
    final cleanOpId = _cleanHeader(operationId);
    final cleanUuid = _cleanHeader(uuid);
    final cleanCookie = _cleanHeader(cookie);

    if (cleanToken.isEmpty) {
      throw Exception('Token cannot be empty');
    }

    final uri = Uri.parse(
      'https://vncmes.ces.myfiinet.com/api/cloudmes-report-mes/snProcess/queryComponentParam',
    );
    final headers = <String, String>{
      'Host': 'vncmes.ces.myfiinet.com',
      'Content-Type': 'application/json;charset=UTF-8',
      'Authorization': 'bearer $cleanToken',
      'factoryid': '13',
      'lang': cleanLang,
      'operation-id': cleanOpId,
      'org-code': defaultOrgCode,
      'timezone': '+07:00',
      'uuid': cleanUuid,
      'Cookie': cleanCookie.isNotEmpty
          ? cleanCookie
          : 'CloudMES-token=$cleanToken',
    };

    _logger.info(
      'Fetching component params for wipProductComponentId: $wipProductComponentId',
    );

    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode({
        'pageIndex': 1,
        'pageSize': 100,
        'wipProductComponentId': wipProductComponentId,
        'orgCode': defaultOrgCode,
      }),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception(
          'Token expired or unauthorized (401). Please update the token.',
        );
      }
      throw Exception('Server error: ${response.statusCode}');
    }

    final data = json.decode(response.body);

    final code = data['code'];
    final msg = data['msg'] ?? data['message'] ?? '';

    if (code != 200 &&
        code != 0 &&
        code.toString() != '200' &&
        code.toString() != '0') {
      if (code.toString() == '401' || msg.toString().contains('401')) {
        throw Exception(
          'Token expired or unauthorized (401). Please update the token.',
        );
      }
      throw Exception('API Error [$code]: $msg');
    }

    final responseData = data['data'];
    List<dynamic> recordsList = [];
    if (responseData is Map) {
      recordsList = responseData['list'] ?? [];
    } else if (responseData is List) {
      recordsList = responseData;
    }

    return recordsList.map((e) => ComponentParamRecord.fromJson(e)).toList();
  }

  static Future<SnMasterInfo> resolveSnMaster({
    required String sn,
    required String token,
    required String lang,
    required String operationId,
    required String uuid,
    required String cookie,
  }) async {
    final cleanToken = _cleanHeader(
      token,
    ).replaceFirst(RegExp(r'^[bB][eE][aA][rR][eE][rR]\s+'), '').trim();
    final cleanLang = _cleanHeader(lang);
    final cleanOpId = _cleanHeader(operationId);
    final cleanUuid = _cleanHeader(uuid);
    final cleanCookie = _cleanHeader(cookie);

    final uri = Uri.parse(
      'https://vncmes.ces.myfiinet.com/api/cloudmes-mes/snMaster/getSnMasterProcess',
    );

    final headers = {
      'Host': 'vncmes.ces.myfiinet.com',
      'Content-Type': 'application/json;charset=UTF-8',
      'Authorization': 'bearer $cleanToken',
      'factoryid': '13',
      'lang': cleanLang,
      'operation-id': cleanOpId,
      'org-code': defaultOrgCode,
      'timezone': '+07:00',
      'uuid': cleanUuid,
      'Cookie': cleanCookie.isNotEmpty
          ? cleanCookie
          : 'CloudMES-token=$cleanToken',
    };

    _logger.info('Resolving SN master for: $sn');

    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode({'sn': sn, 'orgCode': defaultOrgCode}),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception(
          'Token expired or unauthorized (401). Please update the token.',
        );
      }
      throw Exception('Server error: ${response.statusCode}');
    }

    final data = json.decode(response.body);

    final code = data['code'];
    final msg = data['msg'] ?? data['message'] ?? '';

    if (code != 200 &&
        code != 0 &&
        code.toString() != '200' &&
        code.toString() != '0') {
      if (code.toString() == '401' || msg.toString().contains('401')) {
        throw Exception(
          'Token expired or unauthorized (401). Please update the token.',
        );
      }
      throw Exception('API Error [$code]: $msg');
    }

    final snData = data['data'];
    if (snData is! Map || snData.isEmpty) {
      throw Exception('SN not found');
    }

    return SnMasterInfo.fromJson(Map<String, dynamic>.from(snData));
  }

  /// Reverse component lookup: given a scanned component serial (`csn`),
  /// finds which product SN it is currently installed into. `filedType`
  /// selects what kind of identifier `csn` is on the server side (`'2'` =
  /// CSN scan, matching the MES web frontend's default).
  static Future<List<QueryInfoRecord>> queryComponentInfo({
    required String csn,
    required String token,
    required String lang,
    required String operationId,
    required String uuid,
    required String cookie,
    String filedType = '2',
  }) async {
    final cleanToken = _cleanHeader(
      token,
    ).replaceFirst(RegExp(r'^[bB][eE][aA][rR][eE][rR]\s+'), '').trim();
    final cleanLang = _cleanHeader(lang);
    final cleanOpId = _cleanHeader(operationId);
    final cleanUuid = _cleanHeader(uuid);
    final cleanCookie = _cleanHeader(cookie);

    final uri = Uri.parse(
      'https://vncmes.ces.myfiinet.com/api/cloudmes-report-mes/report/queryInfoList',
    );

    final headers = {
      'Host': 'vncmes.ces.myfiinet.com',
      'Content-Type': 'application/json;charset=UTF-8',
      'Authorization': 'bearer $cleanToken',
      'factoryid': '13',
      'lang': cleanLang,
      'operation-id': cleanOpId,
      'org-code': defaultOrgCode,
      'timezone': '+07:00',
      'uuid': cleanUuid,
      'Cookie': cleanCookie.isNotEmpty
          ? cleanCookie
          : 'CloudMES-token=$cleanToken',
    };

    _logger.info('Querying component info for CSN: $csn');

    final response = await http.post(
      uri,
      headers: headers,
      body: json.encode({
        'pageIndex': 1,
        'pageSize': 100,
        'filedType': filedType,
        'filedValue': csn,
        'orgCode': defaultOrgCode,
      }),
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception(
          'Token expired or unauthorized (401). Please update the token.',
        );
      }
      throw Exception('Server error: ${response.statusCode}');
    }

    final data = json.decode(response.body);

    final code = data['code'];
    final msg = data['msg'] ?? data['message'] ?? '';

    if (code != 200 &&
        code != 0 &&
        code.toString() != '200' &&
        code.toString() != '0') {
      if (code.toString() == '401' || msg.toString().contains('401')) {
        throw Exception(
          'Token expired or unauthorized (401). Please update the token.',
        );
      }
      throw Exception('API Error [$code]: $msg');
    }

    final responseData = data['data'];
    List<dynamic> recordsList = [];
    if (responseData is Map) {
      recordsList = responseData['list'] ?? [];
    } else if (responseData is List) {
      recordsList = responseData;
    }

    return recordsList.map((e) => QueryInfoRecord.fromJson(e)).toList();
  }

  static Future<String?> verifyConnection({
    required String token,
    required String lang,
    required String operationId,
    required String uuid,
    required String cookie,
  }) async {
    try {
      final cleanToken = _cleanHeader(
        token,
      ).replaceFirst(RegExp(r'^[bB][eE][aA][rR][eE][rR]\s+'), '').trim();
      final cleanLang = _cleanHeader(lang);
      final cleanOpId = _cleanHeader(operationId);
      final cleanUuid = _cleanHeader(uuid);
      final cleanCookie = _cleanHeader(cookie);
      final uri = Uri.parse(
        'https://vncmes.ces.myfiinet.com/api/cloudmes-report-mes/equipmentRecord/pageTestRecordLists'
        '?pageIndex=1&pageSize=1&sn=TEST_CONNECTION_SN&orgCode=$defaultOrgCode',
      );

      final headers = {
        'Host': 'vncmes.ces.myfiinet.com',
        'Authorization': 'bearer $cleanToken',
        'factoryid': '13',
        'lang': cleanLang,
        'operation-id': cleanOpId,
        'org-code': defaultOrgCode,
        'timezone': '+07:00',
        'uuid': cleanUuid,
        'Cookie': cleanCookie.isNotEmpty
            ? cleanCookie
            : 'CloudMES-token=$cleanToken',
      };

      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 401) {
        return '401 Unauthorized';
      }

      final data = json.decode(response.body);
      final code = data['code']?.toString();
      if (code == '401' || (data['msg']?.toString().contains('401') ?? false)) {
        return '401 Unauthorized';
      }

      return null;
    } catch (e, stack) {
      _logger.severe('Verify connection failed', e, stack);
      return e.toString();
    }
  }

  static int _uuidSeed = DateTime.now().microsecondsSinceEpoch;

  static String generateUuidV4() {
    int nextByte() {
      _uuidSeed = (_uuidSeed * 1664525 + 1013904223) & 0x7fffffff;
      return (_uuidSeed ^ DateTime.now().microsecondsSinceEpoch) & 0xff;
    }

    final bytes = List<int>.generate(16, (_) => nextByte());
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 1
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final h = bytes.map(hex).toList();
    return '${h[0]}${h[1]}${h[2]}${h[3]}-'
        '${h[4]}${h[5]}-'
        '${h[6]}${h[7]}-'
        '${h[8]}${h[9]}-'
        '${h[10]}${h[11]}${h[12]}${h[13]}${h[14]}${h[15]}';
  }

  static String extractAccountFromJwt(String token) {
    try {
      final cleanToken = _cleanHeader(
        token,
      ).replaceFirst(RegExp(r'^[bB][eE][aA][rR][eE][rR]\s+'), '').trim();
      if (cleanToken.isEmpty) return '';
      final parts = cleanToken.split('.');
      if (parts.length < 2) return '';
      final normalized = base64Url.normalize(parts[1]);
      final payloadStr = utf8.decode(base64Url.decode(normalized));
      final dynamic decoded = json.decode(payloadStr);
      if (decoded is Map<String, dynamic>) {
        final account =
            decoded['user_account'] ??
            decoded['username'] ??
            decoded['account'] ??
            decoded['sub'];
        if (account != null) {
          return account.toString().trim();
        }
      }
    } catch (_) {
      // Ignore malformed or non-JWT tokens
    }
    return '';
  }

  static String _mapMesLang(String appLang) {
    final lower = appLang.trim().toLowerCase();
    if (lower == 'vn' || lower == 'vi') return 'vi';
    if (lower == 'cn' || lower == 'zh' || lower == 'zh-cn') return 'zh-CN';
    if (lower == 'en') return 'en';
    return appLang.trim().isEmpty ? 'vi' : appLang.trim();
  }

  static Future<MesCaptchaData?> fetchCaptcha({
    String lang = 'vi',
    String? uuid,
  }) async {
    try {
      final effectiveUuid = (uuid != null && uuid.trim().isNotEmpty)
          ? _cleanHeader(uuid)
          : generateUuidV4();
      final uri = Uri.parse(
        'https://vncmes.ces.myfiinet.com/api/platform-user/platform/captcha',
      );
      final headers = {
        'Host': 'vncmes.ces.myfiinet.com',
        'Accept': 'application/json, text/plain, */*',
        'Authorization': 'Basic dW5kZWZpbmVkOnVuZGVmaW5lZA==',
        'lang': _mapMesLang(lang),
        'operation-id': '',
        'timezone': '+07:00',
        'uuid': effectiveUuid,
      };
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;
      final dynamic decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        final data = decoded['data'] is Map<String, dynamic>
            ? decoded['data'] as Map<String, dynamic>
            : decoded;
        final key = data['key']?.toString().trim() ?? '';
        final image = data['image']?.toString().trim() ?? '';
        if (key.isNotEmpty && image.isNotEmpty) {
          return MesCaptchaData(key: key, imageBase64: image);
        }
      }
    } catch (e, stack) {
      _logger.warning('Failed to fetch CloudMES captcha', e, stack);
    }
    return null;
  }

  static Future<MesLoginResult> loginWithCredentials({
    required String username,
    required String password,
    String loginMethod = 'SSO',
    String copeCode = 'F_VN',
    String? uuid,
    String lang = 'vi',
    String? captchaKey,
    String? captchaCode,
  }) async {
    final cleanUser = username.trim();
    final cleanMethod = loginMethod.trim().toUpperCase();
    final effectiveUuid = (uuid != null && uuid.trim().isNotEmpty)
        ? _cleanHeader(uuid)
        : generateUuidV4();

    if (cleanUser.isEmpty || password.isEmpty) {
      return MesLoginResult(
        success: false,
        uuid: effectiveUuid,
        username: cleanUser,
        message: 'Username and password are required',
      );
    }

    try {
      final isCloudMes = cleanMethod == 'CLOUDMES';
      final uri = Uri.parse(
        isCloudMes
            ? 'https://vncmes.ces.myfiinet.com/api/platform-user/platform/login'
            : 'https://vncmes.ces.myfiinet.com/api/platform-user/platform/sso/login',
      );

      final Map<String, dynamic> body = isCloudMes
          ? {
              'copeCode': copeCode.trim().isEmpty ? 'F_VN' : copeCode.trim(),
              'username': cleanUser,
              'password': password,
              'loginType': 1,
            }
          : {'type': 'pwd', 'account': cleanUser, 'password': password};

      final headers = <String, String>{
        'Host': 'vncmes.ces.myfiinet.com',
        'Accept': 'application/json, text/plain, */*',
        'Content-Type': 'application/json;charset=UTF-8',
        'Authorization': 'Basic dW5kZWZpbmVkOnVuZGVmaW5lZA==',
        'lang': _mapMesLang(lang),
        'operation-id': '',
        'timezone': '+07:00',
        'uuid': effectiveUuid,
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36',
      };

      if (captchaKey != null && captchaKey.trim().isNotEmpty) {
        headers['Captcha-Key'] = _cleanHeader(captchaKey);
      }
      if (captchaCode != null && captchaCode.trim().isNotEmpty) {
        headers['Captcha-Code'] = _cleanHeader(captchaCode);
      }

      final response = await http
          .post(uri, headers: headers, body: json.encode(body))
          .timeout(const Duration(seconds: 15));

      Map<String, dynamic>? decoded;
      try {
        final raw = json.decode(utf8.decode(response.bodyBytes));
        if (raw is Map<String, dynamic>) {
          decoded = raw;
        }
      } catch (_) {}

      final codeStr = decoded?['code']?.toString() ?? '${response.statusCode}';
      final msg =
          decoded?['msg']?.toString() ??
          decoded?['message']?.toString() ??
          'HTTP ${response.statusCode}';
      final data = decoded?['data'];

      if ((response.statusCode == 200 || codeStr == '200') &&
          codeStr == '200' &&
          data is Map<String, dynamic>) {
        final accessToken = data['accessToken']?.toString().trim() ?? '';
        if (accessToken.isNotEmpty) {
          final jwtUser = extractAccountFromJwt(accessToken);
          final resolvedUser = jwtUser.isNotEmpty ? jwtUser : cleanUser;
          final cookie = 'CloudMES-token=$accessToken';
          return MesLoginResult(
            success: true,
            accessToken: accessToken,
            uuid: effectiveUuid,
            cookie: cookie,
            username: resolvedUser,
            message: msg,
          );
        }
      }

      final lowerMsg = msg.toLowerCase();
      final needsCaptcha =
          isCloudMes &&
          (lowerMsg.contains('captcha') ||
              lowerMsg.contains('xác nhận') ||
              lowerMsg.contains('xác thực') ||
              lowerMsg.contains('验证码'));

      return MesLoginResult(
        success: false,
        uuid: effectiveUuid,
        username: cleanUser,
        message: msg.isNotEmpty ? msg : 'Login failed (code: $codeStr)',
        requiresCaptcha: needsCaptcha,
      );
    } catch (e, stack) {
      _logger.severe('CloudMES direct login failed', e, stack);
      return MesLoginResult(
        success: false,
        uuid: effectiveUuid,
        username: cleanUser,
        message: e.toString(),
      );
    }
  }

  static Future<bool> logoutSession({
    required String token,
    required String uuid,
    required String cookie,
    String lang = 'vi',
  }) async {
    final cleanToken = _cleanHeader(
      token,
    ).replaceFirst(RegExp(r'^[bB][eE][aA][rR][eE][rR]\s+'), '').trim();
    if (cleanToken.isEmpty) return true;

    try {
      final cleanUuid = _cleanHeader(uuid);
      final cleanCookie = _cleanHeader(cookie);
      final uri = Uri.parse(
        'https://vncmes.ces.myfiinet.com/api/platform-user/platform/logout',
      );
      final headers = {
        'Host': 'vncmes.ces.myfiinet.com',
        'Accept': 'application/json, text/plain, */*',
        'Content-Type': 'application/json;charset=UTF-8',
        'Authorization': 'bearer $cleanToken',
        'lang': _mapMesLang(lang),
        'operation-id': '',
        'timezone': '+07:00',
        'uuid': cleanUuid.isNotEmpty ? cleanUuid : generateUuidV4(),
        'Cookie': cleanCookie.isNotEmpty
            ? cleanCookie
            : 'CloudMES-token=$cleanToken',
      };
      final response = await http
          .post(uri, headers: headers)
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      _logger.info('CloudMES logout request finished with notice: $e');
      return false;
    }
  }
}
