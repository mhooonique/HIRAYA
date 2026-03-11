import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final int index;
  final VoidCallback? onLike;

  const ProductCard({
    super.key,
    required this.product,
    required this.index,
    this.onLike,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with TickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;
  bool _liked = false;

  late AnimationController _likeCtrl;
  late AnimationController _coverCtrl;
  late Animation<double> _coverScale;

  Color get _categoryColor =>
      AppColors.categoryColors[widget.product.category] ??
      AppColors.navy;

  @override
  void initState() {
    super.initState();

    // Heart beat on like
    _likeCtrl = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );

    // Cover zoom on hover
    _coverCtrl = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _coverScale = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _coverCtrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _likeCtrl.dispose();
    _coverCtrl.dispose();
    super.dispose();
  }

  void _onHoverEnter() {
    setState(() => _hovered = true);
    _coverCtrl.forward();
  }

  void _onHoverExit() {
    setState(() => _hovered = false);
    _coverCtrl.reverse();
  }

  void _onLikeTap() {
    HapticFeedback.lightImpact();
    setState(() => _liked = !_liked);
    _likeCtrl.forward(from: 0);
    widget.onLike?.call();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _onHoverEnter(),
      onExit: (_) => _onHoverExit(),
      child: GestureDetector(
        onTap: () => context.go('/product/${widget.product.id}'),
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.975 : 1.0,
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            transform: Matrix4.identity()
              ..translate(0.0, _hovered ? -6.0 : 0.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _hovered
                    ? _categoryColor.withValues(alpha: 0.35)
                    : AppColors.lightGray.withValues(alpha: 0.8),
                width: _hovered ? 1.5 : 1.0,
              ),
              boxShadow: [
                // Base shadow
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                // Colored glow on hover
                if (_hovered)
                  BoxShadow(
                    color: _categoryColor.withValues(alpha: 0.18),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Cover ─────────────────────────────
                  _CoverArea(
                    categoryColor: _categoryColor,
                    categoryIcon: _categoryIcon(widget.product.category),
                    category: widget.product.category,
                    isVerified: widget.product.isVerifiedInnovator,
                    likes: widget.product.likes,
                    liked: _liked,
                    likeCtrl: _likeCtrl,
                    coverScale: _coverScale,
                    onLike: _onLikeTap,
                    hovered: _hovered,
                  ),

                  // ── Content ───────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            widget.product.name,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: _hovered
                                  ? _categoryColor
                                  : AppColors.navy,
                              height: 1.3,
                              letterSpacing: 0.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          // Description
                          Text(
                            widget.product.description,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11.5,
                              color: Colors.black38,
                              height: 1.55,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 11),
                          // Innovator row
                          Row(
                            children: [
                              // Avatar
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      _categoryColor,
                                      _categoryColor.withValues(
                                          alpha: 0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  widget.product.innovatorName
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  widget.product.innovatorName,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black54,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Divider
                          Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _categoryColor.withValues(
                                      alpha: _hovered ? 0.25 : 0.0),
                                  AppColors.lightGray,
                                  _categoryColor.withValues(
                                      alpha: _hovered ? 0.25 : 0.0),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 11),
                          // Stats + CTA row
                          Row(
                            children: [
                              _MiniStat(
                                icon: Icons.remove_red_eye_rounded,
                                value: _formatCount(
                                    widget.product.views),
                                color: Colors.black38,
                              ),
                              const SizedBox(width: 10),
                              _MiniStat(
                                icon: Icons.trending_up_rounded,
                                value: _formatCount(
                                    widget.product.interestCount),
                                color: AppColors.teal,
                              ),
                              const Spacer(),
                              _ViewDetailsButton(
                                color: _categoryColor,
                                hovered: _hovered,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 55 * widget.index))
        .fadeIn(duration: 420.ms, curve: Curves.easeOut)
        .slideY(
            begin: 0.18,
            end: 0,
            duration: 420.ms,
            curve: Curves.easeOutCubic);
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Agriculture':
        return Icons.grass_rounded;
      case 'Healthcare':
        return Icons.medical_services_rounded;
      case 'Energy':
        return Icons.bolt_rounded;
      case 'Construction':
        return Icons.foundation_rounded;
      case 'Product Design':
        return Icons.design_services_rounded;
      case 'Information Technology':
        return Icons.computer_rounded;
      default:
        return Icons.lightbulb_rounded;
    }
  }
}

// ═══════════════════════════════════════════════════════════
// Cover Area — zoom on hover, animated like, verified badge
// ═══════════════════════════════════════════════════════════
class _CoverArea extends StatelessWidget {
  final Color categoryColor;
  final IconData categoryIcon;
  final String category;
  final bool isVerified;
  final int likes;
  final bool liked;
  final AnimationController likeCtrl;
  final Animation<double> coverScale;
  final VoidCallback onLike;
  final bool hovered;

  const _CoverArea({
    required this.categoryColor,
    required this.categoryIcon,
    required this.category,
    required this.isVerified,
    required this.likes,
    required this.liked,
    required this.likeCtrl,
    required this.coverScale,
    required this.onLike,
    required this.hovered,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 168,
      width: double.infinity,
      child: Stack(
        children: [
          // ── Zooming gradient background ──────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: coverScale,
              builder: (context, _) => Transform.scale(
                scale: coverScale.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        categoryColor,
                        Color.lerp(categoryColor, Colors.black, 0.22)!,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Mesh dot pattern
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _DotMeshPainter(),
                        ),
                      ),
                      // Large icon watermark
                      Positioned(
                        right: -18,
                        bottom: -18,
                        child: Icon(
                          categoryIcon,
                          size: 110,
                          color:
                              Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      // Secondary icon top-left decorative
                      Positioned(
                        left: -12,
                        top: -12,
                        child: Icon(
                          categoryIcon,
                          size: 60,
                          color:
                              Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Hover overlay shimmer ─────────────────────
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(
                        alpha: hovered ? 0.18 : 0.08),
                  ],
                ),
              ),
            ),
          ),

          // ── Category badge (top-left) ─────────────────
          Positioned(
            top: 12,
            left: 12,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white
                    .withValues(alpha: hovered ? 0.30 : 0.20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white
                      .withValues(alpha: hovered ? 0.55 : 0.35),
                ),
                boxShadow: hovered
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                        )
                      ]
                    : [],
              ),
              child: Text(
                category,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),

          // ── Verified badge (top-right) ────────────────
          if (isVerified)
            Positioned(
              top: 12,
              right: 12,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: hovered ? AppColors.teal : AppColors.teal,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.45),
                      blurRadius: hovered ? 12 : 4,
                      spreadRadius: hovered ? 1 : 0,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            ),

          // ── Like button (bottom-right) ────────────────
          Positioned(
            bottom: 12,
            right: 12,
            child: GestureDetector(
              onTap: onLike,
              child: AnimatedBuilder(
                animation: likeCtrl,
                builder: (context, _) {
                  final pulse = likeCtrl.isAnimating
                      ? (1.0 +
                          0.35 *
                              (likeCtrl.value < 0.5
                                  ? likeCtrl.value * 2
                                  : (1 - likeCtrl.value) * 2))
                      : 1.0;
                  return Transform.scale(
                    scale: pulse,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: liked
                            ? AppColors.crimson
                            : Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: liked
                              ? AppColors.crimson
                              : Colors.white.withValues(alpha: 0.4),
                          width: 1,
                        ),
                        boxShadow: liked
                            ? [
                                BoxShadow(
                                  color: AppColors.crimson
                                      .withValues(alpha: 0.40),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                )
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${likes + (liked ? 1 : 0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// View Details Button — arrow slides in on hover
// ═══════════════════════════════════════════════════════════
class _ViewDetailsButton extends StatelessWidget {
  final Color color;
  final bool hovered;

  const _ViewDetailsButton({required this.color, required this.hovered});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: hovered ? 13 : 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: hovered
            ? color
            : color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(9),
        boxShadow: hovered
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'View Details',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: hovered ? Colors.white : color,
              letterSpacing: 0.2,
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            child: hovered
                ? Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Mini Stat — compact icon + value row
// ═══════════════════════════════════════════════════════════
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11.5,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Dot Mesh Painter — subtle polka-dot texture on the cover
// ═══════════════════════════════════════════════════════════
class _DotMeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(13)
      ..style = PaintingStyle.fill;
    const spacing = 22.0;
    const radius = 1.5;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotMeshPainter old) => false;
}