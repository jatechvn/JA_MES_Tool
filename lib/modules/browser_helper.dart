import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

final _logger = Logger('BrowserHelper');

class ExtractedCredentials {
  final String? token;
  final String? lang;
  final String? operationId;
  final String? uuid;
  final String? cookie;

  ExtractedCredentials({
    this.token,
    this.lang,
    this.operationId,
    this.uuid,
    this.cookie,
  });
}

class _CdpEndpoint {
  final String profileDir;
  final int port;
  final List<dynamic> targets;

  const _CdpEndpoint({
    required this.profileDir,
    required this.port,
    required this.targets,
  });
}

class BrowserHelper {
  static const String mesUrl =
      'https://vncmes.ces.myfiinet.com/#/zh-CN/ims/mes/report/test-record';
  static const Duration _cdpProbeTimeout = Duration(seconds: 2);
  static const Duration _cdpStartupTimeout = Duration(seconds: 10);

  static String? _activeProfileDir;
  static Future<bool>? _launchInProgress;

  static String _profileRootPath() {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    final root = localAppData == null || localAppData.isEmpty
        ? Directory.systemTemp.path
        : localAppData;
    return '$root\\JA_MES_Tool\\browser_profiles';
  }

  static String _legacyProfilePath() {
    return '${Directory.systemTemp.path}\\ja_mes_browser_profile';
  }

  static String _profilePath({required bool isEdge}) {
    return '${_profileRootPath()}\\${isEdge ? 'edge' : 'chrome'}';
  }

  static List<String> _candidateProfilePaths() {
    final candidates = <String>[];

    void add(String path) {
      if (!candidates.contains(path)) {
        candidates.add(path);
      }
    }

    if (_activeProfileDir != null) {
      add(_activeProfileDir!);
    }
    add(_profilePath(isEdge: false));
    add(_profilePath(isEdge: true));
    return candidates;
  }

  static String? _findBrowserExecutable() {
    const candidatePaths = [
      r'C:\Program Files\Google\Chrome\Application\chrome.exe',
      r'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
      r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
      r'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
    ];

    for (final path in candidatePaths) {
      if (File(path).existsSync()) {
        return path;
      }
    }
    return null;
  }

  static Future<String> _ensureProfileDirectory({required bool isEdge}) async {
    final profilePath = _profilePath(isEdge: isEdge);
    final profile = Directory(profilePath);
    final legacyProfile = Directory(_legacyProfilePath());
    await Directory(_profileRootPath()).create(recursive: true);

    // Preserve profiles created by older builds when the new browser-specific
    // profile does not exist yet. If the old profile is locked, leave it in
    // place and start with a new profile instead of touching a live browser.
    if (!profile.existsSync() && legacyProfile.existsSync()) {
      try {
        await legacyProfile.rename(profilePath);
        _logger.info(
          'Migrated legacy browser profile to persistent ${isEdge ? "Edge" : "Chrome"} profile: $profilePath',
        );
      } catch (e) {
        _logger.warning(
          'Could not migrate legacy browser profile; keeping it untouched: $e',
        );
      }
    }

    await profile.create(recursive: true);
    return profile.path;
  }

  static Future<_CdpEndpoint?> _probeCdpEndpoint(String profileDir) async {
    final activePortFile = File('$profileDir\\DevToolsActivePort');
    if (!activePortFile.existsSync()) {
      return null;
    }

    try {
      final lines = await activePortFile.readAsLines();
      if (lines.isEmpty) {
        return null;
      }

      final port = int.tryParse(lines.first.trim());
      if (port == null || port < 1 || port > 65535) {
        return null;
      }

      final response = await http
          .get(Uri.parse('http://127.0.0.1:$port/json'))
          .timeout(_cdpProbeTimeout);
      if (response.statusCode != 200) {
        return null;
      }

      final decoded = json.decode(response.body);
      if (decoded is! List<dynamic>) {
        return null;
      }

      return _CdpEndpoint(profileDir: profileDir, port: port, targets: decoded);
    } catch (e) {
      _logger.fine('CDP endpoint is not ready for $profileDir: $e');
      return null;
    }
  }

  static Future<_CdpEndpoint?> _findReadyCdpEndpoint() async {
    for (final profileDir in _candidateProfilePaths()) {
      final endpoint = await _probeCdpEndpoint(profileDir);
      if (endpoint != null) {
        _activeProfileDir = endpoint.profileDir;
        return endpoint;
      }
    }
    return null;
  }

  static Future<_CdpEndpoint?> _waitForCdp(String profileDir) async {
    final deadline = DateTime.now().add(_cdpStartupTimeout);
    while (DateTime.now().isBefore(deadline)) {
      final endpoint = await _probeCdpEndpoint(profileDir);
      if (endpoint != null) {
        return endpoint;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return null;
  }

  /// Launches Chrome or Edge with a persistent, browser-specific profile.
  static Future<bool> launchBrowser() async {
    if (_launchInProgress != null) {
      return _launchInProgress!;
    }

    final future = _launchBrowserInternal();
    _launchInProgress = future;
    try {
      return await future;
    } finally {
      if (identical(_launchInProgress, future)) {
        _launchInProgress = null;
      }
    }
  }

  static Future<bool> _launchBrowserInternal() async {
    try {
      final execPath = _findBrowserExecutable();
      if (execPath == null) {
        _logger.warning('Chrome or Edge executable was not found on Windows');
        return false;
      }

      final isEdge = execPath.toLowerCase().contains('msedge');
      final profileDir = await _ensureProfileDirectory(isEdge: isEdge);
      _activeProfileDir = profileDir;

      final args = [
        '--remote-debugging-port=0',
        '--user-data-dir=$profileDir',
        '--profile-directory=Default',
        '--new-window',
        '--no-first-run',
        '--no-default-browser-check',
        '--disable-background-networking',
        '--disable-component-update',
        '--disable-default-apps',
        '--disable-popup-blocking',
      ];

      if (isEdge) {
        args.addAll([
          '--disable-features=msEdgeStartupBoost,msUnderside,msEdgeSidebar,msHubs,WebAuthentication',
          '--no-service-autorun',
        ]);
      }

      args.add(mesUrl);

      await Process.start(
        execPath,
        args,
        mode: ProcessStartMode.detached,
      ).timeout(const Duration(seconds: 5));
      _logger.info(
        'Launched ${isEdge ? "Edge" : "Chrome"} with persistent profile $profileDir: $execPath',
      );

      final endpoint = await _waitForCdp(profileDir);
      if (endpoint == null) {
        _logger.warning(
          'Browser launched but CDP did not become ready within ${_cdpStartupTimeout.inSeconds}s for $profileDir',
        );
        return false;
      }
      return true;
    } catch (e, stack) {
      _logger.severe('Failed to launch browser with CDP', e, stack);
      return false;
    }
  }

  /// Connects to Chrome DevTools Protocol and uses Network interception
  /// to capture actual API request headers (Authorization, uuid, operation-id, Cookie).
  /// This is more reliable than reading from localStorage, especially for UUID.
  static Future<ExtractedCredentials?> fetchCredentialsFromBrowser() async {
    try {
      final endpoint = await _findReadyCdpEndpoint();
      if (endpoint == null) {
        _logger.warning(
          'No responsive CDP endpoint found in the Chrome/Edge app profiles',
        );
        return null;
      }
      final port = endpoint.port;
      final targets = endpoint.targets;
      _logger.info('Attempting CDP connection on port $port');
      Map<String, dynamic>? mesTarget;

      for (var t in targets) {
        if (t is Map<String, dynamic>) {
          final url = t['url']?.toString() ?? '';
          if (url.contains('vncmes.ces.myfiinet.com') ||
              url.contains('test-record') ||
              url.contains('cloudmes')) {
            mesTarget = t;
            break;
          }
        }
      }

      // If no specific MES tab, pick the first page target
      mesTarget ??= targets.firstWhere(
        (t) => t['type'] == 'page',
        orElse: () => null,
      );

      if (mesTarget == null || mesTarget['webSocketDebuggerUrl'] == null) {
        _logger.warning('No webSocketDebuggerUrl found in CDP targets');
        return null;
      }

      final wsUrl = mesTarget['webSocketDebuggerUrl'].toString();
      _logger.info('Connecting to CDP WebSocket: $wsUrl');
      final socket = await WebSocket.connect(
        wsUrl,
      ).timeout(const Duration(seconds: 4));

      final completer = Completer<ExtractedCredentials?>();

      String? capturedToken;
      String? capturedOperationId;
      String? capturedUuid;
      String? capturedCookie;
      bool networkEnabled = false;

      socket.listen(
        (data) {
          try {
            final map = json.decode(data.toString());

            // Handle Network.enable response
            if (map['id'] == 1 && !networkEnabled) {
              networkEnabled = true;
              _logger.info(
                'Network domain enabled, reloading page to capture API requests...',
              );
              // Reload the page to trigger API calls
              socket.add(
                json.encode({'id': 2, 'method': 'Page.reload', 'params': {}}),
              );
            }

            // Handle Network.requestWillBeSent events
            if (map['method'] == 'Network.requestWillBeSent') {
              final request = map['params']?['request'];
              if (request != null) {
                final url = request['url']?.toString() ?? '';
                // Only capture headers from API requests to the MES server
                if (url.contains('vncmes.ces.myfiinet.com') &&
                    url.contains('/api/')) {
                  final headers = Map<String, dynamic>.from(
                    request['headers'] ?? {},
                  );
                  _logger.info('Intercepted API request to: $url');
                  _logger.info(
                    'Intercepted headers keys: ${headers.keys.toList()}',
                  );

                  for (var key in headers.keys) {
                    final lk = key.toLowerCase();
                    final val = headers[key]?.toString() ?? '';
                    if (lk == 'authorization' && val.isNotEmpty) {
                      capturedToken = val
                          .replaceFirst(
                            RegExp(r'^bearer\s+', caseSensitive: false),
                            '',
                          )
                          .trim();
                    } else if (lk == 'uuid' && val.isNotEmpty) {
                      capturedUuid = val.trim();
                    } else if (lk == 'operation-id' && val.isNotEmpty) {
                      capturedOperationId = val.trim();
                    } else if (lk == 'cookie' && val.isNotEmpty) {
                      capturedCookie = val.trim();
                    }
                  }

                  // Complete once we have at least token and uuid
                  if (capturedToken != null &&
                      capturedUuid != null &&
                      !completer.isCompleted) {
                    final tokenPreview = capturedToken!.length > 20
                        ? capturedToken!.substring(0, 20)
                        : capturedToken!;
                    _logger.info(
                      'Successfully captured credentials from network: token=$tokenPreview..., uuid=$capturedUuid, opId=$capturedOperationId',
                    );
                    completer.complete(
                      ExtractedCredentials(
                        token: capturedToken,
                        operationId: capturedOperationId,
                        uuid: capturedUuid,
                        cookie: capturedCookie,
                      ),
                    );
                    socket.close();
                  }
                }
              }
            }
          } catch (e) {
            _logger.warning('Error processing CDP message: $e');
          }
        },
        onError: (err) {
          _logger.warning('CDP WebSocket error: $err');
          if (!completer.isCompleted) completer.complete(null);
          socket.close();
        },
      );

      // Step 1: Enable Network domain to intercept requests
      socket.add(
        json.encode({'id': 1, 'method': 'Network.enable', 'params': {}}),
      );

      return await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          _logger.warning(
            'Timeout waiting for API request interception. Captured so far: token=${capturedToken != null}, uuid=${capturedUuid != null}, opId=${capturedOperationId != null}',
          );
          socket.close();
          // Return partial results if we have any
          if (capturedToken != null) {
            return ExtractedCredentials(
              token: capturedToken,
              operationId: capturedOperationId,
              uuid: capturedUuid,
              cookie: capturedCookie,
            );
          }
          return null;
        },
      );
    } catch (e, stack) {
      _logger.warning('Could not fetch credentials via CDP', e, stack);
      return null;
    }
  }

  /// Parses raw HTTP request text (copied from F12 DevTools or Postman)
  /// and extracts Authorization, operation-id, uuid, Cookie, lang headers.
  static ExtractedCredentials parseRawHttpRequest(String rawText) {
    String? token;
    String? lang;
    String? operationId;
    String? uuid;
    String? cookie;

    final lines = rawText.split('\n');
    for (var line in lines) {
      final trimmed = line.trim();

      // Authorization header
      if (RegExp(
        r'^(authorization|token):',
        caseSensitive: false,
      ).hasMatch(trimmed)) {
        final val = trimmed.split(RegExp(r':\s*')).skip(1).join(':').trim();
        token = val
            .replaceFirst(RegExp(r'^[bB][eE][aA][rR][eE][rR]\s+'), '')
            .trim();
      }
      // Cookie header
      else if (RegExp(r'^cookie:', caseSensitive: false).hasMatch(trimmed)) {
        cookie = trimmed.split(RegExp(r':\s*')).skip(1).join(':').trim();
        // Check if token is in Cookie CloudMES-token
        if (token == null || token.isEmpty) {
          final m = RegExp(r'CloudMES-token=([^;]+)').firstMatch(cookie);
          if (m != null) {
            token = m.group(1);
          }
        }
      }
      // operation-id header
      else if (RegExp(
        r'^operation-id:',
        caseSensitive: false,
      ).hasMatch(trimmed)) {
        operationId = trimmed.split(RegExp(r':\s*')).skip(1).join(':').trim();
      }
      // uuid header
      else if (RegExp(r'^uuid:', caseSensitive: false).hasMatch(trimmed)) {
        uuid = trimmed.split(RegExp(r':\s*')).skip(1).join(':').trim();
      }
      // lang header
      else if (RegExp(r'^lang:', caseSensitive: false).hasMatch(trimmed)) {
        lang = trimmed.split(RegExp(r':\s*')).skip(1).join(':').trim();
      }
    }

    return ExtractedCredentials(
      token: token,
      lang: lang,
      operationId: operationId,
      uuid: uuid,
      cookie: cookie,
    );
  }
}
