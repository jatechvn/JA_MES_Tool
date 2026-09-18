import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'api_client.dart';
import 'config_service.dart';
import 'constants.dart';
import 'query_queue.dart';

final _logger = Logger('AppLogic');

enum ViewMode {
  testRecord,
  barcodeHistory,
  wipComponents,
  componentTrace,
  terminal,
}

enum SnDataStatus { normal, warning, error }

/// Encodes one value according to RFC 4180-style CSV rules.
///
/// Always quoting values keeps exports valid when MES data contains commas,
/// quotes, or line breaks, while preserving empty values as empty fields.
String csvField(Object? value) {
  final text = value?.toString() ?? '';
  if (text.isEmpty) return '';
  return '"${text.replaceAll('"', '""')}"';
}

bool shouldFallbackToBarcodeHistory({
  required bool recordsAreEmpty,
  String? error,
}) {
  if (recordsAreEmpty) return true;
  return error?.toLowerCase().contains('no records found') ?? false;
}

String defaultLanguageForPlatformLocale(String localeName) {
  final normalized = localeName.toLowerCase().replaceAll('_', '-');
  if (normalized.startsWith('vi') || normalized.startsWith('vn')) {
    return 'vn';
  }
  if (normalized.startsWith('zh') || normalized.startsWith('cn')) {
    return 'cn';
  }
  return 'en';
}

String initialLanguage({
  required Object? configuredLang,
  required bool hasConfiguredLanguage,
  required String platformLocaleName,
}) {
  final lang = configuredLang?.toString();
  if (hasConfiguredLanguage && ['en', 'vn', 'cn'].contains(lang)) {
    return lang!;
  }
  return defaultLanguageForPlatformLocale(platformLocaleName);
}

bool shouldAutoSwitchToBarcodeHistory({
  required String selectedSn,
  required String candidateSn,
  required ViewMode viewMode,
  required bool hasNoTestRecordData,
  required bool fallbackAllowed,
}) {
  return fallbackAllowed &&
      selectedSn == candidateSn &&
      viewMode == ViewMode.testRecord &&
      hasNoTestRecordData;
}

SnDataStatus snDataStatusForViews({
  required bool hasNoTestRecordData,
  required bool hasBarcodeHistoryData,
  required bool hasComponentData,
  required bool relatedViewsResolved,
}) {
  if (!hasNoTestRecordData) return SnDataStatus.normal;
  if (hasBarcodeHistoryData || hasComponentData) {
    return SnDataStatus.warning;
  }
  return relatedViewsResolved ? SnDataStatus.error : SnDataStatus.normal;
}

class AppLogic extends ChangeNotifier {
  ViewMode _viewMode = ViewMode.testRecord;
  ViewMode get viewMode => _viewMode;

  final Map<String, List<SnProcessRecord>> _processResults = {};
  Map<String, List<SnProcessRecord>> get processResults => _processResults;

  final Map<String, bool> _processLoadingStatus = {};
  Map<String, bool> get processLoadingStatus => _processLoadingStatus;

  final Map<String, String> _processErrors = {};
  Map<String, String> get processErrors => _processErrors;

  final Map<String, List<WipComponentRecord>> _wipResults = {};
  Map<String, List<WipComponentRecord>> get wipResults => _wipResults;

  final Map<String, bool> _wipLoadingStatus = {};
  Map<String, bool> get wipLoadingStatus => _wipLoadingStatus;

  final Map<String, String> _wipErrors = {};
  Map<String, String> get wipErrors => _wipErrors;

  // Component Trace: a standalone reverse lookup (scanned component CSN ->
  // product SN it's installed into). Unrelated to the SN queue above — it
  // has its own history of searched CSNs (shown in the sidebar in place of
  // the SN queue while this tab is active), each with its own cached
  // result set, since the input identifier space is different (component,
  // not product SN).
  final List<String> _traceHistory = [];
  List<String> get traceHistory => _traceHistory;

  final Map<String, List<QueryInfoRecord>> _traceResults = {};
  Map<String, List<QueryInfoRecord>> get traceResults => _traceResults;

  final Map<String, bool> _traceLoadingStatus = {};
  Map<String, bool> get traceLoadingStatus => _traceLoadingStatus;

  final Map<String, String> _traceErrors = {};
  Map<String, String> get traceErrors => _traceErrors;

  String _selectedTraceCsn = '';
  String get selectedTraceCsn => _selectedTraceCsn;

  // Maps the SN string the user typed (internal SN, customer SN, or product
  // SN) to its resolved canonical product SN + master info. Test Record,
  // Barcode History, and Component List all require the canonical SN, so
  // this resolution runs once per typed SN before the first detail fetch.
  final Map<String, String> _resolvedSn = {};
  final Map<String, SnMasterInfo> _snMasterInfo = {};
  Map<String, SnMasterInfo> get snMasterInfo => _snMasterInfo;
  String? resolvedSnFor(String sn) => _resolvedSn[sn];

  String _token = '';
  String get token => _token;

  String _lang = 'en';
  String get lang => _lang;

  String _operationId = defaultOperationId;
  String get operationId => _operationId;

  String _uuid = defaultUuid;
  String get uuid => _uuid;

  String _cookie = '';
  String get cookie => _cookie;

  // Glassmorphism controls, matching the JA_Compare reference app's
  // Advanced Settings layout (Main background blur/opacity + Dialog
  // blur/opacity). bgBlur/bgOpacity are persisted for parity but not yet
  // wired to any visual surface — same as in JA_Compare itself, whose main
  // window doesn't consume them either. dialogBlur/dialogOpacity drive the
  // Sort dropdown's glass panel; modal dialogs themselves stay solid opaque
  // (see CHANGELOG v2.1.0: transparency there previously caused see-through
  // overlapping text glitches).
  double _bgBlur = 20.0;
  double get bgBlur => _bgBlur;

  double _bgOpacity = 0.25;
  double get bgOpacity => _bgOpacity;

  double _dialogBlur = 20.0;
  double get dialogBlur => _dialogBlur;

  double _dialogOpacity = 0.85;
  double get dialogOpacity => _dialogOpacity;

  double _dropdownBlur = 20.0;
  double get dropdownBlur => _dropdownBlur;

  double _dropdownOpacity = 0.86;
  double get dropdownOpacity => _dropdownOpacity;

  void setLiveGlassmorphism({
    double? bgBlur,
    double? bgOpacity,
    double? dialogBlur,
    double? dialogOpacity,
    double? dropdownBlur,
    double? dropdownOpacity,
  }) {
    if (bgBlur != null) _bgBlur = bgBlur;
    if (bgOpacity != null) _bgOpacity = bgOpacity;
    if (dialogBlur != null) _dialogBlur = dialogBlur;
    if (dialogOpacity != null) _dialogOpacity = dialogOpacity;
    if (dropdownBlur != null) _dropdownBlur = dropdownBlur;
    if (dropdownOpacity != null) _dropdownOpacity = dropdownOpacity;
    notifyListeners();
  }

  List<String> _snList = [];
  List<String> get snList => _snList;

  final Map<String, List<TestRecord>> _results = {};
  Map<String, List<TestRecord>> get results => _results;

  final Map<String, bool> _loadingStatus = {};
  Map<String, bool> get loadingStatus => _loadingStatus;

  final Map<String, String> _errors = {};
  Map<String, String> get errors => _errors;

  String _selectedSn = '';
  String get selectedSn => _selectedSn;

  bool get isBatchLoading => _loadingStatus.values.any((value) => value);

  String _globalError = '';
  String get globalError => _globalError;

  bool? isConnectionValid;
  String? connectionError;
  Timer? _validationTimer;
  final Set<String> _testRecordFallbackEligibleSns = {};

  final QueryQueue _queue;
  final Map<String, int> _revisions = {};
  final Map<Object, Future<String>> _resolving = {};
  bool _disposed = false;
  int _credentialsRevision = 0;
  final Future<void> Function(Map<String, dynamic>) _saveConfig;

  AppLogic({
    bool initialize = true,
    int queryConcurrency = 6,
    Future<void> Function(Map<String, dynamic>)? saveConfig,
  }) : _queue = QueryQueue(concurrency: queryConcurrency),
       _saveConfig = saveConfig ?? ConfigService.saveConfig {
    if (initialize) _init();
  }

  int _revision(String key) => _revisions[key] ?? 0;

  Future<void> get queriesIdle => _queue.idle;

  void _invalidate(String key) {
    _revisions[key] = _revision(key) + 1;
  }

  void _invalidateAll({bool includeTrace = false}) {
    _resolvedSn.clear();
    _snMasterInfo.clear();
    for (final sn in _snList) {
      _invalidate('sn:$sn');
    }
    if (includeTrace) {
      for (final csn in _traceHistory) {
        _invalidate('csn:$csn');
      }
      _traceResults.clear();
      _traceErrors.clear();
      _traceLoadingStatus.clear();
    }
    _loadingStatus.clear();
    _processLoadingStatus.clear();
    _wipLoadingStatus.clear();
  }

  @override
  void dispose() {
    _disposed = true;
    _validationTimer?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  double _parseDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    return fallback;
  }

  Future<void> _init() async {
    final config = await ConfigService.loadConfig();
    if (_disposed) return;
    _token = config['token'] ?? '';
    _lang = initialLanguage(
      configuredLang: config['lang'],
      hasConfiguredLanguage: config['hasConfiguredLang'] == true,
      platformLocaleName: Platform.localeName,
    );
    _operationId = config['operationId'] ?? defaultOperationId;
    _uuid = config['uuid'] ?? defaultUuid;
    _cookie = config['cookie'] ?? '';
    _bgBlur = _parseDouble(config['bgBlur'], 20.0);
    _bgOpacity = _parseDouble(config['bgOpacity'], 0.25);
    _dialogBlur = _parseDouble(config['dialogBlur'], 20.0);
    _dialogOpacity = _parseDouble(config['dialogOpacity'], 0.85);
    _dropdownBlur = _parseDouble(config['dropdownBlur'], 20.0);
    _dropdownOpacity = _parseDouble(config['dropdownOpacity'], 0.86);

    if (config['sns'] != null) {
      _snList = List<String>.from(config['sns']);
    }
    if (config['traceCsns'] != null) {
      _traceHistory.addAll(List<String>.from(config['traceCsns']));
    }

    if (_token.isEmpty) {
      _token = defaultToken;
    }
    if (_snList.isNotEmpty) {
      _selectedSn = _snList.first;
    }
    if (_traceHistory.isNotEmpty) {
      _selectedTraceCsn = _traceHistory.first;
    }
    _enableTestRecordFallbackFor(_snList);
    notifyListeners();
    // Auto-fetch all 3 SN data views + the saved Component Trace history, so
    // switching tabs never has to wait — not just the currently active view.
    _fetchAllPending();
    _startValidationTimer();
  }

  /// Kicks off the Test Record, Barcode History, Component List, and
  /// Component Trace fetches concurrently, so all 4 tabs are ready before
  /// the user clicks into them instead of loading lazily on tab switch.
  Future<void> _fetchAllPending() {
    return Future.wait([
      _fetchPendingSns(),
      _fetchPendingProcessHistory(),
      _fetchPendingWipComponents(),
      Future.wait(
        List<String>.of(_traceHistory)
            .where(
              (csn) =>
                  !_traceResults.containsKey(csn) &&
                  !_traceErrors.containsKey(csn),
            )
            .map(_fetchTrace),
      ),
    ]);
  }

  void _startValidationTimer() {
    _validationTimer?.cancel();
    _validateNow();
    _validationTimer = Timer.periodic(
      const Duration(minutes: 3),
      (_) => _validateNow(),
    );
  }

  Future<void> _validateNow() async {
    final revision = _credentialsRevision;
    final res = await verifySettings(
      _token,
      _lang,
      _operationId,
      _uuid,
      _cookie,
    );
    if (_disposed || revision != _credentialsRevision) return;
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
      'traceCsns': _traceHistory,
      'lang': _lang,
      'operationId': _operationId,
      'uuid': _uuid,
      'cookie': _cookie,
      'bgBlur': _bgBlur,
      'bgOpacity': _bgOpacity,
      'dialogBlur': _dialogBlur,
      'dialogOpacity': _dialogOpacity,
      'dropdownBlur': _dropdownBlur,
      'dropdownOpacity': _dropdownOpacity,
    };
  }

  void selectSn(String sn) {
    _selectedSn = sn;
    notifyListeners();
    if (_viewMode == ViewMode.barcodeHistory) {
      _fetchPendingProcessHistory();
    } else if (_viewMode == ViewMode.wipComponents) {
      _fetchPendingWipComponents();
    }
  }

  void setViewMode(ViewMode mode) {
    if (_viewMode == mode) return;
    _viewMode = mode;
    notifyListeners();
    if (mode == ViewMode.barcodeHistory) {
      _fetchPendingProcessHistory();
    } else if (mode == ViewMode.wipComponents) {
      _fetchPendingWipComponents();
    }
  }

  void removeSn(String sn) {
    _invalidate('sn:$sn');
    _snList.remove(sn);
    _results.remove(sn);
    _loadingStatus.remove(sn);
    _errors.remove(sn);
    _processResults.remove(sn);
    _processLoadingStatus.remove(sn);
    _processErrors.remove(sn);
    _wipResults.remove(sn);
    _wipLoadingStatus.remove(sn);
    _wipErrors.remove(sn);
    _resolvedSn.remove(sn);
    _snMasterInfo.remove(sn);
    _testRecordFallbackEligibleSns.remove(sn);
    if (_selectedSn == sn) {
      _selectedSn = _snList.isNotEmpty ? _snList.first : '';
    }
    _saveConfig(_exportConfigMap());
    notifyListeners();
  }

  /// Clears cached data for a single SN (all 3 views + its resolved-SN
  /// cache) and re-fetches it, without needing to remove/re-add the SN or
  /// restart the app.
  Future<void> refreshSn(String sn) async {
    _invalidate('sn:$sn');
    _testRecordFallbackEligibleSns.remove(sn);
    _results.remove(sn);
    _errors.remove(sn);
    _loadingStatus.remove(sn);
    _processResults.remove(sn);
    _processErrors.remove(sn);
    _processLoadingStatus.remove(sn);
    _wipResults.remove(sn);
    _wipErrors.remove(sn);
    _wipLoadingStatus.remove(sn);
    _resolvedSn.remove(sn);
    _snMasterInfo.remove(sn);
    if (_viewMode == ViewMode.testRecord) {
      _enableTestRecordFallbackFor([sn]);
    }
    notifyListeners();
    await _fetchAllPending();
  }

  void clearAllSns() {
    _invalidateAll();
    _snList.clear();
    _results.clear();
    _loadingStatus.clear();
    _errors.clear();
    _processResults.clear();
    _processLoadingStatus.clear();
    _processErrors.clear();
    _wipResults.clear();
    _wipLoadingStatus.clear();
    _wipErrors.clear();
    _resolvedSn.clear();
    _snMasterInfo.clear();
    _selectedSn = '';
    _testRecordFallbackEligibleSns.clear();
    _saveConfig(_exportConfigMap());
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
    _saveConfig(_exportConfigMap());
    notifyListeners();
  }

  void setLanguage(String lang) {
    if (['en', 'vn', 'cn'].contains(lang)) {
      _lang = lang;
      _saveConfig(_exportConfigMap());
      notifyListeners();
    }
  }

  Future<void> refetchAllSns({bool allowTestRecordFallback = true}) async {
    _invalidateAll(includeTrace: true);
    _results.clear();
    _errors.clear();
    _loadingStatus.clear();
    _processResults.clear();
    _processErrors.clear();
    _processLoadingStatus.clear();
    _wipResults.clear();
    _wipErrors.clear();
    _wipLoadingStatus.clear();
    _resolvedSn.clear();
    _snMasterInfo.clear();
    _testRecordFallbackEligibleSns.clear();
    if (allowTestRecordFallback && _viewMode == ViewMode.testRecord) {
      _enableTestRecordFallbackFor(_snList);
    }
    notifyListeners();
    await _fetchAllPending();
  }

  Future<void> updateCredentials({
    required String token,
    required String uuid,
    required String operationId,
    required String cookie,
  }) async {
    final revision = ++_credentialsRevision;
    _invalidateAll(includeTrace: true);
    _token = token;
    _uuid = uuid;
    _operationId = operationId;
    _cookie = cookie;
    await _saveConfig(_exportConfigMap());
    if (_disposed || revision != _credentialsRevision) return;
    await _validateNow();
    if (_disposed || revision != _credentialsRevision) return;
    notifyListeners();
    if (_snList.isNotEmpty || _traceHistory.isNotEmpty) {
      refetchAllSns(allowTestRecordFallback: false);
    }
  }

  Future<void> saveFullSettings({
    required String token,
    required String operationId,
    required String uuid,
    required String cookie,
    double? bgBlur,
    double? bgOpacity,
    double? dialogBlur,
    double? dialogOpacity,
    double? dropdownBlur,
    double? dropdownOpacity,
  }) async {
    await updateSettings(
      token: token,
      lang: _lang,
      operationId: operationId,
      uuid: uuid,
      cookie: cookie,
      bgBlur: bgBlur,
      bgOpacity: bgOpacity,
      dialogBlur: dialogBlur,
      dialogOpacity: dialogOpacity,
      dropdownBlur: dropdownBlur,
      dropdownOpacity: dropdownOpacity,
    );
  }

  Future<void> updateSettings({
    required String token,
    required String lang,
    required String operationId,
    required String uuid,
    required String cookie,
    double? bgBlur,
    double? bgOpacity,
    double? dialogBlur,
    double? dialogOpacity,
    double? dropdownBlur,
    double? dropdownOpacity,
  }) async {
    final revision = ++_credentialsRevision;
    _invalidateAll(includeTrace: true);
    _token = token;
    _lang = lang;
    _operationId = operationId;
    _uuid = uuid;
    _cookie = cookie;
    if (bgBlur != null) _bgBlur = bgBlur;
    if (bgOpacity != null) _bgOpacity = bgOpacity;
    if (dialogBlur != null) _dialogBlur = dialogBlur;
    if (dialogOpacity != null) _dialogOpacity = dialogOpacity;
    if (dropdownBlur != null) _dropdownBlur = dropdownBlur;
    if (dropdownOpacity != null) _dropdownOpacity = dropdownOpacity;
    await _saveConfig(_exportConfigMap());
    if (_disposed || revision != _credentialsRevision) return;
    await _validateNow();
    if (_disposed || revision != _credentialsRevision) return;
    notifyListeners();
    if (_snList.isNotEmpty || _traceHistory.isNotEmpty) {
      refetchAllSns(allowTestRecordFallback: false);
    }
  }

  Future<void> addSns(
    String input, {
    bool allowTestRecordFallback = true,
  }) async {
    final lines = input.split(RegExp(r'[\n\r,;\s]+'));
    final addedSns = <String>[];
    for (var line in lines) {
      final sn = line.trim().toUpperCase();
      if (sn == 'SN') continue;
      if (sn.isNotEmpty &&
          RegExp(r'^[A-Z0-9_-]+$').hasMatch(sn) &&
          !_snList.contains(sn)) {
        _snList.add(sn);
        addedSns.add(sn);
      }
    }

    if (addedSns.isNotEmpty) {
      await _saveConfig(_exportConfigMap());
      if (_selectedSn.isEmpty) {
        _selectedSn = _snList.last;
      }
      if (allowTestRecordFallback) {
        _enableTestRecordFallbackFor(addedSns);
      }
      notifyListeners();
      _fetchAllPending();
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
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-STA',
        '-Command',
        script,
      ]);
      final path = result.stdout.toString().trim();
      if (path.isNotEmpty) {
        return path;
      }
    } catch (e) {
      _logger.severe('Failed to pick file: $e');
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
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-STA',
        '-Command',
        script,
      ]);
      final path = result.stdout.toString().trim();
      if (path.isEmpty) return; // User canceled

      final file = File(path.replaceAll('"', '').trim());
      await file.writeAsString('SN\nSN123456\nSN789012\n');
      _globalError = 'Template downloaded successfully to $path';
    } catch (e) {
      _globalError = 'Error downloading template: $e';
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
      await addSns(content, allowTestRecordFallback: false);
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
      buffer.writeln(
        'SN,Internal SN,Customer SN,Product No,Process Code,Line Station Code,Station ID,Error Code,Test Time,Result,Failure Reason,Fail Desc,Host Loc,Product Series,WO,EmpNo',
      );

      for (final sn in _snList) {
        final records = _results[sn];
        if (records != null && records.isNotEmpty) {
          for (final r in records) {
            buffer.writeln(
              [
                r.sn,
                r.internalSn,
                r.customerSn,
                r.productNo,
                r.processCode,
                r.lineStationCode,
                r.stationId,
                r.errCode,
                r.testDate,
                r.testResult,
                r.failureReason,
                r.failDesc,
                r.loc,
                r.productSeries,
                r.woNo,
                r.empNo,
              ].map(csvField).join(','),
            );
          }
        } else {
          final err = _errors[sn] ?? 'No records / Pending';
          buffer.writeln(
            [sn, ...List<String>.filled(14, ''), err].map(csvField).join(','),
          );
        }
      }

      await file.writeAsString(buffer.toString());
      _globalError = 'Exported successfully to $path';
    } catch (e) {
      _globalError = 'Error exporting CSV: $e';
    }
    notifyListeners();
  }

  Future<void> exportBarcodeHistoryCsv() async {
    _globalError = '';
    notifyListeners();
    try {
      final path = await pickFile(isSave: true);
      if (path == null || path.isEmpty) return;

      final file = File(path.replaceAll('"', '').trim());
      final buffer = StringBuffer();
      buffer.writeln(
        'Product SN,Internal SN,Customer SN,Current Process Code,Current Process Name,Line,Line Station,Equipment No,Result,Operate Date,WO,Plan No,Product No,Product Version,Operator,Remark',
      );

      for (final sn in _snList) {
        final records = _processResults[sn];
        if (records != null && records.isNotEmpty) {
          for (final r in records) {
            final lineVal = r.lineName.isNotEmpty ? r.lineName : r.lineCode;
            buffer.writeln(
              [
                r.productSn,
                r.internalSn,
                r.customerSn,
                r.currentProcessCode,
                r.currentProcessName,
                lineVal,
                r.lineStation,
                r.eqpId,
                r.result,
                r.operateDt,
                r.woNo,
                r.planNo,
                r.productNo,
                r.productVersion,
                r.operatorName,
                r.remark,
              ].map(csvField).join(','),
            );
          }
        }
      }

      await file.writeAsString(buffer.toString());
      _globalError = 'Exported Barcode History successfully to $path';
    } catch (e) {
      _globalError = 'Error exporting Barcode History: $e';
    }
    notifyListeners();
  }

  Future<void> exportWipComponentsCsv() async {
    _globalError = '';
    notifyListeners();
    try {
      final path = await pickFile(isSave: true);
      if (path == null || path.isEmpty) return;

      final file = File(path.replaceAll('"', '').trim());
      final buffer = StringBuffer();
      buffer.writeln(
        'Material No,Material Name,Category,Component SN,Location,Manufacturer,Mfg PN,Date Code,Package ID,Installed Qty,Station Code,Process Code,Created Date',
      );

      for (final sn in _snList) {
        final records = _wipResults[sn];
        if (records != null && records.isNotEmpty) {
          for (final r in records) {
            buffer.writeln(
              [
                r.materialNo,
                r.materialName,
                r.materialCategory,
                r.scannedCsn,
                r.location,
                r.mfgName,
                r.mfgPn,
                r.dateCode,
                r.pkgId,
                r.installedQty,
                r.stationCode,
                r.processCode,
                r.createdDt,
              ].map(csvField).join(','),
            );
          }
        }
      }

      await file.writeAsString(buffer.toString());
      _globalError = 'Exported WIP Components successfully to $path';
    } catch (e) {
      _globalError = 'Error exporting WIP Components: $e';
    }
    notifyListeners();
  }

  /// Resolves a typed SN (internal SN, customer SN, or product SN) to its
  /// canonical top-level product SN via the snMaster lookup, caching the
  /// result per typed SN. Falls back to the raw input on failure so a
  /// resolve error never blocks the existing fetch flow.
  Future<String> _resolveCanonicalSn(String sn, int revision) {
    final cached = _resolvedSn[sn];
    if (cached != null) return Future.value(cached);
    final key = (sn, revision);
    return _resolving.putIfAbsent(key, () async {
      try {
        final info = await ApiClient.resolveSnMaster(
          sn: sn,
          token: _token,
          lang: _lang,
          operationId: _operationId,
          uuid: _uuid,
          cookie: _cookie,
        );
        final canonical = info.sn.isNotEmpty ? info.sn : sn;
        if (!_disposed &&
            _revision('sn:$sn') == revision &&
            _snList.contains(sn)) {
          _resolvedSn[sn] = canonical;
          _snMasterInfo[sn] = info;
        }
        return canonical;
      } catch (_) {
        return sn;
      } finally {
        _resolving.remove(key);
      }
    });
  }

  Future<void> _fetchPendingSns() => _fetchView<TestRecord>(
    'test',
    _results,
    _errors,
    _loadingStatus,
    ApiClient.fetchTestRecords,
  );

  Future<void> _fetchView<T>(
    String view,
    Map<String, List<T>> results,
    Map<String, String> errors,
    Map<String, bool> loading,
    Future<List<T>> Function({
      required String sn,
      required String token,
      required String lang,
      required String operationId,
      required String uuid,
      required String cookie,
    })
    fetch,
  ) async {
    final jobs = <Future<void>>[];
    for (final sn in List<String>.of(_snList)) {
      if (results.containsKey(sn) || errors.containsKey(sn)) continue;
      final revision = _revision('sn:$sn');
      bool current() =>
          !_disposed && _snList.contains(sn) && _revision('sn:$sn') == revision;
      loading[sn] = true;
      jobs.add(
        _queue.run((view, sn, revision), () async {
          try {
            final canonical = await _resolveCanonicalSn(sn, revision);
            if (!current()) return;
            final records = await fetch(
              sn: canonical,
              token: _token,
              lang: _lang,
              operationId: _operationId,
              uuid: _uuid,
              cookie: _cookie,
            );
            if (!current()) return;
            results[sn] = records;
            if (records.isEmpty) errors[sn] = 'No records found';
          } catch (e) {
            if (current()) {
              errors[sn] = e.toString().replaceFirst('Exception: ', '');
            }
          } finally {
            if (current()) {
              loading[sn] = false;
              if (view == 'test') {
                _switchToBarcodeHistoryIfNeeded(sn);
                _testRecordFallbackEligibleSns.remove(sn);
              }
              notifyListeners();
            }
          }
        }, isCurrent: current),
      );
    }
    notifyListeners();
    await Future.wait(jobs);
  }

  void _enableTestRecordFallbackFor(Iterable<String> sns) {
    for (final sn in sns) {
      if (sn.isNotEmpty) {
        _testRecordFallbackEligibleSns.add(sn);
      }
    }
  }

  bool _hasNoTestRecordData(String sn) {
    if (sn.isEmpty) return false;
    return shouldFallbackToBarcodeHistory(
      recordsAreEmpty: _results[sn]?.isEmpty ?? false,
      error: _errors[sn],
    );
  }

  SnDataStatus snDataStatus(String sn) {
    final hasBarcodeHistoryData = _processResults[sn]?.isNotEmpty == true;
    final hasComponentData = _wipResults[sn]?.isNotEmpty == true;
    final relatedViewsResolved =
        (_processResults.containsKey(sn) || _processErrors.containsKey(sn)) &&
        (_wipResults.containsKey(sn) || _wipErrors.containsKey(sn));

    return snDataStatusForViews(
      hasNoTestRecordData: _hasNoTestRecordData(sn),
      hasBarcodeHistoryData: hasBarcodeHistoryData,
      hasComponentData: hasComponentData,
      relatedViewsResolved: relatedViewsResolved,
    );
  }

  bool _switchToBarcodeHistoryIfNeeded(String sn) {
    if (!shouldAutoSwitchToBarcodeHistory(
      selectedSn: _selectedSn,
      candidateSn: sn,
      viewMode: _viewMode,
      hasNoTestRecordData: _hasNoTestRecordData(sn),
      fallbackAllowed: _testRecordFallbackEligibleSns.contains(sn),
    )) {
      return false;
    }
    _viewMode = ViewMode.barcodeHistory;
    _testRecordFallbackEligibleSns.remove(sn);
    return true;
  }

  Future<void> _fetchPendingProcessHistory() => _fetchView<SnProcessRecord>(
    'process',
    _processResults,
    _processErrors,
    _processLoadingStatus,
    ApiClient.fetchSnProcessHistory,
  );

  Future<void> _fetchPendingWipComponents() => _fetchView<WipComponentRecord>(
    'wip',
    _wipResults,
    _wipErrors,
    _wipLoadingStatus,
    ApiClient.fetchWipComponents,
  );

  /// Reverse component lookup: given a scanned/typed component CSN, finds
  /// which product SN it is currently installed into. Adds the CSN to the
  /// trace history (if new) and selects it, so the sidebar and detail view
  /// both reflect the just-searched CSN.
  Future<void> searchComponentTrace(String csn) async {
    final trimmed = csn.trim().toUpperCase();
    if (trimmed.isEmpty) return;
    if (!_traceHistory.contains(trimmed)) {
      _traceHistory.insert(0, trimmed);
      _saveConfig(_exportConfigMap());
    }
    _selectedTraceCsn = trimmed;
    _invalidate('csn:$trimmed');
    await _fetchTrace(trimmed);
  }

  Future<void> _fetchTrace(String csn) {
    final revision = _revision('csn:$csn');
    bool current() =>
        !_disposed &&
        _traceHistory.contains(csn) &&
        _revision('csn:$csn') == revision;
    _traceLoadingStatus[csn] = true;
    _traceErrors.remove(csn);
    notifyListeners();
    return _queue.run(('trace', csn, revision), () async {
      try {
        final records = await ApiClient.queryComponentInfo(
          csn: csn,
          token: _token,
          lang: _lang,
          operationId: _operationId,
          uuid: _uuid,
          cookie: _cookie,
        );
        if (!current()) return;
        _traceResults[csn] = records;
        if (records.isEmpty) _traceErrors[csn] = 'No records found';
      } catch (e) {
        if (current()) {
          _traceErrors[csn] = e.toString().replaceFirst('Exception: ', '');
        }
      } finally {
        if (current()) {
          _traceLoadingStatus[csn] = false;
          notifyListeners();
        }
      }
    }, isCurrent: current);
  }

  /// Selects a previously searched CSN from the trace history without
  /// re-fetching (its result is already cached).
  void selectTraceCsn(String csn) {
    _selectedTraceCsn = csn;
    notifyListeners();
  }

  /// Re-runs the lookup for a CSN already in the trace history.
  Future<void> refreshTraceCsn(String csn) async {
    _traceResults.remove(csn);
    _traceErrors.remove(csn);
    notifyListeners();
    await searchComponentTrace(csn);
  }

  void removeTraceCsn(String csn) {
    _invalidate('csn:$csn');
    _traceHistory.remove(csn);
    _traceResults.remove(csn);
    _traceErrors.remove(csn);
    _traceLoadingStatus.remove(csn);
    if (_selectedTraceCsn == csn) {
      _selectedTraceCsn = _traceHistory.isNotEmpty ? _traceHistory.first : '';
    }
    _saveConfig(_exportConfigMap());
    notifyListeners();
  }

  void clearTraceHistory() {
    for (final csn in _traceHistory) {
      _invalidate('csn:$csn');
    }
    _traceHistory.clear();
    _traceResults.clear();
    _traceErrors.clear();
    _traceLoadingStatus.clear();
    _selectedTraceCsn = '';
    _saveConfig(_exportConfigMap());
    notifyListeners();
  }

  /// Explicitly refreshes trace history without changing the user's selection.
  Future<void> refetchAllTraceSearches() async {
    for (final csn in _traceHistory) {
      _invalidate('csn:$csn');
    }
    await Future.wait(List<String>.of(_traceHistory).map(_fetchTrace));
  }

  /// Parses a multi-line/comma-separated blob of component CSNs (manual
  /// paste or CSV file content) and queues the searches concurrently — the
  /// Component Trace equivalent of [addSns], reusing the same delimiter and
  /// header-row-skip conventions.
  Future<void> addTraceCsns(String input) async {
    final lines = input.split(RegExp(r'[\n\r,;\s]+'));
    final toSearch = <String>[];
    for (var line in lines) {
      final csn = line.trim().toUpperCase();
      if (csn == 'SN' || csn == 'CSN') continue;
      if (csn.isNotEmpty &&
          RegExp(r'^[A-Z0-9_-]+$').hasMatch(csn) &&
          !toSearch.contains(csn)) {
        toSearch.add(csn);
      }
    }

    await Future.wait(toSearch.map(searchComponentTrace));
  }

  Future<void> downloadTraceTemplateCsv() async {
    _globalError = '';
    notifyListeners();
    try {
      final script = '''
Add-Type -AssemblyName System.Windows.Forms
\$f = New-Object System.Windows.Forms.SaveFileDialog
\$f.Filter = "CSV Files (*.csv)|*.csv"
\$f.FileName = "Template_Component_SN.csv"
\$f.InitialDirectory = [Environment]::GetFolderPath("Desktop")
if(\$f.ShowDialog() -eq "OK") { Write-Output \$f.FileName }
''';
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-STA',
        '-Command',
        script,
      ]);
      final path = result.stdout.toString().trim();
      if (path.isEmpty) return; // User canceled

      final file = File(path.replaceAll('"', '').trim());
      await file.writeAsString('CSN\nOPM1106349G1CCX\nQB940AE002627V05171\n');
      _globalError = 'Template downloaded successfully to $path';
    } catch (e) {
      _globalError = 'Error downloading template: $e';
    }
    notifyListeners();
  }

  Future<void> importTraceCsv() async {
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
      await addTraceCsns(content);
    } catch (e) {
      _globalError = 'Error importing CSV: $e';
      notifyListeners();
    }
  }

  Future<void> exportTraceCsv() async {
    _globalError = '';
    notifyListeners();
    try {
      final path = await pickFile(isSave: true);
      if (path == null || path.isEmpty) return; // User canceled

      final file = File(path.replaceAll('"', '').trim());
      final buffer = StringBuffer();
      buffer.writeln(
        'Component SN,Product SN,Material No,Material Name,Category,Manufacturer,Mfg Part No,Product No,Line Code,Process Code,WO,Qty,Process Time,Assembled Status',
      );

      for (final csn in _traceHistory) {
        final records = _traceResults[csn];
        if (records != null && records.isNotEmpty) {
          for (final r in records) {
            buffer.writeln(
              [
                csn,
                r.productSn,
                r.materialNo,
                r.materialName,
                r.materialCategory,
                r.mfgName,
                r.mfgPn,
                r.productNo,
                r.lineCode,
                r.processCode,
                r.woNo,
                r.installedQty,
                r.createdDt,
                r.checkAssembled,
              ].map(csvField).join(','),
            );
          }
        } else {
          final err = _traceErrors[csn] ?? 'No records / Pending';
          buffer.writeln(
            [csn, ...List<String>.filled(12, ''), err].map(csvField).join(','),
          );
        }
      }

      await file.writeAsString(buffer.toString());
      _globalError = 'Exported successfully to $path';
    } catch (e) {
      _globalError = 'Error exporting CSV: $e';
    }
    notifyListeners();
  }

  Future<String?> verifySettings(
    String t,
    String l,
    String o,
    String u,
    String c,
  ) async {
    return await ApiClient.verifyConnection(
      token: t,
      lang: l,
      operationId: o,
      uuid: u,
      cookie: c,
    );
  }

  Future<bool> testConnection({
    String? testToken,
    String? testOpId,
    String? testUuid,
    String? testCookie,
  }) async {
    final err = await ApiClient.verifyConnection(
      token: testToken ?? _token,
      lang: _lang,
      operationId: testOpId ?? _operationId,
      uuid: testUuid ?? _uuid,
      cookie: testCookie ?? _cookie,
    );
    if (testToken == null) {
      isConnectionValid = (err == null);
      connectionError = err;
      notifyListeners();
    }
    return err == null;
  }

  Future<void> refetchSn(String sn) => refreshSn(sn);
  Future<void> refetchTraceHistory() => refetchAllTraceSearches();
  Future<void> refetchTraceCsn(String csn) => searchComponentTrace(csn);

  Future<void> fetchSnsData() async {
    _invalidateAll();
    _testRecordFallbackEligibleSns.clear();
    if (_viewMode == ViewMode.testRecord) {
      _enableTestRecordFallbackFor(_snList);
    }
    _results.clear();
    _errors.clear();
    notifyListeners();
    await _fetchAllPending();
  }

  Future<void> refreshAll() async {
    _invalidateAll(includeTrace: true);
    _testRecordFallbackEligibleSns.clear();
    if (_viewMode == ViewMode.testRecord) {
      _enableTestRecordFallbackFor(_snList);
    }
    _results.clear();
    _errors.clear();
    _processResults.clear();
    _processErrors.clear();
    _wipResults.clear();
    _wipErrors.clear();
    notifyListeners();
    await _fetchAllPending();
  }
}
