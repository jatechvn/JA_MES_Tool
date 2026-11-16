part of '../main_window.dart';

extension _MainWindowComponentTraceExt on _MainWindowState {
  Widget _buildComponentTraceView(
    BuildContext context,
    AppLogic logic,
    ThemeProvider theme,
    AppColors colors,
  ) {
    final selectedCsn = logic.selectedTraceCsn;
    final isLoading = logic.traceLoadingStatus[selectedCsn] == true;
    final error = logic.traceErrors[selectedCsn];
    final records = logic.traceResults[selectedCsn] ?? const [];
    final hasSearched = selectedCsn.isNotEmpty;

    if (!hasSearched) {
      return Center(
        child: BentoCard(
          colors: colors,
          blurSigma: logic.bgBlur,
          bgOpacity: logic.bgOpacity,
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.travel_explore_rounded,
                size: 38,
                color: colors.accentCyan,
              ),
              const SizedBox(height: 12),
              Text(
                Translations.get('trace_prompt', logic.lang),
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary, fontSize: 13.5),
              ),
            ],
          ),
        ),
      );
    }

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
                  '${Translations.get('status_fetching', logic.lang)} $selectedCsn...',
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
            '${Translations.get('no_trace_results', logic.lang)}: ${logic.selectedTraceCsn}',
            style: TextStyle(
              color: colors.accentRose,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    final displayRecords = _filterSortTraceRecords(records, _traceListState);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRecordsHeader(
          sn: logic.selectedTraceCsn,
          count: records.length,
          theme: theme,
          colors: colors,
          lang: logic.lang,
          listState: _traceListState,
          sortOptions: [
            _SortOption(
              'process_time',
              Translations.get('process_time', logic.lang),
              icon: Icons.schedule_rounded,
            ),
            _SortOption(
              'product_sn',
              Translations.get('product_sn', logic.lang),
              icon: Icons.qr_code_rounded,
            ),
            _SortOption(
              'material_no',
              Translations.get('material_no', logic.lang),
              icon: Icons.tag_rounded,
            ),
            _SortOption(
              'material_category',
              Translations.get('material_category', logic.lang),
              icon: Icons.category_rounded,
            ),
            _SortOption(
              'manufacturer',
              Translations.get('manufacturer', logic.lang),
              icon: Icons.factory_rounded,
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
                final itemKey =
                    '${record.productSn}_${record.scannedCsn}_${record.createdDt}_$index';

                return _StaggeredItem(
                  key: ValueKey(itemKey),
                  itemKey: itemKey,
                  animatedKeys: _traceListState.animatedItemKeys,
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
                                          Icons.devices_rounded,
                                          color: colors.accentCyan,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        record.productSn,
                                        style: TextStyle(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14.5,
                                          fontFamily: 'JetBrains Mono',
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (record.createdDt.isNotEmpty)
                                    Text(
                                      record.createdDt,
                                      style: TextStyle(
                                        color: colors.textMuted,
                                        fontSize: 11.5,
                                        fontFamily: 'JetBrains Mono',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (record.productSn.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(6),
                                      onTap: () =>
                                          logic.inspectProductSnFromTrace(
                                            record.productSn,
                                          ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.accentCyan.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: colors.accentCyan.withValues(
                                              alpha: 0.35,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.open_in_new_rounded,
                                              size: 12,
                                              color: colors.accentCyan,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              Translations.get(
                                                'inspect_product_sn',
                                                logic.lang,
                                              ),
                                              style: TextStyle(
                                                color: colors.accentCyan,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                if (record.checkAssembled.isNotEmpty)
                                  PillBadge(
                                    label: record.checkAssembled,
                                    color: colors.accentCyan,
                                    bg: colors.accentCyan.withValues(
                                      alpha: 0.12,
                                    ),
                                    border: colors.accentCyan.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                              ],
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
                                    Translations.get(
                                      'component_sn',
                                      logic.lang,
                                    ),
                                    record.scannedCsn,
                                    colors,
                                    highlight: true,
                                  ),
                                  if (record.parsedCsn.isNotEmpty &&
                                      record.parsedCsn != record.scannedCsn)
                                    _buildInfoRow(
                                      Translations.get(
                                        'parsed_csn',
                                        logic.lang,
                                      ),
                                      record.parsedCsn,
                                      colors,
                                      highlight: true,
                                    ),
                                  _buildInfoRow(
                                    Translations.get('mac_address', logic.lang),
                                    record.mac,
                                    colors,
                                    highlight: true,
                                  ),
                                  _buildInfoRow(
                                    Translations.get('material_no', logic.lang),
                                    record.materialNo,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get(
                                      'material_name',
                                      logic.lang,
                                    ),
                                    record.materialName,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get(
                                      'material_category',
                                      logic.lang,
                                    ),
                                    record.materialCategory,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get(
                                      'manufacturer',
                                      logic.lang,
                                    ),
                                    record.mfgName,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get('mfg_pn', logic.lang),
                                    record.mfgPn,
                                    colors,
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
                                    Translations.get('product_no', logic.lang),
                                    record.productNo,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get('line_code', logic.lang),
                                    record.lineCode,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get(
                                      'process_code',
                                      logic.lang,
                                    ),
                                    record.processCode,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get('work_order', logic.lang),
                                    record.woNo,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get('scan_type', logic.lang),
                                    record.scanType,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get(
                                      'material_version',
                                      logic.lang,
                                    ),
                                    record.materialVersion,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get(
                                      'customer_material_no',
                                      logic.lang,
                                    ),
                                    record.customerMaterialNo,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get('quantity', logic.lang),
                                    record.installedQty,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get(
                                      'process_time',
                                      logic.lang,
                                    ),
                                    record.createdDt,
                                    colors,
                                  ),
                                ],
                              ),
                            ),
                          ],
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

  List<QueryInfoRecord> _filterSortTraceRecords(
    List<QueryInfoRecord> records,
    _TraceListViewState listState,
  ) {
    var result = records;
    final q = listState.filter.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result
          .where(
            (r) => [
              r.productSn,
              r.mac,
              r.materialNo,
              r.materialName,
              r.materialCategory,
              r.materialVersion,
              r.customerMaterialNo,
              r.scanType,
              r.mfgName,
              r.mfgPn,
              r.productNo,
              r.lineCode,
              r.processCode,
              r.woNo,
              r.createdDt,
              r.checkAssembled,
              r.scannedCsn,
              r.parsedCsn,
            ].any((f) => f.toLowerCase().contains(q)),
          )
          .toList();
    } else {
      result = List<QueryInfoRecord>.from(result);
    }
    final field = listState.sortField;
    if (field != null) {
      result.sort((a, b) {
        int cmp;
        switch (field) {
          case 'process_time':
            cmp = a.createdDt.compareTo(b.createdDt);
            break;
          case 'product_sn':
            cmp = a.productSn.compareTo(b.productSn);
            break;
          case 'material_no':
            cmp = a.materialNo.compareTo(b.materialNo);
            break;
          case 'material_category':
            cmp = a.materialCategory.compareTo(b.materialCategory);
            break;
          case 'manufacturer':
            cmp = a.mfgName.compareTo(b.mfgName);
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
