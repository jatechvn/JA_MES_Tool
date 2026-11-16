part of '../main_window.dart';

extension _MainWindowTestRecordExt on _MainWindowState {
  Widget _buildTestRecordView(
    BuildContext context,
    AppLogic logic,
    ThemeProvider theme,
    AppColors colors,
  ) {
    final sn = logic.selectedSn;
    final isLoading = logic.loadingStatus[sn] == true;
    final error = logic.errors[sn];
    final records = logic.results[sn];

    if (isLoading) {
      return Center(
        child: BorderBeam(
          borderRadius: 16,
          child: BentoCard(
            colors: colors,
            blurSigma: logic.bgBlur,
            bgOpacity: logic.bgOpacity,
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: colors.accentCyan,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  '${Translations.get('status_fetching', logic.lang)} $sn...',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: BentoCard(
          colors: colors,
          blurSigma: logic.bgBlur,
          bgOpacity: logic.bgOpacity,
          borderRadius: 14,
          padding: const EdgeInsets.all(20),
          customBg: colors.accentRose.withValues(alpha: 0.12),
          customBorder: colors.accentRose.withValues(alpha: 0.35),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: colors.accentRose,
                size: 22,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  '${Translations.get('error_for', logic.lang)} $sn: $error',
                  style: TextStyle(
                    color: colors.accentRose,
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
          blurSigma: logic.bgBlur,
          bgOpacity: logic.bgOpacity,
          borderRadius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Text(
            '${Translations.get('no_records', logic.lang)} $sn',
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
      );
    }

    final displayRecords = _filterSortTestRecords(
      records,
      _testRecordListState,
    );

    final passCount = records
        .where((r) => r.testResult.toUpperCase() == 'PASS')
        .length;
    final failCount = records.length - passCount;
    final kpiRecord = records
        .where((r) => (r.qty ?? 0) > 0 || r.fpy != null || r.lpy != null)
        .firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRecordsHeader(
          sn: sn,
          count: records.length,
          theme: theme,
          colors: colors,
          lang: logic.lang,
          resolvedSn: logic.resolvedSnFor(sn),
          snMasterInfo: logic.snMasterInfo[sn],
          kpiRecord: kpiRecord,
          listState: _testRecordListState,
          passCount: passCount,
          failCount: failCount,
          sortOptions: [
            _SortOption(
              'test_date',
              Translations.get('test_date', logic.lang),
              icon: Icons.event_rounded,
            ),
            _SortOption(
              'station',
              Translations.get('station', logic.lang),
              icon: Icons.dns_rounded,
            ),
            _SortOption(
              'result',
              Translations.get('result', logic.lang),
              icon: Icons.fact_check_rounded,
            ),
            _SortOption(
              'product_no',
              Translations.get('product_no', logic.lang),
              icon: Icons.inventory_2_rounded,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (displayRecords.isEmpty)
          Expanded(
            child: Center(
              child: BentoCard(
                colors: colors,
                blurSigma: logic.bgBlur,
                bgOpacity: logic.bgOpacity,
                borderRadius: 14,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Text(
                  Translations.get('no_matches', logic.lang),
                  style: TextStyle(color: colors.textSecondary),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: displayRecords.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final record = displayRecords[index];
                final isPass = record.testResult.toUpperCase() == 'PASS';

                return _StaggeredItem(
                  itemKey:
                      'test_rec_${record.stationId}_${record.testDate}_${record.testTime}_$index',
                  index: index,
                  animatedKeys: _testRecordListState.animatedItemKeys,
                  child: BentoCard(
                    colors: colors,
                    blurSigma: logic.bgBlur,
                    bgOpacity: logic.bgOpacity,
                    padding: const EdgeInsets.all(12),
                    borderRadius: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: colors.accentCyan.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: colors.accentCyan.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.dns_rounded,
                                          color: colors.accentCyan,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '${Translations.get('station', logic.lang)}: ${record.stationId}',
                                        style: TextStyle(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (record.processCode.isNotEmpty)
                                    PillBadge(
                                      label: record.processCode,
                                      color: colors.accentCyan,
                                      bg: colors.accentCyan.withValues(
                                        alpha: 0.12,
                                      ),
                                      border: colors.accentCyan.withValues(
                                        alpha: 0.35,
                                      ),
                                      fontSize: 10,
                                    ),
                                  if (record.testNo.isNotEmpty)
                                    PillBadge(
                                      label: '#${record.testNo}',
                                      color: colors.accentPurple,
                                      bg: colors.accentPurple.withValues(
                                        alpha: 0.12,
                                      ),
                                      border: colors.accentPurple.withValues(
                                        alpha: 0.35,
                                      ),
                                      fontSize: 10,
                                    ),
                                  if (record.timeDifferenceValue.isNotEmpty)
                                    PillBadge(
                                      label: '⏱ ${record.timeDifferenceValue}',
                                      color: colors.accentAmber,
                                      bg: colors.accentAmber.withValues(
                                        alpha: 0.12,
                                      ),
                                      border: colors.accentAmber.withValues(
                                        alpha: 0.35,
                                      ),
                                      fontSize: 10,
                                    ),
                                  if (record.testDate.isNotEmpty)
                                    Text(
                                      record.testDate,
                                      style: TextStyle(
                                        color: colors.textMuted,
                                        fontSize: 11.5,
                                        fontFamily: 'JetBrains Mono',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            PillBadge(
                              label: record.testResult.toUpperCase(),
                              color: isPass
                                  ? colors.accentEmerald
                                  : colors.accentRose,
                              bg: isPass
                                  ? colors.accentEmerald.withValues(alpha: 0.12)
                                  : colors.accentRose.withValues(alpha: 0.12),
                              border: isPass
                                  ? colors.accentEmerald.withValues(alpha: 0.4)
                                  : colors.accentRose.withValues(alpha: 0.4),
                              showDot: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Divider(color: colors.borderDefault, height: 1),
                        const SizedBox(height: 8),

                        // Details Grid (2 Columns: Compact & Space-optimized)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Column 1: Product, Order & Execution Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(
                                    Translations.get('product_no', logic.lang),
                                    record.productNo,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get('work_order', logic.lang),
                                    record.woNo,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get(
                                      'product_series',
                                      logic.lang,
                                    ),
                                    record.productSeries,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get('emp_no', logic.lang),
                                    record.empNo,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get('test_time', logic.lang),
                                    record.testTime,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get(
                                      'test_start_time',
                                      logic.lang,
                                    ),
                                    record.testStartDate,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get(
                                      'test_end_time',
                                      logic.lang,
                                    ),
                                    record.testEndDate,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get(
                                      'test_duration',
                                      logic.lang,
                                    ),
                                    record.timeDifferenceValue,
                                    colors,
                                    highlight:
                                        record.timeDifferenceValue.isNotEmpty,
                                  ),
                                  _buildInfoRow(
                                    Translations.get('mb_sn', logic.lang),
                                    record.mbSn,
                                    colors,
                                    highlight: record.mbSn.isNotEmpty,
                                  ),
                                  _buildInfoRow(
                                    Translations.get('mac_group', logic.lang),
                                    record.macGroup,
                                    colors,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Column 2: Process, Station & Host Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(
                                    Translations.get(
                                      'process_code',
                                      logic.lang,
                                    ),
                                    record.processCode,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get(
                                      'line_station_code',
                                      logic.lang,
                                    ),
                                    record.lineStationCode,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get('test_host', logic.lang),
                                    record.loc,
                                    colors,
                                    highlight: true,
                                  ),
                                  _buildInfoRow(
                                    Translations.get('internal_sn', logic.lang),
                                    record.internalSn,
                                    colors,
                                    highlight: true,
                                  ),
                                  _buildInfoRow(
                                    Translations.get('customer_sn', logic.lang),
                                    record.customerSn,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get('test_date', logic.lang),
                                    record.testDate,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get('test_no', logic.lang),
                                    record.testNo,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get(
                                      'collecting_data',
                                      logic.lang,
                                    ),
                                    record.collectingData,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get(
                                      'components_info',
                                      logic.lang,
                                    ),
                                    record.components,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get(
                                      'git_asn_data',
                                      logic.lang,
                                    ),
                                    record.gitAsnData,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get('eqp_params', logic.lang),
                                    record.eqpParams,
                                    colors,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (record.zipFileName.isNotEmpty ||
                            record.testLogPath.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colors.accentCyan.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colors.accentCyan.withValues(
                                  alpha: 0.22,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.folder_zip_outlined,
                                  size: 15,
                                  color: colors.accentCyan,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: SelectableText(
                                    record.testLogPath.isNotEmpty
                                        ? (record.zipFileName.isNotEmpty &&
                                                  !record.testLogPath.contains(
                                                    record.zipFileName,
                                                  )
                                              ? '${record.testLogPath} (${record.zipFileName})'
                                              : record.testLogPath)
                                        : record.zipFileName,
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 11.5,
                                      fontFamily: 'JetBrains Mono',
                                    ),
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () => Clipboard.setData(
                                    ClipboardData(
                                      text: record.testLogPath.isNotEmpty
                                          ? record.testLogPath
                                          : record.zipFileName,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: Icon(
                                      Icons.folder_copy_outlined,
                                      size: 14,
                                      color: colors.accentCyan,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        if (!isPass ||
                            record.testItemFailStep.isNotEmpty ||
                            record.testMajorItem.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colors.accentRose.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colors.accentRose.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (record.errCode.isNotEmpty)
                                  _buildInfoRow(
                                    Translations.get('error_code', logic.lang),
                                    record.errCode,
                                    colors,
                                  ),
                                if (record.testItemFailStep.isNotEmpty)
                                  _buildInfoRow(
                                    Translations.get('fail_step', logic.lang),
                                    record.testItemFailStep,
                                    colors,
                                  ),
                                if (record.testItemFailCycle.isNotEmpty)
                                  _buildInfoRow(
                                    Translations.get('fail_cycle', logic.lang),
                                    record.testItemFailCycle,
                                    colors,
                                  ),
                                if (record.testMajorItem.isNotEmpty)
                                  _buildInfoRow(
                                    Translations.get('major_item', logic.lang),
                                    record.testMajorItem,
                                    colors,
                                  ),
                                if (record.failureReason.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      '${Translations.get('failure_reason', logic.lang)}: ${record.failureReason}',
                                      style: TextStyle(
                                        color: colors.accentRose,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                if (record.failDesc.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Text(
                                      '${Translations.get('fail_desc', logic.lang)}: ${record.failDesc}',
                                      style: TextStyle(
                                        color: colors.accentRose,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  List<TestRecord> _filterSortTestRecords(
    List<TestRecord> records,
    _ListViewState listState,
  ) {
    var result = records;
    final q = listState.filter.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result
          .where(
            (r) => [
              r.stationId,
              r.productNo,
              r.internalSn,
              r.customerSn,
              r.processCode,
              r.lineStationCode,
              r.loc,
              r.productSeries,
              r.woNo,
              r.testDate,
              r.testStartDate,
              r.testEndDate,
              r.timeDifferenceValue,
              r.testResult,
              r.testNo,
              r.empNo,
              r.errCode,
              r.failureReason,
              r.failDesc,
              r.testItemFailStep,
              r.testItemFailCycle,
              r.testMajorItem,
              r.mbSn,
              r.macGroup,
              r.collectingData,
              r.components,
              r.gitAsnData,
              r.eqpParams,
              r.testLogPath,
              r.zipFileName,
            ].any((f) => f.toLowerCase().contains(q)),
          )
          .toList();
    } else {
      result = List<TestRecord>.from(result);
    }
    final field = listState.sortField;
    if (field != null) {
      result.sort((a, b) {
        int cmp;
        switch (field) {
          case 'test_date':
            cmp = a.testDate.compareTo(b.testDate);
            break;
          case 'station':
            cmp = a.stationId.compareTo(b.stationId);
            break;
          case 'result':
            cmp = a.testResult.compareTo(b.testResult);
            break;
          case 'product_no':
            cmp = a.productNo.compareTo(b.productNo);
            break;
          default:
            cmp = 0;
        }
        return listState.sortAsc ? cmp : -cmp;
      });
    }
    return result;
  }
}
