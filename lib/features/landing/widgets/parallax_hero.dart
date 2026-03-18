import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

// ═══════════════════════════════════════════════════════════
// ParallaxHero — Cinematic landing page hero (Enhanced v2)
// ═══════════════════════════════════════════════════════════
class ParallaxHero extends StatefulWidget {
  final double scrollOffset;
  const ParallaxHero({super.key, required this.scrollOffset});

  @override
  State<ParallaxHero> createState() => _ParallaxHeroState();
}

class _ParallaxHeroState extends State<ParallaxHero>
    with TickerProviderStateMixin {
  // Existing controllers
  late AnimationController _orbCtrl;
  late AnimationController _floatCtrl;
  late Animation<double> _orbAnim;
  late Animation<double> _floatAnim;

  // New: particle animation
  late AnimationController _particleCtrl;

  // New: diagonal light streak
  late AnimationController _streakCtrl;
  late Animation<double> _streakAnim;

  // New: pulsing ring
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // New: animated counter trigger
  late AnimationController _counterCtrl;
  late Animation<double> _counterAnim;

  // New: mouse parallax
  Offset _mousePosition = Offset.zero;
  bool _mouseInitialized = false;

  @override
  void initState() {
    super.initState();

    _orbCtrl = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
    _orbAnim = CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut);

    _floatCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnim = CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut);

    _particleCtrl = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _streakCtrl = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: false);
    _streakAnim = CurvedAnimation(parent: _streakCtrl, curve: Curves.easeInOut);

    _pulseCtrl = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _counterCtrl = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _counterAnim = CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOutCubic);

    // Start counter animation after a delay
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) _counterCtrl.forward();
    });
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _floatCtrl.dispose();
    _particleCtrl.dispose();
    _streakCtrl.dispose();
    _pulseCtrl.dispose();
    _counterCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final parallaxShift = widget.scrollOffset * 0.4;
    final isDesktop = size.width > 900;

    // Mouse parallax offset
    final mouseOffsetX = _mouseInitialized
        ? (_mousePosition.dx / size.width - 0.5) * 24
        : 0.0;
    final mouseOffsetY = _mouseInitialized
        ? (_mousePosition.dy / size.height - 0.5) * 16
        : 0.0;

    return Listener(
      onPointerMove: (event) {
        setState(() {
          _mousePosition = event.localPosition;
          _mouseInitialized = true;
        });
      },
      child: SizedBox(
        height: size.height,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // ── Deep cinematic background ──────────────────────
            Positioned(
              top: -parallaxShift,
              left: 0,
              right: 0,
              child: Container(
                height: size.height + 200,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.deepVoid,
                      AppColors.richNavy,
                      Color(0xFF0A2240),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),

            // ── Diagonal grid texture ─────────────────────────
            Positioned.fill(
              child: Opacity(
                opacity: 0.025,
                child: CustomPaint(painter: _GridPainter()),
              ),
            ),

            // ── Floating particle dots ─────────────────────────
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _particleCtrl,
                builder: (_, __) {
                  return CustomPaint(
                    painter: _ParticlePainter(
                      progress: _particleCtrl.value,
                      parallaxX: mouseOffsetX * 0.5,
                      parallaxY: mouseOffsetY * 0.5,
                    ),
                  );
                },
              ),
            ),

            // ── Diagonal light streak ──────────────────────────
            AnimatedBuilder(
              animation: _streakAnim,
              builder: (_, __) {
                return Positioned.fill(
                  child: CustomPaint(
                    painter: _LightStreakPainter(progress: _streakAnim.value),
                  ),
                );
              },
            ),

            // ── Animated orbs (with mouse parallax) ───────────
            AnimatedBuilder(
              animation: _orbAnim,
              builder: (_, __) {
                final t = _orbAnim.value;
                return Stack(
                  children: [
                    // Teal orb — top right
                    Positioned(
                      right: -80 + t * 20 - parallaxShift * 0.05 - mouseOffsetX * 0.8,
                      top: -60 + t * 15 + mouseOffsetY * 0.6,
                      child: _Orb(
                        size: 380,
                        color: AppColors.teal.withValues(alpha: 0.15),
                      ),
                    ),
                    // Golden orb — bottom left
                    Positioned(
                      left: -80 + t * 10 + mouseOffsetX * 0.4,
                      bottom: 80 + t * 20 + parallaxShift * 0.1 - mouseOffsetY * 0.5,
                      child: _Orb(
                        size: 300,
                        color: AppColors.golden.withValues(alpha: 0.10),
                      ),
                    ),
                    // Sky orb — center
                    Positioned(
                      left: size.width * 0.35 + t * 10 + mouseOffsetX * 0.3,
                      top: size.height * 0.3 - t * 10 + mouseOffsetY * 0.3,
                      child: _Orb(
                        size: 220,
                        color: AppColors.sky.withValues(alpha: 0.07),
                      ),
                    ),
                    // Crimson orb — top left
                    Positioned(
                      left: 60 - t * 8 + mouseOffsetX * 0.5,
                      top: 120 + t * 12 - parallaxShift * 0.08 + mouseOffsetY * 0.4,
                      child: _Orb(
                        size: 180,
                        color: AppColors.crimson.withValues(alpha: 0.07),
                      ),
                    ),
                    // Extra warmEmber orb — center right
                    Positioned(
                      right: size.width * 0.15 - mouseOffsetX * 0.6,
                      top: size.height * 0.6 + t * 15,
                      child: _Orb(
                        size: 150,
                        color: AppColors.warmEmber.withValues(alpha: 0.06),
                      ),
                    ),
                  ],
                );
              },
            ),

            // ── Main content ──────────────────────────────────
            Positioned.fill(
              child: isDesktop
                  ? _buildDesktopLayout(context, size, parallaxShift)
                  : _buildMobileLayout(context, size),
            ),

            // ── Scroll indicator with gradient progress bar ──
            Positioned(
              bottom: 22,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Text(
                    'SCROLL TO EXPLORE',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontFamily: 'Poppins',
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Gradient progress indicator
                  Container(
                    width: 80,
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.golden.withValues(alpha: 0.70),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white38,
                    size: 28,
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .moveY(
                        begin: 0,
                        end: 8,
                        duration: 900.ms,
                        curve: Curves.easeInOut,
                      )
                      .then()
                      .moveY(begin: 8, end: 0, duration: 900.ms),
                ],
              ).animate().fadeIn(duration: 800.ms, delay: 1600.ms),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Desktop: two-column layout ───────────────────────────
  Widget _buildDesktopLayout(
      BuildContext context, Size size, double parallaxShift) {
    return Row(
      children: [
        // Left column — text content
        Expanded(
          flex: 55,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                _buildEyebrow(),
                const SizedBox(height: 20),
                _buildHeadline(context),
                const SizedBox(height: 20),
                _buildSubtitle(),
                const SizedBox(height: 40),
                _buildCtaRow(context),
                const SizedBox(height: 48),
                _buildStatsRow(),
              ],
            ),
          ),
        ),

        // Right column — floating cards (desktop decorative)
        Expanded(
          flex: 45,
          child: AnimatedBuilder(
            animation: _floatAnim,
            builder: (_, __) {
              final float = _floatAnim.value;
              return Transform.translate(
                offset: Offset(0, -8 + float * 16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulsing ring behind cards
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) {
                        final p = _pulseAnim.value;
                        return CustomPaint(
                          size: const Size(340, 340),
                          painter: _PulsingRingPainter(
                            progress: p,
                            color: AppColors.golden,
                          ),
                        );
                      },
                    ),
                    _buildFloatingCards(),
                  ],
                ),
              );
            },
          )
              .animate()
              .fadeIn(duration: 800.ms, delay: 1000.ms)
              .slideX(
                begin: 0.3,
                end: 0,
                duration: 800.ms,
                delay: 1000.ms,
                curve: Curves.easeOutCubic,
              ),
        ),
      ],
    );
  }

  // ─── Mobile: single-column layout ─────────────────────────
  Widget _buildMobileLayout(BuildContext context, Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          _buildEyebrow(centered: true),
          const SizedBox(height: 16),
          _buildHeadline(context, centered: true),
          const SizedBox(height: 16),
          _buildSubtitle(centered: true),
          const SizedBox(height: 36),
          _buildCtaRow(context, wrap: true),
          const SizedBox(height: 40),
          _buildStatsRow(centered: true),
        ],
      ),
    );
  }

  // ─── Eyebrow label ─────────────────────────────────────────
  Widget _buildEyebrow({bool centered = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.golden.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.golden.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🇵🇭', style: TextStyle(fontSize: 14)),
          SizedBox(width: 8),
          Text(
            'PHILIPPINE INNOVATION MARKETPLACE',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.golden,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .slideY(begin: -0.2, end: 0, duration: 600.ms, delay: 200.ms);
  }

  // ─── Main headline ─────────────────────────────────────────
  Widget _buildHeadline(BuildContext context, {bool centered = false}) {
    return Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'Where Filipino',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 60,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.1,
            letterSpacing: -1,
          ),
          textAlign: centered ? TextAlign.center : TextAlign.start,
        )
            .animate()
            .fadeIn(duration: 700.ms, delay: 400.ms)
            .slideY(
              begin: 0.2,
              end: 0,
              duration: 700.ms,
              delay: 400.ms,
              curve: Curves.easeOutCubic,
            ),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.golden, AppColors.warmEmber, AppColors.golden],
            stops: [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: const Text(
            'Innovation Soars',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 60,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
              letterSpacing: -1,
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 700.ms, delay: 550.ms)
            .slideY(
              begin: 0.2,
              end: 0,
              duration: 700.ms,
              delay: 550.ms,
              curve: Curves.easeOutCubic,
            ),
      ],
    );
  }

  // ─── Subtitle ──────────────────────────────────────────────
  Widget _buildSubtitle({bool centered = false}) {
    return Text(
      AppStrings.subTagline,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 17,
        color: Colors.white.withValues(alpha: 0.70),
        height: 1.6,
        letterSpacing: 0.2,
      ),
      textAlign: centered ? TextAlign.center : TextAlign.start,
      maxLines: 3,
    ).animate().fadeIn(duration: 600.ms, delay: 750.ms);
  }

  // ─── CTA buttons row ───────────────────────────────────────
  Widget _buildCtaRow(BuildContext context, {bool wrap = false}) {
    final buttons = [
      _HeroButton(
        label: 'Explore Innovations',
        icon: Icons.explore_rounded,
        isGolden: true,
        onTap: () => context.go('/marketplace'),
      ),
      _HeroButton(
        label: 'Join as Innovator',
        icon: Icons.rocket_launch_rounded,
        isGolden: false,
        onTap: () => context.go('/signup'),
      ),
    ];

    final row = wrap
        ? Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: buttons,
          )
        : Row(
            children: [
              buttons[0],
              const SizedBox(width: 16),
              buttons[1],
            ],
          );

    return row
        .animate()
        .fadeIn(duration: 600.ms, delay: 1000.ms)
        .slideY(
          begin: 0.2,
          end: 0,
          duration: 600.ms,
          delay: 1000.ms,
          curve: Curves.easeOutCubic,
        );
  }

  // ─── Stats row with animated counters ─────────────────────
  Widget _buildStatsRow({bool centered = false}) {
    return AnimatedBuilder(
      animation: _counterAnim,
      builder: (_, __) {
        final progress = _counterAnim.value;
        return Row(
          mainAxisAlignment:
              centered ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            _AnimatedStatItem(
              label: 'Verified Innovators',
              targetValue: 120,
              suffix: '+',
              color: AppColors.teal,
              progress: progress,
            ),
            _VertDivider(),
            _AnimatedStatItem(
              label: 'Industry Sectors',
              targetValue: 6,
              suffix: '',
              color: AppColors.golden,
              progress: progress,
            ),
            _VertDivider(),
            _AnimatedStatItem(
              label: 'Innovations Listed',
              targetValue: 500,
              suffix: '+',
              color: AppColors.sky,
              progress: progress,
            ),
          ],
        );
      },
    ).animate().fadeIn(duration: 600.ms, delay: 1300.ms);
  }

  // ─── Decorative floating cards (desktop only) ──────────────
  Widget _buildFloatingCards() {
    return Padding(
      padding: const EdgeInsets.only(right: 40),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Back card — rotated left
          Transform.rotate(
            angle: -0.08,
            child: Transform.translate(
              offset: const Offset(-20, 20),
              child: const _MockProductCard(
                name: 'Solar Water Purifier',
                category: 'Energy',
                location: 'MSU-IIT, Iligan City',
                color: AppColors.golden,
              ),
            ),
          ),
          // Front card — slight right rotation
          Transform.rotate(
            angle: 0.05,
            child: Transform.translate(
              offset: const Offset(20, -10),
              child: const _MockProductCard(
                name: 'AI Diagnostic Tablet',
                category: 'Healthcare',
                location: 'CMU College of Medicine',
                color: AppColors.crimson,
              ),
            ),
          ),
          // Center card — upright
          const _MockProductCard(
            name: 'Smart Rice Monitor',
            category: 'Agriculture',
            location: 'Brgy. Maridagao, Cotabato',
            color: AppColors.teal,
            isPrimary: true,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Animated stat item with counter
// ═══════════════════════════════════════════════════════════
class _AnimatedStatItem extends StatelessWidget {
  final String label;
  final int targetValue;
  final String suffix;
  final Color color;
  final double progress;

  const _AnimatedStatItem({
    required this.label,
    required this.targetValue,
    required this.suffix,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final current = (targetValue * progress).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$current$suffix',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.55),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Hero button widget
// ═══════════════════════════════════════════════════════════
class _HeroButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isGolden;
  final VoidCallback onTap;

  const _HeroButton({
    required this.label,
    required this.icon,
    required this.isGolden,
    required this.onTap,
  });

  @override
  State<_HeroButton> createState() => _HeroButtonState();
}

class _HeroButtonState extends State<_HeroButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    double scale = 1.0;
    if (_hovered) scale = 1.04;
    if (_pressed) scale = 0.97;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              gradient: widget.isGolden
                  ? const LinearGradient(
                      colors: [AppColors.golden, AppColors.warmEmber],
                    )
                  : null,
              color: widget.isGolden
                  ? null
                  : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: widget.isGolden
                  ? null
                  : Border.all(
                      color: Colors.white
                          .withValues(alpha: _hovered ? 0.5 : 0.25),
                      width: 1.5,
                    ),
              boxShadow: widget.isGolden && _hovered
                  ? [
                      BoxShadow(
                        color: AppColors.golden.withValues(alpha: 0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      )
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  color: widget.isGolden ? AppColors.navy : Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: widget.isGolden ? AppColors.navy : Colors.white,
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

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      color: Colors.white.withValues(alpha: 0.12),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Mock product card (decorative)
// ═══════════════════════════════════════════════════════════
class _MockProductCard extends StatelessWidget {
  final String name;
  final String category;
  final String location;
  final Color color;
  final bool isPrimary;

  const _MockProductCard({
    required this.name,
    required this.category,
    required this.location,
    required this.color,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isPrimary ? 240 : 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1923).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: isPrimary ? 0.5 : 0.25),
          width: isPrimary ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isPrimary ? 0.25 : 0.10),
            blurRadius: isPrimary ? 30 : 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category color strip
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient:
                  LinearGradient(colors: [color, color.withValues(alpha: 0.3)]),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          // Icon area
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.lightbulb_rounded, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              category,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 11, color: Colors.white38),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  location,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: Colors.white38,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Floating orb
// ═══════════════════════════════════════════════════════════
class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  const _Orb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: size * 0.6,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Grid overlay painter
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

// ═══════════════════════════════════════════════════════════
// Floating particle dots painter
// ═══════════════════════════════════════════════════════════
class _ParticlePainter extends CustomPainter {
  final double progress;
  final double parallaxX;
  final double parallaxY;

  _ParticlePainter({
    required this.progress,
    required this.parallaxX,
    required this.parallaxY,
  });

  static final _rng = math.Random(42);
  static final List<_Particle> _particles = List.generate(60, (i) {
    return _Particle(
      x: _rng.nextDouble(),
      y: _rng.nextDouble(),
      size: 1.0 + _rng.nextDouble() * 2.0,
      speed: 0.04 + _rng.nextDouble() * 0.06,
      opacity: 0.08 + _rng.nextDouble() * 0.18,
      phase: _rng.nextDouble(),
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final y = (p.y + progress * p.speed) % 1.0;
      final wobble = math.sin((progress + p.phase) * math.pi * 2) * 0.005;
      final x = p.x + wobble + parallaxX / size.width * 0.1;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) =>
      old.progress != progress ||
      old.parallaxX != parallaxX ||
      old.parallaxY != parallaxY;
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  final double phase;

  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.phase,
  });
}

// ═══════════════════════════════════════════════════════════
// Diagonal light streak painter
// ═══════════════════════════════════════════════════════════
class _LightStreakPainter extends CustomPainter {
  final double progress;

  _LightStreakPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Animate a diagonal streak across the canvas
    final sweepPos = (progress % 1.0);
    final startX = -200.0 + (size.width + 400) * sweepPos;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.golden.withValues(alpha: 0.06),
          AppColors.warmEmber.withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(startX - 80, 0, 160, size.height))
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(startX - 80, 0)
      ..lineTo(startX + 60, 0)
      ..lineTo(startX + 60 - size.height * 0.6, size.height)
      ..lineTo(startX - 80 - size.height * 0.6, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_LightStreakPainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════════════════════
// Pulsing ring painter (around floating cards)
// ═══════════════════════════════════════════════════════════
class _PulsingRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _PulsingRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Inner ring
    final innerRadius = 120.0 + progress * 8;
    final innerPaint = Paint()
      ..color = color.withValues(alpha: 0.08 + progress * 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, innerRadius, innerPaint);

    // Outer ring
    final outerRadius = 155.0 + progress * 12;
    final outerPaint = Paint()
      ..color = color.withValues(alpha: 0.04 + progress * 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, outerRadius, outerPaint);

    // Far ring
    final farRadius = 190.0 + progress * 16;
    final farPaint = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.03 + progress * 0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, farRadius, farPaint);
  }

  @override
  bool shouldRepaint(_PulsingRingPainter old) => old.progress != progress;
}
