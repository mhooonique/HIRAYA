// lib/features/landing/widgets/innovation_carousel.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// InnovationCarousel — Featured innovations (Enhanced v3)
// Full-width with side peek • Auto-scroll • Rich landscape cards
// Stats row • Trending badge • Hover overlay reveal
// ═══════════════════════════════════════════════════════════

class InnovationCarousel extends StatefulWidget {
  const InnovationCarousel({super.key});

  @override
  State<InnovationCarousel> createState() => _InnovationCarouselState();
}

class _InnovationCarouselState extends State<InnovationCarousel>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;
  Timer? _timer;
  bool _isPaused = false;

  late AnimationController _orbCtrl;
  late AnimationController _glowCtrl;

  static const List<Map<String, dynamic>> _slides = [
    {
      'title': 'Smart Rice Monitoring System',
      'category': 'Agriculture',
      'color': AppColors.teal,
      'innovator': 'Brgy. Maridagao, Cotabato',
      'tag': 'Award-Winning',
      'icon': Icons.grass_rounded,
      'desc': 'IoT-powered sensors track soil moisture, temperature, and crop health in real-time — helping farmers maximize yield sustainably.',
      'views': '1.2k',
      'likes': '248',
      'rating': 4.8,
    },
    {
      'title': 'Solar-Powered Water Purifier',
      'category': 'Energy',
      'color': AppColors.golden,
      'innovator': 'MSU-IIT, Iligan',
      'tag': 'Community Impact',
      'icon': Icons.wb_sunny_rounded,
      'desc': 'Portable solar desalination providing clean drinking water to off-grid coastal communities across Mindanao.',
      'views': '890',
      'likes': '312',
      'rating': 4.9,
    },
    {
      'title': 'AI-Assisted Diagnostic Tablet',
      'category': 'Healthcare',
      'color': AppColors.crimson,
      'innovator': 'CMU College of Medicine',
      'tag': 'Breakthrough Tech',
      'icon': Icons.medical_services_rounded,
      'desc': 'ML-powered tablet enabling rural health workers to pre-screen patients without a specialist — saving lives in remote areas.',
      'views': '2.1k',
      'likes': '475',
      'rating': 4.7,
    },
    {
      'title': 'Bamboo-Composite Structural Panel',
      'category': 'Construction',
      'color': AppColors.sky,
      'innovator': 'Bukidnon State University',
      'tag': 'Sustainable',
      'icon': Icons.foundation_rounded,
      'desc': 'High-strength bamboo composite panels — earthquake-resilient, eco-friendly alternatives to conventional building materials.',
      'views': '654',
      'likes': '189',
      'rating': 4.6,
    },
    {
      'title': 'Adaptive Learning Platform',
      'category': 'Information Technology',
      'color': Color(0xFF3A8FD5),
      'innovator': 'UP Diliman, QC',
      'tag': 'EdTech',
      'icon': Icons.computer_rounded,
      'desc': 'AI-driven personalized learning system that adapts to each student\'s pace and learning style for K-12 education.',
      'views': '3.4k',
      'likes': '621',
      'rating': 4.9,
    },
  ];

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      duration: const Duration(seconds: 7),
      vsync: this,
    )..repeat(reverse: true);

    _glowCtrl = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isPaused && mounted) {
        final next = (_currentPage + 1) % _slides.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _orbCtrl.dispose();
    _glowCtrl.dispose();
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
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.midnight, AppColors.richNavy, AppColors.midnight],
            ),
          ),
          child: Stack(
            children: [
              // Orbs
              Positioned(
                left: -100 + t * 50,
                top: 50 + t * 40,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.golden.withValues(alpha: 0.06),
                        blurRadius: 180,
                        spreadRadius: 50,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: -80 + t * 40,
                bottom: 30 + t * 35,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.06),
                        blurRadius: 150,
                        spreadRadius: 40,
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: isDesktop ? 80 : 56,
                ),
                child: Column(
                  children: [
                    // Section header
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 80 : 24,
                      ),
                      child: _buildHeader(isDesktop),
                    ),
                    SizedBox(height: isDesktop ? 48 : 32),

                    // Carousel
                    MouseRegion(
                      onEnter: (_) => setState(() => _isPaused = true),
                      onExit: (_) => setState(() => _isPaused = false),
                      child: SizedBox(
                        height: isDesktop ? 320 : 420,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _slides.length,
                          onPageChanged: (i) => setState(() => _currentPage = i),
                          itemBuilder: (_, i) {
                            final isActive = i == _currentPage;
                            return AnimatedScale(
                              scale: isActive ? 1.0 : 0.94,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                              child: _CarouselCard(
                                data: _slides[i],
                                isActive: isActive,
                                glowCtrl: _glowCtrl,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Dot indicators + nav arrows
                    _buildControls(isDesktop),

                    const SizedBox(height: 36),

                    // Stats row
                    _buildStatsRow(isDesktop),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Trending this week" sub-label
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.warmEmber,
                    ),
                  )
                      .animate()
                      .then(delay: 600.ms)
                      .fadeOut(duration: 500.ms)
                      .then()
                      .fadeIn(duration: 500.ms),
                  const SizedBox(width: 8),
                  Text(
                    'TRENDING THIS WEEK',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warmEmber.withValues(alpha: 0.90),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Featured Innovations',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isDesktop ? 40 : 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // NEW badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.golden, AppColors.warmEmber],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.golden.withValues(alpha: 0.40),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                        letterSpacing: 1,
                      ),
                    ),
                  )
                      .animate()
                      .then(delay: 1000.ms)
                      .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.4)),
                ],
              ),
            ],
          ),
        ),
        if (isDesktop) ...[
          // Navigation arrow buttons
          _NavButton(
            icon: Icons.arrow_back_ios_rounded,
            onTap: () {
              final prev = (_currentPage - 1 + _slides.length) % _slides.length;
              _pageController.animateToPage(
                prev,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOutCubic,
              );
            },
          ),
          const SizedBox(width: 10),
          _NavButton(
            icon: Icons.arrow_forward_ios_rounded,
            onTap: () {
              final next = (_currentPage + 1) % _slides.length;
              _pageController.animateToPage(
                next,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOutCubic,
              );
            },
          ),
        ],
      ],
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildControls(bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!isDesktop) ...[
          _NavButton(
            icon: Icons.arrow_back_ios_rounded,
            onTap: () {
              final prev = (_currentPage - 1 + _slides.length) % _slides.length;
              _pageController.animateToPage(
                prev,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOutCubic,
              );
            },
            small: true,
          ),
          const SizedBox(width: 16),
        ],
        // Dot indicators
        ...List.generate(_slides.length, (i) {
          final isActive = i == _currentPage;
          final color = _slides[i]['color'] as Color;
          return GestureDetector(
            onTap: () => _pageController.animateToPage(
              i,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isActive ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: isActive ? color : Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(4),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.50),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
            ),
          );
        }),
        if (!isDesktop) ...[
          const SizedBox(width: 16),
          _NavButton(
            icon: Icons.arrow_forward_ios_rounded,
            onTap: () {
              final next = (_currentPage + 1) % _slides.length;
              _pageController.animateToPage(
                next,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOutCubic,
              );
            },
            small: true,
          ),
        ],
      ],
    );
  }

  Widget _buildStatsRow(bool isDesktop) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isDesktop ? 80 : 24),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.darkSurface.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatPill(label: '500+ Innovations', icon: Icons.lightbulb_rounded, color: AppColors.golden),
          Container(width: 1, height: 24, color: AppColors.borderDark),
          _StatPill(label: '200+ Innovators', icon: Icons.people_rounded, color: AppColors.teal),
          Container(width: 1, height: 24, color: AppColors.borderDark),
          _StatPill(label: '50+ Categories', icon: Icons.category_rounded, color: AppColors.sky),
        ],
      ),
    )
        .animate(delay: 300.ms)
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.2, end: 0);
  }
}

// ── Navigation Button ─────────────────────────────────────────────────────
class _NavButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool small;

  const _NavButton({required this.icon, required this.onTap, this.small = false});

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final size = widget.small ? 36.0 : 44.0;
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
                ? AppColors.golden.withValues(alpha: 0.15)
                : AppColors.darkSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? AppColors.golden.withValues(alpha: 0.55)
                  : AppColors.borderDark,
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
          child: Center(
            child: Icon(
              widget.icon,
              size: widget.small ? 14 : 16,
              color: _hovered ? AppColors.golden : Colors.white.withValues(alpha: 0.50),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stat Pill ─────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatPill({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }
}

// ── Carousel Card ─────────────────────────────────────────────────────────
class _CarouselCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final bool isActive;
  final AnimationController glowCtrl;

  const _CarouselCard({
    required this.data,
    required this.isActive,
    required this.glowCtrl,
  });

  @override
  State<_CarouselCard> createState() => _CarouselCardState();
}

class _CarouselCardState extends State<_CarouselCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final color = d['color'] as Color;
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 900;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedBuilder(
        animation: widget.glowCtrl,
        builder: (_, __) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: widget.isActive
                    ? color.withValues(alpha: 0.55)
                    : AppColors.borderDark,
                width: widget.isActive ? 1.5 : 1,
              ),
              boxShadow: [
                if (widget.isActive)
                  BoxShadow(
                    color: color.withValues(
                      alpha: 0.15 * (0.6 + 0.4 * widget.glowCtrl.value),
                    ),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                    spreadRadius: 2,
                  ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.40),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: isDesktop
                  ? _buildDesktopCard(d, color)
                  : _buildMobileCard(d, color),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopCard(Map<String, dynamic> d, Color color) {
    return Row(
      children: [
        // Left: colored category panel (35%)
        Container(
          width: 240,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.25),
                AppColors.richNavy,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Large watermark icon
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  d['icon'] as IconData,
                  size: 140,
                  color: color.withValues(alpha: 0.12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withValues(alpha: 0.40)),
                      ),
                      child: Text(
                        d['category'] as String,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Main icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: color.withValues(alpha: 0.40)),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.30),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(d['icon'] as IconData, color: color, size: 30),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Innovator
                    Text(
                      d['innovator'] as String,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Right: content panel
        Expanded(
          child: _buildCardContent(d, color, isDesktop: true),
        ),
      ],
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> d, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top colored header
        Container(
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.25), AppColors.richNavy],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -10,
                bottom: -10,
                child: Icon(d['icon'] as IconData, size: 100, color: color.withValues(alpha: 0.12)),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: color.withValues(alpha: 0.40)),
                      ),
                      child: Center(child: Icon(d['icon'] as IconData, color: color, size: 24)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: color.withValues(alpha: 0.35)),
                          ),
                          child: Text(
                            d['category'] as String,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          d['innovator'] as String,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildCardContent(d, color, isDesktop: false)),
      ],
    );
  }

  Widget _buildCardContent(Map<String, dynamic> d, Color color, {required bool isDesktop}) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.golden.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.golden.withValues(alpha: 0.30)),
                ),
                child: Text(
                  d['tag'] as String,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.golden,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                d['title'] as String,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isDesktop ? 22 : 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // Description
              Text(
                d['desc'] as String,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.48),
                  height: 1.6,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),

              // Rating + stats row
              Row(
                children: [
                  // Stars
                  ...List.generate(5, (i) {
                    final rating = (d['rating'] as double);
                    return Icon(
                      i < rating.floor()
                          ? Icons.star_rounded
                          : (i < rating ? Icons.star_half_rounded : Icons.star_border_rounded),
                      size: 14,
                      color: i < rating ? AppColors.golden : Colors.white.withValues(alpha: 0.20),
                    );
                  }),
                  const SizedBox(width: 6),
                  Text(
                    '${d['rating']}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.golden,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Icon(Icons.remove_red_eye_rounded, size: 12, color: Colors.white.withValues(alpha: 0.35)),
                  const SizedBox(width: 4),
                  Text(
                    d['views'] as String,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.40),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.favorite_rounded, size: 12, color: AppColors.crimson.withValues(alpha: 0.70)),
                  const SizedBox(width: 4),
                  Text(
                    d['likes'] as String,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.40),
                    ),
                  ),
                  const Spacer(),
                  // View button
                  _ViewButton(color: color),
                ],
              ),
            ],
          ),
        ),

        // Hover overlay
        if (_hovered)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 200.ms),
      ],
    );
  }
}

// ── View Button ───────────────────────────────────────────────────────────
class _ViewButton extends StatefulWidget {
  final Color color;
  const _ViewButton({required this.color});

  @override
  State<_ViewButton> createState() => _ViewButtonState();
}

class _ViewButtonState extends State<_ViewButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go('/marketplace'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _hovered
                  ? [widget.color, widget.color.withValues(alpha: 0.75)]
                  : [widget.color.withValues(alpha: 0.14), widget.color.withValues(alpha: 0.08)],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered ? Colors.transparent : widget.color.withValues(alpha: 0.30),
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.30),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _hovered ? AppColors.navy : widget.color,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_rounded,
                size: 12,
                color: _hovered ? AppColors.navy : widget.color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
