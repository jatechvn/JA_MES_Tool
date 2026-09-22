import 'dart:io';
import 'package:flutter/material.dart';
import '../../logic.dart';
import '../../translations.dart';
import '../../browser_helper.dart';
import '../../build_info.dart';
import '../../constants.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/glass_widgets.dart';
import '../../../widgets/glass_dialog.dart';
import '../../../widgets/app_toast.dart';
import '../../services/ota_update_service.dart';
import 'glass_update_dialog.dart';

String _formatSettingsTranslation(
  String key,
  String lang,
  Map<String, String> values,
) {
  var text = Translations.get(key, lang);
  for (final entry in values.entries) {
    text = text.replaceAll('{${entry.key}}', entry.value);
  }
  return text;
}

String _shareProbeMessage(SmbConnectResult result, String lang) {
  if (!result.connected) {
    return result.errorMessage ??
        Translations.get('share_connect_failed', lang);
  }
  switch (result.accessMode) {
    case ShareAccessMode.currentSession:
      return Translations.get('share_connected_session', lang);
    case ShareAccessMode.credentials:
      return Translations.get('share_connected_credentials', lang);
    case ShareAccessMode.localPath:
      return Translations.get('share_connected_local', lang);
    case ShareAccessMode.none:
      return Translations.get('share_connected', lang);
  }
}

String _localizedHardwareTier(HardwareTier tier, String lang) {
  switch (tier) {
    case HardwareTier.ultra:
      return Translations.get('hardware_tier_ultra', lang);
    case HardwareTier.balanced:
      return Translations.get('hardware_tier_balanced', lang);
    case HardwareTier.lite:
      return Translations.get('hardware_tier_lite', lang);
  }
}

Future<void> showAppSettingsDialog(
  BuildContext context,
  AppLogic logic,
  ThemeProvider theme,
) {
  // Snapshot initial glassmorphism tuning parameters for rollback on Cancel
  final origCardBlur = theme.cardBlur;
  final origCardOpacity = theme.cardOpacity;
  final origDialogBlur = theme.dialogBlur;
  final origDialogOpacity = theme.dialogOpacity;
  final origDropdownBlur = theme.dropdownBlur;
  final origDropdownOpacity = theme.dropdownOpacity;
  final origPerfMode = theme.perfMode;

  double tempCardBlur = origCardBlur;
  double tempCardOpacity = origCardOpacity;
  double tempDialogBlur = origDialogBlur;
  double tempDialogOpacity = origDialogOpacity;
  double tempDropdownBlur = origDropdownBlur;
  double tempDropdownOpacity = origDropdownOpacity;

  final tokenCtrl = TextEditingController(text: logic.token);
  final opIdCtrl = TextEditingController(text: logic.operationId);
  final uuidCtrl = TextEditingController(text: logic.uuid);
  final cookieCtrl = TextEditingController(text: logic.cookie);

  // OTA Update settings controllers & state
  final otaConfig = OtaUpdateService().currentConfig;
  final otaServerPathCtrl = TextEditingController(text: otaConfig.serverPath);
  final otaUsernameCtrl = TextEditingController(text: otaConfig.username);
  final otaPasswordCtrl = TextEditingController(text: otaConfig.password);
  const knownOtaIntervals = {'startup', 'daily', 'weekly', 'off'};
  String otaInterval = knownOtaIntervals.contains(otaConfig.checkInterval)
      ? otaConfig.checkInterval
      : 'daily';
  bool isCheckingForUpdates = false;
  UpdateCheckResult? manualUpdateCheckResult;
  bool isTestingShare = false;
  bool? shareTestOk;
  String? shareTestMessage;

  int currentTab = 0;
  bool isTestingConnection = false;
  bool? connectionTestResult;
  String? connectionTestMsg;
  bool isSyncingCdp = false;

  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim1, anim2, child) {
      final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
          child: StatefulBuilder(
            builder: (dialogCtx, setDialogState) {
              final activeColors = theme.colors;

              void rollbackAndClose() {
                // Restore the profile first because changing a tier also applies
                // that tier's default glass values.
                theme.setPerfTierMode(origPerfMode);
                theme.setLiveGlassmorphism(
                  cardBlur: origCardBlur,
                  cardOpacity: origCardOpacity,
                  dialogBlur: origDialogBlur,
                  dialogOpacity: origDialogOpacity,
                  dropdownBlur: origDropdownBlur,
                  dropdownOpacity: origDropdownOpacity,
                );
                Navigator.pop(dialogCtx);
              }

              return GlassDialog(
                title: Translations.get('settings', logic.lang),
                icon: Icons.settings_rounded,
                isDark: theme.isDark,
                blurSigma: theme.dialogBlur,
                bgOpacity: theme.dialogOpacity,
                width: 760,
                height: 600,
                contentPadding: EdgeInsets.zero,
                actions: [
                  TextButton(
                    onPressed: rollbackAndClose,
                    child: Text(
                      Translations.get('cancel', logic.lang),
                      style: TextStyle(
                        color: activeColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GlowingActionButton(
                    height: 36,
                    colors: activeColors,
                    icon: Icons.check_rounded,
                    label: Translations.get('save', logic.lang),
                    onPressed: () async {
                      await logic.saveFullSettings(
                        token: tokenCtrl.text.trim(),
                        operationId: opIdCtrl.text.trim(),
                        uuid: uuidCtrl.text.trim(),
                        cookie: cookieCtrl.text.trim(),
                        bgBlur: tempCardBlur,
                        bgOpacity: tempCardOpacity,
                        dialogBlur: tempDialogBlur,
                        dialogOpacity: tempDialogOpacity,
                        dropdownBlur: tempDropdownBlur,
                        dropdownOpacity: tempDropdownOpacity,
                      );
                      await OtaUpdateService().updateConfig(
                        serverPath: otaServerPathCtrl.text.trim(),
                        username: otaUsernameCtrl.text.trim(),
                        password: otaPasswordCtrl.text.trim(),
                        checkInterval: otaInterval,
                      );
                      if (dialogCtx.mounted) {
                        Navigator.pop(dialogCtx);
                        showAppToast(
                          context,
                          colors: activeColors,
                          message: Translations.get(
                            'fetched_success',
                            logic.lang,
                          ),
                          icon: Icons.check_circle_rounded,
                          accentColor: activeColors.accentEmerald,
                        );
                      }
                    },
                  ),
                ],
                child: Column(
                  children: [
                    // Tab Bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: activeColors.subCardBg.withValues(alpha: 0.3),
                        border: Border(
                          bottom: BorderSide(color: activeColors.borderDefault),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildTabButton(
                            index: 0,
                            currentTab: currentTab,
                            icon: Icons.cloud_sync_rounded,
                            label: Translations.get('tab_mes_api', logic.lang),
                            colors: activeColors,
                            onTap: () => setDialogState(() => currentTab = 0),
                          ),
                          const SizedBox(width: 8),
                          _buildTabButton(
                            index: 1,
                            currentTab: currentTab,
                            icon: Icons.palette_rounded,
                            label: Translations.get(
                              'tab_display_glass',
                              logic.lang,
                            ),
                            colors: activeColors,
                            onTap: () => setDialogState(() => currentTab = 1),
                          ),
                          const SizedBox(width: 8),
                          _buildTabButton(
                            index: 2,
                            currentTab: currentTab,
                            icon: Icons.info_outline_rounded,
                            label: Translations.get(
                              'tab_about_updates',
                              logic.lang,
                            ),
                            colors: activeColors,
                            onTap: () => setDialogState(() => currentTab = 2),
                          ),
                        ],
                      ),
                    ),

                    // Tab Content Body
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _buildCurrentTabContent(
                            currentTab: currentTab,
                            context: context,
                            dialogCtx: dialogCtx,
                            logic: logic,
                            theme: theme,
                            colors: activeColors,
                            tokenCtrl: tokenCtrl,
                            opIdCtrl: opIdCtrl,
                            uuidCtrl: uuidCtrl,
                            cookieCtrl: cookieCtrl,
                            tempCardBlur: tempCardBlur,
                            tempCardOpacity: tempCardOpacity,
                            tempDialogBlur: tempDialogBlur,
                            tempDialogOpacity: tempDialogOpacity,
                            tempDropdownBlur: tempDropdownBlur,
                            tempDropdownOpacity: tempDropdownOpacity,
                            isTestingConnection: isTestingConnection,
                            connectionTestResult: connectionTestResult,
                            connectionTestMsg: connectionTestMsg,
                            isSyncingCdp: isSyncingCdp,
                            otaServerPathCtrl: otaServerPathCtrl,
                            otaUsernameCtrl: otaUsernameCtrl,
                            otaPasswordCtrl: otaPasswordCtrl,
                            otaInterval: otaInterval,
                            isCheckingForUpdates: isCheckingForUpdates,
                            manualUpdateCheckResult: manualUpdateCheckResult,
                            isTestingShare: isTestingShare,
                            shareTestOk: shareTestOk,
                            shareTestMessage: shareTestMessage,
                            setDialogState: setDialogState,
                            onIntervalChanged: (val) {
                              setDialogState(() => otaInterval = val);
                            },
                            onUpdateCheckStateChanged: (checking, result) {
                              setDialogState(() {
                                isCheckingForUpdates = checking;
                                manualUpdateCheckResult = result;
                              });
                            },
                            onShareTestStateChanged: (checking, ok, message) {
                              setDialogState(() {
                                isTestingShare = checking;
                                shareTestOk = ok;
                                shareTestMessage = message;
                              });
                            },
                            onSliderChange:
                                ({
                                  double? cardBlur,
                                  double? cardOpacity,
                                  double? dialogBlur,
                                  double? dialogOpacity,
                                  double? dropdownBlur,
                                  double? dropdownOpacity,
                                }) {
                                  setDialogState(() {
                                    if (cardBlur != null) {
                                      tempCardBlur = cardBlur;
                                    }
                                    if (cardOpacity != null) {
                                      tempCardOpacity = cardOpacity;
                                    }
                                    if (dialogBlur != null) {
                                      tempDialogBlur = dialogBlur;
                                    }
                                    if (dialogOpacity != null) {
                                      tempDialogOpacity = dialogOpacity;
                                    }
                                    if (dropdownBlur != null) {
                                      tempDropdownBlur = dropdownBlur;
                                    }
                                    if (dropdownOpacity != null) {
                                      tempDropdownOpacity = dropdownOpacity;
                                    }
                                  });
                                  theme.setLiveGlassmorphism(
                                    cardBlur: tempCardBlur,
                                    cardOpacity: tempCardOpacity,
                                    dialogBlur: tempDialogBlur,
                                    dialogOpacity: tempDialogOpacity,
                                    dropdownBlur: tempDropdownBlur,
                                    dropdownOpacity: tempDropdownOpacity,
                                  );
                                },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

Widget _buildTabButton({
  required int index,
  required int currentTab,
  required IconData icon,
  required String label,
  required AppColors colors,
  required VoidCallback onTap,
}) {
  final isSelected = index == currentTab;
  return Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.accentColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? colors.accentColor.withValues(alpha: 0.45)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? colors.accentColor : colors.textSecondary,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
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

Widget _buildCurrentTabContent({
  required int currentTab,
  required BuildContext context,
  required BuildContext dialogCtx,
  required AppLogic logic,
  required ThemeProvider theme,
  required AppColors colors,
  required TextEditingController tokenCtrl,
  required TextEditingController opIdCtrl,
  required TextEditingController uuidCtrl,
  required TextEditingController cookieCtrl,
  required double tempCardBlur,
  required double tempCardOpacity,
  required double tempDialogBlur,
  required double tempDialogOpacity,
  required double tempDropdownBlur,
  required double tempDropdownOpacity,
  required bool isTestingConnection,
  required bool? connectionTestResult,
  required String? connectionTestMsg,
  required bool isSyncingCdp,
  required TextEditingController otaServerPathCtrl,
  required TextEditingController otaUsernameCtrl,
  required TextEditingController otaPasswordCtrl,
  required String otaInterval,
  required bool isCheckingForUpdates,
  required UpdateCheckResult? manualUpdateCheckResult,
  required bool isTestingShare,
  required bool? shareTestOk,
  required String? shareTestMessage,
  required StateSetter setDialogState,
  required void Function(String) onIntervalChanged,
  required void Function(bool, UpdateCheckResult?) onUpdateCheckStateChanged,
  required void Function(bool, bool?, String?) onShareTestStateChanged,
  required void Function({
    double? cardBlur,
    double? cardOpacity,
    double? dialogBlur,
    double? dialogOpacity,
    double? dropdownBlur,
    double? dropdownOpacity,
  })
  onSliderChange,
}) {
  switch (currentTab) {
    case 0:
      return _buildMesApiTab(
        context,
        dialogCtx,
        logic,
        theme,
        colors,
        tokenCtrl,
        opIdCtrl,
        uuidCtrl,
        cookieCtrl,
        isTestingConnection,
        connectionTestResult,
        connectionTestMsg,
        isSyncingCdp,
        setDialogState,
      );
    case 1:
      return _buildDisplayAndGlassTab(
        context,
        logic,
        theme,
        colors,
        tempCardBlur,
        tempCardOpacity,
        tempDialogBlur,
        tempDialogOpacity,
        tempDropdownBlur,
        tempDropdownOpacity,
        setDialogState,
        onSliderChange,
      );
    case 2:
      return _buildAboutAndUpdatesTab(
        context,
        dialogCtx,
        logic,
        theme,
        colors,
        otaServerPathCtrl,
        otaUsernameCtrl,
        otaPasswordCtrl,
        otaInterval,
        isCheckingForUpdates,
        manualUpdateCheckResult,
        isTestingShare,
        shareTestOk,
        shareTestMessage,
        setDialogState,
        onIntervalChanged,
        onUpdateCheckStateChanged,
        onShareTestStateChanged,
      );
    default:
      return const SizedBox.shrink();
  }
}

Widget _buildMesApiTab(
  BuildContext context,
  BuildContext dialogCtx,
  AppLogic logic,
  ThemeProvider theme,
  AppColors colors,
  TextEditingController tokenCtrl,
  TextEditingController opIdCtrl,
  TextEditingController uuidCtrl,
  TextEditingController cookieCtrl,
  bool isTestingConnection,
  bool? connectionTestResult,
  String? connectionTestMsg,
  bool isSyncingCdp,
  StateSetter setDialogState,
) {
  return ListView(
    key: const PageStorageKey('settings_tab_mes_api'),
    physics: const BouncingScrollPhysics(),
    children: [
      // CDP Auto Sync Card
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
                Icon(Icons.bolt_rounded, color: colors.accentAmber, size: 20),
                const SizedBox(width: 8),
                Text(
                  Translations.get('cdp_sync_title', logic.lang),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              Translations.get('cdp_sync_desc', logic.lang),
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.accentColor,
                      side: BorderSide(
                        color: colors.accentColor.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                    label: Text(
                      Translations.get('btn_open_browser', logic.lang),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () async {
                      await BrowserHelper.launchBrowser();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.accentEmerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: isSyncingCdp
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.sync_rounded, size: 16),
                    label: Text(
                      isSyncingCdp
                          ? Translations.get('status_fetching', logic.lang)
                          : Translations.get(
                              'btn_sync_credentials',
                              logic.lang,
                            ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: isSyncingCdp
                        ? null
                        : () async {
                            setDialogState(() => isSyncingCdp = true);
                            final creds =
                                await BrowserHelper.fetchCredentialsFromBrowser();
                            if (!dialogCtx.mounted) return;
                            setDialogState(() => isSyncingCdp = false);
                            if (creds != null &&
                                creds.token != null &&
                                creds.token!.isNotEmpty) {
                              tokenCtrl.text = creds.token!;
                              uuidCtrl.text = creds.uuid ?? '';
                              opIdCtrl.text = creds.operationId ?? '';
                              cookieCtrl.text = creds.cookie ?? '';
                              if (context.mounted) {
                                showAppToast(
                                  context,
                                  colors: colors,
                                  message: Translations.get(
                                    'fetched_success',
                                    logic.lang,
                                  ),
                                  icon: Icons.check_circle_rounded,
                                  accentColor: colors.accentEmerald,
                                );
                              }
                            } else {
                              if (context.mounted) {
                                showAppToast(
                                  context,
                                  colors: colors,
                                  message: Translations.get(
                                    'fetched_fail',
                                    logic.lang,
                                  ),
                                  icon: Icons.error_outline_rounded,
                                  accentColor: colors.accentRose,
                                );
                              }
                            }
                          },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),

      // Credentials Input fields
      _buildTextField(
        label: Translations.get('mes_token', logic.lang),
        controller: tokenCtrl,
        colors: colors,
        maxLines: 2,
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _buildTextField(
              label: Translations.get('operation_id', logic.lang),
              controller: opIdCtrl,
              colors: colors,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildTextField(
              label: Translations.get('uuid', logic.lang),
              controller: uuidCtrl,
              colors: colors,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      _buildTextField(
        label: Translations.get('cookie', logic.lang),
        controller: cookieCtrl,
        colors: colors,
        maxLines: 2,
      ),
      const SizedBox(height: 16),

      // Test Connection Button
      Row(
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.accentCyan,
              side: BorderSide(color: colors.accentCyan.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: isTestingConnection
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.accentCyan,
                    ),
                  )
                : Icon(
                    Icons.shield_outlined,
                    size: 16,
                    color: colors.accentCyan,
                  ),
            label: Text(
              Translations.get('verify_connection', logic.lang),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            onPressed: isTestingConnection
                ? null
                : () async {
                    setDialogState(() {
                      isTestingConnection = true;
                      connectionTestResult = null;
                      connectionTestMsg = null;
                    });
                    final ok = await logic.testConnection(
                      testToken: tokenCtrl.text.trim(),
                      testOpId: opIdCtrl.text.trim(),
                      testUuid: uuidCtrl.text.trim(),
                      testCookie: cookieCtrl.text.trim(),
                    );
                    if (!dialogCtx.mounted) return;
                    setDialogState(() {
                      isTestingConnection = false;
                      connectionTestResult = ok;
                      connectionTestMsg = ok
                          ? Translations.get('connection_valid', logic.lang)
                          : logic.connectionError ??
                                Translations.get(
                                  'connection_failed',
                                  logic.lang,
                                );
                    });
                  },
          ),
          const SizedBox(width: 12),
          if (connectionTestResult != null)
            Expanded(
              child: Row(
                children: [
                  Icon(
                    connectionTestResult == true
                        ? Icons.check_circle_rounded
                        : Icons.error_outline_rounded,
                    color: connectionTestResult == true
                        ? colors.accentEmerald
                        : colors.accentRose,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      connectionTestMsg ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: connectionTestResult == true
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
      ),
    ],
  );
}

Widget _buildDisplayAndGlassTab(
  BuildContext context,
  AppLogic logic,
  ThemeProvider theme,
  AppColors colors,
  double tempCardBlur,
  double tempCardOpacity,
  double tempDialogBlur,
  double tempDialogOpacity,
  double tempDropdownBlur,
  double tempDropdownOpacity,
  StateSetter setDialogState,
  void Function({
    double? cardBlur,
    double? cardOpacity,
    double? dialogBlur,
    double? dialogOpacity,
    double? dropdownBlur,
    double? dropdownOpacity,
  })
  onSliderChange,
) {
  void selectPerfTier(PerfTierMode mode) {
    theme.setPerfTierMode(mode);
    onSliderChange(
      cardBlur: theme.cardBlur,
      cardOpacity: theme.cardOpacity,
      dialogBlur: theme.dialogBlur,
      dialogOpacity: theme.dialogOpacity,
      dropdownBlur: theme.dropdownBlur,
      dropdownOpacity: theme.dropdownOpacity,
    );
  }

  return ListView(
    key: const PageStorageKey('settings_tab_display_glass'),
    physics: const BouncingScrollPhysics(),
    children: [
      // 1. Language Selector
      Text(
        Translations.get('language', logic.lang),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          _buildLanguageChoice(
            label: 'Tiếng Việt',
            flag: '🇻🇳',
            code: 'vn',
            currentCode: logic.lang,
            colors: colors,
            onSelect: () {
              logic.setLanguage('vn');
              setDialogState(() {});
            },
          ),
          const SizedBox(width: 10),
          _buildLanguageChoice(
            label: 'English',
            flag: '🇬🇧',
            code: 'en',
            currentCode: logic.lang,
            colors: colors,
            onSelect: () {
              logic.setLanguage('en');
              setDialogState(() {});
            },
          ),
          const SizedBox(width: 10),
          _buildLanguageChoice(
            label: '中文',
            flag: '🇨🇳',
            code: 'cn',
            currentCode: logic.lang,
            colors: colors,
            onSelect: () {
              logic.setLanguage('cn');
              setDialogState(() {});
            },
          ),
        ],
      ),
      const SizedBox(height: 18),

      // 2. Performance Graphic Tier Switcher
      Text(
        Translations.get('perf_tooltip', logic.lang),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: colors.textPrimary,
        ),
      ),
      const SizedBox(height: 8),
      Column(
        children: [
          _buildTierTile(
            mode: PerfTierMode.auto,
            title: _formatSettingsTranslation('perf_auto_title', logic.lang, {
              'tier': _localizedHardwareTier(theme.effectiveTier, logic.lang),
            }),
            desc: _formatSettingsTranslation('perf_auto_desc', logic.lang, {
              'cores': theme.cpuCores.toString(),
              'score': theme.hardwareScore.toString(),
            }),
            icon: Icons.auto_awesome_rounded,
            currentMode: theme.perfMode,
            colors: colors,
            onSelect: () => selectPerfTier(PerfTierMode.auto),
          ),
          const SizedBox(height: 8),
          _buildTierTile(
            mode: PerfTierMode.ultra,
            title: Translations.get('tier_ultra', logic.lang),
            desc: Translations.get('tier_ultra_desc', logic.lang),
            icon: Icons.bolt_rounded,
            currentMode: theme.perfMode,
            colors: colors,
            onSelect: () => selectPerfTier(PerfTierMode.ultra),
          ),
          const SizedBox(height: 8),
          _buildTierTile(
            mode: PerfTierMode.balanced,
            title: Translations.get('tier_balanced', logic.lang),
            desc: Translations.get('tier_balanced_desc', logic.lang),
            icon: Icons.balance_rounded,
            currentMode: theme.perfMode,
            colors: colors,
            onSelect: () => selectPerfTier(PerfTierMode.balanced),
          ),
          const SizedBox(height: 8),
          _buildTierTile(
            mode: PerfTierMode.lite,
            title: Translations.get('tier_lite', logic.lang),
            desc: Translations.get('tier_lite_desc', logic.lang),
            icon: Icons.eco_rounded,
            currentMode: theme.perfMode,
            colors: colors,
            onSelect: () => selectPerfTier(PerfTierMode.lite),
          ),
        ],
      ),
      const SizedBox(height: 18),

      // 3. Glassmorphism Live-Tuning BentoCard
      BentoCard(
        colors: colors,
        padding: const EdgeInsets.all(16),
        borderRadius: 14,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.blur_on_rounded,
                      size: 18,
                      color: colors.accentColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      Translations.get('glass_settings_title', logic.lang),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {
                    theme.resetToDefaults();
                    onSliderChange(
                      cardBlur: theme.cardBlur,
                      cardOpacity: theme.cardOpacity,
                      dialogBlur: theme.dialogBlur,
                      dialogOpacity: theme.dialogOpacity,
                      dropdownBlur: theme.dropdownBlur,
                      dropdownOpacity: theme.dropdownOpacity,
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Text(
                      Translations.get('default', logic.lang),
                      style: TextStyle(
                        color: colors.accentCyan,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Bento Card Sliders (Row 1: Card Blur & Opacity)
            Row(
              children: [
                Expanded(
                  child: _buildSliderTile(
                    label: Translations.get('card_blur_label', logic.lang),
                    value: tempCardBlur,
                    min: 0,
                    max: 40,
                    colors: colors,
                    labelWidth: 105,
                    onChanged: (v) => onSliderChange(cardBlur: v),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSliderTile(
                    label: Translations.get('card_opacity_label', logic.lang),
                    value: tempCardOpacity,
                    min: 0.05,
                    max: 1.0,
                    isPercent: true,
                    colors: colors,
                    labelWidth: 105,
                    onChanged: (v) => onSliderChange(cardOpacity: v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Divider(color: colors.borderDefault, height: 1),
            const SizedBox(height: 6),

            // Dialog Sliders (Row 2: Dialog Blur & Opacity)
            Row(
              children: [
                Expanded(
                  child: _buildSliderTile(
                    label: Translations.get('dialog_blur', logic.lang),
                    value: tempDialogBlur,
                    min: 0,
                    max: 40,
                    colors: colors,
                    labelWidth: 105,
                    onChanged: (v) => onSliderChange(dialogBlur: v),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSliderTile(
                    label: Translations.get('dialog_opacity', logic.lang),
                    value: tempDialogOpacity,
                    min: 0.1,
                    max: 1.0,
                    isPercent: true,
                    colors: colors,
                    labelWidth: 105,
                    onChanged: (v) => onSliderChange(dialogOpacity: v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Divider(color: colors.borderDefault, height: 1),
            const SizedBox(height: 6),

            // Dropdown Sliders (Row 3: Dropdown Blur & Opacity)
            Row(
              children: [
                Expanded(
                  child: _buildSliderTile(
                    label: Translations.get('dropdown_blur_label', logic.lang),
                    value: tempDropdownBlur,
                    min: 0,
                    max: 40,
                    colors: colors,
                    labelWidth: 105,
                    onChanged: (v) => onSliderChange(dropdownBlur: v),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSliderTile(
                    label: Translations.get(
                      'dropdown_opacity_label',
                      logic.lang,
                    ),
                    value: tempDropdownOpacity,
                    min: 0.1,
                    max: 1.0,
                    isPercent: true,
                    colors: colors,
                    labelWidth: 105,
                    onChanged: (v) => onSliderChange(dropdownOpacity: v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildLanguageChoice({
  required String label,
  required String flag,
  required String code,
  required String currentCode,
  required AppColors colors,
  required VoidCallback onSelect,
}) {
  final isSelected = code == currentCode;
  return Expanded(
    child: InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
            Text(flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? colors.textPrimary : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
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

Widget _buildTierTile({
  required PerfTierMode mode,
  required String title,
  required String desc,
  required IconData icon,
  required PerfTierMode currentMode,
  required AppColors colors,
  required VoidCallback onSelect,
}) {
  final isSelected = mode == currentMode;
  return InkWell(
    onTap: onSelect,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? colors.accentColor.withValues(alpha: 0.12)
            : colors.subCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? colors.accentColor : colors.borderDefault,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isSelected ? colors.accentColor : colors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(fontSize: 11, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          if (isSelected)
            Icon(
              Icons.check_circle_rounded,
              size: 18,
              color: colors.accentColor,
            ),
        ],
      ),
    ),
  );
}

Widget _buildTextField({
  required String label,
  required TextEditingController controller,
  required AppColors colors,
  int maxLines = 1,
  bool obscureText = false,
  String? hintText,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (label.isNotEmpty) ...[
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 5),
      ],
      TextField(
        controller: controller,
        maxLines: maxLines,
        obscureText: obscureText,
        style: TextStyle(fontSize: 12.5, color: colors.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 12,
            color: colors.textSecondary.withValues(alpha: 0.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          filled: true,
          fillColor: colors.subCardBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colors.subCardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colors.subCardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colors.accentColor, width: 1.5),
          ),
        ),
      ),
    ],
  );
}

Widget _buildSliderTile({
  required String label,
  required double value,
  required double min,
  required double max,
  required AppColors colors,
  required ValueChanged<double> onChanged,
  bool isPercent = false,
  double labelWidth = 105,
}) {
  final displayValue = isPercent
      ? '${(value * 100).toInt()}%'
      : '${value.toInt()} px';
  return Row(
    children: [
      SizedBox(
        width: labelWidth,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      Expanded(
        child: SliderTheme(
          data: SliderThemeData(
            thumbColor: colors.accentColor,
            activeTrackColor: colors.accentColor,
            inactiveTrackColor: colors.subCardBorder,
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ),
      SizedBox(
        width: 50,
        child: Text(
          displayValue,
          textAlign: TextAlign.end,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colors.accentColor,
          ),
        ),
      ),
    ],
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

Widget _buildAboutAndUpdatesTab(
  BuildContext context,
  BuildContext dialogCtx,
  AppLogic logic,
  ThemeProvider theme,
  AppColors colors,
  TextEditingController otaServerPathCtrl,
  TextEditingController otaUsernameCtrl,
  TextEditingController otaPasswordCtrl,
  String otaInterval,
  bool isCheckingForUpdates,
  UpdateCheckResult? manualUpdateCheckResult,
  bool isTestingShare,
  bool? shareTestOk,
  String? shareTestMessage,
  StateSetter setDialogState,
  void Function(String) onIntervalChanged,
  void Function(bool, UpdateCheckResult?) onUpdateCheckStateChanged,
  void Function(bool, bool?, String?) onShareTestStateChanged,
) {
  final isDark = theme.isDark;
  final otaConfig = OtaUpdateService().currentConfig;
  final timestamp = BuildInfo.debugTimestamp;

  Future<void> checkForUpdatesManually() async {
    onUpdateCheckStateChanged(true, null);
    final path = otaServerPathCtrl.text.trim();
    try {
      final result = await OtaUpdateService().checkForUpdates(
        overrideServerPath: path.isEmpty ? null : path,
        overrideUsername: otaUsernameCtrl.text.trim(),
        overridePassword: otaPasswordCtrl.text,
        isManual: true,
      );
      if (!dialogCtx.mounted) return;
      onUpdateCheckStateChanged(false, result);
      if (result.hasUpdate && result.packageInfo != null && dialogCtx.mounted) {
        showGlassUpdateDialog(
          context: context,
          packageInfo: result.packageInfo!,
          lang: logic.lang,
        );
      }
    } catch (e) {
      if (!dialogCtx.mounted) return;
      onUpdateCheckStateChanged(
        false,
        UpdateCheckResult(
          hasUpdate: false,
          currentVersion: appVersion,
          isConnectionSuccess: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> testShareConnection() async {
    onShareTestStateChanged(true, null, null);
    try {
      final result = await OtaUpdateService().testConnection(
        path: otaServerPathCtrl.text.trim(),
        username: otaUsernameCtrl.text.trim(),
        password: otaPasswordCtrl.text,
      );
      if (!dialogCtx.mounted) return;
      onShareTestStateChanged(
        false,
        result.connected,
        _shareProbeMessage(result, logic.lang),
      );
    } catch (e) {
      if (!dialogCtx.mounted) return;
      onShareTestStateChanged(
        false,
        false,
        e.toString().replaceFirst('Exception: ', ''),
      );
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
                  onPressed: isCheckingForUpdates
                      ? null
                      : checkForUpdatesManually,
                  icon: isCheckingForUpdates
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
                    isCheckingForUpdates
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
            if (manualUpdateCheckResult == null &&
                shareTestMessage == null &&
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
            if (manualUpdateCheckResult != null) ...[
              const SizedBox(height: 14),
              if (manualUpdateCheckResult.hasUpdate &&
                  manualUpdateCheckResult.packageInfo != null) ...[
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
                          '${Translations.get('update_available', logic.lang)} (${manualUpdateCheckResult.packageInfo!.version.displayVersion} • ${manualUpdateCheckResult.packageInfo!.formattedSize})',
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
                            packageInfo: manualUpdateCheckResult.packageInfo!,
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
              ] else if (manualUpdateCheckResult.errorMessage != null) ...[
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
                          manualUpdateCheckResult.errorMessage!,
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
                          Translations.get('no_updates_available', logic.lang),
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
              controller: otaServerPathCtrl,
              colors: colors,
              hintText: Translations.get('server_path_hint', logic.lang),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: isTestingShare ? null : testShareConnection,
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
                  icon: isTestingShare
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
                    isTestingShare
                        ? Translations.get(
                            'testing_share_connection',
                            logic.lang,
                          )
                        : Translations.get('test_share_connection', logic.lang),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (shareTestMessage != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          shareTestOk == true
                              ? Icons.check_circle_rounded
                              : Icons.error_outline_rounded,
                          color: shareTestOk == true
                              ? colors.accentEmerald
                              : colors.accentRose,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            shareTestMessage,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: shareTestOk == true
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
                  currentValue: otaInterval,
                  colors: colors,
                  onSelect: () => onIntervalChanged('startup'),
                ),
                const SizedBox(width: 8),
                _buildIntervalChoice(
                  label: Translations.get('interval_daily', logic.lang),
                  icon: Icons.today_rounded,
                  value: 'daily',
                  currentValue: otaInterval,
                  colors: colors,
                  onSelect: () => onIntervalChanged('daily'),
                ),
                const SizedBox(width: 8),
                _buildIntervalChoice(
                  label: Translations.get('interval_weekly', logic.lang),
                  icon: Icons.date_range_rounded,
                  value: 'weekly',
                  currentValue: otaInterval,
                  colors: colors,
                  onSelect: () => onIntervalChanged('weekly'),
                ),
                const SizedBox(width: 8),
                _buildIntervalChoice(
                  label: Translations.get('interval_disabled', logic.lang),
                  icon: Icons.block_rounded,
                  value: 'off',
                  currentValue: otaInterval,
                  colors: colors,
                  onSelect: () => onIntervalChanged('off'),
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
                    controller: otaUsernameCtrl,
                    colors: colors,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    label: Translations.get('ota_password', logic.lang),
                    controller: otaPasswordCtrl,
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
              _formatSettingsTranslation('hardware_profile_value', logic.lang, {
                'cores': theme.cpuCores.toString(),
                'tier': _localizedHardwareTier(theme.effectiveTier, logic.lang),
              }),
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
