part of '../main_window.dart';

extension _MainWindowBarcodeHistoryExt on _MainWindowState {
  Widget _buildBarcodeHistoryView(
    BuildContext context,
    AppLogic logic,
    ThemeProvider theme,
    AppColors colors,
  ) {
    final sn = logic.selectedSn;
    final isLoading = logic.processLoadingStatus[sn] == true;
    final error = logic.processErrors[sn];
    final records = logic.processResults[sn];

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
          child: Text(
            '${Translations.get('error_for', logic.lang)} $sn: $error',
            style: TextStyle(
              color: colors.accentRose,
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

    final displayRecords = _filterSortBarcodeRecords(
      records,
      _barcodeListState,
    );

    final passCount = records
        .where(
          (r) =>
              r.result.toLowerCase() == 'pass' ||
              (r.result.isEmpty && r.errorCode.isEmpty),
        )
        .length;
    final failCount = records.length - passCount;

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
          listState: _barcodeListState,
          passCount: passCount,
          failCount: failCount,
          sortOptions: [
            _SortOption(
              'process_time',
              Translations.get('process_time', logic.lang),
              icon: Icons.schedule_rounded,
            ),
            _SortOption(
              'process_name',
              Translations.get('process_name', logic.lang),
              icon: Icons.list_alt_rounded,
            ),
            _SortOption(
              'result',
              Translations.get('result', logic.lang),
              icon: Icons.fact_check_rounded,
            ),
            _SortOption(
              'line_station',
              Translations.get('line_station_code', logic.lang),
              icon: Icons.alt_route_rounded,
            ),
            _SortOption(
              'line',
              Translations.get('line', logic.lang),
              icon: Icons.linear_scale_rounded,
            ),
            _SortOption(
              'internal_sn',
              Translations.get('internal_sn', logic.lang),
              icon: Icons.badge_outlined,
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
              separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final record = displayRecords[index];
                final isPass = record.result.toLowerCase() == 'pass';
                final itemKey =
                    '${record.currentProcessCode}_${record.operateDt}_${record.lineStation}_$index';

                return _StaggeredItem(
                  key: ValueKey(itemKey),
                  itemKey: itemKey,
                  animatedKeys: _barcodeListState.animatedItemKeys,
                  index: index,
                  child: BentoCard(
                    colors: colors,
                    blurSigma: logic.bgBlur,
                    bgOpacity: logic.bgOpacity,
                    padding: const EdgeInsets.all(12),
                    borderRadius: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                          color: colors.accentPurple.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: colors.accentPurple
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.route_rounded,
                                          color: colors.accentPurple,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        record.currentProcessName.isNotEmpty
                                            ? record.currentProcessName
                                            : record.currentProcessCode,
                                        style: TextStyle(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (record.lineStation.isNotEmpty)
                                    PillBadge(
                                      label: record.lineStation,
                                      color: colors.accentAmber,
                                      bg: colors.accentAmber.withValues(
                                        alpha: 0.12,
                                      ),
                                      border: colors.accentAmber.withValues(
                                        alpha: 0.35,
                                      ),
                                      fontSize: 10,
                                    ),
                                  if (record.lineName.isNotEmpty ||
                                      record.lineCode.isNotEmpty)
                                    PillBadge(
                                      label: record.lineName.isNotEmpty
                                          ? record.lineName
                                          : record.lineCode,
                                      color: colors.accentCyan,
                                      bg: colors.accentCyan.withValues(
                                        alpha: 0.12,
                                      ),
                                      border: colors.accentCyan.withValues(
                                        alpha: 0.35,
                                      ),
                                      fontSize: 10,
                                    ),
                                  if (record.productVersion.isNotEmpty)
                                    PillBadge(
                                      label: 'v${record.productVersion}',
                                      color: colors.accentPurple,
                                      bg: colors.accentPurple.withValues(
                                        alpha: 0.12,
                                      ),
                                      border: colors.accentPurple.withValues(
                                        alpha: 0.35,
                                      ),
                                      fontSize: 10,
                                    ),
                                  if (record.operateDt.isNotEmpty)
                                    Text(
                                      record.operateDt,
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
                            if (record.result.isNotEmpty)
                              PillBadge(
                                label: record.result.toUpperCase(),
                                color: isPass
                                    ? colors.accentEmerald
                                    : colors.accentRose,
                                bg: isPass
                                    ? colors.accentEmerald.withValues(
                                        alpha: 0.12,
                                      )
                                    : colors.accentRose.withValues(alpha: 0.12),
                                border: isPass
                                    ? colors.accentEmerald.withValues(
                                        alpha: 0.4,
                                      )
                                    : colors.accentRose.withValues(alpha: 0.4),
                                showDot: true,
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Divider(color: colors.borderDefault, height: 1),
                        const SizedBox(height: 8),

                        // Details Grid (2 Columns)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(
                                    Translations.get('line', logic.lang),
                                    record.lineName.isNotEmpty
                                        ? record.lineName
                                        : record.lineCode,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get(
                                      'line_station_code',
                                      logic.lang,
                                    ),
                                    record.lineStation,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get(
                                      'equipment_no',
                                      logic.lang,
                                    ),
                                    record.eqpId,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get('operator', logic.lang),
                                    record.operatorName,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get(
                                      'process_time',
                                      logic.lang,
                                    ),
                                    record.operateDt,
                                    colors,
                                    highlight: true,
                                  ),
                                  if (record.landMarkCodes.isNotEmpty)
                                    _buildInfoRow(
                                      Translations.get(
                                        'landmark_codes',
                                        logic.lang,
                                      ),
                                      record.landMarkCodes,
                                      colors,
                                      highlight: true,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow(
                                    Translations.get('internal_sn', logic.lang),
                                    record.internalSn,
                                    colors,
                                    highlight: record.internalSn.isNotEmpty,
                                  ),
                                  _buildInfoRow(
                                    Translations.get('customer_sn', logic.lang),
                                    record.customerSn,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get('product_no', logic.lang),
                                    record.productNo,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get('version', logic.lang),
                                    record.productVersion,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get('work_order', logic.lang),
                                    record.woNo,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get('plan_no', logic.lang),
                                    record.planNo,
                                    colors,
                                  ),
                                  if (record.errorCode.isNotEmpty)
                                    _buildInfoRow(
                                      Translations.get(
                                        'error_code',
                                        logic.lang,
                                      ),
                                      record.errorCode,
                                      colors,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (record.remark.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colors.accentAmber.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: colors.accentAmber.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: colors.accentAmber,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${Translations.get('remark', logic.lang)}: ',
                                  style: TextStyle(
                                    color: colors.accentAmber,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Expanded(
                                  child: SelectableText(
                                    record.remark,
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (record.testResultMsg.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colors.accentRose.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: colors.accentRose.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  size: 14,
                                  color: colors.accentRose,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${Translations.get('failure_reason', logic.lang)}: ',
                                  style: TextStyle(
                                    color: colors.accentRose,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Expanded(
                                  child: SelectableText(
                                    record.testResultMsg,
                                    style: TextStyle(
                                      color: colors.accentRose,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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

  List<SnProcessRecord> _filterSortBarcodeRecords(
    List<SnProcessRecord> records,
    _BarcodeListViewState listState,
  ) {
    var result = records;
    final q = listState.filter.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result
          .where(
            (r) => [
              r.currentProcessCode,
              r.currentProcessName,
              r.lineStation,
              r.lineName,
              r.lineCode,
              r.woNo,
              r.planNo,
              r.productNo,
              r.productVersion,
              r.customerSn,
              r.internalSn,
              r.operatorName,
              r.eqpId,
              r.errorCode,
              r.testResultMsg,
              r.remark,
              r.operateDt,
              r.result,
              r.landMarkCodes,
            ].any((f) => f.toLowerCase().contains(q)),
          )
          .toList();
    } else {
      result = List<SnProcessRecord>.from(result);
    }
    final field = listState.sortField;
    if (field != null) {
      result.sort((a, b) {
        int cmp;
        switch (field) {
          case 'process_time':
            cmp = a.operateDt.compareTo(b.operateDt);
            break;
          case 'process_name':
            cmp =
                (a.currentProcessName.isNotEmpty
                        ? a.currentProcessName
                        : a.currentProcessCode)
                    .compareTo(
                      b.currentProcessName.isNotEmpty
                          ? b.currentProcessName
                          : b.currentProcessCode,
                    );
            break;
          case 'result':
            cmp = a.result.compareTo(b.result);
            break;
          case 'line_station':
            cmp = a.lineStation.compareTo(b.lineStation);
            break;
          case 'line':
            final aLine = a.lineName.isNotEmpty ? a.lineName : a.lineCode;
            final bLine = b.lineName.isNotEmpty ? b.lineName : b.lineCode;
            cmp = aLine.compareTo(bLine);
            break;
          case 'internal_sn':
            cmp = a.internalSn.compareTo(b.internalSn);
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
