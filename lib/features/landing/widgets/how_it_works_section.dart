// lib/features/landing/widgets/how_it_works_section.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// HowItWorksSection — 3-step animated flow (New Section)
// Connected steps with animated travelling dot on dashed line
// ═══════════════════════════════════════════════════════════

class HowItWorksSection extends StatefulWidget {
  const HowItWorksSection({super.key});

  @override
  State<HowItWorksSection> createState() => _HowItWorksSectionState();
}

class _HowItWorksSectionState extends State<HowItWorksSection>
    with TickerProviderStateMixin {
  late AnimationController _dotCtrl;
  late Animation<double> _dotAnim;
  late AnimationController _orbCtrl;

  static const _steps = [
    _StepData(
      number: '01',
      icon: Icons.person_add_rounded,
      title: 'Create Your Account',
      description:
          'Sign up as an innovator or client in minutes. Verify your identity and unlock the full Digital Platform experience.',
      color: AppColors.golden,
      delay: 0,
    ),
    _StepData(
      number: '02',
      icon: Icons.explore_rounded,
      title: 'Explore Innovations',
      description:
          'Browse 500+ verified Filipino innovations by category. Filter by industry, status, or university partnership.',
      color: AppColors.teal,
      delay: 150,
    ),
    _StepData(
      number: '03',
      icon: Icons.handshake_rounded,
      title: 'Connect & Collaborate',
      description:
          'Message innovators directly on-platform. Build partnerships, license technologies, and drive Filipino innovation forward.',
      color: AppColors.sky,
      delay: 300,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _dotCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: false);
    _dotAnim = CurvedAnimation(parent: _dotCtrl, curve: Curves.easeInOut);

    _orbCtrl = AnimationController(
      duration: const Duration(seconds: 7),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _dotCtrl.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 900;

    return AnimatedBuilder(
      animation: _orbCtrl,
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
                AppColors.deepVoid,
                const Color(0xFF060D18),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background orb
              Positioned(
                left: -100 + t * 40,
                top: 40 + t * 60,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.06),
                        blurRadius: 180,
                        spreadRadius: 40,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: -80 + t * 30,
                bottom: 20 + t * 50,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.golden.withValues(alpha: 0.05),
                        blurRadius: 150,
                        spreadRadius: 30,
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 80 : 24,
                  vertical: isDesktop ? 80 : 56,
                ),
                child: Column(
                  children: [
                    // Section header
                    _buildHeader(isDesktop),
                    SizedBox(height: isDesktop ? 64 : 48),

                    // Steps
                    isDesktop
                        ? _buildDesktopSteps()
                        : _buildMobileSteps(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Column(
      children: [
        // Step indicator decoration
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.golden.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.golden.withValues(alpha: 0.30),
            ),
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
              ),
              const SizedBox(width: 8),
              const Text(
                'SIMPLE PROCESS',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.golden,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.2, end: 0),
        const SizedBox(height: 20),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFBBCCDD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'How It Works',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: isDesktop ? 42 : 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
              height: 1.1,
            ),
          ),
        )
            .animate(delay: 100.ms)
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.2, end: 0),
        const SizedBox(height: 14),
        Text(
          'Get started with Digital Platform in three simple steps',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: isDesktop ? 16 : 14,
            color: Colors.white.withValues(alpha: 0.50),
            height: 1.6,
          ),
        )
            .animate(delay: 200.ms)
            .fadeIn(duration: 500.ms),
      ],
    );
  }

  Widget _buildDesktopSteps() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _steps.length; i++) ...[
          Expanded(child: _StepCard(step: _steps[i], index: i)),
          if (i < _steps.length - 1)
            _ConnectorLine(dotAnim: _dotAnim),
        ],
      ],
    );
  }

  Widget _buildMobileSteps() {
    return Column(
      children: [
        for (int i = 0; i < _steps.length; i++) ...[
          _StepCard(step: _steps[i], index: i, vertical: true),
          if (i < _steps.length - 1)
            _VerticalConnector(dotAnim: _dotAnim),
        ],
      ],
    );
  }
}

// ── Connector Line (desktop) ──────────────────────────────────────────────
class _ConnectorLine extends StatelessWidget {
  final Animation<double> dotAnim;
  const _ConnectorLine({required this.dotAnim});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 120,
      child: AnimatedBuilder(
        animation: dotAnim,
        builder: (_, __) {
          return CustomPaint(
            painter: _DashLinePainter(progress: dotAnim.value),
          );
        },
      ),
    );
  }
}

// ── Vertical Connector (mobile) ───────────────────────────────────────────
class _VerticalConnector extends StatelessWidget {
  final Animation<double> dotAnim;
  const _VerticalConnector({required this.dotAnim});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: AnimatedBuilder(
        animation: dotAnim,
        builder: (_, __) {
          return CustomPaint(
            painter: _VerticalDashPainter(progress: dotAnim.value),
          );
        },
      ),
    );
  }
}

// ── Dash Line Painter (horizontal) ───────────────────────────────────────
class _DashLinePainter extends CustomPainter {
  final double progress;
  const _DashLinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final paint = Paint()
      ..color = AppColors.borderDark
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Dashed line
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, cy), Offset(math.min(x + 8, size.width), cy), paint);
      x += 14;
    }

    // Travelling golden dot
    final dotX = progress * size.width;
    final dotPaint = Paint()
      ..color = AppColors.golden
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(dotX, cy), 4, dotPaint);

    // Glow
    final glowPaint = Paint()
      ..color = AppColors.golden.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(dotX, cy), 6, glowPaint);
  }

  @override
  bool shouldRepaint(_DashLinePainter old) => old.progress != progress;
}

// ── Vertical Dash Painter (mobile) ───────────────────────────────────────
class _VerticalDashPainter extends CustomPainter {
  final double progress;
  const _VerticalDashPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final paint = Paint()
      ..color = AppColors.borderDark
      ..strokeWidth = 1.5;

    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(cx, y), Offset(cx, math.min(y + 6, size.height)), paint);
      y += 12;
    }

    final dotY = progress * size.height;
    final dotPaint = Paint()
      ..color = AppColors.golden
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, dotY), 4, dotPaint);

    final glowPaint = Paint()
      ..color = AppColors.golden.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(cx, dotY), 6, glowPaint);
  }

  @override
  bool shouldRepaint(_VerticalDashPainter old) => old.progress != progress;
}

// ── Step Data ──────────────────────────────────────────────────────────────
class _StepData {
  final String number;
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final int delay;

  const _StepData({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.delay,
  });
}

// ── Step Card ─────────────────────────────────────────────────────────────
class _StepCard extends StatefulWidget {
  final _StepData step;
  final int index;
  final bool vertical;

  const _StepCard({
    required this.step,
    required this.index,
    this.vertical = false,
  });

  @override
  State<_StepCard> createState() => _StepCardState();
}

class _StepCardState extends State<_StepCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.step;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -8 : 0, 0),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered
                  ? s.color.withValues(alpha: 0.50)
                  : AppColors.borderDark,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? s.color.withValues(alpha: 0.20)
                    : Colors.black.withValues(alpha: 0.30),
                blurRadius: _hovered ? 32 : 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: widget.vertical
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              // Number + icon row
              Row(
                mainAxisAlignment: widget.vertical
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  // Animated icon container
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: s.color.withValues(alpha: _hovered ? 0.20 : 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: s.color.withValues(alpha: _hovered ? 0.50 : 0.25),
                      ),
                      boxShadow: _hovered
                          ? [
                              BoxShadow(
                                color: s.color.withValues(alpha: 0.25),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Icon(s.icon, color: s.color, size: 26),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Step number
                  Text(
                    s.number,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: s.color.withValues(alpha: 0.15),
                      letterSpacing: -2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                s.title,
                textAlign: widget.vertical ? TextAlign.center : TextAlign.start,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              // Description
              Text(
                s.description,
                textAlign: widget.vertical ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.50),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              // Bottom accent line
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 2,
                width: _hovered ? double.infinity : 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [s.color, s.color.withValues(alpha: 0)],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: s.delay))
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic);
  }
}
