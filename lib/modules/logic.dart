import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'api_client.dart';
import 'config_service.dart';
import 'constants.dart';

final _logger = Logger('AppLogic');

enum ViewMode { testRecord, barcodeHistory, wipComponents, componentTrace }

class AppLogic extends ChangeNotifier {
  ViewMode _viewMode = ViewMode.testRecord;
  ViewMode get viewMode => _viewMode;

  final Map<String, List<SnProcessRecord>> _processResults = {};
  Map<String, List<SnProcessRecord>> get processResults => _processResults;

  final Map<String, bool> _processLoadingStatus = {};
  Map<String, bool> get processLoadingStatus => _processLoadingStatus;

  final Map<String, String> _processErrors = {};
  Map<String, String> get processErrors => _processErrors;

  bool _isProcessBatchLoading = false;

  final Map<String, List<WipComponentRecord>> _wipResults = {};
  Map<String, List<WipComponentRecord>> get wipResults => _wipResults;

  final Map<String, bool> _wipLoadingStatus = {};
  Map<String, bool> get wipLoadingStatus => _wipLoadingStatus;

  final Map<String, String> _wipErrors = {};
  Map<String, String> get wipErrors => _wipErrors;

  bool _isWipBatchLoading = false;

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

  void setLiveGlassmorphism({
    double? bgBlur,
    double? bgOpacity,
    double? dialogBlur,
    double? dialogOpacity,
  }) {
    if (bgBlur != null) _bgBlur = bgBlur;
    if (bgOpacity != null) _bgOpacity = bgOpacity;
    if (dialogBlur != null) _dialogBlur = dialogBlur;
    if (dialogOpacity != null) _dialogOpacity = dialogOpacity;
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

  double _parseDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    return fallback;
  }

  Future<void> _init() async {
    final config = await ConfigService.loadConfig();
    _token = config['token'] ?? '';
    _lang = config['lang'] ?? 'en';
    _operationId = config['operationId'] ?? defaultOperationId;
    _uuid = config['uuid'] ?? defaultUuid;
    _cookie = config['cookie'] ?? '';
    _bgBlur = _parseDouble(config['bgBlur'], 20.0);
    _bgOpacity = _parseDouble(config['bgOpacity'], 0.25);
    _dialogBlur = _parseDouble(config['dialogBlur'], 20.0);
    _dialogOpacity = _parseDouble(config['dialogOpacity'], 0.85);

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
      refetchAllTraceSearches(),
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
    final res = await verifySettings(
      _token,
      _lang,
      _operationId,
      _uuid,
      _cookie,
    );
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
    if (_selectedSn == sn) {
      _selectedSn = _snList.isNotEmpty ? _snList.first : '';
    }
    ConfigService.saveConfig(_exportConfigMap());
    notifyListeners();
  }

  /// Clears cached data for a single SN (all 3 views + its resolved-SN
  /// cache) and re-fetches it, without needing to remove/re-add the SN or
  /// restart the app.
  Future<void> refreshSn(String sn) async {
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
    notifyListeners();
    await _fetchAllPending();
  }

  void clearAllSns() {
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
    _processResults.clear();
    _processErrors.clear();
    _processLoadingStatus.clear();
    _isProcessBatchLoading = false;
    _wipResults.clear();
    _wipErrors.clear();
    _wipLoadingStatus.clear();
    _isWipBatchLoading = false;
    notifyListeners();
    await _fetchAllPending();
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
  }) async {
    _token = token;
    _lang = lang;
    _operationId = operationId;
    _uuid = uuid;
    _cookie = cookie;
    if (bgBlur != null) _bgBlur = bgBlur;
    if (bgOpacity != null) _bgOpacity = bgOpacity;
    if (dialogBlur != null) _dialogBlur = dialogBlur;
    if (dialogOpacity != null) _dialogOpacity = dialogOpacity;
    await ConfigService.saveConfig(_exportConfigMap());
    _validateNow();
    notifyListeners();
    if (_snList.isNotEmpty || _traceHistory.isNotEmpty) {
      refetchAllSns();
    }
  }

  Future<void> addSns(String input) async {
    final lines = input.split(RegExp(r'[\n\r,;\s]+'));
    bool added = false;
    for (var line in lines) {
      final sn = line.trim().toUpperCase();
      if (sn == 'SN') continue;
      if (sn.isNotEmpty &&
          RegExp(r'^[A-Z0-9_-]+$').hasMatch(sn) &&
          !_snList.contains(sn)) {
        _snList.add(sn);
        added = true;
      }
    }

    if (added) {
      await ConfigService.saveConfig(_exportConfigMap());
      if (_selectedSn.isEmpty) _selectedSn = _snList.last;
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
      buffer.writeln(
        'SN,Internal SN,Customer SN,Product No,Process Code,Line Station Code,Station ID,Error Code,Test Time,Result,Failure Reason,Fail Desc,Host Loc,Product Series,WO,EmpNo',
      );

      for (final sn in _snList) {
        final records = _results[sn];
        if (records != null && records.isNotEmpty) {
          for (final r in records) {
            buffer.writeln(
              '${r.sn},${r.internalSn},${r.customerSn},${r.productNo},${r.processCode},${r.lineStationCode},${r.stationId},${r.errCode},${r.testDate},${r.testResult},"${r.failureReason}","${r.failDesc}","${r.loc}",${r.productSeries},${r.woNo},${r.empNo}',
            );
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

  /// Resolves a typed SN (internal SN, customer SN, or product SN) to its
  /// canonical top-level product SN via the snMaster lookup, caching the
  /// result per typed SN. Falls back to the raw input on failure so a
  /// resolve error never blocks the existing fetch flow.
  Future<String> _resolveCanonicalSn(String sn) async {
    final cached = _resolvedSn[sn];
    if (cached != null) return cached;
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
      _resolvedSn[sn] = canonical;
      _snMasterInfo[sn] = info;
      return canonical;
    } catch (e) {
      _logger.warning('Failed to resolve SN master for $sn: $e');
      _resolvedSn[sn] = sn;
      return sn;
    }
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
          final canonicalSn = await _resolveCanonicalSn(sn);
          final records = await ApiClient.fetchTestRecords(
            sn: canonicalSn,
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

  Future<void> _fetchPendingProcessHistory() async {
    if (_isProcessBatchLoading) return;
    _isProcessBatchLoading = true;
    notifyListeners();

    final currentList = List<String>.from(_snList);
    for (var sn in currentList) {
      if (!_processResults.containsKey(sn) && _processErrors[sn] == null) {
        _processLoadingStatus[sn] = true;
        notifyListeners();

        try {
          final canonicalSn = await _resolveCanonicalSn(sn);
          final records = await ApiClient.fetchSnProcessHistory(
            sn: canonicalSn,
            token: _token,
            lang: _lang,
            operationId: _operationId,
            uuid: _uuid,
            cookie: _cookie,
          );
          _processResults[sn] = records;
          if (records.isEmpty) {
            _processErrors[sn] = 'No records found';
          }
        } catch (e) {
          _logger.severe('Failed to fetch process history for $sn: $e');
          _processErrors[sn] = e.toString().replaceFirst('Exception: ', '');
        } finally {
          _processLoadingStatus[sn] = false;
          notifyListeners();
        }
      }
    }

    _isProcessBatchLoading = false;
    notifyListeners();
  }

  Future<void> _fetchPendingWipComponents() async {
    if (_isWipBatchLoading) return;
    _isWipBatchLoading = true;
    notifyListeners();

    final currentList = List<String>.from(_snList);
    for (var sn in currentList) {
      if (!_wipResults.containsKey(sn) && _wipErrors[sn] == null) {
        _wipLoadingStatus[sn] = true;
        notifyListeners();

        try {
          final canonicalSn = await _resolveCanonicalSn(sn);
          final records = await ApiClient.fetchWipComponents(
            sn: canonicalSn,
            token: _token,
            lang: _lang,
            operationId: _operationId,
            uuid: _uuid,
            cookie: _cookie,
          );
          _wipResults[sn] = records;
          if (records.isEmpty) {
            _wipErrors[sn] = 'No records found';
          }
        } catch (e) {
          _logger.severe('Failed to fetch WIP components for $sn: $e');
          _wipErrors[sn] = e.toString().replaceFirst('Exception: ', '');
        } finally {
          _wipLoadingStatus[sn] = false;
          notifyListeners();
        }
      }
    }

    _isWipBatchLoading = false;
    notifyListeners();
  }

  /// Reverse component lookup: given a scanned/typed component CSN, finds
  /// which product SN it is currently installed into. Adds the CSN to the
  /// trace history (if new) and selects it, so the sidebar and detail view
  /// both reflect the just-searched CSN.
  Future<void> searchComponentTrace(String csn) async {
    final trimmed = csn.trim().toUpperCase();
    if (trimmed.isEmpty) return;

    if (!_traceHistory.contains(trimmed)) {
      _traceHistory.insert(0, trimmed);
      ConfigService.saveConfig(_exportConfigMap());
    }
    _selectedTraceCsn = trimmed;
    _traceLoadingStatus[trimmed] = true;
    _traceErrors.remove(trimmed);
    notifyListeners();

    try {
      final records = await ApiClient.queryComponentInfo(
        csn: trimmed,
        token: _token,
        lang: _lang,
        operationId: _operationId,
        uuid: _uuid,
        cookie: _cookie,
      );
      _traceResults[trimmed] = records;
      if (records.isEmpty) {
        _traceErrors[trimmed] = 'No records found';
      }
    } catch (e) {
      _logger.severe('Failed to query component info for $trimmed: $e');
      _traceErrors[trimmed] = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _traceLoadingStatus[trimmed] = false;
      notifyListeners();
    }
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
    _traceHistory.remove(csn);
    _traceResults.remove(csn);
    _traceErrors.remove(csn);
    _traceLoadingStatus.remove(csn);
    if (_selectedTraceCsn == csn) {
      _selectedTraceCsn = _traceHistory.isNotEmpty ? _traceHistory.first : '';
    }
    ConfigService.saveConfig(_exportConfigMap());
    notifyListeners();
  }

  void clearTraceHistory() {
    _traceHistory.clear();
    _traceResults.clear();
    _traceErrors.clear();
    _traceLoadingStatus.clear();
    _selectedTraceCsn = '';
    ConfigService.saveConfig(_exportConfigMap());
    notifyListeners();
  }

  /// Re-runs the lookup for every CSN in the trace history (e.g. on app
  /// startup, or after credentials change). Preserves whatever was selected
  /// beforehand rather than leaving the last-fetched item selected as a side
  /// effect of the loop.
  Future<void> refetchAllTraceSearches() async {
    final current = List<String>.from(_traceHistory);
    final previousSelected = _selectedTraceCsn;
    for (final csn in current) {
      await searchComponentTrace(csn);
    }
    _selectedTraceCsn = previousSelected.isNotEmpty
        ? previousSelected
        : (_traceHistory.isNotEmpty ? _traceHistory.first : '');
    notifyListeners();
  }

  /// Parses a multi-line/comma-separated blob of component CSNs (manual
  /// paste or CSV file content) and searches each new one in turn — the
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

    for (final csn in toSearch) {
      await searchComponentTrace(csn);
    }
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
              '$csn,${r.productSn},${r.materialNo},"${r.materialName}",${r.materialCategory},${r.mfgName},${r.mfgPn},${r.productNo},${r.lineCode},${r.processCode},${r.woNo},${r.installedQty},${r.createdDt},${r.checkAssembled}',
            );
          }
        } else {
          final err = _traceErrors[csn] ?? 'No records / Pending';
          buffer.writeln('$csn,,,,,,,,,,,,,"$err"');
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

  Future<void> fetchSnsData() async {
    _results.clear();
    _errors.clear();
    notifyListeners();
    await _fetchPendingSns();
  }

  Future<void> refreshAll() async {
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
