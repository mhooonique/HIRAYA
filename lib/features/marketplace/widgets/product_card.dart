import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';
import '../../../core/providers/theme_provider.dart';
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
      AppColors.categoryColors[widget.product.category] ?? AppColors.navy;

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

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isClient = auth.isLoggedIn && auth.user?.role == 'client';
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    // Only watch client state for real products
    final clientState = (isClient && !_isDummy) ? ref.watch(clientProvider) : null;
    final isLiked      = clientState?.likedIds.contains(widget.product.id) ?? false;
    final isWishlisted = clientState?.wishlistIds.contains(widget.product.id) ?? false;
    final isBookmarked = clientState?.bookmarkIds.contains(widget.product.id) ?? false;

    final cardBg      = isDark ? const Color(0xFF1A2233) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A3448) : AppColors.lightGray;
    final nameColor   = isDark ? Colors.white : AppColors.navy;
    final descColor   = isDark ? Colors.white54 : Colors.black45;
    final dividerColor = isDark ? const Color(0xFF2A3448) : AppColors.lightGray;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.push('/product/${widget.product.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..translate(0.0, _hovered ? -4.0 : 0.0),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered
                  ? _categoryColor.withValues(alpha: 0.3)
                  : borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? _categoryColor.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: _hovered ? 20 : 8,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image / gradient
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: widget.product.images.isNotEmpty
                      ? _buildCoverImage(widget.product.images.first,
                          isLiked: isLiked, isClient: isClient)
                      : _buildGradientCover(
                          _categoryColor, widget.product.category,
                          isLiked: isLiked, isClient: isClient),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Demo badge for dummy posts
                    if (_isDummy) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.golden.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.golden.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.science_rounded,
                                color: AppColors.golden, size: 11),
                            SizedBox(width: 4),
                            Text('SHOWCASE',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.golden,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ],

                    Text(
                      widget.product.name,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: nameColor,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.product.description,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: descColor,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Innovator row
                    // Dummy innovators are not clickable (no real profile)
                    GestureDetector(
                      onTap: _isDummy
                          ? null
                          : () => context
                              .go('/profile/${widget.product.innovatorId}'),
                      behavior: HitTestBehavior.opaque,
                      child: Row(children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor:
                              _categoryColor.withValues(alpha: 0.15),
                          child: Text(
                            widget.product.innovatorName
                                .substring(0, 1)
                                .toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _categoryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.product.innovatorName,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _isDummy
                                  ? Colors.black45
                                  : AppColors.sky,
                              decoration: _isDummy
                                  ? TextDecoration.none
                                  : TextDecoration.underline,
                              decorationColor: AppColors.sky,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!_isDummy)
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 10, color: AppColors.sky),
                      ]),
                    ),

                    const SizedBox(height: 10),
                    Divider(height: 1, color: dividerColor),
                    const SizedBox(height: 10),

                    Row(children: [
                      _StatChip(
                        icon: Icons.remove_red_eye_rounded,
                        value: '${widget.product.views}',
                      ),
                      const SizedBox(width: 10),
                      _StatChip(
                        icon: Icons.trending_up_rounded,
                        value: '${widget.product.interestCount}',
                        color: AppColors.teal,
                      ),
                      const Spacer(),

                      // Wishlist + bookmark — real products & clients only
                      if (isClient && !_isDummy) ...[
                        _IconAction(
                          icon: isWishlisted
                              ? Icons.bookmark_added_rounded
                              : Icons.bookmark_add_outlined,
                          color: isWishlisted
                              ? AppColors.golden
                              : Colors.black38,
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
                              : Colors.black38,
                          onTap: _onBookmarkTap,
                          tooltip: isBookmarked
                              ? 'Remove bookmark'
                              : 'Bookmark',
                        ),
                        const SizedBox(width: 8),
                      ],

                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _isDummy ? 'View Showcase' : 'View Details',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _categoryColor,
                          ),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
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
      return Stack(fit: StackFit.expand, children: [
        isUrl
            ? Image.network(
                imageStr,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : Container(
                        color: _categoryColor.withValues(alpha: 0.1),
                        child: Center(
                          child: CircularProgressIndicator(
                              color: _categoryColor, strokeWidth: 2),
                        )),
                errorBuilder: (_, __, ___) => _buildGradientCover(
                    _categoryColor, widget.product.category,
                    isLiked: isLiked, isClient: isClient),
              )
            : Image.memory(base64Decode(imageStr), fit: BoxFit.cover),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3)
                ],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          top: 12, left: 12,
          child: _CategoryBadge(label: widget.product.category),
        ),
        if (widget.product.isVerifiedInnovator)
          Positioned(
            top: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.verified_rounded,
                  color: Colors.white, size: 14),
            ),
          ),
        // Like button — real products only
        if (!_isDummy)
          Positioned(
            bottom: 12, right: 12,
            child: _LikeButton(
              liked: isLiked,
              count: widget.product.likes,
              isClient: isClient,
              onTap: _onLikeTap,
            ),
          )
        else
          // Dummy: show like count but not interactive
          Positioned(
            bottom: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.favorite_rounded,
                    color: Colors.white60, size: 14),
                const SizedBox(width: 4),
                Text('${widget.product.likes}',
                    style: const TextStyle(
                        color: Colors.white60,
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ]),
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
              colors: [color, color.withValues(alpha: 0.7)],
            ),
          ),
        ),
      ),
      Positioned(
        right: -20, bottom: -20,
        child: Icon(_categoryIcon(category),
            size: 120,
            color: Colors.white.withValues(alpha: 0.1)),
      ),
      Positioned(
        top: 12, left: 12,
        child: _CategoryBadge(label: category),
      ),
      if (widget.product.isVerifiedInnovator)
        Positioned(
          top: 12, right: 12,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.verified_rounded,
                color: Colors.white, size: 14),
          ),
        ),
      if (!_isDummy)
        Positioned(
          bottom: 12, right: 12,
          child: _LikeButton(
            liked: isLiked,
            count: widget.product.likes,
            isClient: isClient,
            onTap: _onLikeTap,
          ),
        )
      else
        Positioned(
          bottom: 12, right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.favorite_rounded,
                  color: Colors.white60, size: 14),
              const SizedBox(width: 4),
              Text('${widget.product.likes}',
                  style: const TextStyle(
                      color: Colors.white60,
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
    ]);
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Agriculture':            return Icons.grass_rounded;
      case 'Healthcare':             return Icons.medical_services_rounded;
      case 'Energy':                 return Icons.bolt_rounded;
      case 'Construction':           return Icons.foundation_rounded;
      case 'Product Design':         return Icons.design_services_rounded;
      case 'Information Technology': return Icons.computer_rounded;
      default:                       return Icons.lightbulb_rounded;
    }
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
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: liked
              ? AppColors.crimson
              : isClient
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            liked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: isClient ? Colors.white : Colors.white60,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              color: isClient ? Colors.white : Colors.white60,
              fontFamily: 'Poppins',
              fontSize: 12,
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

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
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
          child: Icon(icon, size: 18, color: color),
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
    this.color = Colors.black38,
  });

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
}