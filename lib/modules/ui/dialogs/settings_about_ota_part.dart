part of 'settings_dialog.dart';

extension _SettingsAboutOtaTabExt on _AppSettingsDialogState {
  Widget _buildAboutAndUpdatesTab(AppColors colors) {
    final logic = widget.logic;
    final theme = widget.theme;
    final isDark = theme.isDark;
    final otaConfig = OtaUpdateService().currentConfig;
    final timestamp = BuildInfo.debugTimestamp;

    Future<void> checkForUpdatesManually() async {
      _rebuild(() {
        _isCheckingForUpdates = true;
        _manualUpdateCheckResult = null;
      });
      final path = _otaServerPathCtrl.text.trim();
      try {
        final result = await OtaUpdateService().checkForUpdates(
          overrideServerPath: path.isEmpty ? null : path,
          overrideUsername: _otaUsernameCtrl.text.trim(),
          overridePassword: _otaPasswordCtrl.text,
          isManual: true,
        );
        if (!mounted) return;
        _rebuild(() {
          _isCheckingForUpdates = false;
          _manualUpdateCheckResult = result;
        });
        if (result.hasUpdate && result.packageInfo != null && mounted) {
          showGlassUpdateDialog(
            context: context,
            packageInfo: result.packageInfo!,
            lang: logic.lang,
          );
        }
      } catch (e) {
        if (!mounted) return;
        _rebuild(() {
          _isCheckingForUpdates = false;
          _manualUpdateCheckResult = UpdateCheckResult(
            hasUpdate: false,
            currentVersion: appVersion,
            isConnectionSuccess: false,
            errorMessage: e.toString().replaceFirst('Exception: ', ''),
          );
        });
      }
    }

    Future<void> testShareConnection() async {
      _rebuild(() {
        _isTestingShare = true;
        _shareTestOk = null;
        _shareTestMessage = null;
      });
      try {
        final result = await OtaUpdateService().testConnection(
          path: _otaServerPathCtrl.text.trim(),
          username: _otaUsernameCtrl.text.trim(),
          password: _otaPasswordCtrl.text,
        );
        if (!mounted) return;
        _rebuild(() {
          _isTestingShare = false;
          _shareTestOk = result.connected;
          _shareTestMessage = _shareProbeMessage(result, logic.lang);
        });
      } catch (e) {
        if (!mounted) return;
        _rebuild(() {
          _isTestingShare = false;
          _shareTestOk = false;
          _shareTestMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }

    void openAppFolder() {
      final file = OtaUpdateService().getConfigFile();
      if (Platform.isWindows) {
        if (file.existsSync()) {
          Process.run('explorer.exe', ['/select,', file.path]);
        } else {
          Process.run('explorer.exe', [file.parent.path]);
        }
      }
    }

    final manualUpdateResult = _manualUpdateCheckResult;

    return ListView(
      key: const PageStorageKey('settings_tab_about_updates'),
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. Featured Version & Update Status Card
        BentoCard(
          colors: colors,
          padding: const EdgeInsets.all(16),
          borderRadius: 14,
          isFeatured: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors.accentColor, colors.accentCyan],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colors.accentColor.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.hub_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$appName v$appVersion',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${Translations.get('build_label', logic.lang)}: $timestamp • ${otaConfig.lastCheckTime != null ? '${Translations.get('last_checked', logic.lang)}: ${otaConfig.lastCheckTime!.hour.toString().padLeft(2, '0')}:${otaConfig.lastCheckTime!.minute.toString().padLeft(2, '0')} ${otaConfig.lastCheckTime!.day}/${otaConfig.lastCheckTime!.month}/${otaConfig.lastCheckTime!.year}' : Translations.get('never_checked', logic.lang)}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _isCheckingForUpdates
                        ? null
                        : checkForUpdatesManually,
                    icon: _isCheckingForUpdates
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, size: 15),
                    label: Text(
                      _isCheckingForUpdates
                          ? Translations.get('checking_updates', logic.lang)
                          : Translations.get('check_updates_now', logic.lang),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.accentColor,
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (manualUpdateResult == null &&
                  _shareTestMessage == null &&
                  OtaUpdateService().sessionConnected == false &&
                  (OtaUpdateService().sessionDetail?.isNotEmpty ?? false)) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.accentRose.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.accentRose.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 18,
                        color: colors.accentRose,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          OtaUpdateService().sessionDetail!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.accentRose,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (manualUpdateResult != null) ...[
                const SizedBox(height: 14),
                if (manualUpdateResult.hasUpdate &&
                    manualUpdateResult.packageInfo != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.accentEmerald.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colors.accentEmerald.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: colors.accentEmerald,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${Translations.get('update_available', logic.lang)} (${manualUpdateResult.packageInfo!.version.displayVersion} • ${manualUpdateResult.packageInfo!.formattedSize})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.accentEmerald,
                            ),
                          ),
                        ),
                        FilledButton(
                          onPressed: () {
                            showGlassUpdateDialog(
                              context: context,
                              packageInfo: manualUpdateResult.packageInfo!,
                              lang: logic.lang,
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.accentEmerald,
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                          ),
                          child: Text(
                            Translations.get('update_now', logic.lang),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (manualUpdateResult.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.accentRose.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colors.accentRose.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 18,
                          color: colors.accentRose,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            manualUpdateResult.errorMessage!,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.accentRose,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.accentColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: colors.accentColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 18,
                          color: colors.accentColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            Translations.get(
                              'no_updates_available',
                              logic.lang,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. LAN OTA Settings Card
        BentoCard(
          colors: colors,
          padding: const EdgeInsets.all(16),
          borderRadius: 14,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.dns_rounded, size: 18, color: colors.accentColor),
                  const SizedBox(width: 8),
                  Text(
                    Translations.get('server_path', logic.lang),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildTextField(
                label: '',
                controller: _otaServerPathCtrl,
                colors: colors,
                hintText: Translations.get('server_path_hint', logic.lang),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isTestingShare ? null : testShareConnection,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.accentColor,
                      side: BorderSide(
                        color: colors.accentColor.withValues(alpha: 0.5),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    icon: _isTestingShare
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.accentColor,
                            ),
                          )
                        : const Icon(Icons.lan_rounded, size: 16),
                    label: Text(
                      _isTestingShare
                          ? Translations.get(
                              'testing_share_connection',
                              logic.lang,
                            )
                          : Translations.get(
                              'test_share_connection',
                              logic.lang,
                            ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_shareTestMessage != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            _shareTestOk == true
                                ? Icons.check_circle_rounded
                                : Icons.error_outline_rounded,
                            color: _shareTestOk == true
                                ? colors.accentEmerald
                                : colors.accentRose,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _shareTestMessage!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _shareTestOk == true
                                    ? colors.accentEmerald
                                    : colors.accentRose,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: colors.accentColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    Translations.get('check_interval', logic.lang),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildIntervalChoice(
                    label: Translations.get('interval_startup', logic.lang),
                    icon: Icons.rocket_launch_rounded,
                    value: 'startup',
                    currentValue: _otaInterval,
                    colors: colors,
                    onSelect: () => _rebuild(() => _otaInterval = 'startup'),
                  ),
                  const SizedBox(width: 8),
                  _buildIntervalChoice(
                    label: Translations.get('interval_daily', logic.lang),
                    icon: Icons.today_rounded,
                    value: 'daily',
                    currentValue: _otaInterval,
                    colors: colors,
                    onSelect: () => _rebuild(() => _otaInterval = 'daily'),
                  ),
                  const SizedBox(width: 8),
                  _buildIntervalChoice(
                    label: Translations.get('interval_weekly', logic.lang),
                    icon: Icons.date_range_rounded,
                    value: 'weekly',
                    currentValue: _otaInterval,
                    colors: colors,
                    onSelect: () => _rebuild(() => _otaInterval = 'weekly'),
                  ),
                  const SizedBox(width: 8),
                  _buildIntervalChoice(
                    label: Translations.get('interval_disabled', logic.lang),
                    icon: Icons.block_rounded,
                    value: 'off',
                    currentValue: _otaInterval,
                    colors: colors,
                    onSelect: () => _rebuild(() => _otaInterval = 'off'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 15,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    Translations.get('ota_credentials', logic.lang),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                Translations.get('ota_credentials_hint', logic.lang),
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.35,
                  color: colors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: Translations.get('ota_username', logic.lang),
                      controller: _otaUsernameCtrl,
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      label: Translations.get('ota_password', logic.lang),
                      controller: _otaPasswordCtrl,
                      colors: colors,
                      obscureText: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3. Technical Specs & Diagnostics
        BentoCard(
          colors: colors,
          padding: const EdgeInsets.all(14),
          borderRadius: 14,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: colors.accentColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    Translations.get('tab_about', logic.lang),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildAboutRow(
                Translations.get('system_engine', logic.lang),
                'Dart 3.12 / Flutter 3.x Desktop (Windows)',
                colors,
              ),
              _buildAboutRow(
                Translations.get('system_architecture', logic.lang),
                'Bento Glassmorphism + Dynamic Island',
                colors,
              ),
              _buildAboutRow(
                Translations.get('system_cdp_interceptor', logic.lang),
                'Edge / Chrome DevTools Protocol',
                colors,
              ),
              _buildAboutRow(
                Translations.get('system_hardware_profile', logic.lang),
                _formatSettingsTranslation(
                  'hardware_profile_value',
                  logic.lang,
                  {
                    'cores': theme.cpuCores.toString(),
                    'tier': _localizedHardwareTier(
                      theme.effectiveTier,
                      logic.lang,
                    ),
                  },
                ),
                colors,
              ),
              _buildAboutRow(
                Translations.get('system_license', logic.lang),
                'Internal Tool • JA Tech',
                colors,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Action buttons: Open Logs & Open Config Folder
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.accentColor,
                  side: BorderSide(
                    color: colors.accentColor.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.folder_open_rounded, size: 16),
                label: Text(
                  Translations.get('open_logs_folder', logic.lang),
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: () {
                  final exeDir = File(Platform.resolvedExecutable).parent.path;
                  Process.start('explorer.exe', ['$exeDir/logs']);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.accentColor,
                  side: BorderSide(
                    color: colors.accentColor.withValues(alpha: 0.5),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.settings_suggest_rounded, size: 16),
                label: Text(
                  Translations.get('open_config_folder', logic.lang),
                  style: const TextStyle(fontSize: 12),
                ),
                onPressed: openAppFolder,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

Widget _buildIntervalChoice({
  required String label,
  required IconData icon,
  required String value,
  required String currentValue,
  required AppColors colors,
  required VoidCallback onSelect,
}) {
  final isSelected = value == currentValue;
  return Expanded(
    child: InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.accentColor.withValues(alpha: 0.15)
              : colors.subCardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? colors.accentColor : colors.borderDefault,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? colors.accentColor : colors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? colors.textPrimary : colors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildAboutRow(String title, String value, AppColors colors) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
