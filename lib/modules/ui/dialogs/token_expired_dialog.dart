import 'package:flutter/material.dart';
import '../../logic.dart';
import '../../translations.dart';
import '../../browser_helper.dart';
import '../../../theme/theme_provider.dart';
import '../../../widgets/glass_widgets.dart';
import '../../../widgets/glass_dialog.dart';
import '../../../widgets/app_toast.dart';

Future<void> showTokenExpiredWarningDialog(
  BuildContext context,
  AppLogic logic,
  ThemeProvider theme, {
  required VoidCallback onOpenSettings,
}) {
  final colors = theme.colors;
  bool isSyncing = false;

  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim1, anim2, child) {
      final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return GlassDialog(
                title: Translations.get('token_expired_title', logic.lang),
                icon: Icons.warning_amber_rounded,
                isDark: theme.isDark,
                blurSigma: theme.dialogBlur,
                bgOpacity: theme.dialogOpacity,
                width: 520,
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      Translations.get('cancel', logic.lang),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GlowingActionButton(
                    height: 36,
                    colors: colors,
                    icon: Icons.settings_rounded,
                    label: Translations.get('open_settings', logic.lang),
                    onPressed: () {
                      Navigator.pop(ctx);
                      onOpenSettings();
                    },
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Translations.get('token_expired_desc', logic.lang),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 16),
                      BentoCard(
                        colors: colors,
                        padding: const EdgeInsets.all(14),
                        borderRadius: 14,
                        isFeatured: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  color: colors.accentAmber,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  Translations.get(
                                    'cdp_sync_title',
                                    logic.lang,
                                  ),
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 13,
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
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: colors.accentColor,
                                      side: BorderSide(
                                        color: colors.accentColor.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.open_in_browser_rounded,
                                      size: 16,
                                    ),
                                    label: Text(
                                      Translations.get(
                                        'btn_open_browser',
                                        logic.lang,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 11.5,
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
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
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
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
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
                                            if (creds != null &&
                                                creds.token != null &&
                                                creds.token!.isNotEmpty) {
                                              await logic.updateCredentials(
                                                token: creds.token!,
                                                uuid: creds.uuid ?? '',
                                                operationId:
                                                    creds.operationId ?? '',
                                                cookie: creds.cookie ?? '',
                                              );
                                              if (ctx.mounted) {
                                                Navigator.pop(ctx);
                                                showAppToast(
                                                  context,
                                                  colors: colors,
                                                  message: Translations.get(
                                                    'fetched_success',
                                                    logic.lang,
                                                  ),
                                                  icon: Icons
                                                      .check_circle_rounded,
                                                  accentColor:
                                                      colors.accentEmerald,
                                                );
                                              }
                                            } else {
                                              if (ctx.mounted) {
                                                showAppToast(
                                                  context,
                                                  colors: colors,
                                                  message: Translations.get(
                                                    'fetched_fail',
                                                    logic.lang,
                                                  ),
                                                  icon: Icons
                                                      .error_outline_rounded,
                                                  accentColor:
                                                      colors.accentRose,
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
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    },
  );
}
