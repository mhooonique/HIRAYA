import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';

// =============================================================================
// CinematicHero — shared hero component used across all HIRAYA screens.
//
// Parameters
// ----------
// title            : required  — main headline text
// subtitle         : optional  — body text below the title
// tag              : optional  — eyebrow pill label (e.g. "MARKETPLACE")
// height           : optional  — explicit widget height (null → min-height mode)
// accentColor      : optional  — colour for orbs + eyebrow pill, default teal
// backgroundGradient: optional — override the default deep-void gradient
// child            : optional  — arbitrary overlay placed over the hero content
//                               (e.g. a search bar, category pills, CTA row)
// =============================================================================

class CinematicHero extends StatefulWidget {
  const CinematicHero({
    super.key,
    required this.title,
    this.subtitle,
    this.tag,
    // Legacy alias kept so existing callers using `eyebrow:` still compile.
    this.eyebrow,
    this.height,
    this.minHeight = 340,
    this.accentColor = AppColors.teal,
    this.backgroundGradient,
    // Legacy alias kept so existing callers using `gradientColors:` compile.
    this.gradientColors,
    this.child,
    // Legacy alias kept so existing callers using `actions:` compile.
    this.actions,
    // Legacy alias kept so existing callers using `backgroundWidget:` compile.
    this.backgroundWidget,
  });

  final String title;
  final String? subtitle;
  final String? tag;
  final String? eyebrow; // legacy — maps to tag internally
  final double? height;
  final double minHeight;
  final Color accentColor;
  final List<Color>? backgroundGradient;
  final List<Color>? gradientColors; // legacy — maps to backgroundGradient
  final Widget? child;
  final List<Widget>? actions; // legacy
  final Widget? backgroundWidget; // legacy

  @override
  State<CinematicHero> createState() => _CinematicHeroState();
}

class _CinematicHeroState extends State<CinematicHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbController;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  EdgeInsets _hPad(double w) {
    if (w >= 1200) return const EdgeInsets.symmetric(horizontal: 120);
    if (w >= 900) return const EdgeInsets.symmetric(horizontal: 80);
    if (w >= 600) return const EdgeInsets.symmetric(horizontal: 48);
    return const EdgeInsets.symmetric(horizontal: 24);
  }

  List<Color> get _gradientColors =>
      widget.backgroundGradient ??
      widget.gradientColors ??
      const [AppColors.deepVoid, AppColors.richNavy, Color(0xFF0A2240)];

  String? get _eyebrow => widget.tag ?? widget.eyebrow;

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = widget.height;

    Widget content = Stack(
      fit: StackFit.passthrough,
      children: [
        // 1. Gradient background
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _gradientColors,
              ),
            ),
          ),
        ),

        // 2. Optional legacy backgroundWidget
        if (widget.backgroundWidget != null)
          Positioned.fill(child: widget.backgroundWidget!),

        // 3. Grid texture overlay
        Positioned.fill(
          child: CustomPaint(painter: _GridTexturePainter()),
        ),

        // 4. Animated orbs
        AnimatedBuilder(
          animation: _orbController,
          builder: (context, _) {
            final t = _orbController.value;
            return Stack(
              children: [
                // Primary accent orb — top-left drift
                _Orb(
                  left: w * 0.04 + t * 24,
                  top: 16.0 + t * 32,
                  size: 300,
                  color: widget.accentColor.withValues(alpha: 0.13),
                  blur: 110,
                ),
                // Sky orb — top-right
                _Orb(
                  left: w * 0.58 - t * 18,
                  top: 10.0 + t * 22,
                  size: 240,
                  color: AppColors.sky.withValues(alpha: 0.10),
                  blur: 90,
                ),
                // Warm ember orb — lower centre
                _Orb(
                  left: w * 0.32 + t * 12,
                  top: (h ?? widget.minHeight) * 0.50 - t * 14,
                  size: 180,
                  color: AppColors.warmEmber.withValues(alpha: 0.08),
                  blur: 80,
                ),
              ],
            );
          },
        ),

        // 5. Text content + optional child overlay
        Padding(
          padding: _hPad(w).copyWith(top: 72, bottom: 64),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Eyebrow pill
              if (_eyebrow != null) ...[
                _EyebrowPill(label: _eyebrow!, color: widget.accentColor),
                const SizedBox(height: 14),
              ],

              // Title
              Text(
                widget.title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: w >= 900 ? 52 : w >= 600 ? 40 : 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                  height: 1.15,
                  letterSpacing: -0.5,
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 600.ms)
                  .slideY(
                    begin: 0.2,
                    end: 0,
                    duration: 600.ms,
                    curve: Curves.easeOutCubic,
                  ),

              // Subtitle
              if (widget.subtitle != null) ...[
                const SizedBox(height: 18),
                Text(
                  widget.subtitle!,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: w >= 900 ? 18 : 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.white.withValues(alpha: 0.72),
                    height: 1.65,
                    letterSpacing: 0.2,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 380.ms, duration: 600.ms)
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      duration: 600.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ],

              // Child overlay (search bar, CTA row, etc.)
              if (widget.child != null) ...[
                const SizedBox(height: 32),
                widget.child!
                    .animate()
                    .fadeIn(delay: 540.ms, duration: 500.ms)
                    .slideY(
                      begin: 0.15,
                      end: 0,
                      duration: 500.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ],

              // Legacy actions list
              if (widget.actions != null && widget.actions!.isNotEmpty) ...[
                const SizedBox(height: 32),
                Wrap(spacing: 16, runSpacing: 16, children: widget.actions!)
                    .animate()
                    .fadeIn(delay: 540.ms, duration: 500.ms)
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                    ),
              ],
            ],
          ),
        ),
      ],
    );

    // Wrap in explicit height if provided, otherwise use a ConstrainedBox.
    if (h != null) {
      return SizedBox(width: double.infinity, height: h, child: content);
    }
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: widget.minHeight),
      child: content,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Eyebrow pill
// ─────────────────────────────────────────────────────────────────────────────

class _EyebrowPill extends StatelessWidget {
  const _EyebrowPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.5,
          color: color,
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 80.ms, duration: 450.ms)
        .slideY(begin: 0.25, end: 0, duration: 450.ms, curve: Curves.easeOutCubic);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glowing orb helper
// ─────────────────────────────────────────────────────────────────────────────

class _Orb extends StatelessWidget {
  const _Orb({
    required this.left,
    required this.top,
    required this.size,
    required this.color,
    required this.blur,
  });

  final double left;
  final double top;
  final double size;
  final Color color;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: blur,
              spreadRadius: blur * 0.35,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grid texture painter (subtle white lines at 0.025 opacity)
// ─────────────────────────────────────────────────────────────────────────────

class _GridTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x06FFFFFF) // ≈ 2.4% white
      ..strokeWidth = 0.8;

    const step = 40.0;
    // Diagonal lines: top-left → bottom-right
    for (double d = -size.height; d < size.width + size.height; d += step) {
      canvas.drawLine(Offset(d, 0), Offset(d + size.height, size.height), paint);
    }
    // Diagonal lines: top-right → bottom-left
    for (double d = 0; d < size.width + size.height; d += step) {
      canvas.drawLine(Offset(d, 0), Offset(d - size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
