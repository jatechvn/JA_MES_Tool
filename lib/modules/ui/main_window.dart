import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../logic.dart';
import '../api_client.dart';
import '../build_info.dart';
import '../constants.dart';
import '../translations.dart';
import '../browser_helper.dart';
import 'styles.dart';
import 'motion.dart';

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

/// Presents a dialog with an iOS-style scale+fade transition instead of
/// Material's default fade — drop-in replacement for [showDialog].
Future<T?> _showIosDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: Motion.normal,
    pageBuilder: (ctx, animation, secondaryAnimation) => builder(ctx),
    transitionBuilder: (ctx, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Motion.curveOut,
        reverseCurve: Motion.curveIn,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _MainWindowState extends State<MainWindow> with WindowListener {
  final TextEditingController _snController = TextEditingController();
  bool _hasCheckedInitialToken = false;
  bool _isMaximized = false;

  final _ListViewState _testRecordListState = _ListViewState();
  final _ListViewState _barcodeListState = _ListViewState();
  final _ListViewState _wipListState = _ListViewState();

  // Tracks the glass Sort dropdown's OverlayEntry so it can be closed on
  // selection, outside tap, tab/SN switch, or widget dispose. Anchor position
  // is computed fresh at open-time from the button's own RenderBox (see
  // _openSortOverlay) — no shared Key/LayerLink is involved.
  OverlayEntry? _sortOverlayEntry;
  // Last '${viewMode}_${selectedSn}' seen in build(), used to detect a tab or
  // SN change and close a stale, still-open Sort dropdown — otherwise its
  // onSelect closure keeps pointing at the _ListViewState of the tab the
  // user just left, silently re-sorting content that's no longer visible.
  String? _lastSortViewKey;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.isMaximized().then((value) {
      if (mounted) setState(() => _isMaximized = value);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialToken();
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _sortOverlayEntry?.remove();
    _testRecordListState.filterCtrl.dispose();
    _barcodeListState.filterCtrl.dispose();
    _wipListState.filterCtrl.dispose();
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  void _checkInitialToken() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final logic = context.read<AppLogic>();
    if (logic.isConnectionValid == false && !_hasCheckedInitialToken) {
      _hasCheckedInitialToken = true;
      _showTokenExpiredWarningDialog(context, logic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final logic = context.watch<AppLogic>();

    // The Sort dropdown lives in the root Overlay, decoupled from the
    // AnimatedSwitcher that owns the tab/SN view — closing it here (rather
    // than at every tab-pill/SN-row onTap) guarantees it can never be left
    // open and bound to a _ListViewState that's no longer the visible tab.
    final sortViewKey = '${logic.viewMode}_${logic.selectedSn}';
    if (_lastSortViewKey != null &&
        _lastSortViewKey != sortViewKey &&
        _sortOverlayEntry != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _closeSortOverlay());
    }
    _lastSortViewKey = sortViewKey;

    if (logic.isConnectionValid == false && !_hasCheckedInitialToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasCheckedInitialToken && mounted) {
          _hasCheckedInitialToken = true;
          _showTokenExpiredWarningDialog(context, logic);
        }
      });
    } else if (logic.isConnectionValid == true && _hasCheckedInitialToken) {
      _hasCheckedInitialToken = false;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: Motion.normal,
            curve: Motion.curveInOut,
            width: 300,
            color: theme.sidebarBg,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      Translations.get('mes_queue', logic.lang),
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.settings,
                            color: theme.textPrimary,
                            size: 20,
                          ),
                          onPressed: () =>
                              _showSettingsDialog(context, logic, theme),
                          tooltip: Translations.get('settings', logic.lang),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.refresh,
                            color: theme.textPrimary,
                            size: 20,
                          ),
                          onPressed: logic.snList.isEmpty
                              ? null
                              : () => logic.refetchAllSns(),
                          tooltip: Translations.get('refresh_all', logic.lang),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_sweep,
                            color: theme.failColor,
                            size: 20,
                          ),
                          onPressed: logic.snList.isEmpty
                              ? null
                              : () => logic.clearAllSns(),
                          tooltip: Translations.get('clear_all', logic.lang),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Add SN
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _snController,
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: Translations.get('enter_sn', logic.lang),
                          hintStyle: TextStyle(color: theme.textSecondary),
                          filled: true,
                          fillColor: theme.cardBg,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onSubmitted: (val) {
                          logic.addSns(val);
                          _snController.clear();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade700,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () {
                          logic.addSns(_snController.text);
                          _snController.clear();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                const SizedBox(height: 16),
                const Divider(color: Colors.white24),

                // SN List Queue
                Expanded(
                  child: logic.snList.isEmpty
                      ? Center(
                          child: Text(
                            Translations.get('no_sns_in_queue', logic.lang),
                            style: TextStyle(color: theme.textSecondary),
                          ),
                        )
                      : SelectionArea(
                          child: ListView.builder(
                            itemCount: logic.snList.length,
                            itemBuilder: (context, index) {
                              final sn = logic.snList[index];
                              final isSelected = sn == logic.selectedSn;
                              final isLoading = logic.loadingStatus[sn] == true;
                              final hasError = logic.errors[sn] != null;
                              final recordCount =
                                  logic.results[sn]?.length ?? 0;

                              return InkWell(
                                onTap: () => logic.selectSn(sn),
                                child: AnimatedContainer(
                                  duration: Motion.fast,
                                  curve: Motion.curveOut,
                                  margin: const EdgeInsets.only(bottom: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.blue.withValues(alpha: 0.3)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          sn,
                                          style: TextStyle(
                                            color: hasError
                                                ? theme.failColor
                                                : theme.textPrimary,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (isLoading)
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      else if (hasError)
                                        const Icon(
                                          Icons.error,
                                          color: Colors.red,
                                          size: 16,
                                        )
                                      else if (logic.results.containsKey(sn))
                                        AnimatedSwitcher(
                                          duration: Motion.fast,
                                          switchInCurve: Motion.curveOut,
                                          switchOutCurve: Motion.curveIn,
                                          transitionBuilder:
                                              (child, animation) =>
                                                  ScaleTransition(
                                                    scale: animation,
                                                    child: child,
                                                  ),
                                          child: Container(
                                            key: ValueKey(recordCount),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: recordCount > 0
                                                  ? theme.passColor
                                                  : Colors.grey,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              recordCount.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 4),
                                      if (!isLoading)
                                        InkWell(
                                          onTap: () => logic.refreshSn(sn),
                                          child: Icon(
                                            Icons.refresh,
                                            color: theme.textSecondary,
                                            size: 16,
                                          ),
                                        ),
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: () => logic.removeSn(sn),
                                        child: Icon(
                                          Icons.close,
                                          color: theme.textSecondary,
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: AnimatedContainer(
              duration: Motion.normal,
              curve: Motion.curveInOut,
              color: theme.sidebarBg,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar
                  Row(
                    children: [
                      Text(
                        Translations.get('result_details', logic.lang),
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: theme.isDark
                                  ? Colors.black87
                                  : Colors.white70,
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (logic.isConnectionValid == null)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else if (logic.isConnectionValid == true)
                        Tooltip(
                          message: 'Connection Valid',
                          child: Icon(
                            Icons.check_circle,
                            color: theme.passColor,
                            size: 20,
                          ),
                        )
                      else
                        Tooltip(
                          message: logic.connectionError ?? 'Connection Error',
                          child: Icon(
                            Icons.error,
                            color: theme.failColor,
                            size: 20,
                          ),
                        ),
                      if (BuildInfo.isDebug) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            'DEBUG • v${BuildInfo.version} (${BuildInfo.debugTimestamp})',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 16),
                      AnimatedContainer(
                        duration: Motion.normal,
                        curve: Motion.curveInOut,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: theme.cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.isDark
                                ? Colors.white24
                                : Colors.black12,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _HoverChip(
                              icon: Icons.fact_check_rounded,
                              label: Translations.get(
                                'tab_test_record',
                                logic.lang,
                              ),
                              background: logic.viewMode == ViewMode.testRecord
                                  ? Colors.blue.shade700
                                  : Colors.transparent,
                              foreground: logic.viewMode == ViewMode.testRecord
                                  ? Colors.white
                                  : theme.textSecondary,
                              hoverBackground: theme.isDark
                                  ? Colors.white12
                                  : Colors.black.withValues(alpha: 0.06),
                              keepExpanded:
                                  logic.viewMode == ViewMode.testRecord ||
                                  _isMaximized,
                              onTap: () =>
                                  logic.setViewMode(ViewMode.testRecord),
                            ),
                            _HoverChip(
                              icon: Icons.qr_code_2_rounded,
                              label: Translations.get(
                                'tab_barcode_history',
                                logic.lang,
                              ),
                              background:
                                  logic.viewMode == ViewMode.barcodeHistory
                                  ? Colors.blue.shade700
                                  : Colors.transparent,
                              foreground:
                                  logic.viewMode == ViewMode.barcodeHistory
                                  ? Colors.white
                                  : theme.textSecondary,
                              hoverBackground: theme.isDark
                                  ? Colors.white12
                                  : Colors.black.withValues(alpha: 0.06),
                              keepExpanded:
                                  logic.viewMode == ViewMode.barcodeHistory ||
                                  _isMaximized,
                              onTap: () =>
                                  logic.setViewMode(ViewMode.barcodeHistory),
                            ),
                            _HoverChip(
                              icon: Icons.memory_rounded,
                              label: Translations.get(
                                'tab_wip_components',
                                logic.lang,
                              ),
                              background:
                                  logic.viewMode == ViewMode.wipComponents
                                  ? Colors.blue.shade700
                                  : Colors.transparent,
                              foreground:
                                  logic.viewMode == ViewMode.wipComponents
                                  ? Colors.white
                                  : theme.textSecondary,
                              hoverBackground: theme.isDark
                                  ? Colors.white12
                                  : Colors.black.withValues(alpha: 0.06),
                              keepExpanded:
                                  logic.viewMode == ViewMode.wipComponents ||
                                  _isMaximized,
                              onTap: () =>
                                  logic.setViewMode(ViewMode.wipComponents),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),

                      // Template CSV
                      _HoverChip(
                        icon: Icons.file_present_rounded,
                        label: Translations.get('template', logic.lang),
                        background: Colors.blueGrey.shade700,
                        foreground: Colors.white,
                        keepExpanded: _isMaximized,
                        onTap: () => logic.downloadTemplateCsv(),
                      ),
                      const SizedBox(width: 6),

                      // Import CSV
                      _HoverChip(
                        icon: Icons.file_upload_rounded,
                        label: Translations.get('import', logic.lang),
                        background: Colors.orange.shade700,
                        foreground: Colors.white,
                        keepExpanded: _isMaximized,
                        onTap: () => logic.importCsv(),
                      ),
                      const SizedBox(width: 6),

                      // Export CSV
                      _HoverChip(
                        icon: Icons.file_download_rounded,
                        label: Translations.get('export', logic.lang),
                        background: Colors.green.shade700,
                        foreground: Colors.white,
                        keepExpanded: _isMaximized,
                        onTap: () => logic.exportCsv(),
                      ),
                      const SizedBox(width: 12),

                      // Language Toggle
                      _HoverChip(
                        icon: Icons.language_rounded,
                        label: logic.lang.toUpperCase(),
                        background: theme.cardBg,
                        foreground: theme.textPrimary,
                        border: Border.all(
                          color: theme.isDark ? Colors.white24 : Colors.black12,
                        ),
                        keepExpanded: _isMaximized,
                        onTap: () => logic.cycleLanguage(),
                      ),
                      const SizedBox(width: 6),

                      // Theme Toggle
                      _HoverChip(
                        icon: theme.isDark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        label: Translations.get('toggle_theme', logic.lang),
                        background: theme.cardBg,
                        foreground: theme.isDark
                            ? Colors.amber
                            : Colors.indigo.shade600,
                        border: Border.all(
                          color: theme.isDark ? Colors.white24 : Colors.black12,
                        ),
                        keepExpanded: _isMaximized,
                        onTap: () =>
                            context.read<ThemeProvider>().toggleTheme(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (logic.globalError.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: logic.globalError.contains('successfully')
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        border: Border.all(
                          color: logic.globalError.contains('successfully')
                              ? Colors.green
                              : Colors.red.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        logic.globalError,
                        style: TextStyle(
                          color: logic.globalError.contains('successfully')
                              ? Colors.green
                              : theme.failColor,
                        ),
                      ),
                    ),

                  // Detail View
                  Expanded(
                    child: SelectionArea(
                      child: AnimatedSwitcher(
                        duration: Motion.normal,
                        switchInCurve: Motion.curveOut,
                        switchOutCurve: Motion.curveIn,
                        transitionBuilder: (child, animation) {
                          final slide = Tween<Offset>(
                            begin: const Offset(0.03, 0),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: slide,
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey(
                            '${logic.viewMode}_${logic.selectedSn}',
                          ),
                          child: _buildDetailView(context, logic, theme),
                        ),
                      ),
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

  Widget _buildDetailView(
    BuildContext context,
    AppLogic logic,
    ThemeProvider theme,
  ) {
    if (logic.selectedSn.isEmpty) {
      return Center(
        child: Text(
          Translations.get('select_sn', logic.lang),
          style: TextStyle(color: theme.textSecondary),
        ),
      );
    }

    if (logic.viewMode == ViewMode.barcodeHistory) {
      return _buildBarcodeHistoryView(context, logic, theme);
    }

    if (logic.viewMode == ViewMode.wipComponents) {
      return _buildWipComponentsView(context, logic, theme);
    }

    final sn = logic.selectedSn;
    final isLoading = logic.loadingStatus[sn] == true;
    final error = logic.errors[sn];
    final records = logic.results[sn];

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${Translations.get('error_for', logic.lang)} $sn: $error',
          style: TextStyle(color: theme.failColor),
        ),
      );
    }

    if (records == null || records.isEmpty) {
      return Center(
        child: Text(
          '${Translations.get('no_records', logic.lang)} $sn',
          style: TextStyle(color: theme.textSecondary),
        ),
      );
    }

    final displayRecords = _filterSortTestRecords(
      records,
      _testRecordListState,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRecordsHeader(
          sn: sn,
          count: records.length,
          theme: theme,
          lang: logic.lang,
          resolvedSn: logic.resolvedSnFor(sn),
          snMasterInfo: logic.snMasterInfo[sn],
          listState: _testRecordListState,
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
              child: Text(
                Translations.get('no_matches', logic.lang),
                style: TextStyle(color: theme.textSecondary),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: displayRecords.length,
              itemBuilder: (context, index) {
                final record = displayRecords[index];
                final isPass = record.testResult.toUpperCase() == 'PASS';

                final itemKey =
                    '${record.stationId}_${record.testDate}_${record.testTime}_${record.internalSn}';
                return _StaggeredItem(
                  key: ValueKey(itemKey),
                  itemKey: itemKey,
                  animatedKeys: _testRecordListState.animatedItemKeys,
                  index: index,
                  child: AnimatedContainer(
                    duration: Motion.normal,
                    curve: Motion.curveInOut,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.borderTheme),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${Translations.get('station', logic.lang)}: ${record.stationId}',
                              style: TextStyle(
                                color: theme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isPass
                                    ? theme.passColor
                                    : theme.failColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                record.testResult,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Translations.get('product_no', logic.lang),
                          record.productNo,
                          theme,
                        ),
                        _buildInfoRow(
                          Translations.get('internal_sn', logic.lang),
                          record.internalSn,
                          theme,
                          highlight: true,
                        ),
                        _buildInfoRow(
                          Translations.get('customer_sn', logic.lang),
                          record.customerSn,
                          theme,
                        ),
                        _buildInfoRow(
                          Translations.get('process_code', logic.lang),
                          record.processCode,
                          theme,
                        ),
                        _buildInfoRow(
                          Translations.get('line_station_code', logic.lang),
                          record.lineStationCode,
                          theme,
                        ),
                        _buildInfoRow(
                          Translations.get('test_host', logic.lang),
                          record.loc,
                          theme,
                          highlight: true,
                        ),
                        _buildInfoRow(
                          Translations.get('product_series', logic.lang),
                          record.productSeries,
                          theme,
                        ),
                        _buildInfoRow(
                          Translations.get('work_order', logic.lang),
                          record.woNo,
                          theme,
                        ),
                        _buildInfoRow(
                          Translations.get('test_date', logic.lang),
                          record.testDate,
                          theme,
                        ),
                        _buildInfoRow(
                          Translations.get('test_time', logic.lang),
                          record.testTime,
                          theme,
                        ),
                        _buildInfoRow(
                          Translations.get('emp_no', logic.lang),
                          record.empNo,
                          theme,
                        ),
                        if (!isPass) ...[
                          if (record.errCode.isNotEmpty)
                            _buildInfoRow(
                              Translations.get('error_code', logic.lang),
                              record.errCode,
                              theme,
                            ),
                          if (record.failureReason.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                '${Translations.get('failure_reason', logic.lang)}: ${record.failureReason}',
                                style: TextStyle(color: theme.failColor),
                              ),
                            ),
                          if (record.failDesc.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                '${Translations.get('fail_desc', logic.lang)}: ${record.failDesc}',
                                style: TextStyle(color: theme.failColor),
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

  Widget _buildBarcodeHistoryView(
    BuildContext context,
    AppLogic logic,
    ThemeProvider theme,
  ) {
    final sn = logic.selectedSn;
    final isLoading = logic.processLoadingStatus[sn] == true;
    final error = logic.processErrors[sn];
    final records = logic.processResults[sn];

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${Translations.get('error_for', logic.lang)} $sn: $error',
          style: TextStyle(color: theme.failColor),
        ),
      );
    }

    if (records == null || records.isEmpty) {
      return Center(
        child: Text(
          '${Translations.get('no_records', logic.lang)} $sn',
          style: TextStyle(color: theme.textSecondary),
        ),
      );
    }

    final displayRecords = _filterSortBarcodeRecords(
      records,
      _barcodeListState,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRecordsHeader(
          sn: sn,
          count: records.length,
          theme: theme,
          lang: logic.lang,
          resolvedSn: logic.resolvedSnFor(sn),
          snMasterInfo: logic.snMasterInfo[sn],
          listState: _barcodeListState,
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
          ],
        ),
        const SizedBox(height: 12),
        if (displayRecords.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                Translations.get('no_matches', logic.lang),
                style: TextStyle(color: theme.textSecondary),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: displayRecords.length,
              itemBuilder: (context, index) {
                final record = displayRecords[index];
                final isPass = record.result.toLowerCase() == 'pass';

                final itemKey =
                    '${record.currentProcessCode}_${record.operateDt}_${record.lineStation}';
                return _StaggeredItem(
                  key: ValueKey(itemKey),
                  itemKey: itemKey,
                  animatedKeys: _barcodeListState.animatedItemKeys,
                  index: index,
                  child: AnimatedContainer(
                    duration: Motion.normal,
                    curve: Motion.curveInOut,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.borderTheme),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                record.currentProcessName.isNotEmpty
                                    ? record.currentProcessName
                                    : record.currentProcessCode,
                                style: TextStyle(
                                  color: theme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (record.result.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isPass
                                      ? theme.passColor
                                      : theme.failColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  record.result.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Translations.get('process_time', logic.lang),
                          record.operateDt,
                          theme,
                          highlight: true,
                        ),
                        _buildInfoRow(
                          Translations.get('line_station_code', logic.lang),
                          record.lineStation,
                          theme,
                        ),
                        _buildInfoRow(
                          Translations.get('work_order', logic.lang),
                          record.woNo,
                          theme,
                        ),
                        _buildInfoRow(
                          Translations.get('product_no', logic.lang),
                          record.productNo,
                          theme,
                        ),
                        _buildInfoRow(
                          Translations.get('customer_sn', logic.lang),
                          record.customerSn,
                          theme,
                        ),
                        _buildInfoRow(
                          Translations.get('operator', logic.lang),
                          record.operatorName,
                          theme,
                        ),
                        _buildInfoRow(
                          Translations.get('equipment', logic.lang),
                          record.eqpId,
                          theme,
                        ),
                        if (record.errorCode.isNotEmpty)
                          _buildInfoRow(
                            Translations.get('error_code', logic.lang),
                            record.errorCode,
                            theme,
                          ),
                        if (record.testResultMsg.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '${Translations.get('failure_reason', logic.lang)}: ${record.testResultMsg}',
                              style: TextStyle(color: theme.failColor),
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

  Widget _buildWipComponentsView(
    BuildContext context,
    AppLogic logic,
    ThemeProvider theme,
  ) {
    final sn = logic.selectedSn;
    final isLoading = logic.wipLoadingStatus[sn] == true;
    final error = logic.wipErrors[sn];
    final records = logic.wipResults[sn];

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${Translations.get('error_for', logic.lang)} $sn: $error',
          style: TextStyle(color: theme.failColor),
        ),
      );
    }

    if (records == null || records.isEmpty) {
      return Center(
        child: Text(
          '${Translations.get('no_records', logic.lang)} $sn',
          style: TextStyle(color: theme.textSecondary),
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
              child: Text(
                Translations.get('no_matches', logic.lang),
                style: TextStyle(color: theme.textSecondary),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              itemCount: displayRecords.length,
              itemBuilder: (context, index) {
                final record = displayRecords[index];

                final itemKey =
                    '${record.materialNo}_${record.scannedCsn}_${record.createdDt}';
                return _StaggeredItem(
                  key: ValueKey(itemKey),
                  itemKey: itemKey,
                  animatedKeys: _wipListState.animatedItemKeys,
                  index: index,
                  child: AnimatedContainer(
                    duration: Motion.normal,
                    curve: Motion.curveInOut,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.borderTheme),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                record.materialNo,
                                style: TextStyle(
                                  color: theme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (record.materialCategory.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey.shade600,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  record.materialCategory,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Translations.get('manufacturer', logic.lang),
                          record.mfgName,
                          theme,
                        ),
                        _buildInfoRow(
                          Translations.get('mfg_pn', logic.lang),
                          record.mfgPn,
                          theme,
                        ),
                        _buildInfoRow(
                          Translations.get('component_sn', logic.lang),
                          record.scannedCsn,
                          theme,
                          highlight: true,
                        ),
                        _buildInfoRow(
                          Translations.get('package_id', logic.lang),
                          record.pkgId,
                          theme,
                        ),
                        _buildInfoRow(
                          Translations.get('date_code', logic.lang),
                          record.dateCode,
                          theme,
                        ),
                        _buildInfoRow(
                          Translations.get('quantity', logic.lang),
                          record.installedQty,
                          theme,
                        ),
                        _buildInfoRow(
                          Translations.get('line_station_code', logic.lang),
                          record.stationCode,
                          theme,
                        ),
                        _buildInfoRow(
                          Translations.get('process_time', logic.lang),
                          record.createdDt,
                          theme,
                        ),
                        _buildInfoRow(
                          Translations.get('operator', logic.lang),
                          record.creator,
                          theme,
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

  /// Header row shown above each record list: "Records for SN: X (N)" (the
  /// count is omitted when there's 0 or 1 record) plus a search filter box
  /// and a sort-by button, all on the same row.
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
              r.testResult,
              r.empNo,
              r.errCode,
              r.failureReason,
              r.failDesc,
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

  List<SnProcessRecord> _filterSortBarcodeRecords(
    List<SnProcessRecord> records,
    _ListViewState listState,
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
              r.woNo,
              r.productNo,
              r.customerSn,
              r.operatorName,
              r.eqpId,
              r.errorCode,
              r.testResultMsg,
              r.operateDt,
              r.result,
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
          default:
            cmp = 0;
        }
        return listState.sortAsc ? cmp : -cmp;
      });
    }
    return result;
  }

  List<WipComponentRecord> _filterSortWipRecords(
    List<WipComponentRecord> records,
    _ListViewState listState,
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
              r.pkgId,
              r.stationCode,
              r.processCode,
              r.creator,
              r.createdDt,
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

  /// Small tinted pill for at-a-glance SN Master info (error code / next
  /// process) next to the records header title — same visual language as
  /// the connection-health pill in Settings (tinted bg, no border).
  Widget _buildInfoChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRecordsHeader({
    required String sn,
    required int count,
    required ThemeProvider theme,
    required String lang,
    required _ListViewState listState,
    required List<_SortOption> sortOptions,
    String? resolvedSn,
    SnMasterInfo? snMasterInfo,
  }) {
    final countSuffix = count > 1 ? ' ($count)' : '';
    final snLabel =
        (resolvedSn != null && resolvedSn.isNotEmpty && resolvedSn != sn)
        ? '$sn → $resolvedSn'
        : sn;
    final nextProcessLabel = snMasterInfo == null
        ? ''
        : (snMasterInfo.nextProcessName.isNotEmpty
              ? snMasterInfo.nextProcessName
              : snMasterInfo.nextProcessCode);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: _MarqueeText(
                  key: ValueKey('records_header_$snLabel'),
                  text:
                      '${Translations.get('records_for', lang)}: $snLabel$countSuffix',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: theme.isDark ? Colors.black87 : Colors.white70,
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
              if (nextProcessLabel.isNotEmpty) ...[
                const SizedBox(width: 6),
                _buildInfoChip(
                  label: 'Next: $nextProcessLabel',
                  color: Colors.blue.shade600,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 210,
          height: 34,
          child: TextField(
            controller: listState.filterCtrl,
            style: TextStyle(fontSize: 12.5, color: theme.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              hintText: Translations.get('search_placeholder', lang),
              hintStyle: TextStyle(fontSize: 12.5, color: theme.textSecondary),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 16,
                color: theme.textSecondary,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 30,
                minHeight: 30,
              ),
              suffixIcon: listState.filter.isEmpty
                  ? null
                  : InkWell(
                      onTap: () => setState(() {
                        listState.filterCtrl.clear();
                        listState.filter = '';
                      }),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: theme.textSecondary,
                      ),
                    ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 26,
                minHeight: 26,
              ),
              filled: true,
              fillColor: theme.cardBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: theme.isDark ? Colors.white24 : Colors.black12,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue.shade600, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (v) => setState(() => listState.filter = v),
          ),
        ),
        const SizedBox(width: 8),
        _buildSortButton(theme, lang, listState, sortOptions),
      ],
    );
  }

  Widget _buildSortButton(
    ThemeProvider theme,
    String lang,
    _ListViewState listState,
    List<_SortOption> options,
  ) {
    final currentLabel = listState.sortField == null
        ? Translations.get('sort', lang)
        : options.firstWhere((o) => o.key == listState.sortField).label;

    void selectKey(String key) {
      setState(() {
        if (key.isEmpty) {
          listState.sortField = null;
        } else if (listState.sortField == key) {
          listState.sortAsc = !listState.sortAsc;
        } else {
          listState.sortField = key;
          listState.sortAsc = true;
        }
      });
      _closeSortOverlay();
    }

    // Builder gives this exact instance of the button its own BuildContext,
    // so its position can be measured at tap-time via RenderBox. This avoids
    // any shared Key/LayerLink, which would collide (Flutter throws) when
    // AnimatedSwitcher briefly mounts the outgoing and incoming tab/SN view
    // together during a crossfade — both would otherwise render a Sort
    // button for the same _ListViewState at the same time.
    return Builder(
      builder: (buttonContext) {
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (_sortOverlayEntry != null) {
              _closeSortOverlay();
              return;
            }
            final renderBox = buttonContext.findRenderObject() as RenderBox?;
            if (renderBox == null || !renderBox.attached) return;
            _openSortOverlay(
              anchorContext: buttonContext,
              anchorTopLeft: renderBox.localToGlobal(Offset.zero),
              anchorSize: renderBox.size,
              theme: theme,
              lang: lang,
              listState: listState,
              options: options,
              onSelect: selectKey,
            );
          },
          child: Tooltip(
            message: Translations.get('sort', lang),
            child: AnimatedContainer(
              duration: Motion.normal,
              curve: Motion.curveInOut,
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: theme.cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.isDark ? Colors.white24 : Colors.black12,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    listState.sortField == null
                        ? Icons.sort_rounded
                        : (listState.sortAsc
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded),
                    size: 16,
                    color: theme.textPrimary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    currentLabel,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: theme.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _closeSortOverlay() {
    _sortOverlayEntry?.remove();
    _sortOverlayEntry = null;
  }

  /// Custom anchored dropdown for the Sort button, built on a plain
  /// OverlayEntry instead of PopupMenuButton, because the standard
  /// PopupMenuButton route has no hook to inject a BackdropFilter behind its
  /// content. Position is computed once at open-time from the button's
  /// RenderBox (right-aligned to the button so it never overflows the
  /// window edge) rather than followed live via CompositedTransformFollower,
  /// since the latter requires a LayerLink unique to one mounted widget at a
  /// time — a constraint AnimatedSwitcher's transient dual-mount during a
  /// crossfade would violate.
  ///
  /// The blur/opacity here follow the user's "Popup Blur/Opacity" Advanced
  /// Settings (logic.dialogBlur/dialogOpacity). This app's modal dialogs are
  /// deliberately kept solid-opaque (see CHANGELOG v2.1.0: glass dialogs
  /// previously caused see-through overlapping text), so only this
  /// lightweight anchored dropdown uses the setting for now.
  void _openSortOverlay({
    required BuildContext anchorContext,
    required Offset anchorTopLeft,
    required Size anchorSize,
    required ThemeProvider theme,
    required String lang,
    required _ListViewState listState,
    required List<_SortOption> options,
    required void Function(String key) onSelect,
  }) {
    _closeSortOverlay();
    final logic = context.read<AppLogic>();
    // Floor the blur whenever the panel isn't fully solid — an unblurred,
    // translucent panel over the live scrolling record list is exactly the
    // "see-through overlapping text" glitch CHANGELOG v2.1.0 deliberately
    // eliminated from dialogs; the two Advanced Settings sliders are
    // independent, so this has to be enforced here rather than in the UI.
    final rawBlur = logic.dialogBlur;
    final opacity = logic.dialogOpacity;
    final effectiveBlur = opacity < 1.0 && rawBlur < 6.0 ? 6.0 : rawBlur;
    final borderColor = theme.isDark ? Colors.white24 : Colors.black12;
    final screenWidth = MediaQuery.of(context).size.width;
    final top = anchorTopLeft.dy + anchorSize.height + 4;
    final right = screenWidth - (anchorTopLeft.dx + anchorSize.width);

    final menuContent = _buildSortMenuList(
      theme: theme,
      lang: lang,
      listState: listState,
      options: options,
      onSelect: onSelect,
    );

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _closeSortOverlay,
              ),
            ),
            Positioned(
              top: top,
              right: right,
              // The blur sigma and container alpha are animated as their own
              // native parameters (not by wrapping the finished BackdropFilter
              // in an outer Opacity/Transform), since animating opacity/scale
              // directly around a live BackdropFilter is a known source of
              // stale/ghosted backdrop sampling mid-transition — plausibly
              // the very defect CHANGELOG v2.1.0 hit with the old glass
              // dialogs. Only the inner content fades/scales, safely after
              // the backdrop sampling has already happened for this frame.
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Motion.normal,
                curve: Motion.curveOut,
                builder: (context, v, child) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(
                      sigmaX: effectiveBlur * v,
                      sigmaY: effectiveBlur * v,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.cardBg.withValues(alpha: opacity * v),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: borderColor.withValues(alpha: v),
                        ),
                      ),
                      child: Opacity(
                        opacity: v,
                        child: Transform.scale(
                          scale: 0.96 + (0.04 * v),
                          alignment: Alignment.topRight,
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
                child: menuContent,
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(anchorContext).insert(entry);
    _sortOverlayEntry = entry;
  }

  /// The Sort dropdown's row list (Default + each field), sized to its
  /// content and wrapped for InkWell ink support — extracted so the
  /// animated glass shell in _openSortOverlay doesn't nest past the
  /// project's 4-level widget guideline.
  Widget _buildSortMenuList({
    required ThemeProvider theme,
    required String lang,
    required _ListViewState listState,
    required List<_SortOption> options,
    required void Function(String key) onSelect,
  }) {
    return Material(
      color: Colors.transparent,
      child: IntrinsicWidth(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 180),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSortMenuRow(
                theme: theme,
                icon: Icons.sort_rounded,
                label: Translations.get('default', lang),
                selected: listState.sortField == null,
                onTap: () => onSelect(''),
              ),
              ...options.map(
                (o) => _buildSortMenuRow(
                  theme: theme,
                  icon: o.icon,
                  label: o.label,
                  selected: listState.sortField == o.key,
                  sortAsc: listState.sortAsc,
                  onTap: () => onSelect(o.key),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A single row inside the sort dropdown, styled to match the rest of the
  /// app's selectable-chip language (rounded blue-tinted highlight when
  /// active, e.g. the sidebar's selected SN row or the view-mode tab pills)
  /// instead of Flutter's plain default PopupMenuItem look.
  Widget _buildSortMenuRow({
    required ThemeProvider theme,
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool? sortAsc,
  }) {
    final accent = theme.isDark ? Colors.blue.shade300 : Colors.blue.shade700;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? accent : theme.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: selected ? accent : theme.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (selected && sortAsc != null) ...[
              const SizedBox(width: 8),
              Icon(
                sortAsc
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 14,
                color: accent,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    ThemeProvider theme, {
    bool highlight = false,
  }) {
    if (value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: theme.textSecondary, fontSize: 13),
          ),
          if (highlight)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.isDark
                    ? Colors.blue.withValues(alpha: 0.2)
                    : Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: theme.isDark
                      ? Colors.blue.shade200
                      : Colors.blue.shade700,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            Expanded(
              child: Text(
                value,
                style: TextStyle(color: theme.textPrimary, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  void _showSettingsDialog(
    BuildContext context,
    AppLogic logic,
    ThemeProvider theme,
  ) {
    final TextEditingController tokenCtrl = TextEditingController(
      text: logic.token,
    );
    final TextEditingController langCtrl = TextEditingController(
      text: logic.lang,
    );
    final TextEditingController operationIdCtrl = TextEditingController(
      text: logic.operationId,
    );
    final TextEditingController uuidCtrl = TextEditingController(
      text: logic.uuid,
    );
    final TextEditingController cookieCtrl = TextEditingController(
      text: logic.cookie,
    );

    bool isExpanded = false;
    int settingsTabIndex = 0;
    bool isVerifying = false;
    // null = idle, true = last verify succeeded, false = last verify failed.
    // Drives the verify-connection icon's check/cross animation; auto-reverts
    // to null a few seconds after a result lands (see onPressed below).
    bool? verifyOk;
    String verifyTooltip = Translations.get('verify_connection', logic.lang);
    bool isFetchingCdp = false;
    bool isGlassExpanded = true;
    double bgBlur = logic.bgBlur;
    double bgOpacity = logic.bgOpacity;
    double dialogBlur = logic.dialogBlur;
    double dialogOpacity = logic.dialogOpacity;

    Widget buildField(
      String label,
      TextEditingController ctrl, {
      int maxLines = 1,
      String? hint,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 5),
            TextField(
              controller: ctrl,
              style: TextStyle(color: theme.textPrimary, fontSize: 13),
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: theme.textSecondary.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
                filled: true,
                fillColor: theme.isDark
                    ? const Color(0xFF1E1F22)
                    : const Color(0xFFF2F4F7),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.blue.shade600,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // One row inside the "Customize blur & transparency" section: a
    // label + live value on top, a Slider below — mirrors the JA_Compare
    // reference app's Advanced Settings layout (Main background blur/
    // opacity, Dialog blur/opacity).
    Widget buildGlassSlider({
      required String label,
      required double value,
      required double min,
      required double max,
      bool isPercent = false,
      required ValueChanged<double> onChanged,
    }) {
      final display = isPercent
          ? '${(value * 100).round()}%'
          : '${value.toStringAsFixed(0)}px';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(color: theme.textPrimary, fontSize: 12),
                  ),
                ),
                Text(
                  display,
                  style: TextStyle(color: theme.textSecondary, fontSize: 11),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: isPercent ? 18 : 30,
                activeColor: Colors.blue.shade600,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      );
    }

    Widget buildSettingsTabButton({
      required IconData icon,
      required String label,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: AnimatedContainer(
              duration: Motion.fast,
              curve: Motion.curveInOut,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.blue.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: selected
                        ? Colors.blue.shade600
                        : theme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? Colors.blue.shade600
                            : theme.textSecondary,
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget buildAboutTab() {
      return SingleChildScrollView(
        key: const ValueKey('about-tab'),
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.settings_suggest_rounded,
                      color: Colors.blue.shade600,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    appName,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'v$appVersion',
                    style: TextStyle(color: theme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              Translations.get('about_detail', logic.lang),
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '© 2026 JA Tech.\nAll rights reserved.',
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    Widget buildUserGuideTab() {
      return SingleChildScrollView(
        key: const ValueKey('user-guide-tab'),
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Text(
          Translations.get('user_guide_detail', logic.lang),
          style: TextStyle(color: theme.textPrimary, fontSize: 13, height: 1.5),
        ),
      );
    }

    _showIosDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Live-preview the dialogBlur/dialogOpacity sliders on this very
            // dialog (matches JA_Compare's GlassDialog behavior). Floor of
            // 6px blur whenever opacity < 1.0 prevents the see-through
            // overlapping-text glitch fixed in CHANGELOG v2.1.0.
            final effectiveBlur = (dialogOpacity < 1.0 && dialogBlur < 6.0)
                ? 6.0
                : dialogBlur;
            final settingsContentHeight = settingsTabIndex == 0 && !isExpanded
                ? 190.0
                : 430.0;
            return Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(
                      sigmaX: effectiveBlur,
                      sigmaY: effectiveBlur,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor:
                      (theme.isDark ? const Color(0xFF2B2D30) : Colors.white)
                          .withValues(alpha: dialogOpacity),
                  titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.settings_suggest_rounded,
                          color: Colors.blue.shade600,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        Translations.get('settings', logic.lang),
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      // Connection Health Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (logic.isConnectionValid ?? false)
                              ? Colors.green.withValues(alpha: 0.12)
                              : Colors.amber.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: (logic.isConnectionValid ?? false)
                                ? Colors.green.withValues(alpha: 0.3)
                                : Colors.amber.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (logic.isConnectionValid ?? false)
                                    ? Colors.green
                                    : Colors.amber.shade700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              (logic.isConnectionValid ?? false)
                                  ? Translations.get(
                                      'status_connected',
                                      logic.lang,
                                    )
                                  : Translations.get(
                                      'status_check',
                                      logic.lang,
                                    ),
                              style: TextStyle(
                                color: (logic.isConnectionValid ?? false)
                                    ? Colors.green.shade700
                                    : Colors.amber.shade800,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: 480,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.sidebarBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              buildSettingsTabButton(
                                icon: Icons.tune_rounded,
                                label: Translations.get(
                                  'advanced_settings',
                                  logic.lang,
                                ),
                                selected: settingsTabIndex == 0,
                                onTap: () =>
                                    setDialogState(() => settingsTabIndex = 0),
                              ),
                              buildSettingsTabButton(
                                icon: Icons.menu_book_rounded,
                                label: Translations.get(
                                  'user_guide',
                                  logic.lang,
                                ),
                                selected: settingsTabIndex == 1,
                                onTap: () =>
                                    setDialogState(() => settingsTabIndex = 1),
                              ),
                              buildSettingsTabButton(
                                icon: Icons.info_outline_rounded,
                                label: Translations.get('about', logic.lang),
                                selected: settingsTabIndex == 2,
                                onTap: () =>
                                    setDialogState(() => settingsTabIndex = 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        AnimatedSize(
                          duration: Motion.normal,
                          curve: Motion.curveInOut,
                          child: SizedBox(
                            height: settingsContentHeight,
                            child: AnimatedSwitcher(
                              duration: Motion.normal,
                              switchInCurve: Motion.curveOut,
                              switchOutCurve: Motion.curveIn,
                              layoutBuilder: (currentChild, previousChildren) =>
                                  Stack(
                                    alignment: Alignment.topCenter,
                                    children: [
                                      ...previousChildren,
                                      ?currentChild,
                                    ],
                                  ),
                              child: settingsTabIndex == 1
                                  ? buildUserGuideTab()
                                  : settingsTabIndex == 2
                                  ? buildAboutTab()
                                  : SingleChildScrollView(
                                      key: const ValueKey('advanced-tab'),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 10),

                                          // Smart 2-Step Auto Sync Card
                                          Container(
                                            padding: const EdgeInsets.all(14),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: theme.isDark
                                                    ? [
                                                        const Color(0xFF1E2638),
                                                        const Color(0xFF1A2130),
                                                      ]
                                                    : [
                                                        const Color(0xFFEBF3FE),
                                                        const Color(0xFFF4F8FE),
                                                      ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.blue.withValues(
                                                  alpha: 0.2,
                                                ),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.bolt_rounded,
                                                      color:
                                                          Colors.blue.shade600,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      Translations.get(
                                                        'cdp_sync_title',
                                                        logic.lang,
                                                      ),
                                                      style: TextStyle(
                                                        color:
                                                            theme.textPrimary,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  Translations.get(
                                                    'cdp_sync_desc',
                                                    logic.lang,
                                                  ),
                                                  style: TextStyle(
                                                    color: theme.textSecondary,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: ElevatedButton.icon(
                                                        icon: const Icon(
                                                          Icons
                                                              .open_in_browser_rounded,
                                                          size: 16,
                                                        ),
                                                        label: Text(
                                                          Translations.get(
                                                            'btn_open_browser',
                                                            logic.lang,
                                                          ),
                                                        ),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors
                                                                  .blue
                                                                  .shade600,
                                                          foregroundColor:
                                                              Colors.white,
                                                          elevation: 0,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 10,
                                                              ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                          textStyle:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                        onPressed: () async {
                                                          await BrowserHelper.launchBrowser();
                                                        },
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: ElevatedButton.icon(
                                                        icon: isFetchingCdp
                                                            ? const SizedBox(
                                                                width: 14,
                                                                height: 14,
                                                                child: CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                              )
                                                            : const Icon(
                                                                Icons
                                                                    .sync_rounded,
                                                                size: 16,
                                                              ),
                                                        label: Text(
                                                          isFetchingCdp
                                                              ? Translations.get(
                                                                  'status_fetching',
                                                                  logic.lang,
                                                                )
                                                              : Translations.get(
                                                                  'btn_sync_credentials',
                                                                  logic.lang,
                                                                ),
                                                        ),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors
                                                                  .teal
                                                                  .shade600,
                                                          foregroundColor:
                                                              Colors.white,
                                                          elevation: 0,
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 10,
                                                              ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                          textStyle:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                        onPressed: isFetchingCdp
                                                            ? null
                                                            : () async {
                                                                setDialogState(
                                                                  () =>
                                                                      isFetchingCdp =
                                                                          true,
                                                                );
                                                                final creds =
                                                                    await BrowserHelper.fetchCredentialsFromBrowser();
                                                                setDialogState(
                                                                  () =>
                                                                      isFetchingCdp =
                                                                          false,
                                                                );

                                                                if (!context
                                                                    .mounted) {
                                                                  return;
                                                                }
                                                                if (creds !=
                                                                    null) {
                                                                  if (creds.token !=
                                                                          null &&
                                                                      creds
                                                                          .token!
                                                                          .isNotEmpty) {
                                                                    tokenCtrl
                                                                        .text = creds
                                                                        .token!;
                                                                  }
                                                                  if (creds.operationId !=
                                                                          null &&
                                                                      creds
                                                                          .operationId!
                                                                          .isNotEmpty) {
                                                                    operationIdCtrl
                                                                        .text = creds
                                                                        .operationId!;
                                                                  }
                                                                  if (creds.uuid !=
                                                                          null &&
                                                                      creds
                                                                          .uuid!
                                                                          .isNotEmpty) {
                                                                    uuidCtrl
                                                                        .text = creds
                                                                        .uuid!;
                                                                  }
                                                                  if (creds.cookie !=
                                                                          null &&
                                                                      creds
                                                                          .cookie!
                                                                          .isNotEmpty) {
                                                                    cookieCtrl
                                                                        .text = creds
                                                                        .cookie!;
                                                                  }

                                                                  ScaffoldMessenger.of(
                                                                    context,
                                                                  ).showSnackBar(
                                                                    SnackBar(
                                                                      content: Text(
                                                                        Translations.get(
                                                                          'fetched_success',
                                                                          logic
                                                                              .lang,
                                                                        ),
                                                                      ),
                                                                      backgroundColor:
                                                                          Colors
                                                                              .green,
                                                                    ),
                                                                  );
                                                                } else {
                                                                  ScaffoldMessenger.of(
                                                                    context,
                                                                  ).showSnackBar(
                                                                    SnackBar(
                                                                      content: Text(
                                                                        Translations.get(
                                                                          'fetched_fail',
                                                                          logic
                                                                              .lang,
                                                                        ),
                                                                      ),
                                                                      backgroundColor:
                                                                          Colors
                                                                              .red,
                                                                    ),
                                                                  );
                                                                }
                                                              },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          const SizedBox(height: 12),

                                          // Sleek Toggle Button for Advanced Options
                                          Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () {
                                                setDialogState(() {
                                                  isExpanded = !isExpanded;
                                                });
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 12,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: theme.isDark
                                                      ? const Color(0xFF1E1F22)
                                                      : const Color(0xFFF7F9FC),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: isExpanded
                                                        ? Colors.blue.shade600
                                                        : (theme.isDark
                                                              ? Colors.white10
                                                              : Colors.black
                                                                    .withValues(
                                                                      alpha:
                                                                          0.08,
                                                                    )),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.tune_rounded,
                                                      size: 18,
                                                      color: isExpanded
                                                          ? Colors.blue.shade600
                                                          : theme.textSecondary,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        isExpanded
                                                            ? Translations.get(
                                                                'hide_advanced',
                                                                logic.lang,
                                                              )
                                                            : Translations.get(
                                                                'show_advanced',
                                                                logic.lang,
                                                              ),
                                                        style: TextStyle(
                                                          color: isExpanded
                                                              ? Colors
                                                                    .blue
                                                                    .shade600
                                                              : theme
                                                                    .textPrimary,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                    Icon(
                                                      isExpanded
                                                          ? Icons
                                                                .keyboard_arrow_up_rounded
                                                          : Icons
                                                                .keyboard_arrow_down_rounded,
                                                      color: isExpanded
                                                          ? Colors.blue.shade600
                                                          : theme.textSecondary,
                                                      size: 20,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),

                                          // Expandable Section
                                          AnimatedCrossFade(
                                            firstChild: const SizedBox.shrink(),
                                            secondChild: Padding(
                                              padding: const EdgeInsets.only(
                                                top: 12.0,
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  14,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: theme.isDark
                                                      ? const Color(0xFF1E1F22)
                                                      : const Color(0xFFF8FAFC),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: theme.isDark
                                                        ? Colors.white10
                                                        : Colors.black
                                                              .withValues(
                                                                alpha: 0.06,
                                                              ),
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Parse Raw Header Button
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: OutlinedButton.icon(
                                                        icon: const Icon(
                                                          Icons
                                                              .content_paste_rounded,
                                                          size: 16,
                                                        ),
                                                        label: Text(
                                                          Translations.get(
                                                            'paste_raw_http',
                                                            logic.lang,
                                                          ),
                                                        ),
                                                        style: OutlinedButton.styleFrom(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 10,
                                                              ),
                                                          side: BorderSide(
                                                            color: Colors
                                                                .blue
                                                                .shade600
                                                                .withValues(
                                                                  alpha: 0.4,
                                                                ),
                                                          ),
                                                          foregroundColor:
                                                              Colors
                                                                  .blue
                                                                  .shade600,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  8,
                                                                ),
                                                          ),
                                                          textStyle:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                        onPressed: () {
                                                          final TextEditingController
                                                          pasteCtrl =
                                                              TextEditingController();
                                                          _showIosDialog(
                                                            context: context,
                                                            builder: (ctx) => AlertDialog(
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      14,
                                                                    ),
                                                              ),
                                                              backgroundColor:
                                                                  theme.isDark
                                                                  ? const Color(
                                                                      0xFF2B2D30,
                                                                    )
                                                                  : Colors
                                                                        .white,
                                                              title: Text(
                                                                Translations.get(
                                                                  'paste_raw_http',
                                                                  logic.lang,
                                                                ),
                                                                style: TextStyle(
                                                                  color: theme
                                                                      .textPrimary,
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              content: SizedBox(
                                                                width: 450,
                                                                child: TextField(
                                                                  controller:
                                                                      pasteCtrl,
                                                                  maxLines: 10,
                                                                  style: TextStyle(
                                                                    color: theme
                                                                        .textPrimary,
                                                                    fontSize:
                                                                        12,
                                                                  ),
                                                                  decoration: InputDecoration(
                                                                    hintText:
                                                                        'GET /api/... HTTP/1.1\nAuthorization: bearer ...\nCookie: ...',
                                                                    hintStyle: TextStyle(
                                                                      color: theme
                                                                          .textSecondary
                                                                          .withValues(
                                                                            alpha:
                                                                                0.6,
                                                                          ),
                                                                    ),
                                                                    filled:
                                                                        true,
                                                                    fillColor: theme
                                                                        .sidebarBg,
                                                                    border: OutlineInputBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                            8,
                                                                          ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () =>
                                                                      Navigator.pop(
                                                                        ctx,
                                                                      ),
                                                                  child: Text(
                                                                    Translations.get(
                                                                      'cancel',
                                                                      logic
                                                                          .lang,
                                                                    ),
                                                                  ),
                                                                ),
                                                                ElevatedButton(
                                                                  onPressed: () {
                                                                    final creds =
                                                                        BrowserHelper.parseRawHttpRequest(
                                                                          pasteCtrl
                                                                              .text,
                                                                        );
                                                                    if (creds.token !=
                                                                            null &&
                                                                        creds
                                                                            .token!
                                                                            .isNotEmpty) {
                                                                      tokenCtrl
                                                                          .text = creds
                                                                          .token!;
                                                                    }
                                                                    if (creds.lang !=
                                                                            null &&
                                                                        creds
                                                                            .lang!
                                                                            .isNotEmpty) {
                                                                      langCtrl
                                                                          .text = creds
                                                                          .lang!;
                                                                    }
                                                                    if (creds.operationId !=
                                                                            null &&
                                                                        creds
                                                                            .operationId!
                                                                            .isNotEmpty) {
                                                                      operationIdCtrl
                                                                          .text = creds
                                                                          .operationId!;
                                                                    }
                                                                    if (creds.uuid !=
                                                                            null &&
                                                                        creds
                                                                            .uuid!
                                                                            .isNotEmpty) {
                                                                      uuidCtrl
                                                                          .text = creds
                                                                          .uuid!;
                                                                    }
                                                                    if (creds.cookie !=
                                                                            null &&
                                                                        creds
                                                                            .cookie!
                                                                            .isNotEmpty) {
                                                                      cookieCtrl
                                                                          .text = creds
                                                                          .cookie!;
                                                                    }

                                                                    Navigator.pop(
                                                                      ctx,
                                                                    );
                                                                    ScaffoldMessenger.of(
                                                                      context,
                                                                    ).showSnackBar(
                                                                      SnackBar(
                                                                        content: Text(
                                                                          Translations.get(
                                                                            'fetched_success',
                                                                            logic.lang,
                                                                          ),
                                                                        ),
                                                                        backgroundColor:
                                                                            Colors.green,
                                                                      ),
                                                                    );
                                                                  },
                                                                  style: ElevatedButton.styleFrom(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .blue
                                                                            .shade600,
                                                                  ),
                                                                  child: Text(
                                                                    Translations.get(
                                                                      'parse_http',
                                                                      logic
                                                                          .lang,
                                                                    ),
                                                                    style: const TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    const SizedBox(height: 14),
                                                    buildField(
                                                      Translations.get(
                                                        'mes_token',
                                                        logic.lang,
                                                      ),
                                                      tokenCtrl,
                                                      maxLines: 2,
                                                      hint:
                                                          'Bearer token string',
                                                    ),
                                                    buildField(
                                                      Translations.get(
                                                        'cookie',
                                                        logic.lang,
                                                      ),
                                                      cookieCtrl,
                                                      maxLines: 2,
                                                      hint:
                                                          'cultureName=...; CloudMES_Token=...',
                                                    ),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: buildField(
                                                            Translations.get(
                                                              'operation_id',
                                                              logic.lang,
                                                            ),
                                                            operationIdCtrl,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          width: 10,
                                                        ),
                                                        Expanded(
                                                          child: buildField(
                                                            Translations.get(
                                                              'uuid',
                                                              logic.lang,
                                                            ),
                                                            uuidCtrl,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    buildField(
                                                      Translations.get(
                                                        'language',
                                                        logic.lang,
                                                      ),
                                                      langCtrl,
                                                      hint:
                                                          'en / vi-VN / zh-CN',
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      Translations.get(
                                                        'glass_settings_title',
                                                        logic.lang,
                                                      ),
                                                      style: TextStyle(
                                                        color:
                                                            theme.textPrimary,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    Theme(
                                                      data: Theme.of(context)
                                                          .copyWith(
                                                            dividerColor: Colors
                                                                .transparent,
                                                          ),
                                                      child: ExpansionTile(
                                                        initiallyExpanded:
                                                            isGlassExpanded,
                                                        tilePadding:
                                                            EdgeInsets.zero,
                                                        childrenPadding:
                                                            EdgeInsets.zero,
                                                        collapsedIconColor:
                                                            theme.textSecondary,
                                                        iconColor: Colors
                                                            .blue
                                                            .shade600,
                                                        onExpansionChanged:
                                                            (
                                                              v,
                                                            ) => setDialogState(
                                                              () =>
                                                                  isGlassExpanded =
                                                                      v,
                                                            ),
                                                        title: Text(
                                                          Translations.get(
                                                            'glass_customize',
                                                            logic.lang,
                                                          ),
                                                          style: TextStyle(
                                                            color: theme
                                                                .textSecondary,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        children: [
                                                          buildGlassSlider(
                                                            label:
                                                                Translations.get(
                                                                  'bg_blur_label',
                                                                  logic.lang,
                                                                ),
                                                            value: bgBlur,
                                                            min: 0,
                                                            max: 30,
                                                            onChanged: (v) =>
                                                                setDialogState(
                                                                  () => bgBlur =
                                                                      v,
                                                                ),
                                                          ),
                                                          buildGlassSlider(
                                                            label: Translations.get(
                                                              'bg_opacity_label',
                                                              logic.lang,
                                                            ),
                                                            value: bgOpacity,
                                                            min: 0.1,
                                                            max: 1.0,
                                                            isPercent: true,
                                                            onChanged: (v) =>
                                                                setDialogState(
                                                                  () =>
                                                                      bgOpacity =
                                                                          v,
                                                                ),
                                                          ),
                                                          buildGlassSlider(
                                                            label:
                                                                Translations.get(
                                                                  'dialog_blur',
                                                                  logic.lang,
                                                                ),
                                                            value: dialogBlur,
                                                            min: 0,
                                                            max: 30,
                                                            onChanged: (v) =>
                                                                setDialogState(
                                                                  () =>
                                                                      dialogBlur =
                                                                          v,
                                                                ),
                                                          ),
                                                          buildGlassSlider(
                                                            label: Translations.get(
                                                              'dialog_opacity',
                                                              logic.lang,
                                                            ),
                                                            value:
                                                                dialogOpacity,
                                                            min: 0.3,
                                                            max: 1.0,
                                                            isPercent: true,
                                                            onChanged: (v) =>
                                                                setDialogState(
                                                                  () =>
                                                                      dialogOpacity =
                                                                          v,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            crossFadeState: isExpanded
                                                ? CrossFadeState.showSecond
                                                : CrossFadeState.showFirst,
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                          ),

                                          const SizedBox(height: 10),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actionsAlignment: MainAxisAlignment.spaceBetween,
                  actions: [
                    // Left aligned items
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'v$appVersion',
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: verifyTooltip,
                          child: IconButton(
                            icon: AnimatedSwitcher(
                              duration: Motion.normal,
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(
                                    scale: anim,
                                    child: FadeTransition(
                                      opacity: anim,
                                      child: child,
                                    ),
                                  ),
                              child: isVerifying
                                  ? const SizedBox(
                                      key: ValueKey('verifying'),
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : verifyOk == true
                                  ? Icon(
                                      Icons.check_circle,
                                      key: const ValueKey('ok'),
                                      size: 18,
                                      color: theme.passColor,
                                    )
                                  : verifyOk == false
                                  ? Icon(
                                      Icons.cancel,
                                      key: const ValueKey('fail'),
                                      size: 18,
                                      color: theme.failColor,
                                    )
                                  : Icon(
                                      Icons.verified_outlined,
                                      key: const ValueKey('idle'),
                                      size: 18,
                                      color: Colors.blue.shade600,
                                    ),
                            ),
                            onPressed: isVerifying
                                ? null
                                : () async {
                                    setDialogState(() {
                                      isVerifying = true;
                                      verifyOk = null;
                                    });
                                    final res = await logic.verifySettings(
                                      tokenCtrl.text,
                                      langCtrl.text,
                                      operationIdCtrl.text,
                                      uuidCtrl.text,
                                      cookieCtrl.text,
                                    );
                                    if (!context.mounted) return;
                                    setDialogState(() {
                                      isVerifying = false;
                                      verifyOk = res == null;
                                      verifyTooltip = res == null
                                          ? Translations.get(
                                              'connection_valid',
                                              logic.lang,
                                            )
                                          : 'Invalid: $res';
                                    });
                                    // Auto-revert the icon back to idle a few
                                    // seconds after the result lands, since
                                    // ScaffoldMessenger SnackBars anchor to
                                    // the main window's Scaffold and render
                                    // BEHIND this dialog's modal barrier —
                                    // invisible to the user. The icon itself
                                    // (plus its tooltip) is the only reliably
                                    // visible feedback while this dialog is open.
                                    Future.delayed(
                                      const Duration(seconds: 3),
                                      () {
                                        if (!context.mounted) return;
                                        setDialogState(() {
                                          verifyOk = null;
                                          verifyTooltip = Translations.get(
                                            'verify_connection',
                                            logic.lang,
                                          );
                                        });
                                      },
                                    );
                                  },
                          ),
                        ),
                      ],
                    ),
                    // Right aligned buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () {
                            tokenCtrl.text = defaultToken;
                            operationIdCtrl.text = defaultOperationId;
                            uuidCtrl.text = defaultUuid;
                            cookieCtrl.text = defaultCookie;
                            langCtrl.text = 'en';
                            setDialogState(() {
                              bgBlur = 10.0;
                              bgOpacity = 0.6;
                              dialogBlur = 12.0;
                              dialogOpacity = 0.75;
                            });
                          },
                          child: Text(
                            Translations.get('default', logic.lang),
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            Translations.get('cancel', logic.lang),
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton(
                          onPressed: () {
                            logic.updateSettings(
                              token: tokenCtrl.text,
                              lang: langCtrl.text,
                              operationId: operationIdCtrl.text,
                              uuid: uuidCtrl.text,
                              cookie: cookieCtrl.text,
                              bgBlur: bgBlur,
                              bgOpacity: bgOpacity,
                              dialogBlur: dialogBlur,
                              dialogOpacity: dialogOpacity,
                            );
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            Translations.get('save', logic.lang),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTokenExpiredWarningDialog(BuildContext context, AppLogic logic) {
    final theme = context.read<ThemeProvider>();
    bool isSyncing = false;

    _showIosDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: theme.isDark
                  ? const Color(0xFF2B2D30)
                  : Colors.white,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber.shade900,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      Translations.get('token_expired_title', logic.lang),
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Translations.get('token_expired_desc', logic.lang),
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2-Step Sync Wizard Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.isDark
                            ? Colors.blue.withValues(alpha: 0.08)
                            : Colors.blue.shade50.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.isDark
                              ? Colors.blue.withValues(alpha: 0.2)
                              : Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.bolt,
                                color: Colors.blue.shade700,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                Translations.get('cdp_sync_title', logic.lang),
                                style: TextStyle(
                                  color: theme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Translations.get('cdp_sync_desc', logic.lang),
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await BrowserHelper.launchBrowser();
                                  },
                                  icon: const Icon(
                                    Icons.open_in_browser,
                                    size: 16,
                                  ),
                                  label: Text(
                                    Translations.get(
                                      'btn_open_browser',
                                      logic.lang,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: isSyncing
                                      ? null
                                      : () async {
                                          setDialogState(
                                            () => isSyncing = true,
                                          );
                                          final creds =
                                              await BrowserHelper.fetchCredentialsFromBrowser();
                                          setDialogState(
                                            () => isSyncing = false,
                                          );

                                          if (creds != null) {
                                            await logic.updateSettings(
                                              token:
                                                  (creds.token != null &&
                                                      creds.token!.isNotEmpty)
                                                  ? creds.token!
                                                  : logic.token,
                                              lang: logic.lang,
                                              operationId:
                                                  (creds.operationId != null &&
                                                      creds
                                                          .operationId!
                                                          .isNotEmpty)
                                                  ? creds.operationId!
                                                  : logic.operationId,
                                              uuid:
                                                  (creds.uuid != null &&
                                                      creds.uuid!.isNotEmpty)
                                                  ? creds.uuid!
                                                  : logic.uuid,
                                              cookie:
                                                  (creds.cookie != null &&
                                                      creds.cookie!.isNotEmpty)
                                                  ? creds.cookie!
                                                  : logic.cookie,
                                            );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    Translations.get(
                                                      'fetched_success',
                                                      logic.lang,
                                                    ),
                                                    style: const TextStyle(
                                                      color: Colors.greenAccent,
                                                    ),
                                                  ),
                                                  duration: const Duration(
                                                    seconds: 2,
                                                  ),
                                                ),
                                              );
                                              Navigator.pop(ctx);
                                            }
                                          } else {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    Translations.get(
                                                      'fetched_fail',
                                                      logic.lang,
                                                    ),
                                                    style: TextStyle(
                                                      color: theme.failColor,
                                                    ),
                                                  ),
                                                  duration: const Duration(
                                                    seconds: 3,
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                  icon: isSyncing
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.sync_rounded,
                                          size: 16,
                                        ),
                                  label: Text(
                                    isSyncing
                                        ? Translations.get(
                                            'status_fetching',
                                            logic.lang,
                                          )
                                        : Translations.get(
                                            'btn_sync_credentials',
                                            logic.lang,
                                          ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal.shade700,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showSettingsDialog(context, logic, theme);
                  },
                  icon: const Icon(Icons.settings, size: 15),
                  label: Text(
                    Translations.get('open_settings', logic.lang),
                    style: TextStyle(color: Colors.blue.shade600, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    Translations.get('cancel', logic.lang),
                    style: TextStyle(color: theme.textSecondary, fontSize: 12),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// A compact icon-only chip that expands to reveal its label on hover.
/// When [keepExpanded] is true (item selected, or window maximized), the
/// label stays shown permanently and hover has no further effect —
/// Dynamic-Island-style reveal animation otherwise.
/// Per-tab search filter + sort field/direction, kept as plain mutable state
/// (not persisted) since it's a pure display convenience per list view.
class _ListViewState {
  final TextEditingController filterCtrl = TextEditingController();
  String filter = '';
  String? sortField;
  bool sortAsc = true;
  // Item identities that have already played their stagger entrance
  // animation, so scrolling an item out of the cacheExtent and back in
  // (which disposes and recreates its Element) doesn't replay it.
  final Set<String> animatedItemKeys = {};
}

class _SortOption {
  final String key;
  final String label;
  final IconData icon;
  const _SortOption(
    this.key,
    this.label, {
    this.icon = Icons.short_text_rounded,
  });
}

/// Cascades list items in on first appearance (iOS table-view style):
/// each item's fade/slide-in duration grows slightly with its index, so
/// later items visibly settle after earlier ones. [itemKey] identifies the
/// record (stable content-based id, not raw index) — once an id has played
/// its entrance animation it's recorded in [animatedKeys] (owned by the
/// tab's _ListViewState, so it survives filter/sort rebuilds), and any
/// later Element recreated for that same id — e.g. after scrolling it out
/// of the ListView's cacheExtent and back into view — renders directly at
/// its resting state instead of replaying the animation.
class _StaggeredItem extends StatefulWidget {
  final String itemKey;
  final int index;
  final Widget child;
  final Set<String> animatedKeys;
  const _StaggeredItem({
    super.key,
    required this.itemKey,
    required this.index,
    required this.child,
    required this.animatedKeys,
  });

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem> {
  late final bool _shouldAnimate = widget.animatedKeys.add(widget.itemKey);

  @override
  Widget build(BuildContext context) {
    if (!_shouldAnimate) return widget.child;
    final extraDelay = (widget.index * 20).clamp(0, 300);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Motion.normal + Duration(milliseconds: extraDelay),
      curve: Motion.curveOut,
      builder: (context, value, builtChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: builtChild,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _HoverChip extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final Color? hoverBackground;
  final BoxBorder? border;
  final bool keepExpanded;
  final VoidCallback onTap;

  const _HoverChip({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    this.hoverBackground,
    this.border,
    this.keepExpanded = false,
    required this.onTap,
  });

  @override
  State<_HoverChip> createState() => _HoverChipState();
}

class _HoverChipState extends State<_HoverChip> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final expanded = widget.keepExpanded || _isHovering;
    final bgColor =
        !widget.keepExpanded && _isHovering && widget.hoverBackground != null
        ? widget.hoverBackground!
        : widget.background;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(17),
            border: widget.border,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: widget.foreground),
              ClipRect(
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  widthFactor: expanded ? 1.0 : 0.0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 6.0),
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        color: widget.foreground,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontally auto-scrolls [text] when it overflows the space given to
/// this widget, instead of clipping it with an ellipsis — per the
/// `dart-build-pro` skill's Marquee spec: a slow, readable scroll out to
/// the end, then a quick snap back to the start (asymmetric, not a
/// symmetric back-and-forth). Relies on
/// `SingleChildScrollView.position.maxScrollExtent` (computed by Flutter
/// from the real layout) rather than manually measuring text width, which
/// has repeatedly proven unreliable for this exact use case.
class _MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const _MarqueeText({super.key, required this.text, required this.style});

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runLoop());
  }

  Future<void> _runLoop() async {
    if (!mounted || !_scrollController.hasClients) return;
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted || !_scrollController.hasClients) return;

    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    if (maxScrollExtent <= 0) return; // fits within the box, nothing to do

    // Asymmetric on purpose: slow, readable linear scroll out to the end,
    // then a quick easeOut snap back to the start — not a symmetric back-
    // and-forth. Forward duration scales with text length so longer labels
    // don't fly by; the return trip is a fixed short duration regardless.
    while (mounted) {
      await _scrollController.animateTo(
        maxScrollExtent,
        duration: Duration(milliseconds: widget.text.length * 60),
        curve: Curves.linear,
      );
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOut,
      );
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 1500));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(widget.text, style: widget.style, maxLines: 1),
    );
  }
}
