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
  final String testStartDate;
  final String testEndDate;
  final String timeDifferenceValue;
  final String testNo;
  final String testLogPath;
  final String zipFileName;
  final String mbSn;
  final String macGroup;
  final String components;
  final String collectingData;
  final String gitAsnData;
  final String eqpParams;
  final String testItemFailStep;
  final String testItemFailCycle;
  final String testMajorItem;
  final int? qty;
  final int? passQty;
  final int? failQty;
  final int? repassQty;
  final double? fpy;
  final double? lpy;

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
    this.testStartDate = '',
    this.testEndDate = '',
    this.timeDifferenceValue = '',
    this.testNo = '',
    this.testLogPath = '',
    this.zipFileName = '',
    this.mbSn = '',
    this.macGroup = '',
    this.components = '',
    this.collectingData = '',
    this.gitAsnData = '',
    this.eqpParams = '',
    this.testItemFailStep = '',
    this.testItemFailCycle = '',
    this.testMajorItem = '',
    this.qty,
    this.passQty,
    this.failQty,
    this.repassQty,
    this.fpy,
    this.lpy,
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
      testStartDate: json['testStartDate']?.toString() ?? '',
      testEndDate: json['testEndDate']?.toString() ?? '',
      timeDifferenceValue: json['timeDifferenceValue']?.toString() ?? '',
      testNo: json['testNo']?.toString() ?? '',
      testLogPath: json['testLogPath']?.toString() ?? '',
      zipFileName: json['zipFileName']?.toString() ?? '',
      mbSn: json['mbSn']?.toString() ?? '',
      macGroup: json['macGroup']?.toString() ?? '',
      components: json['components']?.toString() ?? '',
      collectingData: json['collectingData']?.toString() ?? '',
      gitAsnData: json['gitAsnData']?.toString() ?? '',
      eqpParams: json['eqpParams']?.toString() ?? '',
      testItemFailStep: json['testItemFailStep']?.toString() ?? '',
      testItemFailCycle: json['testItemFailCycle']?.toString() ?? '',
      testMajorItem: json['testMajorItem']?.toString() ?? '',
      qty: int.tryParse(json['qty']?.toString() ?? ''),
      passQty: int.tryParse(json['passQty']?.toString() ?? ''),
      failQty: int.tryParse(json['failQty']?.toString() ?? ''),
      repassQty: int.tryParse(json['repassQty']?.toString() ?? ''),
      fpy: double.tryParse(json['fpy']?.toString() ?? ''),
      lpy: double.tryParse(json['lpy']?.toString() ?? ''),
    );
  }
}

class SnProcessRecord {
  final int id;
  final String productSn;
  final String internalSn;
  final String customerSn;
  final String lineStation;
  final String landMarkCodes;
  final String currentProcessCode;
  final String currentProcessName;
  final String operateDt;
  final String result;
  final String woNo;
  final String planNo;
  final String productNo;
  final String productVersion;
  final String lineName;
  final String lineCode;
  final String operatorName;
  final String eqpId;
  final String errorCode;
  final String testResultMsg;
  final String remark;
  final int? firstFlag;
  final int? packId;

  SnProcessRecord({
    required this.id,
    required this.productSn,
    required this.internalSn,
    required this.customerSn,
    required this.lineStation,
    this.landMarkCodes = '',
    required this.currentProcessCode,
    required this.currentProcessName,
    required this.operateDt,
    required this.result,
    required this.woNo,
    required this.planNo,
    required this.productNo,
    required this.productVersion,
    required this.lineName,
    required this.lineCode,
    required this.operatorName,
    required this.eqpId,
    required this.errorCode,
    required this.testResultMsg,
    required this.remark,
    this.firstFlag,
    this.packId,
  });

  factory SnProcessRecord.fromJson(Map<String, dynamic> json) {
    final lineN = json['lineName']?.toString() ?? '';
    final lineC = json['lineCode']?.toString() ?? '';
    return SnProcessRecord(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      productSn: json['productSn']?.toString() ?? json['sn']?.toString() ?? '',
      internalSn: json['internalSn']?.toString() ?? '',
      customerSn: json['customerSn']?.toString() ?? '',
      lineStation: json['lineStation']?.toString() ?? '',
      landMarkCodes: json['landMarkCodes']?.toString() ?? '',
      currentProcessCode: json['currentProcessCode']?.toString() ?? '',
      currentProcessName: json['currentProcessName']?.toString() ?? '',
      operateDt: json['operateDt']?.toString() ?? '',
      result: json['result']?.toString() ?? '',
      woNo: json['woNo']?.toString() ?? '',
      planNo: json['planNo']?.toString() ?? '',
      productNo: json['productNo']?.toString() ?? '',
      productVersion: json['productVersion']?.toString() ?? '',
      lineName: lineN.isNotEmpty ? lineN : lineC,
      lineCode: lineC,
      operatorName:
          json['operator']?.toString() ??
          json['operatorName']?.toString() ??
          '',
      eqpId: json['eqpId']?.toString() ?? '',
      errorCode: json['errorCode']?.toString() ?? '',
      testResultMsg: json['testResultMsg']?.toString() ?? '',
      remark: json['remark']?.toString() ?? '',
      firstFlag: int.tryParse(json['firstFlag']?.toString() ?? ''),
      packId: int.tryParse(json['packId']?.toString() ?? ''),
    );
  }
}

class WipComponentRecord {
  final int wipProductComponentId;
  final String productSn;
  final String internalSn;
  final String customerSn;
  final String materialNo;
  final String materialCategory;
  final String mfgName;
  final String mfgPn;
  final String dateCode;
  final String scannedCsn;
  final String parsedCsn;
  final String pkgId;
  final String stationCode;
  final String processCode;
  final String scanType;
  final String installedQty;
  final String creator;
  final String createdDt;
  final String unlinkTime;
  final String checkAssembledCode;
  final String location;
  final String materialNameValue;

  WipComponentRecord({
    required this.wipProductComponentId,
    this.productSn = '',
    this.internalSn = '',
    this.customerSn = '',
    required this.materialNo,
    required this.materialCategory,
    required this.mfgName,
    required this.mfgPn,
    required this.dateCode,
    required this.scannedCsn,
    this.parsedCsn = '',
    required this.pkgId,
    required this.stationCode,
    required this.processCode,
    this.scanType = '',
    required this.installedQty,
    required this.creator,
    required this.createdDt,
    this.unlinkTime = '',
    this.checkAssembledCode = '',
    this.location = '',
    this.materialNameValue = '',
  });

  String get materialName =>
      materialNameValue.isNotEmpty ? materialNameValue : mfgPn;
  String get mfg => mfgName;

  factory WipComponentRecord.fromJson(Map<String, dynamic> json) {
    return WipComponentRecord(
      wipProductComponentId:
          int.tryParse(json['wipProductComponentId']?.toString() ?? '') ??
          int.tryParse(json['id']?.toString() ?? '') ??
          0,
      productSn: json['productSn']?.toString() ?? json['sn']?.toString() ?? '',
      internalSn: json['internalSn']?.toString() ?? '',
      customerSn: json['customerSn']?.toString() ?? '',
      materialNo: json['materialNo']?.toString() ?? '',
      materialCategory: json['materialCategory']?.toString() ?? '',
      mfgName: json['mfgName']?.toString() ?? '',
      mfgPn: json['mfgPn']?.toString() ?? '',
      dateCode: json['dateCode']?.toString() ?? '',
      scannedCsn: json['scannedCsn']?.toString() ?? '',
      parsedCsn: json['parsedCsn']?.toString() ?? '',
      pkgId: json['pkgId']?.toString() ?? '',
      stationCode: json['stationCode']?.toString() ?? '',
      processCode: json['processCode']?.toString() ?? '',
      scanType: json['scanType']?.toString() ?? '',
      installedQty: json['installedQty']?.toString() ?? '',
      creator: json['creator']?.toString() ?? '',
      createdDt: json['createdDt']?.toString() ?? '',
      unlinkTime: json['unlinkTime']?.toString() ?? '',
      checkAssembledCode:
          json['checkAssembledCode']?.toString() ??
          json['checkAssembled']?.toString() ??
          '',
      location: json['location']?.toString() ?? '',
      materialNameValue: json['materialName']?.toString() ?? '',
    );
  }
}

class ComponentParamRecord {
  final String macParam;
  final String macType;
  final String macValue;
  final String parsedCsn;
  final String createdDt;

  const ComponentParamRecord({
    required this.macParam,
    required this.macType,
    required this.macValue,
    required this.parsedCsn,
    required this.createdDt,
  });

  factory ComponentParamRecord.fromJson(Map<String, dynamic> json) {
    return ComponentParamRecord(
      macParam: json['macParam']?.toString() ?? '',
      macType: json['macType']?.toString() ?? '',
      macValue: json['macValue']?.toString() ?? '',
      parsedCsn: json['parsedCsn']?.toString() ?? '',
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
  final String createdDt;
  final String lastEditedDt;
  final String lastEditor;

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
    this.createdDt = '',
    this.lastEditedDt = '',
    this.lastEditor = '',
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
      createdDt: json['createdDt']?.toString() ?? '',
      lastEditedDt: json['lastEditedDt']?.toString() ?? '',
      lastEditor: json['lastEditor']?.toString() ?? '',
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

class TestRecordPage {
  final List<TestRecord> records;
  final int pageIndex;
  final int pageSize;
  final int? totalCount;

  const TestRecordPage({
    required this.records,
    required this.pageIndex,
    required this.pageSize,
    this.totalCount,
  });

  bool get hasNext => totalCount == null
      ? records.length >= pageSize
      : pageIndex * pageSize < totalCount!;
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
}
