// lib/features/landing/widgets/cta_section.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// CtaSection — Call-to-action (Enhanced v3)
// Diagonal gradient • Circuit lines bg • Stacked glass cards
// Animated word highlight • Live stats ticker
// ═══════════════════════════════════════════════════════════

class CtaSection extends StatefulWidget {
  const CtaSection({super.key});

  @override
  State<CtaSection> createState() => _CtaSectionState();
}

class _CtaSectionState extends State<CtaSection>
    with TickerProviderStateMixin {
  late AnimationController _orbCtrl;
  late AnimationController _highlightCtrl;
  late AnimationController _tickerCtrl;

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _highlightCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _tickerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _highlightCtrl.dispose();
    _tickerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 900;

    return AnimatedBuilder(
      animation: Listenable.merge([_orbCtrl, _highlightCtrl]),
      builder: (_, __) {
        final t = _orbCtrl.value;
        return Container(
          width: double.infinity,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.richNavy,
                const Color(0xFF071520),
                AppColors.deepVoid,
                const Color(0xFF04100F),
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Circuit lines background
              Positioned.fill(
                child: CustomPaint(
                  painter: _CircuitPainter(progress: _tickerCtrl.value),
                ),
              ),

              // Golden orb — top right
              Positioned(
                right: -80 + t * 40,
                top: -60 + t * 30,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.golden.withValues(alpha: 0.08),
                        blurRadius: 200,
                        spreadRadius: 60,
                      ),
                    ],
                  ),
                ),
              ),
              // Teal orb — bottom left
              Positioned(
                left: -60 + t * 30,
                bottom: -40 + t * 25,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.08),
                        blurRadius: 160,
                        spreadRadius: 40,
                      ),
                    ],
                  ),
                ),
              ),

              // Stats ticker strip at top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _StatsTicker(ctrl: _tickerCtrl),
              ),

              Padding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 80 : 24,
                  isDesktop ? 80 : 64,
                  isDesktop ? 80 : 24,
                  isDesktop ? 80 : 56,
                ),
                child: isDesktop
                    ? _buildDesktopLayout(t)
                    : _buildMobileLayout(t),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout(double t) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left: headline
        Expanded(
          flex: 5,
          child: _buildHeadline(true),
        ),
        const SizedBox(width: 60),
        // Right: CTA cards
        Expanded(
          flex: 4,
          child: _buildCtaCards(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(double t) {
    return Column(
      children: [
        _buildHeadline(false),
        const SizedBox(height: 40),
        _buildCtaCards(),
      ],
    );
  }

  Widget _buildHeadline(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.golden.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.golden.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.golden,
                ),
              )
                  .animate()
                  .then(delay: 500.ms)
                  .fadeOut(duration: 500.ms)
                  .then()
                  .fadeIn(duration: 500.ms),
              const SizedBox(width: 8),
              const Text(
                'JOIN THE MOVEMENT',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.golden,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.3, end: 0),
        const SizedBox(height: 24),

        // Main headline
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isDesktop ? 54 : 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
              letterSpacing: -2,
            ),
            children: [
              const TextSpan(text: 'Ready to\n'),
              WidgetSpan(
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      AppColors.golden,
                      AppColors.warmEmber,
                      AppColors.golden,
                    ],
                    stops: [
                      0.0,
                      _highlightCtrl.value,
                      1.0,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'Connect?',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isDesktop ? 54 : 36,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                      letterSpacing: -2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
            .animate(delay: 100.ms)
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.2, end: 0),

        const SizedBox(height: 20),
        Text(
          'Join thousands of Filipino innovators and clients already building the future together on Digital Platform.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: isDesktop ? 17 : 14,
            color: Colors.white.withValues(alpha: 0.50),
            height: 1.7,
          ),
        )
            .animate(delay: 200.ms)
            .fadeIn(duration: 500.ms),

        const SizedBox(height: 32),

        // Social proof row
        Row(
          children: [
            // Avatar stack
            SizedBox(
              width: 80,
              height: 32,
              child: Stack(
                children: [
                  for (int i = 0; i < 3; i++)
                    Positioned(
                      left: i * 20.0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              [AppColors.teal, AppColors.golden, AppColors.sky][i],
                              [AppColors.golden, AppColors.crimson, AppColors.teal][i],
                            ],
                          ),
                          border: Border.all(
                            color: AppColors.deepVoid,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '200+ innovators joined this month',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ],
        )
            .animate(delay: 300.ms)
            .fadeIn(duration: 500.ms),
      ],
    );
  }

  Widget _buildCtaCards() {
    return Column(
      children: [
        // Innovator card
        _CtaCard(
          icon: Icons.lightbulb_rounded,
          color: AppColors.teal,
          eyebrow: 'FOR INNOVATORS',
          title: 'List Your Innovation',
          subtitle: 'Share your research and reach clients across the Philippines',
          buttonLabel: 'Get Started Free',
          onTap: () {},
          index: 0,
        ),
        const SizedBox(height: 16),
        // Client card
        _CtaCard(
          icon: Icons.search_rounded,
          color: AppColors.golden,
          eyebrow: 'FOR CLIENTS',
          title: 'Discover Innovations',
          subtitle: 'Browse 500+ verified Filipino technologies ready to partner',
          buttonLabel: 'Browse Now',
          onTap: () {},
          index: 1,
        ),
      ],
    );
  }
}

// ── Stats Ticker Strip ────────────────────────────────────────────────────
class _StatsTicker extends StatelessWidget {
  final AnimationController ctrl;
  const _StatsTicker({required this.ctrl});

  static const _items = [
    '🏆  500+ Filipino Innovations Listed',
    '🎓  15+ Partner Universities',
    '🔬  200+ Verified Innovators',
    '📊  6 Innovation Categories',
    '🇵🇭  Proudly Made in the Philippines',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.golden.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(color: AppColors.golden.withValues(alpha: 0.15)),
        ),
      ),
      child: AnimatedBuilder(
        animation: ctrl,
        builder: (_, __) {
          final fullText = _items.join('    ·    ');
          return OverflowBox(
            maxWidth: double.infinity,
            child: Transform.translate(
              offset: Offset(-ctrl.value * 800, 0),
              child: Row(
                children: [
                  for (int i = 0; i < 4; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        fullText,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: AppColors.golden.withValues(alpha: 0.70),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Circuit Lines Painter ─────────────────────────────────────────────────
class _CircuitPainter extends CustomPainter {
  final double progress;
  const _CircuitPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.borderDark.withValues(alpha: 0.25)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = AppColors.golden.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;

    // Horizontal lines
    final yPositions = [size.height * 0.2, size.height * 0.5, size.height * 0.8];
    for (final y in yPositions) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      // Moving dot along line
      final dotX = (progress * size.width * 2) % (size.width + 100);
      if (dotX > 0 && dotX < size.width) {
        canvas.drawCircle(Offset(dotX, y), 3, dotPaint);
      }
    }

    // Vertical segments
    final xPositions = [size.width * 0.25, size.width * 0.5, size.width * 0.75];
    for (int i = 0; i < xPositions.length; i++) {
      final x = xPositions[i];
      final y1 = yPositions[i % yPositions.length];
      final y2 = yPositions[(i + 1) % yPositions.length];
      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
      // Corner dots
      canvas.drawCircle(Offset(x, y1), 3, dotPaint);
      canvas.drawCircle(Offset(x, y2), 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_CircuitPainter old) => old.progress != progress;
}

// ── CTA Card ──────────────────────────────────────────────────────────────
class _CtaCard extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String eyebrow;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;
  final int index;

  const _CtaCard({
    required this.icon,
    required this.color,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
    required this.index,
  });

  @override
  State<_CtaCard> createState() => _CtaCardState();
}

class _CtaCardState extends State<_CtaCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered
                ? widget.color.withValues(alpha: 0.55)
                : AppColors.borderDark,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.20)
                  : Colors.black.withValues(alpha: 0.30),
              blurRadius: _hovered ? 30 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Row(
              children: [
                // Icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: _hovered ? 0.20 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: widget.color.withValues(alpha: _hovered ? 0.50 : 0.25),
                    ),
                    boxShadow: _hovered
                        ? [
                            BoxShadow(
                              color: widget.color.withValues(alpha: 0.25),
                              blurRadius: 16,
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Icon(widget.icon, color: widget.color, size: 24),
                  ),
                ),
                const SizedBox(width: 16),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.eyebrow,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: widget.color,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.42),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Arrow button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _hovered
                          ? [widget.color, widget.color.withValues(alpha: 0.8)]
                          : [widget.color.withValues(alpha: 0.15), widget.color.withValues(alpha: 0.08)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _hovered
                          ? Colors.transparent
                          : widget.color.withValues(alpha: 0.30),
                    ),
                    boxShadow: _hovered
                        ? [
                            BoxShadow(
                              color: widget.color.withValues(alpha: 0.30),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: _hovered ? AppColors.navy : widget.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 300 + widget.index * 150))
        .fadeIn(duration: 600.ms)
        .slideX(begin: 0.15, end: 0, curve: Curves.easeOutCubic);
  }
}
