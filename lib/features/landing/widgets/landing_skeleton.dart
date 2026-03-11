// ignore_for_file: unused_element
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// LandingSkeleton — cinematic shimmer skeleton for the
// entire landing page. Each section is a separate widget
// that mirrors the real layout pixel-for-pixel.
// ═══════════════════════════════════════════════════════════
class LandingSkeleton extends StatelessWidget {
  const LandingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          _HeroSkeleton(height: size.height),
          const _CategoryGridSkeleton(),
          const _CarouselSkeleton(),
          const _FeaturesSkeleton(),
          const _CtaSkeleton(),
          const _FooterSkeleton(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Hero skeleton — dark background, navbar + centered content
// ─────────────────────────────────────────────────────────────
class _HeroSkeleton extends StatelessWidget {
  final double height;
  const _HeroSkeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      // Mirrors the hero dark gradient
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF032B43),
            Color(0xFF064663),
            Color(0xFF136F63),
          ],
        ),
      ),
      child: Stack(
        children: [
          // ── Navbar skeleton ──────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
                child: Row(
                  children: [
                    // Logo
                    _DSkel(w: 38, h: 38, r: 8, dark: true)
                        .animate().fadeIn(duration: 320.ms),
                    const SizedBox(width: 10),
                    // Brand name
                    _DSkel(w: 90, h: 22, r: 5, dark: true)
                        .animate(delay: 40.ms).fadeIn(duration: 320.ms),
                    const Spacer(),
                    // Nav links
                    if (MediaQuery.of(context).size.width > 768) ...[
                      _DSkel(w: 88, h: 16, r: 5, dark: true)
                          .animate(delay: 80.ms).fadeIn(duration: 320.ms),
                      const SizedBox(width: 28),
                      _DSkel(w: 56, h: 16, r: 5, dark: true)
                          .animate(delay: 100.ms).fadeIn(duration: 320.ms),
                      const SizedBox(width: 28),
                      _DSkel(w: 78, h: 16, r: 5, dark: true)
                          .animate(delay: 120.ms).fadeIn(duration: 320.ms),
                      const SizedBox(width: 20),
                      _DSkel(w: 76, h: 36, r: 9, dark: true)
                          .animate(delay: 140.ms).fadeIn(duration: 320.ms),
                      const SizedBox(width: 10),
                      _DSkel(w: 100, h: 36, r: 9, dark: true)
                          .animate(delay: 160.ms).fadeIn(duration: 320.ms),
                    ] else
                      _DSkel(w: 36, h: 36, r: 8, dark: true)
                          .animate(delay: 80.ms).fadeIn(duration: 320.ms),
                  ],
                ),
              ),
            ),
          ),

          // ── Hero centered content ────────────────────
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 80),

                // Logo circle
                _DSkel(w: 96, h: 96, r: 48, dark: true)
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 480.ms)
                    .slideY(begin: -0.15, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 18),

                // HIRAYA — 6 letter boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _DSkel(w: 52, h: 72, r: 8, dark: true)
                          .animate(
                              delay: Duration(milliseconds: 280 + i * 60))
                          .fadeIn(duration: 480.ms)
                          .slideY(
                              begin: 0.25,
                              end: 0,
                              curve: Curves.easeOutBack),
                    );
                  }),
                ),
                const SizedBox(height: 14),

                // Tagline pill
                _DSkel(w: 300, h: 44, r: 8, dark: true)
                    .animate(delay: 620.ms)
                    .fadeIn(duration: 440.ms)
                    .slideX(begin: -0.1, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 14),

                // Sub-tagline 2 lines
                _DSkel(w: 360, h: 16, r: 5, dark: true)
                    .animate(delay: 720.ms).fadeIn(duration: 400.ms),
                const SizedBox(height: 6),
                _DSkel(w: 280, h: 16, r: 5, dark: true)
                    .animate(delay: 760.ms).fadeIn(duration: 400.ms),
                const SizedBox(height: 38),

                // CTA buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _DSkel(w: 162, h: 56, r: 14, dark: true)
                        .animate(delay: 880.ms)
                        .fadeIn(duration: 440.ms)
                        .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                    const SizedBox(width: 14),
                    _DSkel(w: 184, h: 56, r: 14, dark: true)
                        .animate(delay: 920.ms)
                        .fadeIn(duration: 440.ms)
                        .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                  ],
                ),
                const SizedBox(height: 40),

                // Stats strip
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  height: 74,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(7, (i) {
                      if (i.isOdd) {
                        return Container(
                          width: 1, height: 32,
                          color: Colors.white.withValues(alpha: 0.12),
                        );
                      }
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _DSkel(w: 48, h: 18, r: 5, dark: true)
                              .animate(
                                  delay: Duration(
                                      milliseconds: 1100 + (i ~/ 2) * 60))
                              .fadeIn(duration: 360.ms),
                          const SizedBox(height: 4),
                          _DSkel(w: 64, h: 12, r: 4, dark: true)
                              .animate(
                                  delay: Duration(
                                      milliseconds: 1120 + (i ~/ 2) * 60))
                              .fadeIn(duration: 360.ms),
                        ],
                      );
                    }),
                  ),
                )
                    .animate(delay: 1050.ms)
                    .fadeIn(duration: 440.ms)
                    .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
              ],
            ),
          ),

          // Scroll indicator
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Column(
              children: [
                _DSkel(w: 130, h: 11, r: 4, dark: true)
                    .animate(delay: 1300.ms).fadeIn(duration: 360.ms),
                const SizedBox(height: 8),
                Column(
                  children: List.generate(3, (i) =>
                    _DSkel(w: 22, h: 10, r: 4, dark: true)
                        .animate(delay: Duration(milliseconds: 1340 + i * 60))
                        .fadeIn(duration: 300.ms),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Category grid skeleton
// ─────────────────────────────────────────────────────────────
class _CategoryGridSkeleton extends StatelessWidget {
  const _CategoryGridSkeleton();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossCount = width > 900 ? 3 : width > 600 ? 2 : 1;

    return Container(
      color: AppColors.offWhite,
      padding: const EdgeInsets.symmetric(vertical: 88, horizontal: 24),
      child: Column(
        children: [
          // Header
          Column(
            children: [
              _LSkel(w: 130, h: 28, r: 20)
                  .animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 16),
              _LSkel(w: 260, h: 42, r: 8)
                  .animate(delay: 60.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: 10),
              _LSkel(w: 56, h: 3, r: 2)
                  .animate(delay: 80.ms).fadeIn(duration: 380.ms),
              const SizedBox(height: 12),
              _LSkel(w: 320, h: 16, r: 5)
                  .animate(delay: 100.ms).fadeIn(duration: 380.ms),
            ],
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.15, end: 0),
          const SizedBox(height: 52),

          // Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.6,
            ),
            itemCount: 6,
            itemBuilder: (_, index) => _CategoryCardSkeleton(index: index),
          ),
          const SizedBox(height: 44),

          // Explore all button
          _LSkel(w: 220, h: 52, r: 14)
              .animate(delay: 400.ms).fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}

class _CategoryCardSkeleton extends StatelessWidget {
  final int index;
  const _CategoryCardSkeleton({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _LSkel(w: 50, h: 50, r: 13),
              const Spacer(),
              _LSkel(w: 64, h: 22, r: 10),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LSkel(w: 120, h: 17, r: 6),
              const SizedBox(height: 6),
              _LSkel(w: double.infinity, h: 13, r: 5),
              const SizedBox(height: 4),
              _LSkel(w: 140, h: 13, r: 5),
            ],
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 80 * index))
        .fadeIn(duration: 420.ms)
        .slideY(begin: 0.18, end: 0, curve: Curves.easeOutCubic);
  }
}

// ─────────────────────────────────────────────────────────────
// Innovation Carousel skeleton
// ─────────────────────────────────────────────────────────────
class _CarouselSkeleton extends StatelessWidget {
  const _CarouselSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF021825),
      padding: const EdgeInsets.symmetric(vertical: 88),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _DSkel(w: 100, h: 28, r: 20, dark: true)
                    .animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 16),
                _DSkel(w: 260, h: 42, r: 8, dark: true)
                    .animate(delay: 60.ms).fadeIn(duration: 400.ms),
                const SizedBox(height: 10),
                _DSkel(w: 340, h: 15, r: 5, dark: true)
                    .animate(delay: 80.ms).fadeIn(duration: 380.ms),
              ],
            ).animate().fadeIn(duration: 500.ms),
          ),
          const SizedBox(height: 48),

          // Slide cards row
          SizedBox(
            height: 300,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 3,
              itemBuilder: (_, i) => Container(
                width: MediaQuery.of(context).size.width * 0.75,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08)),
                ),
                padding: const EdgeInsets.all(30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _DSkel(w: 140, h: 28, r: 20, dark: true)
                        .animate(delay: Duration(milliseconds: 60 * i))
                        .fadeIn(duration: 380.ms),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DSkel(w: 80, h: 12, r: 4, dark: true)
                            .animate(delay: Duration(milliseconds: 80 + 60 * i))
                            .fadeIn(duration: 360.ms),
                        const SizedBox(height: 8),
                        _DSkel(w: double.infinity, h: 26, r: 6, dark: true)
                            .animate(delay: Duration(milliseconds: 100 + 60 * i))
                            .fadeIn(duration: 360.ms),
                        const SizedBox(height: 6),
                        _DSkel(w: 200, h: 26, r: 6, dark: true)
                            .animate(delay: Duration(milliseconds: 120 + 60 * i))
                            .fadeIn(duration: 360.ms),
                        const SizedBox(height: 10),
                        _DSkel(w: 160, h: 13, r: 4, dark: true)
                            .animate(delay: Duration(milliseconds: 140 + 60 * i))
                            .fadeIn(duration: 360.ms),
                      ],
                    ),
                  ],
                ),
              )
                  .animate(delay: Duration(milliseconds: 120 * i))
                  .fadeIn(duration: 440.ms)
                  .slideX(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
            ),
          ),
          const SizedBox(height: 28),

          // Controls row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _DSkel(w: 36, h: 36, r: 18, dark: true)
                    .animate(delay: 200.ms).fadeIn(duration: 360.ms),
                const SizedBox(width: 20),
                Row(
                  children: List.generate(4, (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _DSkel(w: i == 0 ? 28 : 8, h: 8, r: 4, dark: true)
                        .animate(delay: Duration(milliseconds: 220 + i * 30))
                        .fadeIn(duration: 340.ms),
                  )),
                ),
                const SizedBox(width: 20),
                _DSkel(w: 36, h: 36, r: 18, dark: true)
                    .animate(delay: 340.ms).fadeIn(duration: 360.ms),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                widthFactor: 0.25,
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Features section skeleton
// ─────────────────────────────────────────────────────────────
class _FeaturesSkeleton extends StatelessWidget {
  const _FeaturesSkeleton();

  @override
  Widget build(BuildContext context) {
    final crossCount = MediaQuery.of(context).size.width > 700 ? 4 : 2;
    return Container(
      color: AppColors.navy,
      padding: const EdgeInsets.symmetric(vertical: 88, horizontal: 24),
      child: Column(
        children: [
          // Header
          Column(
            children: [
              _DSkel(w: 100, h: 28, r: 20, dark: true)
                  .animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 16),
              _DSkel(w: 290, h: 42, r: 8, dark: true)
                  .animate(delay: 60.ms).fadeIn(duration: 400.ms),
              const SizedBox(height: 12),
              _DSkel(w: 380, h: 16, r: 5, dark: true)
                  .animate(delay: 80.ms).fadeIn(duration: 380.ms),
              const SizedBox(height: 6),
              _DSkel(w: 300, h: 16, r: 5, dark: true)
                  .animate(delay: 100.ms).fadeIn(duration: 380.ms),
            ],
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.12, end: 0),
          const SizedBox(height: 56),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              childAspectRatio: 0.88,
            ),
            itemCount: 4,
            itemBuilder: (_, index) => _FeatureCardSkeleton(index: index),
          ),
        ],
      ),
    );
  }
}

class _FeatureCardSkeleton extends StatelessWidget {
  final int index;
  const _FeatureCardSkeleton({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: const Color(0xFF042235),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _DSkel(w: 52, h: 52, r: 13, dark: true),
              _DSkel(w: 56, h: 22, r: 12, dark: true),
            ],
          ),
          const SizedBox(height: 18),
          _DSkel(w: 130, h: 17, r: 6, dark: true),
          const SizedBox(height: 10),
          _DSkel(w: double.infinity, h: 13, r: 5, dark: true),
          const SizedBox(height: 5),
          _DSkel(w: double.infinity, h: 13, r: 5, dark: true),
          const SizedBox(height: 5),
          _DSkel(w: 160, h: 13, r: 5, dark: true),
          const Spacer(),
          _DSkel(w: 18, h: 2, r: 2, dark: true),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 80 * index))
        .fadeIn(duration: 480.ms)
        .slideY(begin: 0.14, end: 0, curve: Curves.easeOutCubic);
  }
}

// ─────────────────────────────────────────────────────────────
// CTA section skeleton
// ─────────────────────────────────────────────────────────────
class _CtaSkeleton extends StatelessWidget {
  const _CtaSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 88, horizontal: 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.teal, AppColors.navy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          _DSkel(w: 170, h: 34, r: 20, dark: true)
              .animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 22),
          _DSkel(w: 340, h: 50, r: 8, dark: true)
              .animate(delay: 80.ms).fadeIn(duration: 420.ms),
          const SizedBox(height: 10),
          _DSkel(w: 240, h: 50, r: 8, dark: true)
              .animate(delay: 100.ms).fadeIn(duration: 420.ms),
          const SizedBox(height: 14),
          _DSkel(w: 340, h: 16, r: 5, dark: true)
              .animate(delay: 140.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 44),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              if (i.isEven) {
                return _DSkel(w: 100, h: 52, r: 8, dark: true)
                    .animate(delay: Duration(milliseconds: 200 + i * 40))
                    .fadeIn(duration: 400.ms);
              }
              return const SizedBox(width: 48);
            }),
          ),
          const SizedBox(height: 44),
          _DSkel(w: 240, h: 62, r: 16, dark: true)
              .animate(delay: 360.ms)
              .fadeIn(duration: 440.ms)
              .slideY(begin: 0.10, end: 0, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Footer skeleton
// ─────────────────────────────────────────────────────────────
class _FooterSkeleton extends StatelessWidget {
  const _FooterSkeleton();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    return Container(
      color: const Color(0xFF080E14),
      child: Column(
        children: [
          // Gradient top divider
          Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.teal,
                  AppColors.golden,
                  AppColors.teal,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 40),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _FooterBrandSkeleton(),
                      ),
                      const SizedBox(width: 48),
                      Expanded(child: _FooterColSkeleton(itemCount: 3)),
                      const SizedBox(width: 32),
                      Expanded(child: _FooterColSkeleton(itemCount: 5)),
                      const SizedBox(width: 32),
                      Expanded(child: _FooterColSkeleton(itemCount: 4)),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FooterBrandSkeleton(),
                      const SizedBox(height: 36),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _FooterColSkeleton(itemCount: 3)),
                          Expanded(child: _FooterColSkeleton(itemCount: 3)),
                        ],
                      ),
                    ],
                  ),
          ),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _DSkel(w: 320, h: 12, r: 4, dark: true)
                    .animate().fadeIn(duration: 360.ms),
                _DSkel(w: 180, h: 12, r: 4, dark: true)
                    .animate(delay: 60.ms).fadeIn(duration: 360.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterBrandSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _DSkel(w: 38, h: 38, r: 8, dark: true),
          const SizedBox(width: 10),
          _DSkel(w: 80, h: 22, r: 5, dark: true),
        ]),
        const SizedBox(height: 14),
        _DSkel(w: 160, h: 14, r: 5, dark: true),
        const SizedBox(height: 6),
        _DSkel(w: 140, h: 14, r: 5, dark: true),
        const SizedBox(height: 18),
        Row(children: [
          _DSkel(w: 36, h: 36, r: 9, dark: true),
          const SizedBox(width: 10),
          _DSkel(w: 36, h: 36, r: 9, dark: true),
          const SizedBox(width: 10),
          _DSkel(w: 36, h: 36, r: 9, dark: true),
        ]),
      ],
    ).animate().fadeIn(duration: 460.ms);
  }
}

class _FooterColSkeleton extends StatelessWidget {
  final int itemCount;
  const _FooterColSkeleton({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DSkel(w: 80, h: 12, r: 4, dark: true)
            .animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 16),
        ...List.generate(
          itemCount,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DSkel(
              w: 80.0 + (i % 3) * 20.0,
              h: 13,
              r: 5,
              dark: true,
            ).animate(delay: Duration(milliseconds: 40 * i)).fadeIn(duration: 360.ms),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// _DSkel — dark shimmer box (for dark backgrounds)
// ═══════════════════════════════════════════════════════════
class _DSkel extends StatelessWidget {
  final double w;
  final double h;
  final double r;
  final bool dark;

  const _DSkel({
    required this.w,
    required this.h,
    this.r = 8,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w == double.infinity ? null : w,
      height: h,
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.10)
            : AppColors.lightGray,
        borderRadius: BorderRadius.circular(r),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1400.ms,
          delay: 100.ms,
          color: dark
              ? Colors.white.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.80),
          blendMode: BlendMode.srcATop,
        );
  }
}

// ═══════════════════════════════════════════════════════════
// _LSkel — light shimmer box (for light backgrounds)
// ═══════════════════════════════════════════════════════════
class _LSkel extends StatelessWidget {
  final double w;
  final double h;
  final double r;

  const _LSkel({
    required this.w,
    required this.h,
    this.r = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w == double.infinity ? null : w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.lightGray.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(r),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1400.ms,
          delay: 100.ms,
          color: Colors.white.withValues(alpha: 0.90),
          blendMode: BlendMode.srcATop,
        );
  }
}
