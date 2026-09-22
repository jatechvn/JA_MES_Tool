import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../constants.dart';

/// Semantic Versioning (SemVer) parser and comparator for JA MES Tool
class SemanticVersion implements Comparable<SemanticVersion> {
  final int major;
  final int minor;
  final int patch;
  final int? build;
  final String raw;
  final String? prerelease;

  const SemanticVersion({
    required this.major,
    required this.minor,
    required this.patch,
    this.build,
    required this.raw,
    this.prerelease,
  });

  /// Parses version strings like '2.9.7', 'v2.9.7', '2.9.7+21', '2.9.8-beta'
  static SemanticVersion? tryParse(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    final clean = input.trim().toLowerCase().replaceAll(RegExp(r'^[vV]'), '');
    if (!RegExp(
      r'^\d+\.\d+(?:\.\d+)?(?:-[0-9a-z.-]+)?(?:\+\d+)?$',
    ).hasMatch(clean)) {
      return null;
    }
    final pre = RegExp(r'-([^+]+)').firstMatch(clean)?.group(1);

    // Extract build number after '+'
    int? buildNum;
    String versionCore = clean;
    if (clean.contains('+')) {
      final parts = clean.split('+');
      versionCore = parts[0];
      buildNum = int.tryParse(parts[1]);
    }

    // Strip pre-release suffix (e.g. -beta, -rc1)
    if (versionCore.contains('-')) {
      versionCore = versionCore.split('-')[0];
    }

    final segments = versionCore.split('.');
    if (segments.isEmpty) return null;

    final major = int.tryParse(segments[0]);
    if (major == null) return null;
    final minor = segments.length > 1 ? int.tryParse(segments[1]) : 0;
    if (minor == null) return null;
    final patch = segments.length > 2 ? int.tryParse(segments[2]) : 0;
    if (patch == null) return null;

    return SemanticVersion(
      major: major,
      minor: minor,
      patch: patch,
      build: buildNum,
      raw: input.trim(),
      prerelease: pre,
    );
  }

  @override
  int compareTo(SemanticVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    if (patch != other.patch) return patch.compareTo(other.patch);
    if (prerelease != other.prerelease) {
      if (prerelease == null) return 1;
      if (other.prerelease == null) return -1;
      final a = prerelease!.split('.');
      final b = other.prerelease!.split('.');
      for (var i = 0; i < a.length && i < b.length; i++) {
        final x = int.tryParse(a[i]);
        final y = int.tryParse(b[i]);
        final comparison = x != null && y != null
            ? x.compareTo(y)
            : x != null
            ? -1
            : y != null
            ? 1
            : a[i].compareTo(b[i]);
        if (comparison != 0) return comparison;
      }
      if (a.length != b.length) return a.length.compareTo(b.length);
    }
    final b1 = build ?? 0;
    final b2 = other.build ?? 0;
    return b1.compareTo(b2);
  }

  bool operator >(SemanticVersion other) => compareTo(other) > 0;
  bool operator <(SemanticVersion other) => compareTo(other) < 0;
  bool operator >=(SemanticVersion other) => compareTo(other) >= 0;
  bool operator <=(SemanticVersion other) => compareTo(other) <= 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SemanticVersion && compareTo(other) == 0;
  }

  @override
  int get hashCode => Object.hash(major, minor, patch, build ?? 0, prerelease);

  @override
  String toString() {
    final base =
        '$major.$minor.$patch${prerelease == null ? '' : '-$prerelease'}';
    return build != null && build! > 0 ? '$base+$build' : base;
  }

  String get displayVersion => 'v$this';
}

/// Information about an update package discovered on the server
class UpdatePackageInfo {
  final SemanticVersion version;
  final String fileName;
  final String fullPath;
  final int fileSize;
  final String? releaseNotes;
  final DateTime? releaseDate;

  const UpdatePackageInfo({
    required this.version,
    required this.fileName,
    required this.fullPath,
    required this.fileSize,
    this.releaseNotes,
    this.releaseDate,
  });

  String get formattedSize {
    if (fileSize <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = fileSize.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(i == 0 ? 0 : 2)} ${suffixes[i]}';
  }
}

/// Result of checking for updates
class UpdateCheckResult {
  final bool hasUpdate;
  final UpdatePackageInfo? packageInfo;
  final String currentVersion;
  final String? errorMessage;
  final bool isConnectionSuccess;

  const UpdateCheckResult({
    required this.hasUpdate,
    this.packageInfo,
    required this.currentVersion,
    this.errorMessage,
    this.isConnectionSuccess = true,
  });
}

/// OTA update configuration persisted in update_config.json
class OtaUpdateConfig {
  final String serverPath;
  final String username;
  final String password;
  final String checkInterval; // 'daily', 'weekly', 'monthly', 'off'
  final bool autoDownload;
  final DateTime? lastCheckTime;
  final String? cachedUpdateVersion;

  const OtaUpdateConfig({
    required this.serverPath,
    required this.username,
    required this.password,
    this.checkInterval = 'daily',
    this.autoDownload = false,
    this.lastCheckTime,
    this.cachedUpdateVersion,
  });

  factory OtaUpdateConfig.defaults() => const OtaUpdateConfig(
    serverPath: r'\\10.81.141.226\temp\FBT\JA_PROJECT\JA_Update\JA_MES_Tool',
    username: '',
    password: '',
    checkInterval: 'daily',
    autoDownload: false,
  );

  factory OtaUpdateConfig.fromJson(Map<String, dynamic> json) {
    return OtaUpdateConfig(
      serverPath:
          json['serverPath'] as String? ??
          r'\\10.81.141.226\temp\FBT\JA_PROJECT\JA_Update\JA_MES_Tool',
      username: json['username'] as String? ?? '',
      // Network passwords are session-only and must never be read from disk.
      password: '',
      checkInterval: json['checkInterval'] as String? ?? 'daily',
      autoDownload: json['autoDownload'] as bool? ?? false,
      lastCheckTime: json['lastCheckTime'] != null
          ? DateTime.tryParse(json['lastCheckTime'].toString())
          : null,
      cachedUpdateVersion: json['cachedUpdateVersion'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'serverPath': serverPath,
    'username': username,
    'checkInterval': checkInterval,
    'autoDownload': autoDownload,
    'lastCheckTime': lastCheckTime?.toIso8601String(),
    'cachedUpdateVersion': cachedUpdateVersion,
  };

  OtaUpdateConfig copyWith({
    String? serverPath,
    String? username,
    String? password,
    String? checkInterval,
    bool? autoDownload,
    DateTime? lastCheckTime,
    String? cachedUpdateVersion,
    bool clearCachedUpdateVersion = false,
  }) {
    return OtaUpdateConfig(
      serverPath: serverPath ?? this.serverPath,
      username: username ?? this.username,
      password: password ?? this.password,
      checkInterval: checkInterval ?? this.checkInterval,
      autoDownload: autoDownload ?? this.autoDownload,
      lastCheckTime: lastCheckTime ?? this.lastCheckTime,
      cachedUpdateVersion: clearCachedUpdateVersion
          ? null
          : (cachedUpdateVersion ?? this.cachedUpdateVersion),
    );
  }
}

/// How a share folder was opened. Credentials are skipped when Windows can
/// already read the path with the signed-in session.
enum ShareAccessMode { none, currentSession, credentials, localPath }

/// Result of a share reachability probe. [errorMessage] is safe to show in
/// the update tab: it never includes the password.
class SmbConnectResult {
  final bool connected;
  final String? errorMessage;
  final ShareAccessMode accessMode;

  const SmbConnectResult({
    required this.connected,
    this.errorMessage,
    this.accessMode = ShareAccessMode.none,
  });
}

/// Service managing checking, downloading and applying LAN OTA updates
class OtaUpdateService {
  static final RegExp _packageNamePattern = RegExp(
    r'^JA_MES_Tool_[vV]?(\d+\.\d+(?:\.\d+)?(?:-[0-9a-z.-]+)?(?:\+\d+)?)(?:_Windows_x64)?\.zip$',
    caseSensitive: false,
  );

  /// Parses a release version only from the supported Windows archive name.
  /// This prevents `version.json` from pointing the updater at arbitrary ZIPs.
  static SemanticVersion? packageVersionFromFileName(String name) {
    final match = _packageNamePattern.firstMatch(name);
    return match == null ? null : SemanticVersion.tryParse(match.group(1));
  }

  static bool isValidPackageName(String name) =>
      packageVersionFromFileName(name) != null;

  static bool _sameReleaseVersion(
    SemanticVersion metadata,
    SemanticVersion archive,
  ) =>
      metadata.major == archive.major &&
      metadata.minor == archive.minor &&
      metadata.patch == archive.patch &&
      metadata.prerelease == archive.prerelease;

  static String _psLiteral(String value) => "'${value.replaceAll("'", "''")}'";

  static Future<ProcessResult> _runPowerShell(String script) {
    final encoded = base64Encode(
      script.codeUnits.expand((c) => [c & 255, c >> 8]).toList(),
    );
    return Process.run('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-EncodedCommand',
      encoded,
    ]);
  }

  bool _applying = false;
  static final OtaUpdateService _instance = OtaUpdateService._internal();
  factory OtaUpdateService() => _instance;
  OtaUpdateService._internal();

  final List<VoidCallback> _listeners = [];

  /// Package found by the latest successful scan, kept for the top-bar badge.
  UpdatePackageInfo? pendingPackage;

  /// `false` after a share probe or scan could not reach the folder.
  /// `true` after a completed scan. `null` before the first attempt.
  bool? sessionConnected;
  String? sessionDetail;

  File? _customConfigFileForTesting;
  Directory? _customServerDirForTesting;
  OtaUpdateConfig? _cachedConfig;

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }

  /// Version label for the top-bar badge, or null when nothing newer is known.
  String? get advertisedUpdateLabel {
    final pending = pendingPackage;
    if (pending != null) return pending.version.displayVersion;
    final cached = SemanticVersion.tryParse(currentConfig.cachedUpdateVersion);
    final current = SemanticVersion.tryParse(appVersion);
    if (cached != null && current != null && cached > current) {
      return cached.displayVersion;
    }
    return null;
  }

  @visibleForTesting
  void resetSessionForTesting() {
    pendingPackage = null;
    sessionConnected = null;
    sessionDetail = null;
  }

  @visibleForTesting
  void setCustomConfigFileForTesting(File? file) {
    _customConfigFileForTesting = file;
    _cachedConfig = null;
  }

  @visibleForTesting
  void setCustomServerDirForTesting(Directory? dir) {
    _customServerDirForTesting = dir;
  }

  /// Returns path to update_config.json:
  /// 1. Next to the .exe file if exists (portable deployment)
  /// 2. AppData directory (%APPDATA%\JA_MES_Tool\update_config.json)
  File getConfigFile() {
    if (_customConfigFileForTesting != null) {
      return _customConfigFileForTesting!;
    }

    try {
      final exeDir = File(Platform.resolvedExecutable).parent;
      final exeConfig = File(
        '${exeDir.path}${Platform.pathSeparator}update_config.json',
      );
      if (exeConfig.existsSync()) {
        return exeConfig;
      }
    } catch (_) {}

    final appData = Platform.environment['APPDATA'];
    if (appData != null && appData.isNotEmpty) {
      final dir = Directory('$appData\\JA_MES_Tool');
      if (!dir.existsSync()) {
        try {
          dir.createSync(recursive: true);
        } catch (_) {}
      }
      return File('${dir.path}\\update_config.json');
    }
    return File('update_config.json');
  }

  /// Loads configuration from update_config.json
  Future<OtaUpdateConfig> loadConfig() async {
    if (_cachedConfig != null) return _cachedConfig!;
    try {
      final file = getConfigFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final json = jsonDecode(content) as Map<String, dynamic>;
          final hadLegacyPassword = json.containsKey('password');
          _cachedConfig = OtaUpdateConfig.fromJson(json);
          if (hadLegacyPassword) {
            // Migrate previously-written plaintext credentials out of the
            // update configuration as soon as it is next loaded.
            await saveConfig(_cachedConfig!);
          }
          return _cachedConfig!;
        }
      }
    } catch (e) {
      debugPrint('[OtaUpdateService] Load config error: $e');
    }
    _cachedConfig = OtaUpdateConfig.defaults();
    return _cachedConfig!;
  }

  /// Saves configuration to update_config.json
  Future<void> saveConfig(OtaUpdateConfig config) async {
    _cachedConfig = config;
    try {
      final file = getConfigFile();
      final encoder = const JsonEncoder.withIndent('  ');
      await file.writeAsString(encoder.convert(config.toJson()), flush: true);
    } catch (e) {
      debugPrint('[OtaUpdateService] Save config error: $e');
    }
    _notifyListeners();
  }

  /// Current cached configuration or defaults
  OtaUpdateConfig get currentConfig =>
      _cachedConfig ?? OtaUpdateConfig.defaults();

  /// Updates configuration with new values and persists to disk
  Future<void> updateConfig({
    String? serverPath,
    String? username,
    String? password,
    String? checkInterval,
    bool? autoDownload,
  }) async {
    final current = await loadConfig();
    final updated = current.copyWith(
      serverPath: serverPath,
      username: username,
      password: password,
      checkInterval: checkInterval,
      autoDownload: autoDownload,
    );
    await saveConfig(updated);
  }

  /// Checks whether it is time for an automatic update check
  bool shouldCheckForUpdates({
    required String interval,
    DateTime? lastCheckTime,
    DateTime? now,
  }) {
    if (interval == 'off') return false;
    if (lastCheckTime == null) return true;

    final currentTime = now ?? DateTime.now();
    final elapsed = currentTime.difference(lastCheckTime);

    switch (interval) {
      case 'daily':
        return elapsed.inHours >= 24;
      case 'weekly':
        return elapsed.inDays >= 7;
      case 'monthly':
        return elapsed.inDays >= 30;
      case 'startup':
      case 'off':
        return false;
      default:
        return elapsed.inHours >= 24;
    }
  }

  /// How long until the next in-session scan. `null` for `off` and `startup`
  /// (those modes do not poll while the window stays open). [Duration.zero]
  /// means the check is already due.
  Duration? timeUntilNextCheck({
    required String interval,
    DateTime? lastCheckTime,
    DateTime? now,
  }) {
    if (interval == 'off' || interval == 'startup') return null;
    if (shouldCheckForUpdates(
      interval: interval,
      lastCheckTime: lastCheckTime,
      now: now,
    )) {
      return Duration.zero;
    }
    final currentTime = now ?? DateTime.now();
    final elapsed = currentTime.difference(lastCheckTime!);
    final window = switch (interval) {
      'weekly' => const Duration(days: 7),
      'monthly' => const Duration(days: 30),
      _ => const Duration(hours: 24),
    };
    final remaining = window - elapsed;
    if (remaining <= Duration.zero) return Duration.zero;
    return remaining;
  }

  /// Arguments for `net use`, without a shell. Empty credentials are omitted
  /// so a blank password is not sent as a literal argument.
  @visibleForTesting
  static List<String> smbUseArguments({
    required String shareRoot,
    required String username,
    required String password,
  }) {
    final args = <String>['use', shareRoot];
    if (password.isNotEmpty) args.add(password);
    if (username.isNotEmpty) args.add('/user:$username');
    return args;
  }

  static String _shortNetMessage(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.isEmpty) return 'net use failed';
    if (cleaned.length <= 280) return cleaned;
    return '${cleaned.substring(0, 280)}…';
  }

  /// Extracts SMB share root from a UNC path (e.g. '\\10.81.141.226\temp')
  static String? extractSmbShareRoot(String uncPath) {
    final normalized = uncPath.replaceAll('/', '\\');
    if (!normalized.startsWith(r'\\')) return null;

    final parts = normalized.substring(2).split('\\');
    if (parts.length < 2) return null;
    return '\\\\${parts[0]}\\${parts[1]}';
  }

  /// UNC paths that are already readable use the Windows session. A drive
  /// letter or local folder never needs a network account.
  @visibleForTesting
  static ShareAccessMode accessModeForOpenPath(
    String targetPath, {
    required bool viaCredentials,
  }) {
    if (viaCredentials) return ShareAccessMode.credentials;
    final normalized = targetPath.replaceAll('/', '\\');
    if (normalized.startsWith(r'\\')) return ShareAccessMode.currentSession;
    return ShareAccessMode.localPath;
  }

  /// Connects to an SMB share with `net use` when credentials are present.
  /// A folder that is already reachable is left alone.
  Future<SmbConnectResult> connectSmbShare({
    String? path,
    String? username,
    String? password,
  }) async {
    if (_customServerDirForTesting != null) {
      final exists = await _customServerDirForTesting!.exists();
      return SmbConnectResult(
        connected: exists,
        errorMessage: exists ? null : 'Server directory does not exist',
      );
    }

    final cfg = await loadConfig();
    final targetPath = (path ?? cfg.serverPath).trim();
    final user = username ?? cfg.username;
    final pass = password ?? cfg.password;
    if (targetPath.isEmpty) {
      return const SmbConnectResult(
        connected: false,
        errorMessage: 'Update server path is empty',
      );
    }

    final normalized = targetPath.replaceAll('/', '\\');
    if (!normalized.startsWith(r'\\')) {
      try {
        final exists = await Directory(targetPath).exists();
        return SmbConnectResult(
          connected: exists,
          accessMode: exists ? ShareAccessMode.localPath : ShareAccessMode.none,
          errorMessage: exists
              ? null
              : 'Server directory does not exist: $targetPath',
        );
      } catch (e) {
        return SmbConnectResult(
          connected: false,
          errorMessage: 'Cannot access $targetPath: $e',
        );
      }
    }

    try {
      if (await Directory(targetPath).exists()) {
        return SmbConnectResult(
          connected: true,
          accessMode: accessModeForOpenPath(targetPath, viaCredentials: false),
        );
      }
    } catch (e) {
      debugPrint('[OtaUpdateService] Share exists check failed: $e');
    }

    final shareRoot = extractSmbShareRoot(targetPath);
    if (shareRoot != null &&
        Platform.isWindows &&
        (user.isNotEmpty || pass.isNotEmpty)) {
      try {
        final result = await Process.run(
          'net',
          smbUseArguments(shareRoot: shareRoot, username: user, password: pass),
        );
        final out = _shortNetMessage('${result.stdout} ${result.stderr}');
        if (result.exitCode == 0) {
          final exists = await Directory(targetPath).exists();
          return SmbConnectResult(
            connected: exists,
            accessMode: exists
                ? ShareAccessMode.credentials
                : ShareAccessMode.none,
            errorMessage: exists
                ? null
                : 'Share authenticated but folder is missing: $targetPath',
          );
        }
        if (out.contains('1219')) {
          final exists = await Directory(targetPath).exists();
          if (exists) {
            return SmbConnectResult(
              connected: true,
              accessMode: accessModeForOpenPath(
                targetPath,
                viaCredentials: false,
              ),
            );
          }
          return SmbConnectResult(
            connected: false,
            errorMessage:
                'Share is already connected with different credentials (1219): $shareRoot',
          );
        }
        return SmbConnectResult(connected: false, errorMessage: out);
      } catch (e) {
        debugPrint('[OtaUpdateService] net use error: $e');
        return SmbConnectResult(
          connected: false,
          errorMessage: 'net use error: $e',
        );
      }
    }

    return SmbConnectResult(
      connected: false,
      errorMessage: 'Cannot connect to server share: $targetPath',
    );
  }

  /// Probes the share folder only. Does not scan packages and does not move
  /// [OtaUpdateConfig.lastCheckTime].
  Future<SmbConnectResult> testConnection({
    String? path,
    String? username,
    String? password,
  }) async {
    final result = await connectSmbShare(
      path: path,
      username: username,
      password: password,
    );
    sessionConnected = result.connected;
    sessionDetail = result.connected ? null : result.errorMessage;
    _notifyListeners();
    return result;
  }

  void _markUnreachable(String message) {
    sessionConnected = false;
    sessionDetail = message;
    _notifyListeners();
  }

  /// Checks for available updates on the server.
  ///
  /// [isManual] still records the schedule after a completed scan. Share
  /// probes must use [testConnection], which leaves the cycle untouched.
  /// A failed connection does not advance [OtaUpdateConfig.lastCheckTime].
  Future<UpdateCheckResult> checkForUpdates({
    String? overrideServerPath,
    String? overrideUsername,
    String? overridePassword,
    String? overrideCurrentVersion,
    bool isManual = false,
    bool recordCheckTime = true,
  }) async {
    final cfg = await loadConfig();
    final serverPath = overrideServerPath ?? cfg.serverPath;
    final currentVerStr = overrideCurrentVersion ?? appVersion;
    final currentSemVer =
        SemanticVersion.tryParse(currentVerStr) ??
        const SemanticVersion(major: 1, minor: 0, patch: 0, raw: '1.0.0');

    Future<void> rememberCompletedCheck({
      required bool hasUpdate,
      required UpdatePackageInfo? package,
    }) async {
      pendingPackage = hasUpdate ? package : null;
      sessionConnected = true;
      sessionDetail = null;
      var next = cfg;
      // Manual and scheduled scans both stamp the cycle. The stamp is applied
      // together with cachedUpdateVersion so a later write cannot roll it back.
      if (recordCheckTime || isManual) {
        next = next.copyWith(lastCheckTime: DateTime.now());
      }
      if (hasUpdate && package != null) {
        next = next.copyWith(cachedUpdateVersion: package.version.toString());
      } else {
        next = next.copyWith(clearCachedUpdateVersion: true);
      }
      await saveConfig(next);
    }

    final connection = await connectSmbShare(
      path: serverPath,
      username: overrideUsername,
      password: overridePassword,
    );
    if (!connection.connected) {
      final message =
          connection.errorMessage ??
          'Cannot connect to server share: $serverPath';
      _markUnreachable(message);
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: currentVerStr,
        isConnectionSuccess: false,
        errorMessage: message,
      );
    }

    final Directory dir = _customServerDirForTesting ?? Directory(serverPath);
    if (!await dir.exists()) {
      const message = 'Server directory does not exist';
      _markUnreachable('$message: $serverPath');
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: currentVerStr,
        isConnectionSuccess: false,
        errorMessage: '$message: $serverPath',
      );
    }

    // 2. Try reading version.json if present
    final versionJsonFile = File(
      '${dir.path}${Platform.pathSeparator}version.json',
    );
    if (await versionJsonFile.exists()) {
      try {
        final content = await versionJsonFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final verStr = json['version'] as String?;
        final fileName = json['fileName'] as String? ?? json['file'] as String?;
        final notes =
            json['releaseNotes'] as String? ?? json['changelog'] as String?;
        final dateStr = json['releaseDate'] as String?;

        final serverSemVer = SemanticVersion.tryParse(verStr);
        final archiveSemVer = fileName == null
            ? null
            : packageVersionFromFileName(fileName);
        if (serverSemVer != null &&
            fileName != null &&
            archiveSemVer != null &&
            _sameReleaseVersion(serverSemVer, archiveSemVer)) {
          final zipFile = File('${dir.path}${Platform.pathSeparator}$fileName');
          if (await zipFile.exists()) {
            final hasUpdate = serverSemVer > currentSemVer;
            final pkg = UpdatePackageInfo(
              version: serverSemVer,
              fileName: fileName,
              fullPath: zipFile.path,
              fileSize: await zipFile.length(),
              releaseNotes: notes,
              releaseDate: dateStr != null ? DateTime.tryParse(dateStr) : null,
            );
            await rememberCompletedCheck(hasUpdate: hasUpdate, package: pkg);
            return UpdateCheckResult(
              hasUpdate: hasUpdate,
              packageInfo: pkg,
              currentVersion: currentVerStr,
            );
          }
        }
      } catch (e) {
        debugPrint('[OtaUpdateService] Parse version.json error: $e');
      }
    }

    // 3. Scan for .zip candidate files in directory
    try {
      final List<FileSystemEntity> entries = await dir
          .list(followLinks: false)
          .toList();
      final List<UpdatePackageInfo> candidates = [];

      for (final entity in entries) {
        if (entity is File && entity.path.toLowerCase().endsWith('.zip')) {
          final fileName = entity.path.split(Platform.pathSeparator).last;
          final semVer = packageVersionFromFileName(fileName);
          if (semVer != null) {
            int size = 0;
            try {
              size = await entity.length();
            } catch (_) {}
            candidates.add(
              UpdatePackageInfo(
                version: semVer,
                fileName: fileName,
                fullPath: entity.path,
                fileSize: size,
              ),
            );
          }
        }
      }

      if (candidates.isEmpty) {
        await rememberCompletedCheck(hasUpdate: false, package: null);
        return UpdateCheckResult(
          hasUpdate: false,
          currentVersion: currentVerStr,
          errorMessage: 'No matching update .zip package found on server',
        );
      }

      // Sort descending to find the highest version
      candidates.sort((a, b) => b.version.compareTo(a.version));
      final latestPkg = candidates.first;
      final hasUpdate = latestPkg.version > currentSemVer;

      await rememberCompletedCheck(hasUpdate: hasUpdate, package: latestPkg);

      return UpdateCheckResult(
        hasUpdate: hasUpdate,
        packageInfo: latestPkg,
        currentVersion: currentVerStr,
      );
    } catch (e) {
      final message = 'Error scanning update packages: $e';
      _markUnreachable(message);
      return UpdateCheckResult(
        hasUpdate: false,
        currentVersion: currentVerStr,
        isConnectionSuccess: false,
        errorMessage: message,
      );
    }
  }

  /// Downloads, validates, and initiates installation of the update package
  Future<void> performUpdate(
    UpdatePackageInfo packageInfo, {
    void Function(double progress, String status)? onProgress,
  }) async {
    if (!Platform.isWindows) throw UnsupportedError('OTA requires Windows');
    if (_applying) throw StateError('An update is already running');
    _applying = true;
    try {
      await _performUpdate(packageInfo, onProgress: onProgress);
    } finally {
      _applying = false;
    }
  }

  Future<Directory> _performUpdate(
    UpdatePackageInfo packageInfo, {
    void Function(double progress, String status)? onProgress,
    bool prepareOnly = false,
  }) async {
    final archiveVersion = packageVersionFromFileName(packageInfo.fileName);
    final sourceZip = File(packageInfo.fullPath);
    final sourceFileName = sourceZip.path.split(Platform.pathSeparator).last;
    if (archiveVersion == null ||
        !_sameReleaseVersion(packageInfo.version, archiveVersion) ||
        sourceFileName != packageInfo.fileName) {
      throw StateError('Update package identity validation failed');
    }

    onProgress?.call(0.05, 'Initializing temporary workspace...');

    final tempBase = await Directory.systemTemp.createTemp(
      'JA_MES_Tool_Update_',
    );
    final localZipFile = File('${tempBase.path}/update.zip');
    final totalBytes = await sourceZip.length();
    if (totalBytes == 0 ||
        (packageInfo.fileSize > 0 && totalBytes != packageInfo.fileSize)) {
      throw StateError('Update package size changed; please check again');
    }

    final writer = localZipFile.openWrite();
    var copied = 0;
    try {
      await for (final chunk in sourceZip.openRead()) {
        writer.add(chunk);
        copied += chunk.length;
        onProgress?.call(
          (0.1 + copied / totalBytes * 0.5).clamp(0.1, 0.6),
          'Downloading update (${((copied / totalBytes) * 100).toInt()}%)...',
        );
      }
      await writer.flush();
    } finally {
      await writer.close();
    }
    if (copied != totalBytes) throw StateError('Incomplete update download');

    // 2. Extract update archive with Zip Slip protection
    onProgress?.call(0.65, 'Extracting update package...');
    final extractDir = Directory('${tempBase.path}\\extracted');
    extractDir.createSync(recursive: true);

    final validation = await _runPowerShell("""
\$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
\$zip = [IO.Compression.ZipFile]::OpenRead(${_psLiteral(localZipFile.path)})
try {
  foreach (\$entry in \$zip.Entries) {
    \$parts = \$entry.FullName.Replace('\\', '/').Split('/')
    if (\$entry.FullName -match '^[\\/]' -or \$entry.FullName.Contains(':') -or \$parts -contains '..' -or ((\$entry.ExternalAttributes -shr 16) -band 61440) -eq 40960) { throw 'Unsafe archive entry' }
  }
  [IO.Compression.ZipFileExtensions]::ExtractToDirectory(\$zip, ${_psLiteral(extractDir.path)})
} finally { \$zip.Dispose() }
""");
    if (validation.exitCode != 0) {
      throw StateError('Invalid or unsafe update archive');
    }

    // 3. Locate payload directory (handle parent folder wrapper)
    onProgress?.call(0.85, 'Validating package integrity...');
    Directory payloadDir = extractDir;

    final subDirs = extractDir.listSync().whereType<Directory>().toList();
    if (subDirs.length == 1) {
      final testExe = File('${subDirs.first.path}\\ja_mes_tool.exe');
      if (testExe.existsSync()) {
        payloadDir = subDirs.first;
      }
    }

    for (final name in ['ja_mes_tool.exe', 'flutter_windows.dll', 'data']) {
      if (!await FileSystemEntity.isFile('${payloadDir.path}/$name') &&
          !await FileSystemEntity.isDirectory('${payloadDir.path}/$name')) {
        throw StateError('Incomplete Flutter update package: $name missing');
      }
    }

    if (prepareOnly) return payloadDir;

    // 4. Identify currently executing application
    final currentExe = File(Platform.resolvedExecutable);
    final targetAppDir = currentExe.parent;
    final currentPid = pid;

    // 5. Generate apply_update.bat script
    final batFile = File('${tempBase.path}\\apply_update.bat');
    final batContent = generateApplyUpdateScript(
      oldPid: currentPid,
      sourceDir: payloadDir.path,
      targetDir: targetAppDir.path,
      exeName: currentExe.path.split(Platform.pathSeparator).last,
    );
    batFile.writeAsStringSync(batContent);

    onProgress?.call(1.0, 'Ready! Restarting to apply update...');
    await Future.delayed(const Duration(milliseconds: 600));

    // 6. Launch apply_update.bat detached and terminate current process
    if (Platform.isWindows) {
      final launch = await _runPowerShell(
        "Start-Process -FilePath 'cmd.exe' -ArgumentList ${_psLiteral('/c ""${batFile.path}""')} -WindowStyle Hidden",
      );
      if (launch.exitCode != 0) {
        throw StateError('Cannot start update installer');
      }
      exit(0);
    }
    return payloadDir;
  }

  @visibleForTesting
  Future<Directory> validatePackageForTesting(UpdatePackageInfo package) =>
      _performUpdate(package, prepareOnly: true);

  static String generateApplyUpdateScript({
    required int oldPid,
    required String sourceDir,
    required String targetDir,
    required String exeName,
  }) {
    for (final value in [sourceDir, targetDir, exeName]) {
      if (value.contains(RegExp(r'["%\r\n]'))) {
        throw ArgumentError('Unsupported updater path');
      }
    }
    if (oldPid <= 0 || exeName.contains(RegExp(r'[\\/]'))) {
      throw ArgumentError('Invalid updater target');
    }
    return '''@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul
title JA MES Tool - Updating to New Version...

set "OLD_PID=$oldPid"
set "SRC_DIR=$sourceDir"
set "DST_DIR=$targetDir"
set "EXE_NAME=$exeName"
set "BACKUP_DIR=%~dp0backup"
if not exist "%SRC_DIR%\\%EXE_NAME%" exit /b 10
if not exist "%DST_DIR%\\%EXE_NAME%" exit /b 11
set /a WAIT_COUNT=0

echo ========================================================
echo   JA MES TOOL - AUTOMATED OTA UPDATE INSTALLER
echo ========================================================
echo.
echo [1/3] Waiting for old process (PID %OLD_PID%) to terminate...

:wait_loop
set /a WAIT_COUNT+=1
if %WAIT_COUNT% GEQ 60 exit /b 12
timeout /t 1 /nobreak >nul
tasklist /fi "PID eq %OLD_PID%" 2>nul | findstr /i "%OLD_PID%" >nul
if not errorlevel 1 goto wait_loop

timeout /t 1 /nobreak >nul

echo [2/3] Updating application files (preserving config.json and logs)...
if exist "%DST_DIR%\\config.json" copy /y "%DST_DIR%\\config.json" "%~dp0config.json.keep" >nul
if exist "%DST_DIR%\\config.ini" copy /y "%DST_DIR%\\config.ini" "%~dp0config.ini.keep" >nul
if exist "%DST_DIR%\\update_config.json" copy /y "%DST_DIR%\\update_config.json" "%~dp0update_config.json.keep" >nul
robocopy "%DST_DIR%" "%BACKUP_DIR%" /E /NP /R:2 /W:1 /XD logs /XF config.json config.ini update_config.json >"%~dp0backup.log"
if errorlevel 8 exit /b 13
robocopy "%SRC_DIR%" "%DST_DIR%" /E /IS /IT /NP /R:5 /W:2 /XD logs /XF config.json config.ini update_config.json >"%~dp0apply.log"
if errorlevel 8 goto rollback
if exist "%~dp0config.json.keep" copy /y "%~dp0config.json.keep" "%DST_DIR%\\config.json" >nul
if exist "%~dp0config.ini.keep" copy /y "%~dp0config.ini.keep" "%DST_DIR%\\config.ini" >nul
if exist "%~dp0update_config.json.keep" copy /y "%~dp0update_config.json.keep" "%DST_DIR%\\update_config.json" >nul

echo [3/3] Launching updated application...
start "" "%DST_DIR%\\%EXE_NAME%"

timeout /t 2 /nobreak >nul
exit /b 0

:rollback
robocopy "%BACKUP_DIR%" "%DST_DIR%" /E /IS /IT /NP /R:2 /W:1 >"%~dp0rollback.log"
if errorlevel 8 exit /b 14
if exist "%~dp0config.json.keep" copy /y "%~dp0config.json.keep" "%DST_DIR%\\config.json" >nul
if exist "%~dp0config.ini.keep" copy /y "%~dp0config.ini.keep" "%DST_DIR%\\config.ini" >nul
if exist "%~dp0update_config.json.keep" copy /y "%~dp0update_config.json.keep" "%DST_DIR%\\update_config.json" >nul
start "" "%DST_DIR%\\%EXE_NAME%"
exit /b 15
''';
  }
}
