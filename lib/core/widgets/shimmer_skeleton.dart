import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

// =============================================================================
// Digital Platform — Shimmer Skeleton System  (Enhanced v3)
// Triple-layer animation: shimmer sweep + pulse opacity + breathing scale
// Wave stagger: each block animates with 50ms offset delay per index
// Dark theme: darkSurface(0xFF0F1923) base → borderDark(0xFF1E2D3D) highlight
// =============================================================================

// ─────────────────────────────────────────────────────────────────────────────
// _SkeletonCtrl — three synchronized animation controllers
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonCtrl {
  const _SkeletonCtrl({
    required this.shimmer,
    required this.pulse,
    required this.breath,
  });

  /// Horizontal shimmer sweep across block (1600ms, repeat forward)
  final AnimationController shimmer;

  /// Opacity pulse 0.45 → 0.85 → 0.45 (1800ms, repeat reverse)
  final AnimationController pulse;

  /// Subtle scale breathe 0.98 → 1.02 (3200ms, repeat reverse)
  final AnimationController breath;
}

// ─────────────────────────────────────────────────────────────────────────────
// Core shimmer painter — shared across all skeleton variants
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({required this.progress, required this.borderRadius});

  final double progress;
  final double borderRadius;

  static const Color _base      = AppColors.darkSurface; // 0xFF0F1923
  static const Color _highlight = AppColors.borderDark;  // 0xFF1E2D3D

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final double sweepRange = size.width * 2;
    final double sweepStart = -size.width + progress * (sweepRange + size.width);
    final double sweepEnd   = sweepStart + size.width * 0.8;

    final shader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [_base, _highlight, _highlight, _base],
      stops: [0.0, 0.35, 0.65, 1.0],
    ).createShader(Rect.fromLTRB(sweepStart, 0, sweepEnd, size.height));

    canvas.drawRRect(rrect, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// _AnimatedBlock — single block with all three animation layers + stagger
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedBlock extends StatelessWidget {
  const _AnimatedBlock({
    required this.ctrl,
    this.width,
    required this.height,
    this.radius = 6,
    this.delay  = 0,
  });

  final _SkeletonCtrl ctrl;
  final double?       width;
  final double        height;
  final double        radius;

  /// Block index used for wave stagger (50ms offset per index).
  final int delay;

  // Triangle wave: 0 → 1 → 0
  static double _wave(double t) => t < 0.5 ? t * 2.0 : (1.0 - t) * 2.0;

  @override
  Widget build(BuildContext context) {
    final staggerShift = (delay * 0.055) % 1.0;

    return AnimatedBuilder(
      animation: Listenable.merge([ctrl.shimmer, ctrl.pulse, ctrl.breath]),
      builder: (_, __) {
        final pulseT  = (ctrl.pulse.value  + staggerShift)       % 1.0;
        final breathT = (ctrl.breath.value + staggerShift * 0.4) % 1.0;

        final opacity = 0.42 + 0.43 * _wave(pulseT);
        final scale   = 0.98 + 0.04 * _wave(breathT);

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: SizedBox(
              width:  width,
              height: height,
              child: CustomPaint(
                painter: _ShimmerPainter(
                  progress:     ctrl.shimmer.value,
                  borderRadius: radius,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SkeletonBase — owns the three AnimationControllers
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonBase extends StatefulWidget {
  const _SkeletonBase({required this.builder});

  final Widget Function(BuildContext, _SkeletonCtrl) builder;

  @override
  State<_SkeletonBase> createState() => _SkeletonBaseState();
}

class _SkeletonBaseState extends State<_SkeletonBase>
    with TickerProviderStateMixin {
  late final AnimationController _shimmer;
  late final AnimationController _pulse;
  late final AnimationController _breath;
  late final _SkeletonCtrl       _ctrl;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _pulse = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _breath = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _ctrl = _SkeletonCtrl(shimmer: _shimmer, pulse: _pulse, breath: _breath);
  }

  @override
  void dispose() {
    _shimmer.dispose();
    _pulse.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _ctrl);
}

// ─────────────────────────────────────────────────────────────────────────────
// Convenience builder used inside all named skeleton constructors
// ─────────────────────────────────────────────────────────────────────────────

Widget _block(
  _SkeletonCtrl ctrl, {
  double? width,
  required double height,
  double radius = 6,
  int delay = 0,
}) =>
    _AnimatedBlock(
      ctrl:   ctrl,
      width:  width,
      height: height,
      radius: radius,
      delay:  delay,
    );

// =============================================================================
// ShimmerSkeleton — public API
// =============================================================================

/// Entry point for all skeleton loading variants.
///
/// Usage:
/// ```dart
/// ShimmerSkeleton.navBar()
/// ShimmerSkeleton.productCard()
/// ShimmerSkeleton.productGrid(count: 6)
/// ShimmerSkeleton.marketplaceHero()
/// ShimmerSkeleton.landingHero()
/// ShimmerSkeleton.categoryBentoGrid()
/// ShimmerSkeleton.innovationCarouselCard()
/// ShimmerSkeleton.featureCard()
/// ShimmerSkeleton.categoryCard()
/// ShimmerSkeleton.productDetail()
/// ShimmerSkeleton.profileCard()
/// ShimmerSkeleton.authForm()
/// ```
class ShimmerSkeleton extends StatelessWidget {
  const ShimmerSkeleton._({required _SkeletonType type, int count = 6})
      : _type  = type,
        _count = count;

  final _SkeletonType _type;
  final int           _count;

  // ── Named constructors ────────────────────────────────────────────────────

  /// Horizontal navbar strip: logo + nav link placeholders.
  factory ShimmerSkeleton.navBar() =>
      const ShimmerSkeleton._(type: _SkeletonType.navBar);

  /// Single product card skeleton.
  factory ShimmerSkeleton.productCard() =>
      const ShimmerSkeleton._(type: _SkeletonType.productCard);

  /// Responsive grid of [count] product card skeletons.
  factory ShimmerSkeleton.productGrid({int count = 6}) =>
      ShimmerSkeleton._(type: _SkeletonType.productGrid, count: count);

  /// Marketplace hero section skeleton.
  factory ShimmerSkeleton.marketplaceHero() =>
      const ShimmerSkeleton._(type: _SkeletonType.marketplaceHero);

  /// Full-viewport landing hero skeleton.
  factory ShimmerSkeleton.landingHero() =>
      const ShimmerSkeleton._(type: _SkeletonType.landingHero);

  /// Bento-grid category section skeleton.
  factory ShimmerSkeleton.categoryBentoGrid() =>
      const ShimmerSkeleton._(type: _SkeletonType.categoryBentoGrid);

  /// Single innovation carousel card skeleton.
  factory ShimmerSkeleton.innovationCarouselCard() =>
      const ShimmerSkeleton._(type: _SkeletonType.innovationCarouselCard);

  /// Feature card: icon square + title + description lines.
  factory ShimmerSkeleton.featureCard() =>
      const ShimmerSkeleton._(type: _SkeletonType.featureCard);

  /// Category card: horizontal icon + text.
  factory ShimmerSkeleton.categoryCard() =>
      const ShimmerSkeleton._(type: _SkeletonType.categoryCard);

  /// Product detail: full-width hero banner + two-column below.
  factory ShimmerSkeleton.productDetail() =>
      const ShimmerSkeleton._(type: _SkeletonType.productDetail);

  /// User / innovator profile card skeleton.
  factory ShimmerSkeleton.profileCard() =>
      const ShimmerSkeleton._(type: _SkeletonType.profileCard);

  /// Auth form: title + input fields + submit button.
  factory ShimmerSkeleton.authForm() =>
      const ShimmerSkeleton._(type: _SkeletonType.authForm);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return _SkeletonBase(
      builder: (ctx, ctrl) {
        return switch (_type) {
          _SkeletonType.navBar                 => _NavBarSkeleton(ctrl),
          _SkeletonType.productCard            => _ProductCardSkeleton(ctrl),
          _SkeletonType.productGrid            => _ProductGridSkeleton(ctrl, count: _count),
          _SkeletonType.marketplaceHero        => _MarketplaceHeroSkeleton(ctrl),
          _SkeletonType.landingHero            => _LandingHeroSkeleton(ctrl),
          _SkeletonType.categoryBentoGrid      => _CategoryBentoGridSkeleton(ctrl),
          _SkeletonType.innovationCarouselCard => _InnovationCarouselCardSkeleton(ctrl),
          _SkeletonType.featureCard            => _FeatureCardSkeleton(ctrl),
          _SkeletonType.categoryCard           => _CategoryCardSkeleton(ctrl),
          _SkeletonType.productDetail          => _ProductDetailSkeleton(ctrl),
          _SkeletonType.profileCard            => _ProfileCardSkeleton(ctrl),
          _SkeletonType.authForm               => _AuthFormSkeleton(ctrl),
        };
      },
    );
  }
}

enum _SkeletonType {
  navBar,
  productCard,
  productGrid,
  marketplaceHero,
  landingHero,
  categoryBentoGrid,
  innovationCarouselCard,
  featureCard,
  categoryCard,
  productDetail,
  profileCard,
  authForm,
}

// =============================================================================
// Skeleton layout implementations
// =============================================================================

// ── NavBar ────────────────────────────────────────────────────────────────────

class _NavBarSkeleton extends StatelessWidget {
  const _NavBarSkeleton(this.ctrl);
  final _SkeletonCtrl ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      color: AppColors.darkSurface,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _block(ctrl, width: 120, height: 36, radius: 8, delay: 0),
          const Spacer(),
          for (int i = 0; i < 5; i++) ...[
            _block(ctrl, width: 60 + i * 8.0, height: 14, radius: 6, delay: i + 1),
            const SizedBox(width: 28),
          ],
          _block(ctrl, width: 110, height: 38, radius: 10, delay: 6),
        ],
      ),
    );
  }
}

// ── Product Card ──────────────────────────────────────────────────────────────

class _ProductCardSkeleton extends StatelessWidget {
  const _ProductCardSkeleton(this.ctrl);
  final _SkeletonCtrl ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area
          _block(ctrl, height: 180, radius: 16, delay: 0),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _block(ctrl, width: 80,  height: 20, radius: 10, delay: 1),
                const SizedBox(height: 10),
                _block(ctrl, width: double.infinity, height: 14, radius: 6, delay: 2),
                const SizedBox(height: 6),
                _block(ctrl, width: 140, height: 14, radius: 6, delay: 3),
                const SizedBox(height: 12),
                _block(ctrl, width: double.infinity, height: 12, radius: 6, delay: 4),
                const SizedBox(height: 5),
                _block(ctrl, width: 180, height: 12, radius: 6, delay: 5),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _block(ctrl, width: 14, height: 14, radius: 7, delay: 6),
                    const SizedBox(width: 6),
                    _block(ctrl, width: 90, height: 12, radius: 6, delay: 7),
                    const Spacer(),
                    _block(ctrl, width: 40, height: 12, radius: 6, delay: 8),
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

// ── Product Grid ──────────────────────────────────────────────────────────────

class _ProductGridSkeleton extends StatelessWidget {
  const _ProductGridSkeleton(this.ctrl, {required this.count});
  final _SkeletonCtrl ctrl;
  final int count;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final int cols = width > 1200
        ? 4
        : width > 800
            ? 3
            : width > 500
                ? 2
                : 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 0.68,
        ),
        itemBuilder: (_, __) => _ProductCardSkeleton(ctrl),
      ),
    );
  }
}

// ── Marketplace Hero ──────────────────────────────────────────────────────────

class _MarketplaceHeroSkeleton extends StatelessWidget {
  const _MarketplaceHeroSkeleton(this.ctrl);
  final _SkeletonCtrl ctrl;

  @override
  Widget build(BuildContext context) {
    final isDesktop  = MediaQuery.of(context).size.width > 900;
    final heroHeight = isDesktop ? 300.0 : 220.0;

    return Container(
      width: double.infinity,
      height: heroHeight,
      color: AppColors.darkSurface,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _block(ctrl, width: double.infinity, height: heroHeight, radius: 0, delay: 0),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _block(ctrl, width: 120, height: 18, radius: 9, delay: 1),
              const SizedBox(height: 16),
              _block(ctrl, width: isDesktop ? 420 : 240, height: 36, radius: 8, delay: 2),
              const SizedBox(height: 10),
              _block(ctrl, width: isDesktop ? 300 : 180, height: 36, radius: 8, delay: 3),
              const SizedBox(height: 24),
              _block(
                ctrl,
                width:  isDesktop ? 560 : null,
                height: 52,
                radius: 14,
                delay:  4,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Landing Hero ──────────────────────────────────────────────────────────────

class _LandingHeroSkeleton extends StatelessWidget {
  const _LandingHeroSkeleton(this.ctrl);
  final _SkeletonCtrl ctrl;

  @override
  Widget build(BuildContext context) {
    final size      = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Container(
      width: double.infinity,
      height: size.height,
      color: AppColors.deepVoid,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Full background block
          _block(ctrl, width: double.infinity, height: size.height, radius: 0, delay: 0),
          // Centered content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 80 : 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Eyebrow pill
                _block(ctrl, width: 160, height: 22, radius: 11, delay: 1),
                const SizedBox(height: 24),
                // Heading line 1
                _block(ctrl, width: isDesktop ? 600 : double.infinity, height: 52, radius: 10, delay: 2),
                const SizedBox(height: 12),
                // Heading line 2
                _block(ctrl, width: isDesktop ? 500 : 280, height: 52, radius: 10, delay: 3),
                const SizedBox(height: 28),
                // Subtitle lines
                _block(ctrl, width: isDesktop ? 480 : double.infinity, height: 16, radius: 6, delay: 4),
                const SizedBox(height: 8),
                _block(ctrl, width: isDesktop ? 380 : 220, height: 16, radius: 6, delay: 5),
                const SizedBox(height: 40),
                // CTA buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _block(ctrl, width: 160, height: 52, radius: 14, delay: 6),
                    const SizedBox(width: 16),
                    _block(ctrl, width: 160, height: 52, radius: 14, delay: 7),
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

// ── Category Bento Grid ───────────────────────────────────────────────────────

class _CategoryBentoGridSkeleton extends StatelessWidget {
  const _CategoryBentoGridSkeleton(this.ctrl);
  final _SkeletonCtrl ctrl;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 24,
        vertical: 60,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          _block(ctrl, width: 200, height: 14, radius: 6, delay: 0),
          const SizedBox(height: 12),
          _block(ctrl, width: isDesktop ? 350 : 240, height: 36, radius: 8, delay: 1),
          const SizedBox(height: 40),
          // Bento grid: 2 large + 4 small
          if (isDesktop) ...[
            Row(
              children: [
                Expanded(flex: 2, child: _block(ctrl, height: 220, radius: 16, delay: 2)),
                const SizedBox(width: 16),
                Expanded(child: _block(ctrl, height: 220, radius: 16, delay: 3)),
                const SizedBox(width: 16),
                Expanded(child: _block(ctrl, height: 220, radius: 16, delay: 4)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _block(ctrl, height: 160, radius: 16, delay: 5)),
                const SizedBox(width: 16),
                Expanded(child: _block(ctrl, height: 160, radius: 16, delay: 6)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _block(ctrl, height: 160, radius: 16, delay: 7)),
              ],
            ),
          ] else ...[
            for (int i = 0; i < 4; i++) ...[
              _block(ctrl, width: double.infinity, height: 100, radius: 14, delay: i + 2),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

// ── Innovation Carousel Card ──────────────────────────────────────────────────

class _InnovationCarouselCardSkeleton extends StatelessWidget {
  const _InnovationCarouselCardSkeleton(this.ctrl);
  final _SkeletonCtrl ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _block(ctrl, width: double.infinity, height: 160, radius: 20, delay: 0),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _block(ctrl, width: 70, height: 18, radius: 9, delay: 1),
                const SizedBox(height: 10),
                _block(ctrl, width: double.infinity, height: 16, radius: 6, delay: 2),
                const SizedBox(height: 6),
                _block(ctrl, width: 180, height: 16, radius: 6, delay: 3),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _block(ctrl, width: 32, height: 32, radius: 16, delay: 4),
                    const SizedBox(width: 8),
                    _block(ctrl, width: 100, height: 14, radius: 6, delay: 5),
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

// ── Feature Card ──────────────────────────────────────────────────────────────

class _FeatureCardSkeleton extends StatelessWidget {
  const _FeatureCardSkeleton(this.ctrl);
  final _SkeletonCtrl ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _block(ctrl, width: 52, height: 52, radius: 14, delay: 0),
          const SizedBox(height: 16),
          _block(ctrl, width: 130, height: 16, radius: 6, delay: 1),
          const SizedBox(height: 10),
          _block(ctrl, width: double.infinity, height: 12, radius: 6, delay: 2),
          const SizedBox(height: 6),
          _block(ctrl, width: double.infinity, height: 12, radius: 6, delay: 3),
          const SizedBox(height: 6),
          _block(ctrl, width: 160, height: 12, radius: 6, delay: 4),
        ],
      ),
    );
  }
}

// ── Category Card ─────────────────────────────────────────────────────────────

class _CategoryCardSkeleton extends StatelessWidget {
  const _CategoryCardSkeleton(this.ctrl);
  final _SkeletonCtrl ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark, width: 1),
      ),
      child: Row(
        children: [
          _block(ctrl, width: 40, height: 40, radius: 10, delay: 0),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _block(ctrl, width: 90, height: 14, radius: 6, delay: 1),
                const SizedBox(height: 6),
                _block(ctrl, width: 60, height: 12, radius: 6, delay: 2),
              ],
            ),
          ),
          _block(ctrl, width: 18, height: 18, radius: 9, delay: 3),
        ],
      ),
    );
  }
}

// ── Product Detail ────────────────────────────────────────────────────────────

class _ProductDetailSkeleton extends StatelessWidget {
  const _ProductDetailSkeleton(this.ctrl);
  final _SkeletonCtrl ctrl;

  @override
  Widget build(BuildContext context) {
    final width     = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;
    final heroH     = isDesktop ? 280.0 : 200.0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _block(ctrl, width: double.infinity, height: heroH, radius: 0, delay: 0),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 80 : 24,
              vertical: 32,
            ),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _detailLeftColumn(ctrl)),
                      const SizedBox(width: 40),
                      SizedBox(width: 300, child: _detailRightColumn(ctrl)),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailLeftColumn(ctrl),
                      const SizedBox(height: 32),
                      _detailRightColumn(ctrl),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _detailLeftColumn(_SkeletonCtrl ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _block(ctrl, width: 90,  height: 22, radius: 11, delay: 1),
        const SizedBox(height: 14),
        _block(ctrl, width: double.infinity, height: 28, radius: 8, delay: 2),
        const SizedBox(height: 8),
        _block(ctrl, width: 280, height: 28, radius: 8, delay: 3),
        const SizedBox(height: 24),
        for (int i = 0; i < 4; i++) ...[
          _block(ctrl, width: double.infinity, height: 14, radius: 6, delay: 4 + i),
          const SizedBox(height: 6),
        ],
        _block(ctrl, width: 200, height: 14, radius: 6, delay: 8),
        const SizedBox(height: 28),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) =>
                _block(ctrl, width: 80, height: 80, radius: 10, delay: 9 + i),
          ),
        ),
      ],
    );
  }

  Widget _detailRightColumn(_SkeletonCtrl ctrl) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _block(ctrl, width: 100, height: 14, radius: 6, delay: 1),
          const SizedBox(height: 10),
          _block(ctrl, width: double.infinity, height: 48, radius: 12, delay: 2),
          const SizedBox(height: 14),
          _block(ctrl, width: double.infinity, height: 48, radius: 12, delay: 3),
          const SizedBox(height: 20),
          Row(
            children: [
              _block(ctrl, width: 44, height: 44, radius: 22, delay: 4),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _block(ctrl, width: 110, height: 14, radius: 6, delay: 5),
                  const SizedBox(height: 6),
                  _block(ctrl, width: 70, height: 12, radius: 6, delay: 6),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Profile Card ──────────────────────────────────────────────────────────────

class _ProfileCardSkeleton extends StatelessWidget {
  const _ProfileCardSkeleton(this.ctrl);
  final _SkeletonCtrl ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          // Avatar
          _block(ctrl, width: 80, height: 80, radius: 40, delay: 0),
          const SizedBox(height: 16),
          // Name
          _block(ctrl, width: 160, height: 18, radius: 8, delay: 1),
          const SizedBox(height: 8),
          // Role badge
          _block(ctrl, width: 90, height: 22, radius: 11, delay: 2),
          const SizedBox(height: 20),
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int i = 0; i < 3; i++)
                Column(
                  children: [
                    _block(ctrl, width: 40, height: 20, radius: 6, delay: 3 + i),
                    const SizedBox(height: 4),
                    _block(ctrl, width: 50, height: 12, radius: 6, delay: 6 + i),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Bio lines
          _block(ctrl, width: double.infinity, height: 12, radius: 6, delay: 9),
          const SizedBox(height: 6),
          _block(ctrl, width: double.infinity, height: 12, radius: 6, delay: 10),
          const SizedBox(height: 6),
          _block(ctrl, width: 180, height: 12, radius: 6, delay: 11),
        ],
      ),
    );
  }
}

// ── Auth Form ─────────────────────────────────────────────────────────────────

class _AuthFormSkeleton extends StatelessWidget {
  const _AuthFormSkeleton(this.ctrl);
  final _SkeletonCtrl ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _block(ctrl, width: 180, height: 28, radius: 8, delay: 0),
          const SizedBox(height: 8),
          _block(ctrl, width: 240, height: 14, radius: 6, delay: 1),
          const SizedBox(height: 32),
          _block(ctrl, width: 80,  height: 13, radius: 6, delay: 2),
          const SizedBox(height: 8),
          _block(ctrl, width: double.infinity, height: 52, radius: 12, delay: 3),
          const SizedBox(height: 20),
          _block(ctrl, width: 80,  height: 13, radius: 6, delay: 4),
          const SizedBox(height: 8),
          _block(ctrl, width: double.infinity, height: 52, radius: 12, delay: 5),
          const SizedBox(height: 32),
          _block(ctrl, width: double.infinity, height: 52, radius: 12, delay: 6),
        ],
      ),
    );
  }
}

// =============================================================================
// Legacy helpers — backward-compat with code using ShimmerBox/ShimmerCircle/ShimmerText
// =============================================================================

/// Rectangular shimmer placeholder (legacy API — prefer ShimmerSkeleton.*).
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => SizedBox(
        width:  widget.width,
        height: widget.height,
        child: CustomPaint(
          painter: _ShimmerPainter(
            progress:     _ctrl.value,
            borderRadius: widget.borderRadius,
          ),
        ),
      ),
    );
  }
}

/// Circular shimmer placeholder (legacy API — prefer ShimmerSkeleton.*).
class ShimmerCircle extends StatefulWidget {
  const ShimmerCircle({super.key, required this.size});
  final double size;

  @override
  State<ShimmerCircle> createState() => _ShimmerCircleState();
}

class _ShimmerCircleState extends State<ShimmerCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => SizedBox(
        width:  widget.size,
        height: widget.size,
        child: CustomPaint(
          painter: _ShimmerPainter(
            progress:     _ctrl.value,
            borderRadius: widget.size / 2,
          ),
        ),
      ),
    );
  }
}

/// Single-line text shimmer placeholder (legacy API — prefer ShimmerSkeleton.*).
class ShimmerText extends StatefulWidget {
  const ShimmerText({
    super.key,
    required this.width,
    this.height = 14.0,
  });

  final double width;
  final double height;

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => SizedBox(
        width:  widget.width,
        height: widget.height,
        child: CustomPaint(
          painter: _ShimmerPainter(
            progress:     _ctrl.value,
            borderRadius: widget.height / 2,
          ),
        ),
      ),
    );
  }
}
