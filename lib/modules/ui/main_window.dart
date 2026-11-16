import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'dialogs/login_dialog.dart';
import 'dialogs/glass_update_dialog.dart';
import '../services/ota_update_service.dart';
import '../services/window_activity_monitor.dart';
import 'views/terminal_view.dart';

part 'sidebar/main_sidebar_part.dart';
part 'views/test_record_part.dart';
part 'views/barcode_history_part.dart';
part 'views/wip_components_part.dart';
part 'views/component_trace_part.dart';
part 'widgets/main_records_toolbar_part.dart';

class MainWindow extends StatefulWidget {
  const MainWindow({super.key});

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> with WindowListener {
  final TextEditingController _snController = TextEditingController();
  bool _isWoInputMode = false;
  bool _hasCheckedInitialToken = false;
  bool _isMaximized = false;
  Timer? _tokenCheckTimer;
  Timer? _otaCheckTimer;
  bool _otaCheckRunning = false;
  bool _otaHoldRetry = false;
  static const Duration _otaStartupDelay = Duration(milliseconds: 2500);
  static const Duration _otaRetryDelay = Duration(minutes: 15);

  late final AppLifecycleListener _lifecycleListener;
  late final WindowActivityMonitor _windowActivity;

  final _ListViewState _testRecordListState = _ListViewState();
  final _BarcodeListViewState _barcodeListState = _BarcodeListViewState();
  final _WipListViewState _wipListState = _WipListViewState();
  final _TraceListViewState _traceListState = _TraceListViewState();

  OverlayEntry? _sortOverlayEntry;
  String? _lastSortViewKey;
  bool _queueFailOnlyFilter = false;
  final Set<int> _expandedCompParamIds = {};

  void _rebuild(VoidCallback fn) => setState(fn);
  @override
  void initState() {
    super.initState();
    _windowActivity = WindowActivityMonitor();
    _lifecycleListener = AppLifecycleListener(
      onStateChange: _windowActivity.onLifecycleStateChanged,
    );
    windowManager.addListener(this);
    windowManager.addListener(_windowActivity);
    _windowActivity.start();
    windowManager
        .isMaximized()
        .then((value) {
          if (mounted) setState(() => _isMaximized = value);
        })
        .catchError((_) {});
    OtaUpdateService().addListener(_onOtaServiceChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialToken();
      _primeOtaSchedule();
    });
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    windowManager.removeListener(_windowActivity);
    _windowActivity.dispose();
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
      if (isMesLoginDialogOpen) {
        _hasCheckedInitialToken = true;
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_hasCheckedInitialToken && mounted && !isMesLoginDialogOpen) {
            _hasCheckedInitialToken = true;
            _showTokenExpiredWarningDialog(context, logic);
          }
        });
      }
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
                                    color:
                                        (logic.globalMessageIsError
                                                ? colors.accentRose
                                                : colors.accentEmerald)
                                            .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color:
                                          (logic.globalMessageIsError
                                                  ? colors.accentRose
                                                  : colors.accentEmerald)
                                              .withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        logic.globalMessageIsError
                                            ? Icons.error_outline_rounded
                                            : Icons
                                                  .check_circle_outline_rounded,
                                        color: logic.globalMessageIsError
                                            ? colors.accentRose
                                            : colors.accentEmerald,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          logic.globalError,
                                          style: TextStyle(
                                            color: logic.globalMessageIsError
                                                ? colors.accentRose
                                                : colors.accentEmerald,
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
        label: Translations.get('cmd_login_account', lang),
        subtitle: Translations.get('mes_login_subtitle', lang),
        category: Translations.get('category_actions', lang),
        icon: Icons.login_rounded,
        keywords: [
          'login',
          'dang nhap',
          'account',
          'tai khoan',
          'sso',
          'cloudmes',
          'switch',
        ],
        onSelect: () => _showLoginDialog(context, logic, theme),
      ),
      if (logic.isConnectionValid == true && logic.token.trim().isNotEmpty)
        CommandPaletteItem(
          label: Translations.get('cmd_logout_account', lang),
          subtitle: Translations.get('logout_success_msg', lang),
          category: Translations.get('category_actions', lang),
          icon: Icons.logout_rounded,
          keywords: ['logout', 'dang xuat', 'sign out', 'doi tai khoan'],
          onSelect: () => logic.logoutAccount(),
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

          // Dynamic Island Status Capsule (Live MES state & Account)
          DynamicIslandCapsule(
            colors: colors,
            isRunning: isConnValid,
            statusText: isConnValid
                ? (logic.activeAccount.isNotEmpty
                      ? 'LIVE • ${logic.activeAccount}'
                      : 'LIVE • MES OK')
                : (isConnError ? 'TOKEN EXPIRED' : 'CONNECTING...'),
            subText: logic.viewMode == ViewMode.componentTrace
                ? '${logic.traceHistory.length} csn'
                : '${logic.snList.length} sn',
            customColor: isConnValid
                ? colors.accentEmerald
                : (isConnError ? colors.accentRose : colors.accentAmber),
            onTap: () => _showLoginDialog(context, logic, theme),
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

          const SizedBox(width: 2),

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

  /// Modern GlassDialog Settings Modal with live 4-slider Glassmorphism Controls
  void _showSettingsDialog(
    BuildContext context,
    AppLogic logic,
    ThemeProvider theme,
  ) {
    showAppSettingsDialog(context, logic, theme);
  }

  void _showLoginDialog(
    BuildContext context,
    AppLogic logic,
    ThemeProvider theme,
  ) {
    showMesLoginDialog(
      context,
      logic: logic,
      colors: theme.colors,
      onOpenFullSettings: () => _showSettingsDialog(context, logic, theme),
    );
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
}
