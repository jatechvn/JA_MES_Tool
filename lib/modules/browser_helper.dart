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

class BrowserHelper {
  static const String mesUrl = 'https://vncmes.ces.myfiinet.com/#/zh-CN/ims/mes/report/test-record';
  static const int cdpPort = 9222;

  /// Launches Chrome or Edge with Remote Debugging enabled on port 9222.
  static Future<bool> launchBrowser() async {
    try {
      // Find Chrome or Edge executable on Windows
      String? execPath;
      
      final candidatePaths = [
        r'C:\Program Files\Google\Chrome\Application\chrome.exe',
        r'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
        r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
        r'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
      ];

      for (var path in candidatePaths) {
        if (File(path).existsSync()) {
          execPath = path;
          break;
        }
      }

      final userDataDir = '${Directory.systemTemp.path}\\ja_mes_browser_profile';
      final dir = Directory(userDataDir);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      if (execPath != null) {
        await Process.start(execPath, [
          '--remote-debugging-port=0',
          '--user-data-dir=$userDataDir',
          '--no-first-run',
          '--no-default-browser-check',
          mesUrl
        ]);
        _logger.info('Launched browser with dynamic CDP port and profile $userDataDir: $execPath');
        return true;
      } else {
        // Fallback: launch default browser using cmd start
        await Process.run('cmd', ['/c', 'start', 'chrome', '--remote-debugging-port=$cdpPort', '--user-data-dir=$userDataDir', mesUrl]);
        return true;
      }
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
      int port = cdpPort;
      final activePortFile = File('${Directory.systemTemp.path}\\ja_mes_browser_profile\\DevToolsActivePort');
      if (activePortFile.existsSync()) {
        final lines = activePortFile.readAsLinesSync();
        if (lines.isNotEmpty) {
          port = int.tryParse(lines.first.trim()) ?? cdpPort;
        }
      }
      _logger.info('Attempting CDP connection on port $port');

      final response = await http.get(Uri.parse('http://127.0.0.1:$port/json')).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        _logger.warning('CDP endpoint responded with status ${response.statusCode}');
        return null;
      }

      final List<dynamic> targets = json.decode(response.body);
      Map<String, dynamic>? mesTarget;

      for (var t in targets) {
        if (t is Map<String, dynamic>) {
          final url = t['url']?.toString() ?? '';
          if (url.contains('vncmes.ces.myfiinet.com') || url.contains('test-record') || url.contains('cloudmes')) {
            mesTarget = t;
            break;
          }
        }
      }

      // If no specific MES tab, pick the first page target
      mesTarget ??= targets.firstWhere((t) => t['type'] == 'page', orElse: () => null);

      if (mesTarget == null || mesTarget['webSocketDebuggerUrl'] == null) {
        _logger.warning('No webSocketDebuggerUrl found in CDP targets');
        return null;
      }

      final wsUrl = mesTarget['webSocketDebuggerUrl'].toString();
      _logger.info('Connecting to CDP WebSocket: $wsUrl');
      final socket = await WebSocket.connect(wsUrl).timeout(const Duration(seconds: 4));

      final completer = Completer<ExtractedCredentials?>();

      String? capturedToken;
      String? capturedOperationId;
      String? capturedUuid;
      String? capturedCookie;
      bool networkEnabled = false;

      socket.listen((data) {
        try {
          final map = json.decode(data.toString());

          // Handle Network.enable response
          if (map['id'] == 1 && !networkEnabled) {
            networkEnabled = true;
            _logger.info('Network domain enabled, reloading page to capture API requests...');
            // Reload the page to trigger API calls
            socket.add(json.encode({
              'id': 2,
              'method': 'Page.reload',
              'params': {}
            }));
          }

          // Handle Network.requestWillBeSent events
          if (map['method'] == 'Network.requestWillBeSent') {
            final request = map['params']?['request'];
            if (request != null) {
              final url = request['url']?.toString() ?? '';
              // Only capture headers from API requests to the MES server
              if (url.contains('vncmes.ces.myfiinet.com') && url.contains('/api/')) {
                final headers = Map<String, dynamic>.from(request['headers'] ?? {});
                _logger.info('Intercepted API request to: $url');
                _logger.info('Intercepted headers keys: ${headers.keys.toList()}');

                for (var key in headers.keys) {
                  final lk = key.toLowerCase();
                  final val = headers[key]?.toString() ?? '';
                  if (lk == 'authorization' && val.isNotEmpty) {
                    capturedToken = val.replaceFirst(RegExp(r'^bearer\s+', caseSensitive: false), '').trim();
                  } else if (lk == 'uuid' && val.isNotEmpty) {
                    capturedUuid = val.trim();
                  } else if (lk == 'operation-id' && val.isNotEmpty) {
                    capturedOperationId = val.trim();
                  } else if (lk == 'cookie' && val.isNotEmpty) {
                    capturedCookie = val.trim();
                  }
                }

                // Complete once we have at least token and uuid
                if (capturedToken != null && capturedUuid != null && !completer.isCompleted) {
                  _logger.info('Successfully captured credentials from network: token=${capturedToken!.substring(0, 20)}..., uuid=$capturedUuid, opId=$capturedOperationId');
                  completer.complete(ExtractedCredentials(
                    token: capturedToken,
                    operationId: capturedOperationId,
                    uuid: capturedUuid,
                    cookie: capturedCookie,
                  ));
                  socket.close();
                }
              }
            }
          }
        } catch (e) {
          _logger.warning('Error processing CDP message: $e');
        }
      }, onError: (err) {
        _logger.warning('CDP WebSocket error: $err');
        if (!completer.isCompleted) completer.complete(null);
        socket.close();
      });

      // Step 1: Enable Network domain to intercept requests
      socket.add(json.encode({
        'id': 1,
        'method': 'Network.enable',
        'params': {}
      }));

      return await completer.future.timeout(const Duration(seconds: 15), onTimeout: () {
        _logger.warning('Timeout waiting for API request interception. Captured so far: token=${capturedToken != null}, uuid=${capturedUuid != null}, opId=${capturedOperationId != null}');
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
      });
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
      if (RegExp(r'^(authorization|token):', caseSensitive: false).hasMatch(trimmed)) {
        final val = trimmed.split(RegExp(r':\s*')).skip(1).join(':').trim();
        token = val.replaceFirst(RegExp(r'^[bB][eE][aA][rR][eE][rR]\s+'), '').trim();
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
      else if (RegExp(r'^operation-id:', caseSensitive: false).hasMatch(trimmed)) {
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
