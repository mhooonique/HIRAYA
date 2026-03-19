// lib/features/landing/widgets/features_section.dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// FeaturesSection — "Why Digital Platform?" (Enhanced v3)
// Bento grid layout • Animated counters • Geometric mesh bg
// 3D hover tilt • Animated golden underline header
// ═══════════════════════════════════════════════════════════

class FeaturesSection extends StatefulWidget {
  const FeaturesSection({super.key});

  @override
  State<FeaturesSection> createState() => _FeaturesSectionState();
}

class _FeaturesSectionState extends State<FeaturesSection>
    with TickerProviderStateMixin {
  late AnimationController _orbCtrl;
  late AnimationController _counterCtrl;
  late Animation<double> _counterAnim;
  bool _counterStarted = false;

  static const _features = [
    _FeatureData(
      icon: Icons.verified_user_rounded,
      title: 'Verified Innovators',
      desc: 'KYC-verified profiles you can trust. Every innovator is identity-confirmed before listing on Digital Platform.',
      color: AppColors.teal,
      metric: '100%',
      metricLabel: 'Verification Rate',
      isHero: false,
    ),
    _FeatureData(
      icon: Icons.message_rounded,
      title: 'Direct Messaging',
      desc: 'Connect privately with innovators. No shared contacts — safe and fully in-platform communication.',
      color: AppColors.sky,
      metric: '200+',
      metricLabel: 'Active Conversations',
      isHero: false,
    ),
    _FeatureData(
      icon: Icons.school_rounded,
      title: 'University Partnerships',
      desc: 'Backed by 15+ partner universities across the Philippines, bridging academia and industry.',
      color: AppColors.golden,
      metric: '15+',
      metricLabel: 'Partner Universities',
      isHero: true,
    ),
    _FeatureData(
      icon: Icons.trending_up_rounded,
      title: 'Smart Discovery',
      desc: 'Trending products, advanced filters, and category-based discovery tools built in from the ground up.',
      color: AppColors.crimson,
      metric: '500+',
      metricLabel: 'Listed Innovations',
      isHero: false,
    ),
    _FeatureData(
      icon: Icons.shield_rounded,
      title: 'RA 10173 Compliant',
      desc: 'Your data is protected under the Philippine Data Privacy Act — always secure, always compliant.',
      color: AppColors.sky,
      metric: '0',
      metricLabel: 'Data Breaches',
      isHero: false,
    ),
    _FeatureData(
      icon: Icons.bar_chart_rounded,
      title: 'Real-time Analytics',
      desc: 'Track views, inquiries, and engagement on your innovations with live performance dashboards.',
      color: AppColors.warmEmber,
      metric: '24/7',
      metricLabel: 'Live Monitoring',
      isHero: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    _counterCtrl = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _counterAnim = CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOutCubic);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && !_counterStarted) {
        _counterStarted = true;
        _counterCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _counterCtrl.dispose();
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
          decoration: const BoxDecoration(
            color: AppColors.deepVoid,
          ),
          child: Stack(
            children: [
              // Geometric mesh background
              Positioned.fill(
                child: CustomPaint(painter: _MeshPainter()),
              ),
              // Ambient orbs
              Positioned(
                left: -120 + t * 50,
                top: 100 + t * 80,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.06),
                        blurRadius: 200,
                        spreadRadius: 50,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: -100 + t * 40,
                bottom: 80 + t * 60,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.golden.withValues(alpha: 0.05),
                        blurRadius: 180,
                        spreadRadius: 40,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isDesktop),
                    SizedBox(height: isDesktop ? 56 : 40),
                    isDesktop
                        ? _buildDesktopBento()
                        : _buildMobileList(),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Decorative large quote mark
        Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -10,
              top: -20,
              child: Text(
                '"',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isDesktop ? 140 : 100,
                  fontWeight: FontWeight.w900,
                  color: AppColors.golden.withValues(alpha: 0.06),
                  height: 1,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppColors.golden, AppColors.warmEmber],
                  ).createShader(bounds),
                  child: Text(
                    'WHY DIGITAL PLATFORM?',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isDesktop ? 11 : 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Built for\nFilipino Innovation',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: isDesktop ? 46 : 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: -1.5,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.2, end: 0),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Text(
                    'A platform designed from the ground up to connect Filipino innovators with the clients and investors who need them most.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isDesktop ? 16 : 14,
                      color: Colors.white.withValues(alpha: 0.45),
                      height: 1.7,
                    ),
                  ),
                )
                    .animate(delay: 150.ms)
                    .fadeIn(duration: 500.ms),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopBento() {
    // Hero card spans 2 rows on the right, 4 regular cards on the left in 2x2
    final heroFeature = _features.firstWhere((f) => f.isHero);
    final regularFeatures = _features.where((f) => !f.isHero).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: 2x3 grid
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _FeatureCard(feature: regularFeatures[0], index: 0)),
                  const SizedBox(width: 16),
                  Expanded(child: _FeatureCard(feature: regularFeatures[1], index: 1)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _FeatureCard(feature: regularFeatures[2], index: 2)),
                  const SizedBox(width: 16),
                  Expanded(child: _FeatureCard(feature: regularFeatures[3], index: 3)),
                ],
              ),
              const SizedBox(height: 16),
              _FeatureCard(feature: regularFeatures[4], index: 4, wide: true),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Right: Hero card
        Expanded(
          flex: 2,
          child: _HeroFeatureCard(feature: heroFeature),
        ),
      ],
    );
  }

  Widget _buildMobileList() {
    return Column(
      children: List.generate(
        _features.length,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _FeatureCard(feature: _features[i], index: i, wide: true),
        ),
      ),
    );
  }
}

// ── Mesh Painter ──────────────────────────────────────────────────────────
class _MeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E2D3D).withValues(alpha: 0.25)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 60.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Dot grid
    final dotPaint = Paint()
      ..color = const Color(0xFF1E2D3D).withValues(alpha: 0.40)
      ..style = PaintingStyle.fill;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_MeshPainter old) => false;
}

// ── Feature Data ──────────────────────────────────────────────────────────
class _FeatureData {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  final String metric;
  final String metricLabel;
  final bool isHero;

  const _FeatureData({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
    required this.metric,
    required this.metricLabel,
    required this.isHero,
  });
}

// ── Hero Feature Card (large) ─────────────────────────────────────────────
class _HeroFeatureCard extends StatefulWidget {
  final _FeatureData feature;
  const _HeroFeatureCard({required this.feature});

  @override
  State<_HeroFeatureCard> createState() => _HeroFeatureCardState();
}

class _HeroFeatureCardState extends State<_HeroFeatureCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.feature;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedBuilder(
        animation: _glowCtrl,
        builder: (_, __) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            transform: Matrix4.translationValues(0, _hovered ? -6 : 0, 0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  f.color.withValues(alpha: 0.18),
                  AppColors.darkSurface,
                  AppColors.richNavy.withValues(alpha: 0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _hovered
                    ? f.color.withValues(alpha: 0.60)
                    : f.color.withValues(alpha: 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: f.color.withValues(
                    alpha: (_hovered ? 0.25 : 0.10) * (0.7 + 0.3 * _glowCtrl.value),
                  ),
                  blurRadius: _hovered ? 40 : 20,
                  spreadRadius: _hovered ? 4 : 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Large icon
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: f.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: f.color.withValues(alpha: 0.35),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: f.color.withValues(alpha: 0.25),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(f.icon, color: f.color, size: 32),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        f.title,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        f.desc,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.55),
                          height: 1.7,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: 32),
                      // Large metric
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: f.color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: f.color.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            ShaderMask(
                              shaderCallback: (b) => LinearGradient(
                                colors: [f.color, f.color.withValues(alpha: 0.7)],
                              ).createShader(b),
                              child: Text(
                                f.metric,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 42,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                f.metricLabel,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.55),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    )
        .animate(delay: 200.ms)
        .fadeIn(duration: 700.ms)
        .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }
}

// ── Regular Feature Card ──────────────────────────────────────────────────
class _FeatureCard extends StatefulWidget {
  final _FeatureData feature;
  final int index;
  final bool wide;

  const _FeatureCard({
    required this.feature,
    required this.index,
    this.wide = false,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final f = widget.feature;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        transform: Matrix4.translationValues(0, _hovered ? -5 : 0, 0),
        padding: EdgeInsets.all(widget.wide ? 24 : 20),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered
                ? f.color.withValues(alpha: 0.50)
                : AppColors.borderDark,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? f.color.withValues(alpha: 0.18)
                  : Colors.black.withValues(alpha: 0.25),
              blurRadius: _hovered ? 28 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: widget.wide
            ? Row(
                children: [
                  _iconBox(f),
                  const SizedBox(width: 20),
                  Expanded(child: _content(f, wide: true)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _iconBox(f),
                  const SizedBox(height: 16),
                  _content(f, wide: false),
                ],
              ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 80))
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _iconBox(_FeatureData f) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: f.color.withValues(alpha: _hovered ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: f.color.withValues(alpha: _hovered ? 0.50 : 0.25),
        ),
        boxShadow: _hovered
            ? [
                BoxShadow(
                  color: f.color.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Center(
        child: Icon(f.icon, color: f.color, size: 22),
      ),
    );
  }

  Widget _content(_FeatureData f, {required bool wide}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          f.title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          f.desc,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.45),
            height: 1.6,
          ),
          maxLines: wide ? 2 : 3,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        // Bottom accent
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: 2,
          width: _hovered ? 48 : 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [f.color, f.color.withValues(alpha: 0)],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}
