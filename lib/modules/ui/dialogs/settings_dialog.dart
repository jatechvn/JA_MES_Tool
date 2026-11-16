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
import '../../services/app_power_manager.dart';
import 'glass_update_dialog.dart';
import 'login_dialog.dart';

part 'settings_mes_api_part.dart';
part 'settings_display_glass_part.dart';
part 'settings_about_ota_part.dart';

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
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (ctx, anim1, anim2) =>
        _AppSettingsDialog(parentContext: context, logic: logic, theme: theme),
    transitionBuilder: (ctx, anim1, anim2, child) {
      final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _AppSettingsDialog extends StatefulWidget {
  final BuildContext parentContext;
  final AppLogic logic;
  final ThemeProvider theme;

  const _AppSettingsDialog({
    required this.parentContext,
    required this.logic,
    required this.theme,
  });

  @override
  State<_AppSettingsDialog> createState() => _AppSettingsDialogState();
}

class _AppSettingsDialogState extends State<_AppSettingsDialog> {
  // Snapshot initial glassmorphism tuning parameters for rollback on Cancel.
  late final double _origCardBlur;
  late final double _origCardOpacity;
  late final double _origDialogBlur;
  late final double _origDialogOpacity;
  late final double _origDropdownBlur;
  late final double _origDropdownOpacity;
  late final PerfTierMode _origPerfMode;
  late final bool _origEnableIdleSleep;
  late final int _origIdleTimeoutSeconds;

  late double _tempCardBlur;
  late double _tempCardOpacity;
  late double _tempDialogBlur;
  late double _tempDialogOpacity;
  late double _tempDropdownBlur;
  late double _tempDropdownOpacity;
  late bool _tempEnableIdleSleep;
  late int _tempIdleTimeoutSeconds;

  late final TextEditingController _tokenCtrl;
  late final TextEditingController _opIdCtrl;
  late final TextEditingController _uuidCtrl;
  late final TextEditingController _cookieCtrl;

  late final TextEditingController _otaServerPathCtrl;
  late final TextEditingController _otaUsernameCtrl;
  late final TextEditingController _otaPasswordCtrl;
  late String _otaInterval;

  bool _isCheckingForUpdates = false;
  UpdateCheckResult? _manualUpdateCheckResult;
  bool _isTestingShare = false;
  bool? _shareTestOk;
  String? _shareTestMessage;

  int _currentTab = 0;
  bool _isTestingConnection = false;
  bool? _connectionTestResult;
  String? _connectionTestMsg;
  bool _isSyncingCdp = false;

  @override
  void initState() {
    super.initState();
    final theme = widget.theme;
    final logic = widget.logic;

    _origCardBlur = theme.cardBlur;
    _origCardOpacity = theme.cardOpacity;
    _origDialogBlur = theme.dialogBlur;
    _origDialogOpacity = theme.dialogOpacity;
    _origDropdownBlur = theme.dropdownBlur;
    _origDropdownOpacity = theme.dropdownOpacity;
    _origPerfMode = theme.perfMode;
    _origEnableIdleSleep = logic.enableIdleSleep;
    _origIdleTimeoutSeconds = logic.idleTimeoutSeconds;

    _tempCardBlur = _origCardBlur;
    _tempCardOpacity = _origCardOpacity;
    _tempDialogBlur = _origDialogBlur;
    _tempDialogOpacity = _origDialogOpacity;
    _tempDropdownBlur = _origDropdownBlur;
    _tempDropdownOpacity = _origDropdownOpacity;
    _tempEnableIdleSleep = _origEnableIdleSleep;
    _tempIdleTimeoutSeconds = _origIdleTimeoutSeconds;

    _tokenCtrl = TextEditingController(text: logic.token);
    _opIdCtrl = TextEditingController(text: logic.operationId);
    _uuidCtrl = TextEditingController(text: logic.uuid);
    _cookieCtrl = TextEditingController(text: logic.cookie);

    final otaConfig = OtaUpdateService().currentConfig;
    _otaServerPathCtrl = TextEditingController(text: otaConfig.serverPath);
    _otaUsernameCtrl = TextEditingController(text: otaConfig.username);
    _otaPasswordCtrl = TextEditingController(text: otaConfig.password);
    const knownOtaIntervals = {'startup', 'daily', 'weekly', 'off'};
    _otaInterval = knownOtaIntervals.contains(otaConfig.checkInterval)
        ? otaConfig.checkInterval
        : 'daily';
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    _opIdCtrl.dispose();
    _uuidCtrl.dispose();
    _cookieCtrl.dispose();
    _otaServerPathCtrl.dispose();
    _otaUsernameCtrl.dispose();
    _otaPasswordCtrl.dispose();
    super.dispose();
  }

  void _rebuild(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  void _onSliderChange({
    double? cardBlur,
    double? cardOpacity,
    double? dialogBlur,
    double? dialogOpacity,
    double? dropdownBlur,
    double? dropdownOpacity,
  }) {
    _rebuild(() {
      if (cardBlur != null) _tempCardBlur = cardBlur;
      if (cardOpacity != null) _tempCardOpacity = cardOpacity;
      if (dialogBlur != null) _tempDialogBlur = dialogBlur;
      if (dialogOpacity != null) _tempDialogOpacity = dialogOpacity;
      if (dropdownBlur != null) _tempDropdownBlur = dropdownBlur;
      if (dropdownOpacity != null) _tempDropdownOpacity = dropdownOpacity;
    });
    widget.theme.setLiveGlassmorphism(
      cardBlur: _tempCardBlur,
      cardOpacity: _tempCardOpacity,
      dialogBlur: _tempDialogBlur,
      dialogOpacity: _tempDialogOpacity,
      dropdownBlur: _tempDropdownBlur,
      dropdownOpacity: _tempDropdownOpacity,
    );
  }

  void _rollbackAndClose() {
    // Restore the profile first because changing a tier also applies
    // that tier's default glass values.
    widget.theme.setPerfTierMode(_origPerfMode);
    widget.theme.setLiveGlassmorphism(
      cardBlur: _origCardBlur,
      cardOpacity: _origCardOpacity,
      dialogBlur: _origDialogBlur,
      dialogOpacity: _origDialogOpacity,
      dropdownBlur: _origDropdownBlur,
      dropdownOpacity: _origDropdownOpacity,
    );
    if (_tempEnableIdleSleep != _origEnableIdleSleep) {
      AppPowerManager.instance.setEnableIdleSleep(_origEnableIdleSleep);
    }
    if (_tempIdleTimeoutSeconds != _origIdleTimeoutSeconds) {
      AppPowerManager.instance.setIdleTimeout(
        Duration(seconds: _origIdleTimeoutSeconds),
      );
    }
    Navigator.pop(context);
  }

  Future<void> _saveAndClose() async {
    final logic = widget.logic;
    final activeColors = widget.theme.colors;
    await logic.saveFullSettings(
      token: _tokenCtrl.text.trim(),
      operationId: _opIdCtrl.text.trim(),
      uuid: _uuidCtrl.text.trim(),
      cookie: _cookieCtrl.text.trim(),
      bgBlur: _tempCardBlur,
      bgOpacity: _tempCardOpacity,
      dialogBlur: _tempDialogBlur,
      dialogOpacity: _tempDialogOpacity,
      dropdownBlur: _tempDropdownBlur,
      dropdownOpacity: _tempDropdownOpacity,
      enableIdleSleep: _tempEnableIdleSleep,
      idleTimeoutSeconds: _tempIdleTimeoutSeconds,
    );
    await OtaUpdateService().updateConfig(
      serverPath: _otaServerPathCtrl.text.trim(),
      username: _otaUsernameCtrl.text.trim(),
      password: _otaPasswordCtrl.text.trim(),
      checkInterval: _otaInterval,
    );
    if (!mounted) return;
    Navigator.pop(context);
    if (widget.parentContext.mounted) {
      showAppToast(
        widget.parentContext,
        colors: activeColors,
        message: Translations.get('fetched_success', logic.lang),
        icon: Icons.check_circle_rounded,
        accentColor: activeColors.accentEmerald,
      );
    }
  }

  Widget _buildCurrentTabContent(AppColors colors) {
    switch (_currentTab) {
      case 0:
        return _buildMesApiTab(colors);
      case 1:
        return _buildDisplayAndGlassTab(colors);
      case 2:
        return _buildAboutAndUpdatesTab(colors);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final logic = widget.logic;
    final theme = widget.theme;

    return ListenableBuilder(
      listenable: Listenable.merge([logic, theme]),
      builder: (context, _) {
        final activeColors = theme.colors;
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
              onPressed: _rollbackAndClose,
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
              onPressed: _saveAndClose,
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
                      currentTab: _currentTab,
                      icon: Icons.cloud_sync_rounded,
                      label: Translations.get('tab_mes_api', logic.lang),
                      colors: activeColors,
                      onTap: () => _rebuild(() => _currentTab = 0),
                    ),
                    const SizedBox(width: 8),
                    _buildTabButton(
                      index: 1,
                      currentTab: _currentTab,
                      icon: Icons.palette_rounded,
                      label: Translations.get('tab_display_glass', logic.lang),
                      colors: activeColors,
                      onTap: () => _rebuild(() => _currentTab = 1),
                    ),
                    const SizedBox(width: 8),
                    _buildTabButton(
                      index: 2,
                      currentTab: _currentTab,
                      icon: Icons.info_outline_rounded,
                      label: Translations.get('tab_about_updates', logic.lang),
                      colors: activeColors,
                      onTap: () => _rebuild(() => _currentTab = 2),
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
                    child: _buildCurrentTabContent(activeColors),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
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
