import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ja_mes_tool/modules/services/ota_update_service.dart';

void main() {
  group('SemanticVersion Tests', () {
    test('parses standard semver versions', () {
      final v1 = SemanticVersion.tryParse('2.9.7');
      expect(v1, isNotNull);
      expect(v1!.major, 2);
      expect(v1.minor, 9);
      expect(v1.patch, 7);
      expect(v1.build, isNull);

      final v2 = SemanticVersion.tryParse('v2.9.8');
      expect(v2, isNotNull);
      expect(v2!.major, 2);
      expect(v2.minor, 9);
      expect(v2.patch, 8);

      final v3 = SemanticVersion.tryParse('2.9.7+21');
      expect(v3, isNotNull);
      expect(v3!.major, 2);
      expect(v3.minor, 9);
      expect(v3.patch, 7);
      expect(v3.build, 21);
      expect(v3.displayVersion, 'v2.9.7+21');

      final v4 = SemanticVersion.tryParse('3.0.0-beta');
      expect(v4, isNotNull);
      expect(v4!.major, 3);
      expect(v4.minor, 0);
      expect(v4.patch, 0);
      expect(v4.prerelease, 'beta');
    });

    test('rejects invalid version strings', () {
      expect(SemanticVersion.tryParse(null), isNull);
      expect(SemanticVersion.tryParse(''), isNull);
      expect(SemanticVersion.tryParse('invalid'), isNull);
      expect(SemanticVersion.tryParse('1..0'), isNull);
      expect(SemanticVersion.tryParse('abc.def.ghi'), isNull);
    });

    test('correctly compares semantic versions', () {
      final v297 = SemanticVersion.tryParse('2.9.7')!;
      final v298 = SemanticVersion.tryParse('2.9.8')!;
      final v2100 = SemanticVersion.tryParse('2.10.0')!;
      final v300 = SemanticVersion.tryParse('3.0.0')!;
      final v297b21 = SemanticVersion.tryParse('2.9.7+21')!;
      final v297b22 = SemanticVersion.tryParse('2.9.7+22')!;

      expect(v298 > v297, isTrue);
      expect(v297 < v298, isTrue);
      expect(v2100 > v298, isTrue);
      expect(v300 > v2100, isTrue);

      // Build number comparison when major.minor.patch match
      expect(v297b22 > v297b21, isTrue);
      expect(v297b21 < v297b22, isTrue);

      // Equality
      final v297Copy = SemanticVersion.tryParse('v2.9.7')!;
      expect(v297 == v297Copy, isTrue);
      expect(v297 >= v297Copy, isTrue);
      expect(v297 <= v297Copy, isTrue);
    });
  });

  group('Package Name & Path Validation', () {
    test('validates package archive names correctly', () {
      expect(
        OtaUpdateService.isValidPackageName(
          'JA_MES_Tool_v2.9.8_Windows_x64.zip',
        ),
        isTrue,
      );
      expect(
        OtaUpdateService.isValidPackageName(
          'JA_MES_Tool_v2.9.8+22_Windows_x64.zip',
        ),
        isTrue,
      );
      expect(
        OtaUpdateService.isValidPackageName('ja_mes_tool_v3.0.0.zip'),
        isTrue,
      );

      // Invalid names
      expect(
        OtaUpdateService.isValidPackageName('JA_LAN_Messenger_v1.0.0.zip'),
        isFalse,
      );
      expect(OtaUpdateService.isValidPackageName('payload.exe'), isFalse);
      expect(
        OtaUpdateService.isValidPackageName('JA_MES_Tool_payload.zip'),
        isFalse,
      );
      expect(
        OtaUpdateService.isValidPackageName('../JA_MES_Tool_v2.9.8.zip'),
        isFalse,
      );
      expect(
        OtaUpdateService.packageVersionFromFileName(
          'JA_MES_Tool_v2.9.8+22_Windows_x64.zip',
        )?.toString(),
        '2.9.8+22',
      );
    });

    test('extracts SMB share root from UNC paths', () {
      expect(
        OtaUpdateService.extractSmbShareRoot(
          r'\\10.81.141.226\temp\FBT\JA_PROJECT\JA_Update\JA_MES_Tool',
        ),
        r'\\10.81.141.226\temp',
      );
      expect(
        OtaUpdateService.extractSmbShareRoot(r'\\fileserver\releases'),
        r'\\fileserver\releases',
      );
      expect(OtaUpdateService.extractSmbShareRoot(r'D:\Local\Path'), isNull);
    });

    test('determines update check interval correctly', () {
      final service = OtaUpdateService();
      final now = DateTime(2026, 9, 21, 15, 0);

      expect(
        service.shouldCheckForUpdates(
          interval: 'off',
          lastCheckTime: now.subtract(const Duration(days: 30)),
          now: now,
        ),
        isFalse,
      );

      expect(
        service.shouldCheckForUpdates(
          interval: 'daily',
          lastCheckTime: null,
          now: now,
        ),
        isTrue,
      );

      // Daily: 10h elapsed -> false
      expect(
        service.shouldCheckForUpdates(
          interval: 'daily',
          lastCheckTime: now.subtract(const Duration(hours: 10)),
          now: now,
        ),
        isFalse,
      );

      // Daily: 25h elapsed -> true
      expect(
        service.shouldCheckForUpdates(
          interval: 'daily',
          lastCheckTime: now.subtract(const Duration(hours: 25)),
          now: now,
        ),
        isTrue,
      );

      // Weekly: 6 days elapsed -> false
      expect(
        service.shouldCheckForUpdates(
          interval: 'weekly',
          lastCheckTime: now.subtract(const Duration(days: 6)),
          now: now,
        ),
        isFalse,
      );

      // Weekly: 8 days elapsed -> true
      expect(
        service.shouldCheckForUpdates(
          interval: 'weekly',
          lastCheckTime: now.subtract(const Duration(days: 8)),
          now: now,
        ),
        isTrue,
      );
    });
  });

  group('Configuration & Persistence Tests', () {
    late Directory tempDir;
    late File testConfigFile;
    late OtaUpdateService service;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('ota_test_cfg_');
      testConfigFile = File('${tempDir.path}/update_config.json');
      service = OtaUpdateService();
      service.setCustomConfigFileForTesting(testConfigFile);
    });

    tearDown(() {
      service.setCustomConfigFileForTesting(null);
      service.setCustomServerDirForTesting(null);
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('loads defaults and persists changes', () async {
      final cfg = await service.loadConfig();
      expect(cfg.serverPath, contains('JA_MES_Tool'));
      expect(cfg.checkInterval, 'daily');

      // Update config
      await service.updateConfig(
        serverPath: r'D:\Testing\UpdateServer',
        username: 'testuser',
        password: 'secretpassword',
        checkInterval: 'weekly',
      );

      expect(testConfigFile.existsSync(), isTrue);

      final reloaded = await service.loadConfig();
      expect(reloaded.serverPath, r'D:\Testing\UpdateServer');
      expect(reloaded.username, 'testuser');
      expect(reloaded.checkInterval, 'weekly');

      final persisted = jsonDecode(testConfigFile.readAsStringSync()) as Map;
      expect(persisted.containsKey('password'), isFalse);

      // A later app session cannot recover the password from disk.
      service.setCustomConfigFileForTesting(testConfigFile);
      final nextSession = await service.loadConfig();
      expect(nextSession.password, isEmpty);
    });

    test('migrates legacy plaintext OTA passwords out of config', () async {
      testConfigFile.writeAsStringSync(
        jsonEncode({
          'serverPath': r'\\server\releases',
          'username': 'operator',
          'password': 'legacy-secret',
          'checkInterval': 'weekly',
        }),
      );

      final config = await service.loadConfig();
      expect(config.password, isEmpty);

      final persisted = jsonDecode(testConfigFile.readAsStringSync()) as Map;
      expect(persisted.containsKey('password'), isFalse);
    });

    test('discovers update package via mock server directory', () async {
      final serverDir = Directory('${tempDir.path}/server_share');
      serverDir.createSync(recursive: true);
      service.setCustomServerDirForTesting(serverDir);

      // Create a mock zip package and version.json
      final zipFile = File(
        '${serverDir.path}/JA_MES_Tool_v2.9.9_Windows_x64.zip',
      );
      zipFile.writeAsStringSync('dummy zip content for testing');

      final versionJson = File('${serverDir.path}/version.json');
      versionJson.writeAsStringSync(
        jsonEncode({
          'version': '2.9.9',
          'fileName': 'JA_MES_Tool_v2.9.9_Windows_x64.zip',
          'releaseNotes': 'Major performance improvements and bugfixes.',
          'releaseDate': '2026-09-22T08:00:00Z',
        }),
      );

      final checkResult = await service.checkForUpdates(
        overrideServerPath: serverDir.path,
        overrideCurrentVersion: '2.9.7+21',
      );

      expect(checkResult.isConnectionSuccess, isTrue);
      expect(checkResult.hasUpdate, isTrue);
      expect(checkResult.packageInfo, isNotNull);
      expect(checkResult.packageInfo!.version.toString(), '2.9.9');
      expect(
        checkResult.packageInfo!.fileName,
        'JA_MES_Tool_v2.9.9_Windows_x64.zip',
      );
      expect(
        checkResult.packageInfo!.releaseNotes,
        contains('Major performance improvements'),
      );
    });

    test(
      'does not trust version.json that points to an arbitrary ZIP',
      () async {
        final serverDir = Directory('${tempDir.path}/invalid_server_share');
        serverDir.createSync(recursive: true);
        service.setCustomServerDirForTesting(serverDir);

        File(
          '${serverDir.path}/JA_MES_Tool_payload.zip',
        ).writeAsStringSync('not a release package');
        File('${serverDir.path}/version.json').writeAsStringSync(
          jsonEncode({
            'version': '9.0.0',
            'fileName': 'JA_MES_Tool_payload.zip',
          }),
        );

        final result = await service.checkForUpdates(
          overrideServerPath: serverDir.path,
          overrideCurrentVersion: '2.9.6',
        );

        expect(result.hasUpdate, isFalse);
        expect(result.packageInfo, isNull);
      },
    );

    test(
      'rejects a manually constructed package with inconsistent identity',
      () async {
        final package = UpdatePackageInfo(
          version: SemanticVersion.tryParse('2.9.9')!,
          fileName: 'JA_MES_Tool_v2.9.9_Windows_x64.zip',
          fullPath: '${tempDir.path}/unrelated.zip',
          fileSize: 1,
        );

        await expectLater(
          service.validatePackageForTesting(package),
          throwsA(isA<StateError>()),
        );
      },
    );

    test(
      'generates robocopy apply update batch script with safety protections',
      () {
        final script = OtaUpdateService.generateApplyUpdateScript(
          oldPid: 12345,
          sourceDir: r'C:\Temp\ota_extracted',
          targetDir: r'C:\Apps\JA_MES_Tool',
          exeName: 'ja_mes_tool.exe',
        );

        // Verify PID waiting loop
        expect(script, contains('PID eq %OLD_PID%'));
        expect(script, contains('set "OLD_PID=12345"'));

        // Verify robocopy mirroring with configuration exclusions
        expect(script, contains('robocopy "%SRC_DIR%" "%DST_DIR%"'));
        expect(
          script,
          contains('/XD logs /XF config.json config.ini update_config.json'),
        );

        // Verify backup and rollback logic
        expect(script, contains(':rollback'));
        expect(script, contains('robocopy "%BACKUP_DIR%" "%DST_DIR%"'));

        // Verify restarting app
        expect(script, contains('start "" "%DST_DIR%\\%EXE_NAME%"'));
      },
    );
  });
}
