import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/api_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../marketplace/providers/marketplace_provider.dart';

final _productDetailProvider =
    FutureProvider.family<ProductModel?, int>((ref, id) async {
  final api = ref.read(apiServiceProvider);
  try {
    final res = await api.get('products/$id', auth: true);
    if (res['success'] == true && res['data'] is Map<String, dynamic>) {
      return ProductModel.fromJson(res['data'] as Map<String, dynamic>);
    }
  } catch (_) {}

  return ref
      .read(marketplaceProvider)
      .products
      .cast<ProductModel?>()
      .firstWhere((p) => p?.id == id, orElse: () => null);
});

class ProductDetailScreen extends ConsumerStatefulWidget {
  final int productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  bool _liked = false;
  bool _bookmarked = false;
  bool _interestSent = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Color _categoryColor(String cat) =>
      AppColors.categoryColors[cat] ?? AppColors.teal;

  void _goBack(String role) {
    if (role == 'admin') {
      context.go('/admin');
    } else if (role == 'innovator') {
      context.go('/innovator/dashboard');
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/marketplace');
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncProduct = ref.watch(_productDetailProvider(widget.productId));
    final auth = ref.watch(authProvider);
    final role = auth.user?.role ?? '';
    final isLoggedIn = auth.isLoggedIn;

    final product = asyncProduct.value;
    if (product == null) {
      return Scaffold(
        backgroundColor: AppColors.deepVoid,
        appBar: AppBar(
          backgroundColor: AppColors.midnight,
          elevation: 0,
          leading: IconButton(
            onPressed: () => _goBack(role),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.golden),
              const SizedBox(height: 12),
              Text(
                'Loading innovation...',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white.withValues(alpha: 0.52),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final color = _categoryColor(product.category);

    return Scaffold(
      backgroundColor: AppColors.deepVoid,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.midnight,
            leading: IconButton(
              onPressed: () => _goBack(role),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => setState(() => _bookmarked = !_bookmarked),
                icon: Icon(
                  _bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                  color: _bookmarked ? AppColors.golden : Colors.white70,
                ),
              ),
              const SizedBox(width: 6),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHero(product, color),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.status != 'approved')
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: product.status == 'pending'
                            ? AppColors.golden.withValues(alpha: 0.10)
                            : AppColors.crimson.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: product.status == 'pending'
                              ? AppColors.golden.withValues(alpha: 0.40)
                              : AppColors.crimson.withValues(alpha: 0.40),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            product.status == 'pending'
                                ? Icons.pending_rounded
                                : Icons.cancel_rounded,
                            color: product.status == 'pending'
                                ? AppColors.golden
                                : AppColors.crimson,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              product.status == 'pending'
                                  ? 'This post is pending admin review'
                                  : 'This post was rejected by admin',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: product.status == 'pending'
                                    ? AppColors.golden
                                    : AppColors.crimson,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(),

                  _panel(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: color.withValues(alpha: 0.18),
                          child: Text(
                            product.innovatorName.isNotEmpty
                                ? product.innovatorName[0].toUpperCase()
                                : 'I',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.innovatorName,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '@${product.innovatorUsername}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.42),
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.go(isLoggedIn ? '/messaging' : '/login'),
                          icon: const Icon(Icons.message_rounded, size: 16),
                          label: const Text('Message'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.teal,
                            side: const BorderSide(color: AppColors.teal),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate(delay: 80.ms).fadeIn(),

                  if (product.images.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionTitle('Gallery', Icons.photo_library_rounded),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 420,
                        child: PageView.builder(
                          controller: _pageCtrl,
                          itemCount: product.images.length,
                          onPageChanged: (index) => setState(() => _currentPage = index),
                          itemBuilder: (_, index) {
                            try {
                              return GestureDetector(
                                onTap: () => _openImageViewer(product.images, index),
                                child: Image.memory(
                                  base64Decode(product.images[index]),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              );
                            } catch (_) {
                              return Container(
                                color: color.withValues(alpha: 0.12),
                                child: Icon(Icons.image_rounded, color: color, size: 40),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        product.images.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentPage == i ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentPage == i
                                ? AppColors.golden
                                : Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  _sectionTitle('About this Innovation', Icons.lightbulb_rounded),
                  const SizedBox(height: 10),
                  _panel(
                    child: Text(
                      product.description,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.64),
                        height: 1.7,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  _sectionTitle('Details', Icons.info_outline_rounded),
                  const SizedBox(height: 10),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                    children: [
                      _detailChip(Icons.category_rounded, 'Category', product.category, color),
                      _detailChip(Icons.verified_user_rounded, 'KYC', product.kycStatus.toUpperCase(),
                          product.isVerifiedInnovator ? AppColors.teal : AppColors.golden),
                      _detailChip(Icons.calendar_today_rounded, 'Listed',
                          '${product.createdAt.day}/${product.createdAt.month}/${product.createdAt.year}',
                          AppColors.sky),
                      _detailChip(Icons.bar_chart_rounded, 'Status', product.status.toUpperCase(), AppColors.teal),
                    ],
                  ),

                  if (product.externalLink != null && product.externalLink!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionTitle('External Link', Icons.link_rounded),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => launchUrl(Uri.parse(product.externalLink!),
                          mode: LaunchMode.externalApplication),
                      child: _panel(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.sky.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.sky.withValues(alpha: 0.2)),
                              ),
                              child: const Icon(Icons.link_rounded, color: AppColors.sky, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                product.externalLink!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: AppColors.sky,
                                ),
                              ),
                            ),
                            Icon(Icons.open_in_new_rounded,
                                color: Colors.white.withValues(alpha: 0.35), size: 16),
                          ],
                        ),
                      ),
                    ).animate(delay: 160.ms).fadeIn(),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isLoggedIn
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: BoxDecoration(
                color: AppColors.midnight,
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      setState(() => _liked = !_liked);
                      final ok = await ref.read(marketplaceProvider.notifier).likeProduct(product.id);
                      if (!ok && mounted) {
                        setState(() => _liked = !_liked);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: _liked
                            ? AppColors.crimson.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _liked
                              ? AppColors.crimson.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: _liked ? AppColors.crimson : Colors.white.withValues(alpha: 0.45),
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${product.likes + (_liked ? 1 : 0)}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: _liked
                                  ? AppColors.crimson
                                  : Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _interestSent
                        ? Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.teal.withValues(alpha: 0.35)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_rounded, color: AppColors.teal, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Interest Sent!',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppColors.teal,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GestureDetector(
                            onTap: () {
                              setState(() => _interestSent = true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Interest expressed! The innovator will be notified.',
                                    style: TextStyle(fontFamily: 'Poppins', color: AppColors.navy),
                                  ),
                                  backgroundColor: AppColors.golden,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.golden, AppColors.warmEmber],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.handshake_rounded, color: AppColors.navy, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Express Interest',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildHero(ProductModel product, Color color) {
    return Stack(
      children: [
        Positioned.fill(
          child: product.images.isNotEmpty
              ? _decodedImage(product.images.first)
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.deepVoid, AppColors.richNavy, color.withValues(alpha: 0.30)],
                    ),
                  ),
                ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.30),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.78),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.45)),
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
              const SizedBox(height: 10),
              Text(
                product.name,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _decodedImage(String image) {
    try {
      return Image.memory(base64Decode(image), fit: BoxFit.cover, width: double.infinity);
    } catch (_) {
      return Container(color: AppColors.richNavy);
    }
  }

  void _openImageViewer(List<String> images, int initialPage) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (_) => _ImageViewer(images: images, initialPage: initialPage),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.golden),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _detailChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
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
                    color: Colors.white.withValues(alpha: 0.38),
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

class _ImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialPage;
  const _ImageViewer({required this.images, required this.initialPage});

  @override
  State<_ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<_ImageViewer> {
  late final PageController _ctrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialPage;
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
        child: Stack(
          children: [
            PageView.builder(
              controller: _ctrl,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) {
                try {
                  return InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 5,
                    child: Center(
                      child: Image.memory(base64Decode(widget.images[i]), fit: BoxFit.contain),
                    ),
                  );
                } catch (_) {
                  return const Center(
                    child: Icon(Icons.broken_image_rounded, color: Colors.white38, size: 64),
                  );
                }
              },
            ),
            Positioned(
              top: 48,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
              ),
            ),
            Positioned(
              top: 56,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_current + 1} / ${widget.images.length}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
