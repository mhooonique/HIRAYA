import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

// =============================================================================
// HIRAYA Shimmer Skeleton System
// Custom AnimationController-based shimmer — no external shimmer package.
// Dark theme: darkSurface(0xFF0F1923) base → borderDark(0xFF1E2D3D) highlight
// =============================================================================

// ─────────────────────────────────────────────────────────────────────────────
// Core shimmer painter — shared across all skeleton variants
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerPainter extends CustomPainter {
  _ShimmerPainter({required this.progress, required this.borderRadius});

  final double progress;
  final double borderRadius;

  static const Color _base = AppColors.darkSurface; // 0xFF0F1923
  static const Color _highlight = AppColors.borderDark; // 0xFF1E2D3D

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    // Sweep from -size.width to 2*size.width so it fully crosses the widget
    final double sweepRange = size.width * 2;
    final double sweepStart = -size.width + progress * (sweepRange + size.width);
    final double sweepEnd = sweepStart + size.width * 0.8;

    final shader = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [_base, _highlight, _highlight, _base],
      stops: [0.0, 0.35, 0.65, 1.0],
    ).createShader(Rect.fromLTRB(sweepStart, 0, sweepEnd, size.height));

    final paint = Paint()..shader = shader;
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// _ShimmerBlock — single animated placeholder rectangle
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerBlock extends StatelessWidget {
  const _ShimmerBlock({
    required this.controller,
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  final AnimationController controller;
  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _ShimmerPainter(
              progress: controller.value,
              borderRadius: borderRadius,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SkeletonBase — StatefulWidget that owns the AnimationController
// All public ShimmerSkeleton variants are StatelessWidget wrappers that
// receive the controller from the outer _SkeletonBase.
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonBase extends StatefulWidget {
  const _SkeletonBase({required this.builder});

  final Widget Function(BuildContext context, AnimationController controller)
      builder;

  @override
  State<_SkeletonBase> createState() => _SkeletonBaseState();
}

class _SkeletonBaseState extends State<_SkeletonBase>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}

// ─────────────────────────────────────────────────────────────────────────────
// Convenience block builder (used inside all named constructors)
// ─────────────────────────────────────────────────────────────────────────────

Widget _block(
  AnimationController c, {
  double? width,
  required double height,
  double radius = 6,
}) =>
    _ShimmerBlock(
      controller: c,
      width: width,
      height: height,
      borderRadius: radius,
    );

// =============================================================================
// ShimmerSkeleton — public API
// =============================================================================

/// Entry point for all skeleton loading variants.
///
/// Usage:
/// ```dart
/// ShimmerSkeleton.productCard()
/// ShimmerSkeleton.productGrid(count: 6)
/// ShimmerSkeleton.navBar()
/// ShimmerSkeleton.marketplaceHero()
/// ShimmerSkeleton.featureCard()
/// ShimmerSkeleton.categoryCard()
/// ShimmerSkeleton.productDetail()
/// ShimmerSkeleton.authForm()
/// ```
class ShimmerSkeleton extends StatelessWidget {
  // ── Internal factory constructor ──────────────────────────────────────────

  const ShimmerSkeleton._({required _SkeletonType type, int count = 6})
      : _type = type,
        _count = count;

  final _SkeletonType _type;
  final int _count;

  // ── Named constructors (public API) ───────────────────────────────────────

  /// Horizontal navbar strip: logo + nav link placeholders.
  factory ShimmerSkeleton.navBar() =>
      const ShimmerSkeleton._(type: _SkeletonType.navBar);

  /// Single product card skeleton: image area + text lines + badge + location.
  factory ShimmerSkeleton.productCard() =>
      const ShimmerSkeleton._(type: _SkeletonType.productCard);

  /// Grid of [count] product card skeletons.
  factory ShimmerSkeleton.productGrid({int count = 6}) =>
      ShimmerSkeleton._(type: _SkeletonType.productGrid, count: count);

  /// Marketplace hero section skeleton: tall block + centred search bar.
  factory ShimmerSkeleton.marketplaceHero() =>
      const ShimmerSkeleton._(type: _SkeletonType.marketplaceHero);

  /// Feature card: icon square + title + description lines.
  factory ShimmerSkeleton.featureCard() =>
      const ShimmerSkeleton._(type: _SkeletonType.featureCard);

  /// Category card: horizontal icon + text.
  factory ShimmerSkeleton.categoryCard() =>
      const ShimmerSkeleton._(type: _SkeletonType.categoryCard);

  /// Product detail: full-width hero banner + two-column below.
  factory ShimmerSkeleton.productDetail() =>
      const ShimmerSkeleton._(type: _SkeletonType.productDetail);

  /// Auth form: title + two input fields + button.
  factory ShimmerSkeleton.authForm() =>
      const ShimmerSkeleton._(type: _SkeletonType.authForm);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return _SkeletonBase(
      builder: (ctx, ctrl) {
        switch (_type) {
          case _SkeletonType.navBar:
            return _NavBarSkeleton(ctrl);
          case _SkeletonType.productCard:
            return _ProductCardSkeleton(ctrl);
          case _SkeletonType.productGrid:
            return _ProductGridSkeleton(ctrl, count: _count);
          case _SkeletonType.marketplaceHero:
            return _MarketplaceHeroSkeleton(ctrl);
          case _SkeletonType.featureCard:
            return _FeatureCardSkeleton(ctrl);
          case _SkeletonType.categoryCard:
            return _CategoryCardSkeleton(ctrl);
          case _SkeletonType.productDetail:
            return _ProductDetailSkeleton(ctrl);
          case _SkeletonType.authForm:
            return _AuthFormSkeleton(ctrl);
        }
      },
    );
  }
}

enum _SkeletonType {
  navBar,
  productCard,
  productGrid,
  marketplaceHero,
  featureCard,
  categoryCard,
  productDetail,
  authForm,
}

// =============================================================================
// Skeleton layout implementations
// =============================================================================

// ── NavBar ────────────────────────────────────────────────────────────────────

class _NavBarSkeleton extends StatelessWidget {
  const _NavBarSkeleton(this.c);
  final AnimationController c;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      color: AppColors.darkSurface,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo placeholder
          _block(c, width: 100, height: 36, radius: 8),
          const Spacer(),
          // Nav links
          for (int i = 0; i < 5; i++) ...[
            _block(c, width: 60 + i * 8.0, height: 14, radius: 6),
            const SizedBox(width: 28),
          ],
          // CTA button placeholder
          _block(c, width: 110, height: 38, radius: 10),
        ],
      ),
    );
  }
}

// ── Product Card ──────────────────────────────────────────────────────────────

class _ProductCardSkeleton extends StatelessWidget {
  const _ProductCardSkeleton(this.c);
  final AnimationController c;

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
          _block(c, height: 180, radius: 16),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge
                _block(c, width: 80, height: 20, radius: 10),
                const SizedBox(height: 10),
                // Title line 1
                _block(c, width: double.infinity, height: 14, radius: 6),
                const SizedBox(height: 6),
                // Title line 2 (shorter)
                _block(c, width: 140, height: 14, radius: 6),
                const SizedBox(height: 12),
                // Description lines
                _block(c, width: double.infinity, height: 12, radius: 6),
                const SizedBox(height: 5),
                _block(c, width: 180, height: 12, radius: 6),
                const SizedBox(height: 14),
                // Location row
                Row(
                  children: [
                    _block(c, width: 14, height: 14, radius: 7),
                    const SizedBox(width: 6),
                    _block(c, width: 90, height: 12, radius: 6),
                    const Spacer(),
                    _block(c, width: 40, height: 12, radius: 6),
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
  const _ProductGridSkeleton(this.c, {required this.count});
  final AnimationController c;
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
        itemBuilder: (_, __) => _ProductCardSkeleton(c),
      ),
    );
  }
}

// ── Marketplace Hero ──────────────────────────────────────────────────────────

class _MarketplaceHeroSkeleton extends StatelessWidget {
  const _MarketplaceHeroSkeleton(this.c);
  final AnimationController c;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final heroHeight = isDesktop ? 300.0 : 220.0;

    return Container(
      width: double.infinity,
      height: heroHeight,
      color: AppColors.darkSurface,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background block covering full hero
          _block(c, width: double.infinity, height: heroHeight, radius: 0),
          // Centred content column
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Eyebrow pill
              _block(c, width: 120, height: 18, radius: 9),
              const SizedBox(height: 16),
              // Title
              _block(c, width: isDesktop ? 420 : 240, height: 36, radius: 8),
              const SizedBox(height: 10),
              _block(c, width: isDesktop ? 300 : 180, height: 36, radius: 8),
              const SizedBox(height: 24),
              // Search bar shape
              Container(
                width: isDesktop ? 560 : double.infinity,
                margin: EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 24),
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.borderDark,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: AnimatedBuilder(
                  animation: c,
                  builder: (context, _) => CustomPaint(
                    painter: _ShimmerPainter(
                      progress: c.value,
                      borderRadius: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Feature Card ──────────────────────────────────────────────────────────────

class _FeatureCardSkeleton extends StatelessWidget {
  const _FeatureCardSkeleton(this.c);
  final AnimationController c;

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
          // Icon square
          _block(c, width: 52, height: 52, radius: 14),
          const SizedBox(height: 16),
          // Title
          _block(c, width: 130, height: 16, radius: 6),
          const SizedBox(height: 10),
          // Description lines
          _block(c, width: double.infinity, height: 12, radius: 6),
          const SizedBox(height: 6),
          _block(c, width: double.infinity, height: 12, radius: 6),
          const SizedBox(height: 6),
          _block(c, width: 160, height: 12, radius: 6),
        ],
      ),
    );
  }
}

// ── Category Card ─────────────────────────────────────────────────────────────

class _CategoryCardSkeleton extends StatelessWidget {
  const _CategoryCardSkeleton(this.c);
  final AnimationController c;

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
          // Icon placeholder
          _block(c, width: 40, height: 40, radius: 10),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _block(c, width: 90, height: 14, radius: 6),
                const SizedBox(height: 6),
                _block(c, width: 60, height: 12, radius: 6),
              ],
            ),
          ),
          // Arrow placeholder
          _block(c, width: 18, height: 18, radius: 9),
        ],
      ),
    );
  }
}

// ── Product Detail ────────────────────────────────────────────────────────────

class _ProductDetailSkeleton extends StatelessWidget {
  const _ProductDetailSkeleton(this.c);
  final AnimationController c;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;
    final heroH = isDesktop ? 280.0 : 200.0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero banner
          _block(c, width: double.infinity, height: heroH, radius: 0),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 80 : 24,
              vertical: 32,
            ),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column — main info
                      Expanded(
                        flex: 3,
                        child: _detailLeftColumn(c),
                      ),
                      const SizedBox(width: 40),
                      // Right column — sidebar
                      SizedBox(
                        width: 300,
                        child: _detailRightColumn(c),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailLeftColumn(c),
                      const SizedBox(height: 32),
                      _detailRightColumn(c),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _detailLeftColumn(AnimationController c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category badge
        _block(c, width: 90, height: 22, radius: 11),
        const SizedBox(height: 14),
        // Title
        _block(c, width: double.infinity, height: 28, radius: 8),
        const SizedBox(height: 8),
        _block(c, width: 280, height: 28, radius: 8),
        const SizedBox(height: 24),
        // Description block
        for (int i = 0; i < 4; i++) ...[
          _block(c, width: double.infinity, height: 14, radius: 6),
          const SizedBox(height: 6),
        ],
        _block(c, width: 200, height: 14, radius: 6),
        const SizedBox(height: 28),
        // Image gallery strip
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, __) => _block(c, width: 80, height: 80, radius: 10),
          ),
        ),
      ],
    );
  }

  Widget _detailRightColumn(AnimationController c) {
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
          _block(c, width: 100, height: 14, radius: 6),
          const SizedBox(height: 10),
          _block(c, width: double.infinity, height: 48, radius: 12),
          const SizedBox(height: 14),
          _block(c, width: double.infinity, height: 48, radius: 12),
          const SizedBox(height: 20),
          // Innovator info
          Row(
            children: [
              _block(c, width: 44, height: 44, radius: 22),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _block(c, width: 110, height: 14, radius: 6),
                  const SizedBox(height: 6),
                  _block(c, width: 70, height: 12, radius: 6),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Auth Form ─────────────────────────────────────────────────────────────────

class _AuthFormSkeleton extends StatelessWidget {
  const _AuthFormSkeleton(this.c);
  final AnimationController c;

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
          // Title
          _block(c, width: 180, height: 28, radius: 8),
          const SizedBox(height: 8),
          // Subtitle
          _block(c, width: 240, height: 14, radius: 6),
          const SizedBox(height: 32),
          // Field label 1
          _block(c, width: 80, height: 13, radius: 6),
          const SizedBox(height: 8),
          // Input field 1
          _block(c, width: double.infinity, height: 52, radius: 12),
          const SizedBox(height: 20),
          // Field label 2
          _block(c, width: 80, height: 13, radius: 6),
          const SizedBox(height: 8),
          // Input field 2
          _block(c, width: double.infinity, height: 52, radius: 12),
          const SizedBox(height: 32),
          // Submit button
          _block(c, width: double.infinity, height: 52, radius: 12),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Legacy helpers kept for backward-compat with any existing code that uses
// ShimmerBox / ShimmerCircle / ShimmerText
// ─────────────────────────────────────────────────────────────────────────────

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
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerBlock(
      controller: _ctrl,
      width: widget.width,
      height: widget.height,
      borderRadius: widget.borderRadius,
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
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerBlock(
      controller: _ctrl,
      width: widget.size,
      height: widget.size,
      borderRadius: widget.size / 2,
    );
  }
}

/// Text-line shimmer placeholder (legacy API — prefer ShimmerSkeleton.*).
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
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ShimmerBlock(
      controller: _ctrl,
      width: widget.width,
      height: widget.height,
      borderRadius: 4,
    );
  }
}
