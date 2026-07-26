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
      testDate: json['lastEditedDt']?.toString() ?? json['createdDt']?.toString() ?? '',
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
    final cleanToken = _cleanHeader(token).replaceFirst(RegExp(r'^[bB][eE][aA][rR][eE][rR]\s+'), '').trim();
    final cleanLang = _cleanHeader(lang);
    final cleanOpId = _cleanHeader(operationId);
    final cleanUuid = _cleanHeader(uuid);
    final cleanCookie = _cleanHeader(cookie);
    
    final uri = Uri.parse(
        'https://vncmes.ces.myfiinet.com/api/cloudmes-report-mes/equipmentRecord/pageTestRecordLists'
        '?pageIndex=1&pageSize=100&productNo=&testStartDate=&processCode=&woNo=&sn=$sn'
        '&stationId=&testTime=&productSeries=&orgCode=$defaultOrgCode');

    final headers = {
      'Host': 'vncmes.ces.myfiinet.com',
      'Authorization': 'bearer $cleanToken',
      'factoryid': '13',
      'lang': cleanLang,
      'operation-id': cleanOpId,
      'org-code': defaultOrgCode,
      'timezone': '+07:00',
      'uuid': cleanUuid,
      'Cookie': cleanCookie.isNotEmpty ? cleanCookie : 'CloudMES-token=$cleanToken',
    };

    _logger.info('Fetching records for SN: $sn');
    
    final response = await http.get(uri, headers: headers);
    
    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        throw Exception('Token expired or unauthorized (401). Please update the token.');
      }
      throw Exception('Server error: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    
    final code = data['code'];
    final msg = data['msg'] ?? data['message'] ?? '';
    
    if (code != 200 && code != 0 && code.toString() != '200' && code.toString() != '0') {
      if (code.toString() == '401' || msg.toString().contains('401')) {
        throw Exception('Token expired or unauthorized (401). Please update the token.');
      }
      throw Exception('API Error [$code]: $msg');
    }

    final responseData = data['data'];
    List<dynamic> recordsList = [];
    if (responseData is Map) {
      recordsList = responseData['list'] ?? responseData['records'] ?? responseData['rows'] ?? [];
    } else if (responseData is List) {
      recordsList = responseData;
    }

    return recordsList.map((e) => TestRecord.fromJson(e)).toList();
  }

  static Future<String?> verifyConnection({
    required String token,
    required String lang,
    required String operationId,
    required String uuid,
    required String cookie,
  }) async {
    try {
      final cleanToken = _cleanHeader(token).replaceFirst(RegExp(r'^[bB][eE][aA][rR][eE][rR]\s+'), '').trim();
      final cleanLang = _cleanHeader(lang);
      final cleanOpId = _cleanHeader(operationId);
      final cleanUuid = _cleanHeader(uuid);
      final cleanCookie = _cleanHeader(cookie);
      final uri = Uri.parse(
          'https://vncmes.ces.myfiinet.com/api/cloudmes-report-mes/equipmentRecord/pageTestRecordLists'
          '?pageIndex=1&pageSize=1&sn=TEST_CONNECTION_SN&orgCode=$defaultOrgCode');

      final headers = {
        'Host': 'vncmes.ces.myfiinet.com',
        'Authorization': 'bearer $cleanToken',
        'factoryid': '13',
        'lang': cleanLang,
        'operation-id': cleanOpId,
        'org-code': defaultOrgCode,
        'timezone': '+07:00',
        'uuid': cleanUuid,
        'Cookie': cleanCookie.isNotEmpty ? cleanCookie : 'CloudMES-token=$cleanToken',
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
