import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class CtaSection extends StatefulWidget {
  const CtaSection({super.key});

  @override
  State<CtaSection> createState() => _CtaSectionState();
}

class _CtaSectionState extends State<CtaSection>
    with TickerProviderStateMixin {
  late AnimationController _orbCtrl;
  late AnimationController _particleCtrl;

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 7))
      ..repeat(reverse: true);
    _particleCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 14))
      ..repeat();
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_orbCtrl, _particleCtrl]),
      builder: (_, child) {
        final t = _orbCtrl.value;
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(AppColors.teal, const Color(0xFF0D5A50), t)!,
                Color.lerp(AppColors.navy, const Color(0xFF041F33), t)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Orb top-left
              Positioned(
                top: -60.0 + math.sin(t * math.pi * 2) * 30,
                left: -60,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      AppColors.teal.withValues(alpha: 0.25),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              // Orb bottom-right
              Positioned(
                bottom: -40.0 + math.sin((t + 0.5) * math.pi * 2) * 22,
                right: -40,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      AppColors.golden.withValues(alpha: 0.16),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
              // Floating particle dots
              Positioned.fill(
                child: CustomPaint(
                  painter: _CtaParticlePainter(_particleCtrl.value),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 88, horizontal: 32),
        child: Column(
          children: [
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: const Text(
                '🚀  JOIN THE MOVEMENT',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
            ).animate().fadeIn(duration: 600.ms),
            const SizedBox(height: 22),

            // Headline
            const Text(
              'Ready to Showcase\nYour Innovation?',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 44,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.15,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 100.ms).fadeIn(duration: 600.ms).slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),

            const SizedBox(height: 14),

            const Text(
              'Join hundreds of Filipino innovators already on HIRAYA.',
              style: TextStyle(
                color: Colors.white60,
                fontFamily: 'Poppins',
                fontSize: 15,
                height: 1.6,
              ),
            ).animate(delay: 180.ms).fadeIn(duration: 600.ms),

            const SizedBox(height: 24),

            // Social proof avatar cluster
            const _SocialProofRow(),

            const SizedBox(height: 44),

            // Stats row
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CtaStat(value: '500+', label: 'Innovations Listed'),
                SizedBox(width: 48),
                _CtaStat(value: '120+', label: 'Active Innovators'),
                SizedBox(width: 48),
                _CtaStat(value: '6', label: 'Industry Sectors'),
              ],
            ).animate(delay: 250.ms).fadeIn(duration: 600.ms),

            const SizedBox(height: 44),

            // Primary CTA
            _CtaButton(),
          ],
        ),
      ),
    );
  }
}

class _CtaStat extends StatelessWidget {
  final String value;
  final String label;
  const _CtaStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.golden,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Colors.white54,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _CtaButton extends StatefulWidget {
  @override
  State<_CtaButton> createState() => _CtaButtonState();
}

class _CtaButtonState extends State<_CtaButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;
  late AnimationController _shimCtrl;

  @override
  void initState() {
    super.initState();
    _shimCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
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
        _shimCtrl..stop()..reset();
      },
      child: GestureDetector(
        onTap: () => context.go('/signup'),
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.golden,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.golden
                      .withValues(alpha: _hovered ? 0.55 : 0.30),
                  blurRadius: _hovered ? 32 : 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  if (_hovered)
                    AnimatedBuilder(
                      animation: _shimCtrl,
                      builder: (_, __) => Positioned(
                        left: -80.0 + _shimCtrl.value * 400,
                        top: 0,
                        bottom: 0,
                        width: 80,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.transparent,
                              Colors.white.withValues(alpha: 0.25),
                              Colors.transparent,
                            ]),
                          ),
                        ),
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Create Your Account',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: AppColors.navy,
                          letterSpacing: 0.3,
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        child: _hovered
                            ? const Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Icon(Icons.arrow_forward_rounded,
                                    color: AppColors.navy, size: 18),
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
    ).animate(delay: 350.ms).fadeIn(duration: 600.ms).slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic);
  }
}
// ═══════════════════════════════════════════════════════════
// Social proof — overlapping avatar circles + join text
// ═══════════════════════════════════════════════════════════
class _SocialProofRow extends StatelessWidget {
  const _SocialProofRow();

  static const _avatarDefs = [
    {'initials': 'JR', 'color': 0xFF2E86AB},
    {'initials': 'MA', 'color': 0xFF136F63},
    {'initials': 'KD', 'color': 0xFF8B1A1A},
    {'initials': 'PL', 'color': 0xFF5C5470},
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 28.0 + (_avatarDefs.length - 1) * 24.0,
          height: 36,
          child: Stack(
            children: _avatarDefs.asMap().entries.map((e) {
              return Positioned(
                left: e.key * 24.0,
                child: _AvatarCircle(
                  initials: e.value['initials'] as String,
                  color: Color(e.value['color'] as int),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 12),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.white70,
            ),
            children: [
              TextSpan(text: 'Join '),
              TextSpan(
                text: '120+',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.golden,
                ),
              ),
              TextSpan(text: ' innovators already on HIRAYA'),
            ],
          ),
        ),
      ],
    )
        .animate(delay: 220.ms)
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.10, end: 0, curve: Curves.easeOutCubic);
  }
}

class _AvatarCircle extends StatelessWidget {
  final String initials;
  final Color color;
  const _AvatarCircle({required this.initials, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.25), width: 2),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CTA floating particle painter
// ═══════════════════════════════════════════════════════════
class _CtaParticlePainter extends CustomPainter {
  final double t;

  static final _rng = math.Random(99);
  static final List<_CtaParticleDef> _defs = List.generate(18, (i) {
    return _CtaParticleDef(
      x: _rng.nextDouble(),
      y: _rng.nextDouble(),
      r: 1.0 + _rng.nextDouble() * 2.0,
      speed: 0.12 + _rng.nextDouble() * 0.18,
      phase: _rng.nextDouble() * math.pi * 2,
      drift: (_rng.nextDouble() - 0.5) * 0.05,
      opacity: 0.05 + _rng.nextDouble() * 0.12,
    );
  });

  const _CtaParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _defs) {
      final cy = ((p.y - t * p.speed + 1.0) % 1.0) * size.height;
      final cx =
          (p.x + math.sin(t * math.pi * 2 + p.phase) * p.drift) * size.width;
      canvas.drawCircle(
        Offset(cx, cy),
        p.r,
        Paint()
          ..color = Colors.white.withValues(alpha: p.opacity)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_CtaParticlePainter old) => old.t != t;
}

class _CtaParticleDef {
  final double x, y, r, speed, phase, drift, opacity;
  const _CtaParticleDef({
    required this.x,
    required this.y,
    required this.r,
    required this.speed,
    required this.phase,
    required this.drift,
    required this.opacity,
  });
}
