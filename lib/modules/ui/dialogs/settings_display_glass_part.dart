part of 'settings_dialog.dart';

extension _SettingsDisplayGlassTabExt on _AppSettingsDialogState {
  Widget _buildDisplayAndGlassTab(AppColors colors) {
    final logic = widget.logic;
    final theme = widget.theme;

    void selectPerfTier(PerfTierMode mode) {
      theme.setPerfTierMode(mode);
      _onSliderChange(
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
                _rebuild(() {});
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
                _rebuild(() {});
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
                _rebuild(() {});
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
                      _onSliderChange(
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
                      value: _tempCardBlur,
                      min: 0,
                      max: 40,
                      colors: colors,
                      labelWidth: 105,
                      onChanged: (v) => _onSliderChange(cardBlur: v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSliderTile(
                      label: Translations.get('card_opacity_label', logic.lang),
                      value: _tempCardOpacity,
                      min: 0.05,
                      max: 1.0,
                      isPercent: true,
                      colors: colors,
                      labelWidth: 105,
                      onChanged: (v) => _onSliderChange(cardOpacity: v),
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
                      value: _tempDialogBlur,
                      min: 0,
                      max: 40,
                      colors: colors,
                      labelWidth: 105,
                      onChanged: (v) => _onSliderChange(dialogBlur: v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSliderTile(
                      label: Translations.get('dialog_opacity', logic.lang),
                      value: _tempDialogOpacity,
                      min: 0.1,
                      max: 1.0,
                      isPercent: true,
                      colors: colors,
                      labelWidth: 105,
                      onChanged: (v) => _onSliderChange(dialogOpacity: v),
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
                      label: Translations.get(
                        'dropdown_blur_label',
                        logic.lang,
                      ),
                      value: _tempDropdownBlur,
                      min: 0,
                      max: 40,
                      colors: colors,
                      labelWidth: 105,
                      onChanged: (v) => _onSliderChange(dropdownBlur: v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSliderTile(
                      label: Translations.get(
                        'dropdown_opacity_label',
                        logic.lang,
                      ),
                      value: _tempDropdownOpacity,
                      min: 0.1,
                      max: 1.0,
                      isPercent: true,
                      colors: colors,
                      labelWidth: 105,
                      onChanged: (v) => _onSliderChange(dropdownOpacity: v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 4. Idle Power Saving Mode (Sleep Mode) BentoCard
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
                        Icons.energy_savings_leaf_rounded,
                        size: 18,
                        color: colors.accentEmerald,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Translations.get('idle_sleep_title', logic.lang),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Transform.scale(
                    scale: 0.85,
                    child: Switch(
                      value: _tempEnableIdleSleep,
                      activeThumbColor: colors.accentEmerald,
                      activeTrackColor: colors.accentEmerald.withValues(
                        alpha: 0.35,
                      ),
                      inactiveThumbColor: colors.textSecondary.withValues(
                        alpha: 0.7,
                      ),
                      inactiveTrackColor: colors.subCardBg,
                      onChanged: (val) {
                        _rebuild(() => _tempEnableIdleSleep = val);
                        AppPowerManager.instance.setEnableIdleSleep(val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                Translations.get('idle_sleep_desc', logic.lang),
                style: TextStyle(
                  fontSize: 11.5,
                  color: colors.textSecondary,
                  height: 1.3,
                ),
              ),
              if (_tempEnableIdleSleep) ...[
                const SizedBox(height: 12),
                Divider(color: colors.borderDefault, height: 1),
                const SizedBox(height: 12),
                Text(
                  Translations.get('idle_timeout_label', logic.lang),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildIdleTimeoutChoice(
                      label: Translations.get('idle_12s', logic.lang),
                      icon: Icons.timer_outlined,
                      value: 12,
                      currentValue: _tempIdleTimeoutSeconds,
                      colors: colors,
                      onSelect: () => _selectIdleTimeout(12),
                    ),
                    const SizedBox(width: 8),
                    _buildIdleTimeoutChoice(
                      label: Translations.get('idle_30s', logic.lang),
                      icon: Icons.timer_outlined,
                      value: 30,
                      currentValue: _tempIdleTimeoutSeconds,
                      colors: colors,
                      onSelect: () => _selectIdleTimeout(30),
                    ),
                    const SizedBox(width: 8),
                    _buildIdleTimeoutChoice(
                      label: Translations.get('idle_60s', logic.lang),
                      icon: Icons.timer_outlined,
                      value: 60,
                      currentValue: _tempIdleTimeoutSeconds,
                      colors: colors,
                      onSelect: () => _selectIdleTimeout(60),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _selectIdleTimeout(int seconds) {
    _rebuild(() => _tempIdleTimeoutSeconds = seconds);
    AppPowerManager.instance.setIdleTimeout(Duration(seconds: seconds));
  }
}

Widget _buildIdleTimeoutChoice({
  required String label,
  required IconData icon,
  required int value,
  required int currentValue,
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
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ),
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
