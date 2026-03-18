import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';

// =============================================================================
// HIRAYA Premium Button System
//
// Variants
// --------
//   AnimatedButton.golden(...)   — primary CTA  (golden→warmEmber gradient)
//   AnimatedButton.teal(...)     — secondary CTA (teal gradient, white text)
//   AnimatedButton.outline(...)  — ghost with coloured border
//   AnimatedButton.ghost(...)    — text-only with hover underline/fade
//
// All variants share:
//   • Hover  → scale 1.04 + glow boxShadow  (200 ms, easeOutCubic)
//   • Press  → scale 0.97                   (50 ms)
//   • Loading state  → inline CircularProgressIndicator
//   • Leading icon support
//   • Golden variant → shimmer sweep on hover (flutter_animate)
// =============================================================================

/// Button style variants for [AnimatedButton].
enum ButtonVariant { golden, teal, outline, ghost }

class AnimatedButton extends StatefulWidget {
  // ── Private canonical constructor ─────────────────────────────────────────

  const AnimatedButton._({
    super.key,
    required this.label,
    required this.variant,
    this.onPressed,
    this.icon,
    this.width,
    this.isLoading = false,
    this.accentColor,
  });

  // ── Named constructors (public API) ───────────────────────────────────────

  /// Golden gradient primary button — main CTA.
  factory AnimatedButton.golden({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    double? width,
    bool isLoading = false,
  }) =>
      AnimatedButton._(
        key: key,
        label: label,
        variant: ButtonVariant.golden,
        onPressed: onPressed,
        icon: icon,
        width: width,
        isLoading: isLoading,
      );

  /// Teal gradient secondary button — trust / action.
  factory AnimatedButton.teal({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    double? width,
    bool isLoading = false,
  }) =>
      AnimatedButton._(
        key: key,
        label: label,
        variant: ButtonVariant.teal,
        onPressed: onPressed,
        icon: icon,
        width: width,
        isLoading: isLoading,
      );

  /// Outline button — transparent fill, coloured border + text.
  factory AnimatedButton.outline({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    double? width,
    bool isLoading = false,
    Color accentColor = AppColors.golden,
  }) =>
      AnimatedButton._(
        key: key,
        label: label,
        variant: ButtonVariant.outline,
        onPressed: onPressed,
        icon: icon,
        width: width,
        isLoading: isLoading,
        accentColor: accentColor,
      );

  /// Ghost / text-only button — minimal, no background.
  factory AnimatedButton.ghost({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
    double? width,
    bool isLoading = false,
    Color accentColor = AppColors.golden,
  }) =>
      AnimatedButton._(
        key: key,
        label: label,
        variant: ButtonVariant.ghost,
        onPressed: onPressed,
        icon: icon,
        width: width,
        isLoading: isLoading,
        accentColor: accentColor,
      );

  // ── Legacy default constructor ─────────────────────────────────────────────
  // Keeps existing call-sites that pass backgroundColor / outlined from
  // breaking at compile time.

  factory AnimatedButton({
    Key? key,
    required String label,
    VoidCallback? onPressed,
    Color backgroundColor = AppColors.teal,
    Color textColor = AppColors.white, // accepted but variant drives text color
    IconData? icon,
    bool outlined = false,
    double? width,
    bool isLoading = false,
  }) =>
      AnimatedButton._(
        key: key,
        label: label,
        variant: outlined ? ButtonVariant.outline : ButtonVariant.teal,
        onPressed: onPressed,
        icon: icon,
        width: width,
        isLoading: isLoading,
        accentColor: backgroundColor,
      );

  final String label;
  final ButtonVariant variant;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;
  final bool isLoading;
  final Color? accentColor;

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;

  late final AnimationController _pressCtrl;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
      reverseDuration: const Duration(milliseconds: 130),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  // ── Interaction callbacks ──────────────────────────────────────────────────

  bool get _disabled => widget.onPressed == null || widget.isLoading;

  void _onTapDown(TapDownDetails _) {
    if (_disabled) return;
    _pressCtrl.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (_disabled) return;
    _pressCtrl.reverse();
    widget.onPressed?.call();
  }

  void _onTapCancel() => _pressCtrl.reverse();

  // ── Style resolution ───────────────────────────────────────────────────────

  double get _hoverScale => _hovered ? 1.04 : 1.0;

  Decoration _decoration() {
    switch (widget.variant) {
      case ButtonVariant.golden:
        return BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.golden, AppColors.warmEmber],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppColors.golden.withValues(alpha: 0.40),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        );

      case ButtonVariant.teal:
        return BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.teal, Color(0xFF0E5A50)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.38),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        );

      case ButtonVariant.outline:
        final c = widget.accentColor ?? AppColors.golden;
        return BoxDecoration(
          color: _hovered ? c.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c, width: 1.5),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: c.withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        );

      case ButtonVariant.ghost:
        return BoxDecoration(
          color: _hovered
              ? (widget.accentColor ?? AppColors.golden)
                  .withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        );
    }
  }

  Color get _labelColor {
    switch (widget.variant) {
      case ButtonVariant.golden:
        return AppColors.navy;
      case ButtonVariant.teal:
        return AppColors.white;
      case ButtonVariant.outline:
      case ButtonVariant.ghost:
        return widget.accentColor ?? AppColors.golden;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isGolden = widget.variant == ButtonVariant.golden;

    return MouseRegion(
      cursor:
          _disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: _disabled ? null : _onTapDown,
        onTapUp: _disabled ? null : _onTapUp,
        onTapCancel: _disabled ? null : _onTapCancel,
        child: AnimatedBuilder(
          animation: _pressScale,
          builder: (context, child) => Transform.scale(
            scale: _pressScale.value * _hoverScale,
            child: child,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: widget.width,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
            decoration: _decoration(),
            child: _buildContent(isGolden),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isGolden) {
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(_labelColor),
          ),
        ),
      );
    }

    Widget label = Text(
      widget.label,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: _labelColor,
        letterSpacing: 0.2,
      ),
    );

    // Golden variant: shimmer sweep animates on hover via flutter_animate.
    if (isGolden && _hovered) {
      label = label
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: 900.ms,
            color: AppColors.white.withValues(alpha: 0.55),
            angle: 0.3,
          );
    }

    if (widget.icon == null) {
      return Center(child: label);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(widget.icon, size: 18, color: _labelColor),
        const SizedBox(width: 8),
        label,
      ],
    );
  }
}

// =============================================================================
// AnimatedHoverButton — legacy class name alias.
// Existing code that imports/uses AnimatedHoverButton keeps compiling.
// =============================================================================

/// @deprecated  Use [AnimatedButton] instead.
///
/// Legacy shim — forwards all parameters to [AnimatedButton].
class AnimatedHoverButton extends AnimatedButton {
  const AnimatedHoverButton({
    super.key,
    required super.label,
    super.onPressed,
    Color backgroundColor = AppColors.teal,
    // textColor accepted for signature compat but variant drives the colour.
    Color textColor = AppColors.white,
    super.icon,
    bool outlined = false,
    super.width,
    super.isLoading,
  }) : super._(
          variant: outlined ? ButtonVariant.outline : ButtonVariant.teal,
          accentColor: backgroundColor,
        );
}
