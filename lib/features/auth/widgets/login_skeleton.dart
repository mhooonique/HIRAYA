import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// LoginSkeleton — pixel-accurate skeleton of the login page
// Shows on page entry, then AnimatedSwitcher fades to real form
// ═══════════════════════════════════════════════════════════
class LoginSkeleton extends StatelessWidget {
  const LoginSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final showLeft = size.width > 900;

    return Row(
      children: [
        if (showLeft)
          Expanded(
            flex: 5,
            child: _LeftSkeleton(),
          ),
        Expanded(
          flex: showLeft ? 4 : 1,
          child: _RightSkeleton(),
        ),
      ],
    );
  }
}

// ── Left panel skeleton (dark gradient background) ──────────
class _LeftSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, Color(0xFF064663), AppColors.teal],
        ),
      ),
      child: Stack(
        children: [
          // Subtle grid
          Positioned.fill(
            child: Opacity(
              opacity: 0.04,
              child: CustomPaint(painter: _GridPainter()),
            ),
          ),
          // Decorative orb hints (static in skeleton)
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.teal.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.sky.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Content skeletons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 56),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                _Skel(w: 72, h: 72, r: 16, dark: true)
                    .animate(delay: 0.ms)
                    .fadeIn(duration: 380.ms)
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 22),
                // HIRAYA — 6 individual letter boxes
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(6, (i) =>
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _Skel(w: 36, h: 52, r: 6, dark: true)
                          .animate(delay: Duration(milliseconds: 60 + i * 55))
                          .fadeIn(duration: 360.ms)
                          .slideY(begin: 0.25, end: 0, curve: Curves.easeOutBack),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Tagline line 1
                _Skel(w: 172, h: 18, dark: true)
                    .animate(delay: 400.ms)
                    .fadeIn(duration: 380.ms),
                const SizedBox(height: 7),
                // Tagline line 2
                _Skel(w: 140, h: 18, dark: true)
                    .animate(delay: 420.ms)
                    .fadeIn(duration: 380.ms),
                const SizedBox(height: 44),
                // Welcome back!
                _Skel(w: 186, h: 28, dark: true)
                    .animate(delay: 470.ms)
                    .fadeIn(duration: 380.ms)
                    .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 8),
                // Subtitle
                _Skel(w: 262, h: 15, dark: true)
                    .animate(delay: 505.ms)
                    .fadeIn(duration: 380.ms),
                const SizedBox(height: 44),
                // Stats strip skeleton
                Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(4, (i) =>
                      i.isOdd
                          ? Container(width: 1, height: 28,
                              color: Colors.white.withValues(alpha: 0.12))
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _Skel(w: 40, h: 16, dark: true)
                                    .animate(delay: Duration(milliseconds: 550 + i * 40))
                                    .fadeIn(duration: 360.ms),
                                const SizedBox(height: 4),
                                _Skel(w: 56, h: 11, dark: true)
                                    .animate(delay: Duration(milliseconds: 570 + i * 40))
                                    .fadeIn(duration: 360.ms),
                              ],
                            ),
                    ),
                  ),
                )
                .animate(delay: 530.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.10, end: 0, curve: Curves.easeOutCubic),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Right panel skeleton (light offWhite background) ────────
class _RightSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.offWhite,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Back to Home button
                _Skel(w: 122, h: 20, r: 6)
                    .animate(delay: 55.ms)
                    .fadeIn(duration: 350.ms)
                    .slideX(begin: -0.06, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 30),

                // "Sign In" title
                _Skel(w: 150, h: 38, r: 8)
                    .animate(delay: 90.ms)
                    .fadeIn(duration: 360.ms)
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 7),
                // Teal accent underline
                _Skel(w: 44, h: 4, r: 4)
                    .animate(delay: 105.ms)
                    .fadeIn(duration: 340.ms),
                const SizedBox(height: 10),
                // Subtitle
                _Skel(w: 274, h: 16, r: 6)
                    .animate(delay: 120.ms)
                    .fadeIn(duration: 350.ms),
                const SizedBox(height: 32),

                // Email Address label
                _Skel(w: 102, h: 13, r: 4)
                    .animate(delay: 155.ms)
                    .fadeIn(duration: 340.ms),
                const SizedBox(height: 8),
                // Email field
                _Skel(w: double.infinity, h: 52)
                    .animate(delay: 172.ms)
                    .fadeIn(duration: 350.ms),
                const SizedBox(height: 16),

                // Password label
                _Skel(w: 80, h: 13, r: 4)
                    .animate(delay: 205.ms)
                    .fadeIn(duration: 340.ms),
                const SizedBox(height: 8),
                // Password field
                _Skel(w: double.infinity, h: 52)
                    .animate(delay: 222.ms)
                    .fadeIn(duration: 350.ms),
                const SizedBox(height: 14),

                // Remember me row
                Row(
                  children: [
                    _Skel(w: 20, h: 20, r: 5)
                        .animate(delay: 255.ms)
                        .fadeIn(duration: 340.ms),
                    const SizedBox(width: 8),
                    _Skel(w: 95, h: 13, r: 4)
                        .animate(delay: 268.ms)
                        .fadeIn(duration: 340.ms),
                    const Spacer(),
                    _Skel(w: 120, h: 13, r: 4)
                        .animate(delay: 280.ms)
                        .fadeIn(duration: 340.ms),
                  ],
                ),
                const SizedBox(height: 24),

                // Sign In button
                _Skel(w: double.infinity, h: 54, r: 14)
                    .animate(delay: 308.ms)
                    .fadeIn(duration: 360.ms)
                    .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 22),

                // Divider with "or continue with"
                Row(
                  children: [
                    Expanded(
                      child: _Skel(w: double.infinity, h: 1, r: 1)
                          .animate(delay: 345.ms)
                          .fadeIn(duration: 340.ms),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _Skel(w: 92, h: 13, r: 4)
                          .animate(delay: 355.ms)
                          .fadeIn(duration: 340.ms),
                    ),
                    Expanded(
                      child: _Skel(w: double.infinity, h: 1, r: 1)
                          .animate(delay: 345.ms)
                          .fadeIn(duration: 340.ms),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Social buttons row
                Row(
                  children: [
                    Expanded(
                      child: _Skel(w: double.infinity, h: 46, r: 12)
                          .animate(delay: 380.ms)
                          .fadeIn(duration: 340.ms),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Skel(w: double.infinity, h: 46, r: 12)
                          .animate(delay: 395.ms)
                          .fadeIn(duration: 340.ms),
                    ),
                  ],
                ),
                const SizedBox(height: 26),

                // Create account
                Center(
                  child: _Skel(w: 252, h: 14, r: 5)
                      .animate(delay: 425.ms)
                      .fadeIn(duration: 340.ms),
                ),
                const SizedBox(height: 28),

                // Trust badges
                _Skel(w: double.infinity, h: 44, r: 12)
                    .animate(delay: 460.ms)
                    .fadeIn(duration: 360.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// _Skel — shimmer skeleton box
// ═══════════════════════════════════════════════════════════
class _Skel extends StatelessWidget {
  final double w;
  final double h;
  final double r;
  final bool dark;

  const _Skel({
    required this.w,
    required this.h,
    this.r = 8,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.13)
            : AppColors.lightGray,
        borderRadius: BorderRadius.circular(r),
      ),
    )
        .animate(onPlay: (ctrl) => ctrl.repeat())
        .shimmer(
          duration: 1300.ms,
          delay: 80.ms,
          color: dark
              ? Colors.white.withValues(alpha: 0.26)
              : Colors.white,
          blendMode: BlendMode.srcATop,
        );
  }
}

// ═══════════════════════════════════════════════════════════
// Grid painter (local copy for left panel texture)
// ═══════════════════════════════════════════════════════════
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
