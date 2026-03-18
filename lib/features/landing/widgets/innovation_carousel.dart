import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/constants/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// InnovationCarousel — Featured innovations (Enhanced v2)
// ═══════════════════════════════════════════════════════════
class InnovationCarousel extends StatefulWidget {
  const InnovationCarousel({super.key});

  @override
  State<InnovationCarousel> createState() => _InnovationCarouselState();
}

class _InnovationCarouselState extends State<InnovationCarousel>
    with TickerProviderStateMixin {
  final PageController _pageController =
      PageController(viewportFraction: 0.82);
  int _currentPage = 0;
  Timer? _timer;
  bool _isPaused = false;

  // Orb animation for header
  late AnimationController _orbCtrl;
  late Animation<double> _orbAnim;

  static const List<Map<String, dynamic>> _slides = [
    {
      'title': 'Smart Rice Monitoring System',
      'category': 'Agriculture',
      'color': AppColors.teal,
      'innovator': 'Brgy. Maridagao, Cotabato',
      'tag': 'Award-winning Innovation',
      'icon': Icons.grass_rounded,
      'desc':
          'IoT-powered sensors that track soil moisture, temperature, and crop health in real-time — helping farmers maximize yield sustainably.',
    },
    {
      'title': 'Solar-Powered Water Purifier',
      'category': 'Energy',
      'color': AppColors.golden,
      'innovator': 'MSU-IIT, Iligan',
      'tag': 'Community Impact',
      'icon': Icons.wb_sunny_rounded,
      'desc':
          'A portable solar desalination unit providing clean drinking water to off-grid coastal communities across Mindanao.',
    },
    {
      'title': 'AI-Assisted Diagnostic Tablet',
      'category': 'Healthcare',
      'color': AppColors.crimson,
      'innovator': 'CMU College of Medicine',
      'tag': 'Breakthrough Technology',
      'icon': Icons.medical_services_rounded,
      'desc':
          'Machine learning-powered medical tablet enabling rural health workers to pre-screen patients for common diseases without a specialist.',
    },
    {
      'title': 'Bamboo-Composite Structural Panel',
      'category': 'Construction',
      'color': AppColors.sky,
      'innovator': 'Bukidnon State University',
      'tag': 'Sustainable Materials',
      'icon': Icons.foundation_rounded,
      'desc':
          'High-strength bamboo composite panels offering earthquake-resilient, eco-friendly alternatives to conventional building materials.',
    },
  ];

  @override
  void initState() {
    super.initState();

    _orbCtrl = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
    _orbAnim = CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut);

    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_isPaused || !mounted) return;
      final next = (_currentPage + 1) % _slides.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _goTo(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  void _prev() {
    final prev = (_currentPage - 1 + _slides.length) % _slides.length;
    _goTo(prev);
  }

  void _next() {
    final next = (_currentPage + 1) % _slides.length;
    _goTo(next);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.richNavy, AppColors.deepVoid],
        ),
      ),
      child: Column(
        children: [
          // ── Hero section header ────────────────────────────
          _buildSectionHeader(context),

          const SizedBox(height: 52),

          // ── Carousel with pause on hover ──────────────────
          MouseRegion(
            onEnter: (_) => setState(() => _isPaused = true),
            onExit: (_) => setState(() => _isPaused = false),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Page view
                SizedBox(
                  height: isDesktop ? 320 : 280,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      final isActive = index == _currentPage;
                      return AnimatedScale(
                        scale: isActive ? 1.0 : 0.93,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        child: AnimatedOpacity(
                          opacity: isActive ? 1.0 : 0.60,
                          duration: const Duration(milliseconds: 300),
                          child: _CarouselSlide(
                            slide: slide,
                            isActive: isActive,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Left arrow
                if (isDesktop)
                  Positioned(
                    left: 8,
                    child: _NavArrow(
                      icon: Icons.chevron_left_rounded,
                      onTap: _prev,
                    ),
                  ),

                // Right arrow
                if (isDesktop)
                  Positioned(
                    right: 8,
                    child: _NavArrow(
                      icon: Icons.chevron_right_rounded,
                      onTap: _next,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Navigation dots + arrows (mobile) ─────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!isDesktop) ...[
                _NavArrow(icon: Icons.chevron_left_rounded, onTap: _prev, small: true),
                const SizedBox(width: 16),
              ],
              AnimatedSmoothIndicator(
                activeIndex: _currentPage,
                count: _slides.length,
                onDotClicked: _goTo,
                effect: const ExpandingDotsEffect(
                  dotHeight: 6,
                  dotWidth: 6,
                  expansionFactor: 5,
                  activeDotColor: AppColors.golden,
                  dotColor: Colors.white24,
                  spacing: 6,
                ),
              ),
              if (!isDesktop) ...[
                const SizedBox(width: 16),
                _NavArrow(icon: Icons.chevron_right_rounded, onTap: _next, small: true),
              ],
            ],
          ),

          const SizedBox(height: 56),
        ],
      ),
    );
  }

  // ─── Section header ────────────────────────────────────────
  Widget _buildSectionHeader(BuildContext context) {
    return AnimatedBuilder(
      animation: _orbAnim,
      builder: (_, child) {
        final t = _orbAnim.value;
        return Container(
          padding: const EdgeInsets.only(top: 80, bottom: 0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Subtle golden orb behind header
              Positioned(
                right: MediaQuery.of(context).size.width * 0.1 + t * 10,
                top: -20 + t * 10,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.golden.withValues(alpha: 0.06),
                        blurRadius: 120,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            // Eyebrow
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.golden.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.golden.withValues(alpha: 0.30),
                ),
              ),
              child: const Text(
                'FEATURED',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.golden,
                  letterSpacing: 2,
                ),
              ),
            ).animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 16),

            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.white, AppColors.golden],
                stops: [0.5, 1.0],
              ).createShader(bounds),
              child: const Text(
                'Featured Innovations',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.8,
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 100.ms)
                .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

            const SizedBox(height: 12),

            Text(
              'Discover groundbreaking solutions from Filipino innovators',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.50),
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

            const SizedBox(height: 6),

            // Gradient separator line
            Container(
              width: 80,
              height: 2,
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.teal, AppColors.golden],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 300.ms).scaleX(begin: 0, end: 1),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Navigation arrow button
// ═══════════════════════════════════════════════════════════
class _NavArrow extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool small;

  const _NavArrow({
    required this.icon,
    required this.onTap,
    this.small = false,
  });

  @override
  State<_NavArrow> createState() => _NavArrowState();
}

class _NavArrowState extends State<_NavArrow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final size = widget.small ? 36.0 : 44.0;
    final iconSize = widget.small ? 18.0 : 22.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.golden.withValues(alpha: 0.18)
                : AppColors.darkSurface.withValues(alpha: 0.80),
            shape: BoxShape.circle,
            border: Border.all(
              color: _hovered
                  ? AppColors.golden.withValues(alpha: 0.50)
                  : AppColors.borderDark,
              width: 1.5,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.golden.withValues(alpha: 0.20),
                      blurRadius: 16,
                    ),
                  ]
                : [],
          ),
          child: Icon(
            widget.icon,
            color: _hovered ? AppColors.golden : Colors.white54,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Carousel slide — cinematic with gradient overlay
// ═══════════════════════════════════════════════════════════
class _CarouselSlide extends StatelessWidget {
  final Map<String, dynamic> slide;
  final bool isActive;

  const _CarouselSlide({required this.slide, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = slide['color'] as Color;
    final icon = slide['icon'] as IconData;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF080F1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withValues(alpha: isActive ? 0.50 : 0.12),
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.28),
                  blurRadius: 48,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.40),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.40),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Stack(
        children: [
          // ── Image placeholder with gradient overlay ────────
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Simulated image bg (gradient pattern as placeholder)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          color.withValues(alpha: 0.12),
                          AppColors.deepVoid.withValues(alpha: 0.80),
                          color.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                  // Large translucent icon as image stand-in
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(
                      icon,
                      size: 180,
                      color: color.withValues(alpha: 0.06),
                    ),
                  ),
                  // Cinematic dark gradient overlay (bottom fade)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF080F1A).withValues(alpha: 0.60),
                            const Color(0xFF080F1A).withValues(alpha: 0.95),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Category color strip at top ────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.20)],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
            ),
          ),

          // ── Background glow orb ────────────────────────────
          Positioned(
            right: -40,
            bottom: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isActive ? 0.18 : 0.06),
                    blurRadius: 120,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tag pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: color.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Text(
                    slide['tag'] as String,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                // Bottom text block
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (slide['category'] as String).toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      slide['title'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 8),
                    // Description — visible on active slide
                    AnimatedOpacity(
                      opacity: isActive ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        slide['desc'] as String,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.50),
                          fontSize: 12,
                          fontFamily: 'Poppins',
                          height: 1.55,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: Colors.white.withValues(alpha: 0.30),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            slide['innovator'] as String,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.40),
                              fontSize: 12,
                              fontFamily: 'Poppins',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
