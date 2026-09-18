import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../logic.dart';
import '../../translations.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/glass_widgets.dart';

class BarcodeHistoryView extends StatefulWidget {
  final AppLogic logic;
  final ThemeProvider theme;

  const BarcodeHistoryView({
    super.key,
    required this.logic,
    required this.theme,
  });

  @override
  State<BarcodeHistoryView> createState() => _BarcodeHistoryViewState();
}

class _BarcodeHistoryViewState extends State<BarcodeHistoryView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _sortField = 'process_time';
  bool _sortAsc = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logic = widget.logic;
    final theme = widget.theme;
    final colors = theme.colors;
    final lang = logic.lang;
    final sn = logic.selectedSn;

    if (sn.isEmpty) {
      return Center(
        child: Text(
          Translations.get('select_sn', lang),
          style: TextStyle(fontSize: 13, color: colors.textSecondary),
        ),
      );
    }

    final isLoading = logic.processLoadingStatus[sn] == true;
    final error = logic.processErrors[sn];
    final records = logic.processResults[sn];

    if (isLoading) {
      return Center(
        child: BentoCard(
          colors: colors,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          borderRadius: 14,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: colors.accentCyan,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${Translations.get('status_fetching', lang)} $sn...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: BentoCard(
          colors: colors,
          padding: const EdgeInsets.all(18),
          borderRadius: 14,
          customBg: colors.accentRose.withValues(alpha: 0.1),
          customBorder: colors.accentRose.withValues(alpha: 0.35),
          child: Text(
            '${Translations.get('error_for', lang)} $sn: $error',
            style: TextStyle(
              color: colors.accentRose,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (records == null || records.isEmpty) {
      return Center(
        child: BentoCard(
          colors: colors,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          borderRadius: 14,
          child: Text(
            '${Translations.get('no_records', lang)} $sn',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ),
      );
    }

    final displayRecords = _filterAndSort(records);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Header Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colors.cardBg.withValues(alpha: theme.cardOpacity),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.borderDefault),
          ),
          child: Row(
            children: [
              PillBadge(
                label: '${records.length} Steps',
                color: colors.accentPurple,
                bg: colors.accentPurple.withValues(alpha: 0.12),
                border: colors.accentPurple.withValues(alpha: 0.35),
                icon: Icons.timeline_rounded,
              ),
              const Spacer(),

              // Search Box
              SizedBox(
                width: 180,
                height: 32,
                child: TextField(
                  controller: _searchCtrl,
                  style: TextStyle(fontSize: 12, color: colors.textPrimary),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: Translations.get('search_placeholder', lang),
                    hintStyle: TextStyle(
                      fontSize: 11.5,
                      color: colors.textSecondary.withValues(alpha: 0.7),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 15,
                      color: colors.textSecondary,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : InkWell(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 13,
                              color: colors.textSecondary,
                            ),
                          ),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
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
                      borderSide: BorderSide(color: colors.accentColor),
                    ),
                  ),
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.trim().toLowerCase()),
                ),
              ),
              const SizedBox(width: 8),

              // Sort Dropdown
              SizedBox(
                width: 140,
                height: 32,
                child: GlassDropdown<String>(
                  colors: colors,
                  value: _sortField,
                  hintText: Translations.get('sort', lang),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  borderRadius: 8,
                  onChanged: (val) {
                    setState(() {
                      if (_sortField == val) {
                        _sortAsc = !_sortAsc;
                      } else {
                        _sortField = val;
                        _sortAsc = true;
                      }
                    });
                  },
                  items: [
                    GlassDropdownItem(
                      value: 'process_time',
                      label: Translations.get('process_time', lang),
                      icon: Icons.schedule_rounded,
                    ),
                    GlassDropdownItem(
                      value: 'process_name',
                      label: Translations.get('process_name', lang),
                      icon: Icons.list_alt_rounded,
                    ),
                    GlassDropdownItem(
                      value: 'result',
                      label: Translations.get('result', lang),
                      icon: Icons.fact_check_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Export CSV Button
              GlowingActionButton(
                height: 32,
                colors: colors,
                icon: Icons.file_download_outlined,
                label: Translations.get('export', lang),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                onPressed: () => logic.exportBarcodeHistoryCsv(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 2. Timeline List
        Expanded(
          child: displayRecords.isEmpty
              ? Center(
                  child: Text(
                    Translations.get('no_matches', lang),
                    style: TextStyle(fontSize: 13, color: colors.textSecondary),
                  ),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: displayRecords.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final record = displayRecords[index];
                    final isPass = record.result.toLowerCase() == 'pass';

                    return BentoCard(
                      colors: colors,
                      padding: const EdgeInsets.all(14),
                      borderRadius: 12,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: colors.accentPurple.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: colors.accentPurple.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.route_rounded,
                                      color: colors.accentPurple,
                                      size: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    record.currentProcessName.isNotEmpty
                                        ? record.currentProcessName
                                        : record.currentProcessCode,
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                              if (record.result.isNotEmpty)
                                PillBadge(
                                  label: record.result.toUpperCase(),
                                  color: isPass
                                      ? colors.accentEmerald
                                      : colors.accentRose,
                                  bg:
                                      (isPass
                                              ? colors.accentEmerald
                                              : colors.accentRose)
                                          .withValues(alpha: 0.12),
                                  border:
                                      (isPass
                                              ? colors.accentEmerald
                                              : colors.accentRose)
                                          .withValues(alpha: 0.35),
                                  showDot: true,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Divider(color: colors.borderDefault, height: 1),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  Translations.get('process_time', lang),
                                  record.operateDt,
                                  colors,
                                  isCyan: true,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  Translations.get('line_station_code', lang),
                                  record.lineStation,
                                  colors,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  Translations.get('work_order', lang),
                                  record.woNo,
                                  colors,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  Translations.get('operator', lang),
                                  record.operatorName,
                                  colors,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    String label,
    String value,
    AppColors colors, {
    bool isCyan = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: colors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '—' : value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isCyan ? colors.accentCyan : colors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  List<SnProcessRecord> _filterAndSort(List<SnProcessRecord> source) {
    var list = source;
    if (_searchQuery.isNotEmpty) {
      list = list.where((r) {
        return r.currentProcessCode.toLowerCase().contains(_searchQuery) ||
            r.currentProcessName.toLowerCase().contains(_searchQuery) ||
            r.lineStation.toLowerCase().contains(_searchQuery) ||
            r.result.toLowerCase().contains(_searchQuery) ||
            r.operatorName.toLowerCase().contains(_searchQuery) ||
            r.operateDt.toLowerCase().contains(_searchQuery);
      }).toList();
    } else {
      list = List<SnProcessRecord>.from(list);
    }

    list.sort((a, b) {
      int cmp = 0;
      switch (_sortField) {
        case 'process_time':
          cmp = a.operateDt.compareTo(b.operateDt);
          break;
        case 'process_name':
          cmp = a.currentProcessName.compareTo(b.currentProcessName);
          break;
        case 'result':
          cmp = a.result.compareTo(b.result);
          break;
        default:
          cmp = 0;
      }
      return _sortAsc ? cmp : -cmp;
    });

    return list;
  }
}
