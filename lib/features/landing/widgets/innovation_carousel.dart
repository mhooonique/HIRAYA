import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/constants/app_colors.dart';

class InnovationCarousel extends StatefulWidget {
  const InnovationCarousel({super.key});

  @override
  State<InnovationCarousel> createState() => _InnovationCarouselState();
}

class _InnovationCarouselState extends State<InnovationCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.82);
  final FocusNode _focusNode = FocusNode();
  int _currentPage = 0;
  Timer? _timer;
  double _progress = 0.0;
  bool _isPaused = false;
  static const int _intervalMs = 4000;
  static const int _tickMs = 60;

  static const List<Map<String, dynamic>> _slides = [
    {
      'title': 'Smart Rice Monitoring System',
      'category': 'Agriculture',
      'color': AppColors.teal,
      'innovator': 'Brgy. Maridagao, Cotabato',
      'tag': 'Award-winning Innovation',
      'icon': Icons.grass_rounded,
    },
    {
      'title': 'Solar-Powered Water Purifier',
      'category': 'Energy',
      'color': AppColors.golden,
      'innovator': 'MSU-IIT, Iligan',
      'tag': 'Community Impact',
      'icon': Icons.wb_sunny_rounded,
    },
    {
      'title': 'AI-Assisted Diagnostic Tablet',
      'category': 'Healthcare',
      'color': AppColors.crimson,
      'innovator': 'CMU College of Medicine',
      'tag': 'Breakthrough Technology',
      'icon': Icons.medical_services_rounded,
    },
    {
      'title': 'Bamboo-Composite Structural Panel',
      'category': 'Construction',
      'color': Color(0xFF1A5276),
      'innovator': 'Bukidnon State University',
      'tag': 'Sustainable Materials',
      'icon': Icons.foundation_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _progress = 0.0;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: _tickMs), (_) {
      if (!mounted) return;
      if (_isPaused) return; // paused on hover
      setState(() {
        _progress += _tickMs / _intervalMs;
        if (_progress >= 1.0) {
          _progress = 0.0;
          _currentPage = (_currentPage + 1) % _slides.length;
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    });
  }

  void _goToPage(int page) {
    setState(() {
      _currentPage = page;
      _progress = 0.0;
    });
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: false,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _goToPage(
                (_currentPage - 1 + _slides.length) % _slides.length);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _goToPage((_currentPage + 1) % _slides.length);
          }
        }
      },
      child: MouseRegion(
        onEnter: (_) {
          _focusNode.requestFocus();
          setState(() => _isPaused = true);
        },
        onExit: (_) => setState(() => _isPaused = false),
        child: Container(
      color: const Color(0xFF021825),
      padding: const EdgeInsets.symmetric(vertical: 88),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.golden.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.golden.withValues(alpha: 0.30)),
                  ),
                  child: const Text(
                    'FEATURED',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.golden,
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Featured Innovations',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Groundbreaking solutions from Filipino minds',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14.5,
                    color: Colors.white38,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ).animate().fadeIn(duration: 600.ms),
          ),

          const SizedBox(height: 48),

          // Carousel
          SizedBox(
            height: 300,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) {
                setState(() {
                  _currentPage = i;
                  _progress = 0.0;
                });
                _startTimer();
              },
              itemCount: _slides.length,
              itemBuilder: (context, index) {
                final slide = _slides[index];
                final isActive = index == _currentPage;
                return AnimatedScale(
                  scale: isActive ? 1.0 : 0.91,
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeOutCubic,
                  child: _CarouselSlide(
                    slide: slide,
                    isActive: isActive,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 28),

          // Bottom controls row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Prev arrow
                _NavArrow(
                  icon: Icons.chevron_left_rounded,
                  onTap: () => _goToPage(
                      (_currentPage - 1 + _slides.length) % _slides.length),
                ),
                const SizedBox(width: 20),

                // Animated smooth indicator
                AnimatedSmoothIndicator(
                  activeIndex: _currentPage,
                  count: _slides.length,
                  onDotClicked: _goToPage,
                  effect: const ExpandingDotsEffect(
                    dotHeight: 8,
                    dotWidth: 8,
                    expansionFactor: 4,
                    activeDotColor: AppColors.golden,
                    dotColor: Colors.white24,
                    spacing: 6,
                  ),
                ),

                const SizedBox(width: 20),

                // Next arrow
                _NavArrow(
                  icon: Icons.chevron_right_rounded,
                  onTap: () =>
                      _goToPage((_currentPage + 1) % _slides.length),
                ),

                const Spacer(),

                // Slide counter
                Text(
                  '${(_currentPage + 1).toString().padLeft(2, '0')} / ${_slides.length.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white30,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Stack(
                children: [
                  Container(
                      height: 3,
                      color: Colors.white.withValues(alpha: 0.08)),
                  FractionallySizedBox(
                    widthFactor: _progress,
                    child: Container(
                      height: 3,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                            colors: [AppColors.teal, AppColors.golden]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
        ), // MouseRegion child
      ), // MouseRegion
    ); // KeyboardListener
  }
}

class _NavArrow extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavArrow({required this.icon, required this.onTap});

  @override
  State<_NavArrow> createState() => _NavArrowState();
}

class _NavArrowState extends State<_NavArrow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hovered
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.07),
            border: Border.all(
              color: _hovered
                  ? Colors.white.withValues(alpha: 0.40)
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Icon(
            widget.icon,
            color: _hovered ? Colors.white : Colors.white38,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _CarouselSlide extends StatefulWidget {
  final Map<String, dynamic> slide;
  final bool isActive;

  const _CarouselSlide({required this.slide, required this.isActive});

  @override
  State<_CarouselSlide> createState() => _CarouselSlideState();
}

class _CarouselSlideState extends State<_CarouselSlide> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.slide['color'] as Color;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color,
              Color.lerp(color, Colors.black, 0.30)!,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: widget.isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: _hovered ? 0.55 : 0.38),
                    blurRadius: _hovered ? 44 : 30,
                    offset: const Offset(0, 12),
                  )
                ]
              : [],
        ),
        child: Stack(
          children: [
            // Large translucent icon watermark
            Positioned(
              right: -24,
              bottom: -24,
              child: Opacity(
                opacity: 0.10,
                child: Icon(widget.slide['icon'] as IconData,
                    size: 180, color: Colors.white),
              ),
            ),
            // Active indicator dot
            if (widget.isActive)
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                    begin: const Offset(0.7, 0.7),
                    end: const Offset(1.3, 1.3),
                    duration: 1000.ms),
              ),
            Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tag pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28)),
                    ),
                    child: Text(
                      widget.slide['tag'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (widget.slide['category'] as String).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.slide['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: Colors.white54, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            widget.slide['innovator'] as String,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12.5,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
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
      ),
    );
  }
}