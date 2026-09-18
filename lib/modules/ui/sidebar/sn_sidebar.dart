import 'package:flutter/material.dart';
import '../../logic.dart';
import '../../translations.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/glass_widgets.dart';

enum SnFilterType { all, pass, fail, noData }

class SnSidebar extends StatefulWidget {
  final AppLogic logic;
  final ThemeProvider theme;

  const SnSidebar({super.key, required this.logic, required this.theme});

  @override
  State<SnSidebar> createState() => _SnSidebarState();
}

class _SnSidebarState extends State<SnSidebar> {
  final TextEditingController _inputCtrl = TextEditingController();
  SnFilterType _activeFilter = SnFilterType.all;

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  void _submitInput() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    final isTraceMode = widget.logic.viewMode == ViewMode.componentTrace;
    if (isTraceMode) {
      widget.logic.addTraceCsns(text);
    } else {
      widget.logic.addSns(text);
    }
    _inputCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.theme.colors;
    final logic = widget.logic;
    final lang = logic.lang;
    final isTraceMode = logic.viewMode == ViewMode.componentTrace;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBg.withValues(alpha: widget.theme.cardOpacity),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderDefault),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Input Field
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        controller: _inputCtrl,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: isTraceMode
                              ? Translations.get('component_trace_hint', lang)
                              : Translations.get('enter_sn', lang),
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary.withValues(alpha: 0.7),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          filled: true,
                          fillColor: colors.subCardBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: colors.subCardBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: colors.subCardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: colors.accentColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _submitInput(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GlowingActionButton(
                    height: 38,
                    colors: colors,
                    icon: Icons.add_rounded,
                    label: '',
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    onPressed: _submitInput,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 2. Quick Action Toolbar (Import CSV, Refresh All, Clear All, Template)
              Row(
                children: [
                  _buildToolbarButton(
                    icon: Icons.file_upload_outlined,
                    label: Translations.get('import', lang),
                    colors: colors,
                    onTap: isTraceMode ? logic.importTraceCsv : logic.importCsv,
                  ),
                  const SizedBox(width: 6),
                  _buildToolbarButton(
                    icon: Icons.refresh_rounded,
                    label: Translations.get('refresh_all', lang),
                    colors: colors,
                    onTap: isTraceMode
                        ? logic.refetchTraceHistory
                        : logic.refetchAllSns,
                  ),
                  const SizedBox(width: 6),
                  _buildToolbarButton(
                    icon: Icons.delete_sweep_outlined,
                    label: Translations.get('clear_all', lang),
                    colors: colors,
                    onTap: isTraceMode
                        ? logic.clearTraceHistory
                        : logic.clearAllSns,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 3. Smart Stats Summary Pills (Only in SN mode)
              if (!isTraceMode) ...[
                _buildStatsSummary(logic, colors, lang),
                const SizedBox(height: 10),

                // 4. Quick Filter Pills (All / Pass / Fail / No Data)
                _buildFilterChips(colors, lang),
                const SizedBox(height: 10),
              ],

              // Header of Queue
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isTraceMode
                          ? Translations.get('trace_history', lang)
                          : Translations.get('mes_queue', lang),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.textSecondary,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      isTraceMode
                          ? '${logic.traceHistory.length}'
                          : '${logic.snList.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.accentCyan,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Divider(color: colors.borderDefault, height: 1),
              const SizedBox(height: 6),

              // 5. SN or Trace History List
              Expanded(
                child: isTraceMode
                    ? _buildTraceHistoryList(logic, colors, lang)
                    : _buildSnList(logic, colors, lang),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required AppColors colors,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: colors.subCardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.subCardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: colors.textSecondary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSummary(AppLogic logic, AppColors colors, String lang) {
    int total = logic.snList.length;
    int pass = 0;
    int fail = 0;
    int pending = 0;

    for (final sn in logic.snList) {
      final records = logic.results[sn];
      final error = logic.errors[sn];
      final isLoading = logic.loadingStatus[sn] == true;

      if (isLoading) {
        pending++;
      } else if (records != null && records.isNotEmpty) {
        final lastResult = records.first.testResult.toUpperCase();
        if (lastResult == 'PASS') {
          pass++;
        } else {
          fail++;
        }
      } else if (error != null) {
        fail++;
      } else {
        pending++;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.subCardBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.subCardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatPill('Total', '$total', colors.accentCyan),
          _buildStatPill('Pass', '$pass', colors.accentEmerald),
          _buildStatPill('Fail', '$fail', colors.accentRose),
          _buildStatPill('Wait', '$pending', colors.accentAmber),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips(AppColors colors, String lang) {
    return Row(
      children: [
        _buildFilterItem(
          SnFilterType.all,
          Translations.get('filter_all', lang),
          colors,
        ),
        const SizedBox(width: 4),
        _buildFilterItem(
          SnFilterType.pass,
          Translations.get('filter_pass', lang),
          colors,
        ),
        const SizedBox(width: 4),
        _buildFilterItem(
          SnFilterType.fail,
          Translations.get('filter_fail', lang),
          colors,
        ),
        const SizedBox(width: 4),
        _buildFilterItem(
          SnFilterType.noData,
          Translations.get('filter_nodata', lang),
          colors,
        ),
      ],
    );
  }

  Widget _buildFilterItem(SnFilterType filter, String label, AppColors colors) {
    final isSelected = _activeFilter == filter;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeFilter = filter),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.accentColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? colors.accentColor : colors.borderDefault,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? colors.accentColor : colors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildSnList(AppLogic logic, AppColors colors, String lang) {
    if (logic.snList.isEmpty) {
      return Center(
        child: Text(
          Translations.get('no_sns_in_queue', lang),
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
      );
    }

    final filteredSns = logic.snList.where((sn) {
      if (_activeFilter == SnFilterType.all) return true;
      final records = logic.results[sn];
      final error = logic.errors[sn];
      final hasRecords = records != null && records.isNotEmpty;

      if (_activeFilter == SnFilterType.pass) {
        return hasRecords && records.first.testResult.toUpperCase() == 'PASS';
      }
      if (_activeFilter == SnFilterType.fail) {
        if (hasRecords && records.first.testResult.toUpperCase() != 'PASS') {
          return true;
        }
        if (error != null) return true;
        return false;
      }
      if (_activeFilter == SnFilterType.noData) {
        return (!hasRecords &&
            error == null &&
            logic.loadingStatus[sn] != true);
      }
      return true;
    }).toList();

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: filteredSns.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final sn = filteredSns[index];
        final isSelected = sn == logic.selectedSn;
        final records = logic.results[sn];
        final error = logic.errors[sn];
        final isLoading = logic.loadingStatus[sn] == true;
        final resolvedSn = logic.resolvedSnFor(sn);
        final masterInfo = logic.snMasterInfo[sn];

        // Status color determination
        Color statusColor = colors.textSecondary;
        IconData statusIcon = Icons.help_outline_rounded;

        if (isLoading) {
          statusColor = colors.accentCyan;
          statusIcon = Icons.hourglass_top_rounded;
        } else if (error != null) {
          statusColor = colors.accentRose;
          statusIcon = Icons.error_outline_rounded;
        } else if (records != null && records.isNotEmpty) {
          final isPass = records.first.testResult.toUpperCase() == 'PASS';
          statusColor = isPass ? colors.accentEmerald : colors.accentRose;
          statusIcon = isPass
              ? Icons.check_circle_rounded
              : Icons.cancel_rounded;
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => logic.selectSn(sn),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.accentColor.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? colors.accentColor.withValues(alpha: 0.5)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sn,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? colors.textPrimary
                                : colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (resolvedSn != null && resolvedSn != sn) ...[
                          const SizedBox(height: 2),
                          Text(
                            '→ $resolvedSn',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: colors.accentCyan,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (masterInfo != null &&
                            (masterInfo.nextProcessName.isNotEmpty ||
                                masterInfo.nextProcessCode.isNotEmpty)) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Next: ${masterInfo.nextProcessName.isNotEmpty ? masterInfo.nextProcessName : masterInfo.nextProcessCode}',
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.accentPurple,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Actions: Refresh single SN & Delete
                  IconButton(
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 14,
                      color: colors.textSecondary,
                    ),
                    tooltip: Translations.get('refresh_sn', lang),
                    constraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 26,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () => logic.refetchSn(sn),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: colors.textSecondary,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () => logic.removeSn(sn),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTraceHistoryList(AppLogic logic, AppColors colors, String lang) {
    if (logic.traceHistory.isEmpty) {
      return Center(
        child: Text(
          Translations.get('no_trace_history', lang),
          style: TextStyle(fontSize: 12, color: colors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: logic.traceHistory.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final csn = logic.traceHistory[index];
        final isSelected = csn == logic.selectedTraceCsn;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => logic.selectTraceCsn(csn),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.accentColor.withValues(alpha: 0.14)
                    : colors.subCardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? colors.accentColor : colors.subCardBorder,
                  width: isSelected ? 1.4 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 14,
                    color: colors.accentCyan,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AsymmetricMarqueeText(
                      text: csn,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isSelected
                            ? colors.accentColor
                            : colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 14,
                      color: colors.textSecondary,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 26,
                      minHeight: 26,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () => logic.refetchTraceCsn(csn),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: colors.textSecondary,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () => logic.removeTraceCsn(csn),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
