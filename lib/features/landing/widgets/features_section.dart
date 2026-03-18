import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// FeaturesSection — "Why HIRAYA?" About section (Enhanced v2)
// ═══════════════════════════════════════════════════════════
class FeaturesSection extends StatefulWidget {
  const FeaturesSection({super.key});

  @override
  State<FeaturesSection> createState() => _FeaturesSectionState();
}

class _FeaturesSectionState extends State<FeaturesSection>
    with TickerProviderStateMixin {
  late AnimationController _orbCtrl;
  late Animation<double> _orbAnim;

  static const _features = [
    _FeatureData(
      icon: Icons.verified_user_rounded,
      title: 'Verified Innovators',
      desc:
          'KYC-verified profiles you can trust. Every innovator is identity-confirmed before listing on HIRAYA.',
      color: AppColors.teal,
    ),
    _FeatureData(
      icon: Icons.message_rounded,
      title: 'Direct Messaging',
      desc:
          'Connect privately with innovators. No shared contacts — safe and fully in-platform communication.',
      color: AppColors.sky,
    ),
    _FeatureData(
      icon: Icons.trending_up_rounded,
      title: 'Smart Discovery',
      desc:
          'Trending products, advanced filters, and category-based discovery tools built in from the ground up.',
      color: AppColors.crimson,
    ),
    _FeatureData(
      icon: Icons.shield_rounded,
      title: 'RA 10173 Compliant',
      desc:
          'Your data is protected under the Philippine Data Privacy Act — always secure, always compliant.',
      color: AppColors.sky,
    ),
    _FeatureData(
      icon: Icons.school_rounded,
      title: 'University Partnerships',
      desc:
          'Backed by 15+ partner universities across the Philippines, bridging academia and industry.',
      color: AppColors.golden,
    ),
    _FeatureData(
      icon: Icons.bar_chart_rounded,
      title: 'Real-time Analytics',
      desc:
          'Track views, inquiries, and engagement on your innovations with live performance dashboards.',
      color: AppColors.warmEmber,
    ),
    _FeatureData(
      icon: Icons.gavel_rounded,
      title: 'IP Protection Support',
      desc:
          'Guidance on intellectual property rights, patents, and legal frameworks for Filipino innovators.',
      color: AppColors.teal,
    ),
    _FeatureData(
      icon: Icons.hub_rounded,
      title: 'Multi-sector Network',
      desc:
          'Six thriving industry sectors connecting agriculture, healthcare, energy, IT, and more.',
      color: AppColors.sky,
    ),
  ];

  static const _stats = [
    _StatData(value: '500+', label: 'Innovations Listed', color: AppColors.golden),
    _StatData(value: '120+', label: 'Verified Innovators', color: AppColors.teal),
    _StatData(value: '15', label: 'University Partners', color: AppColors.sky),
    _StatData(value: '6', label: 'Industry Sectors', color: AppColors.crimson),
  ];

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      duration: const Duration(seconds: 7),
      vsync: this,
    )..repeat(reverse: true);
    _orbAnim = CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.midnight, AppColors.deepVoid],
        ),
      ),
      child: Column(
        children: [
          // ── Hero mini-banner ──────────────────────────────────
          _buildHeroBanner(context),

          // ── Feature cards grid ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
            child: Column(
              children: [
                LayoutBuilder(builder: (context, constraints) {
                  final crossCount = constraints.maxWidth > 900
                      ? 4
                      : constraints.maxWidth > 600
                          ? 2
                          : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: crossCount == 1 ? 2.0 : 0.82,
                    ),
                    itemCount: _features.length,
                    itemBuilder: (context, index) {
                      final f = _features[index];
                      return _FeatureCard(
                        data: f,
                        index: index,
                      );
                    },
                  );
                }),

                const SizedBox(height: 80),

                // ── Stats strip ────────────────────────────────
                _buildStatsStrip(context),

                const SizedBox(height: 80),

                // ── Our Mission ────────────────────────────────
                _buildMissionBlock(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Hero mini-banner (300px) ──────────────────────────────
  Widget _buildHeroBanner(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _orbAnim,
      builder: (_, child) {
        final t = _orbAnim.value;
        return SizedBox(
          height: 300,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Gradient background
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF061A2E),
                        AppColors.richNavy,
                        Color(0xFF0A2240),
                      ],
                    ),
                  ),
                ),
              ),

              // Subtle grid
              Positioned.fill(
                child: Opacity(
                  opacity: 0.025,
                  child: CustomPaint(painter: _SmallGridPainter()),
                ),
              ),

              // Teal orb — top right
              Positioned(
                right: -60 + t * 20,
                top: -40 + t * 15,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.18),
                        blurRadius: 160,
                        spreadRadius: 30,
                      ),
                    ],
                  ),
                ),
              ),

              // Golden orb — bottom left
              Positioned(
                left: -40 + t * 12,
                bottom: -30 + t * 10,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.golden.withValues(alpha: 0.12),
                        blurRadius: 130,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // Sky orb — center
              Positioned(
                left: size.width * 0.45 + t * 8,
                top: 60 - t * 8,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sky.withValues(alpha: 0.08),
                        blurRadius: 100,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // Border bottom gradient line
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.golden.withValues(alpha: 0.40),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              child!,
            ],
          ),
        );
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Eyebrow pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.golden.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.golden.withValues(alpha: 0.35),
                  ),
                ),
                child: const Text(
                  'ABOUT HIRAYA',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.golden,
                    letterSpacing: 2,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 200.ms)
                  .slideY(begin: -0.2, end: 0),

              const SizedBox(height: 20),

              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, AppColors.golden],
                  stops: [0.0, 1.0],
                ).createShader(bounds),
                child: const Text(
                  'Why HIRAYA?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: -1,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 700.ms, delay: 350.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: 14),

              Text(
                'A platform designed from the ground up to elevate\nPhilippine innovation onto the global stage.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.60),
                  height: 1.6,
                  letterSpacing: 0.1,
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 550.ms),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Stats strip ───────────────────────────────────────────
  Widget _buildStatsStrip(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isDesktop = constraints.maxWidth > 700;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 32),
        decoration: BoxDecoration(
          color: AppColors.darkSurface.withValues(alpha: 0.80),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.borderDark,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.golden.withValues(alpha: 0.05),
              blurRadius: 40,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: isDesktop
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _stats
                    .asMap()
                    .entries
                    .map((e) => _buildStatItem(e.value, e.key, isDesktop))
                    .toList(),
              )
            : GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                mainAxisSpacing: 24,
                crossAxisSpacing: 16,
                children: _stats
                    .asMap()
                    .entries
                    .map((e) => _buildStatItem(e.value, e.key, isDesktop))
                    .toList(),
              ),
      )
          .animate()
          .fadeIn(duration: 600.ms)
          .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic);
    });
  }

  Widget _buildStatItem(_StatData stat, int index, bool isDesktop) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [stat.color, stat.color.withValues(alpha: 0.70)],
          ).createShader(bounds),
          child: Text(
            stat.value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          stat.label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.50),
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    )
        .animate(delay: Duration(milliseconds: 120 * index))
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.2, end: 0);
  }

  // ─── Our Mission block ─────────────────────────────────────
  Widget _buildMissionBlock(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.teal.withValues(alpha: 0.08),
            AppColors.richNavy.withValues(alpha: 0.60),
            AppColors.golden.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.teal.withValues(alpha: 0.20),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.golden.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.golden.withValues(alpha: 0.30),
              ),
            ),
            child: const Icon(
              Icons.flag_rounded,
              color: AppColors.golden,
              size: 26,
            ),
          ),

          const SizedBox(height: 20),

          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, AppColors.golden],
              stops: [0.4, 1.0],
            ).createShader(bounds),
            child: const Text(
              'Our Mission',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'HIRAYA exists to bridge the gap between brilliant Filipino minds and the market '
            'opportunities they deserve. We believe that innovation has no borders — '
            'that a rice farmer in Cotabato or a student-engineer in Iligan City can '
            'change the world with the right platform behind them. Our mission is to '
            'create that platform: transparent, secure, and built for the Filipino innovator.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.65),
              height: 1.75,
              letterSpacing: 0.1,
            ),
          ),

          const SizedBox(height: 28),

          // Decorative gradient separator
          Container(
            width: 120,
            height: 2,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.teal, AppColors.golden],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            '"Hiraya" — a Filipino word for the fruit of one\'s imagination and aspirations.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.golden.withValues(alpha: 0.70),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 700.ms)
        .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic);
  }
}

// ═══════════════════════════════════════════════════════════
// Data classes
// ═══════════════════════════════════════════════════════════
class _FeatureData {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;

  const _FeatureData({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
  });
}

class _StatData {
  final String value;
  final String label;
  final Color color;

  const _StatData({
    required this.value,
    required this.label,
    required this.color,
  });
}

// ═══════════════════════════════════════════════════════════
// Feature card with hover glow + "Learn More" arrow
// ═══════════════════════════════════════════════════════════
class _FeatureCard extends StatefulWidget {
  final _FeatureData data;
  final int index;

  const _FeatureCard({required this.data, required this.index});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovered = true);
        _scaleCtrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _scaleCtrl.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          transform:
              Matrix4.translationValues(0.0, _hovered ? -6.0 : 0.0, 0.0),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.data.color.withValues(alpha: 0.10)
                : AppColors.darkSurface.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered
                  ? widget.data.color.withValues(alpha: 0.45)
                  : AppColors.borderDark,
              width: 1.5,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.data.color.withValues(alpha: 0.22),
                      blurRadius: 32,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: widget.data.color.withValues(alpha: 0.08),
                      blurRadius: 60,
                      spreadRadius: 8,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.data.color
                      .withValues(alpha: _hovered ? 0.22 : 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.data.color
                        .withValues(alpha: _hovered ? 0.45 : 0.20),
                  ),
                ),
                child: Icon(widget.data.icon,
                    color: widget.data.color, size: 24),
              ),

              const SizedBox(height: 18),

              // Title
              Text(
                widget.data.title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _hovered ? widget.data.color : Colors.white,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(height: 8),

              // Description
              Expanded(
                child: Text(
                  widget.data.desc,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color:
                        Colors.white.withValues(alpha: _hovered ? 0.72 : 0.45),
                    height: 1.60,
                  ),
                ),
              ),

              // "Learn More" arrow — appears on hover
              AnimatedOpacity(
                opacity: _hovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: AnimatedSlide(
                  offset: _hovered ? Offset.zero : const Offset(0, 0.3),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: Row(
                    children: [
                      Text(
                        'Learn More',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: widget.data.color,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: widget.data.color,
                        size: 13,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
            .animate(delay: Duration(milliseconds: 80 * widget.index))
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.2, end: 0),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Small grid painter for hero banner
// ═══════════════════════════════════════════════════════════
class _SmallGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5;
    const spacing = 36.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_SmallGridPainter old) => false;
}
