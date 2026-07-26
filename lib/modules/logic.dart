import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'api_client.dart';
import 'config_service.dart';
import 'constants.dart';

final _logger = Logger('AppLogic');

class AppLogic extends ChangeNotifier {
  String _token = '';
  String get token => _token;

  String _lang = 'en';
  String get lang => _lang;

  String _operationId = defaultOperationId;
  String get operationId => _operationId;

  String _uuid = 'e1d5e78c-bf60-4aba-9b5f-a94b15cb63d4';
  String get uuid => _uuid;

  String _cookie = 'cultureName=zh-CHS; ClousMES_AccountInfo=eyJjb3BlQ29kZSI6IkZfVk4iLCJsb2dpblR5cGUiOjEsInVzZXJuYW1lIjoiVjE4MDExNzkiLCJwYXNzd29yZCI6IkZveGNvbm4yMDI2MDUiLCJpc1JlbWVtYmVyIjp0cnVlLCJsb2dpbk1ldGhvZCI6IlNTTyJ9';
  String get cookie => _cookie;

  List<String> _snList = [];
  List<String> get snList => _snList;

  Map<String, List<TestRecord>> _results = {};
  Map<String, List<TestRecord>> get results => _results;

  Map<String, bool> _loadingStatus = {};
  Map<String, bool> get loadingStatus => _loadingStatus;

  Map<String, String> _errors = {};
  Map<String, String> get errors => _errors;

  String _selectedSn = '';
  String get selectedSn => _selectedSn;

  bool _isBatchLoading = false;
  bool get isBatchLoading => _isBatchLoading;

  String _globalError = '';
  String get globalError => _globalError;

  bool? isConnectionValid;
  String? connectionError;
  Timer? _validationTimer;

  AppLogic() {
    _init();
  }

  Future<void> _init() async {
    final config = await ConfigService.loadConfig();
    _token = config['token'] ?? '';
    _lang = config['lang'] ?? 'en';
    _operationId = config['operationId'] ?? defaultOperationId;
    _uuid = config['uuid'] ?? defaultUuid;
    _cookie = config['cookie'] ?? '';
    
    if (config['sns'] != null) {
      _snList = List<String>.from(config['sns']);
    }
    
    if (_token.isEmpty) {
      _token = defaultToken;
    }
    if (_snList.isNotEmpty) {
      _selectedSn = _snList.first;
    }
    notifyListeners();
    // Auto-fetch if there are SNs without results
    _fetchPendingSns();
    _startValidationTimer();
  }

  void _startValidationTimer() {
    _validationTimer?.cancel();
    _validateNow();
    _validationTimer = Timer.periodic(const Duration(minutes: 3), (_) => _validateNow());
  }

  Future<void> _validateNow() async {
    final res = await verifySettings(_token, _lang, _operationId, _uuid, _cookie);
    if (res == null) {
      isConnectionValid = true;
      connectionError = null;
    } else {
      isConnectionValid = false;
      connectionError = res;
    }
    notifyListeners();
  }

  Map<String, dynamic> _exportConfigMap() {
    return {
      'token': _token,
      'sns': _snList,
      'lang': _lang,
      'operationId': _operationId,
      'uuid': _uuid,
      'cookie': _cookie,
    };
  }

  void selectSn(String sn) {
    _selectedSn = sn;
    notifyListeners();
  }

  void removeSn(String sn) {
    _snList.remove(sn);
    _results.remove(sn);
    _loadingStatus.remove(sn);
    _errors.remove(sn);
    if (_selectedSn == sn) {
      _selectedSn = _snList.isNotEmpty ? _snList.first : '';
    }
    ConfigService.saveConfig(_exportConfigMap());
    notifyListeners();
  }
  
  void clearAllSns() {
    _snList.clear();
    _results.clear();
    _loadingStatus.clear();
    _errors.clear();
    _selectedSn = '';
    ConfigService.saveConfig(_exportConfigMap());
    notifyListeners();
  }

  void cycleLanguage() {
    if (_lang == 'en') {
      _lang = 'vn';
    } else if (_lang == 'vn') {
      _lang = 'cn';
    } else {
      _lang = 'en';
    }
    ConfigService.saveConfig(_exportConfigMap());
    notifyListeners();
  }

  Future<void> refetchAllSns() async {
    _results.clear();
    _errors.clear();
    _loadingStatus.clear();
    _isBatchLoading = false;
    notifyListeners();
    await _fetchPendingSns();
  }

  Future<void> updateSettings({
    required String token,
    required String lang,
    required String operationId,
    required String uuid,
    required String cookie,
  }) async {
    _token = token;
    _lang = lang;
    _operationId = operationId;
    _uuid = uuid;
    _cookie = cookie;
    await ConfigService.saveConfig(_exportConfigMap());
    _validateNow();
    notifyListeners();
    if (_snList.isNotEmpty) {
      refetchAllSns();
    }
  }

  Future<void> addSns(String input) async {
    final lines = input.split(RegExp(r'[\n\r,;\s]+'));
    bool added = false;
    for (var line in lines) {
      final sn = line.trim().toUpperCase();
      if (sn == 'SN') continue;
      if (sn.isNotEmpty && RegExp(r'^[A-Z0-9_-]+$').hasMatch(sn) && !_snList.contains(sn)) {
        _snList.add(sn);
        added = true;
      }
    }

    if (added) {
      await ConfigService.saveConfig(_exportConfigMap());
      if (_selectedSn.isEmpty) _selectedSn = _snList.last;
      notifyListeners();
      _fetchPendingSns();
    }
  }

  Future<String?> pickFile({bool isSave = false}) async {
    final script = isSave
        ? '''
Add-Type -AssemblyName System.Windows.Forms
\$f = New-Object System.Windows.Forms.SaveFileDialog
\$f.Filter = "CSV Files (*.csv)|*.csv|All Files (*.*)|*.*"
\$f.InitialDirectory = [Environment]::GetFolderPath("Desktop")
if(\$f.ShowDialog() -eq "OK") { Write-Output \$f.FileName }
'''
        : '''
Add-Type -AssemblyName System.Windows.Forms
\$f = New-Object System.Windows.Forms.OpenFileDialog
\$f.Filter = "CSV Files (*.csv)|*.csv|All Files (*.*)|*.*"
\$f.InitialDirectory = [Environment]::GetFolderPath("Desktop")
if(\$f.ShowDialog() -eq "OK") { Write-Output \$f.FileName }
''';

    try {
      final result = await Process.run('powershell', ['-NoProfile', '-STA', '-Command', script]);
      final path = result.stdout.toString().trim();
      if (path.isNotEmpty) {
        return path;
      }
    } catch (e) {
      _logger.severe('Failed to pick file: \$e');
    }
    return null;
  }

  Future<void> downloadTemplateCsv() async {
    _globalError = '';
    notifyListeners();
    try {
      final script = '''
Add-Type -AssemblyName System.Windows.Forms
\$f = New-Object System.Windows.Forms.SaveFileDialog
\$f.Filter = "CSV Files (*.csv)|*.csv"
\$f.FileName = "Template_SN.csv"
\$f.InitialDirectory = [Environment]::GetFolderPath("Desktop")
if(\$f.ShowDialog() -eq "OK") { Write-Output \$f.FileName }
''';
      final result = await Process.run('powershell', ['-NoProfile', '-STA', '-Command', script]);
      final path = result.stdout.toString().trim();
      if (path.isEmpty) return; // User canceled

      final file = File(path.replaceAll('"', '').trim());
      await file.writeAsString('SN\nSN123456\nSN789012\n');
      _globalError = 'Template downloaded successfully to \$path';
    } catch (e) {
      _globalError = 'Error downloading template: \$e';
    }
    notifyListeners();
  }



  Future<void> importCsv() async {
    _globalError = '';
    notifyListeners();
    try {
      final path = await pickFile(isSave: false);
      if (path == null || path.isEmpty) return; // User canceled

      final file = File(path.replaceAll('"', '').trim());
      if (!await file.exists()) {
        _globalError = 'CSV file not found.';
        notifyListeners();
        return;
      }
      final content = await file.readAsString();
      await addSns(content);
    } catch (e) {
      _globalError = 'Error importing CSV: $e';
      notifyListeners();
    }
  }

  Future<void> exportCsv() async {
    _globalError = '';
    notifyListeners();
    try {
      final path = await pickFile(isSave: true);
      if (path == null || path.isEmpty) return; // User canceled

      final file = File(path.replaceAll('"', '').trim());
      final buffer = StringBuffer();
      // Write Header
      buffer.writeln('SN,Internal SN,Customer SN,Product No,Process Code,Line Station Code,Station ID,Error Code,Test Time,Result,Failure Reason,Fail Desc,Host Loc,Product Series,WO,EmpNo');
      
      for (final sn in _snList) {
        final records = _results[sn];
        if (records != null && records.isNotEmpty) {
          for (final r in records) {
            buffer.writeln('${r.sn},${r.internalSn},${r.customerSn},${r.productNo},${r.processCode},${r.lineStationCode},${r.stationId},${r.errCode},${r.testDate},${r.testResult},"${r.failureReason}","${r.failDesc}","${r.loc}",${r.productSeries},${r.woNo},${r.empNo}');
          }
        } else {
          final err = _errors[sn] ?? 'No records / Pending';
          buffer.writeln('$sn,,,,,,,,,,,"$err"');
        }
      }
      
      await file.writeAsString(buffer.toString());
      _globalError = 'Exported successfully to $path';
    } catch (e) {
      _globalError = 'Error exporting CSV: $e';
    }
    notifyListeners();
  }

  Future<void> _fetchPendingSns() async {
    if (_isBatchLoading) return;
    _isBatchLoading = true;
    notifyListeners();

    // Iterate through a copy of the list so modifications during await don't crash
    final currentList = List<String>.from(_snList);
    for (var sn in currentList) {
      if (!_results.containsKey(sn) && _errors[sn] == null) {
        _loadingStatus[sn] = true;
        notifyListeners();

        try {
          final records = await ApiClient.fetchTestRecords(
            sn: sn,
            token: _token,
            lang: _lang,
            operationId: _operationId,
            uuid: _uuid,
            cookie: _cookie,
          );
          _results[sn] = records;
          if (records.isEmpty) {
            _errors[sn] = 'No records found';
          }
        } catch (e) {
          _logger.severe('Failed to fetch records for $sn: $e');
          _errors[sn] = e.toString().replaceFirst('Exception: ', '');
        } finally {
          _loadingStatus[sn] = false;
          notifyListeners();
        }
      }
    }

    _isBatchLoading = false;
    notifyListeners();
  }

  Future<String?> verifySettings(String t, String l, String o, String u, String c) async {
    return await ApiClient.verifyConnection(token: t, lang: l, operationId: o, uuid: u, cookie: c);
  }

  Future<void> fetchSnsData() async {
    _results.clear();
    _errors.clear();
    notifyListeners();
    await _fetchPendingSns();
  }

  Future<void> refreshAll() async {
    _results.clear();
    _errors.clear();
    notifyListeners();
    await _fetchPendingSns();
  }
}
