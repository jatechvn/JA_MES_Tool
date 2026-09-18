import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';
import '../theme/styles_win11.dart';
import 'glass_widgets.dart';

/// One entry in the command palette's result list.
class CommandPaletteItem {
  const CommandPaletteItem({
    required this.label,
    required this.icon,
    required this.onSelect,
    this.subtitle,
    this.category,
    this.keywords = const [],
  });

  final String label;
  final String? subtitle;
  final String? category;
  final IconData icon;
  final VoidCallback onSelect;
  final List<String> keywords;

  bool matches(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return label.toLowerCase().contains(q) ||
        (subtitle?.toLowerCase().contains(q) ?? false) ||
        (category?.toLowerCase().contains(q) ?? false) ||
        keywords.any((k) => k.toLowerCase().contains(q));
  }
}

class _DismissIntent extends Intent {
  const _DismissIntent();
}

/// Ctrl+K spotlight-style command palette. Open it with [showCommandPalette]
/// rather than constructing this directly.
class CommandPalette extends StatefulWidget {
  const CommandPalette({super.key, required this.items, required this.colors});

  final List<CommandPaletteItem> items;
  final AppColors colors;

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final _controller = TextEditingController();
  late List<CommandPaletteItem> _filtered = widget.items;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {
      _filtered = widget.items.where((item) => item.matches(value)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    ThemeProvider? theme;
    try {
      theme = context.watch<ThemeProvider>();
    } catch (_) {
      theme = null;
    }
    final dialogBlur = theme?.dialogBlur ?? 24.0;
    final isDark = theme?.isDark ?? true;

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: dialogBlur, sigmaY: dialogBlur),
          child: Container(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.20),
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.only(top: 120),
            child: GestureDetector(
              onTap: () {}, // absorb taps so they don't bubble to the backdrop
              child: _CommandPaletteCard(
                colors: c,
                theme: theme,
                controller: _controller,
                onQueryChanged: _onQueryChanged,
                filtered: _filtered,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CommandPaletteCard extends StatelessWidget {
  const _CommandPaletteCard({
    required this.colors,
    this.theme,
    required this.controller,
    required this.onQueryChanged,
    required this.filtered,
  });

  final AppColors colors;
  final ThemeProvider? theme;
  final TextEditingController controller;
  final ValueChanged<String> onQueryChanged;
  final List<CommandPaletteItem> filtered;

  @override
  Widget build(BuildContext context) {
    final isDark = theme?.isDark ?? true;
    final opacity = theme?.dialogOpacity ?? 0.85;
    final bg = isDark
        ? const Color(0xFF0F172A).withValues(alpha: opacity)
        : const Color(0xFFFFFFFF).withValues(alpha: opacity);

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape): const _DismissIntent(),
      },
      child: Actions(
        actions: {
          _DismissIntent: CallbackAction<_DismissIntent>(
            onInvoke: (_) => Navigator.of(context).pop(),
          ),
        },
        child: Container(
          width: 560,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.borderDefault),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border(
              top: BorderSide(color: colors.glassHighlight, width: 1),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 18,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          autofocus: true,
                          onChanged: onQueryChanged,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Type a command or search…',
                            hintStyle: TextStyle(color: colors.textMuted),
                          ),
                        ),
                      ),
                      KbdTag(label: 'ESC', colors: colors),
                    ],
                  ),
                ),
                Divider(color: colors.borderDefault, height: 1),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: filtered.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No results',
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(6),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return Material(
                              type: MaterialType.transparency,
                              child: ListTile(
                                dense: true,
                                leading: Icon(
                                  item.icon,
                                  size: 18,
                                  color: colors.accentColor,
                                ),
                                title: Text(
                                  item.label,
                                  style: TextStyle(
                                    color: colors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: item.subtitle != null
                                    ? Text(
                                        item.subtitle!,
                                        style: TextStyle(
                                          color: colors.textMuted,
                                          fontSize: 11,
                                        ),
                                      )
                                    : null,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  item.onSelect();
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the command palette as a transparent-barrier dialog (the barrier
/// is painted by [CommandPalette] itself so it can fade/scale in together
/// with the content).
Future<void> showCommandPalette(
  BuildContext context, {
  required List<CommandPaletteItem> items,
  AppColors? colors,
}) {
  AppColors effectiveColors;
  try {
    effectiveColors = colors ?? context.read<ThemeProvider>().colors;
  } catch (_) {
    effectiveColors = colors ?? win11DarkColors;
  }
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Command Palette',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (context, animation, secondaryAnimation) {
      return CommandPalette(items: items, colors: effectiveColors);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  );
}

class _OpenPaletteIntent extends Intent {
  const _OpenPaletteIntent();
}

/// Wraps [child] with a global Ctrl+K (and Cmd+K) shortcut that opens the
/// command palette. Wrap this around the app's root content (e.g. inside
/// `MaterialApp.builder` or directly around `DashboardShell`).
///
/// [items] is a callback (not a fixed list) so the palette always reflects
/// current app state — e.g. the current view's available actions.
class CommandPaletteShortcut extends StatelessWidget {
  const CommandPaletteShortcut({
    super.key,
    required this.child,
    required this.items,
    this.colors,
    this.searchHint,
    this.noResultsText,
    this.blurSigma,
    this.isDark,
    this.bgOpacity,
  });

  final Widget child;
  final List<CommandPaletteItem> Function() items;
  final AppColors? colors;
  final String? searchHint;
  final String? noResultsText;
  final double? blurSigma;
  final bool? isDark;
  final double? bgOpacity;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK):
            const _OpenPaletteIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK):
            const _OpenPaletteIntent(),
      },
      child: Actions(
        actions: {
          _OpenPaletteIntent: CallbackAction<_OpenPaletteIntent>(
            onInvoke: (_) {
              showCommandPalette(context, items: items());
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}
