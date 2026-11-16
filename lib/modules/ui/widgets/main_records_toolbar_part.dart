part of '../main_window.dart';

extension _MainWindowToolbarExt on _MainWindowState {
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
    TestRecord? kpiRecord,
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

    final extraBadges = <Widget>[];
    if (snMasterInfo != null) {
      if (snMasterInfo.productStatus.isNotEmpty) {
        final isGood = snMasterInfo.productStatus.toUpperCase() == 'GOOD';
        final stColor = isGood ? colors.accentEmerald : colors.accentRose;
        extraBadges.add(
          PillBadge(
            label: snMasterInfo.productStatus.toUpperCase(),
            color: stColor,
            bg: stColor.withValues(alpha: 0.12),
            border: stColor.withValues(alpha: 0.35),
            fontSize: 10,
            showDot: true,
          ),
        );
      }
      final curStage = snMasterInfo.currentProcessCode.isNotEmpty
          ? snMasterInfo.currentProcessCode
          : snMasterInfo.currentProcessName;
      final nxtStage = snMasterInfo.nextProcessCode;
      if (curStage.isNotEmpty || nxtStage.isNotEmpty) {
        final stageFlow = curStage.isNotEmpty && nxtStage.isNotEmpty
            ? '$curStage ➔ $nxtStage'
            : (curStage.isNotEmpty ? curStage : nxtStage);
        extraBadges.add(
          PillBadge(
            label: '${Translations.get('current_station', lang)}: $stageFlow',
            color: colors.accentCyan,
            bg: colors.accentCyan.withValues(alpha: 0.1),
            border: colors.accentCyan.withValues(alpha: 0.3),
            fontSize: 10,
          ),
        );
      }
      if (snMasterInfo.woNo.isNotEmpty) {
        extraBadges.add(
          PillBadge(
            label: 'WO: ${snMasterInfo.woNo}',
            color: colors.accentPurple,
            bg: colors.accentPurple.withValues(alpha: 0.1),
            border: colors.accentPurple.withValues(alpha: 0.3),
            fontSize: 10,
          ),
        );
      }
      if (snMasterInfo.productNo.isNotEmpty) {
        final rev = snMasterInfo.productVersion.isNotEmpty
            ? ' (v${snMasterInfo.productVersion})'
            : '';
        extraBadges.add(
          PillBadge(
            label: 'PN: ${snMasterInfo.productNo}$rev',
            color: colors.accentAmber,
            bg: colors.accentAmber.withValues(alpha: 0.1),
            border: colors.accentAmber.withValues(alpha: 0.3),
            fontSize: 10,
          ),
        );
      }
      final lineStr = snMasterInfo.lineName.isNotEmpty
          ? snMasterInfo.lineName
          : snMasterInfo.lineCode;
      if (lineStr.isNotEmpty) {
        extraBadges.add(
          PillBadge(
            label: '${Translations.get('line', lang)}: $lineStr',
            color: colors.textSecondary,
            bg: colors.subCardBg,
            border: colors.subCardBorder,
            fontSize: 10,
          ),
        );
      }
      if (snMasterInfo.lastEditedDt.isNotEmpty) {
        final editor = snMasterInfo.lastEditor.isNotEmpty
            ? ' (${snMasterInfo.lastEditor})'
            : '';
        extraBadges.add(
          PillBadge(
            label:
                '${Translations.get('last_scan_time', lang)}: ${snMasterInfo.lastEditedDt}$editor',
            color: colors.textSecondary,
            bg: colors.subCardBg,
            border: colors.subCardBorder,
            fontSize: 10,
          ),
        );
      }
    }

    if (kpiRecord != null &&
        (kpiRecord.fpy != null ||
            kpiRecord.lpy != null ||
            (kpiRecord.qty ?? 0) > 0)) {
      final kpiParts = <String>[];
      if (kpiRecord.qty != null) {
        kpiParts.add('${Translations.get('kpi_total', lang)}:${kpiRecord.qty}');
      }
      if (kpiRecord.passQty != null) {
        kpiParts.add(
          '${Translations.get('kpi_pass', lang)}:${kpiRecord.passQty}',
        );
      }
      if (kpiRecord.failQty != null) {
        kpiParts.add(
          '${Translations.get('kpi_fail', lang)}:${kpiRecord.failQty}',
        );
      }
      if (kpiRecord.repassQty != null) {
        kpiParts.add(
          '${Translations.get('kpi_repass', lang)}:${kpiRecord.repassQty}',
        );
      }
      if (kpiRecord.fpy != null) {
        kpiParts.add(
          '${Translations.get('kpi_fpy', lang)}:${kpiRecord.fpy!.toStringAsFixed(1)}%',
        );
      }
      if (kpiRecord.lpy != null) {
        kpiParts.add(
          '${Translations.get('kpi_lpy', lang)}:${kpiRecord.lpy!.toStringAsFixed(1)}%',
        );
      }
      if (kpiParts.isNotEmpty) {
        extraBadges.add(
          PillBadge(
            label: kpiParts.join(' · '),
            color: colors.accentEmerald,
            bg: colors.accentEmerald.withValues(alpha: 0.1),
            border: colors.accentEmerald.withValues(alpha: 0.3),
            fontSize: 10,
          ),
        );
      }
    }

    return BentoCard(
      colors: colors,
      blurSigma: logic.bgBlur,
      bgOpacity: logic.bgOpacity,
      borderRadius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
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
                        onTap: () => _rebuild(() {
                          listState.filterCtrl.clear();
                          listState.filter = '';
                        }),
                      ),
                      _buildQuickFilterTab(
                        label: 'PASS ($passCount)',
                        selected: isPassSelected,
                        colors: colors,
                        activeColor: colors.accentEmerald,
                        onTap: () => _rebuild(() {
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
                          onTap: () => _rebuild(() {
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
                    hintStyle: TextStyle(
                      fontSize: 11.5,
                      color: colors.textMuted,
                    ),
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
                            onTap: () => _rebuild(() {
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
                      borderSide: BorderSide(
                        color: colors.accentColor,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (v) => _rebuild(() => listState.filter = v),
                ),
              ),
              const SizedBox(width: 8),
              _buildSortButton(theme, colors, lang, listState, sortOptions),
            ],
          ),
          if (extraBadges.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: extraBadges,
            ),
          ],
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
      _rebuild(() {
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
