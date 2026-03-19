import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../client/providers/client_provider.dart';

class ProductCard extends ConsumerStatefulWidget {
  final ProductModel product;
  final int index;

  const ProductCard({
    super.key,
    required this.product,
    required this.index,
  });

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  bool _hovered = false;

  Color get _categoryColor =>
      AppColors.categoryColors[widget.product.category] ?? AppColors.teal;

  bool get _isDummy => widget.product.id < 0;

  bool get _isClient {
    final auth = ref.read(authProvider);
    return auth.isLoggedIn && auth.user?.role == 'client';
  }

  void _onLikeTap() {
    if (_isDummy) return; // no-op for dummy
    if (_isClient) {
      ref.read(clientProvider.notifier).toggleLike(widget.product.id);
    } else {
      context.go('/login');
    }
  }

  void _onWishlistTap() {
    if (_isDummy) return;
    if (_isClient) {
      ref.read(clientProvider.notifier).toggleWishlist(widget.product);
    } else {
      context.go('/login');
    }
  }

  void _onBookmarkTap() {
    if (_isDummy) return;
    if (_isClient) {
      ref.read(clientProvider.notifier).toggleBookmark(widget.product);
    } else {
      context.go('/login');
    }
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

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return 'Available';
      case 'limited':
        return 'Limited';
      case 'patent_pending':
      case 'patent pending':
        return 'Patent Pending';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return AppColors.teal;
      case 'limited':
        return AppColors.golden;
      default:
        return AppColors.sky;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final effectiveHover = _hovered && isDesktop;
    final auth = ref.watch(authProvider);
    final isClient = auth.isLoggedIn && auth.user?.role == 'client';

    final clientState = isClient ? ref.watch(clientProvider) : null;
    final isLiked =
        clientState?.likedIds.contains(widget.product.id) ?? false;
    final isWishlisted =
        clientState?.wishlistIds.contains(widget.product.id) ?? false;
    final isBookmarked =
        clientState?.bookmarkIds.contains(widget.product.id) ?? false;

    final catColor = _categoryColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go('/product/${widget.product.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(
              0.0, effectiveHover ? -8.0 : 0.0, 0.0),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border(
              left: BorderSide(
                color: catColor.withValues(alpha: effectiveHover ? 0.90 : 0.55),
                width: 4,
              ),
              top: BorderSide(
                color: effectiveHover
                    ? catColor.withValues(alpha: 0.45)
                    : AppColors.borderDark,
                width: 1,
              ),
              right: BorderSide(
                color: effectiveHover
                    ? catColor.withValues(alpha: 0.30)
                    : AppColors.borderDark,
                width: 1,
              ),
              bottom: BorderSide(
                color: effectiveHover
                    ? catColor.withValues(alpha: 0.30)
                    : AppColors.borderDark,
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: effectiveHover
                    ? catColor.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.40),
                blurRadius: effectiveHover ? 32 : 12,
                offset: const Offset(0, 8),
                spreadRadius: effectiveHover ? 2 : 0,
              ),
              if (effectiveHover)
                BoxShadow(
                  color: catColor.withValues(alpha: 0.10),
                  blurRadius: 60,
                  offset: const Offset(0, 16),
                  spreadRadius: 4,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image/gradient area (140px) ──────────────
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: widget.product.images.isNotEmpty
                      ? _buildCoverImage(
                          widget.product.images.first,
                          isLiked: isLiked,
                          isClient: isClient,
                        )
                      : _buildGradientCover(
                          catColor,
                          widget.product.category,
                          isLiked: isLiked,
                          isClient: isClient,
                        ),
                ),

                // ── Content ─────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status badge + verified
                        Row(
                          children: [
                            _StatusBadge(
                              label: _statusLabel(widget.product.status),
                              color: _statusColor(widget.product.status),
                            ),
                            if (widget.product.isVerifiedInnovator) ...[
                              const SizedBox(width: 6),
                              _VerifiedBadge(),
                            ],
                            const Spacer(),
                            // Rating stars (static display)
                            _RatingStars(rating: 4.2),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Product name
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.product.description,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.42),
                            height: 1.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),

                        // Innovator row
                        GestureDetector(
                          onTap: () => context
                              .go('/profile/${widget.product.innovatorId}'),
                          behavior: HitTestBehavior.opaque,
                          child: Row(children: [
                            CircleAvatar(
                              radius: 11,
                              backgroundColor:
                                  catColor.withValues(alpha: 0.18),
                              child: Text(
                                widget.product.innovatorName.isNotEmpty
                                    ? widget.product.innovatorName
                                        .substring(0, 1)
                                        .toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: catColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                widget.product.innovatorName,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.sky,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.sky,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                size: 9, color: AppColors.sky),
                          ]),
                        ),

                        const Spacer(),

                        // Divider
                        Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.07)),
                        const SizedBox(height: 10),

                        // Bottom row: stats + actions + view button
                        Row(children: [
                          _StatChip(
                            icon: Icons.remove_red_eye_rounded,
                            value: '${widget.product.views}',
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                          const SizedBox(width: 8),
                          _StatChip(
                            icon: Icons.trending_up_rounded,
                            value: '${widget.product.interestCount}',
                            color: AppColors.teal,
                          ),
                          const Spacer(),

                          // Wishlist + bookmark — client only
                          if (isClient) ...[
                            _IconAction(
                              icon: isWishlisted
                                  ? Icons.bookmark_added_rounded
                                  : Icons.bookmark_add_outlined,
                              color: isWishlisted
                                  ? AppColors.golden
                                  : Colors.white.withValues(alpha: 0.30),
                              onTap: _onWishlistTap,
                              tooltip: isWishlisted
                                  ? 'Remove from wishlist'
                                  : 'Add to wishlist',
                            ),
                            const SizedBox(width: 6),
                            _IconAction(
                              icon: isBookmarked
                                  ? Icons.turned_in_rounded
                                  : Icons.turned_in_not_rounded,
                              color: isBookmarked
                                  ? AppColors.teal
                                  : Colors.white.withValues(alpha: 0.30),
                              onTap: _onBookmarkTap,
                              tooltip: isBookmarked
                                  ? 'Remove bookmark'
                                  : 'Bookmark',
                            ),
                            const SizedBox(width: 8),
                          ],

                          // View Details button — slides in on hover
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: effectiveHover
                                    ? [
                                        AppColors.golden,
                                        AppColors.warmEmber,
                                      ]
                                    : [
                                        AppColors.golden
                                            .withValues(alpha: 0.12),
                                        AppColors.warmEmber
                                            .withValues(alpha: 0.12),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: effectiveHover
                                    ? Colors.transparent
                                    : AppColors.golden
                                        .withValues(alpha: 0.22),
                              ),
                              boxShadow: effectiveHover
                                  ? [
                                      BoxShadow(
                                        color: AppColors.golden
                                            .withValues(alpha: 0.30),
                                        blurRadius: 12,
                                        offset: const Offset(0, 3),
                                      ),
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
                                    fontWeight: FontWeight.w600,
                                    color: effectiveHover
                                        ? AppColors.navy
                                        : AppColors.golden,
                                  ),
                                ),
                                AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 250),
                                  width: effectiveHover ? 14 : 0,
                                  child: effectiveHover
                                      ? Padding(
                                          padding: const EdgeInsets.only(
                                              left: 4),
                                          child: Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 10,
                                            color: AppColors.navy,
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        ]),

                        // Location chip
                        const SizedBox(height: 8),
                        _LocationChip(
                          category: widget.product.category,
                          color: catColor,
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
    )
        .animate(delay: Duration(milliseconds: 60 * widget.index))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }

  Widget _buildCoverImage(String imageStr,
      {required bool isLiked, required bool isClient}) {
    try {
      // URL = dummy product image, base64 = real product image
      final isUrl = imageStr.startsWith('http');
      final bytes = isUrl ? null : base64Decode(imageStr);
      return Stack(fit: StackFit.expand, children: [
        isUrl
            ? Image.network(imageStr, fit: BoxFit.cover)
            : Image.memory(bytes!, fit: BoxFit.cover),
        // Cinematic dark gradient overlay
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.55),
                ],
                stops: const [0.4, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: 10,
          left: 10,
          child: _CategoryBadge(label: widget.product.category),
        ),
        if (widget.product.isVerifiedInnovator)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(7),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.shield_rounded,
                  color: Colors.white, size: 13),
            ),
          ),
        Positioned(
          bottom: 10,
          right: 10,
          child: _LikeButton(
            liked: isLiked,
            count: widget.product.likes,
            isClient: isClient,
            onTap: _onLikeTap,
          ),
        ),
      ]);
    } catch (_) {
      return _buildGradientCover(
          _categoryColor, widget.product.category,
          isLiked: isLiked, isClient: isClient);
    }
  }

  Widget _buildGradientCover(Color color, String category,
      {required bool isLiked, required bool isClient}) {
    return Stack(children: [
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.richNavy,
                color.withValues(alpha: 0.30),
              ],
            ),
          ),
        ),
      ),
      // Subtle category icon watermark
      Positioned(
        right: -14,
        bottom: -14,
        child: Icon(
          _categoryIcon(category),
          size: 100,
          color: color.withValues(alpha: 0.14),
        ),
      ),
      // Accent orb
      Positioned(
        left: -18,
        top: -18,
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.20),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      // Second orb
      Positioned(
        right: 20,
        top: -10,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.golden.withValues(alpha: 0.08),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      Positioned(
        top: 10,
        left: 10,
        child: _CategoryBadge(label: category),
      ),
      if (widget.product.isVerifiedInnovator)
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AppColors.teal,
              borderRadius: BorderRadius.circular(7),
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.shield_rounded,
                color: Colors.white, size: 13),
          ),
        ),
      Positioned(
        bottom: 10,
        right: 10,
        child: _LikeButton(
          liked: isLiked,
          count: widget.product.likes,
          isClient: isClient,
          onTap: _onLikeTap,
        ),
      ),
    ]);
  }
}

// ─── LOCATION CHIP ─────────────────────────────────────────────────────────────
class _LocationChip extends StatelessWidget {
  final String category;
  final Color color;

  const _LocationChip({required this.category, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.location_on_rounded,
          size: 11,
          color: color.withValues(alpha: 0.65),
        ),
        const SizedBox(width: 3),
        Text(
          'Philippines',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.38),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── STATUS BADGE ──────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      );
}

// ─── VERIFIED BADGE ────────────────────────────────────────────────────────────
class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.teal.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(6),
          border:
              Border.all(color: AppColors.teal.withValues(alpha: 0.40)),
          boxShadow: [
            BoxShadow(
              color: AppColors.teal.withValues(alpha: 0.20),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_rounded,
                size: 9, color: AppColors.teal),
            const SizedBox(width: 3),
            Text(
              'Verified',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.teal,
              ),
            ),
          ],
        ),
      );
}

// ─── RATING STARS ──────────────────────────────────────────────────────────────
class _RatingStars extends StatelessWidget {
  final double rating;
  const _RatingStars({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          final filled = i < rating.floor();
          final halfFilled =
              !filled && i < rating && (rating - i) >= 0.5;
          return Icon(
            filled
                ? Icons.star_rounded
                : (halfFilled
                    ? Icons.star_half_rounded
                    : Icons.star_border_rounded),
            size: 11,
            color: filled || halfFilled
                ? AppColors.golden
                : Colors.white.withValues(alpha: 0.20),
          );
        }),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.40),
          ),
        ),
      ],
    );
  }
}

// ─── LIKE BUTTON ──────────────────────────────────────────────────────────────
class _LikeButton extends StatelessWidget {
  final bool liked;
  final int count;
  final bool isClient;
  final VoidCallback onTap;

  const _LikeButton({
    required this.liked,
    required this.count,
    required this.isClient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: liked
              ? AppColors.crimson
              : Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: liked
                ? AppColors.crimson.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.15),
          ),
          boxShadow: liked
              ? [
                  BoxShadow(
                    color: AppColors.crimson.withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
                ]
              : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            liked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: isClient ? Colors.white : Colors.white60,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              color: isClient ? Colors.white : Colors.white60,
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── CATEGORY BADGE ───────────────────────────────────────────────────────────
class _CategoryBadge extends StatelessWidget {
  final String label;
  const _CategoryBadge({required this.label});

  Color get _color =>
      AppColors.categoryColors[label] ?? AppColors.teal;

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _color.withValues(alpha: 0.45)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: label == 'All'
                ? AppColors.golden
                : Colors.white.withValues(alpha: 0.9),
            letterSpacing: 0.4,
          ),
        ),
      );
}

// ─── ICON ACTION BUTTON ───────────────────────────────────────────────────────
class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _IconAction({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Icon(icon, size: 17, color: color),
        ),
      );
}

// ─── STAT CHIP ────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
}
