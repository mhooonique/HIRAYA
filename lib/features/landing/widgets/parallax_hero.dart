import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class ParallaxHero extends StatefulWidget {
  final double scrollOffset;
  const ParallaxHero({super.key, required this.scrollOffset});

  @override
  State<ParallaxHero> createState() => _ParallaxHeroState();
}

class _ParallaxHeroState extends State<ParallaxHero>
    with TickerProviderStateMixin {
  late AnimationController _gradCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _breathCtrl;
  late AnimationController _particleCtrl;

  // Mouse-tracking position (normalised 0..1)
  Offset _mouse = const Offset(0.5, 0.5);

  @override
  void initState() {
    super.initState();
    _gradCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _orbCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
    _breathCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 12))
      ..repeat();
  }

  @override
  void dispose() {
    _gradCtrl.dispose();
    _orbCtrl.dispose();
    _breathCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final parallaxShift = widget.scrollOffset * 0.4;

    // Mouse-driven tilt amounts (max Â±24 px)
    final mx = (_mouse.dx - 0.5) * 48;
    final my = (_mouse.dy - 0.5) * 32;

    return MouseRegion(
      onHover: (e) {
        final norm = Offset(
          e.localPosition.dx / size.width,
          e.localPosition.dy / size.height,
        );
        setState(() => _mouse = norm);
      },
      child: SizedBox(
        height: size.height,
        child: Stack(
          children: [
            // â”€â”€ Animated gradient background â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Positioned(
              top: -parallaxShift,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _gradCtrl,
                builder: (_, __) => Container(
                  height: size.height + 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(AppColors.navy,
                            const Color(0xFF041F33), _gradCtrl.value)!,
                        Color.lerp(const Color(0xFF064663),
                            const Color(0xFF053E5E), _gradCtrl.value)!,
                        Color.lerp(AppColors.teal,
                            const Color(0xFF0A4F45), _gradCtrl.value)!,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // â”€â”€ Cinematic vignette â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.4,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.30),
                    ],
                  ),
                ),
              ),
            ),

            // â”€â”€ Dot grid (subtle) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Positioned.fill(
              child: Opacity(
                opacity: 0.04,
                child: CustomPaint(painter: _GridPainter()),
              ),
            ),

            // â”€â”€ Scanline overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Positioned.fill(
              child: Opacity(
                opacity: 0.025,
                child: CustomPaint(painter: _ScanlinePainter()),
              ),
            ),

            // â”€â”€ Floating particles â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _particleCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _ParticlePainter(_particleCtrl.value),
                ),
              ),
            ),

            // â”€â”€ Orb 1 â€” teal, top-right (mouse-tracked) â”€
            AnimatedBuilder(
              animation: _orbCtrl,
              builder: (_, __) {
                final drift =
                    math.sin(_orbCtrl.value * math.pi * 2) * 30;
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 80),
                  curve: Curves.easeOut,
                  top: 50.0 + drift + my * 0.6,
                  right: -80.0 + mx * 0.5,
                  child: Container(
                    width: 380,
                    height: 380,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        AppColors.teal.withValues(alpha: 0.22),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                );
              },
            ),

            // â”€â”€ Orb 2 â€” sky, left (mouse-tracked) â”€â”€â”€â”€â”€â”€â”€
            AnimatedBuilder(
              animation: _orbCtrl,
              builder: (_, __) {
                final drift =
                    math.sin((_orbCtrl.value + 0.33) * math.pi * 2) *
                        22;
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 80),
                  curve: Curves.easeOut,
                  top: 180.0 + drift - my * 0.4,
                  left: -100.0 - mx * 0.5,
                  child: Container(
                    width: 290,
                    height: 290,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        AppColors.sky.withValues(alpha: 0.16),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                );
              },
            ),

            // â”€â”€ Orb 3 â€” golden, bottom-right â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            AnimatedBuilder(
              animation: _orbCtrl,
              builder: (_, __) {
                final drift =
                    math.sin((_orbCtrl.value + 0.66) * math.pi * 2) *
                        18;
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 80),
                  curve: Curves.easeOut,
                  bottom: 90.0 + drift - my * 0.3,
                  right: 80.0 + mx * 0.3,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        AppColors.golden.withValues(alpha: 0.14),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                );
              },
            ),

            // â”€â”€ Main content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 80),

                  // Logo â€” breathes gently
                  AnimatedBuilder(
                    animation: _breathCtrl,
                    builder: (_, child) => Transform.scale(
                      scale: 1.0 + _breathCtrl.value * 0.025,
                      child: child,
                    ),
                    child: Image.asset(
                      'assets/images/logo/final-logo.png',
                      height: 96,
                    )
                        .animate()
                        .fadeIn(duration: 700.ms, delay: 150.ms)
                        .slideY(
                            begin: -0.22,
                            end: 0,
                            duration: 700.ms,
                            delay: 150.ms,
                            curve: Curves.easeOutCubic),
                  ),

                  const SizedBox(height: 18),

                  // HIRAYA â€” letter stagger with glow
                  const _HirayaTitle(),

                  const SizedBox(height: 14),

                  // Tagline pill with golden border-left
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 9),
                    decoration: BoxDecoration(
                      border: const Border(
                        left: BorderSide(
                            color: AppColors.golden, width: 3),
                      ),
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: const Text(
                      AppStrings.tagline,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: AppColors.golden,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 700.ms, delay: 620.ms)
                      .slideX(
                          begin: -0.15,
                          end: 0,
                          curve: Curves.easeOutCubic),

                  const SizedBox(height: 14),

                  // Sub-tagline â€” word-by-word reveal
                  const _SubTagline(),

                  const SizedBox(height: 38),

                  // CTA buttons
                  const _HeroCTARow(),

                  const SizedBox(height: 40),

                  // Stats strip
                  const _StatsStrip(),
                ],
              ),
            ),

            // â”€â”€ Scroll indicator â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Text(
                    'SCROLL TO EXPLORE',
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 10,
                      fontFamily: 'Poppins',
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const _ScrollChevrons(),
                ],
              ).animate().fadeIn(duration: 700.ms, delay: 1500.ms),
            ),
          ],
        ),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// HIRAYA â€” letter-by-letter stagger + ambient glow
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _HirayaTitle extends StatelessWidget {
  const _HirayaTitle();

  @override
  Widget build(BuildContext context) {
    const letters = ['H', 'I', 'R', 'A', 'Y', 'A'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: letters.asMap().entries.map((e) {
        return Text(
          e.value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 72,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 12,
            shadows: [
              Shadow(
                color: AppColors.teal.withValues(alpha: 0.55),
                blurRadius: 28,
                offset: const Offset(0, 0),
              ),
              Shadow(
                color: Colors.white.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        )
            .animate(delay: Duration(milliseconds: 420 + e.key * 65))
            .fadeIn(duration: 480.ms)
            .slideY(
                begin: 0.28,
                end: 0,
                curve: Curves.easeOutBack);
      }).toList(),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// Sub-tagline â€” words appear one-by-one
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _SubTagline extends StatelessWidget {
  const _SubTagline();

  @override
  Widget build(BuildContext context) {
    // Split into word groups for a staggered reveal
    const line1 = 'Discover, connect, and invest in the boldest';
    const line2 = 'innovations shaping the future.';

    return Column(
      children: [
        Text(
          line1,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            color: Colors.white60,
            height: 1.65,
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(duration: 600.ms, delay: 800.ms)
            .slideY(
                begin: 0.12,
                end: 0,
                duration: 600.ms,
                delay: 800.ms,
                curve: Curves.easeOutCubic),
        Text(
          line2,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            color: Colors.white60,
            height: 1.65,
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(duration: 600.ms, delay: 920.ms)
            .slideY(
                begin: 0.12,
                end: 0,
                duration: 600.ms,
                delay: 920.ms,
                curve: Curves.easeOutCubic),
      ],
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// Hero CTA Row
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _HeroCTARow extends StatelessWidget {
  const _HeroCTARow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _HeroPrimaryButton(),
        const SizedBox(width: 14),
        _HeroGhostButton(),
      ],
    )
        .animate()
        .fadeIn(duration: 700.ms, delay: 1000.ms)
        .slideY(begin: 0.18, end: 0, curve: Curves.easeOutCubic);
  }
}

class _HeroPrimaryButton extends StatefulWidget {
  @override
  State<_HeroPrimaryButton> createState() => _HeroPrimaryButtonState();
}

class _HeroPrimaryButtonState extends State<_HeroPrimaryButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;
  late AnimationController _shimCtrl;

  @override
  void initState() {
    super.initState();
    _shimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
  }

  @override
  void dispose() {
    _shimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovered = true);
        _shimCtrl.repeat();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _shimCtrl
          ..stop()
          ..reset();
      },
      child: GestureDetector(
        onTap: () => context.go('/signup'),
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _hovered
                    ? [AppColors.crimson, const Color(0xFFFF2244)]
                    : [const Color(0xFFE80020), AppColors.crimson],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.crimson
                      .withValues(alpha: _hovered ? 0.55 : 0.32),
                  blurRadius: _hovered ? 28 : 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  if (_hovered)
                    AnimatedBuilder(
                      animation: _shimCtrl,
                      builder: (_, __) => Positioned(
                        left: -60.0 + _shimCtrl.value * 280,
                        top: 0,
                        bottom: 0,
                        width: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.18),
                              Colors.transparent,
                            ]),
                          ),
                        ),
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.rocket_launch_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      const Text(
                        'Get Started',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        child: _hovered
                            ? const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 15),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroGhostButton extends StatefulWidget {
  @override
  State<_HeroGhostButton> createState() => _HeroGhostButtonState();
}

class _HeroGhostButtonState extends State<_HeroGhostButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go('/marketplace'),
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            decoration: BoxDecoration(
              color: _hovered
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _hovered
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.38),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.explore_rounded,
                    color: _hovered ? Colors.white : Colors.white70,
                    size: 18),
                const SizedBox(width: 10),
                Text(
                  'Browse Innovations',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: _hovered ? Colors.white : Colors.white70,
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

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// Stats strip
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _StatsStrip extends StatelessWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding:
          const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(value: '500+', label: 'Innovations'),
          _StatDivider(),
          _StatItem(value: '120+', label: 'Innovators'),
          _StatDivider(),
          _StatItem(value: '6', label: 'Categories'),
          _StatDivider(),
          _StatItem(value: '100%', label: 'Verified'),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 700.ms, delay: 1200.ms)
        .slideY(begin: 0.14, end: 0, curve: Curves.easeOutCubic);
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.golden,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: Colors.white54,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// Scroll chevrons â€” triple-layer bounce
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _ScrollChevrons extends StatelessWidget {
  const _ScrollChevrons();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (i) {
        return Icon(
          Icons.keyboard_arrow_down_rounded,
          color: Colors.white.withValues(alpha: 0.18 + i * 0.13),
          size: 22,
        )
            .animate(
              delay: Duration(milliseconds: 220 * i),
              onPlay: (c) => c.repeat(reverse: true),
            )
            .slideY(
                begin: -0.3,
                end: 0.3,
                duration: 700.ms,
                curve: Curves.easeInOut)
            .fadeIn(duration: 700.ms);
      }),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// Grid painter (dot grid)
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
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

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// Scanline painter â€” horizontal scan bands
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter old) => false;
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// Floating particle painter â€” 24 drifting dots
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
class _ParticlePainter extends CustomPainter {
  final double t; // 0..1, drives sine drift

  static final _rng = math.Random(42);
  static final List<_ParticleDef> _defs = List.generate(24, (i) {
    return _ParticleDef(
      x: _rng.nextDouble(),
      y: _rng.nextDouble(),
      r: 1.2 + _rng.nextDouble() * 2.2,
      speed: 0.18 + _rng.nextDouble() * 0.22,
      phase: _rng.nextDouble() * math.pi * 2,
      drift: (_rng.nextDouble() - 0.5) * 0.04,
      opacity: 0.08 + _rng.nextDouble() * 0.18,
    );
  });

  const _ParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _defs) {
      final cy = ((p.y - t * p.speed + 1.0) % 1.0) * size.height;
      final cx = (p.x + math.sin(t * math.pi * 2 + p.phase) * p.drift) *
          size.width;
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), p.r, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}

class _ParticleDef {
  final double x, y, r, speed, phase, drift, opacity;
  const _ParticleDef({
    required this.x,
    required this.y,
    required this.r,
    required this.speed,
    required this.phase,
    required this.drift,
    required this.opacity,
  });
}

