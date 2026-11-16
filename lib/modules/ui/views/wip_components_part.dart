part of '../main_window.dart';

extension _MainWindowWipComponentsExt on _MainWindowState {
  Widget _buildWipComponentsView(
    BuildContext context,
    AppLogic logic,
    ThemeProvider theme,
    AppColors colors,
  ) {
    final sn = logic.selectedSn;
    final isLoading = logic.wipLoadingStatus[sn] == true;
    final error = logic.wipErrors[sn];
    final records = logic.wipResults[sn];

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

    final displayRecords = _filterSortWipRecords(records, _wipListState);

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
          listState: _wipListState,
          sortOptions: [
            _SortOption(
              'process_time',
              Translations.get('process_time', logic.lang),
              icon: Icons.schedule_rounded,
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
                    '${record.materialNo}_${record.scannedCsn}_${record.createdDt}_$index';
                final compId = record.wipProductComponentId;
                final isParamExpanded =
                    compId > 0 && _expandedCompParamIds.contains(compId);
                final traceTargetCsn = record.parsedCsn.isNotEmpty
                    ? record.parsedCsn
                    : record.scannedCsn;

                return _StaggeredItem(
                  key: ValueKey(itemKey),
                  itemKey: itemKey,
                  animatedKeys: _wipListState.animatedItemKeys,
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
                                          color: colors.accentAmber.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: colors.accentAmber
                                                .withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.memory_rounded,
                                          color: colors.accentAmber,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        record.materialNo,
                                        style: TextStyle(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (record.scanType.isNotEmpty)
                                    PillBadge(
                                      label: record.scanType,
                                      color: colors.accentCyan,
                                      bg: colors.accentCyan.withValues(
                                        alpha: 0.12,
                                      ),
                                      border: colors.accentCyan.withValues(
                                        alpha: 0.35,
                                      ),
                                      fontSize: 10,
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
                                if (traceTargetCsn.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(6),
                                      onTap: () => logic.traceComponentFromWip(
                                        traceTargetCsn,
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
                                              Icons.travel_explore_rounded,
                                              size: 12,
                                              color: colors.accentCyan,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              Translations.get(
                                                'trace_component',
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
                                if (compId > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(6),
                                      onTap: () {
                                        _rebuild(() {
                                          if (isParamExpanded) {
                                            _expandedCompParamIds.remove(
                                              compId,
                                            );
                                          } else {
                                            _expandedCompParamIds.add(compId);
                                            logic.fetchComponentParams(compId);
                                          }
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isParamExpanded
                                              ? colors.accentPurple.withValues(
                                                  alpha: 0.2,
                                                )
                                              : colors.accentPurple.withValues(
                                                  alpha: 0.1,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: colors.accentPurple
                                                .withValues(
                                                  alpha: isParamExpanded
                                                      ? 0.5
                                                      : 0.3,
                                                ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.settings_ethernet_rounded,
                                              size: 12,
                                              color: colors.accentPurple,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              Translations.get(
                                                'component_params',
                                                logic.lang,
                                              ),
                                              style: TextStyle(
                                                color: colors.accentPurple,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                if (record.materialCategory.isNotEmpty)
                                  PillBadge(
                                    label: record.materialCategory,
                                    color: colors.accentAmber,
                                    bg: colors.accentAmber.withValues(
                                      alpha: 0.12,
                                    ),
                                    border: colors.accentAmber.withValues(
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
                                    Translations.get('location', logic.lang),
                                    record.location,
                                    colors,
                                    highlight: true,
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
                                  _buildInfoRow(
                                    Translations.get('package_id', logic.lang),
                                    record.pkgId,
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
                                    Translations.get('quantity', logic.lang),
                                    record.installedQty,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get('date_code', logic.lang),
                                    record.dateCode,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get(
                                      'line_station_code',
                                      logic.lang,
                                    ),
                                    record.stationCode,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get('scan_type', logic.lang),
                                    record.scanType,
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
                                  _buildInfoRow(
                                    Translations.get('unlink_time', logic.lang),
                                    record.unlinkTime,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get(
                                      'check_assembled_code',
                                      logic.lang,
                                    ),
                                    record.checkAssembledCode,
                                    colors,
                                  ),
                                  _buildInfoRow(
                                    Translations.get('operator', logic.lang),
                                    record.creator,
                                    colors,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (isParamExpanded) ...[
                          const SizedBox(height: 8),
                          _buildComponentParamsSubPanel(compId, logic, colors),
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

  Widget _buildComponentParamsSubPanel(
    int compId,
    AppLogic logic,
    AppColors colors,
  ) {
    final loading = logic.componentParamsLoading[compId] == true;
    final err = logic.componentParamsErrors[compId];
    final params = logic.componentParams[compId] ?? const [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.accentPurple.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.accentPurple.withValues(alpha: 0.25)),
      ),
      child: loading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.accentPurple,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${Translations.get('status_fetching', logic.lang)}...',
                  style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
                ),
              ],
            )
          : err != null
          ? Text(
              err,
              style: TextStyle(color: colors.accentRose, fontSize: 11.5),
            )
          : params.isEmpty
          ? Text(
              Translations.get('no_component_params', logic.lang),
              style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Translations.get('component_params', logic.lang),
                  style: TextStyle(
                    color: colors.accentPurple,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                ...params.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (p.macParam.isNotEmpty)
                          Text(
                            '${Translations.get('mac_param', logic.lang)}: ${p.macParam}',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                        if (p.macType.isNotEmpty)
                          Text(
                            '${Translations.get('mac_type', logic.lang)}: ${p.macType}',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 11.5,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                        if (p.macValue.isNotEmpty)
                          Text(
                            '${Translations.get('mac_value', logic.lang)}: ${p.macValue}',
                            style: TextStyle(
                              color: colors.accentCyan,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                        if (p.parsedCsn.isNotEmpty)
                          Text(
                            '${Translations.get('parsed_csn', logic.lang)}: ${p.parsedCsn}',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 11.5,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                        if (p.createdDt.isNotEmpty)
                          Text(
                            p.createdDt,
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 11,
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  List<WipComponentRecord> _filterSortWipRecords(
    List<WipComponentRecord> records,
    _WipListViewState listState,
  ) {
    var result = records;
    final q = listState.filter.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result
          .where(
            (r) => [
              r.materialNo,
              r.materialCategory,
              r.mfgName,
              r.mfgPn,
              r.dateCode,
              r.scannedCsn,
              r.parsedCsn,
              r.scanType,
              r.unlinkTime,
              r.checkAssembledCode,
              r.pkgId,
              r.stationCode,
              r.processCode,
              r.creator,
              r.createdDt,
              r.location,
            ].any((f) => f.toLowerCase().contains(q)),
          )
          .toList();
    } else {
      result = List<WipComponentRecord>.from(result);
    }
    final field = listState.sortField;
    if (field != null) {
      result.sort((a, b) {
        int cmp;
        switch (field) {
          case 'process_time':
            cmp = a.createdDt.compareTo(b.createdDt);
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
