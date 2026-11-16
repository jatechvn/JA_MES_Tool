part of 'settings_dialog.dart';

extension _SettingsMesApiTabExt on _AppSettingsDialogState {
  Widget _buildMesApiTab(AppColors colors) {
    final logic = widget.logic;
    return ListView(
      key: const PageStorageKey('settings_tab_mes_api'),
      physics: const BouncingScrollPhysics(),
      children: [
        // Direct Account Login & Auto-Login Card
        BentoCard(
          colors: colors,
          padding: const EdgeInsets.all(16),
          borderRadius: 14,
          isFeatured: true,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      (logic.isConnectionValid == true &&
                                  logic.token.trim().isNotEmpty
                              ? colors.accentEmerald
                              : colors.accentColor)
                          .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  logic.isConnectionValid == true &&
                          logic.token.trim().isNotEmpty
                      ? Icons.verified_user_rounded
                      : Icons.person_outline_rounded,
                  color:
                      logic.isConnectionValid == true &&
                          logic.token.trim().isNotEmpty
                      ? colors.accentEmerald
                      : colors.accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Translations.get('account_section_title', logic.lang),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      logic.isConnectionValid == true &&
                              logic.token.trim().isNotEmpty
                          ? '${Translations.get('logged_in_as', logic.lang)} '
                                '${logic.activeAccount.isNotEmpty ? logic.activeAccount : 'LIVE'} '
                                '(${logic.loginMethod == 'CLOUDMES' ? 'CloudMES' : 'SSO'})'
                          : Translations.get('not_logged_in', logic.lang),
                      style: TextStyle(
                        color:
                            logic.isConnectionValid == true &&
                                logic.token.trim().isNotEmpty
                            ? colors.accentEmerald
                            : colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (logic.isConnectionValid == true &&
                  logic.token.trim().isNotEmpty) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.accentRose,
                    side: BorderSide(
                      color: colors.accentRose.withValues(alpha: 0.45),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    await logic.logoutAccount();
                    _rebuild(() {
                      _tokenCtrl.text = logic.token;
                      _cookieCtrl.text = logic.cookie;
                    });
                  },
                  icon: const Icon(Icons.logout_rounded, size: 15),
                  label: Text(
                    Translations.get('logout_btn', logic.lang),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  await showMesLoginDialog(
                    context,
                    logic: logic,
                    colors: colors,
                  );
                  _rebuild(() {
                    _tokenCtrl.text = logic.token;
                    _uuidCtrl.text = logic.uuid;
                    _cookieCtrl.text = logic.cookie;
                  });
                },
                icon: const Icon(Icons.login_rounded, size: 15),
                label: Text(
                  Translations.get(
                    logic.isConnectionValid == true &&
                            logic.token.trim().isNotEmpty
                        ? 'switch_account_btn'
                        : 'login_btn',
                    logic.lang,
                  ),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // CDP Auto Sync Card
        BentoCard(
          colors: colors,
          padding: const EdgeInsets.all(16),
          borderRadius: 14,
          isFeatured: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt_rounded, color: colors.accentAmber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    Translations.get('cdp_sync_title', logic.lang),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                Translations.get('cdp_sync_desc', logic.lang),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.accentColor,
                        side: BorderSide(
                          color: colors.accentColor.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                      label: Text(
                        Translations.get('btn_open_browser', logic.lang),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accentEmerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: _isSyncingCdp
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.sync_rounded, size: 16),
                      label: Text(
                        _isSyncingCdp
                            ? Translations.get('status_fetching', logic.lang)
                            : Translations.get(
                                'btn_sync_credentials',
                                logic.lang,
                              ),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: _isSyncingCdp
                          ? null
                          : () async {
                              _rebuild(() => _isSyncingCdp = true);
                              final creds =
                                  await BrowserHelper.fetchCredentialsFromBrowser();
                              if (!mounted) return;
                              _rebuild(() => _isSyncingCdp = false);
                              if (creds != null &&
                                  creds.token != null &&
                                  creds.token!.isNotEmpty) {
                                _tokenCtrl.text = creds.token!;
                                _uuidCtrl.text = creds.uuid ?? '';
                                _opIdCtrl.text = creds.operationId ?? '';
                                _cookieCtrl.text = creds.cookie ?? '';
                                if (widget.parentContext.mounted) {
                                  showAppToast(
                                    widget.parentContext,
                                    colors: colors,
                                    message: Translations.get(
                                      'fetched_success',
                                      logic.lang,
                                    ),
                                    icon: Icons.check_circle_rounded,
                                    accentColor: colors.accentEmerald,
                                  );
                                }
                              } else {
                                if (widget.parentContext.mounted) {
                                  showAppToast(
                                    widget.parentContext,
                                    colors: colors,
                                    message: Translations.get(
                                      'fetched_fail',
                                      logic.lang,
                                    ),
                                    icon: Icons.error_outline_rounded,
                                    accentColor: colors.accentRose,
                                  );
                                }
                              }
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Credentials Input fields
        _buildTextField(
          label: Translations.get('mes_token', logic.lang),
          controller: _tokenCtrl,
          colors: colors,
          maxLines: 2,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: Translations.get('operation_id', logic.lang),
                controller: _opIdCtrl,
                colors: colors,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTextField(
                label: Translations.get('uuid', logic.lang),
                controller: _uuidCtrl,
                colors: colors,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildTextField(
          label: Translations.get('cookie', logic.lang),
          controller: _cookieCtrl,
          colors: colors,
          maxLines: 2,
        ),
        const SizedBox(height: 16),

        // Test Connection Button
        Row(
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.accentCyan,
                side: BorderSide(
                  color: colors.accentCyan.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: _isTestingConnection
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.accentCyan,
                      ),
                    )
                  : Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: colors.accentCyan,
                    ),
              label: Text(
                Translations.get('verify_connection', logic.lang),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: _isTestingConnection
                  ? null
                  : () async {
                      _rebuild(() {
                        _isTestingConnection = true;
                        _connectionTestResult = null;
                        _connectionTestMsg = null;
                      });
                      final ok = await logic.testConnection(
                        testToken: _tokenCtrl.text.trim(),
                        testOpId: _opIdCtrl.text.trim(),
                        testUuid: _uuidCtrl.text.trim(),
                        testCookie: _cookieCtrl.text.trim(),
                      );
                      if (!mounted) return;
                      _rebuild(() {
                        _isTestingConnection = false;
                        _connectionTestResult = ok;
                        _connectionTestMsg = ok
                            ? Translations.get('connection_valid', logic.lang)
                            : logic.connectionError ??
                                  Translations.get(
                                    'connection_failed',
                                    logic.lang,
                                  );
                      });
                    },
            ),
            const SizedBox(width: 12),
            if (_connectionTestResult != null)
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      _connectionTestResult == true
                          ? Icons.check_circle_rounded
                          : Icons.error_outline_rounded,
                      color: _connectionTestResult == true
                          ? colors.accentEmerald
                          : colors.accentRose,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _connectionTestMsg ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _connectionTestResult == true
                              ? colors.accentEmerald
                              : colors.accentRose,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
