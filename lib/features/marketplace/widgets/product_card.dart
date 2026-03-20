import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../client/providers/client_provider.dart';

const _fallbackShareBase = 'https://digitalplatform.app';

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
  bool _actionsHovered = false;

  Color get _categoryColor =>
      AppColors.categoryColors[widget.product.category] ?? AppColors.teal;

  bool get _isDummy => widget.product.id < 0;

  String get _productLink {
    final origin = Uri.base.origin;
    final base = origin.isEmpty ? _fallbackShareBase : origin;
    return '$base/#/product/${widget.product.id}';
  }

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

  Future<void> _onShareTap() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (context) => _ProductShareSheet(
        product: widget.product,
        link: _productLink,
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Agri-Aqua and Forestry':
        return Icons.grass_rounded;
      case 'Food Processing and Nutrition':
        return Icons.restaurant_menu_rounded;
      case 'Health and Medical Sciences':
        return Icons.medical_services_rounded;
      case 'Energy, Utilities, and Environment':
        return Icons.bolt_rounded;
      case 'Advanced Manufacturing and Engineering':
        return Icons.foundation_rounded;
      case 'Creative Industries and Product Design':
        return Icons.design_services_rounded;
      case 'Information and Communications Technology (ICT)':
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
        onTap: () => context.push('/product/${widget.product.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..translate(0.0, effectiveHover ? -8.0 : 0.0, 0.0)
            ..rotateZ(effectiveHover ? 0.01 : 0.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.darkSurface,
                AppColors.richNavy.withValues(alpha: 0.92),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
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
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          catColor.withValues(alpha: 0.04),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: effectiveHover ? 1.0 : 0.0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.02),
                              catColor.withValues(alpha: 0.08),
                              Colors.transparent,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: effectiveHover ? 1.0 : 0.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: catColor.withValues(alpha: 0.45)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 12, color: catColor),
                          const SizedBox(width: 4),
                          Text(
                            'Featured',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.80),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Image/gradient area (170px) ──────────────
                    SizedBox(
                      height: 170,
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
                            // Status badge + verified + rating
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
                                _RatingPill(rating: 4.2),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Product name
                            Text(
                              widget.product.name,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 15,
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
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.55),
                                height: 1.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),

                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _MetaPill(
                                  icon: Icons.remove_red_eye_rounded,
                                  label: 'Views',
                                  value: '${widget.product.views}',
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                                _MetaPill(
                                  icon: Icons.trending_up_rounded,
                                  label: 'Interest',
                                  value: '${widget.product.interestCount}',
                                  color: AppColors.teal,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Innovator row
                            GestureDetector(
                              onTap: () => context
                                  .go('/profile/${widget.product.innovatorId}'),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.midnight.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.10),
                                  ),
                                ),
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
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      widget.product.innovatorName,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.sky,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded,
                                      size: 9, color: AppColors.sky),
                                ]),
                              ),
                            ),

                            const Spacer(),

                            // Divider
                            Divider(
                                height: 1,
                                color: Colors.white.withValues(alpha: 0.07)),
                            const SizedBox(height: 10),

                            // Bottom row: actions + view button
                            Row(children: [
                              MouseRegion(
                                onEnter: (_) => setState(() => _actionsHovered = true),
                                onExit: (_) => setState(() => _actionsHovered = false),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _actionsHovered
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : AppColors.midnight.withValues(alpha: 0.55),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _actionsHovered
                                          ? catColor.withValues(alpha: 0.35)
                                          : Colors.white.withValues(alpha: 0.08),
                                    ),
                                    boxShadow: _actionsHovered
                                        ? [
                                            BoxShadow(
                                              color:
                                                  catColor.withValues(alpha: 0.20),
                                              blurRadius: 10,
                                              offset: const Offset(0, 3),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isClient) ...[
                                        _IconAction(
                                          icon: isWishlisted
                                              ? Icons.bookmark_added_rounded
                                              : Icons.bookmark_add_outlined,
                                          color: isWishlisted
                                              ? AppColors.golden
                                              : Colors.white
                                                  .withValues(alpha: 0.35),
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
                                              : Colors.white
                                                  .withValues(alpha: 0.35),
                                          onTap: _onBookmarkTap,
                                          tooltip: isBookmarked
                                              ? 'Remove bookmark'
                                              : 'Bookmark',
                                        ),
                                        const SizedBox(width: 6),
                                      ],
                                      _IconAction(
                                        icon: Icons.qr_code_2_rounded,
                                        color: Colors.white
                                            .withValues(alpha: 0.70),
                                        onTap: _onShareTap,
                                        tooltip: 'Share via QR or link',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Spacer(),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
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
                                  borderRadius: BorderRadius.circular(10),
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
        Positioned(
          left: 10,
          bottom: 10,
          right: 80,
          child: _SignatureBand(color: _categoryColor),
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
      Positioned(
        left: 10,
        bottom: 10,
        right: 80,
        child: _SignatureBand(color: color),
      ),
    ]);
  }
}

class _SignatureBand extends StatelessWidget {
  final Color color;

  const _SignatureBand({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.0),
            color.withValues(alpha: 0.55),
            AppColors.golden.withValues(alpha: 0.65),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
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

class _ProductShareSheet extends StatelessWidget {
  final ProductModel product;
  final String link;

  const _ProductShareSheet({required this.product, required this.link});

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Product link copied',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _shareLink() async {
    await Share.share(
      '🚀 Check out "${product.name}" on Digital Platform\n\n$link',
      subject: product.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor =
        AppColors.categoryColors[product.category] ?? AppColors.teal;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.midnight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        categoryColor.withValues(alpha: 0.30),
                        categoryColor.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: categoryColor.withValues(alpha: 0.45)),
                  ),
                  child: Icon(Icons.lightbulb_rounded,
                      color: categoryColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.share_rounded, size: 18, color: categoryColor),
              const SizedBox(width: 8),
              const Text(
                'Share Innovation',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 108,
                height: 108,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.lightGray),
                ),
                child: QrImageView(
                  data: link,
                  version: QrVersions.auto,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan to open product page',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.midnight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Text(
                        link,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.72),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ShareActionButton(
                  icon: Icons.link_rounded,
                  label: 'Copy Link',
                  outlined: true,
                  onTap: () => _copyLink(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ShareActionButton(
                  icon: Icons.ios_share_rounded,
                  label: 'Share',
                  onTap: _shareLink,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.08, end: 0);
  }
}

class _ShareActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool outlined;
  final VoidCallback onTap;

  const _ShareActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  @override
  State<_ShareActionButton> createState() => _ShareActionButtonState();
}

class _ShareActionButtonState extends State<_ShareActionButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : (_hovered ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 120),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              gradient: widget.outlined
                  ? null
                  : const LinearGradient(
                      colors: [AppColors.golden, AppColors.warmEmber],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: widget.outlined
                  ? AppColors.midnight
                      .withValues(alpha: _hovered ? 0.85 : 1.0)
                  : null,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.outlined
                    ? Colors.white.withValues(alpha: _hovered ? 0.25 : 0.14)
                    : Colors.transparent,
              ),
              boxShadow: _hovered && !widget.outlined
                  ? [
                      BoxShadow(
                        color: AppColors.golden.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 15,
                  color: widget.outlined
                      ? Colors.white70
                      : AppColors.navy,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: widget.outlined
                        ? Colors.white70
                        : AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── ICON ACTION BUTTON ───────────────────────────────────────────────────────
class _IconAction extends StatefulWidget {
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
  State<_IconAction> createState() => _IconActionState();
}

class _IconActionState extends State<_IconAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              scale: _hovered ? 1.08 : 1.0,
              child: Icon(widget.icon, size: 17, color: widget.color),
            ),
          ),
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

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetaPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.midnight.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  final double rating;

  const _RatingPill({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.midnight.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 12, color: AppColors.golden),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.80),
            ),
          ),
        ],
      ),
    );
  }
}
