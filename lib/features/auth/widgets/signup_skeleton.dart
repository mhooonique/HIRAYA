import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Pixel-accurate skeleton for the Signup screen.
///
/// Layout mirrors exactly: left cinematic panel | right floating-card form.
/// Right panel order (inside card):
///   back btn → progress bar → step indicator (7 × 30 px uniform circles)
///   → step label → title + underline → subtitle → role cards → continue btn
///   → keyboard hint
class SignupSkeleton extends StatefulWidget {
  const SignupSkeleton({super.key});

  @override
  State<SignupSkeleton> createState() => _SignupSkeletonState();
}

class _SignupSkeletonState extends State<SignupSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final showLeft = w > 900;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Row(
        children: [
          // ── Left panel skeleton ─────────────────────────
          if (showLeft)
            Expanded(
              flex: 2,
              child: _LeftPanelSkeleton(pulseCtrl: _pulseCtrl),
            ),
          // ── Right panel skeleton ────────────────────────
          Expanded(
            flex: 3,
            child: _RightPanelSkeleton(pulseCtrl: _pulseCtrl),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Left Panel Skeleton — animated gradient + dot grid
// ═══════════════════════════════════════════════════════════
class _LeftPanelSkeleton extends StatelessWidget {
  final AnimationController pulseCtrl;
  const _LeftPanelSkeleton({required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (_, child) {
        final t = pulseCtrl.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(AppColors.navy, const Color(0xFF041F33), t)!,
                Color.lerp(
                    const Color(0xFF064663), AppColors.teal, t * 0.4)!,
              ],
            ),
          ),
          child: child,
        );
      },
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Dot grid texture
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
          // Top vignette
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo circle
                _DSkel(w: 80, h: 80, radius: 40)
                    .animate()
                    .fadeIn(duration: 500.ms),
                const SizedBox(height: 24),

                // HIRAYA letter boxes — entrance stagger
                Row(
                  children: List.generate(
                    6,
                    (i) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _DSkel(w: 42, h: 52, radius: 8)
                          .animate(
                              delay:
                                  Duration(milliseconds: 120 + i * 70))
                          .fadeIn(duration: 400.ms)
                          .slideY(
                              begin: 0.3,
                              end: 0,
                              curve: Curves.easeOutBack),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Tagline lines
                _DSkel(w: 240, h: 14, radius: 7)
                    .animate(delay: 600.ms)
                    .fadeIn(duration: 400.ms),
                const SizedBox(height: 10),
                _DSkel(w: 200, h: 14, radius: 7)
                    .animate(delay: 660.ms)
                    .fadeIn(duration: 400.ms),
                const SizedBox(height: 52),

                // CTA heading
                _DSkel(w: 180, h: 22, radius: 8)
                    .animate(delay: 720.ms)
                    .fadeIn(duration: 400.ms),
                const SizedBox(height: 10),
                _DSkel(w: 260, h: 13, radius: 6)
                    .animate(delay: 760.ms)
                    .fadeIn(duration: 400.ms),
                const SizedBox(height: 8),
                _DSkel(w: 220, h: 13, radius: 6)
                    .animate(delay: 800.ms)
                    .fadeIn(duration: 400.ms),
                const SizedBox(height: 44),

                // Trust badge rows — staggered
                ...List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        _DSkel(w: 36, h: 36, radius: 10),
                        const SizedBox(width: 12),
                        _DSkel(w: 130.0 + i * 12, h: 13, radius: 6),
                      ],
                    ),
                  )
                      .animate(
                          delay: Duration(milliseconds: 860 + i * 80))
                      .fadeIn(duration: 420.ms)
                      .slideX(
                          begin: -0.08,
                          end: 0,
                          curve: Curves.easeOutCubic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Right Panel Skeleton — dot grid + orbs + floating card
// Mirrors _buildFormPanel exactly:
//   offWhite bg → Stack(dot grid, orbs) → floating card → Column
// ═══════════════════════════════════════════════════════════
class _RightPanelSkeleton extends StatelessWidget {
  final AnimationController pulseCtrl;
  const _RightPanelSkeleton({required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (_, child) {
        final t = pulseCtrl.value;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            boxShadow: [
              BoxShadow(
                color:
                    AppColors.teal.withValues(alpha: 0.025 + t * 0.03),
                blurRadius: 60,
                offset: const Offset(-20, 0),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Subtle navy dot grid — matches actual right panel
          Positioned.fill(
            child: CustomPaint(painter: _RightDotGridPainter()),
          ),

          // Ambient orb — top-right teal
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.teal.withValues(alpha: 0.045),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Ambient orb — bottom-left sky
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.sky.withValues(alpha: 0.035),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Floating card — identical spec to actual form card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 36),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color:
                          AppColors.lightGray.withValues(alpha: 0.45),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.055),
                        blurRadius: 48,
                        offset: const Offset(0, 12),
                        spreadRadius: -6,
                      ),
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.035),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Back to Login ──────────────────────
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _LSkel(w: 14, h: 14, radius: 7),
                          const SizedBox(width: 8),
                          _LSkel(w: 90, h: 13, radius: 6),
                        ],
                      )
                          .animate()
                          .fadeIn(duration: 380.ms)
                          .slideX(
                              begin: -0.08,
                              end: 0,
                              curve: Curves.easeOutCubic),

                      const SizedBox(height: 20),

                      // ── Progress bar ───────────────────────
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              Container(
                                height: 4,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppColors.lightGray
                                      .withValues(alpha: 0.45),
                                  borderRadius:
                                      BorderRadius.circular(4),
                                ),
                              ),
                              // Shimmer fill — ~14% (step 1 of 7)
                              Container(
                                height: 4,
                                width: 60,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.teal,
                                      AppColors.sky
                                    ],
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(4),
                                ),
                              ).animate(onPlay: (c) => c.repeat()).shimmer(
                                    duration: 1400.ms,
                                    color: Colors.white
                                        .withValues(alpha: 0.50),
                                    blendMode: BlendMode.srcATop,
                                  ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _LSkel(
                            w: 90,
                            h: 11,
                            radius: 5,
                            baseColor:
                                AppColors.teal.withValues(alpha: 0.12),
                            shimColor:
                                AppColors.teal.withValues(alpha: 0.25),
                          ),
                        ],
                      ).animate(delay: 60.ms).fadeIn(duration: 500.ms),

                      const SizedBox(height: 20),

                      // ── Step indicator — 7 × 30 px uniform circles ─
                      const _StepIndicatorSkeleton()
                          .animate(delay: 100.ms)
                          .fadeIn(duration: 450.ms),

                      const SizedBox(height: 10),

                      // Step label
                      Center(
                        child: _LSkel(w: 130, h: 11, radius: 5),
                      )
                          .animate(delay: 140.ms)
                          .fadeIn(duration: 380.ms),

                      const SizedBox(height: 32),

                      // ── Step title ─────────────────────────
                      _LSkel(w: 220, h: 26, radius: 10)
                          .animate(delay: 180.ms)
                          .fadeIn(duration: 420.ms)
                          .slideY(
                              begin: 0.10,
                              end: 0,
                              curve: Curves.easeOutCubic),

                      const SizedBox(height: 8),

                      // Teal underline accent
                      _LSkel(
                        w: 44,
                        h: 4,
                        radius: 4,
                        baseColor:
                            AppColors.teal.withValues(alpha: 0.25),
                        shimColor:
                            AppColors.sky.withValues(alpha: 0.40),
                      )
                          .animate(delay: 220.ms)
                          .fadeIn(duration: 380.ms),

                      const SizedBox(height: 10),

                      _LSkel(w: 270, h: 13, radius: 6)
                          .animate(delay: 250.ms)
                          .fadeIn(duration: 380.ms),

                      const SizedBox(height: 32),

                      // ── Role card 1 ────────────────────────
                      const _RoleCardSkeleton()
                          .animate(delay: 300.ms)
                          .fadeIn(duration: 450.ms)
                          .slideY(
                              begin: 0.10,
                              end: 0,
                              curve: Curves.easeOutCubic),

                      const SizedBox(height: 16),

                      // ── Role card 2 ────────────────────────
                      const _RoleCardSkeleton()
                          .animate(delay: 380.ms)
                          .fadeIn(duration: 450.ms)
                          .slideY(
                              begin: 0.10,
                              end: 0,
                              curve: Curves.easeOutCubic),

                      const SizedBox(height: 36),

                      // ── Continue button ────────────────────
                      _LSkel(
                        w: double.infinity,
                        h: 54,
                        radius: 14,
                        baseColor:
                            AppColors.navy.withValues(alpha: 0.14),
                        shimColor:
                            AppColors.navy.withValues(alpha: 0.22),
                      )
                          .animate(delay: 460.ms)
                          .fadeIn(duration: 450.ms)
                          .slideY(
                              begin: 0.10,
                              end: 0,
                              curve: Curves.easeOutCubic),

                      const SizedBox(height: 8),

                      // ── Keyboard hint ──────────────────────
                      Center(
                        child: _LSkel(w: 150, h: 11, radius: 5),
                      )
                          .animate(delay: 520.ms)
                          .fadeIn(duration: 380.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Step indicator skeleton — 7 × 30 px uniform circles
// Mirrors the actual StepIndicator: all circles same fixed size
// ═══════════════════════════════════════════════════════════
class _StepIndicatorSkeleton extends StatelessWidget {
  const _StepIndicatorSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(13, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Container(
              height: 2.5,
              decoration: BoxDecoration(
                color: AppColors.lightGray.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }
        final stepIdx = i ~/ 2;
        final isFirst = stepIdx == 0;

        // 30 px — uniform, matching the actual StepIndicator
        return Container(
          width: 30.0,
          height: 30.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFirst
                ? AppColors.navy.withValues(alpha: 0.22)
                : AppColors.lightGray.withValues(alpha: 0.42),
          ),
        )
            .animate(
              onPlay: (c) => c.repeat(),
              delay: Duration(milliseconds: 40 + stepIdx * 55),
            )
            .shimmer(
              duration: 1400.ms,
              color:
                  Colors.white.withValues(alpha: isFirst ? 0.35 : 0.28),
              blendMode: BlendMode.srcATop,
            );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Role card skeleton — white card + icon + text lines + badge
// ═══════════════════════════════════════════════════════════
class _RoleCardSkeleton extends StatelessWidget {
  const _RoleCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.lightGray.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.lightGray.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 16),
          // Text lines
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LSkel(w: 100, h: 15, radius: 7),
                const SizedBox(height: 8),
                _LSkel(w: double.infinity, h: 11, radius: 5),
                const SizedBox(height: 5),
                _LSkel(w: 140, h: 11, radius: 5),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Check badge
          _LSkel(w: 22, h: 22, radius: 11),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1600.ms,
          color: Colors.white.withValues(alpha: 0.55),
          blendMode: BlendMode.srcATop,
        );
  }
}

// ═══════════════════════════════════════════════════════════
// Left-panel dot grid — white dots (0.06 alpha), 28 px grid
// ═══════════════════════════════════════════════════════════
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => false;
}

// ═══════════════════════════════════════════════════════════
// Right-panel dot grid — navy dots (0.028 alpha), 32 px grid
// ═══════════════════════════════════════════════════════════
class _RightDotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.navy.withValues(alpha: 0.028)
      ..style = PaintingStyle.fill;
    const spacing = 32.0;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_RightDotGridPainter old) => false;
}

// ═══════════════════════════════════════════════════════════
// _DSkel — dark-background shimmer block (left panel)
// ═══════════════════════════════════════════════════════════
class _DSkel extends StatelessWidget {
  final double w;
  final double h;
  final double radius;

  const _DSkel({required this.w, required this.h, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(radius),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1400.ms,
          color: Colors.white.withValues(alpha: 0.22),
          blendMode: BlendMode.srcATop,
        );
  }
}

// ═══════════════════════════════════════════════════════════
// _LSkel — light-background shimmer block (right panel / card)
// ═══════════════════════════════════════════════════════════
class _LSkel extends StatelessWidget {
  final double w;
  final double h;
  final double radius;
  final Color? baseColor;
  final Color? shimColor;

  const _LSkel({
    required this.w,
    required this.h,
    required this.radius,
    this.baseColor,
    this.shimColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: baseColor ?? AppColors.lightGray.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(radius),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1400.ms,
          color: shimColor ?? Colors.white.withValues(alpha: 0.72),
          blendMode: BlendMode.srcATop,
        );
  }
}
