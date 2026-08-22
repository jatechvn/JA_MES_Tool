import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'constants.dart';

final _logger = Logger('ApiClient');

String _cleanHeader(String value) {
  String clean = value.replaceAll('\r', '').replaceAll('\n', '').trim();
  if (clean.startsWith('"') && clean.endsWith('"')) {
    clean = clean.substring(1, clean.length - 1).trim();
  }
  return clean;
}

class TestRecord {
  final String sn;
  final String internalSn;
  final String customerSn;
  final String productNo;
  final String processCode;
  final String lineStationCode;
  final String stationId;
  final String errCode;
  final String failureReason;
  final String failDesc;
  final String loc;
  final String productSeries;
  final String testTime; // count
  final String testResult;
  final String woNo;
  final String empNo;
  final String testDate;

  TestRecord({
    required this.sn,
    required this.internalSn,
    required this.customerSn,
    required this.productNo,
    required this.processCode,
    required this.lineStationCode,
    required this.stationId,
    required this.errCode,
    required this.failureReason,
    required this.failDesc,
    required this.loc,
    required this.productSeries,
    required this.testTime,
    required this.testResult,
    required this.woNo,
    required this.empNo,
    required this.testDate,
  });

  factory TestRecord.fromJson(Map<String, dynamic> json) {
    return TestRecord(
      sn: json['sn']?.toString() ?? '',
      internalSn: json['internalSn']?.toString() ?? '',
      customerSn: json['customerSn']?.toString() ?? '',
      productNo: json['productNo']?.toString() ?? '',
      processCode: json['processCode']?.toString() ?? '',
      lineStationCode: json['lineStationCode']?.toString() ?? '',
      stationId: json['stationId']?.toString() ?? '',
      errCode: json['errCode']?.toString() ?? '',
      failureReason: json['failureReason']?.toString() ?? '',
      failDesc: json['failDesc']?.toString() ?? '',
      loc: json['loc']?.toString() ?? '',
      productSeries: json['productSeries']?.toString() ?? '',
      testTime: json['testTime']?.toString() ?? '',
      testResult: json['result']?.toString() ?? '',
      woNo: json['woNo']?.toString() ?? '',
      empNo: json['empNo']?.toString() ?? '',
      testDate:
          json['lastEditedDt']?.toString() ??
          json['createdDt']?.toString() ??
          '',
    );
  }
}

class SnProcessRecord {
  final int id;
  final String productSn;
  final String customerSn;
  final String lineStation;
  final String currentProcessCode;
  final String currentProcessName;
  final String operateDt;
  final String result;
  final String woNo;
  final String productNo;
  final String productVersion;
  final String lineName;
  final String operatorName;
  final String eqpId;
  final String errorCode;
  final String testResultMsg;

  SnProcessRecord({
    required this.id,
    required this.productSn,
    required this.customerSn,
    required this.lineStation,
    required this.currentProcessCode,
    required this.currentProcessName,
    required this.operateDt,
    required this.result,
    required this.woNo,
    required this.productNo,
    required this.productVersion,
    required this.lineName,
    required this.operatorName,
    required this.eqpId,
    required this.errorCode,
    required this.testResultMsg,
  });

  factory SnProcessRecord.fromJson(Map<String, dynamic> json) {
    return SnProcessRecord(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      productSn: json['productSn']?.toString() ?? '',
      customerSn: json['customerSn']?.toString() ?? '',
      lineStation: json['lineStation']?.toString() ?? '',
      currentProcessCode: json['currentProcessCode']?.toString() ?? '',
      currentProcessName: json['currentProcessName']?.toString() ?? '',
      operateDt: json['operateDt']?.toString() ?? '',
      result: json['result']?.toString() ?? '',
      woNo: json['woNo']?.toString() ?? '',
      productNo: json['productNo']?.toString() ?? '',
      productVersion: json['productVersion']?.toString() ?? '',
      lineName: json['lineName']?.toString() ?? '',
      operatorName: json['operator']?.toString() ?? '',
      eqpId: json['eqpId']?.toString() ?? '',
      errorCode: json['errorCode']?.toString() ?? '',
      testResultMsg: json['testResultMsg']?.toString() ?? '',
    );
  }
}

class WipComponentRecord {
  final int wipProductComponentId;
  final String materialNo;
  final String materialCategory;
  final String mfgName;
  final String mfgPn;
  final String dateCode;
  final String scannedCsn;
  final String pkgId;
  final String stationCode;
  final String processCode;
  final String installedQty;
  final String creator;
  final String createdDt;

  WipComponentRecord({
    required this.wipProductComponentId,
    required this.materialNo,
    required this.materialCategory,
    required this.mfgName,
    required this.mfgPn,
    required this.dateCode,
    required this.scannedCsn,
    required this.pkgId,
    required this.stationCode,
    required this.processCode,
    required this.installedQty,
    required this.creator,
    required this.createdDt,
  });

  factory WipComponentRecord.fromJson(Map<String, dynamic> json) {
    return WipComponentRecord(
      wipProductComponentId:
          int.tryParse(json['wipProductComponentId']?.toString() ?? '') ?? 0,
      materialNo: json['materialNo']?.toString() ?? '',
      materialCategory: json['materialCategory']?.toString() ?? '',
      mfgName: json['mfgName']?.toString() ?? '',
      mfgPn: json['mfgPn']?.toString() ?? '',
      dateCode: json['dateCode']?.toString() ?? '',
      scannedCsn: json['scannedCsn']?.toString() ?? '',
      pkgId: json['pkgId']?.toString() ?? '',
      stationCode: json['stationCode']?.toString() ?? '',
      processCode: json['processCode']?.toString() ?? '',
      installedQty: json['installedQty']?.toString() ?? '',
      creator: json['creator']?.toString() ?? '',
      createdDt: json['createdDt']?.toString() ?? '',
    );
  }
}

/// Result of resolving an arbitrary scanned/typed SN (internal SN, customer
/// SN, or product SN) to its canonical top-level product SN. Test Record,
/// Barcode History, and Component List all require the canonical `sn` — they
/// don't accept internal/customer SN aliases themselves, so this lookup must
/// run first (mirrors what the MES web frontend does before those calls).
class SnMasterInfo {
  final String sn;
  final String productNo;
  final String productName;
  final String productVersion;
  final String woNo;
  final String lineCode;
  final String lineName;
  final String currentProcessCode;
  final String currentProcessName;
  final String nextProcessCode;
  final String nextProcessName;
  final String errorCode;
  final String routeCode;
  final String routeName;
  final String productStatus;

  SnMasterInfo({
    required this.sn,
    required this.productNo,
    required this.productName,
    required this.productVersion,
    required this.woNo,
    required this.lineCode,
    required this.lineName,
    required this.currentProcessCode,
    required this.currentProcessName,
    required this.nextProcessCode,
    required this.nextProcessName,
    required this.errorCode,
    required this.routeCode,
    required this.routeName,
    required this.productStatus,
  });

  factory SnMasterInfo.fromJson(Map<String, dynamic> json) {
    return SnMasterInfo(
      sn: json['sn']?.toString() ?? '',
      productNo: json['productNo']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      productVersion: json['productVersion']?.toString() ?? '',
      woNo: json['woNo']?.toString() ?? '',
      lineCode: json['lineCode']?.toString() ?? '',
      lineName: json['lineName']?.toString() ?? '',
      currentProcessCode: json['currentProcessCode']?.toString() ?? '',
      currentProcessName: json['currentProcessName']?.toString() ?? '',
      nextProcessCode: json['nextProcessCode']?.toString() ?? '',
      nextProcessName: json['nextProcessName']?.toString() ?? '',
      errorCode: json['errorCode']?.toString() ?? '',
      routeCode: json['routeCode']?.toString() ?? '',
      routeName: json['routeName']?.toString() ?? '',
      productStatus: json['productStatus']?.toString() ?? '',
    );
  }
}

/// Result of a reverse component lookup: given a scanned/typed component
/// serial (e.g. a mainboard CSN), returns which product SN it is currently
/// installed into plus its material/traceability detail. Unlike
/// [SnMasterInfo] and the other record types, the input here is a
/// *component* identifier, not necessarily a top-level product SN.
class QueryInfoRecord {
  final String productSn;
  final String mac;
  final String productNo;
  final String snMasterId;
  final String productSeriesCode;
  final String productSeriesName;
  final String customerMaterialCode;
  final String materialName;
  final String customerMaterialVersion;
  final String woNo;
  final String lineCode;
  final String createdDt;
  final String materialNo;
  final String customerMaterialNo;
  final String materialVersion;
  final String scannedCsn;
  final String parsedCsn;
  final String checkAssembled;
  final String processCode;
  final String mfgName;
  final String mfgPn;
  final String materialCategory;
  final String installedQty;
  final String scanType;

  QueryInfoRecord({
    required this.productSn,
    required this.mac,
    required this.productNo,
    required this.snMasterId,
    required this.productSeriesCode,
    required this.productSeriesName,
    required this.customerMaterialCode,
    required this.materialName,
    required this.customerMaterialVersion,
    required this.woNo,
    required this.lineCode,
    required this.createdDt,
    required this.materialNo,
    required this.customerMaterialNo,
    required this.materialVersion,
    required this.scannedCsn,
    required this.parsedCsn,
    required this.checkAssembled,
    required this.processCode,
    required this.mfgName,
    required this.mfgPn,
    required this.materialCategory,
    required this.installedQty,
    required this.scanType,
  });

  factory QueryInfoRecord.fromJson(Map<String, dynamic> json) {
    return QueryInfoRecord(
      productSn: json['productSn']?.toString() ?? '',
      mac: json['mac']?.toString() ?? '',
      productNo: json['productNo']?.toString() ?? '',
      snMasterId: json['snMasterId']?.toString() ?? '',
      productSeriesCode: json['productSeriesCode']?.toString() ?? '',
      productSeriesName: json['productSeriesName']?.toString() ?? '',
      customerMaterialCode: json['customerMaterialCode']?.toString() ?? '',
      materialName: json['materialName']?.toString() ?? '',
      customerMaterialVersion:
          json['customerMaterialVersion']?.toString() ?? '',
      woNo: json['woNo']?.toString() ?? '',
      lineCode: json['lineCode']?.toString() ?? '',
      createdDt: json['createdDt']?.toString() ?? '',
      materialNo: json['materialNo']?.toString() ?? '',
      customerMaterialNo: json['customerMaterialNo']?.toString() ?? '',
      materialVersion: json['materialVersion']?.toString() ?? '',
      scannedCsn: json['scannedCsn']?.toString() ?? '',
      parsedCsn: json['parsedCsn']?.toString() ?? '',
      checkAssembled: json['checkAssembled']?.toString() ?? '',
      processCode: json['processCode']?.toString() ?? '',
      mfgName: json['mfgName']?.toString() ?? '',
      mfgPn: json['mfgPn']?.toString() ?? '',
      materialCategory: json['materialCategory']?.toString() ?? '',
      installedQty: json['installedQty']?.toString() ?? '',
      scanType: json['scanType']?.toString() ?? '',
    );
  }
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
    final cleanToken = _cleanHeader(
      token,
    ).replaceFirst(RegExp(r'^[bB][eE][aA][rR][eE][rR]\s+'), '').trim();
    final cleanLang = _cleanHeader(lang);
    final cleanOpId = _cleanHeader(operationId);
    final cleanUuid = _cleanHeader(uuid);
    final cleanCookie = _cleanHeader(cookie);

    final uri = Uri.parse(
      'https://vncmes.ces.myfiinet.com/api/cloudmes-report-mes/equipmentRecord/pageTestRecordLists'
      '?pageIndex=1&pageSize=100&productNo=&testStartDate=&processCode=&woNo=&sn=$sn'
      '&stationId=&testTime=&productSeries=&orgCode=$defaultOrgCode',
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

    _logger.info('Fetching records for SN: $sn');

    final response = await http.get(uri, headers: headers);

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

    return recordsList.map((e) => TestRecord.fromJson(e)).toList();
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
}
