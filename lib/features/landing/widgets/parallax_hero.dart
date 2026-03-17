import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class ParallaxHero extends StatelessWidget {
  final double scrollOffset;
  const ParallaxHero({super.key, required this.scrollOffset});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final parallaxShift = scrollOffset * 0.4;

    return SizedBox(
      height: size.height,
      child: Stack(
        children: [
          // Background gradient + parallax shift
          Positioned(
            top: -parallaxShift,
            left: 0,
            right: 0,
            child: Container(
              height: size.height + 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.navy,
                    Color(0xFF064663),
                    AppColors.teal,
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // Decorative floating circles (parallax layers)
          Positioned(
            top: 80 - parallaxShift * 0.2,
            right: -60,
            child: _FloatingCircle(
              size: 300,
              color: AppColors.teal.withOpacity(0.18),
            ),
          ),
          Positioned(
            top: 200 - parallaxShift * 0.1,
            left: -80,
            child: _FloatingCircle(
              size: 220,
              color: AppColors.sky.withOpacity(0.12),
            ),
          ),
          Positioned(
            bottom: 60 + parallaxShift * 0.15,
            right: 100,
            child: _FloatingCircle(
              size: 150,
              color: AppColors.golden.withOpacity(0.15),
            ),
          ),

          // Grid overlay texture
          Positioned.fill(
            child: Opacity(
              opacity: 0.04,
              child: CustomPaint(painter: _GridPainter()),
            ),
          ),

          // Content
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 80),

                // Logo
                Image.asset(
                  'assets/images/logo/final-logo.png',
                  height: 100,
                )
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 200.ms)
                    .slideY(begin: -0.3, end: 0, duration: 800.ms, delay: 200.ms),
                  

                const SizedBox(height: 24),

                // App Name
                const Text(
                  'DIGITAL PLATFORM',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 8,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 900.ms, delay: 400.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 16),

                // Tagline
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      left: BorderSide(color: AppColors.golden, width: 3),
                    ),
                  ),
                  child: const Text(
                    AppStrings.tagline,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.golden,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 600.ms)
                    .slideX(begin: -0.2, end: 0),

                const SizedBox(height: 20),

                // Sub tagline
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    AppStrings.subTagline,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      color: Colors.white70,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 800.ms),

                const SizedBox(height: 48),

                // CTA Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Builder(
                      builder: (ctx) => ElevatedButton.icon(
                        onPressed: () => ctx.go('/signup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.crimson,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 8,
                          shadowColor: AppColors.crimson.withOpacity(0.5),
                        ),
                        icon: const Icon(Icons.rocket_launch_rounded, color: Colors.white),
                        label: const Text(
                          'Get Started',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Builder(
                      builder: (ctx) => OutlinedButton.icon(
                        onPressed: () => ctx.go('/marketplace'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white54, width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.explore_rounded, color: Colors.white70),
                        label: const Text(
                          'Browse Innovations',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 1000.ms)
                    .slideY(begin: 0.3, end: 0),
              ],
            ),
          ),

          // Scroll indicator at bottom
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text(
                  'Scroll to explore',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white38, size: 28)
                    .animate(onPlay: (c) => c.repeat())
                    .moveY(begin: 0, end: 8, duration: 900.ms, curve: Curves.easeInOut)
                    .then()
                    .moveY(begin: 8, end: 0, duration: 900.ms),
              ],
            )
                .animate()
                .fadeIn(duration: 800.ms, delay: 1400.ms),
          ),
        ],
      ),
    );
  }
}

class _FloatingCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _FloatingCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

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