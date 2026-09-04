import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
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
    this.shortcut,
  });

  final String label;
  final String? subtitle;
  final String? category;
  final IconData icon;
  final VoidCallback onSelect;
  final List<String> keywords;
  final String? shortcut;

  bool matches(String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase().trim();
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
  const CommandPalette({
    super.key,
    required this.items,
    required this.colors,
    this.searchHint = 'Nhập lệnh hoặc tìm kiếm… (Type a command…)',
    this.noResultsText = 'Không tìm thấy kết quả phù hợp (No results)',
    this.blurSigma = 24.0,
    this.isDark = true,
    this.bgOpacity = 0.88,
  });

  final List<CommandPaletteItem> items;
  final AppColors colors;
  final String searchHint;
  final String noResultsText;
  final double blurSigma;
  final bool isDark;
  final double bgOpacity;

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _keyboardFocusNode = FocusNode();
  late List<CommandPaletteItem> _filtered = widget.items;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Delay the focus request until after the open transition (180ms, see
    // showCommandPalette) settles. Requesting it immediately via
    // `autofocus: true` hands the Windows IME/TSF layer a composition rect
    // sampled mid-animation, which some IMEs (observed with a Chinese IME
    // active) then cache and render a stray composition underline under
    // unrelated text below once the dialog finishes scaling in.
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() {
      _filtered = widget.items.where((item) => item.matches(value)).toList();
      _selectedIndex = 0;
    });
  }

  void _selectCurrent() {
    if (_filtered.isNotEmpty && _selectedIndex < _filtered.length) {
      Navigator.of(context).pop();
      _filtered[_selectedIndex].onSelect();
    }
  }

  void _navigateUp() {
    if (_filtered.isEmpty) return;
    setState(() {
      _selectedIndex =
          (_selectedIndex - 1 + _filtered.length) % _filtered.length;
    });
  }

  void _navigateDown() {
    if (_filtered.isEmpty) return;
    setState(() {
      _selectedIndex = (_selectedIndex + 1) % _filtered.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final cardBg = widget.isDark
        ? const Color(0xFF0F172A).withValues(alpha: widget.bgOpacity)
        : const Color(0xFFFFFFFF).withValues(alpha: widget.bgOpacity);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: widget.blurSigma,
          sigmaY: widget.blurSigma,
        ),
        child: Container(
          color: Colors.black.withValues(alpha: 0.45),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 100),
          child: GestureDetector(
            onTap: () {}, // absorb taps so they don't bubble to the backdrop
            child: Shortcuts(
              shortcuts: {
                LogicalKeySet(LogicalKeyboardKey.escape):
                    const _DismissIntent(),
              },
              child: Actions(
                actions: {
                  _DismissIntent: CallbackAction<_DismissIntent>(
                    onInvoke: (_) => Navigator.of(context).pop(),
                  ),
                },
                child: KeyboardListener(
                  focusNode: _keyboardFocusNode,
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        _navigateDown();
                      } else if (event.logicalKey ==
                          LogicalKeyboardKey.arrowUp) {
                        _navigateUp();
                      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
                        _selectCurrent();
                      }
                    }
                  },
                  child: GlassContainer(
                    colors: c,
                    borderRadius: 18,
                    padding: EdgeInsets.zero,
                    backgroundColor: cardBg,
                    child: SizedBox(
                      width: 580,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Search Bar Header
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  size: 20,
                                  color: c.accentCyan,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    focusNode: _focusNode,
                                    onChanged: _onQueryChanged,
                                    style: TextStyle(
                                      color: c.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      hintText: widget.searchHint,
                                      hintStyle: TextStyle(
                                        color: c.textMuted,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ),
                                ),
                                KbdTag(label: 'ESC', colors: c),
                              ],
                            ),
                          ),
                          Divider(color: c.borderDefault, height: 1),

                          // Filtered Results List
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 380),
                            child: _filtered.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(28),
                                    child: Text(
                                      widget.noResultsText,
                                      style: TextStyle(
                                        color: c.textMuted,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    itemCount: _filtered.length,
                                    itemBuilder: (context, index) {
                                      final item = _filtered[index];
                                      final isHighlighted =
                                          index == _selectedIndex;

                                      return InkWell(
                                        borderRadius: BorderRadius.circular(10),
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          item.onSelect();
                                        },
                                        onHover: (hovered) {
                                          if (hovered) {
                                            setState(
                                              () => _selectedIndex = index,
                                            );
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isHighlighted
                                                ? c.accentColor.withValues(
                                                    alpha: 0.15,
                                                  )
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: isHighlighted
                                                  ? c.accentColor.withValues(
                                                      alpha: 0.4,
                                                    )
                                                  : Colors.transparent,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: isHighlighted
                                                      ? c.accentColor
                                                            .withValues(
                                                              alpha: 0.25,
                                                            )
                                                      : c.subCardBg,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  item.icon,
                                                  size: 17,
                                                  color: isHighlighted
                                                      ? c.accentCyan
                                                      : c.textSecondary,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      item.label,
                                                      style: TextStyle(
                                                        color: isHighlighted
                                                            ? c.textPrimary
                                                            : c.textSecondary,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            isHighlighted
                                                            ? FontWeight.w700
                                                            : FontWeight.w600,
                                                      ),
                                                    ),
                                                    if (item.subtitle !=
                                                        null) ...[
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        item.subtitle!,
                                                        style: TextStyle(
                                                          color: c.textMuted,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                              if (item.category != null) ...[
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: c.subCardBorder
                                                        .withValues(alpha: 0.3),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          5,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    item.category!,
                                                    style: TextStyle(
                                                      color: c.textMuted,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                              ],
                                              if (item.shortcut != null) ...[
                                                KbdTag(
                                                  label: item.shortcut!,
                                                  colors: c,
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
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the command palette as a transparent-barrier dialog.
Future<void> showCommandPalette(
  BuildContext context, {
  required List<CommandPaletteItem> items,
  required AppColors colors,
  String? searchHint,
  String? noResultsText,
  double blurSigma = 24.0,
  bool isDark = true,
  double bgOpacity = 0.88,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Command Palette',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, animation, secondaryAnimation) {
      return CommandPalette(
        items: items,
        colors: colors,
        searchHint: searchHint ?? 'Nhập lệnh hoặc tìm kiếm… (Type a command…)',
        noResultsText:
            noResultsText ?? 'Không tìm thấy kết quả phù hợp (No results)',
        blurSigma: blurSigma,
        isDark: isDark,
        bgOpacity: bgOpacity,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween(begin: 0.95, end: 1.0).animate(
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
/// command palette.
class CommandPaletteShortcut extends StatelessWidget {
  const CommandPaletteShortcut({
    super.key,
    required this.child,
    required this.items,
    required this.colors,
    this.searchHint,
    this.noResultsText,
    this.blurSigma = 24.0,
    this.isDark = true,
    this.bgOpacity = 0.88,
  });

  final Widget child;
  final List<CommandPaletteItem> Function() items;
  final AppColors colors;
  final String? searchHint;
  final String? noResultsText;
  final double blurSigma;
  final bool isDark;
  final double bgOpacity;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK):
            const _OpenPaletteIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK):
            const _OpenPaletteIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _OpenPaletteIntent: CallbackAction<_OpenPaletteIntent>(
            onInvoke: (intent) {
              showCommandPalette(
                context,
                items: items(),
                colors: colors,
                searchHint: searchHint,
                noResultsText: noResultsText,
                blurSigma: blurSigma,
                isDark: isDark,
                bgOpacity: bgOpacity,
              );
              return null;
            },
          ),
        },
        child: Focus(autofocus: true, child: child),
      ),
    );
  }
}
