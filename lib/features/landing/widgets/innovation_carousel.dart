import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/constants/app_colors.dart';

class InnovationCarousel extends StatefulWidget {
  const InnovationCarousel({super.key});

  @override
  State<InnovationCarousel> createState() => _InnovationCarouselState();
}

class _InnovationCarouselState extends State<InnovationCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;
  Timer? _timer;

  // Placeholder slides — will be replaced with real product/innovation photos
  static const List<Map<String, dynamic>> _slides = [
    {
      'title': 'Smart Rice Monitoring System',
      'category': 'Agriculture',
      'color': AppColors.teal,
      'innovator': 'Brgy. Maridagao, Cotabato',
      'tag': 'Award-winning Innovation',
    },
    {
      'title': 'Solar-Powered Water Purifier',
      'category': 'Energy',
      'color': AppColors.golden,
      'innovator': 'MSU-IIT, Iligan',
      'tag': 'Community Impact',
    },
    {
      'title': 'AI-Assisted Diagnostic Tablet',
      'category': 'Healthcare',
      'color': AppColors.crimson,
      'innovator': 'CMU College of Medicine',
      'tag': 'Breakthrough Technology',
    },
    {
      'title': 'Bamboo-Composite Structural Panel',
      'category': 'Construction',
      'color': AppColors.navy,
      'innovator': 'Bukidnon State University',
      'tag': 'Sustainable Materials',
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_currentPage < _slides.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navy,
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          // Header
          const Column(
            children: [
              Text(
                'Featured Innovations',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Discover groundbreaking solutions from Filipino innovators',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  color: Colors.white54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 600.ms),

          const SizedBox(height: 48),

          // Carousel
          SizedBox(
            height: 280,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemCount: _slides.length,
              itemBuilder: (context, index) {
                final slide = _slides[index];
                final isActive = index == _currentPage;
                return AnimatedScale(
                  scale: isActive ? 1.0 : 0.92,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  child: _CarouselSlide(slide: slide, isActive: isActive),
                );
              },
            ),
          ),

          const SizedBox(height: 28),

          // Page Indicator
          AnimatedSmoothIndicator(
            activeIndex: _currentPage,
            count: _slides.length,
            effect: const ExpandingDotsEffect(
              dotHeight: 8,
              dotWidth: 8,
              expansionFactor: 4,
              activeDotColor: AppColors.golden,
              dotColor: Colors.white24,
              spacing: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _CarouselSlide extends StatelessWidget {
  final Map<String, dynamic> slide;
  final bool isActive;

  const _CarouselSlide({required this.slide, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = slide['color'] as Color;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: isActive
            ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 32, offset: const Offset(0, 12))]
            : [],
      ),
      child: Stack(
        children: [
          // Background pattern
          const Positioned(
            right: -30,
            bottom: -30,
            child: Opacity(
              opacity: 0.1,
              child: Icon(Icons.hexagon_rounded, size: 200, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    slide['tag'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
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
                      slide['category'],
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      slide['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: Colors.white60, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          slide['innovator'],
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                            fontFamily: 'Poppins',
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