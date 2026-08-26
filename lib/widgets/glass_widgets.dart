import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A single blurred, slowly-drifting circle used by [MeshBackground].
class MeshOrb extends StatefulWidget {
  const MeshOrb({
    super.key,
    required this.color,
    required this.size,
    required this.duration,
    required this.travel,
  });

  final Color color;
  final double size;
  final Duration duration;
  final Offset travel;

  @override
  State<MeshOrb> createState() => _MeshOrbState();
}

class _MeshOrbState extends State<MeshOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOutSine.transform(_controller.value);
        return Transform.translate(
          offset: Offset(widget.travel.dx * t, widget.travel.dy * t),
          child: child,
        );
      },
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 85, sigmaY: 85),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

/// Ambient mesh background: 3 drifting [MeshOrb]s behind the app content.
class MeshBackground extends StatelessWidget {
  const MeshBackground({super.key, required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -160,
          left: -160,
          child: MeshOrb(
            color: colors.orb1.withValues(alpha: colors.orbOpacity),
            size: 480,
            duration: const Duration(seconds: 16),
            travel: const Offset(60, 70),
          ),
        ),
        Positioned(
          bottom: -140,
          right: -120,
          child: MeshOrb(
            color: colors.orb2.withValues(alpha: colors.orbOpacity),
            size: 440,
            duration: const Duration(seconds: 18),
            travel: const Offset(-60, -60),
          ),
        ),
        Positioned(
          top: 180,
          right: 120,
          child: MeshOrb(
            color: colors.orb3.withValues(alpha: colors.orbOpacity),
            size: 340,
            duration: const Duration(seconds: 20),
            travel: const Offset(-40, 45),
          ),
        ),
      ],
    );
  }
}

/// Reusable frosted-glass surface: blurred backdrop + soft outer shadow +
/// a faint top-edge highlight line standing in for a native inset shadow.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.colors,
    required this.child,
    this.blurSigma = 24,
    this.borderRadius = 16,
    this.padding,
    this.borderColor,
    this.backgroundColor,
  });

  final AppColors colors;
  final Widget child;
  final double blurSigma;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? colors.glassBg,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor ?? colors.glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border(
              top: BorderSide(color: colors.glassHighlight, width: 1),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Small rounded-pill badge, optionally with a glowing status dot.
class PillBadge extends StatelessWidget {
  const PillBadge({
    super.key,
    required this.label,
    required this.color,
    required this.bg,
    required this.border,
    this.showDot = false,
    this.icon,
    this.fontSize = 11,
    this.padding,
  });

  final String label;
  final Color color;
  final Color bg;
  final Color border;
  final bool showDot;
  final IconData? icon;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [BoxShadow(color: color, blurRadius: 6)],
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: fontSize, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Frosted Bento Grid Card with highlight top-border and soft glow on hover.
class BentoCard extends StatelessWidget {
  final AppColors colors;
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;
  final VoidCallback? onTap;
  final bool isFeatured;
  final Color? customBg;
  final Color? customBorder;
  final double? bgOpacity;

  const BentoCard({
    super.key,
    required this.colors,
    required this.child,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(20),
    this.blurSigma = 20,
    this.onTap,
    this.isFeatured = false,
    this.customBg,
    this.customBorder,
    this.bgOpacity,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg =
        customBg ??
        (bgOpacity != null
            ? colors.cardBg.withValues(alpha: bgOpacity!)
            : colors.cardBg);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            hoverColor: colors.cardHoverBg.withValues(alpha: 0.15),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: effectiveBg,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color:
                      customBorder ??
                      (isFeatured
                          ? colors.accentColor.withValues(alpha: 0.4)
                          : colors.borderDefault),
                  width: isFeatured ? 1.2 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  if (isFeatured)
                    BoxShadow(
                      color: colors.primaryGlow.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                ],
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border(
                  top: BorderSide(
                    color: isFeatured
                        ? colors.accentCyan.withValues(alpha: 0.6)
                        : colors.glassHighlight,
                    width: 1,
                  ),
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated 3-bar sound wave / equalizer indicator for active status.
class WaveIndicator extends StatefulWidget {
  final Color color;
  final double height;
  const WaveIndicator({super.key, required this.color, this.height = 14});

  @override
  State<WaveIndicator> createState() => _WaveIndicatorState();
}

class _WaveIndicatorState extends State<WaveIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final val = _controller.value;
        final h1 = (widget.height * (0.3 + 0.7 * val)).clamp(
          3.0,
          widget.height,
        );
        final h2 = (widget.height * (0.9 - 0.6 * val)).clamp(
          3.0,
          widget.height,
        );
        final h3 = (widget.height * (0.4 + 0.5 * (1 - val))).clamp(
          3.0,
          widget.height,
        );

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildBar(h1),
            const SizedBox(width: 2),
            _buildBar(h2),
            const SizedBox(width: 2),
            _buildBar(h3),
          ],
        );
      },
    );
  }

  Widget _buildBar(double height) {
    return Container(
      width: 2.5,
      height: height,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}

/// Dynamic Island Status Capsule for the top header.
class DynamicIslandCapsule extends StatelessWidget {
  final AppColors colors;
  final bool isRunning;
  final String statusText;
  final String? subText;
  final VoidCallback? onTap;
  final Color? customColor;

  const DynamicIslandCapsule({
    super.key,
    required this.colors,
    required this.isRunning,
    required this.statusText,
    this.subText,
    this.onTap,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = customColor ?? colors.accentEmerald;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: colors.subCardBg,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: isRunning
                  ? activeColor.withValues(alpha: 0.45)
                  : colors.subCardBorder,
            ),
            boxShadow: [
              if (isRunning)
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isRunning) ...[
                WaveIndicator(color: activeColor, height: 12),
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: activeColor,
                    boxShadow: [BoxShadow(color: activeColor, blurRadius: 6)],
                  ),
                ),
              ] else ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.textMuted,
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Text(
                statusText,
                style: TextStyle(
                  color: isRunning ? activeColor : colors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'JetBrains Mono',
                  letterSpacing: 0.4,
                ),
              ),
              if (subText != null && subText!.isNotEmpty) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: colors.subCardBorder.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    subText!,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'JetBrains Mono',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Sliding Magnetic Pill Tab Bar with smooth sliding indicator animation.
class SlidingPillTabBar extends StatelessWidget {
  final AppColors colors;
  final int currentIndex;
  final List<String> tabs;
  final List<IconData> icons;
  final ValueChanged<int> onTabSelected;

  const SlidingPillTabBar({
    super.key,
    required this.colors,
    required this.currentIndex,
    required this.tabs,
    required this.icons,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.subCardBg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: colors.subCardBorder),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(tabs.length, (index) {
            final isSelected = currentIndex == index;
            return GestureDetector(
              onTap: () => onTabSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? colors.accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colors.primaryGlow,
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icons[index],
                      size: 14,
                      color: isSelected ? Colors.white : colors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tabs[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : colors.textSecondary,
                        fontSize: 11.5,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// High-tech glowing action button with vibrant gradients and tactile feedback.
class GlowingActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final AppColors colors;
  final double height;
  final Color? customStartColor;
  final Color? customEndColor;

  const GlowingActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isDestructive = false,
    required this.colors,
    this.height = 42,
    this.customStartColor,
    this.customEndColor,
  });

  @override
  Widget build(BuildContext context) {
    final start =
        customStartColor ??
        (isDestructive ? const Color(0xFFF43F5E) : colors.accentColor);
    final end =
        customEndColor ??
        (isDestructive ? const Color(0xFFE11D48) : colors.accentCyan);

    final gradient = LinearGradient(
      colors: [start, end],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final glowColor = isDestructive
        ? const Color(0x66F43F5E)
        : (customStartColor != null
              ? customStartColor!.withValues(alpha: 0.35)
              : colors.primaryGlow);

    final isDisabled = onPressed == null;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: isDisabled
            ? null
            : [
                BoxShadow(
                  color: glowColor,
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ).copyWith(elevation: WidgetStateProperty.all(0)),
        child: Ink(
          decoration: BoxDecoration(
            gradient: isDisabled
                ? LinearGradient(colors: [colors.subCardBg, colors.subCardBg])
                : gradient,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDisabled
                  ? colors.subCardBorder
                  : Colors.white.withValues(alpha: 0.2),
            ),
          ),
          child: Container(
            height: height,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isDisabled ? colors.textMuted : Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    color: isDisabled ? colors.textMuted : Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
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
