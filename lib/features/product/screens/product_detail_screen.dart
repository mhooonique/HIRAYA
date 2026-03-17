import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';
import '../../../core/providers/theme_provider.dart';
import '../../marketplace/providers/marketplace_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/share_qr_section.dart';
import '../../reviews/widgets/reviews_widget.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState
    extends ConsumerState<ProductDetailScreen> {
  bool _liked = false;
  bool _bookmarked = false;
  bool _interestSent = false;

  // Image gallery state
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Color _categoryColor(String category) =>
      AppColors.categoryColors[category] ?? AppColors.navy;

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

  void _openImageViewer(
      BuildContext context, List<String> images, int initialPage) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) =>
          _ImageViewer(images: images, initialPage: initialPage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketplaceProvider);
    final products = state.products;
    final product = products.isEmpty
        ? null
        : products.cast<ProductModel?>().firstWhere(
            (p) => p?.id == widget.productId,
            orElse: () => null);

    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final scaffoldBg   = isDark ? const Color(0xFF0D1117) : AppColors.offWhite;
    final cardBg       = isDark ? const Color(0xFF1A2233) : Colors.white;
    final borderCol    = isDark ? const Color(0xFF2A3448) : AppColors.lightGray;
    final primaryText  = isDark ? Colors.white : AppColors.navy;
    final secondaryText = isDark ? Colors.white54 : Colors.black54;
    final subtleText   = isDark ? Colors.white38 : Colors.black45;

    if (product == null) {
      return Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: AppColors.navy,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go('/marketplace'),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.teal),
        ),
      );
    }

    final color = _categoryColor(product.category);
    final isLoggedIn = ref.watch(authProvider).isLoggedIn;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: color,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 18),
              ),
              onPressed: () => context.go('/marketplace'),
            ),
            actions: [
              // Image count badge
              if (product.images.length > 1)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library_rounded,
                              color: Colors.white, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '${product.images.length}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _bookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    key: ValueKey(_bookmarked),
                    color: Colors.white,
                  ),
                ),
                onPressed: () =>
                    setState(() => _bookmarked = !_bookmarked),
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded,
                    color: Colors.white),
                onPressed: () {},
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: product.images.isNotEmpty
                  ? _buildImageGallery(product, color)
                  : _buildGradientFallback(product, color),
            ),
          ),

          // Body content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Innovator card (clickable)
                  GestureDetector(
                    onTap: () =>
                        context.go('/profile/${product.innovatorId}'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor:
                                color.withValues(alpha: 0.15),
                            child: Text(
                              product.innovatorName
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.innovatorName,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: primaryText,
                                  ),
                                ),
                                Text(
                                  '@${product.innovatorUsername}',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: subtleText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.go(
                                isLoggedIn ? '/messaging' : '/login'),
                            icon: const Icon(
                                Icons.message_rounded,
                                size: 16),
                            label: const Text('Message',
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: color,
                              side: BorderSide(color: color),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms),

                  // Video section
                  if (product.videoBase64 != null &&
                      product.videoBase64!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const _SectionTitle(title: 'Video'),
                    const SizedBox(height: 12),
                    _VideoCard(
                      videoBase64: product.videoBase64!,
                      filename:
                          product.videoFilename ?? 'video.mp4',
                    ),
                  ],

                  const SizedBox(height: 24),

                  // About section
                  const _SectionTitle(
                      title: 'About this Innovation'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderCol),
                    ),
                    child: Text(
                      product.description,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: secondaryText,
                        height: 1.7,
                      ),
                    ),
                  ).animate(delay: 100.ms).fadeIn(),

                  const SizedBox(height: 24),

                  // Details grid
                  const _SectionTitle(title: 'Details'),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                    children: [
                      _DetailChip(
                        icon: Icons.category_rounded,
                        label: 'Category',
                        value: product.category,
                        color: color,
                      ),
                      _DetailChip(
                        icon: Icons.verified_user_rounded,
                        label: 'KYC Status',
                        value: product.kycStatus
                            .toUpperCase(),
                        color: product.isVerifiedInnovator
                            ? AppColors.teal
                            : AppColors.golden,
                      ),
                      _DetailChip(
                        icon: Icons.calendar_today_rounded,
                        label: 'Listed',
                        value:
                            '${product.createdAt.day}/${product.createdAt.month}/${product.createdAt.year}',
                        color: AppColors.sky,
                      ),
                      _DetailChip(
                        icon: Icons.bar_chart_rounded,
                        label: 'Status',
                        value: product.status.toUpperCase(),
                        color: AppColors.teal,
                      ),
                    ],
                  ).animate(delay: 200.ms).fadeIn(),

                  // External link section
                  if (product.externalLink != null &&
                      product.externalLink!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const _SectionTitle(title: 'External Link'),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => launchUrl(
                          Uri.parse(product.externalLink!),
                          mode: LaunchMode.externalApplication),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius:
                              BorderRadius.circular(14),
                          border: Border.all(color: borderCol),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: 0.03),
                                blurRadius: 6)
                          ],
                        ),
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: AppColors.sky
                                    .withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(10)),
                            child: const Icon(
                                Icons.link_rounded,
                                color: AppColors.sky,
                                size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('Learn More',
                                      style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          fontWeight:
                                              FontWeight.w700,
                                          color: primaryText)),
                                  Text(
                                    product.externalLink!,
                                    style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        color: AppColors.sky),
                                    overflow:
                                        TextOverflow.ellipsis,
                                  ),
                                ]),
                          ),
                          const Icon(
                              Icons.open_in_new_rounded,
                              color: Colors.black38,
                              size: 16),
                        ]),
                      ),
                    ).animate(delay: 200.ms).fadeIn(),
                  ],

                  const SizedBox(height: 32),
                  ReviewsSection(productId: product.id),
                  const SizedBox(height: 32),
                  ShareQrSection(product: product),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom action bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: cardBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            )
          ],
        ),
        child: Row(
          children: [
            // Like button
            GestureDetector(
              onTap: () {
                setState(() => _liked = !_liked);
                ref
                    .read(marketplaceProvider.notifier)
                    .likeProduct(product.id);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: _liked
                      ? AppColors.crimson.withValues(alpha: 0.1)
                      : isDark ? const Color(0xFF1A2233) : AppColors.offWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _liked ? AppColors.crimson : borderCol,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: _liked
                          ? AppColors.crimson
                          : Colors.black38,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${product.likes + (_liked ? 1 : 0)}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _liked
                            ? AppColors.crimson
                            : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Express Interest button
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _interestSent
                    ? null
                    : () {
                        setState(
                            () => _interestSent = true);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Interest expressed! The innovator will be notified.',
                              style: TextStyle(
                                  fontFamily: 'Poppins'),
                            ),
                            backgroundColor: AppColors.teal,
                            behavior:
                                SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        10)),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _interestSent
                      ? AppColors.lightGray
                      : color,
                  padding: const EdgeInsets.symmetric(
                      vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12)),
                  elevation: _interestSent ? 0 : 4,
                ),
                icon: Icon(
                  _interestSent
                      ? Icons.check_rounded
                      : Icons.handshake_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                label: Text(
                  _interestSent
                      ? 'Interest Sent!'
                      : 'Express Interest',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery(ProductModel product, Color color) {
    return Stack(children: [
      // PageView of images
      PageView.builder(
        controller: _pageCtrl,
        onPageChanged: (i) => setState(() => _currentPage = i),
        itemCount: product.images.length,
        itemBuilder: (_, i) {
          try {
            return GestureDetector(
              onTap: () =>
                  _openImageViewer(context, product.images, i),
              child: Image.memory(
                base64Decode(product.images[i]),
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            );
          } catch (_) {
            return Container(color: color);
          }
        },
      ),
      // Dark gradient overlay at bottom
      Positioned.fill(
          child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.6)
            ],
            stops: const [0.4, 1.0],
          ),
        ),
      )),
      // Page indicator dots
      if (product.images.length > 1)
        Positioned(
          bottom: 80,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                product.images.length,
                (i) => AnimatedContainer(
                      duration: 200.ms,
                      margin:
                          const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentPage == i ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentPage == i
                            ? Colors.white
                            : Colors.white54,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )),
          ),
        ),
      // Text content at bottom
      _buildHeroContent(product),
    ]);
  }

  Widget _buildGradientFallback(ProductModel product, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.7)],
        ),
      ),
      child: Stack(
        children: [
          // Background icon
          Positioned(
            right: -30,
            bottom: -30,
            child: Opacity(
              opacity: 0.08,
              child: Icon(
                _categoryIcon(product.category),
                size: 250,
                color: Colors.white,
              ),
            ),
          ),
          // Grid texture
          Positioned.fill(
            child: Opacity(
              opacity: 0.04,
              child: CustomPaint(painter: _GridPainter()),
            ),
          ),
          // Text content
          _buildHeroContent(product),
        ],
      ),
    );
  }

  Widget _buildHeroContent(ProductModel product) {
    final color = _categoryColor(product.category);
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(24, 100, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Category + KYC
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white
                          .withValues(alpha: 0.4)),
                ),
                child: Text(
                  product.category,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              if (product.isVerifiedInnovator) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_rounded,
                          color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text('Verified',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Product name
          Text(
            product.name,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ).animate().fadeIn(duration: 500.ms),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              _HeroStat(
                  icon: Icons.favorite_rounded,
                  value: '${product.likes}',
                  label: 'Likes'),
              const SizedBox(width: 20),
              _HeroStat(
                  icon: Icons.remove_red_eye_rounded,
                  value: '${product.views}',
                  label: 'Views'),
              const SizedBox(width: 20),
              _HeroStat(
                  icon: Icons.trending_up_rounded,
                  value: '${product.interestCount}',
                  label: 'Interests'),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Full-screen Image Viewer ──────────────────────────────────────────────────

class _ImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialPage;
  const _ImageViewer(
      {required this.images, required this.initialPage});

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late PageController _ctrl;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _ctrl = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(children: [
          // PageView with pinch-to-zoom
          PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: widget.images.length,
            itemBuilder: (_, i) {
              try {
                return InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5.0,
                  child: Center(
                    child: Image.memory(
                      base64Decode(widget.images[i]),
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              } catch (_) {
                return const Center(
                    child: Icon(Icons.broken_image_rounded,
                        color: Colors.white54, size: 64));
              }
            },
          ),
          // Close button
          Positioned(
            top: 48,
            right: 20,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
          // Page counter
          Positioned(
            top: 56,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentPage + 1} / ${widget.images.length}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Video Card ────────────────────────────────────────────────────────────────

class _VideoCard extends StatelessWidget {
  final String videoBase64;
  final String filename;
  const _VideoCard(
      {required this.videoBase64, required this.filename});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
              ),
            ),
          ),
          // Film strip decoration
          Positioned(
              top: 12,
              left: 12,
              child: Icon(Icons.videocam_rounded,
                  color: Colors.white.withValues(alpha: 0.2),
                  size: 28)),
          // Play button center
          Center(
            child: GestureDetector(
              onTap: () {
                final url = 'data:video/mp4;base64,$videoBase64';
                html.window.open(url, '_blank');
              },
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color:
                            Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white54, width: 2),
                      ),
                      child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 40),
                    ),
                    const SizedBox(height: 12),
                    Text(filename,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Colors.white70)),
                    const SizedBox(height: 4),
                    const Text('Tap to play in browser',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Colors.white38)),
                  ]),
            ),
          ),
        ]),
      ),
    ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.1, end: 0);
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeroStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends ConsumerWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : AppColors.navy,
      ),
    );
  }
}

class _DetailChip extends ConsumerWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final cardBg   = isDark ? const Color(0xFF1A2233) : Colors.white;
    final borderCol = isDark ? const Color(0xFF2A3448) : AppColors.lightGray;
    final labelCol  = isDark ? Colors.white38 : Colors.black38;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: labelCol,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
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
      canvas.drawLine(
          Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
