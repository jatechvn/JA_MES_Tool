import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'api_client.dart';
import 'config_service.dart';
import 'constants.dart';
import 'query_queue.dart';
import 'translations.dart';
import 'services/app_power_manager.dart';

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

  final Map<int, List<ComponentParamRecord>> _componentParams = {};
  Map<int, List<ComponentParamRecord>> get componentParams => _componentParams;

  final Map<int, bool> _componentParamsLoading = {};
  Map<int, bool> get componentParamsLoading => _componentParamsLoading;

  final Map<int, String> _componentParamsErrors = {};
  Map<int, String> get componentParamsErrors => _componentParamsErrors;

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

  /// Returns true if the SN has a FAIL status in SN Master, Test Record, or
  /// Barcode History. Used by the Sidebar Queue quick filter (All / FAIL Only).
  bool snHasFail(String sn) {
    final masterStatus =
        _snMasterInfo[sn]?.productStatus.trim().toUpperCase() ?? '';
    if (masterStatus.contains('FAIL') ||
        masterStatus == 'NG' ||
        masterStatus == 'ERR') {
      return true;
    }
    final testRecords = _results[sn];
    if (testRecords != null &&
        testRecords.any((r) {
          final res = r.testResult.trim().toUpperCase();
          return res.isNotEmpty &&
              res != 'PASS' &&
              res != 'OK' &&
              res != 'GOOD';
        })) {
      return true;
    }
    final procRecords = _processResults[sn];
    if (procRecords != null &&
        procRecords.any((r) {
          final res = r.result.trim().toUpperCase();
          return res.isNotEmpty &&
              res != 'PASS' &&
              res != 'OK' &&
              res != 'GOOD';
        })) {
      return true;
    }
    return false;
  }

  /// Sidebar counterpart: internal input shows customer SN; other identifiers
  /// show internal SN. Keep canonical resolution separate from display fallback.
  String? alternateSnFor(String sn) {
    final input = sn.trim().toUpperCase();
    String? different(String value) {
      final candidate = value.trim();
      return candidate.isNotEmpty && candidate.toUpperCase() != input
          ? candidate
          : null;
    }

    final resolved = different(_resolvedSn[sn] ?? '');
    if (resolved != null) return resolved;

    String? counterpart(String internal, String customer) {
      if (internal.trim().toUpperCase() == input) {
        return different(customer);
      }
      return different(internal) ?? different(customer);
    }

    final tests = _results[sn];
    if (tests != null && tests.isNotEmpty) {
      final alternate = counterpart(
        tests.first.internalSn,
        tests.first.customerSn,
      );
      if (alternate != null) return alternate;
    }
    final processes = _processResults[sn];
    if (processes != null && processes.isNotEmpty) {
      return counterpart(
        processes.first.internalSn,
        processes.first.customerSn,
      );
    }
    return null;
  }

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

  String _username = '';
  String get username => _username;

  String _savedPassword = '';
  String get savedPassword => _savedPassword;

  String _loginMethod = 'SSO';
  String get loginMethod => _loginMethod;

  String _copeCode = 'F_VN';
  String get copeCode => _copeCode;

  bool _rememberPassword = true;
  bool get rememberPassword => _rememberPassword;

  bool _autoLogin = true;
  bool get autoLogin => _autoLogin;

  bool _isLoggingIn = false;
  bool get isLoggingIn => _isLoggingIn;

  bool _manualLogoutInSession = false;
  bool get manualLogoutInSession => _manualLogoutInSession;

  String get activeAccount {
    final jwtAccount = ApiClient.extractAccountFromJwt(_token);
    if (jwtAccount.isNotEmpty) return jwtAccount;
    if (_username.trim().isNotEmpty) return _username.trim();
    return '';
  }

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

  bool _enableIdleSleep = true;
  bool get enableIdleSleep => _enableIdleSleep;

  int _idleTimeoutSeconds = 12;
  int get idleTimeoutSeconds => _idleTimeoutSeconds;

  void setEnableIdleSleep(bool value) {
    if (_enableIdleSleep != value) {
      _enableIdleSleep = value;
      AppPowerManager.instance.setEnableIdleSleep(value);
      notifyListeners();
    }
  }

  void setIdleTimeoutSeconds(int value) {
    if (_idleTimeoutSeconds != value) {
      _idleTimeoutSeconds = value;
      AppPowerManager.instance.setIdleTimeout(Duration(seconds: value));
      notifyListeners();
    }
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

  int _loadingWoCount = 0;
  bool get isLoadingWo => _loadingWoCount > 0;

  String _globalMessageKey = '';
  Map<String, String> _globalMessageValues = {};
  bool _globalMessageIsError = false;
  bool get globalMessageIsError => _globalMessageIsError;
  String get globalError {
    if (_globalMessageKey.isEmpty) return '';
    var message = Translations.get(_globalMessageKey, _lang);
    for (final entry in _globalMessageValues.entries) {
      message = message.replaceAll('{${entry.key}}', entry.value);
    }
    return message;
  }

  void _setGlobalMessage(
    String key, {
    bool isError = true,
    Map<String, String> values = const {},
  }) {
    _globalMessageKey = key;
    _globalMessageValues = values;
    _globalMessageIsError = key.isNotEmpty && isError;
  }

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
  final Future<Map<String, dynamic>> Function() _loadConfig;
  final Future<String?> Function(bool isSave)? filePicker;

  AppLogic({
    bool initialize = true,
    int queryConcurrency = 6,
    Future<void> Function(Map<String, dynamic>)? saveConfig,
    Future<Map<String, dynamic>> Function()? loadConfig,
    this.filePicker,
  }) : _queue = QueryQueue(concurrency: queryConcurrency),
       _saveConfig = saveConfig ?? ConfigService.saveConfig,
       _loadConfig = loadConfig ?? ConfigService.loadConfig {
    if (initialize) _init();
  }

  int _revision(String key) => _revisions[key] ?? 0;

  Future<void> get queriesIdle => _queue.idle;

  /// WO queries bypass SN resolution and never mutate SN/trace history.
  Future<TestRecordPage> fetchWorkOrderPage(
    String woNo, {
    int pageIndex = 1,
    bool Function()? isCurrent,
  }) async {
    final revision = _credentialsRevision;
    bool current() =>
        !_disposed &&
        revision == _credentialsRevision &&
        (isCurrent?.call() ?? true);
    TestRecordPage? result;
    await _queue.run(
      Object(),
      () async {
        final page = await ApiClient.fetchWorkOrderPage(
          woNo: woNo,
          pageIndex: pageIndex,
          token: _token,
          lang: _lang,
          operationId: _operationId,
          uuid: _uuid,
          cookie: _cookie,
        );
        if (current()) result = page;
      },
      isCurrent: current,
      priority: () => _snList.length + 1000,
    );
    if (!current() || result == null) throw StateError('Query invalidated');
    return result!;
  }

  void _invalidate(String key) {
    _revisions[key] = _revision(key) + 1;
  }

  void _invalidateAll({bool includeTrace = false}) {
    _resolvedSn.clear();
    _snMasterInfo.clear();
    _componentParams.clear();
    _componentParamsLoading.clear();
    _componentParamsErrors.clear();
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
    final config = await _loadConfig();
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
    _username = config['username']?.toString() ?? '';
    _savedPassword = config['savedPassword']?.toString() ?? '';
    final cfgMethod =
        config['loginMethod']?.toString().trim().toUpperCase() ?? 'SSO';
    _loginMethod = cfgMethod == 'CLOUDMES' ? 'CLOUDMES' : 'SSO';
    _copeCode = config['copeCode']?.toString() ?? 'F_VN';
    _rememberPassword = config['rememberPassword'] is bool
        ? config['rememberPassword'] as bool
        : true;
    _autoLogin = config['autoLogin'] is bool
        ? config['autoLogin'] as bool
        : true;
    _bgBlur = _parseDouble(config['bgBlur'], 20.0);
    _bgOpacity = _parseDouble(config['bgOpacity'], 0.25);
    _dialogBlur = _parseDouble(config['dialogBlur'], 20.0);
    _dialogOpacity = _parseDouble(config['dialogOpacity'], 0.85);
    _dropdownBlur = _parseDouble(config['dropdownBlur'], 20.0);
    _dropdownOpacity = _parseDouble(config['dropdownOpacity'], 0.86);
    _enableIdleSleep = config['enableIdleSleep'] is bool
        ? config['enableIdleSleep'] as bool
        : true;
    _idleTimeoutSeconds = config['idleTimeoutSeconds'] is num
        ? (config['idleTimeoutSeconds'] as num).toInt()
        : 12;
    AppPowerManager.instance.setEnableIdleSleep(_enableIdleSleep);
    AppPowerManager.instance.setIdleTimeout(
      Duration(seconds: _idleTimeoutSeconds),
    );

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
      _selectedSn = _snList.last;
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
    String? res;
    if (_token.trim().isEmpty) {
      res = '401 Unauthorized';
    } else {
      res = await verifySettings(_token, _lang, _operationId, _uuid, _cookie);
    }
    if (_disposed || revision != _credentialsRevision) return;
    if (res == null) {
      final jwtUser = ApiClient.extractAccountFromJwt(_token);
      if (jwtUser.isNotEmpty && _username.trim().isEmpty) {
        _username = jwtUser;
        unawaited(_saveConfig(_exportConfigMap()));
      }
      isConnectionValid = true;
      connectionError = null;
      notifyListeners();
      return;
    }

    // Attempt silent auto-login if remembered credentials exist and user did not manually log out
    if (!_manualLogoutInSession &&
        _autoLogin &&
        _rememberPassword &&
        _username.trim().isNotEmpty &&
        _savedPassword.isNotEmpty) {
      final autoRes = await loginWithAccount(
        username: _username,
        password: _savedPassword,
        loginMethod: _loginMethod,
        rememberPassword: _rememberPassword,
        autoLogin: _autoLogin,
      );
      if (_disposed) return;
      if (autoRes.success) {
        return;
      }
    }

    isConnectionValid = false;
    connectionError = res;
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
      'username': _username,
      'savedPassword': _rememberPassword ? _savedPassword : '',
      'loginMethod': _loginMethod,
      'copeCode': _copeCode,
      'rememberPassword': _rememberPassword,
      'autoLogin': _autoLogin,
      'bgBlur': _bgBlur,
      'bgOpacity': _bgOpacity,
      'dialogBlur': _dialogBlur,
      'dialogOpacity': _dialogOpacity,
      'dropdownBlur': _dropdownBlur,
      'dropdownOpacity': _dropdownOpacity,
      'enableIdleSleep': _enableIdleSleep,
      'idleTimeoutSeconds': _idleTimeoutSeconds,
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

  void setLoginPreferences({
    String? loginMethod,
    bool? rememberPassword,
    bool? autoLogin,
  }) {
    if (loginMethod != null) {
      _loginMethod = loginMethod.trim().toUpperCase() == 'CLOUDMES'
          ? 'CLOUDMES'
          : 'SSO';
    }
    if (rememberPassword != null) {
      _rememberPassword = rememberPassword;
      if (!rememberPassword) {
        _savedPassword = '';
      }
    }
    if (autoLogin != null) {
      _autoLogin = autoLogin;
    }
    _saveConfig(_exportConfigMap());
    notifyListeners();
  }

  Future<MesLoginResult> loginWithAccount({
    required String username,
    required String password,
    String? loginMethod,
    bool? rememberPassword,
    bool? autoLogin,
    String? captchaKey,
    String? captchaCode,
  }) async {
    final cleanUser = username.trim();
    final effectiveMethod =
        (loginMethod ?? _loginMethod).trim().toUpperCase() == 'CLOUDMES'
        ? 'CLOUDMES'
        : 'SSO';
    final effectiveRemember = rememberPassword ?? _rememberPassword;
    final effectiveAuto = autoLogin ?? _autoLogin;

    _isLoggingIn = true;
    notifyListeners();

    try {
      final result = await ApiClient.loginWithCredentials(
        username: cleanUser,
        password: password,
        loginMethod: effectiveMethod,
        copeCode: _copeCode,
        uuid: _uuid,
        lang: _lang,
        captchaKey: captchaKey,
        captchaCode: captchaCode,
      );

      if (_disposed) return result;

      if (result.success) {
        final revision = ++_credentialsRevision;
        _invalidateAll(includeTrace: true);
        _token = result.accessToken;
        _uuid = result.uuid;
        _cookie = result.cookie;
        _username = result.username.isNotEmpty ? result.username : cleanUser;
        _loginMethod = effectiveMethod;
        _rememberPassword = effectiveRemember;
        _autoLogin = effectiveAuto;
        _savedPassword = effectiveRemember ? password : '';
        _manualLogoutInSession = false;
        isConnectionValid = true;
        connectionError = null;
        await _saveConfig(_exportConfigMap());
        if (_disposed || revision != _credentialsRevision) return result;
        _isLoggingIn = false;
        notifyListeners();
        if (_snList.isNotEmpty || _traceHistory.isNotEmpty) {
          refetchAllSns(allowTestRecordFallback: false);
        }
        return result;
      } else {
        _loginMethod = effectiveMethod;
        _rememberPassword = effectiveRemember;
        _autoLogin = effectiveAuto;
        _isLoggingIn = false;
        notifyListeners();
        return result;
      }
    } catch (e) {
      _isLoggingIn = false;
      notifyListeners();
      return MesLoginResult(
        success: false,
        uuid: _uuid,
        username: cleanUser,
        message: e.toString(),
      );
    }
  }

  Future<void> logoutAccount({bool clearSavedPassword = false}) async {
    final oldToken = _token;
    final oldUuid = _uuid;
    final oldCookie = _cookie;

    ++_credentialsRevision;
    _invalidateAll(includeTrace: true);
    _manualLogoutInSession = true;
    _token = '';
    _cookie = '';
    if (clearSavedPassword) {
      _savedPassword = '';
      _rememberPassword = false;
    }
    isConnectionValid = false;
    connectionError = '401 Unauthorized';
    await _saveConfig(_exportConfigMap());
    notifyListeners();

    if (oldToken.isNotEmpty && oldToken != defaultToken) {
      unawaited(
        ApiClient.logoutSession(
          token: oldToken,
          uuid: oldUuid,
          cookie: oldCookie,
          lang: _lang,
        ),
      );
    }
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
    _manualLogoutInSession = false;
    final jwtUser = ApiClient.extractAccountFromJwt(token);
    if (jwtUser.isNotEmpty) {
      _username = jwtUser;
    }
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
    bool? enableIdleSleep,
    int? idleTimeoutSeconds,
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
      enableIdleSleep: enableIdleSleep,
      idleTimeoutSeconds: idleTimeoutSeconds,
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
    bool? enableIdleSleep,
    int? idleTimeoutSeconds,
  }) async {
    final revision = ++_credentialsRevision;
    _invalidateAll(includeTrace: true);
    _token = token;
    _lang = lang;
    _operationId = operationId;
    _uuid = uuid;
    _cookie = cookie;
    _manualLogoutInSession = false;
    final jwtUser = ApiClient.extractAccountFromJwt(token);
    if (jwtUser.isNotEmpty) {
      _username = jwtUser;
    }
    if (bgBlur != null) _bgBlur = bgBlur;
    if (bgOpacity != null) _bgOpacity = bgOpacity;
    if (dialogBlur != null) _dialogBlur = dialogBlur;
    if (dialogOpacity != null) _dialogOpacity = dialogOpacity;
    if (dropdownBlur != null) _dropdownBlur = dropdownBlur;
    if (dropdownOpacity != null) _dropdownOpacity = dropdownOpacity;
    if (enableIdleSleep != null) {
      _enableIdleSleep = enableIdleSleep;
      AppPowerManager.instance.setEnableIdleSleep(enableIdleSleep);
    }
    if (idleTimeoutSeconds != null) {
      _idleTimeoutSeconds = idleTimeoutSeconds;
      AppPowerManager.instance.setIdleTimeout(
        Duration(seconds: idleTimeoutSeconds),
      );
    }
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
    var hasSubmittedSn = false;
    for (var line in lines) {
      final sn = line.trim().toUpperCase();
      if (sn == 'SN') continue;
      if (sn.isNotEmpty && RegExp(r'^[A-Z0-9_-]+$').hasMatch(sn)) {
        if (!_snList.remove(sn)) {
          addedSns.add(sn);
        }
        // Re-submitting an existing SN makes it the most recently checked row.
        _snList.add(sn);
        hasSubmittedSn = true;
      }
    }

    if (hasSubmittedSn) {
      _selectedSn = _snList.last;
      await _saveConfig(_exportConfigMap());
      if (allowTestRecordFallback) {
        _enableTestRecordFallbackFor(addedSns);
      }
      notifyListeners();
      _fetchAllPending();
    }
  }

  /// Fetches all pages of test records for one or more Work Orders (WO) and
  /// adds the unique unit SNs found in those Work Orders into the SN queue,
  /// triggering full parallel SN queries (Test Record, Barcode History,
  /// Component List, SnMaster Next Process/Route) just like batch SN lookup.
  Future<void> addWorkOrders(
    String input, {
    bool allowTestRecordFallback = true,
  }) async {
    final lines = input.split(RegExp(r'[\n\r,;\s]+'));
    final wos = <String>[];
    for (final line in lines) {
      final wo = line.trim();
      if (wo.isEmpty) continue;
      final upper = wo.toUpperCase();
      if (upper == 'WO' || upper == 'WONO' || upper == 'WO_NO') continue;
      if (!wos.contains(wo)) {
        wos.add(wo);
      }
    }
    if (wos.isEmpty) return;

    _setGlobalMessage('');
    _loadingWoCount++;
    notifyListeners();

    try {
      final extractedSns = <String>[];
      final idToUnitSn = <String, String>{};
      final preseededRecords = <String, List<TestRecord>>{};

      for (final wo in wos) {
        var pageIndex = 1;
        var woFoundAny = false;
        while (pageIndex <= 20) {
          if (_disposed) return;
          TestRecordPage page;
          try {
            page = await fetchWorkOrderPage(wo, pageIndex: pageIndex);
          } on StateError {
            return;
          } catch (e) {
            final errText = e.toString().replaceFirst('Exception: ', '');
            _setGlobalMessage(
              'wo_error',
              isError: true,
              values: {'wo': wo, 'error': errText},
            );
            notifyListeners();
            break;
          }

          for (final r in page.records) {
            final candidates =
                [
                      r.internalSn.trim().toUpperCase(),
                      r.sn.trim().toUpperCase(),
                      r.customerSn.trim().toUpperCase(),
                    ]
                    .where(
                      (s) =>
                          s.isNotEmpty && RegExp(r'^[A-Z0-9_-]+$').hasMatch(s),
                    )
                    .toList();
            if (candidates.isEmpty) continue;
            woFoundAny = true;
            String? existingUnit;
            for (final c in candidates) {
              final mapped = idToUnitSn[c];
              if (mapped != null) {
                existingUnit = mapped;
                break;
              }
            }
            if (existingUnit != null) {
              for (final c in candidates) {
                idToUnitSn[c] = existingUnit;
              }
              preseededRecords[existingUnit]?.add(r);
              continue;
            }
            final unitSn = candidates.first;
            for (final c in candidates) {
              idToUnitSn[c] = unitSn;
            }
            extractedSns.add(unitSn);
            preseededRecords[unitSn] = [r];
          }

          if (!page.hasNext || page.records.isEmpty) {
            break;
          }
          pageIndex++;
        }

        if (!woFoundAny && _globalMessageKey.isEmpty) {
          _setGlobalMessage('wo_empty', isError: true, values: {'wo': wo});
          notifyListeners();
        }
      }

      if (extractedSns.isNotEmpty) {
        for (final entry in preseededRecords.entries) {
          if (entry.value.isNotEmpty) {
            _results[entry.key] = entry.value;
            _loadingStatus[entry.key] = false;
            _errors.remove(entry.key);
          }
        }
        await addSns(
          extractedSns.join('\n'),
          allowTestRecordFallback: allowTestRecordFallback,
        );
      }
    } finally {
      _loadingWoCount = (_loadingWoCount - 1).clamp(0, 1 << 30);
      notifyListeners();
    }
  }

  Future<String?> pickFile({bool isSave = false}) async {
    final picker = filePicker;
    if (picker != null) return picker(isSave);
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
    _setGlobalMessage('');
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
      final path = await _pickTemplatePath(script);
      if (path.isEmpty) return; // User canceled

      final file = File(path.replaceAll('"', '').trim());
      await file.writeAsString('SN\nSN123456\nSN789012\n');
      _setGlobalMessage(
        'csv_template_success',
        isError: false,
        values: {'path': path},
      );
    } catch (e) {
      _setGlobalMessage('csv_template_error', values: {'error': '$e'});
    }
    notifyListeners();
  }

  Future<String> _pickTemplatePath(String script) async {
    final picker = filePicker;
    if (picker != null) return await picker(true) ?? '';
    final result = await Process.run('powershell', [
      '-NoProfile',
      '-STA',
      '-Command',
      script,
    ]);
    return result.stdout.toString().trim();
  }

  Future<void> importCsv() async {
    _setGlobalMessage('');
    notifyListeners();
    try {
      final path = await pickFile(isSave: false);
      if (path == null || path.isEmpty) return; // User canceled

      final file = File(path.replaceAll('"', '').trim());
      if (!await file.exists()) {
        _setGlobalMessage('csv_file_not_found');
        notifyListeners();
        return;
      }
      final content = await file.readAsString();
      await addSns(content, allowTestRecordFallback: false);
      _setGlobalMessage(
        'csv_import_success',
        isError: false,
        values: {'path': path},
      );
      notifyListeners();
    } catch (e) {
      _setGlobalMessage('csv_import_error', values: {'error': '$e'});
      notifyListeners();
    }
  }

  Future<void> exportCsv() async {
    _setGlobalMessage('');
    notifyListeners();
    try {
      final path = await pickFile(isSave: true);
      if (path == null || path.isEmpty) return; // User canceled

      final file = File(path.replaceAll('"', '').trim());
      final buffer = StringBuffer();
      // Write Header
      buffer.writeln(
        'SN,Internal SN,Customer SN,Product No,Process Code,Line Station Code,Station ID,Error Code,Test Time,Test Start Time,Test End Time,Duration,Test No,Result,Failure Reason,Fail Desc,Fail Step,Fail Cycle,Major Item,Host Loc,Product Series,WO,EmpNo,MB SN,MAC Group,Collecting Data,Components,GIT/ASN Data,Eqp Params,Zip File,Test Log Path,Qty,Pass Qty,Fail Qty,Repass Qty,FPY,LPY',
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
                r.testStartDate,
                r.testEndDate,
                r.timeDifferenceValue,
                r.testNo,
                r.testResult,
                r.failureReason,
                r.failDesc,
                r.testItemFailStep,
                r.testItemFailCycle,
                r.testMajorItem,
                r.loc,
                r.productSeries,
                r.woNo,
                r.empNo,
                r.mbSn,
                r.macGroup,
                r.collectingData,
                r.components,
                r.gitAsnData,
                r.eqpParams,
                r.zipFileName,
                r.testLogPath,
                r.qty,
                r.passQty,
                r.failQty,
                r.repassQty,
                r.fpy,
                r.lpy,
              ].map(csvField).join(','),
            );
          }
        } else {
          final err = _errors[sn] ?? 'No records / Pending';
          buffer.writeln(
            [sn, ...List<String>.filled(35, ''), err].map(csvField).join(','),
          );
        }
      }

      await file.writeAsString(buffer.toString());
      _setGlobalMessage(
        'csv_export_success',
        isError: false,
        values: {'path': path},
      );
    } catch (e) {
      _setGlobalMessage('csv_export_error', values: {'error': '$e'});
    }
    notifyListeners();
  }

  Future<void> exportBarcodeHistoryCsv() async {
    _setGlobalMessage('');
    notifyListeners();
    try {
      final path = await pickFile(isSave: true);
      if (path == null || path.isEmpty) return;

      final file = File(path.replaceAll('"', '').trim());
      final buffer = StringBuffer();
      buffer.writeln(
        'Product SN,Internal SN,Customer SN,Current Process Code,Current Process Name,Line,Line Station,Equipment No,Result,Operate Date,WO,Plan No,Product No,Product Version,Operator,Landmark Codes,Remark',
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
                r.landMarkCodes,
                r.remark,
              ].map(csvField).join(','),
            );
          }
        }
      }

      await file.writeAsString(buffer.toString());
      _setGlobalMessage(
        'csv_export_success',
        isError: false,
        values: {'path': path},
      );
    } catch (e) {
      _setGlobalMessage('csv_export_error', values: {'error': '$e'});
    }
    notifyListeners();
  }

  Future<void> exportWipComponentsCsv() async {
    _setGlobalMessage('');
    notifyListeners();
    try {
      final path = await pickFile(isSave: true);
      if (path == null || path.isEmpty) return;

      final file = File(path.replaceAll('"', '').trim());
      final buffer = StringBuffer();
      buffer.writeln(
        'Product SN,Internal SN,Customer SN,Material No,Material Name,Category,Component SN,Parsed CSN,Scan Type,Location,Manufacturer,Mfg PN,Date Code,Package ID,Installed Qty,Station Code,Process Code,Created Date,Unlink Time,Check Assembled Code',
      );

      for (final sn in _snList) {
        final records = _wipResults[sn];
        if (records != null && records.isNotEmpty) {
          for (final r in records) {
            buffer.writeln(
              [
                r.productSn,
                r.internalSn,
                r.customerSn,
                r.materialNo,
                r.materialName,
                r.materialCategory,
                r.scannedCsn,
                r.parsedCsn,
                r.scanType,
                r.location,
                r.mfgName,
                r.mfgPn,
                r.dateCode,
                r.pkgId,
                r.installedQty,
                r.stationCode,
                r.processCode,
                r.createdDt,
                r.unlinkTime,
                r.checkAssembledCode,
              ].map(csvField).join(','),
            );
          }
        }
      }

      await file.writeAsString(buffer.toString());
      _setGlobalMessage(
        'csv_export_success',
        isError: false,
        values: {'path': path},
      );
    } catch (e) {
      _setGlobalMessage('csv_export_error', values: {'error': '$e'});
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
    // Storage remains oldest-first; submit requests in the sidebar's order.
    for (final sn in List<String>.of(_snList).reversed) {
      if (results.containsKey(sn) || errors.containsKey(sn)) continue;
      final revision = _revision('sn:$sn');
      bool current() =>
          !_disposed && _snList.contains(sn) && _revision('sn:$sn') == revision;
      loading[sn] = true;
      jobs.add(
        _queue.run(
          (view, sn, revision),
          () async {
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
          },
          isCurrent: current,
          priority: () => _snList.indexOf(sn) + 1,
        ),
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

  /// Queries additional parameters / MAC addresses (`queryComponentParam`) for
  /// a specific WIP component row by its `wipProductComponentId`.
  Future<void> fetchComponentParams(
    int wipProductComponentId, {
    bool force = false,
  }) async {
    if (wipProductComponentId <= 0) return;
    if (!force &&
        (_componentParams.containsKey(wipProductComponentId) ||
            _componentParamsLoading[wipProductComponentId] == true)) {
      return;
    }
    final revision = _credentialsRevision;
    bool current() => !_disposed && revision == _credentialsRevision;
    _componentParamsLoading[wipProductComponentId] = true;
    _componentParamsErrors.remove(wipProductComponentId);
    notifyListeners();

    await _queue.run(('comp_param', wipProductComponentId, revision), () async {
      try {
        final params = await ApiClient.fetchComponentParams(
          wipProductComponentId: wipProductComponentId,
          token: _token,
          lang: _lang,
          operationId: _operationId,
          uuid: _uuid,
          cookie: _cookie,
        );
        if (!current()) return;
        _componentParams[wipProductComponentId] = params;
      } catch (e) {
        if (current()) {
          _componentParamsErrors[wipProductComponentId] = e
              .toString()
              .replaceFirst('Exception: ', '');
        }
      } finally {
        if (current()) {
          _componentParamsLoading[wipProductComponentId] = false;
          notifyListeners();
        }
      }
    }, isCurrent: current);
  }

  /// 1-click navigation from Tab 3 (Component List) -> Tab 4 (Component Trace).
  Future<void> traceComponentFromWip(String csn) async {
    final target = csn.trim().toUpperCase();
    if (target.isEmpty) return;
    setViewMode(ViewMode.componentTrace);
    if (_traceResults.containsKey(target) && _traceErrors[target] == null) {
      if (!_traceHistory.contains(target)) {
        _traceHistory.insert(0, target);
        _saveConfig(_exportConfigMap());
      }
      selectTraceCsn(target);
      return;
    }
    await searchComponentTrace(target);
  }

  /// 1-click navigation from Tab 4 (Component Trace) -> SN Queue (Test Record).
  Future<void> inspectProductSnFromTrace(String productSn) async {
    final target = productSn.trim();
    if (target.isEmpty) return;
    setViewMode(ViewMode.testRecord);
    await addSns(target);
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
    _setGlobalMessage('');
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
      final path = await _pickTemplatePath(script);
      if (path.isEmpty) return; // User canceled

      final file = File(path.replaceAll('"', '').trim());
      await file.writeAsString('CSN\nOPM1106349G1CCX\nQB940AE002627V05171\n');
      _setGlobalMessage(
        'csv_template_success',
        isError: false,
        values: {'path': path},
      );
    } catch (e) {
      _setGlobalMessage('csv_template_error', values: {'error': '$e'});
    }
    notifyListeners();
  }

  Future<void> importTraceCsv() async {
    _setGlobalMessage('');
    notifyListeners();
    try {
      final path = await pickFile(isSave: false);
      if (path == null || path.isEmpty) return; // User canceled

      final file = File(path.replaceAll('"', '').trim());
      if (!await file.exists()) {
        _setGlobalMessage('csv_file_not_found');
        notifyListeners();
        return;
      }
      final content = await file.readAsString();
      await addTraceCsns(content);
      _setGlobalMessage(
        'csv_import_success',
        isError: false,
        values: {'path': path},
      );
      notifyListeners();
    } catch (e) {
      _setGlobalMessage('csv_import_error', values: {'error': '$e'});
      notifyListeners();
    }
  }

  Future<void> exportTraceCsv() async {
    _setGlobalMessage('');
    notifyListeners();
    try {
      final path = await pickFile(isSave: true);
      if (path == null || path.isEmpty) return; // User canceled

      final file = File(path.replaceAll('"', '').trim());
      final buffer = StringBuffer();
      buffer.writeln(
        'Component SN,Parsed CSN,MAC,Scan Type,Product SN,Material No,Material Name,Material Version,Customer Material No,Category,Manufacturer,Mfg Part No,Product No,Line Code,Process Code,WO,Qty,Process Time,Assembled Status',
      );

      for (final csn in _traceHistory) {
        final records = _traceResults[csn];
        if (records != null && records.isNotEmpty) {
          for (final r in records) {
            buffer.writeln(
              [
                csn,
                r.parsedCsn,
                r.mac,
                r.scanType,
                r.productSn,
                r.materialNo,
                r.materialName,
                r.materialVersion,
                r.customerMaterialNo,
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
            [csn, ...List<String>.filled(17, ''), err].map(csvField).join(','),
          );
        }
      }

      await file.writeAsString(buffer.toString());
      _setGlobalMessage(
        'csv_export_success',
        isError: false,
        values: {'path': path},
      );
    } catch (e) {
      _setGlobalMessage('csv_export_error', values: {'error': '$e'});
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
