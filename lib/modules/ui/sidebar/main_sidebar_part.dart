part of '../main_window.dart';

extension _MainWindowSidebarExt on _MainWindowState {
  /// Sidebar content (SN Queue or Component Trace CSN History)
  Widget _buildSidebarContent(
    BuildContext context,
    AppLogic logic,
    ThemeProvider theme,
    AppColors colors,
  ) {
    final isTraceMode = logic.viewMode == ViewMode.componentTrace;
    final isWoMode = !isTraceMode && _isWoInputMode;
    final count = isTraceMode ? logic.traceHistory.length : logic.snList.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    isTraceMode
                        ? Icons.history_rounded
                        : Icons.view_list_rounded,
                    size: 18,
                    color: colors.accentCyan,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      Translations.get(
                        isTraceMode ? 'trace_history' : 'mes_queue',
                        logic.lang,
                      ),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                PillBadge(
                  label: '$count',
                  color: colors.accentCyan,
                  bg: colors.accentCyan.withValues(alpha: 0.12),
                  border: colors.accentCyan.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  fontSize: 10,
                ),
                const SizedBox(width: 4),
                if (!isTraceMode)
                  IconButton(
                    key: const ValueKey('toggle_wo_mode'),
                    icon: Icon(
                      _isWoInputMode
                          ? Icons.assignment_rounded
                          : Icons.assignment_outlined,
                      color: _isWoInputMode
                          ? colors.accentCyan
                          : colors.textSecondary,
                      size: 18,
                    ),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    splashRadius: 16,
                    onPressed: () {
                      _rebuild(() {
                        _isWoInputMode = !_isWoInputMode;
                      });
                    },
                    tooltip: Translations.get(
                      _isWoInputMode ? 'switch_to_sn' : 'switch_to_wo',
                      logic.lang,
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: colors.textSecondary,
                    size: 18,
                  ),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                  onPressed: count == 0
                      ? null
                      : () {
                          if (isTraceMode) {
                            logic.refetchAllTraceSearches();
                          } else {
                            logic.refetchAllSns();
                          }
                        },
                  tooltip: Translations.get('refresh_all', logic.lang),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_sweep_rounded,
                    color: colors.accentRose,
                    size: 18,
                  ),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                  onPressed: count == 0
                      ? null
                      : () {
                          if (isTraceMode) {
                            logic.clearTraceHistory();
                          } else {
                            logic.clearAllSns();
                          }
                        },
                  tooltip: Translations.get('clear_all', logic.lang),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Shared Pill-Shaped Input Field (SN ↔ WO swap or Component Trace)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            color: colors.subCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isWoMode
                  ? colors.accentCyan.withValues(alpha: 0.55)
                  : colors.subCardBorder,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Icon(
                isTraceMode
                    ? Icons.search_rounded
                    : (isWoMode
                          ? Icons.assignment_outlined
                          : Icons.qr_code_scanner_rounded),
                size: 16,
                color: isWoMode ? colors.accentCyan : colors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const ValueKey('sidebar_primary_input'),
                  controller: _snController,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12.5,
                    fontFamily: 'JetBrains Mono',
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: Translations.get(
                      isTraceMode
                          ? 'component_trace_hint'
                          : (isWoMode ? 'enter_wo' : 'enter_sn'),
                      logic.lang,
                    ),
                    hintStyle: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11.5,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onSubmitted: (val) {
                    if (isTraceMode) {
                      logic.addTraceCsns(val);
                    } else if (isWoMode) {
                      logic.addWorkOrders(val);
                    } else {
                      logic.addSns(val);
                    }
                    _snController.clear();
                  },
                ),
              ),
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.accentColor, colors.accentCyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  key: const ValueKey('sidebar_submit_input'),
                  padding: EdgeInsets.zero,
                  icon: isWoMode && logic.isLoadingWo
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isTraceMode
                              ? Icons.search_rounded
                              : Icons.add_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                  onPressed: () {
                    if (isTraceMode) {
                      logic.addTraceCsns(_snController.text);
                    } else if (isWoMode) {
                      logic.addWorkOrders(_snController.text);
                    } else {
                      logic.addSns(_snController.text);
                    }
                    _snController.clear();
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Divider(color: colors.borderDefault, height: 1),
        const SizedBox(height: 8),

        // Scrollable Queue Items
        Expanded(
          child: isTraceMode
              ? _buildTraceHistoryList(logic, theme, colors)
              : _buildSnQueueList(logic, theme, colors),
        ),
      ],
    );
  }

  Widget _buildSnQueueList(
    AppLogic logic,
    ThemeProvider theme,
    AppColors colors,
  ) {
    if (logic.snList.isEmpty) {
      return Center(
        child: Text(
          Translations.get('no_sns_in_queue', logic.lang),
          style: TextStyle(color: colors.textMuted, fontSize: 12),
        ),
      );
    }

    final failSnCount = logic.snList.where(logic.snHasFail).length;
    final effectiveFailOnly = _queueFailOnlyFilter && failSnCount > 0;
    final displaySns = effectiveFailOnly
        ? logic.snList.where(logic.snHasFail).toList()
        : logic.snList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (failSnCount > 0 || _queueFailOnlyFilter) ...[
          Container(
            height: 26,
            padding: const EdgeInsets.all(2),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: colors.subCardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.subCardBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    key: const ValueKey('queue_filter_all'),
                    onTap: () => _rebuild(() => _queueFailOnlyFilter = false),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: !effectiveFailOnly
                            ? colors.accentCyan.withValues(alpha: 0.16)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: !effectiveFailOnly
                              ? colors.accentCyan.withValues(alpha: 0.4)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        '${Translations.get('queue_filter_all', logic.lang)} (${logic.snList.length})',
                        style: TextStyle(
                          color: !effectiveFailOnly
                              ? colors.accentCyan
                              : colors.textSecondary,
                          fontSize: 10.5,
                          fontWeight: !effectiveFailOnly
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: InkWell(
                    key: const ValueKey('queue_filter_fail'),
                    onTap: () => _rebuild(
                      () => _queueFailOnlyFilter = !effectiveFailOnly,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: effectiveFailOnly
                            ? colors.accentRose.withValues(alpha: 0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: effectiveFailOnly
                              ? colors.accentRose.withValues(alpha: 0.45)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        '${Translations.get('queue_filter_fail', logic.lang)} ($failSnCount)',
                        style: TextStyle(
                          color: effectiveFailOnly
                              ? colors.accentRose
                              : colors.textSecondary,
                          fontSize: 10.5,
                          fontWeight: effectiveFailOnly
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        Expanded(
          child: SelectionArea(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: displaySns.length,
              separatorBuilder: (ctx, idx) => const SizedBox(height: 5),
              itemBuilder: (context, index) {
                final sn = displaySns[displaySns.length - 1 - index];
                final isSelected = sn == logic.selectedSn;
                final isLoading = logic.loadingStatus[sn] == true;
                final dataStatus = logic.snDataStatus(sn);
                final hasError = dataStatus == SnDataStatus.error;
                final hasWarning = dataStatus == SnDataStatus.warning;

                // Record count for active tab
                int recordCount = 0;
                switch (logic.viewMode) {
                  case ViewMode.testRecord:
                    recordCount = logic.results[sn]?.length ?? 0;
                    break;
                  case ViewMode.barcodeHistory:
                    recordCount = logic.processResults[sn]?.length ?? 0;
                    break;
                  case ViewMode.wipComponents:
                    recordCount = logic.wipResults[sn]?.length ?? 0;
                    break;
                  case ViewMode.componentTrace:
                    recordCount = logic.traceResults[sn]?.length ?? 0;
                    break;
                  default:
                    recordCount = logic.results[sn]?.length ?? 0;
                    break;
                }
                if (recordCount == 0 && logic.results.containsKey(sn)) {
                  recordCount = logic.results[sn]?.length ?? 0;
                }

                // Next Station info from MES master
                final masterInfo = logic.snMasterInfo[sn];
                final nextStation = masterInfo == null
                    ? ''
                    : (masterInfo.nextProcessName.isNotEmpty
                          ? masterInfo.nextProcessName
                          : masterInfo.nextProcessCode);
                final productStatus = masterInfo?.productStatus.trim() ?? '';

                // Alternate / Resolved SN
                final alternateSn = logic.alternateSnFor(sn);

                final hasBottomRow =
                    isLoading ||
                    hasError ||
                    hasWarning ||
                    productStatus.isNotEmpty ||
                    (alternateSn != null && alternateSn.isNotEmpty) ||
                    nextStation.isNotEmpty;

                final Color cardBg = isSelected
                    ? (theme.isDark
                          ? Color.alphaBlend(
                              colors.accentColor.withValues(alpha: 0.16),
                              const Color(0xFF1E293B).withValues(
                                alpha: (theme.cardOpacity * 1.5).clamp(
                                  0.20,
                                  0.85,
                                ),
                              ),
                            )
                          : Color.alphaBlend(
                              colors.accentColor.withValues(alpha: 0.08),
                              Colors.white.withValues(
                                alpha: (theme.cardOpacity * 2.0).clamp(
                                  0.35,
                                  0.85,
                                ),
                              ),
                            ))
                    : colors.subCardBg;

                final Color cardBorder = isSelected
                    ? (theme.isDark
                          ? colors.accentColor.withValues(alpha: 0.55)
                          : colors.accentColor.withValues(alpha: 0.45))
                    : colors.subCardBorder;

                final List<BoxShadow>? cardShadow = isSelected
                    ? [
                        BoxShadow(
                          color: colors.primaryGlow.withValues(
                            alpha: theme.isDark ? 0.20 : 0.12,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null;

                return InkWell(
                  key: ValueKey('sn_row_$sn'),
                  onTap: () => logic.selectSn(sn),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: Motion.fast,
                    curve: Motion.curveOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6.5,
                    ),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: cardBorder,
                        width: isSelected ? 1.1 : 1.0,
                      ),
                      boxShadow: cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Row 1: Status Icon + SN + Count Badge + Actions
                        Row(
                          children: [
                            Icon(
                              hasError
                                  ? Icons.error_rounded
                                  : hasWarning
                                  ? Icons.warning_amber_rounded
                                  : (isLoading
                                        ? Icons.sync_rounded
                                        : (isSelected
                                              ? Icons.tag_rounded
                                              : Icons.tag_rounded)),
                              size: 14,
                              color: hasError
                                  ? colors.accentRose
                                  : hasWarning
                                  ? colors.accentAmber
                                  : (isSelected
                                        ? colors.accentCyan
                                        : colors.textMuted),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              // Independent selection scopes avoid combining the
                              // horizontal marquee coordinates of other rows.
                              child: Listener(
                                onPointerDown: (_) {
                                  if (logic.selectedSn != sn) {
                                    logic.selectSn(sn);
                                  }
                                },
                                child: SelectionArea(
                                  key: ValueKey('select_sn_$sn'),
                                  child: BounceMarqueeText(
                                    text: sn,
                                    style: TextStyle(
                                      color: hasError
                                          ? colors.accentRose
                                          : hasWarning
                                          ? colors.accentAmber
                                          : (isSelected
                                                ? colors.textPrimary
                                                : colors.textSecondary),
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      fontFamily: 'JetBrains Mono',
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (recordCount > 0 ||
                                logic.results.containsKey(sn)) ...[
                              AnimatedSwitcher(
                                duration: Motion.fast,
                                transitionBuilder: (child, animation) =>
                                    ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    ),
                                child: PillBadge(
                                  key: ValueKey('${sn}_$recordCount'),
                                  label: '$recordCount',
                                  color: recordCount > 0
                                      ? colors.accentEmerald
                                      : colors.textMuted,
                                  bg: recordCount > 0
                                      ? colors.accentEmerald.withValues(
                                          alpha: 0.15,
                                        )
                                      : colors.subCardBg,
                                  border: recordCount > 0
                                      ? colors.accentEmerald.withValues(
                                          alpha: 0.4,
                                        )
                                      : colors.subCardBorder,
                                  fontSize: 9.5,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            IconButton(
                              key: ValueKey('copy_sn_$sn'),
                              tooltip: Translations.get('copy_sn', logic.lang),
                              onPressed: () =>
                                  Clipboard.setData(ClipboardData(text: sn)),
                              padding: const EdgeInsets.all(2),
                              constraints: const BoxConstraints.tightFor(
                                width: 18,
                                height: 18,
                              ),
                              icon: Icon(
                                Icons.copy_rounded,
                                color: colors.textMuted,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (!isLoading) ...[
                              InkWell(
                                onTap: () => logic.refreshSn(sn),
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.refresh_rounded,
                                    color: colors.textMuted,
                                    size: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            InkWell(
                              onTap: () => logic.removeSn(sn),
                              borderRadius: BorderRadius.circular(4),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: colors.textMuted,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Row 2: Alternate SN + Next Station / Status
                        if (hasBottomRow) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              if (isLoading) ...[
                                SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.8,
                                    color: colors.accentCyan,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  Translations.get(
                                    'status_fetching',
                                    logic.lang,
                                  ),
                                  style: TextStyle(
                                    color: colors.accentCyan,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ] else if (hasError) ...[
                                Flexible(
                                  child: Text(
                                    logic.errors[sn] ?? 'Error',
                                    style: TextStyle(
                                      color: colors.accentRose,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ] else ...[
                                if (productStatus.isNotEmpty) ...[
                                  Builder(
                                    builder: (context) {
                                      final upper = productStatus.toUpperCase();
                                      final isGood =
                                          upper == 'GOOD' ||
                                          upper == 'PASS' ||
                                          upper == 'OK';
                                      final badgeColor = isGood
                                          ? colors.accentEmerald
                                          : colors.accentRose;
                                      return PillBadge(
                                        label: productStatus,
                                        color: badgeColor,
                                        bg: badgeColor.withValues(alpha: 0.12),
                                        border: badgeColor.withValues(
                                          alpha: 0.35,
                                        ),
                                        fontSize: 9.0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4.5,
                                          vertical: 1.5,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                if (alternateSn != null &&
                                    alternateSn.isNotEmpty) ...[
                                  Flexible(
                                    flex: 3,
                                    fit: FlexFit.loose,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.accentCyan.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                          color: colors.accentCyan.withValues(
                                            alpha: 0.25,
                                          ),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.sync_alt_rounded,
                                            size: 10,
                                            color: colors.accentCyan,
                                          ),
                                          const SizedBox(width: 3),
                                          Flexible(
                                            child: Listener(
                                              onPointerDown: (_) {
                                                if (logic.selectedSn != sn) {
                                                  logic.selectSn(sn);
                                                }
                                              },
                                              child: SelectionArea(
                                                key: ValueKey(
                                                  'select_alternate_sn_$sn',
                                                ),
                                                child: BounceMarqueeText(
                                                  text: alternateSn,
                                                  style: TextStyle(
                                                    color: colors.accentCyan,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    fontFamily:
                                                        'JetBrains Mono',
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                ],
                                if (nextStation.isNotEmpty) ...[
                                  Flexible(
                                    flex: 2,
                                    fit: FlexFit.loose,
                                    child: PillBadge(
                                      label: 'Next: $nextStation',
                                      color: colors.accentPurple,
                                      bg: colors.accentPurple.withValues(
                                        alpha: 0.12,
                                      ),
                                      border: colors.accentPurple.withValues(
                                        alpha: 0.35,
                                      ),
                                      fontSize: 9.5,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1.5,
                                      ),
                                      icon: Icons.arrow_forward_rounded,
                                      useMarquee: true,
                                    ),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTraceHistoryList(
    AppLogic logic,
    ThemeProvider theme,
    AppColors colors,
  ) {
    if (logic.traceHistory.isEmpty) {
      return Center(
        child: Text(
          Translations.get('no_trace_history', logic.lang),
          style: TextStyle(color: colors.textMuted, fontSize: 12),
        ),
      );
    }

    return SelectionArea(
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        itemCount: logic.traceHistory.length,
        separatorBuilder: (ctx, idx) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final csn = logic.traceHistory[index];
          final isSelected = csn == logic.selectedTraceCsn;
          final isLoading = logic.traceLoadingStatus[csn] == true;
          final hasError = logic.traceErrors[csn] != null;
          final recordCount = logic.traceResults[csn]?.length ?? 0;

          final Color cardBg = isSelected
              ? (theme.isDark
                    ? Color.alphaBlend(
                        colors.accentColor.withValues(alpha: 0.16),
                        const Color(0xFF1E293B).withValues(
                          alpha: (theme.cardOpacity * 1.5).clamp(0.20, 0.85),
                        ),
                      )
                    : Color.alphaBlend(
                        colors.accentColor.withValues(alpha: 0.08),
                        Colors.white.withValues(
                          alpha: (theme.cardOpacity * 2.0).clamp(0.35, 0.85),
                        ),
                      ))
              : colors.subCardBg;

          final Color cardBorder = isSelected
              ? (theme.isDark
                    ? colors.accentColor.withValues(alpha: 0.55)
                    : colors.accentColor.withValues(alpha: 0.45))
              : colors.subCardBorder;

          final List<BoxShadow>? cardShadow = isSelected
              ? [
                  BoxShadow(
                    color: colors.primaryGlow.withValues(
                      alpha: theme.isDark ? 0.20 : 0.12,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null;

          return InkWell(
            onTap: () => logic.selectTraceCsn(csn),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: Motion.fast,
              curve: Motion.curveOut,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5.5),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: cardBorder,
                  width: isSelected ? 1.1 : 1.0,
                ),
                boxShadow: cardShadow,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.memory_rounded,
                    size: 14,
                    color: isSelected ? colors.accentCyan : colors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: BounceMarqueeText(
                      text: csn,
                      style: TextStyle(
                        color: hasError
                            ? colors.accentRose
                            : (isSelected
                                  ? colors.textPrimary
                                  : colors.textSecondary),
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w600,
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (isLoading) ...[
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.accentCyan,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ] else if (hasError) ...[
                    Icon(
                      Icons.error_rounded,
                      color: colors.accentRose,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                  ] else if (logic.traceResults.containsKey(csn)) ...[
                    AnimatedSwitcher(
                      duration: Motion.fast,
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: PillBadge(
                        key: ValueKey(recordCount),
                        label: '$recordCount',
                        color: recordCount > 0
                            ? colors.accentEmerald
                            : colors.textMuted,
                        bg: recordCount > 0
                            ? colors.accentEmerald.withValues(alpha: 0.15)
                            : colors.subCardBg,
                        border: recordCount > 0
                            ? colors.accentEmerald.withValues(alpha: 0.4)
                            : colors.subCardBorder,
                        fontSize: 9.5,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (!isLoading) ...[
                    InkWell(
                      onTap: () => logic.refreshTraceCsn(csn),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.refresh_rounded,
                          color: colors.textMuted,
                          size: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  InkWell(
                    onTap: () => logic.removeTraceCsn(csn),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        Icons.close_rounded,
                        color: colors.textMuted,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
