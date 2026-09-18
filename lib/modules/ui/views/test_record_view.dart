import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../logic.dart';
import '../../translations.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/glass_widgets.dart';
import '../dialogs/sn_detail_dialog.dart';

class TestRecordView extends StatefulWidget {
  final AppLogic logic;
  final ThemeProvider theme;

  const TestRecordView({super.key, required this.logic, required this.theme});

  @override
  State<TestRecordView> createState() => _TestRecordViewState();
}

class _TestRecordViewState extends State<TestRecordView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _sortField = 'test_date';
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

    final isLoading = logic.loadingStatus[sn] == true;
    final error = logic.errors[sn];
    final records = logic.results[sn];

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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: colors.accentRose,
                size: 22,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  '${Translations.get('error_for', lang)} $sn: $error',
                  style: TextStyle(
                    color: colors.accentRose,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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

    // Filter and sort records
    final displayRecords = _filterAndSort(records);

    // Calculate smart stats
    int passCount = 0;
    for (final r in records) {
      if (r.testResult.toUpperCase() == 'PASS') passCount++;
    }
    final passRate = records.isNotEmpty
        ? (passCount / records.length * 100).toInt()
        : 0;
    final masterInfo = logic.snMasterInfo[sn];
    final routeLabel = masterInfo?.routeName.isNotEmpty == true
        ? masterInfo!.routeName
        : (masterInfo?.routeCode ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Smart Summary & Action Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colors.cardBg.withValues(alpha: theme.cardOpacity),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.borderDefault),
          ),
          child: Row(
            children: [
              // Pass Rate & Count Pills
              PillBadge(
                label: '$passCount/${records.length} PASS ($passRate%)',
                color: passRate >= 80
                    ? colors.accentEmerald
                    : colors.accentAmber,
                bg: (passRate >= 80 ? colors.accentEmerald : colors.accentAmber)
                    .withValues(alpha: 0.12),
                border:
                    (passRate >= 80 ? colors.accentEmerald : colors.accentAmber)
                        .withValues(alpha: 0.35),
                showDot: true,
              ),
              if (routeLabel.isNotEmpty) ...[
                const SizedBox(width: 8),
                PillBadge(
                  label: 'Route: $routeLabel',
                  color: colors.accentCyan,
                  bg: colors.accentCyan.withValues(alpha: 0.12),
                  border: colors.accentCyan.withValues(alpha: 0.35),
                  icon: Icons.alt_route_rounded,
                ),
              ],
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

              // GlassDropdown for Sorting
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
                      value: 'test_date',
                      label: Translations.get('test_date', lang),
                      icon: Icons.event_rounded,
                    ),
                    GlassDropdownItem(
                      value: 'station',
                      label: Translations.get('station', lang),
                      icon: Icons.dns_rounded,
                    ),
                    GlassDropdownItem(
                      value: 'result',
                      label: Translations.get('result', lang),
                      icon: Icons.check_circle_outline_rounded,
                    ),
                    GlassDropdownItem(
                      value: 'operator',
                      label: Translations.get('operator', lang),
                      icon: Icons.person_outline_rounded,
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
                onPressed: () => logic.exportCsv(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 2. Records List
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
                    final isPass = record.testResult.toUpperCase() == 'PASS';

                    return BentoCard(
                      colors: colors,
                      padding: const EdgeInsets.all(14),
                      borderRadius: 12,
                      onTap: () => showSnDetailDialog(
                        context,
                        record: record,
                        lang: lang,
                        theme: theme,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Header Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: colors.accentCyan.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: colors.accentCyan.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.dns_rounded,
                                      color: colors.accentCyan,
                                      size: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${Translations.get('station', lang)}: ${record.stationId}',
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ],
                              ),
                              PillBadge(
                                label: record.testResult.toUpperCase(),
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

                          // Details Grid Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  Translations.get('test_date', lang),
                                  '${record.testDate} ${record.testTime}',
                                  colors,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  Translations.get('internal_sn', lang),
                                  record.internalSn,
                                  colors,
                                  isCyan: true,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  Translations.get('test_host', lang),
                                  record.loc,
                                  colors,
                                ),
                              ),
                              Expanded(
                                child: _buildInfoItem(
                                  Translations.get('emp_no', lang),
                                  record.empNo,
                                  colors,
                                ),
                              ),
                            ],
                          ),
                          if (!isPass &&
                              (record.failureReason.isNotEmpty ||
                                  record.errCode.isNotEmpty)) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 14,
                                  color: colors.accentRose,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${record.errCode.isNotEmpty ? '[${record.errCode}] ' : ''}${record.failureReason}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: colors.accentRose,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
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

  List<TestRecord> _filterAndSort(List<TestRecord> source) {
    var list = source;
    if (_searchQuery.isNotEmpty) {
      list = list.where((r) {
        return r.stationId.toLowerCase().contains(_searchQuery) ||
            r.testResult.toLowerCase().contains(_searchQuery) ||
            r.internalSn.toLowerCase().contains(_searchQuery) ||
            r.loc.toLowerCase().contains(_searchQuery) ||
            r.empNo.toLowerCase().contains(_searchQuery) ||
            r.errCode.toLowerCase().contains(_searchQuery) ||
            r.failureReason.toLowerCase().contains(_searchQuery);
      }).toList();
    } else {
      list = List<TestRecord>.from(list);
    }

    list.sort((a, b) {
      int cmp = 0;
      switch (_sortField) {
        case 'test_date':
          cmp = '${a.testDate} ${a.testTime}'.compareTo(
            '${b.testDate} ${b.testTime}',
          );
          break;
        case 'station':
          cmp = a.stationId.compareTo(b.stationId);
          break;
        case 'result':
          cmp = a.testResult.compareTo(b.testResult);
          break;
        case 'operator':
          cmp = a.empNo.compareTo(b.empNo);
          break;
        default:
          cmp = 0;
      }
      return _sortAsc ? cmp : -cmp;
    });

    return list;
  }
}
