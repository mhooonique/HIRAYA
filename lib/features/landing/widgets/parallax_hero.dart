// lib/features/landing/widgets/parallax_hero.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// ParallaxHero — Cinematic landing page hero (Enhanced v3)
// Full-viewport • 50+ particle stars • Orb system • Parallax
// Word-by-word headline reveal • Animated badges • Scroll indicator
// ═══════════════════════════════════════════════════════════

class ParallaxHero extends StatefulWidget {
  final double scrollOffset;
  const ParallaxHero({super.key, required this.scrollOffset});

  @override
  State<ParallaxHero> createState() => _ParallaxHeroState();
}

class _ParallaxHeroState extends State<ParallaxHero>
    with TickerProviderStateMixin {
  late AnimationController _orbCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _scrollIndicatorCtrl;
  late AnimationController _shimmerCtrl;

  Offset _mousePosition = Offset.zero;

  // Pre-generated particle data
  late final List<_ParticleData> _particles;

  @override
  void initState() {
    super.initState();
    final rng = math.Random(42);
    _particles = List.generate(
      55,
      (i) => _ParticleData(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: 1.0 + rng.nextDouble() * 2.5,
        speed: 0.2 + rng.nextDouble() * 0.8,
        opacity: 0.15 + rng.nextDouble() * 0.55,
        phase: rng.nextDouble() * math.pi * 2,
      ),
    );

    _orbCtrl = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _particleCtrl = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _pulseCtrl = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scrollIndicatorCtrl = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _shimmerCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _particleCtrl.dispose();
    _pulseCtrl.dispose();
    _scrollIndicatorCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;
    final heroHeight = size.height;

    return MouseRegion(
      onHover: (e) => setState(() => _mousePosition = e.localPosition),
      child: SizedBox(
        height: heroHeight,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _orbCtrl, _particleCtrl, _pulseCtrl, _scrollIndicatorCtrl, _shimmerCtrl,
          ]),
          builder: (_, __) {
            final t = _orbCtrl.value;
            // Mouse parallax delta (subtle)
            final mx = (_mousePosition.dx / (size.width + 1) - 0.5) * 30;
            final my = (_mousePosition.dy / (heroHeight + 1) - 0.5) * 20;

            return Stack(
              children: [
                // ── Background gradient (with scroll parallax) ──────────
                Positioned(
                  top: -widget.scrollOffset * 0.3,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(0, -0.3),
                        radius: 1.4,
                        colors: [
                          Color(0xFF0A1628),
                          AppColors.richNavy,
                          AppColors.deepVoid,
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // ── Particle field ──────────────────────────────────────
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ParticlePainter(
                      particles: _particles,
                      progress: _particleCtrl.value,
                    ),
                  ),
                ),

                // ── Orb system ──────────────────────────────────────────
                // Golden orb — top right
                Positioned(
                  right: -120 + t * 60 + mx,
                  top: -80 + t * 50 + my,
                  child: Container(
                    width: 500,
                    height: 500,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.golden.withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Teal orb — bottom left
                Positioned(
                  left: -100 + (1 - t) * 50 - mx * 0.5,
                  bottom: -60 + t * 40,
                  child: Container(
                    width: 420,
                    height: 420,
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
                // Sky orb — center left
                Positioned(
                  left: size.width * 0.15 + t * 30,
                  top: heroHeight * 0.4 + (1 - t) * 30,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.sky.withValues(alpha: 0.08),
                          blurRadius: 150,
                          spreadRadius: 30,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Diagonal light streaks ──────────────────────────────
                Positioned.fill(
                  child: CustomPaint(
                    painter: _StreakPainter(progress: _shimmerCtrl.value),
                  ),
                ),

                // ── Main content ────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.only(
                    left: isDesktop ? 80 : 24,
                    right: isDesktop ? 80 : 24,
                    top: 90, // navbar height + padding
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Announcement badge
                      _AnnouncementBadge(pulseCtrl: _pulseCtrl),
                      SizedBox(height: isDesktop ? 28 : 20),

                      // Main headline
                      _HeroHeadline(isDesktop: isDesktop),
                      SizedBox(height: isDesktop ? 20 : 14),

                      // Subtitle
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isDesktop ? 580 : double.infinity,
                        ),
                        child: Text(
                          'The premier Philippine platform connecting verified innovators with clients, investors, and institutions — driving Filipino excellence forward.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: isDesktop ? 17 : 14,
                            color: Colors.white.withValues(alpha: 0.48),
                            height: 1.75,
                          ),
                        )
                            .animate(delay: 800.ms)
                            .fadeIn(duration: 700.ms)
                            .slideY(begin: 0.2, end: 0),
                      ),
                      SizedBox(height: isDesktop ? 40 : 28),

                      // CTA Buttons
                      _CtaButtons(isDesktop: isDesktop),
                      SizedBox(height: isDesktop ? 52 : 36),

                      // Stats row
                      _StatsRow(
                        isDesktop: isDesktop,
                        pulseCtrl: _pulseCtrl,
                      ),
                    ],
                  ),
                ),

                // ── Scroll indicator ────────────────────────────────────
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: _ScrollIndicator(ctrl: _scrollIndicatorCtrl),
                ),

                // ── Bottom fade overlay ─────────────────────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 120,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.deepVoid.withValues(alpha: 0.80),
                          AppColors.deepVoid,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Particle Data ─────────────────────────────────────────────────────────
class _ParticleData {
  final double x, y, size, speed, opacity, phase;
  const _ParticleData({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.phase,
  });
}

// ── Particle Painter ──────────────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final List<_ParticleData> particles;
  final double progress;

  const _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final opacity = p.opacity *
          (0.4 + 0.6 * math.sin(progress * math.pi * 2 * p.speed + p.phase).abs());
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final x = p.x * size.width;
      final y = (p.y * size.height + progress * size.height * p.speed * 0.1) %
          size.height;

      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}

// ── Streak Painter ────────────────────────────────────────────────────────
class _StreakPainter extends CustomPainter {
  final double progress;
  const _StreakPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final streaks = [
      _StreakConfig(startX: 0.15, startY: 0.1, endX: 0.55, endY: 0.6, phase: 0.0),
      _StreakConfig(startX: 0.60, startY: 0.05, endX: 0.95, endY: 0.55, phase: 0.33),
      _StreakConfig(startX: 0.05, startY: 0.45, endX: 0.45, endY: 0.95, phase: 0.67),
    ];

    for (final s in streaks) {
      final t = ((progress + s.phase) % 1.0);
      if (t > 0.8) continue;
      final opacity = (math.sin(t * math.pi)).clamp(0.0, 1.0) * 0.06;
      final paint = Paint()
        ..color = AppColors.golden.withValues(alpha: opacity)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(s.startX * size.width, s.startY * size.height),
        Offset(s.endX * size.width, s.endY * size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StreakPainter old) => old.progress != progress;
}

class _StreakConfig {
  final double startX, startY, endX, endY, phase;
  const _StreakConfig({
    required this.startX, required this.startY,
    required this.endX, required this.endY,
    required this.phase,
  });
}

// ── Announcement Badge ────────────────────────────────────────────────────
class _AnnouncementBadge extends StatelessWidget {
  final AnimationController pulseCtrl;
  const _AnnouncementBadge({required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (_, __) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.golden.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.golden.withValues(alpha: 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.golden.withValues(
                  alpha: 0.08 + 0.06 * pulseCtrl.value,
                ),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Live pulse dot
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.teal,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withValues(
                        alpha: 0.4 + 0.4 * pulseCtrl.value,
                      ),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [AppColors.golden, AppColors.warmEmber],
                ).createShader(b),
                child: const Text(
                  '500+ Filipino Innovations Listed',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 10,
                color: AppColors.golden,
              ),
            ],
          ),
        );
      },
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -0.3, end: 0, curve: Curves.easeOutCubic);
  }
}

// ── Hero Headline ─────────────────────────────────────────────────────────
class _HeroHeadline extends StatelessWidget {
  final bool isDesktop;
  const _HeroHeadline({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final fontSize = isDesktop ? 62.0 : 36.0;

    return Column(
      children: [
        Text(
          'Connecting',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.1,
            letterSpacing: -2,
          ),
        )
            .animate(delay: 200.ms)
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.3, end: 0),

        // "Innovators" — golden gradient
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.golden, AppColors.warmEmber, AppColors.golden],
            stops: [0.0, 0.5, 1.0],
          ).createShader(bounds),
          child: Text(
            'Innovators',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
              letterSpacing: -2,
            ),
          ),
        )
            .animate(delay: 350.ms)
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.3, end: 0)
            .shimmer(delay: 1200.ms, duration: 1500.ms, color: Colors.white.withValues(alpha: 0.3)),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'with ',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.1,
                letterSpacing: -2,
              ),
            ),
            // "Opportunities" — teal gradient
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.teal, AppColors.sky],
              ).createShader(bounds),
              child: Text(
                'Opportunities',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: -2,
                ),
              ),
            ),
          ],
        )
            .animate(delay: 500.ms)
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.3, end: 0),
      ],
    );
  }
}

// ── CTA Buttons ───────────────────────────────────────────────────────────
class _CtaButtons extends StatelessWidget {
  final bool isDesktop;
  const _CtaButtons({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final buttons = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Primary: Explore Innovations
        _PrimaryButton(
          label: 'Explore Innovations',
          icon: Icons.explore_rounded,
          onTap: () => context.go('/marketplace'),
        ),
        const SizedBox(width: 14),
        // Secondary: Join as Innovator
        _SecondaryButton(
          label: 'Join as Innovator',
          icon: Icons.lightbulb_rounded,
          onTap: () => context.go('/signup'),
        ),
      ],
    );

    return (isDesktop
        ? buttons
        : Column(
            children: [
              _PrimaryButton(
                label: 'Explore Innovations',
                icon: Icons.explore_rounded,
                onTap: () => context.go('/marketplace'),
              ),
              const SizedBox(height: 12),
              _SecondaryButton(
                label: 'Join as Innovator',
                icon: Icons.lightbulb_rounded,
                onTap: () => context.go('/signup'),
              ),
            ],
          ))
        .animate(delay: 700.ms)
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.25, end: 0);
  }
}

class _PrimaryButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.icon, required this.onTap});

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.golden, AppColors.warmEmber],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.golden.withValues(alpha: _hovered ? 0.55 : 0.25),
                  blurRadius: _hovered ? 30 : 14,
                  offset: const Offset(0, 6),
                  spreadRadius: _hovered ? 4 : 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 18, color: AppColors.navy),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
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

class _SecondaryButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _SecondaryButton({required this.label, required this.icon, required this.onTap});

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                decoration: BoxDecoration(
                  color: _hovered
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _hovered
                        ? Colors.white.withValues(alpha: 0.40)
                        : Colors.white.withValues(alpha: 0.18),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, size: 18, color: Colors.white.withValues(alpha: 0.80)),
                    const SizedBox(width: 10),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.90),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stats Row ─────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final bool isDesktop;
  final AnimationController pulseCtrl;
  const _StatsRow({required this.isDesktop, required this.pulseCtrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 20,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: isDesktop
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _buildStatItems(),
                )
              : Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 0,
                  runSpacing: 8,
                  children: _buildStatItems(),
                ),
        ),
      ),
    )
        .animate(delay: 1000.ms)
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.2, end: 0);
  }

  List<Widget> _buildStatItems() {
    final items = [
      ('500+', 'Innovations', AppColors.golden),
      ('200+', 'Innovators', AppColors.teal),
      ('15+', 'Universities', AppColors.sky),
    ];

    final result = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      result.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              ShaderMask(
                shaderCallback: (b) => LinearGradient(
                  colors: [item.$3, item.$3.withValues(alpha: 0.7)],
                ).createShader(b),
                child: Text(
                  item.$1,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Text(
                item.$2,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
      if (i < items.length - 1) {
        result.add(
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.12),
          ),
        );
      }
    }
    return result;
  }
}

// ── Scroll Indicator ──────────────────────────────────────────────────────
class _ScrollIndicator extends StatelessWidget {
  final AnimationController ctrl;
  const _ScrollIndicator({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        return Column(
          children: [
            Text(
              'Scroll to explore',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.30),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Transform.translate(
              offset: Offset(0, ctrl.value * 8),
              child: Opacity(
                opacity: 0.4 + ctrl.value * 0.4,
                child: Container(
                  width: 28,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: 4,
                      height: 10,
                      margin: EdgeInsets.only(top: ctrl.value * 16),
                      decoration: BoxDecoration(
                        color: AppColors.golden.withValues(alpha: 0.70),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    )
        .animate(delay: 1400.ms)
        .fadeIn(duration: 700.ms);
  }
}
