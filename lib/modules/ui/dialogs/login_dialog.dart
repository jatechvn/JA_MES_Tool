import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../api_client.dart';
import '../../browser_helper.dart';
import '../../logic.dart';
import '../../translations.dart';
import '../styles.dart';

bool _isMesLoginDialogOpen = false;
bool get isMesLoginDialogOpen => _isMesLoginDialogOpen;

Future<void> showMesLoginDialog(
  BuildContext context, {
  required AppLogic logic,
  required AppColors colors,
  VoidCallback? onOpenFullSettings,
}) async {
  if (_isMesLoginDialogOpen) return;
  _isMesLoginDialogOpen = true;
  try {
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
            child: MesLoginDialog(
              logic: logic,
              colors: colors,
              onOpenFullSettings: onOpenFullSettings,
            ),
          ),
        );
      },
    );
  } finally {
    _isMesLoginDialogOpen = false;
  }
}

class MesLoginDialog extends StatefulWidget {
  final AppLogic logic;
  final AppColors colors;
  final VoidCallback? onOpenFullSettings;

  const MesLoginDialog({
    super.key,
    required this.logic,
    required this.colors,
    this.onOpenFullSettings,
  });

  @override
  State<MesLoginDialog> createState() => _MesLoginDialogState();
}

class _MesLoginDialogState extends State<MesLoginDialog> {
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _captchaCtrl;
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  late String _loginMethod;
  late bool _rememberPassword;
  late bool _autoLogin;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _isSyncingBrowser = false;
  bool _requiresCaptcha = false;
  MesCaptchaData? _captchaData;
  String _statusMessage = '';
  bool _isStatusSuccess = false;

  @override
  void initState() {
    super.initState();
    final initialUser = widget.logic.username.trim().isNotEmpty
        ? widget.logic.username.trim()
        : widget.logic.activeAccount;
    _usernameCtrl = TextEditingController(text: initialUser);
    _passwordCtrl = TextEditingController(text: widget.logic.savedPassword);
    _captchaCtrl = TextEditingController();
    _loginMethod = widget.logic.loginMethod;
    _rememberPassword = widget.logic.rememberPassword;
    _autoLogin = widget.logic.autoLogin;
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _captchaCtrl.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _loadCaptcha() async {
    final captcha = await ApiClient.fetchCaptcha(
      lang: widget.logic.lang,
      uuid: widget.logic.uuid,
    );
    if (!mounted) return;
    setState(() {
      _captchaData = captcha;
    });
  }

  Uint8List? _decodeCaptchaBytes(String rawBase64) {
    try {
      final clean = rawBase64.contains(',')
          ? rawBase64.split(',').last.trim()
          : rawBase64.trim();
      if (clean.isEmpty) return null;
      return base64Decode(clean);
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleLogin() async {
    if (_isSubmitting || widget.logic.isLoggingIn) return;
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;
    final lang = widget.logic.lang;

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _statusMessage = Translations.get('login_empty_error', lang);
        _isStatusSuccess = false;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _statusMessage = '';
    });

    final result = await widget.logic.loginWithAccount(
      username: username,
      password: password,
      loginMethod: _loginMethod,
      rememberPassword: _rememberPassword,
      autoLogin: _rememberPassword && _autoLogin,
      captchaKey: _captchaData?.key,
      captchaCode: _requiresCaptcha ? _captchaCtrl.text.trim() : null,
    );

    if (!mounted) return;

    if (result.success) {
      final resolvedUser = result.username.isNotEmpty
          ? result.username
          : username;
      setState(() {
        _isSubmitting = false;
        _isStatusSuccess = true;
        _statusMessage = Translations.get(
          'login_success_msg',
          lang,
        ).replaceAll('{user}', resolvedUser);
      });
      await Future.delayed(const Duration(milliseconds: 550));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      final needCaptcha = result.requiresCaptcha && _loginMethod == 'CLOUDMES';
      setState(() {
        _isSubmitting = false;
        _isStatusSuccess = false;
        if (needCaptcha) {
          _requiresCaptcha = true;
        }
        _statusMessage = Translations.get(
          'login_failed_msg',
          lang,
        ).replaceAll('{error}', result.message);
      });
      if (needCaptcha) {
        await _loadCaptcha();
      }
    }
  }

  Future<void> _handleLogout() async {
    final lang = widget.logic.lang;
    await widget.logic.logoutAccount();
    if (!mounted) return;
    setState(() {
      _passwordCtrl.clear();
      _statusMessage = Translations.get('logout_success_msg', lang);
      _isStatusSuccess = true;
    });
    _usernameFocus.requestFocus();
    _usernameCtrl.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _usernameCtrl.text.length,
    );
  }

  Future<void> _handleSyncFromBrowser() async {
    if (_isSyncingBrowser) return;
    final lang = widget.logic.lang;
    setState(() {
      _isSyncingBrowser = true;
      _statusMessage = '';
    });

    final creds = await BrowserHelper.fetchCredentialsFromBrowser();
    if (!mounted) return;

    if (creds != null &&
        creds.token != null &&
        creds.token!.trim().isNotEmpty) {
      await widget.logic.updateCredentials(
        token: creds.token!,
        uuid: creds.uuid ?? widget.logic.uuid,
        operationId: creds.operationId ?? widget.logic.operationId,
        cookie: creds.cookie ?? widget.logic.cookie,
      );
      if (!mounted) return;
      setState(() {
        _isSyncingBrowser = false;
        _isStatusSuccess = true;
        _statusMessage = Translations.get('fetched_success', lang);
      });
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      setState(() {
        _isSyncingBrowser = false;
        _isStatusSuccess = false;
        _statusMessage = Translations.get('fetched_fail', lang);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return ListenableBuilder(
      listenable: widget.logic,
      builder: (context, _) {
        final lang = widget.logic.lang;
        final isLoggedIn =
            widget.logic.isConnectionValid == true &&
            widget.logic.token.trim().isNotEmpty;
        final activeUser = widget.logic.activeAccount;

        return BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: widget.logic.dialogBlur,
            sigmaY: widget.logic.dialogBlur,
          ),
          child: Dialog(
            backgroundColor: colors.cardBg.withValues(
              alpha: widget.logic.dialogOpacity.clamp(0.15, 1.0),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isLoggedIn
                    ? colors.accentEmerald.withValues(alpha: 0.45)
                    : colors.accentColor.withValues(alpha: 0.45),
                width: 1.4,
              ),
            ),
            child: Container(
              width: 470,
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                (isLoggedIn
                                        ? colors.accentEmerald
                                        : colors.accentColor)
                                    .withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isLoggedIn
                                ? Icons.verified_user_rounded
                                : Icons.lock_person_rounded,
                            color: isLoggedIn
                                ? colors.accentEmerald
                                : colors.accentColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Translations.get('mes_login_title', lang),
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                Translations.get('mes_login_subtitle', lang),
                                style: TextStyle(
                                  color: colors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: colors.textSecondary,
                            size: 20,
                          ),
                          splashRadius: 18,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Active Account Banner (when logged in)
                    if (isLoggedIn) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: colors.accentEmerald.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.accentEmerald.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.account_circle_rounded,
                              color: colors.accentEmerald,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Translations.get('logged_in_as', lang),
                                    style: TextStyle(
                                      color: colors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        activeUser.isNotEmpty
                                            ? activeUser
                                            : 'LIVE SESSION',
                                        style: TextStyle(
                                          color: colors.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'JetBrains Mono',
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.accentEmerald
                                              .withValues(alpha: 0.18),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          widget.logic.loginMethod == 'CLOUDMES'
                                              ? 'CloudMES'
                                              : 'SSO',
                                          style: TextStyle(
                                            color: colors.accentEmerald,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              key: const ValueKey('mes_logout_btn'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.accentRose.withValues(
                                  alpha: 0.14,
                                ),
                                foregroundColor: colors.accentRose,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: colors.accentRose.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                              ),
                              onPressed: _handleLogout,
                              icon: const Icon(Icons.logout_rounded, size: 15),
                              label: Text(
                                Translations.get('switch_account_btn', lang),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Login Method Selector (SSO vs CloudMES)
                    Text(
                      Translations.get('login_method_label', lang),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMethodTile(
                            key: const ValueKey('login_method_sso'),
                            label: Translations.get('login_method_sso', lang),
                            icon: Icons.vpn_key_rounded,
                            selected: _loginMethod == 'SSO',
                            colors: colors,
                            onTap: () {
                              setState(() {
                                _loginMethod = 'SSO';
                                _requiresCaptcha = false;
                              });
                              widget.logic.setLoginPreferences(
                                loginMethod: 'SSO',
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMethodTile(
                            key: const ValueKey('login_method_cloudmes'),
                            label: Translations.get(
                              'login_method_cloudmes',
                              lang,
                            ),
                            icon: Icons.cloud_done_rounded,
                            selected: _loginMethod == 'CLOUDMES',
                            colors: colors,
                            onTap: () {
                              setState(() {
                                _loginMethod = 'CLOUDMES';
                              });
                              widget.logic.setLoginPreferences(
                                loginMethod: 'CLOUDMES',
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Username Input
                    Text(
                      Translations.get('account_label', lang),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      key: const ValueKey('login_username_field'),
                      controller: _usernameCtrl,
                      focusNode: _usernameFocus,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13.5,
                        fontFamily: 'JetBrains Mono',
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: colors.subCardBg,
                        hintText: Translations.get('account_hint', lang),
                        hintStyle: TextStyle(
                          color: colors.textSecondary.withValues(alpha: 0.6),
                          fontSize: 12.5,
                        ),
                        prefixIcon: Icon(
                          Icons.badge_outlined,
                          size: 18,
                          color: colors.accentCyan,
                        ),
                        suffixIcon: _usernameCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  size: 16,
                                  color: colors.textSecondary,
                                ),
                                splashRadius: 16,
                                onPressed: () {
                                  setState(() {
                                    _usernameCtrl.clear();
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: BorderSide(color: colors.subCardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: BorderSide(color: colors.subCardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: BorderSide(
                            color: colors.accentCyan,
                            width: 1.4,
                          ),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 12),

                    // Password Input
                    Text(
                      Translations.get('password_label', lang),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      key: const ValueKey('login_password_field'),
                      controller: _passwordCtrl,
                      focusNode: _passwordFocus,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleLogin(),
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 13.5,
                        fontFamily: 'JetBrains Mono',
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: colors.subCardBg,
                        hintText: Translations.get('password_hint', lang),
                        hintStyle: TextStyle(
                          color: colors.textSecondary.withValues(alpha: 0.6),
                          fontSize: 12.5,
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline_rounded,
                          size: 18,
                          color: colors.accentCyan,
                        ),
                        suffixIcon: IconButton(
                          key: const ValueKey('toggle_password_visibility'),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 18,
                            color: colors.textSecondary,
                          ),
                          splashRadius: 16,
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: BorderSide(color: colors.subCardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: BorderSide(color: colors.subCardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(11),
                          borderSide: BorderSide(
                            color: colors.accentCyan,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),

                    // Optional Captcha Row for CloudMES fallback
                    if (_requiresCaptcha && _loginMethod == 'CLOUDMES') ...[
                      const SizedBox(height: 12),
                      Text(
                        Translations.get('captcha_label', lang),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _captchaCtrl,
                              onSubmitted: (_) => _handleLogin(),
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 13,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                filled: true,
                                fillColor: colors.subCardBg,
                                hintText: Translations.get(
                                  'captcha_hint',
                                  lang,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: colors.subCardBorder,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_captchaData != null)
                            Builder(
                              builder: (context) {
                                final bytes = _decodeCaptchaBytes(
                                  _captchaData!.imageBase64,
                                );
                                if (bytes == null) {
                                  return const SizedBox.shrink();
                                }
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    bytes,
                                    height: 38,
                                    width: 100,
                                    fit: BoxFit.contain,
                                  ),
                                );
                              },
                            ),
                          IconButton(
                            icon: Icon(
                              Icons.refresh_rounded,
                              color: colors.accentCyan,
                              size: 18,
                            ),
                            onPressed: _loadCaptcha,
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 10),

                    // Checkboxes: Remember Password & Auto-login
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            key: const ValueKey('remember_password_checkbox'),
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              setState(() {
                                _rememberPassword = !_rememberPassword;
                                if (!_rememberPassword) {
                                  _autoLogin = false;
                                }
                              });
                              widget.logic.setLoginPreferences(
                                rememberPassword: _rememberPassword,
                                autoLogin: _autoLogin,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _rememberPassword,
                                      activeColor: colors.accentColor,
                                      onChanged: (val) {
                                        final v = val ?? false;
                                        setState(() {
                                          _rememberPassword = v;
                                          if (!v) _autoLogin = false;
                                        });
                                        widget.logic.setLoginPreferences(
                                          rememberPassword: v,
                                          autoLogin: _autoLogin,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      Translations.get(
                                        'remember_password',
                                        lang,
                                      ),
                                      style: TextStyle(
                                        color: colors.textPrimary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            key: const ValueKey('auto_login_checkbox'),
                            borderRadius: BorderRadius.circular(8),
                            onTap: _rememberPassword
                                ? () {
                                    setState(() {
                                      _autoLogin = !_autoLogin;
                                    });
                                    widget.logic.setLoginPreferences(
                                      autoLogin: _autoLogin,
                                    );
                                  }
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _rememberPassword && _autoLogin,
                                      activeColor: colors.accentColor,
                                      onChanged: _rememberPassword
                                          ? (val) {
                                              final v = val ?? false;
                                              setState(() {
                                                _autoLogin = v;
                                              });
                                              widget.logic.setLoginPreferences(
                                                autoLogin: v,
                                              );
                                            }
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      Translations.get(
                                        'auto_login_enable',
                                        lang,
                                      ),
                                      style: TextStyle(
                                        color: _rememberPassword
                                            ? colors.textPrimary
                                            : colors.textSecondary.withValues(
                                                alpha: 0.5,
                                              ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_statusMessage.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (_isStatusSuccess
                                      ? colors.accentEmerald
                                      : colors.accentRose)
                                  .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                (_isStatusSuccess
                                        ? colors.accentEmerald
                                        : colors.accentRose)
                                    .withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isStatusSuccess
                                  ? Icons.check_circle_rounded
                                  : Icons.error_outline_rounded,
                              color: _isStatusSuccess
                                  ? colors.accentEmerald
                                  : colors.accentRose,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _statusMessage,
                                style: TextStyle(
                                  color: _isStatusSuccess
                                      ? colors.accentEmerald
                                      : colors.accentRose,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Primary Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        key: const ValueKey('mes_login_submit_btn'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                        onPressed: (_isSubmitting || widget.logic.isLoggingIn)
                            ? null
                            : _handleLogin,
                        icon: (_isSubmitting || widget.logic.isLoggingIn)
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.login_rounded, size: 18),
                        label: Text(
                          Translations.get(
                            (_isSubmitting || widget.logic.isLoggingIn)
                                ? 'logging_in'
                                : 'login_btn',
                            lang,
                          ),
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    Divider(color: colors.borderDefault, height: 1),
                    const SizedBox(height: 12),

                    // Secondary Browser CDP Sync & Full Settings
                    Text(
                      Translations.get('or_browser_sync', lang),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.textPrimary,
                              side: BorderSide(color: colors.subCardBorder),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            onPressed: () async {
                              await BrowserHelper.launchBrowser();
                            },
                            icon: Icon(
                              Icons.open_in_browser_rounded,
                              size: 16,
                              color: colors.accentCyan,
                            ),
                            label: Text(
                              Translations.get('btn_open_browser', lang),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.textPrimary,
                              side: BorderSide(color: colors.subCardBorder),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            onPressed: _isSyncingBrowser
                                ? null
                                : _handleSyncFromBrowser,
                            icon: _isSyncingBrowser
                                ? SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.accentEmerald,
                                    ),
                                  )
                                : Icon(
                                    Icons.sync_rounded,
                                    size: 16,
                                    color: colors.accentEmerald,
                                  ),
                            label: Text(
                              Translations.get(
                                _isSyncingBrowser
                                    ? 'status_fetching'
                                    : 'btn_sync_credentials',
                                lang,
                              ),
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (widget.onOpenFullSettings != null) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onOpenFullSettings?.call();
                          },
                          child: Text(
                            Translations.get('open_settings', lang),
                            style: TextStyle(
                              color: colors.accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMethodTile({
    required Key key,
    required String label,
    required IconData icon,
    required bool selected,
    required AppColors colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      borderRadius: BorderRadius.circular(11),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? colors.accentColor.withValues(alpha: 0.16)
              : colors.subCardBg,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected ? colors.accentColor : colors.subCardBorder,
            width: selected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? colors.accentColor : colors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? colors.textPrimary : colors.textSecondary,
                fontSize: 12.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 15,
              color: selected ? colors.accentColor : colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
