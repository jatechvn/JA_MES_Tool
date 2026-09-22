import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../logic.dart';
import '../api_client.dart';
import '../build_info.dart';
import '../constants.dart';
import '../translations.dart';
import '../../widgets/glass_widgets.dart';
import '../../widgets/command_palette.dart';
import 'styles.dart';
import 'motion.dart';
import 'dialogs/settings_dialog.dart';
import 'dialogs/token_expired_dialog.dart';
import 'dialogs/glass_update_dialog.dart';
import '../services/ota_update_service.dart';
import 'views/terminal_view.dart';

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> with WindowListener {
  final TextEditingController _snController = TextEditingController();
  bool _hasCheckedInitialToken = false;
  bool _isMaximized = false;
  Timer? _tokenCheckTimer;
  Timer? _otaCheckTimer;
  bool _otaCheckRunning = false;
  bool _otaHoldRetry = false;
  static const Duration _otaStartupDelay = Duration(milliseconds: 2500);
  static const Duration _otaRetryDelay = Duration(minutes: 15);

  final _ListViewState _testRecordListState = _ListViewState();
  final _BarcodeListViewState _barcodeListState = _BarcodeListViewState();
  final _WipListViewState _wipListState = _WipListViewState();
  final _TraceListViewState _traceListState = _TraceListViewState();

  OverlayEntry? _sortOverlayEntry;
  String? _lastSortViewKey;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.isMaximized().then((value) {
      if (mounted) setState(() => _isMaximized = value);
    });
    OtaUpdateService().addListener(_onOtaServiceChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialToken();
      _primeOtaSchedule();
    });
  }

  @override
  void dispose() {
    OtaUpdateService().removeListener(_onOtaServiceChanged);
    _tokenCheckTimer?.cancel();
    _otaCheckTimer?.cancel();
    windowManager.removeListener(this);
    _sortOverlayEntry?.remove();
    _testRecordListState.filterCtrl.dispose();
    _barcodeListState.filterCtrl.dispose();
    _wipListState.filterCtrl.dispose();
    _traceListState.filterCtrl.dispose();
    _snController.dispose();
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

  void _checkInitialToken() {
    _tokenCheckTimer?.cancel();
    _tokenCheckTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final logic = context.read<AppLogic>();
      if (logic.isConnectionValid == false && !_hasCheckedInitialToken) {
        _hasCheckedInitialToken = true;
        _showTokenExpiredWarningDialog(context, logic);
      }
    });
  }

  void _onOtaServiceChanged() {
    if (!mounted) return;
    setState(() {});
    if (_otaCheckRunning) return;
    _otaHoldRetry = false;
    _armOtaCheck(allowStartupBurst: false);
  }

  Future<void> _primeOtaSchedule() async {
    try {
      await OtaUpdateService().loadConfig();
    } catch (e) {
      debugPrint('[OtaUpdate] Load config error: $e');
    }
    if (!mounted) return;
    setState(() {});
    _armOtaCheck(allowStartupBurst: true);
  }

  void _armOtaCheck({required bool allowStartupBurst}) {
    _otaCheckTimer?.cancel();
    _otaCheckTimer = null;
    final service = OtaUpdateService();
    final cfg = service.currentConfig;
    if (cfg.checkInterval == 'off') return;

    if (cfg.checkInterval == 'startup') {
      if (!allowStartupBurst) return;
      _otaCheckTimer = Timer(_otaStartupDelay, _runScheduledOtaCheck);
      return;
    }

    final wait =
        service.timeUntilNextCheck(
          interval: cfg.checkInterval,
          lastCheckTime: cfg.lastCheckTime,
        ) ??
        Duration.zero;
    final delay = allowStartupBurst && wait < _otaStartupDelay
        ? _otaStartupDelay
        : wait;
    _otaCheckTimer = Timer(delay, _runScheduledOtaCheck);
  }

  void _scheduleOtaRetry() {
    _otaHoldRetry = true;
    _otaCheckTimer?.cancel();
    _otaCheckTimer = Timer(_otaRetryDelay, () {
      _otaHoldRetry = false;
      _runScheduledOtaCheck();
    });
  }

  Future<void> _runScheduledOtaCheck() async {
    if (!mounted || _otaCheckRunning) return;
    _otaCheckRunning = true;
    var retryLater = false;
    var scheduleNext = true;
    try {
      final otaService = OtaUpdateService();
      final cfg = await otaService.loadConfig();
      if (!mounted || cfg.checkInterval == 'off') {
        scheduleNext = false;
      } else if (cfg.checkInterval == 'startup' ||
          otaService.shouldCheckForUpdates(
            interval: cfg.checkInterval,
            lastCheckTime: cfg.lastCheckTime,
          )) {
        final result = await otaService.checkForUpdates();
        if (!mounted) {
          scheduleNext = false;
        } else {
          final package = result.packageInfo;
          if (result.hasUpdate && package != null) {
            final logic = context.read<AppLogic>();
            showGlassUpdateDialog(
              context: context,
              packageInfo: package,
              lang: logic.lang,
            );
          } else if (!result.isConnectionSuccess &&
              cfg.checkInterval != 'startup') {
            retryLater = true;
          }
        }
      }
    } catch (e) {
      debugPrint('[OtaUpdate] Scheduled check error: $e');
      final interval = OtaUpdateService().currentConfig.checkInterval;
      if (interval != 'startup' && interval != 'off') retryLater = true;
    } finally {
      _otaCheckRunning = false;
    }
    if (!mounted || !scheduleNext) return;
    if (retryLater) {
      _scheduleOtaRetry();
    } else if (!_otaHoldRetry) {
      _armOtaCheck(allowStartupBurst: false);
    }
  }

  Future<void> _openPendingOtaUpdate() async {
    final logic = context.read<AppLogic>();
    final pending = OtaUpdateService().pendingPackage;
    if (pending != null) {
      if (!mounted) return;
      showGlassUpdateDialog(
        context: context,
        packageInfo: pending,
        lang: logic.lang,
      );
      return;
    }
    try {
      final result = await OtaUpdateService().checkForUpdates(isManual: true);
      if (!mounted) return;
      final package = result.packageInfo;
      if (result.hasUpdate && package != null) {
        showGlassUpdateDialog(
          context: context,
          packageInfo: package,
          lang: logic.lang,
        );
      }
    } catch (e) {
      debugPrint('[OtaUpdate] Badge check error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final colors = theme.colors;
    final logic = context.watch<AppLogic>();

    final sortViewKey =
        '${logic.viewMode}_${logic.selectedSn}_${logic.selectedTraceCsn}';
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

    return CommandPaletteShortcut(
      colors: colors,
      searchHint: Translations.get('command_search_hint', logic.lang),
      noResultsText: Translations.get('no_commands_found', logic.lang),
      blurSigma: logic.dialogBlur,
      isDark: theme.isDark,
      bgOpacity: logic.dialogOpacity,
      items: () => _buildCommandPaletteItems(context, logic, theme, colors),
      child: Scaffold(
        backgroundColor: colors.bgPrimary,
        body: Stack(
          children: [
            // 1. Mesh Gradient Base Tint (Translucent)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.bgSecondary,
                      colors.bgSecondary.withValues(alpha: 0.5),
                      colors.bgSecondary.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
            ),

            // 2. GPU Composited Floating Ambient Mesh Orbs
            Positioned.fill(
              child: RepaintBoundary(child: MeshBackground(colors: colors)),
            ),

            // 3. Main Scaffold Layout: Top Header + Bento Body
            Column(
              children: [
                _buildTopHeader(context, logic, theme, colors),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Bento Sidebar with custom live blur, opacity & mouse spotlight
                        SizedBox(
                          width: 320,
                          child: SpotlightGlow(
                            colors: colors,
                            borderRadius: 18,
                            child: BentoCard(
                              colors: colors,
                              blurSigma: logic.bgBlur,
                              bgOpacity: logic.bgOpacity,
                              padding: const EdgeInsets.all(14),
                              child: _buildSidebarContent(
                                context,
                                logic,
                                theme,
                                colors,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Main Floating Workspace Detail (Individual floating glass components)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (logic.globalError.isNotEmpty) ...[
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.accentRose.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: colors.accentRose.withValues(
                                        alpha: 0.35,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline_rounded,
                                        color: colors.accentRose,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          logic.globalError,
                                          style: TextStyle(
                                            color: colors.accentRose,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              Expanded(
                                child: SelectionArea(
                                  child: AnimatedSwitcher(
                                    duration: Motion.normal,
                                    switchInCurve: Motion.curveOut,
                                    switchOutCurve: Motion.curveIn,
                                    transitionBuilder: (child, animation) {
                                      final slide = Tween<Offset>(
                                        begin: const Offset(0.02, 0),
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
                                        '${logic.viewMode}_${logic.selectedSn}_${logic.selectedTraceCsn}',
                                      ),
                                      child: _buildDetailView(
                                        context,
                                        logic,
                                        theme,
                                        colors,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<CommandPaletteItem> _buildCommandPaletteItems(
    BuildContext context,
    AppLogic logic,
    ThemeProvider theme,
    AppColors colors,
  ) {
    final lang = logic.lang;
    final isTraceMode = logic.viewMode == ViewMode.componentTrace;

    return [
      CommandPaletteItem(
        label: 'Terminal & Logs',
        icon: Icons.terminal_rounded,
        onSelect: () => logic.setViewMode(ViewMode.terminal),
      ),
      // Navigation
      CommandPaletteItem(
        label: Translations.get('tab_test_record', lang),
        subtitle: 'Switch view to Test Record',
        category: Translations.get('category_navigation', lang),
        icon: Icons.fact_check_rounded,
        keywords: ['test', 'record', 'ket qua', 'kiem thu'],
        onSelect: () => logic.setViewMode(ViewMode.testRecord),
      ),
      CommandPaletteItem(
        label: Translations.get('tab_barcode_history', lang),
        subtitle: 'Switch view to Barcode History',
        category: Translations.get('category_navigation', lang),
        icon: Icons.qr_code_2_rounded,
        keywords: ['barcode', 'history', 'lich su', 'cong doan'],
        onSelect: () => logic.setViewMode(ViewMode.barcodeHistory),
      ),
      CommandPaletteItem(
        label: Translations.get('tab_wip_components', lang),
        subtitle: 'Switch view to WIP Component List',
        category: Translations.get('category_navigation', lang),
        icon: Icons.memory_rounded,
        keywords: ['wip', 'component', 'linh kien', 'bom'],
        onSelect: () => logic.setViewMode(ViewMode.wipComponents),
      ),
      CommandPaletteItem(
        label: Translations.get('tab_component_trace', lang),
        subtitle: 'Switch view to Component Trace',
        category: Translations.get('category_navigation', lang),
        icon: Icons.travel_explore_rounded,
        keywords: ['trace', 'truy vet', 'nguoc'],
        onSelect: () => logic.setViewMode(ViewMode.componentTrace),
      ),

      // Actions
      CommandPaletteItem(
        label: Translations.get('cmd_refresh_all', lang),
        subtitle: 'Re-fetch all records in queue',
        category: Translations.get('category_actions', lang),
        icon: Icons.refresh_rounded,
        keywords: ['refresh', 'lam moi', 'reload', 'sync'],
        onSelect: () => isTraceMode
            ? logic.refetchAllTraceSearches()
            : logic.refetchAllSns(),
      ),
      CommandPaletteItem(
        label: Translations.get('cmd_clear_all', lang),
        subtitle: 'Remove all SNs from queue',
        category: Translations.get('category_actions', lang),
        icon: Icons.delete_sweep_rounded,
        keywords: ['clear', 'xoa', 'empty', 'reset'],
        onSelect: () =>
            isTraceMode ? logic.clearTraceHistory() : logic.clearAllSns(),
      ),
      CommandPaletteItem(
        label: Translations.get('cmd_import_csv', lang),
        subtitle: 'Import SNs from a CSV file',
        category: Translations.get('category_actions', lang),
        icon: Icons.file_upload_rounded,
        keywords: ['import', 'nhap', 'csv', 'file'],
        onSelect: () =>
            isTraceMode ? logic.importTraceCsv() : logic.importCsv(),
      ),
      CommandPaletteItem(
        label: Translations.get('cmd_export_csv', lang),
        subtitle: 'Export records to a CSV file',
        category: Translations.get('category_actions', lang),
        icon: Icons.file_download_rounded,
        keywords: ['export', 'xuat', 'csv', 'save'],
        onSelect: () =>
            isTraceMode ? logic.exportTraceCsv() : logic.exportCsv(),
      ),
      CommandPaletteItem(
        label: Translations.get('cmd_download_template', lang),
        subtitle: 'Download template CSV sample file',
        category: Translations.get('category_actions', lang),
        icon: Icons.file_present_rounded,
        keywords: ['template', 'mau', 'csv', 'sample'],
        onSelect: () => isTraceMode
            ? logic.downloadTraceTemplateCsv()
            : logic.downloadTemplateCsv(),
      ),
      CommandPaletteItem(
        label: Translations.get('cmd_fetch_cdp', lang),
        subtitle: 'Automatically sync Token & Cookie from Chrome/Edge',
        category: Translations.get('category_actions', lang),
        icon: Icons.sync_lock_rounded,
        keywords: [
          'cdp',
          'token',
          'cookie',
          'browser',
          'trinh duyet',
          'dong bo',
        ],
        onSelect: () => _showSettingsDialog(context, logic, theme),
      ),

      // View & Theme
      CommandPaletteItem(
        label: Translations.get('cmd_toggle_theme', lang),
        subtitle: theme.isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
        category: Translations.get('category_view', lang),
        icon: theme.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        keywords: ['theme', 'dark', 'light', 'giao dien', 'sang', 'toi'],
        onSelect: () => theme.toggleTheme(),
      ),
      CommandPaletteItem(
        label: Translations.get('cmd_open_settings', lang),
        subtitle: 'Open full MES configurations & glass adjustments',
        category: Translations.get('category_system', lang),
        icon: Icons.settings_rounded,
        keywords: ['settings', 'cai dat', 'config', 'glass', 'blur', 'opacity'],
        onSelect: () => _showSettingsDialog(context, logic, theme),
      ),
    ];
  }

  /// Top Modern Bento Header Bar
  Widget _buildTopHeader(
    BuildContext context,
    AppLogic logic,
    ThemeProvider theme,
    AppColors colors,
  ) {
    int currentTabIndex = 0;
    switch (logic.viewMode) {
      case ViewMode.testRecord:
        currentTabIndex = 0;
        break;
      case ViewMode.barcodeHistory:
        currentTabIndex = 1;
        break;
      case ViewMode.wipComponents:
        currentTabIndex = 2;
        break;
      case ViewMode.terminal:
      case ViewMode.componentTrace:
        currentTabIndex = 3;
        break;
    }

    final isConnValid = logic.isConnectionValid == true;
    final isConnError = logic.isConnectionValid == false;
    final otaLabel = OtaUpdateService().advertisedUpdateLabel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.headerBg,
        border: Border(
          bottom: BorderSide(color: colors.headerBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Brand Logo + Title + Version Tag
          InkWell(
            onTap: () => logic.setViewMode(ViewMode.testRecord),
            borderRadius: BorderRadius.circular(10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.accentColor, colors.accentCyan],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primaryGlow.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'JA',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          appName,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                        if (BuildInfo.isDebug) ...[
                          const SizedBox(width: 6),
                          PillBadge(
                            label: 'DEBUG',
                            color: colors.accentAmber,
                            bg: colors.accentAmber.withValues(alpha: 0.15),
                            border: colors.accentAmber.withValues(alpha: 0.4),
                            icon: Icons.bug_report_rounded,
                            fontSize: 9.5,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      BuildInfo.isDebug
                          ? 'v$appVersion (${BuildInfo.debugTimestamp})'
                          : 'v$appVersion',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontFamily: 'JetBrains Mono',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (otaLabel != null) ...[
            const SizedBox(width: 8),
            _OtaUpdateBadge(
              label: otaLabel,
              colors: colors,
              tooltip: Translations.get('update_available', logic.lang),
              onTap: _openPendingOtaUpdate,
            ),
          ],

          const SizedBox(width: 16),

          // Sliding Pill Tab Bar (Centered 4 Tabs)
          Expanded(
            child: Center(
              child: SlidingPillTabBar(
                colors: colors,
                currentIndex: currentTabIndex,
                tabs: [
                  Translations.get('tab_test_record', logic.lang),
                  Translations.get('tab_barcode_history', logic.lang),
                  Translations.get('tab_wip_components', logic.lang),
                  Translations.get('tab_component_trace', logic.lang),
                ],
                icons: const [
                  Icons.fact_check_rounded,
                  Icons.qr_code_2_rounded,
                  Icons.memory_rounded,
                  Icons.travel_explore_rounded,
                ],
                onTabSelected: (index) {
                  switch (index) {
                    case 0:
                      logic.setViewMode(ViewMode.testRecord);
                      break;
                    case 1:
                      logic.setViewMode(ViewMode.barcodeHistory);
                      break;
                    case 2:
                      logic.setViewMode(ViewMode.wipComponents);
                      break;
                    case 3:
                      logic.setViewMode(ViewMode.componentTrace);
                      break;
                  }
                },
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Dynamic Island Status Capsule (Live MES state)
          DynamicIslandCapsule(
            colors: colors,
            isRunning: isConnValid,
            statusText: isConnValid
                ? 'LIVE • MES OK'
                : (isConnError ? 'TOKEN EXPIRED' : 'CONNECTING...'),
            subText: logic.viewMode == ViewMode.componentTrace
                ? '${logic.traceHistory.length} csn'
                : '${logic.snList.length} sn',
            customColor: isConnValid
                ? colors.accentEmerald
                : (isConnError ? colors.accentRose : colors.accentAmber),
            onTap: () => _showSettingsDialog(context, logic, theme),
          ),

          const SizedBox(width: 10),

          // Template CSV button
          _HoverChip(
            icon: Icons.file_present_rounded,
            label: Translations.get('template', logic.lang),
            background: colors.subCardBg,
            foreground: colors.textSecondary,
            border: Border.all(color: colors.subCardBorder),
            hoverBackground: colors.accentColor.withValues(alpha: 0.15),
            keepExpanded: _isMaximized,
            onTap: () => logic.viewMode == ViewMode.componentTrace
                ? logic.downloadTraceTemplateCsv()
                : logic.downloadTemplateCsv(),
          ),

          const SizedBox(width: 4),

          // Import CSV button
          _HoverChip(
            icon: Icons.file_upload_rounded,
            label: Translations.get('import', logic.lang),
            background: colors.subCardBg,
            foreground: colors.accentAmber,
            border: Border.all(color: colors.subCardBorder),
            hoverBackground: colors.accentAmber.withValues(alpha: 0.15),
            keepExpanded: _isMaximized,
            onTap: () => logic.viewMode == ViewMode.componentTrace
                ? logic.importTraceCsv()
                : logic.importCsv(),
          ),

          const SizedBox(width: 4),

          // Export CSV button
          _HoverChip(
            icon: Icons.file_download_rounded,
            label: Translations.get('export', logic.lang),
            background: colors.subCardBg,
            foreground: colors.accentEmerald,
            border: Border.all(color: colors.subCardBorder),
            hoverBackground: colors.accentEmerald.withValues(alpha: 0.15),
            keepExpanded: _isMaximized,
            onTap: () => logic.viewMode == ViewMode.componentTrace
                ? logic.exportTraceCsv()
                : logic.exportCsv(),
          ),

          const SizedBox(width: 4),

          // Command Palette Trigger (Ctrl+K)
          _HoverChip(
            icon: Icons.bolt_rounded,
            label: 'Ctrl+K',
            background: colors.subCardBg,
            foreground: colors.accentCyan,
            border: Border.all(color: colors.subCardBorder),
            hoverBackground: colors.accentCyan.withValues(alpha: 0.15),
            keepExpanded: _isMaximized,
            onTap: () => showCommandPalette(
              context,
              items: _buildCommandPaletteItems(context, logic, theme, colors),
              colors: colors,
            ),
          ),

          const SizedBox(width: 6),

          // Language Cycle Toggle
          _HoverChip(
            icon: Icons.language_rounded,
            label: logic.lang.toUpperCase(),
            background: colors.subCardBg,
            foreground: colors.textPrimary,
            border: Border.all(color: colors.subCardBorder),
            keepExpanded: _isMaximized,
            onTap: () => logic.cycleLanguage(),
          ),

          const SizedBox(width: 4),

          // Theme Toggle Button
          IconButton(
            icon: Icon(
              theme.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: theme.isDark ? colors.accentAmber : colors.accentPurple,
              size: 18,
            ),
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            splashRadius: 18,
            onPressed: () => theme.toggleTheme(),
            tooltip: Translations.get('toggle_theme', logic.lang),
          ),

          const SizedBox(width: 4),

          // Settings Button
          IconButton(
            icon: Icon(
              Icons.settings_rounded,
              color: colors.textSecondary,
              size: 18,
            ),
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
            splashRadius: 18,
            onPressed: () => _showSettingsDialog(context, logic, theme),
            tooltip: Translations.get('settings', logic.lang),
          ),
        ],
      ),
    );
  }

  /// Sidebar content (SN Queue or Component Trace CSN History)
  Widget _buildSidebarContent(
    BuildContext context,
    AppLogic logic,
    ThemeProvider theme,
    AppColors colors,
  ) {
    final isTraceMode = logic.viewMode == ViewMode.componentTrace;
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

        // Shared Pill-Shaped Input Field
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          decoration: BoxDecoration(
            color: colors.subCardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.subCardBorder),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Icon(
                isTraceMode
                    ? Icons.search_rounded
                    : Icons.qr_code_scanner_rounded,
                size: 16,
                color: colors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _snController,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12.5,
                    fontFamily: 'JetBrains Mono',
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: Translations.get(
                      isTraceMode ? 'component_trace_hint' : 'enter_sn',
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
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    isTraceMode ? Icons.search_rounded : Icons.add_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  onPressed: () {
                    if (isTraceMode) {
                      logic.addTraceCsns(_snController.text);
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

    return SelectionArea(
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        itemCount: logic.snList.length,
        separatorBuilder: (ctx, idx) => const SizedBox(height: 5),
        itemBuilder: (context, index) {
          final sn = logic.snList[index];
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

          // Alternate / Resolved SN
          String? alternateSn;
          final resolved = logic.resolvedSnFor(sn);
          if (resolved != null && resolved.isNotEmpty && resolved != sn) {
            alternateSn = resolved;
          } else {
            final testList = logic.results[sn];
            if (testList != null && testList.isNotEmpty) {
              final r = testList.first;
              if (r.customerSn.isNotEmpty && r.customerSn != sn) {
                alternateSn = r.customerSn;
              } else if (r.internalSn.isNotEmpty && r.internalSn != sn) {
                alternateSn = r.internalSn;
              }
            }
            if (alternateSn == null) {
              final procList = logic.processResults[sn];
              if (procList != null && procList.isNotEmpty) {
                final r = procList.first;
                if (r.customerSn.isNotEmpty && r.customerSn != sn) {
                  alternateSn = r.customerSn;
                } else if (r.internalSn.isNotEmpty && r.internalSn != sn) {
                  alternateSn = r.internalSn;
                }
              }
            }
          }

          final hasBottomRow =
              isLoading ||
              hasError ||
              hasWarning ||
              (alternateSn != null && alternateSn.isNotEmpty) ||
              nextStation.isNotEmpty;

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
                      if (recordCount > 0 || logic.results.containsKey(sn)) ...[
                        AnimatedSwitcher(
                          duration: Motion.fast,
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: PillBadge(
                            key: ValueKey('${sn}_$recordCount'),
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
                            Translations.get('status_fetching', logic.lang),
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
                                      child: BounceMarqueeText(
                                        text: alternateSn,
                                        style: TextStyle(
                                          color: colors.accentCyan,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'JetBrains Mono',
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
                                bg: colors.accentPurple.withValues(alpha: 0.12),
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

  /// Detail Workspace View Router
  Widget _buildDetailView(
    BuildContext context,
    AppLogic logic,
    ThemeProvider theme,
    AppColors colors,
  ) {
    if (logic.viewMode == ViewMode.terminal) {
      return TerminalView(logic: logic, theme: theme);
    }
    if (logic.viewMode == ViewMode.componentTrace) {
      return _buildComponentTraceView(context, logic, theme, colors);
    }

    if (logic.selectedSn.isEmpty) {
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
              Icon(Icons.touch_app_rounded, size: 36, color: colors.accentCyan),
              const SizedBox(height: 12),
              Text(
                Translations.get('select_sn', logic.lang),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (logic.viewMode == ViewMode.barcodeHistory) {
      return _buildBarcodeHistoryView(context, logic, theme, colors);
    }

    if (logic.viewMode == ViewMode.wipComponents) {
      return _buildWipComponentsView(context, logic, theme, colors);
    }

    // Default: Test Record View
    return _buildTestRecordView(context, logic, theme, colors);
  }

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
                                if (record.processCode.isNotEmpty) ...[
                                  const SizedBox(width: 8),
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
                                ],
                                if (record.testDate.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    record.testDate,
                                    style: TextStyle(
                                      color: colors.textMuted,
                                      fontSize: 11.5,
                                      fontFamily: 'JetBrains Mono',
                                    ),
                                  ),
                                ],
                              ],
                            ),
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
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (!isPass) ...[
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
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: colors.accentAmber.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: colors.accentAmber.withValues(
                                        alpha: 0.3,
                                      ),
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
                                if (record.createdDt.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    record.createdDt,
                                    style: TextStyle(
                                      color: colors.textMuted,
                                      fontSize: 11.5,
                                      fontFamily: 'JetBrains Mono',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (record.materialCategory.isNotEmpty)
                              PillBadge(
                                label: record.materialCategory,
                                color: colors.accentAmber,
                                bg: colors.accentAmber.withValues(alpha: 0.12),
                                border: colors.accentAmber.withValues(
                                  alpha: 0.35,
                                ),
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
                                    Translations.get(
                                      'process_time',
                                      logic.lang,
                                    ),
                                    record.createdDt,
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
                                if (record.createdDt.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    record.createdDt,
                                    style: TextStyle(
                                      color: colors.textMuted,
                                      fontSize: 11.5,
                                      fontFamily: 'JetBrains Mono',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (record.checkAssembled.isNotEmpty)
                              PillBadge(
                                label: record.checkAssembled,
                                color: colors.accentCyan,
                                bg: colors.accentCyan.withValues(alpha: 0.12),
                                border: colors.accentCyan.withValues(
                                  alpha: 0.35,
                                ),
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

  /// Records Header (Bento Floating Capsule: Marquee SN + Next Stage Pill + Live Search + Sort Menu)
  Widget _buildRecordsHeader({
    required String sn,
    required int count,
    required ThemeProvider theme,
    required AppColors colors,
    required String lang,
    required _BaseListViewState listState,
    required List<_SortOption> sortOptions,
    String? resolvedSn,
    SnMasterInfo? snMasterInfo,
    int? passCount,
    int? failCount,
  }) {
    final logic = context.watch<AppLogic>();
    final routeLabel = snMasterInfo == null
        ? ''
        : (snMasterInfo.routeName.isNotEmpty
              ? snMasterInfo.routeName
              : snMasterInfo.routeCode);

    final isAllSelected = listState.filter.isEmpty;
    final isPassSelected = listState.filter.toUpperCase() == 'PASS';
    final isFailSelected = listState.filter.toUpperCase() == 'FAIL';

    return BentoCard(
      colors: colors,
      blurSigma: logic.bgBlur,
      bgOpacity: logic.bgOpacity,
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (routeLabel.isNotEmpty) ...[
            PillBadge(
              label: 'Route: $routeLabel',
              color: colors.accentEmerald,
              bg: colors.accentEmerald.withValues(alpha: 0.12),
              border: colors.accentEmerald.withValues(alpha: 0.35),
              fontSize: 10.5,
              icon: Icons.alt_route_rounded,
            ),
            const SizedBox(width: 10),
          ],
          if (passCount != null && failCount != null && count > 0) ...[
            Container(
              height: 28,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: colors.subCardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.subCardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildQuickFilterTab(
                    label: 'All ($count)',
                    selected: isAllSelected,
                    colors: colors,
                    activeColor: colors.accentCyan,
                    onTap: () => setState(() {
                      listState.filterCtrl.clear();
                      listState.filter = '';
                    }),
                  ),
                  _buildQuickFilterTab(
                    label: 'PASS ($passCount)',
                    selected: isPassSelected,
                    colors: colors,
                    activeColor: colors.accentEmerald,
                    onTap: () => setState(() {
                      if (isPassSelected) {
                        listState.filterCtrl.clear();
                        listState.filter = '';
                      } else {
                        listState.filterCtrl.text = 'PASS';
                        listState.filter = 'PASS';
                      }
                    }),
                  ),
                  if (failCount > 0)
                    _buildQuickFilterTab(
                      label: 'FAIL ($failCount)',
                      selected: isFailSelected,
                      colors: colors,
                      activeColor: colors.accentRose,
                      onTap: () => setState(() {
                        if (isFailSelected) {
                          listState.filterCtrl.clear();
                          listState.filter = '';
                        } else {
                          listState.filterCtrl.text = 'FAIL';
                          listState.filter = 'FAIL';
                        }
                      }),
                    ),
                ],
              ),
            ),
          ],
          const Spacer(),
          const SizedBox(width: 12),
          SizedBox(
            width: 200,
            height: 32,
            child: TextField(
              controller: listState.filterCtrl,
              style: TextStyle(fontSize: 12, color: colors.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                hintText: Translations.get('search_placeholder', lang),
                hintStyle: TextStyle(fontSize: 11.5, color: colors.textMuted),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 15,
                  color: colors.textSecondary,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 28,
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
                          size: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
                filled: true,
                fillColor: colors.subCardBg,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colors.subCardBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: colors.accentColor, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (v) => setState(() => listState.filter = v),
            ),
          ),
          const SizedBox(width: 8),
          _buildSortButton(theme, colors, lang, listState, sortOptions),
        ],
      ),
    );
  }

  Widget _buildSortButton(
    ThemeProvider theme,
    AppColors colors,
    String lang,
    _BaseListViewState listState,
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
              colors: colors,
              lang: lang,
              listState: listState,
              options: options,
              onSelect: selectKey,
            );
          },
          child: Tooltip(
            message: Translations.get('sort', lang),
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: colors.subCardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.subCardBorder),
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
                    color: listState.sortField != null
                        ? colors.accentCyan
                        : colors.textPrimary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    currentLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: listState.sortField != null
                          ? colors.accentCyan
                          : colors.textPrimary,
                      fontWeight: FontWeight.w700,
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

  void _openSortOverlay({
    required BuildContext anchorContext,
    required Offset anchorTopLeft,
    required Size anchorSize,
    required ThemeProvider theme,
    required AppColors colors,
    required String lang,
    required _BaseListViewState listState,
    required List<_SortOption> options,
    required void Function(String key) onSelect,
  }) {
    _closeSortOverlay();
    final logic = context.read<AppLogic>();
    final rawBlur = logic.dialogBlur;
    final opacity = logic.dialogOpacity;
    final effectiveBlur = opacity < 1.0 && rawBlur < 6.0 ? 6.0 : rawBlur;
    final borderColor = colors.borderDefault;
    final screenWidth = MediaQuery.of(context).size.width;
    final top = anchorTopLeft.dy + anchorSize.height + 4;
    final right = screenWidth - (anchorTopLeft.dx + anchorSize.width);

    final menuContent = _buildSortMenuList(
      colors: colors,
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
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Motion.normal,
                curve: Motion.curveOut,
                builder: (context, v, child) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(
                      sigmaX: effectiveBlur * v,
                      sigmaY: effectiveBlur * v,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.cardBg.withValues(alpha: opacity * v),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: borderColor.withValues(alpha: v),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15 * v),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      foregroundDecoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border(
                          top: BorderSide(
                            color: colors.glassHighlight.withValues(alpha: v),
                          ),
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

  Widget _buildSortMenuList({
    required AppColors colors,
    required String lang,
    required _BaseListViewState listState,
    required List<_SortOption> options,
    required void Function(String key) onSelect,
  }) {
    return Material(
      color: Colors.transparent,
      child: IntrinsicWidth(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 190),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSortMenuRow(
                  colors: colors,
                  icon: Icons.sort_rounded,
                  label: Translations.get('default', lang),
                  selected: listState.sortField == null,
                  onTap: () => onSelect(''),
                ),
                ...options.map(
                  (o) => _buildSortMenuRow(
                    colors: colors,
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
      ),
    );
  }

  Widget _buildSortMenuRow({
    required AppColors colors,
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool? sortAsc,
  }) {
    final accent = colors.accentColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? colors.accentCyan : colors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  color: selected ? colors.textPrimary : colors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
                color: colors.accentCyan,
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
    AppColors colors, {
    bool highlight = false,
    double labelWidth = 135,
  }) {
    if (value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              '$label: ',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (highlight)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: colors.accentCyan.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: colors.accentCyan.withValues(alpha: 0.3),
                ),
              ),
              child: SelectableText(
                value,
                style: TextStyle(
                  color: colors.accentCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'JetBrains Mono',
                ),
                maxLines: 1,
              ),
            )
          else
            Expanded(
              child: SelectableText(
                value,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'JetBrains Mono',
                ),
                maxLines: 1,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterTab({
    required String label,
    required bool selected,
    required AppColors colors,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? activeColor.withValues(alpha: 0.45)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? activeColor : colors.textSecondary,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Modern GlassDialog Settings Modal with live 4-slider Glassmorphism Controls
  void _showSettingsDialog(
    BuildContext context,
    AppLogic logic,
    ThemeProvider theme,
  ) {
    showAppSettingsDialog(context, logic, theme);
  }

  void _showTokenExpiredWarningDialog(BuildContext context, AppLogic logic) {
    final theme = context.read<ThemeProvider>();
    showTokenExpiredWarningDialog(
      context,
      logic,
      theme,
      onOpenSettings: () => _showSettingsDialog(context, logic, theme),
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

abstract class _BaseListViewState {
  TextEditingController get filterCtrl;
  String get filter;
  set filter(String value);
  String? get sortField;
  set sortField(String? value);
  bool get sortAsc;
  set sortAsc(bool value);
  Set<String> get animatedItemKeys;
}

class _ListViewState implements _BaseListViewState {
  @override
  final TextEditingController filterCtrl = TextEditingController();
  @override
  String filter = '';
  @override
  String? sortField;
  @override
  bool sortAsc = true;
  @override
  final Set<String> animatedItemKeys = {};
}

class _BarcodeListViewState implements _BaseListViewState {
  @override
  final TextEditingController filterCtrl = TextEditingController();
  @override
  String filter = '';
  @override
  String? sortField;
  @override
  bool sortAsc = true;
  @override
  final Set<String> animatedItemKeys = {};
}

class _WipListViewState implements _BaseListViewState {
  @override
  final TextEditingController filterCtrl = TextEditingController();
  @override
  String filter = '';
  @override
  String? sortField;
  @override
  bool sortAsc = true;
  @override
  final Set<String> animatedItemKeys = {};
}

class _TraceListViewState implements _BaseListViewState {
  @override
  final TextEditingController filterCtrl = TextEditingController();
  @override
  String filter = '';
  @override
  String? sortField;
  @override
  bool sortAsc = true;
  @override
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
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(100),
            border: widget.border,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 15, color: widget.foreground),
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
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
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

class _OtaUpdateBadge extends StatelessWidget {
  const _OtaUpdateBadge({
    required this.label,
    required this.colors,
    required this.tooltip,
    required this.onTap,
  });

  final String label;
  final AppColors colors;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: PillBadge(
            label: label,
            color: colors.accentEmerald,
            bg: colors.accentEmerald.withValues(alpha: 0.15),
            border: colors.accentEmerald.withValues(alpha: 0.45),
            icon: Icons.system_update_alt_rounded,
            showDot: true,
            fontSize: 10,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          ),
        ),
      ),
    );
  }
}
