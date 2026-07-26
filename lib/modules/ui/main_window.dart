import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic.dart';
import '../constants.dart';
import '../translations.dart';
import '../browser_helper.dart';
import 'styles.dart';

class MainWindow extends StatefulWidget {
  const MainWindow({Key? key}) : super(key: key);

  @override
  State<MainWindow> createState() => _MainWindowState();
}

class _MainWindowState extends State<MainWindow> {
  final TextEditingController _snController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final logic = context.watch<AppLogic>();

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
                      const Spacer(),
                      
                      // Template CSV
                      ElevatedButton.icon(
                        icon: const Icon(Icons.file_present, size: 18),
                        label: Text(Translations.get('template', logic.lang)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          logic.downloadTemplateCsv();
                        },
                      ),
                      const SizedBox(width: 8),

                      // Import CSV
                      ElevatedButton.icon(
                        icon: const Icon(Icons.file_upload, size: 18),
                        label: Text(Translations.get('import', logic.lang)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          logic.importCsv();
                        },
                      ),
                      const SizedBox(width: 8),
                      
                      // Export CSV
                      ElevatedButton.icon(
                        icon: const Icon(Icons.file_download, size: 18),
                        label: Text(Translations.get('export', logic.lang)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          logic.exportCsv();
                        },
                      ),
                      const SizedBox(width: 16),
                      // Language Toggle
                      ElevatedButton(
                        onPressed: () => logic.cycleLanguage(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.cardBg,
                          foregroundColor: theme.textPrimary,
                          elevation: 1,
                          side: BorderSide(color: theme.isDark ? Colors.white24 : Colors.black12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        child: Text(logic.lang.toUpperCase(), style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      const SizedBox(width: 8),

                      // Theme Toggle
                      Container(
                        decoration: BoxDecoration(
                          color: theme.cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.isDark ? Colors.white24 : Colors.black12),
                        ),
                        child: IconButton(
                          icon: Icon(
                            theme.isDark ? Icons.light_mode : Icons.dark_mode, 
                            color: theme.isDark ? Colors.amber : Colors.indigo.shade600,
                          ),
                          onPressed: () => context.read<ThemeProvider>().toggleTheme(),
                          tooltip: Translations.get('toggle_theme', logic.lang),
                        ),
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
                    child: _buildDetailView(context, logic, theme),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${Translations.get('records_for', logic.lang)}: $sn', 
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
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
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
    
    Widget buildField(String label, TextEditingController ctrl, {int maxLines = 1}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: theme.textSecondary, fontSize: 13)),
            const SizedBox(height: 4),
            TextField(
              controller: ctrl,
              style: TextStyle(color: theme.textPrimary, fontSize: 13),
              maxLines: maxLines,
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.sidebarBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
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
        return AlertDialog(
          backgroundColor: theme.isDark ? const Color(0xFF242526) : Colors.white,
          title: Text(Translations.get('settings', logic.lang), style: TextStyle(color: theme.textPrimary)),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Auto Fetch & Helper Tools
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.blue.shade700, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              Translations.get('auto_login_browser', logic.lang),
                              style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.open_in_browser, size: 16),
                              label: Text(Translations.get('auto_login_browser', logic.lang)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              onPressed: () async {
                                await BrowserHelper.launchBrowser();
                              },
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.cloud_download, size: 16),
                              label: Text(Translations.get('get_from_browser', logic.lang)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              onPressed: () async {
                                final creds = await BrowserHelper.fetchCredentialsFromBrowser();
                                if (creds != null) {
                                  if (creds.token != null && creds.token!.isNotEmpty) tokenCtrl.text = creds.token!;
                                  // Keep current lang — don't overwrite from browser
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
                            OutlinedButton.icon(
                              icon: const Icon(Icons.content_paste, size: 16),
                              label: Text(Translations.get('paste_raw_http', logic.lang)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              onPressed: () {
                                final TextEditingController pasteCtrl = TextEditingController();
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: theme.cardBg,
                                    title: Text(Translations.get('paste_raw_http', logic.lang), style: TextStyle(color: theme.textPrimary)),
                                    content: SizedBox(
                                      width: 450,
                                      child: TextField(
                                        controller: pasteCtrl,
                                        maxLines: 10,
                                        style: TextStyle(color: theme.textPrimary, fontSize: 12),
                                        decoration: InputDecoration(
                                          hintText: 'GET /api/... HTTP/1.1\nAuthorization: bearer ...\nCookie: ...',
                                          hintStyle: TextStyle(color: theme.textSecondary),
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
                                        child: Text(Translations.get('parse_http', logic.lang)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  buildField(Translations.get('mes_token', logic.lang), tokenCtrl, maxLines: 3),
                  buildField(Translations.get('language', logic.lang), langCtrl),
                  buildField(Translations.get('operation_id', logic.lang), operationIdCtrl),
                  buildField(Translations.get('uuid', logic.lang), uuidCtrl),
                  buildField(Translations.get('cookie', logic.lang), cookieCtrl, maxLines: 3),
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
                Text('v$appVersion', style: TextStyle(color: theme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Verify Connection',
                  onPressed: () async {
                    final res = await logic.verifySettings(tokenCtrl.text, langCtrl.text, operationIdCtrl.text, uuidCtrl.text, cookieCtrl.text);
                    if (res == null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Connection valid!', style: TextStyle(color: theme.passColor)), duration: const Duration(seconds: 2)));
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
                  child: Text(Translations.get('about', logic.lang), style: TextStyle(color: Colors.blue.shade600)),
                ),
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: theme.cardBg,
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
                  child: Text(Translations.get('user_guide', logic.lang), style: TextStyle(color: Colors.blue.shade600)),
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
                  child: Text(Translations.get('default', logic.lang), style: TextStyle(color: theme.textSecondary)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(Translations.get('cancel', logic.lang), style: TextStyle(color: theme.textSecondary)),
                ),
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                  child: Text(Translations.get('save', logic.lang), style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        );
      }
    );
  }
}
