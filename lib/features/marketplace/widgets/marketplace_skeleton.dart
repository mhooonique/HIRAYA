import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// MarketplaceSkeleton
// Full-layout skeleton that mirrors every element of the
// Marketplace screen: search bar, category chips, stats strip,
// and a responsive grid of product card skeletons.
// ═══════════════════════════════════════════════════════════
class MarketplaceSkeleton extends StatelessWidget {
  const MarketplaceSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossCount = width > 1200
        ? 4
        : width > 800
            ? 3
            : width > 500
                ? 2
                : 1;

    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        // ── Search + Sort skeleton ───────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Row(
              children: [
                Expanded(
                  child: _Shimmer(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _Shimmer(
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms),
        ),

        // ── Category chips skeleton ──────────────────────
        SliverToBoxAdapter(
          child: SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _SkeletonChip(width: 60, delay: 0),
                const SizedBox(width: 8),
                _SkeletonChip(width: 108, delay: 50),
                const SizedBox(width: 8),
                _SkeletonChip(width: 100, delay: 100),
                const SizedBox(width: 8),
                _SkeletonChip(width: 72, delay: 150),
                const SizedBox(width: 8),
                _SkeletonChip(width: 116, delay: 200),
                const SizedBox(width: 8),
                _SkeletonChip(width: 130, delay: 250),
                const SizedBox(width: 8),
                _SkeletonChip(width: 178, delay: 300),
              ],
            ),
          ),
        ),

        // ── Stats strip skeleton ─────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: _Shimmer(
              child: Container(
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    _SkeletonStatItem(delay: 0),
                    const SizedBox(width: 16),
                    Container(
                        width: 1, height: 28, color: AppColors.lightGray),
                    const SizedBox(width: 16),
                    _SkeletonStatItem(delay: 80),
                    const SizedBox(width: 16),
                    Container(
                        width: 1, height: 28, color: AppColors.lightGray),
                    const SizedBox(width: 16),
                    _SkeletonStatItem(delay: 160),
                  ],
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // ── Product card grid skeleton ───────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _SkeletonProductCard(index: index),
              childCount: crossCount * 2, // 2 rows
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.72,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// _SkeletonProductCard — pixel-accurate mirror of ProductCard
// ═══════════════════════════════════════════════════════════
class _SkeletonProductCard extends StatelessWidget {
  final int index;
  const _SkeletonProductCard({required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cover area (180px) ───────────────────────
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: _Shimmer(
              baseColor: const Color(0xFFE8ECF0),
              highlightColor: const Color(0xFFF8FAFB),
              child: Container(
                height: 168,
                width: double.infinity,
                color: const Color(0xFFE8ECF0),
                child: Stack(
                  children: [
                    // Category badge (top-left)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        width: 80,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    // Verified badge (top-right)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    // Like button (bottom-right)
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        width: 64,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Content area ─────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title line 1
                _Shimmer(
                  child: _SkeletonBox(
                      width: double.infinity, height: 14, radius: 6)),
                const SizedBox(height: 6),
                // Title line 2
                _Shimmer(
                  child: _SkeletonBox(
                      width: 140, height: 14, radius: 6)),
                const SizedBox(height: 10),
                // Desc line 1
                _Shimmer(
                  child: _SkeletonBox(
                      width: double.infinity, height: 11, radius: 5)),
                const SizedBox(height: 5),
                // Desc line 2
                _Shimmer(
                  child: _SkeletonBox(
                      width: 160, height: 11, radius: 5)),
                const SizedBox(height: 14),
                // Avatar + innovator name row
                Row(
                  children: [
                    _Shimmer(
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFE8ECF0),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _Shimmer(
                      child: _SkeletonBox(
                          width: 100, height: 11, radius: 5)),
                  ],
                ),
                const SizedBox(height: 12),
                // Divider
                Container(
                    height: 1, color: AppColors.lightGray),
                const SizedBox(height: 12),
                // Stats row: views | interest | view details
                Row(
                  children: [
                    _Shimmer(
                      child: _SkeletonBox(
                          width: 40, height: 11, radius: 5)),
                    const SizedBox(width: 12),
                    _Shimmer(
                      child: _SkeletonBox(
                          width: 36, height: 11, radius: 5)),
                    const Spacer(),
                    _Shimmer(
                      child: Container(
                        width: 76,
                        height: 26,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8ECF0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(
            delay: Duration(milliseconds: 55 * index))
        .fadeIn(duration: 380.ms, curve: Curves.easeOut)
        .slideY(
            begin: 0.12,
            end: 0,
            duration: 380.ms,
            curve: Curves.easeOutCubic);
  }
}

// ═══════════════════════════════════════════════════════════
// _SkeletonChip — horizontal chip placeholder
// ═══════════════════════════════════════════════════════════
class _SkeletonChip extends StatelessWidget {
  final double width;
  final int delay;
  const _SkeletonChip({required this.width, required this.delay});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: width,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.lightGray),
        ),
      ),
    )
        .animate()
        .fadeIn(
            duration: 380.ms,
            delay: Duration(milliseconds: delay))
        .slideX(
            begin: 0.12,
            end: 0,
            duration: 380.ms,
            delay: Duration(milliseconds: delay),
            curve: Curves.easeOutCubic);
  }
}

// ═══════════════════════════════════════════════════════════
// _SkeletonStatItem — stat chip placeholder inside stats strip
// ═══════════════════════════════════════════════════════════
class _SkeletonStatItem extends StatelessWidget {
  final int delay;
  const _SkeletonStatItem({required this.delay});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.lightGray.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 13,
              decoration: BoxDecoration(
                color: AppColors.lightGray.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 52,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.lightGray.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// _SkeletonBox — a generic rounded rectangle skeleton block
// ═══════════════════════════════════════════════════════════
class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE8ECF0),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// _Shimmer — sweeping highlight shimmer on any child
// Uses flutter_animate's shimmer effect for buttery smoothness
// ═══════════════════════════════════════════════════════════
class _Shimmer extends StatelessWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const _Shimmer({
    required this.child,
    this.baseColor = const Color(0xFFE8ECF0),
    this.highlightColor = const Color(0xFFF4F6F8),
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1400.ms,
          delay: 200.ms,
          color: highlightColor,
          angle: 6,
          blendMode: BlendMode.srcATop,
        );
  }
}
