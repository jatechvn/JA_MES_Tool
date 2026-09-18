import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../api_client.dart';
import '../../translations.dart';
import '../../../theme/theme_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/glass_widgets.dart';
import '../../../widgets/glass_dialog.dart';
import '../../../widgets/app_toast.dart';

Future<void> showSnDetailDialog(
  BuildContext context, {
  required TestRecord record,
  required String lang,
  required ThemeProvider theme,
}) {
  final colors = theme.colors;
  final isPass = record.testResult.toUpperCase() == 'PASS';

  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim1, anim2, child) {
      final curved = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
          child: GlassDialog(
            title:
                '${Translations.get('result_details', lang)} - ${record.stationId}',
            icon: Icons.assignment_outlined,
            isDark: theme.isDark,
            blurSigma: theme.dialogBlur,
            bgOpacity: theme.dialogOpacity,
            width: 620,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Close',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              GlowingActionButton(
                height: 36,
                colors: colors,
                icon: Icons.copy_rounded,
                label: 'Copy Record',
                onPressed: () {
                  final text =
                      '''
Station: ${record.stationId}
Result: ${record.testResult}
Date: ${record.testDate} ${record.testTime}
Product No: ${record.productNo}
Internal SN: ${record.internalSn}
Customer SN: ${record.customerSn}
Work Order: ${record.woNo}
Host: ${record.loc}
Operator: ${record.empNo}
Error Code: ${record.errCode}
Failure Reason: ${record.failureReason}
''';
                  Clipboard.setData(ClipboardData(text: text.trim()));
                  Navigator.pop(ctx);
                  showAppToast(
                    context,
                    colors: colors,
                    message: 'Record data copied to clipboard!',
                    icon: Icons.check_circle_rounded,
                    accentColor: colors.accentEmerald,
                  );
                },
              ),
            ],
            child: SelectionArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Result Banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isPass
                            ? colors.accentEmerald.withValues(alpha: 0.12)
                            : colors.accentRose.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPass
                              ? colors.accentEmerald.withValues(alpha: 0.35)
                              : colors.accentRose.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPass
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: isPass
                                ? colors.accentEmerald
                                : colors.accentRose,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.testResult.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isPass
                                      ? colors.accentEmerald
                                      : colors.accentRose,
                                ),
                              ),
                              Text(
                                '${record.testDate} • ${record.testTime}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          PillBadge(
                            label: record.stationId,
                            color: colors.accentCyan,
                            bg: colors.accentCyan.withValues(alpha: 0.12),
                            border: colors.accentCyan.withValues(alpha: 0.35),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Failure Details if not PASS
                    if (!isPass &&
                        (record.failureReason.isNotEmpty ||
                            record.errCode.isNotEmpty)) ...[
                      BentoCard(
                        colors: colors,
                        padding: const EdgeInsets.all(14),
                        borderRadius: 12,
                        customBg: colors.accentRose.withValues(alpha: 0.08),
                        customBorder: colors.accentRose.withValues(alpha: 0.3),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.bug_report_rounded,
                                  color: colors.accentRose,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  Translations.get('failure_reason', lang),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: colors.accentRose,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (record.errCode.isNotEmpty)
                              _buildDetailRow(
                                Translations.get('error_code', lang),
                                record.errCode,
                                colors,
                              ),
                            if (record.failureReason.isNotEmpty)
                              _buildDetailRow(
                                Translations.get('failure_reason', lang),
                                record.failureReason,
                                colors,
                              ),
                            if (record.failDesc.isNotEmpty)
                              _buildDetailRow(
                                Translations.get('fail_desc', lang),
                                record.failDesc,
                                colors,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Main Info Grid
                    BentoCard(
                      colors: colors,
                      padding: const EdgeInsets.all(14),
                      borderRadius: 12,
                      child: Column(
                        children: [
                          _buildDetailRow(
                            Translations.get('product_no', lang),
                            record.productNo,
                            colors,
                          ),
                          _buildDetailRow(
                            Translations.get('internal_sn', lang),
                            record.internalSn,
                            colors,
                            highlight: true,
                          ),
                          _buildDetailRow(
                            Translations.get('customer_sn', lang),
                            record.customerSn,
                            colors,
                          ),
                          _buildDetailRow(
                            Translations.get('process_code', lang),
                            record.processCode,
                            colors,
                          ),
                          _buildDetailRow(
                            Translations.get('line_station_code', lang),
                            record.lineStationCode,
                            colors,
                          ),
                          _buildDetailRow(
                            Translations.get('test_host', lang),
                            record.loc,
                            colors,
                            highlight: true,
                          ),
                          _buildDetailRow(
                            Translations.get('product_series', lang),
                            record.productSeries,
                            colors,
                          ),
                          _buildDetailRow(
                            Translations.get('work_order', lang),
                            record.woNo,
                            colors,
                          ),
                          _buildDetailRow(
                            Translations.get('emp_no', lang),
                            record.empNo,
                            colors,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildDetailRow(
  String label,
  String value,
  AppColors colors, {
  bool highlight = false,
}) {
  if (value.trim().isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              color: highlight ? colors.accentCyan : colors.textPrimary,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
