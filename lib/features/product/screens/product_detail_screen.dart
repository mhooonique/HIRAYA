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
import '../../messaging/providers/messaging_provider.dart';
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
  int _activeDeck = 0;
  bool _liked = false;
  bool _bookmarked = false;
  bool _interestSent = false;
  bool _qrExpanded = false;

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
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final maxH = constraints.maxHeight;
                final t = ((maxH - kToolbarHeight) / (340 - kToolbarHeight))
                    .clamp(0.0, 1.0);
                return _buildHero(product, color, t);
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProductDetailSplitLayout(
                    product: product,
                    color: color,
                    activeDeck: _activeDeck,
                    onDeckChange: (i) => setState(() => _activeDeck = i),
                    pageCtrl: _pageCtrl,
                    currentPage: _currentPage,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    onOpenImage: (i) => _openImageViewer(product.images, i),
                    qrExpanded: _qrExpanded,
                    onToggleQr: () => setState(() => _qrExpanded = !_qrExpanded),
                    isLoggedIn: isLoggedIn,
                  ).animate(delay: 120.ms).fadeIn().slideY(begin: 0.08, end: 0),

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

  Widget _buildHero(ProductModel product, Color color, double t) {
    final parallaxY = -24 * (1 - t);
    return Stack(
      children: [
        Positioned.fill(
          child: Transform.translate(
            offset: Offset(0, parallaxY),
            child: product.images.isNotEmpty
                ? _decodedImage(product.images.first)
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.deepVoid,
                          AppColors.richNavy,
                          color.withValues(alpha: 0.30),
                        ],
                      ),
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
                  Colors.black.withValues(alpha: 0.25 + (1 - t) * 0.12),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.78 + (1 - t) * 0.10),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0.16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.6, -0.4),
                  radius: 1.1,
                  colors: [
                    color.withValues(alpha: 0.40),
                    AppColors.golden.withValues(alpha: 0.20),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: -60,
          top: -40,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.golden.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.96, end: 1.06, duration: 2200.ms),
        ),
        Positioned(
          left: -40,
          bottom: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.teal.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.02, end: 0.96, duration: 2600.ms),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - t)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                    const Spacer(),
                    _HeroStatPill(icon: Icons.remove_red_eye_rounded, value: '${product.views}'),
                    const SizedBox(width: 8),
                    _HeroStatPill(icon: Icons.favorite_rounded, value: '${product.likes}'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  product.name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _HeroActionChip(
                      label: 'View Gallery',
                      icon: Icons.photo_library_rounded,
                      color: color,
                      onTap: product.images.isNotEmpty
                          ? () => _openImageViewer(product.images, 0)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    _HeroActionChip(
                      label: 'Scan QR',
                      icon: Icons.qr_code_2_rounded,
                      color: AppColors.golden,
                      onTap: () => setState(() => _qrExpanded = true),
                    ),
                  ],
                ),
              ],
            ),
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

class _ProductQrCard extends StatelessWidget {
  const _ProductQrCard({
    required this.seed,
    required this.color,
    required this.expanded,
    required this.onToggle,
  });

  final String seed;
  final Color color;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.18),
              AppColors.richNavy.withValues(alpha: 0.70),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.18),
              blurRadius: expanded ? 24 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              width: expanded ? 112 : 88,
              height: expanded ? 112 : 88,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: _PseudoQrMatrix(seed: seed),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Interactive Product QR',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    expanded
                        ? 'Tap again to collapse. Share this code for quick access to this innovation profile.'
                        : 'Tap to enlarge QR preview for better scanning and sharing.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.68),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              expanded ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
              color: Colors.white.withValues(alpha: 0.72),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _PseudoQrMatrix extends StatelessWidget {
  const _PseudoQrMatrix({required this.seed});
  final String seed;

  @override
  Widget build(BuildContext context) {
    final hash = seed.codeUnits.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);
    const size = 21;
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: size * size,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: size,
      ),
      itemBuilder: (_, i) {
        final x = i % size;
        final y = i ~/ size;
        final finder = (x < 7 && y < 7) ||
            (x > size - 8 && y < 7) ||
            (x < 7 && y > size - 8);
        final on = finder || (((hash + x * 17 + y * 31) % 7) < 3);
        return Container(
          margin: const EdgeInsets.all(0.15),
          color: on ? Colors.black : Colors.white,
        );
      },
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

class _ProductContentDeck extends StatelessWidget {
  final ProductModel product;
  final Color color;
  final int activeIndex;
  final ValueChanged<int> onTabChange;
  final PageController pageCtrl;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onOpenImage;
  final bool qrExpanded;
  final VoidCallback onToggleQr;

  const _ProductContentDeck({
    required this.product,
    required this.color,
    required this.activeIndex,
    required this.onTabChange,
    required this.pageCtrl,
    required this.currentPage,
    required this.onPageChanged,
    required this.onOpenImage,
    required this.qrExpanded,
    required this.onToggleQr,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const _DeckTabData('Overview', Icons.lightbulb_rounded),
      const _DeckTabData('Gallery', Icons.photo_library_rounded),
      const _DeckTabData('Details', Icons.info_outline_rounded),
      const _DeckTabData('QR', Icons.qr_code_2_rounded),
      const _DeckTabData('Link', Icons.link_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Innovation Content Deck',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Navigate through the core story, visuals, and signals of this innovation.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  tabs.length,
                  (i) => _DeckTab(
                    data: tabs[i],
                    selected: i == activeIndex,
                    color: color,
                    onTap: () => onTabChange(i),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          child: _DeckPanel(
            key: ValueKey(activeIndex),
            product: product,
            color: color,
            activeIndex: activeIndex,
            pageCtrl: pageCtrl,
            currentPage: currentPage,
            onPageChanged: onPageChanged,
            onOpenImage: onOpenImage,
            qrExpanded: qrExpanded,
            onToggleQr: onToggleQr,
          ),
        ),
      ],
    );
  }
}

class _ProductDetailSplitLayout extends StatelessWidget {
  final ProductModel product;
  final Color color;
  final int activeDeck;
  final ValueChanged<int> onDeckChange;
  final PageController pageCtrl;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onOpenImage;
  final bool qrExpanded;
  final VoidCallback onToggleQr;
  final bool isLoggedIn;

  const _ProductDetailSplitLayout({
    required this.product,
    required this.color,
    required this.activeDeck,
    required this.onDeckChange,
    required this.pageCtrl,
    required this.currentPage,
    required this.onPageChanged,
    required this.onOpenImage,
    required this.qrExpanded,
    required this.onToggleQr,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 980;
        final deck = _CinematicDeckPanel(
          title: 'Innovation Storyline',
          subtitle: 'Explore the narrative, visuals, and signals in one flow.',
          color: color,
          child: _ProductContentDeck(
            product: product,
            color: color,
            activeIndex: activeDeck,
            onTabChange: onDeckChange,
            pageCtrl: pageCtrl,
            currentPage: currentPage,
            onPageChanged: onPageChanged,
            onOpenImage: onOpenImage,
            qrExpanded: qrExpanded,
            onToggleQr: onToggleQr,
          ),
        );

        final sidebar = Column(
          children: [
            if (product.status != 'approved')
              _StatusBanner(status: product.status)
                  .animate()
                  .fadeIn(duration: 320.ms)
                  .slideY(begin: 0.08, end: 0),
            const SizedBox(height: 16),
            _InnovatorCard(
              product: product,
              name: product.innovatorName,
              username: product.innovatorUsername,
              color: color,
              isLoggedIn: isLoggedIn,
            )
                .animate()
                .fadeIn(duration: 340.ms, delay: 80.ms)
                .slideY(begin: 0.08, end: 0),
            const SizedBox(height: 16),
            _QuickSignalsCard(product: product, color: color)
                .animate()
                .fadeIn(duration: 360.ms, delay: 140.ms)
                .slideY(begin: 0.08, end: 0),
          ],
        );

        if (!isWide) {
          return Column(
            children: [
              if (product.status != 'approved') ...[
                _StatusBanner(status: product.status),
                const SizedBox(height: 16),
              ],
              _InnovatorCard(
                product: product,
                name: product.innovatorName,
                username: product.innovatorUsername,
                color: color,
                isLoggedIn: isLoggedIn,
              ),
              const SizedBox(height: 24),
              deck,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: deck),
            const SizedBox(width: 20),
            Expanded(flex: 2, child: sidebar),
          ],
        );
      },
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String status;

  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final pending = status == 'pending';
    final color = pending ? AppColors.golden : AppColors.crimson;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: Row(
        children: [
          Icon(
            pending ? Icons.pending_rounded : Icons.cancel_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              pending
                  ? 'This post is pending admin review'
                  : 'This post was rejected by admin',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _InnovatorCard extends ConsumerWidget {
  final ProductModel product;
  final String name;
  final String username;
  final Color color;
  final bool isLoggedIn;

  const _InnovatorCard({
    required this.product,
    required this.name,
    required this.username,
    required this.color,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.18),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'I',
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
                  name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '@$username',
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
            onPressed: () async {
              if (!isLoggedIn) {
                context.push('/login');
                return;
              }
              final user = ref.read(authProvider).user!;
              await ref
                  .read(messagingProvider.notifier)
                  .startOrGetConversation(
                    productId: product.id,
                    productName: product.name,
                    productCategory: product.category,
                    innovatorId: product.innovatorId.toString(),
                    innovatorName: product.innovatorName,
                    clientId: user.id.toString(),
                    clientName: user.fullName,
                  );
              if (context.mounted) context.push('/messaging');
            },
            icon: const Icon(Icons.message_rounded, size: 16),
            label: const Text(
              'Message',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 80.ms).fadeIn();
  }
}

class _QuickSignalsCard extends StatelessWidget {
  final ProductModel product;
  final Color color;

  const _QuickSignalsCard({required this.product, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Signals',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          _SignalRow(label: 'Category', value: product.category, color: color),
          _SignalRow(label: 'KYC', value: product.kycStatus.toUpperCase(), color: AppColors.teal),
          _SignalRow(
            label: 'Listed',
            value: '${product.createdAt.day}/${product.createdAt.month}/${product.createdAt.year}',
            color: AppColors.sky,
          ),
          _SignalRow(label: 'Status', value: product.status.toUpperCase(), color: AppColors.golden),
        ],
      ),
    );
  }
}

class _SignalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SignalRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.50),
              ),
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
          ),
        ],
      ),
    );
  }
}

class _CinematicDeckPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final Widget child;

  const _CinematicDeckPanel({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.14),
                  AppColors.richNavy.withValues(alpha: 0.65),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
          ),
        ),
        Positioned(
          right: -20,
          top: -20,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.golden.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 0.96, end: 1.04, duration: 2200.ms),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.60),
                ),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ],
    );
  }
}

class _DeckTabData {
  final String label;
  final IconData icon;

  const _DeckTabData(this.label, this.icon);
}

class _DeckTab extends StatelessWidget {
  final _DeckTabData data;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _DeckTab({
    required this.data,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = selected ? color : Colors.white.withValues(alpha: 0.45);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.12),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(data.icon, size: 14, color: accent),
            const SizedBox(width: 6),
            Text(
              data.label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckPanel extends StatelessWidget {
  final ProductModel product;
  final Color color;
  final int activeIndex;
  final PageController pageCtrl;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onOpenImage;
  final bool qrExpanded;
  final VoidCallback onToggleQr;

  const _DeckPanel({
    super.key,
    required this.product,
    required this.color,
    required this.activeIndex,
    required this.pageCtrl,
    required this.currentPage,
    required this.onPageChanged,
    required this.onOpenImage,
    required this.qrExpanded,
    required this.onToggleQr,
  });

  @override
  Widget build(BuildContext context) {
    switch (activeIndex) {
      case 1:
        return _DeckCard(
          title: 'Visual Gallery',
          icon: Icons.photo_library_rounded,
          color: color,
          child: product.images.isEmpty
              ? _DeckEmptyState(
                  icon: Icons.image_not_supported_rounded,
                  label: 'No images uploaded yet.',
                )
              : Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 320,
                        child: PageView.builder(
                          controller: pageCtrl,
                          itemCount: product.images.length,
                          onPageChanged: onPageChanged,
                          itemBuilder: (_, index) {
                            try {
                              return GestureDetector(
                                onTap: () => onOpenImage(index),
                                child: Image.memory(
                                  base64Decode(product.images[index]),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              );
                            } catch (_) {
                              return Container(
                                color: color.withValues(alpha: 0.12),
                                child: Icon(Icons.image_rounded,
                                    color: color, size: 40),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        product.images.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: currentPage == i ? 20 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: currentPage == i
                                ? AppColors.golden
                                : Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        );
      case 2:
        return _DeckCard(
          title: 'Innovation Signals',
          icon: Icons.info_outline_rounded,
          color: color,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth < 560 ? 1 : 2;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: crossAxisCount == 1 ? 3.1 : 2.5,
                children: [
                  _DeckDetailChip(Icons.category_rounded, 'Category', product.category, color),
                  _DeckDetailChip(Icons.verified_user_rounded, 'KYC', product.kycStatus.toUpperCase(),
                      product.isVerifiedInnovator ? AppColors.teal : AppColors.golden),
                  _DeckDetailChip(Icons.calendar_today_rounded, 'Listed',
                      '${product.createdAt.day}/${product.createdAt.month}/${product.createdAt.year}',
                      AppColors.sky),
                  _DeckDetailChip(Icons.bar_chart_rounded, 'Status', product.status.toUpperCase(), AppColors.teal),
                ],
              );
            },
          ),
        );
      case 3:
        return _DeckCard(
          title: 'Scan Product QR',
          icon: Icons.qr_code_2_rounded,
          color: color,
          child: _ProductQrCard(
            seed: '${product.id}-${product.name}-${product.category}',
            color: color,
            expanded: qrExpanded,
            onToggle: onToggleQr,
          ),
        );
      case 4:
        return _DeckCard(
          title: 'External Link',
          icon: Icons.link_rounded,
          color: color,
          child: product.externalLink == null || product.externalLink!.isEmpty
              ? _DeckEmptyState(
                  icon: Icons.link_off_rounded,
                  label: 'No external reference added yet.',
                )
              : GestureDetector(
                  onTap: () => launchUrl(Uri.parse(product.externalLink!),
                      mode: LaunchMode.externalApplication),
                  child: _DeckPanelShell(
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
                ),
        );
      default:
        return _DeckCard(
          title: 'About this Innovation',
          icon: Icons.lightbulb_rounded,
          color: color,
          child: Text(
            product.description,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.64),
              height: 1.7,
            ),
          ),
        );
    }
  }
}

class _DeckCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _DeckCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.darkSurface,
            AppColors.richNavy.withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -10,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.95, end: 1.05, duration: 2000.ms),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withValues(alpha: 0.35)),
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatPill extends StatelessWidget {
  final IconData icon;
  final String value;

  const _HeroStatPill({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _HeroActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: onTap == null ? 0.45 : 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeckPanelShell extends StatelessWidget {
  final Widget child;

  const _DeckPanelShell({required this.child});

  @override
  Widget build(BuildContext context) {
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
}

class _DeckDetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DeckDetailChip(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
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

class _DeckEmptyState extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DeckEmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.45), size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
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
