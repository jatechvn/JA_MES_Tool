import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../logic.dart';
import '../api_client.dart';
import '../constants.dart';
import '../translations.dart';
import '../browser_helper.dart';
import 'styles.dart';

class MainWindow extends StatefulWidget {
  const MainWindow({Key? key}) : super(key: key);

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> with WindowListener {
  final TextEditingController _snController = TextEditingController();
  bool _hasCheckedInitialToken = false;
  bool _isMaximized = false;

  final _ListViewState _testRecordListState = _ListViewState();
  final _ListViewState _barcodeListState = _ListViewState();
  final _ListViewState _wipListState = _ListViewState();

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
          Container(
            width: 300,
            color: theme.sidebarBg,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(Translations.get('mes_queue', logic.lang), 
                        style: TextStyle(color: theme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.settings, color: theme.textPrimary, size: 20),
                          onPressed: () => _showSettingsDialog(context, logic, theme),
                          tooltip: Translations.get('settings', logic.lang),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_sweep, color: theme.failColor, size: 20),
                          onPressed: logic.snList.isEmpty ? null : () => logic.clearAllSns(),
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
                        style: TextStyle(color: theme.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: Translations.get('enter_sn', logic.lang),
                          hintStyle: TextStyle(color: theme.textSecondary),
                          filled: true,
                          fillColor: theme.cardBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      ? Center(child: Text(Translations.get('no_sns_in_queue', logic.lang), style: TextStyle(color: theme.textSecondary)))
                      : ListView.builder(
                          itemCount: logic.snList.length,
                          itemBuilder: (context, index) {
                            final sn = logic.snList[index];
                            final isSelected = sn == logic.selectedSn;
                            final isLoading = logic.loadingStatus[sn] == true;
                            final hasError = logic.errors[sn] != null;
                            final recordCount = logic.results[sn]?.length ?? 0;
                            
                            return InkWell(
                              onTap: () => logic.selectSn(sn),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.blue.withOpacity(0.3) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isSelected ? Colors.blue : Colors.transparent),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        sn, 
                                        style: TextStyle(
                                          color: hasError ? theme.failColor : theme.textPrimary, 
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                                        )
                                      )
                                    ),
                                    if (isLoading)
                                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    else if (hasError)
                                      const Icon(Icons.error, color: Colors.red, size: 16)
                                    else if (logic.results.containsKey(sn))
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: recordCount > 0 ? theme.passColor : Colors.grey,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          recordCount.toString(),
                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    const SizedBox(width: 4),
                                    InkWell(
                                      onTap: () => logic.removeSn(sn),
                                      child: Icon(Icons.close, color: theme.textSecondary, size: 16),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: Container(
              color: Colors.transparent,
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
                              color: theme.isDark ? Colors.black87 : Colors.white70,
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (logic.isConnectionValid == null)
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      else if (logic.isConnectionValid == true)
                        Tooltip(message: 'Connection Valid', child: Icon(Icons.check_circle, color: theme.passColor, size: 20))
                      else
                        Tooltip(message: logic.connectionError ?? 'Connection Error', child: Icon(Icons.error, color: theme.failColor, size: 20)),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: theme.cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: theme.isDark ? Colors.white24 : Colors.black12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _HoverChip(
                              icon: Icons.fact_check_rounded,
                              label: Translations.get('tab_test_record', logic.lang),
                              background: logic.viewMode == ViewMode.testRecord ? Colors.blue.shade700 : Colors.transparent,
                              foreground: logic.viewMode == ViewMode.testRecord ? Colors.white : theme.textSecondary,
                              hoverBackground: theme.isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
                              keepExpanded: logic.viewMode == ViewMode.testRecord || _isMaximized,
                              onTap: () => logic.setViewMode(ViewMode.testRecord),
                            ),
                            _HoverChip(
                              icon: Icons.qr_code_2_rounded,
                              label: Translations.get('tab_barcode_history', logic.lang),
                              background: logic.viewMode == ViewMode.barcodeHistory ? Colors.blue.shade700 : Colors.transparent,
                              foreground: logic.viewMode == ViewMode.barcodeHistory ? Colors.white : theme.textSecondary,
                              hoverBackground: theme.isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
                              keepExpanded: logic.viewMode == ViewMode.barcodeHistory || _isMaximized,
                              onTap: () => logic.setViewMode(ViewMode.barcodeHistory),
                            ),
                            _HoverChip(
                              icon: Icons.memory_rounded,
                              label: Translations.get('tab_wip_components', logic.lang),
                              background: logic.viewMode == ViewMode.wipComponents ? Colors.blue.shade700 : Colors.transparent,
                              foreground: logic.viewMode == ViewMode.wipComponents ? Colors.white : theme.textSecondary,
                              hoverBackground: theme.isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
                              keepExpanded: logic.viewMode == ViewMode.wipComponents || _isMaximized,
                              onTap: () => logic.setViewMode(ViewMode.wipComponents),
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
                        border: Border.all(color: theme.isDark ? Colors.white24 : Colors.black12),
                        keepExpanded: _isMaximized,
                        onTap: () => logic.cycleLanguage(),
                      ),
                      const SizedBox(width: 6),

                      // Theme Toggle
                      _HoverChip(
                        icon: theme.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        label: Translations.get('toggle_theme', logic.lang),
                        background: theme.cardBg,
                        foreground: theme.isDark ? Colors.amber : Colors.indigo.shade600,
                        border: Border.all(color: theme.isDark ? Colors.white24 : Colors.black12),
                        keepExpanded: _isMaximized,
                        onTap: () => context.read<ThemeProvider>().toggleTheme(),
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
                        color: logic.globalError.contains('successfully') ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        border: Border.all(color: logic.globalError.contains('successfully') ? Colors.green : Colors.red.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(logic.globalError, style: TextStyle(color: logic.globalError.contains('successfully') ? Colors.green : theme.failColor)),
                    ),
                  
                  // Detail View
                  Expanded(
                    child: SelectionArea(
                      child: _buildDetailView(context, logic, theme),
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


  Widget _buildDetailView(BuildContext context, AppLogic logic, ThemeProvider theme) {
    if (logic.selectedSn.isEmpty) {
      return Center(child: Text(Translations.get('select_sn', logic.lang), style: TextStyle(color: theme.textSecondary)));
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
          color: Colors.red.withOpacity(0.1),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('${Translations.get('error_for', logic.lang)} $sn: $error', style: TextStyle(color: theme.failColor)),
      );
    }

    if (records == null || records.isEmpty) {
      return Center(child: Text('${Translations.get('no_records', logic.lang)} $sn', style: TextStyle(color: theme.textSecondary)));
    }

    final displayRecords = _filterSortTestRecords(records, _testRecordListState);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRecordsHeader(
          sn: sn,
          count: records.length,
          theme: theme,
          lang: logic.lang,
          listState: _testRecordListState,
          sortOptions: [
            _SortOption('test_date', Translations.get('test_date', logic.lang)),
            _SortOption('station', Translations.get('station', logic.lang)),
            _SortOption('result', Translations.get('result', logic.lang)),
            _SortOption('product_no', Translations.get('product_no', logic.lang)),
          ],
        ),
        const SizedBox(height: 12),
        if (displayRecords.isEmpty)
          Expanded(child: Center(child: Text(Translations.get('no_matches', logic.lang), style: TextStyle(color: theme.textSecondary))))
        else
        Expanded(
          child: ListView.builder(
            itemCount: displayRecords.length,
            itemBuilder: (context, index) {
              final record = displayRecords[index];
              final isPass = record.testResult.toUpperCase() == 'PASS';

              return Container(
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
                        Text('${Translations.get('station', logic.lang)}: ${record.stationId}', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPass ? theme.passColor : theme.failColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            record.testResult,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(Translations.get('product_no', logic.lang), record.productNo, theme),
                    _buildInfoRow(Translations.get('internal_sn', logic.lang), record.internalSn, theme, highlight: true),
                    _buildInfoRow(Translations.get('customer_sn', logic.lang), record.customerSn, theme),
                    _buildInfoRow(Translations.get('process_code', logic.lang), record.processCode, theme),
                    _buildInfoRow(Translations.get('line_station_code', logic.lang), record.lineStationCode, theme),
                    _buildInfoRow(Translations.get('test_host', logic.lang), record.loc, theme, highlight: true),
                    _buildInfoRow(Translations.get('product_series', logic.lang), record.productSeries, theme),
                    _buildInfoRow(Translations.get('work_order', logic.lang), record.woNo, theme),
                    _buildInfoRow(Translations.get('test_date', logic.lang), record.testDate, theme),
                    _buildInfoRow(Translations.get('test_time', logic.lang), record.testTime, theme),
                    _buildInfoRow(Translations.get('emp_no', logic.lang), record.empNo, theme),
                    if (!isPass) ...[
                      if (record.errCode.isNotEmpty)
                        _buildInfoRow(Translations.get('error_code', logic.lang), record.errCode, theme),
                      if (record.failureReason.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text('${Translations.get('failure_reason', logic.lang)}: ${record.failureReason}', style: TextStyle(color: theme.failColor)),
                        ),
                      if (record.failDesc.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text('${Translations.get('fail_desc', logic.lang)}: ${record.failDesc}', style: TextStyle(color: theme.failColor)),
                        ),
                    ]
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBarcodeHistoryView(BuildContext context, AppLogic logic, ThemeProvider theme) {
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
          color: Colors.red.withOpacity(0.1),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('${Translations.get('error_for', logic.lang)} $sn: $error', style: TextStyle(color: theme.failColor)),
      );
    }

    if (records == null || records.isEmpty) {
      return Center(child: Text('${Translations.get('no_records', logic.lang)} $sn', style: TextStyle(color: theme.textSecondary)));
    }

    final displayRecords = _filterSortBarcodeRecords(records, _barcodeListState);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRecordsHeader(
          sn: sn,
          count: records.length,
          theme: theme,
          lang: logic.lang,
          listState: _barcodeListState,
          sortOptions: [
            _SortOption('process_time', Translations.get('process_time', logic.lang)),
            _SortOption('process_name', Translations.get('process_name', logic.lang)),
            _SortOption('result', Translations.get('result', logic.lang)),
            _SortOption('line_station', Translations.get('line_station_code', logic.lang)),
          ],
        ),
        const SizedBox(height: 12),
        if (displayRecords.isEmpty)
          Expanded(child: Center(child: Text(Translations.get('no_matches', logic.lang), style: TextStyle(color: theme.textSecondary))))
        else
        Expanded(
          child: ListView.builder(
            itemCount: displayRecords.length,
            itemBuilder: (context, index) {
              final record = displayRecords[index];
              final isPass = record.result.toLowerCase() == 'pass';

              return Container(
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
                            record.currentProcessName.isNotEmpty ? record.currentProcessName : record.currentProcessCode,
                            style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        if (record.result.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPass ? theme.passColor : theme.failColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              record.result.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(Translations.get('process_time', logic.lang), record.operateDt, theme, highlight: true),
                    _buildInfoRow(Translations.get('line_station_code', logic.lang), record.lineStation, theme),
                    _buildInfoRow(Translations.get('work_order', logic.lang), record.woNo, theme),
                    _buildInfoRow(Translations.get('product_no', logic.lang), record.productNo, theme),
                    _buildInfoRow(Translations.get('customer_sn', logic.lang), record.customerSn, theme),
                    _buildInfoRow(Translations.get('operator', logic.lang), record.operatorName, theme),
                    _buildInfoRow(Translations.get('equipment', logic.lang), record.eqpId, theme),
                    if (record.errorCode.isNotEmpty)
                      _buildInfoRow(Translations.get('error_code', logic.lang), record.errorCode, theme),
                    if (record.testResultMsg.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('${Translations.get('failure_reason', logic.lang)}: ${record.testResultMsg}', style: TextStyle(color: theme.failColor)),
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

  Widget _buildWipComponentsView(BuildContext context, AppLogic logic, ThemeProvider theme) {
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
          color: Colors.red.withOpacity(0.1),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('${Translations.get('error_for', logic.lang)} $sn: $error', style: TextStyle(color: theme.failColor)),
      );
    }

    if (records == null || records.isEmpty) {
      return Center(child: Text('${Translations.get('no_records', logic.lang)} $sn', style: TextStyle(color: theme.textSecondary)));
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
          listState: _wipListState,
          sortOptions: [
            _SortOption('process_time', Translations.get('process_time', logic.lang)),
            _SortOption('material_no', Translations.get('material_no', logic.lang)),
            _SortOption('material_category', Translations.get('material_category', logic.lang)),
            _SortOption('manufacturer', Translations.get('manufacturer', logic.lang)),
          ],
        ),
        const SizedBox(height: 12),
        if (displayRecords.isEmpty)
          Expanded(child: Center(child: Text(Translations.get('no_matches', logic.lang), style: TextStyle(color: theme.textSecondary))))
        else
        Expanded(
          child: ListView.builder(
            itemCount: displayRecords.length,
            itemBuilder: (context, index) {
              final record = displayRecords[index];

              return Container(
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
                            style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        if (record.materialCategory.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade600,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              record.materialCategory,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(Translations.get('manufacturer', logic.lang), record.mfgName, theme),
                    _buildInfoRow(Translations.get('mfg_pn', logic.lang), record.mfgPn, theme),
                    _buildInfoRow(Translations.get('component_sn', logic.lang), record.scannedCsn, theme, highlight: true),
                    _buildInfoRow(Translations.get('package_id', logic.lang), record.pkgId, theme),
                    _buildInfoRow(Translations.get('date_code', logic.lang), record.dateCode, theme),
                    _buildInfoRow(Translations.get('quantity', logic.lang), record.installedQty, theme),
                    _buildInfoRow(Translations.get('line_station_code', logic.lang), record.stationCode, theme),
                    _buildInfoRow(Translations.get('process_time', logic.lang), record.createdDt, theme),
                    _buildInfoRow(Translations.get('operator', logic.lang), record.creator, theme),
                  ],
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
  List<TestRecord> _filterSortTestRecords(List<TestRecord> records, _ListViewState listState) {
    var result = records;
    final q = listState.filter.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((r) => [
            r.stationId, r.productNo, r.internalSn, r.customerSn, r.processCode,
            r.lineStationCode, r.loc, r.productSeries, r.woNo, r.testDate,
            r.testResult, r.empNo, r.errCode, r.failureReason, r.failDesc,
          ].any((f) => f.toLowerCase().contains(q))).toList();
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

  List<SnProcessRecord> _filterSortBarcodeRecords(List<SnProcessRecord> records, _ListViewState listState) {
    var result = records;
    final q = listState.filter.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((r) => [
            r.currentProcessCode, r.currentProcessName, r.lineStation, r.woNo,
            r.productNo, r.customerSn, r.operatorName, r.eqpId, r.errorCode,
            r.testResultMsg, r.operateDt, r.result,
          ].any((f) => f.toLowerCase().contains(q))).toList();
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
            cmp = (a.currentProcessName.isNotEmpty ? a.currentProcessName : a.currentProcessCode)
                .compareTo(b.currentProcessName.isNotEmpty ? b.currentProcessName : b.currentProcessCode);
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

  List<WipComponentRecord> _filterSortWipRecords(List<WipComponentRecord> records, _ListViewState listState) {
    var result = records;
    final q = listState.filter.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((r) => [
            r.materialNo, r.materialCategory, r.mfgName, r.mfgPn, r.dateCode,
            r.scannedCsn, r.pkgId, r.stationCode, r.processCode, r.creator, r.createdDt,
          ].any((f) => f.toLowerCase().contains(q))).toList();
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

  Widget _buildRecordsHeader({
    required String sn,
    required int count,
    required ThemeProvider theme,
    required String lang,
    required _ListViewState listState,
    required List<_SortOption> sortOptions,
  }) {
    final countSuffix = count > 1 ? ' ($count)' : '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            '${Translations.get('records_for', lang)}: $sn$countSuffix',
            overflow: TextOverflow.ellipsis,
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
              prefixIcon: Icon(Icons.search_rounded, size: 16, color: theme.textSecondary),
              prefixIconConstraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              suffixIcon: listState.filter.isEmpty
                  ? null
                  : InkWell(
                      onTap: () => setState(() {
                        listState.filterCtrl.clear();
                        listState.filter = '';
                      }),
                      child: Icon(Icons.close_rounded, size: 14, color: theme.textSecondary),
                    ),
              suffixIconConstraints: const BoxConstraints(minWidth: 26, minHeight: 26),
              filled: true,
              fillColor: theme.cardBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: theme.isDark ? Colors.white24 : Colors.black12),
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

  Widget _buildSortButton(ThemeProvider theme, String lang, _ListViewState listState, List<_SortOption> options) {
    final currentLabel = listState.sortField == null
        ? Translations.get('sort', lang)
        : options.firstWhere((o) => o.key == listState.sortField).label;

    return PopupMenuButton<String>(
      tooltip: Translations.get('sort', lang),
      offset: const Offset(0, 38),
      onSelected: (key) {
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
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: '',
          child: Text(Translations.get('default', lang)),
        ),
        ...options.map((o) => PopupMenuItem<String>(
              value: o.key,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    child: listState.sortField == o.key
                        ? Icon(listState.sortAsc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 14)
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Text(o.label),
                ],
              ),
            )),
      ],
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: theme.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.isDark ? Colors.white24 : Colors.black12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              listState.sortField == null
                  ? Icons.sort_rounded
                  : (listState.sortAsc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
              size: 16,
              color: theme.textPrimary,
            ),
            const SizedBox(width: 4),
            Text(currentLabel, style: TextStyle(fontSize: 12.5, color: theme.textPrimary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeProvider theme, {bool highlight = false}) {
    if (value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(color: theme.textSecondary, fontSize: 13)),
          if (highlight)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Text(value, style: TextStyle(color: theme.isDark ? Colors.blue.shade200 : Colors.blue.shade700, fontSize: 13, fontWeight: FontWeight.bold)),
            )
          else
            Expanded(child: Text(value, style: TextStyle(color: theme.textPrimary, fontSize: 13))),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, AppLogic logic, ThemeProvider theme) {
    final TextEditingController tokenCtrl = TextEditingController(text: logic.token);
    final TextEditingController langCtrl = TextEditingController(text: logic.lang);
    final TextEditingController operationIdCtrl = TextEditingController(text: logic.operationId);
    final TextEditingController uuidCtrl = TextEditingController(text: logic.uuid);
    final TextEditingController cookieCtrl = TextEditingController(text: logic.cookie);
    
    bool isExpanded = false;
    bool isVerifying = false;
    bool isFetchingCdp = false;

    Widget buildField(String label, TextEditingController ctrl, {int maxLines = 1, String? hint}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: theme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            TextField(
              controller: ctrl,
              style: TextStyle(color: theme.textPrimary, fontSize: 13),
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: theme.textSecondary.withOpacity(0.5), fontSize: 12),
                filled: true,
                fillColor: theme.isDark ? const Color(0xFF1E1F22) : const Color(0xFFF2F4F7),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: theme.isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue.shade600, width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: theme.isDark ? const Color(0xFF2B2D30) : Colors.white,
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.settings_suggest_rounded, color: Colors.blue.shade600, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    Translations.get('settings', logic.lang),
                    style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const Spacer(),
                  // Connection Health Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (logic.isConnectionValid ?? false) ? Colors.green.withOpacity(0.12) : Colors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (logic.isConnectionValid ?? false) ? Colors.green.withOpacity(0.3) : Colors.amber.withOpacity(0.4),
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
                            color: (logic.isConnectionValid ?? false) ? Colors.green : Colors.amber.shade700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          (logic.isConnectionValid ?? false)
                              ? Translations.get('status_connected', logic.lang)
                              : Translations.get('status_check', logic.lang),
                          style: TextStyle(
                            color: (logic.isConnectionValid ?? false) ? Colors.green.shade700 : Colors.amber.shade800,
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),

                      // Smart 2-Step Auto Sync Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: theme.isDark
                                ? [const Color(0xFF1E2638), const Color(0xFF1A2130)]
                                : [const Color(0xFFEBF3FE), const Color(0xFFF4F8FE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.bolt_rounded, color: Colors.blue.shade600, size: 20),
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
                              style: TextStyle(color: theme.textSecondary, fontSize: 11),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                                    label: Text(Translations.get('btn_open_browser', logic.lang)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade600,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Icon(Icons.sync_rounded, size: 16),
                                    label: Text(
                                      isFetchingCdp
                                          ? Translations.get('status_fetching', logic.lang)
                                          : Translations.get('btn_sync_credentials', logic.lang),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal.shade600,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                    onPressed: isFetchingCdp
                                        ? null
                                        : () async {
                                            setDialogState(() => isFetchingCdp = true);
                                            final creds = await BrowserHelper.fetchCredentialsFromBrowser();
                                            setDialogState(() => isFetchingCdp = false);

                                            if (creds != null) {
                                              if (creds.token != null && creds.token!.isNotEmpty) tokenCtrl.text = creds.token!;
                                              if (creds.operationId != null && creds.operationId!.isNotEmpty) operationIdCtrl.text = creds.operationId!;
                                              if (creds.uuid != null && creds.uuid!.isNotEmpty) uuidCtrl.text = creds.uuid!;
                                              if (creds.cookie != null && creds.cookie!.isNotEmpty) cookieCtrl.text = creds.cookie!;

                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(Translations.get('fetched_success', logic.lang)), backgroundColor: Colors.green),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text(Translations.get('fetched_fail', logic.lang)), backgroundColor: Colors.red),
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
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: theme.isDark ? const Color(0xFF1E1F22) : const Color(0xFFF7F9FC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isExpanded ? Colors.blue.shade600 : (theme.isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 18,
                                  color: isExpanded ? Colors.blue.shade600 : theme.textSecondary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    isExpanded
                                        ? Translations.get('hide_advanced', logic.lang)
                                        : Translations.get('show_advanced', logic.lang),
                                    style: TextStyle(
                                      color: isExpanded ? Colors.blue.shade600 : theme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Icon(
                                  isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                  color: isExpanded ? Colors.blue.shade600 : theme.textSecondary,
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
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.isDark ? const Color(0xFF1E1F22) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Parse Raw Header Button
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.content_paste_rounded, size: 16),
                                    label: Text(Translations.get('paste_raw_http', logic.lang)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      side: BorderSide(color: Colors.blue.shade600.withOpacity(0.4)),
                                      foregroundColor: Colors.blue.shade600,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                    onPressed: () {
                                      final TextEditingController pasteCtrl = TextEditingController();
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                          backgroundColor: theme.isDark ? const Color(0xFF2B2D30) : Colors.white,
                                          title: Text(Translations.get('paste_raw_http', logic.lang), style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                                          content: SizedBox(
                                            width: 450,
                                            child: TextField(
                                              controller: pasteCtrl,
                                              maxLines: 10,
                                              style: TextStyle(color: theme.textPrimary, fontSize: 12),
                                              decoration: InputDecoration(
                                                hintText: 'GET /api/... HTTP/1.1\nAuthorization: bearer ...\nCookie: ...',
                                                hintStyle: TextStyle(color: theme.textSecondary.withOpacity(0.6)),
                                                filled: true,
                                                fillColor: theme.sidebarBg,
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: Text(Translations.get('cancel', logic.lang)),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                final creds = BrowserHelper.parseRawHttpRequest(pasteCtrl.text);
                                                if (creds.token != null && creds.token!.isNotEmpty) tokenCtrl.text = creds.token!;
                                                if (creds.lang != null && creds.lang!.isNotEmpty) langCtrl.text = creds.lang!;
                                                if (creds.operationId != null && creds.operationId!.isNotEmpty) operationIdCtrl.text = creds.operationId!;
                                                if (creds.uuid != null && creds.uuid!.isNotEmpty) uuidCtrl.text = creds.uuid!;
                                                if (creds.cookie != null && creds.cookie!.isNotEmpty) cookieCtrl.text = creds.cookie!;
                                                
                                                Navigator.pop(ctx);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text(Translations.get('fetched_success', logic.lang)), backgroundColor: Colors.green),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600),
                                              child: Text(Translations.get('parse_http', logic.lang), style: const TextStyle(color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 14),
                                buildField(Translations.get('mes_token', logic.lang), tokenCtrl, maxLines: 2, hint: 'Bearer token string'),
                                buildField(Translations.get('cookie', logic.lang), cookieCtrl, maxLines: 2, hint: 'cultureName=...; CloudMES_Token=...'),
                                Row(
                                  children: [
                                    Expanded(child: buildField(Translations.get('operation_id', logic.lang), operationIdCtrl)),
                                    const SizedBox(width: 10),
                                    Expanded(child: buildField(Translations.get('uuid', logic.lang), uuidCtrl)),
                                  ],
                                ),
                                buildField(Translations.get('language', logic.lang), langCtrl, hint: 'en / vi-VN / zh-CN'),
                              ],
                            ),
                          ),
                        ),
                        crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 200),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              actionsAlignment: MainAxisAlignment.spaceBetween,
              actions: [
                // Left aligned items
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('v$appVersion', style: TextStyle(color: theme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: isVerifying
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.verified_outlined, size: 18, color: Colors.blue.shade600),
                      tooltip: Translations.get('verify_connection', logic.lang),
                      onPressed: isVerifying
                          ? null
                          : () async {
                              setDialogState(() => isVerifying = true);
                              final res = await logic.verifySettings(tokenCtrl.text, langCtrl.text, operationIdCtrl.text, uuidCtrl.text, cookieCtrl.text);
                              setDialogState(() => isVerifying = false);
                              if (res == null) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(Translations.get('connection_valid', logic.lang), style: TextStyle(color: theme.passColor)), duration: const Duration(seconds: 2)));
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid: $res', style: TextStyle(color: theme.failColor)), duration: const Duration(seconds: 3)));
                              }
                            },
                    ),
                    TextButton(
                      onPressed: () {
                        showAboutDialog(
                          context: context,
                          applicationName: appName,
                          applicationVersion: appVersion,
                          applicationLegalese: '© 2026 JA Tech.\nAll rights reserved.',
                          children: [
                            const SizedBox(height: 12),
                            Text(
                              Translations.get('about_detail', logic.lang),
                              style: TextStyle(color: theme.textPrimary, fontSize: 13, height: 1.4),
                            ),
                          ],
                        );
                      },
                      child: Text(Translations.get('about', logic.lang), style: TextStyle(color: Colors.blue.shade600, fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            backgroundColor: theme.isDark ? const Color(0xFF2B2D30) : Colors.white,
                            title: Text(Translations.get('user_guide', logic.lang), style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold)),
                            content: SizedBox(
                              width: 520,
                              child: SingleChildScrollView(
                                child: Text(
                                  Translations.get('user_guide_detail', logic.lang),
                                  style: TextStyle(color: theme.textPrimary, fontSize: 13, height: 1.5),
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('OK'),
                              )
                            ],
                          ),
                        );
                      },
                      child: Text(Translations.get('user_guide', logic.lang), style: TextStyle(color: Colors.blue.shade600, fontSize: 12)),
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
                      },
                      child: Text(Translations.get('default', logic.lang), style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(Translations.get('cancel', logic.lang), style: TextStyle(color: theme.textSecondary, fontSize: 12)),
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
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(Translations.get('save', logic.lang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: theme.isDark ? const Color(0xFF2B2D30) : Colors.white,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 24),
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
                      style: TextStyle(color: theme.textSecondary, fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    
                    // 2-Step Sync Wizard Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.isDark ? Colors.blue.withOpacity(0.08) : Colors.blue.shade50.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.isDark ? Colors.blue.withOpacity(0.2) : Colors.blue.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.bolt, color: Colors.blue.shade700, size: 18),
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
                            style: TextStyle(color: theme.textSecondary, fontSize: 11),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await BrowserHelper.launchBrowser();
                                  },
                                  icon: const Icon(Icons.open_in_browser, size: 16),
                                  label: Text(
                                    Translations.get('btn_open_browser', logic.lang),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: isSyncing
                                      ? null
                                      : () async {
                                          setDialogState(() => isSyncing = true);
                                          final creds = await BrowserHelper.fetchCredentialsFromBrowser();
                                          setDialogState(() => isSyncing = false);

                                          if (creds != null) {
                                            await logic.updateSettings(
                                              token: (creds.token != null && creds.token!.isNotEmpty) ? creds.token! : logic.token,
                                              lang: logic.lang,
                                              operationId: (creds.operationId != null && creds.operationId!.isNotEmpty) ? creds.operationId! : logic.operationId,
                                              uuid: (creds.uuid != null && creds.uuid!.isNotEmpty) ? creds.uuid! : logic.uuid,
                                              cookie: (creds.cookie != null && creds.cookie!.isNotEmpty) ? creds.cookie! : logic.cookie,
                                            );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    Translations.get('fetched_success', logic.lang),
                                                    style: const TextStyle(color: Colors.greenAccent),
                                                  ),
                                                  duration: const Duration(seconds: 2),
                                                ),
                                              );
                                              Navigator.pop(ctx);
                                            }
                                          } else {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    Translations.get('fetched_fail', logic.lang),
                                                    style: TextStyle(color: theme.failColor),
                                                  ),
                                                  duration: const Duration(seconds: 3),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                  icon: isSyncing
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                        )
                                      : const Icon(Icons.sync_rounded, size: 16),
                                  label: Text(
                                    isSyncing
                                        ? Translations.get('status_fetching', logic.lang)
                                        : Translations.get('btn_sync_credentials', logic.lang),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal.shade700,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
}

class _SortOption {
  final String key;
  final String label;
  const _SortOption(this.key, this.label);
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
    final bgColor = !widget.keepExpanded && _isHovering && widget.hoverBackground != null
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
                      style: TextStyle(color: widget.foreground, fontWeight: FontWeight.w600, fontSize: 12.5),
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
