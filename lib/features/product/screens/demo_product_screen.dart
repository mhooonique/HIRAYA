import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';

class DemoProductScreen extends ConsumerStatefulWidget {
  final ProductModel product;
  const DemoProductScreen({super.key, required this.product});

  @override
  ConsumerState<DemoProductScreen> createState() => _DemoProductScreenState();
}

class _DemoProductScreenState extends ConsumerState<DemoProductScreen> {
  final PageController _pageCtrl = PageController(viewportFraction: 0.88);
  int _currentPage = 0;
  int _activeDeck = 0;
  bool _qrExpanded = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Color _categoryColor(String cat) =>
      AppColors.categoryColors[cat] ?? AppColors.navy;

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/marketplace');
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final color = _categoryColor(product.category);

    return Scaffold(
      backgroundColor: AppColors.deepVoid,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.midnight,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
              ),
              onPressed: _goBack,
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.science_rounded, color: AppColors.golden, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'DEMO',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.golden,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final maxH = constraints.maxHeight;
                final t = ((maxH - kToolbarHeight) / (320 - kToolbarHeight))
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.golden.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.golden.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.golden, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This is a showcase post. Sign in to interact with real innovations.',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.golden),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 20),
                  _DemoProductSplitLayout(
                    product: product,
                    color: color,
                    activeDeck: _activeDeck,
                    onDeckChange: (i) => setState(() => _activeDeck = i),
                    pageCtrl: _pageCtrl,
                    currentPage: _currentPage,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    qrExpanded: _qrExpanded,
                    onToggleQr: () => setState(() => _qrExpanded = !_qrExpanded),
                  ).animate(delay: 120.ms).fadeIn().slideY(begin: 0.08, end: 0),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(ProductModel product, Color color, double t) {
    final parallaxY = -20 * (1 - t);
    return Stack(
      children: [
        Positioned.fill(
          child: Transform.translate(
            offset: Offset(0, parallaxY),
            child: product.images.isNotEmpty
                ? Image.network(product.images.first, fit: BoxFit.cover)
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.deepVoid, AppColors.richNavy, color.withValues(alpha: 0.35)],
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
                  Colors.black.withValues(alpha: 0.18 + (1 - t) * 0.12),
                  Colors.black.withValues(alpha: 0.72 + (1 - t) * 0.10),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: -40,
          top: -30,
          child: Container(
            width: 180,
            height: 180,
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
          left: -30,
          bottom: -40,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.teal.withValues(alpha: 0.16),
                  Colors.transparent,
                ],
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.02, end: 0.96, duration: 2400.ms),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - t)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(18),
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
                    _DemoHeroStatPill(icon: Icons.remove_red_eye_rounded, value: '${product.views}'),
                    const SizedBox(width: 8),
                    _DemoHeroStatPill(icon: Icons.favorite_rounded, value: '${product.likes}'),
                  ],
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 8),
                Container(
                  width: 120,
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, AppColors.golden.withValues(alpha: 0.2)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fadeIn(duration: 900.ms)
                    .scaleX(begin: 0.9, end: 1.05, duration: 1600.ms),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DemoHeroBadge(
                      label: 'KYC',
                      value: product.kycStatus.toUpperCase(),
                      color: product.isVerifiedInnovator
                          ? AppColors.teal
                          : AppColors.golden,
                    ),
                    _DemoHeroBadge(
                      label: 'Status',
                      value: product.status.toUpperCase(),
                      color: AppColors.sky,
                    ),
                    _DemoHeroBadge(
                      label: 'Listed',
                      value: '${product.createdAt.day}/${product.createdAt.month}/${product.createdAt.year}',
                      color: color,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _DemoHeroActionChip(
                      label: 'View Gallery',
                      icon: Icons.photo_library_rounded,
                      color: color,
                      onTap: product.images.isNotEmpty ? () {} : null,
                    ),
                    const SizedBox(width: 10),
                    _DemoHeroActionChip(
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

  Widget _glassCard({required Widget child}) {
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

class _DemoHeroStatPill extends StatelessWidget {
  final IconData icon;
  final String value;

  const _DemoHeroStatPill({required this.icon, required this.value});

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

class _DemoHeroActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _DemoHeroActionChip({
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

class _DemoHeroBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DemoHeroBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 9,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductQrCard extends StatelessWidget {
  const _ProductQrCard({
    required this.qrData,
    required this.color,
    required this.expanded,
    required this.onToggle,
    required this.productRoute,
  });

  final String qrData;
  final Color color;
  final bool expanded;
  final VoidCallback onToggle;
  final String productRoute;

  Future<void> _openLink() async {
    if (qrData.isEmpty) return;
    final uri = Uri.tryParse(qrData);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

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
              AppColors.richNavy.withValues(alpha: 0.72),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: expanded ? 126 : 98,
                  height: expanded ? 126 : 98,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        color.withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 0.9, end: 1.05, duration: 1400.ms)
                    .fadeIn(duration: 600.ms),
                GestureDetector(
                  onTap: _openLink,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    width: expanded ? 112 : 88,
                    height: expanded ? 112 : 88,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      gapless: false,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppColors.navy.withValues(alpha: 0.95),
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.navy.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                ),
              ],
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
                        ? 'Tap again to collapse. Scanning this QR opens this product page directly.'
                        : 'Tap to enlarge. Scan to jump straight to this product section.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.68),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.link_rounded, size: 14, color: color),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Product route: $productRoute',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _openLink,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          foregroundColor: color,
                        ),
                        child: const Text(
                          'Open',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
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

class _DemoProductContentDeck extends StatelessWidget {
  final ProductModel product;
  final Color color;
  final int activeIndex;
  final ValueChanged<int> onTabChange;
  final PageController pageCtrl;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final bool qrExpanded;
  final VoidCallback onToggleQr;

  const _DemoProductContentDeck({
    required this.product,
    required this.color,
    required this.activeIndex,
    required this.onTabChange,
    required this.pageCtrl,
    required this.currentPage,
    required this.onPageChanged,
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
                'Switch between story, visuals, and signals for this demo innovation.',
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
            qrExpanded: qrExpanded,
            onToggleQr: onToggleQr,
          ),
        ),
      ],
    );
  }
}

class _DemoProductSplitLayout extends StatelessWidget {
  final ProductModel product;
  final Color color;
  final int activeDeck;
  final ValueChanged<int> onDeckChange;
  final PageController pageCtrl;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final bool qrExpanded;
  final VoidCallback onToggleQr;

  const _DemoProductSplitLayout({
    required this.product,
    required this.color,
    required this.activeDeck,
    required this.onDeckChange,
    required this.pageCtrl,
    required this.currentPage,
    required this.onPageChanged,
    required this.qrExpanded,
    required this.onToggleQr,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 980;
        final deck = _DemoCinematicDeckPanel(
          title: 'Demo Innovation Storyline',
          subtitle: 'Switch across story, visuals, and signals at a glance.',
          color: color,
          child: _DemoProductContentDeck(
            product: product,
            color: color,
            activeIndex: activeDeck,
            onTabChange: onDeckChange,
            pageCtrl: pageCtrl,
            currentPage: currentPage,
            onPageChanged: onPageChanged,
            qrExpanded: qrExpanded,
            onToggleQr: onToggleQr,
          ),
        );

        final sidebar = Column(
          children: [
            _DemoInnovatorCard(
              name: product.innovatorName,
              username: product.innovatorUsername,
              color: color,
            )
                .animate()
                .fadeIn(duration: 320.ms)
                .slideY(begin: 0.08, end: 0),
            const SizedBox(height: 16),
            _DemoQuickSignals(product: product, color: color)
                .animate()
                .fadeIn(duration: 340.ms, delay: 80.ms)
                .slideY(begin: 0.08, end: 0),
            const SizedBox(height: 16),
            _DemoCtaCard(product: product, color: color)
                .animate()
                .fadeIn(duration: 360.ms, delay: 140.ms)
                .slideY(begin: 0.08, end: 0),
          ],
        );

        if (!isWide) {
          return Column(
            children: [
              _DemoInnovatorCard(
                name: product.innovatorName,
                username: product.innovatorUsername,
                color: color,
              ),
              const SizedBox(height: 20),
              deck,
              const SizedBox(height: 20),
              _DemoCtaCard(product: product, color: color),
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

class _DemoInnovatorCard extends StatelessWidget {
  final String name;
  final String username;
  final Color color;

  const _DemoInnovatorCard({
    required this.name,
    required this.username,
    required this.color,
  });

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
            backgroundColor: color.withValues(alpha: 0.16),
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
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 60.ms).fadeIn();
  }
}

class _DemoQuickSignals extends StatelessWidget {
  final ProductModel product;
  final Color color;

  const _DemoQuickSignals({required this.product, required this.color});

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
          _DemoSignalRow(label: 'Category', value: product.category, color: color),
          _DemoSignalRow(label: 'KYC', value: product.kycStatus.toUpperCase(), color: AppColors.teal),
          _DemoSignalRow(
            label: 'Listed',
            value: '${product.createdAt.day}/${product.createdAt.month}/${product.createdAt.year}',
            color: AppColors.sky,
          ),
          _DemoSignalRow(label: 'Status', value: product.status.toUpperCase(), color: AppColors.golden),
        ],
      ),
    );
  }
}

class _DemoSignalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DemoSignalRow({required this.label, required this.value, required this.color});

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

class _DemoCtaCard extends StatelessWidget {
  final ProductModel product;
  final Color color;

  const _DemoCtaCard({required this.product, required this.color});

  @override
  Widget build(BuildContext context) {
    final videoUrl = product.videoBase64?.trim();
    final hasVideoUrl =
        videoUrl != null && videoUrl.isNotEmpty && videoUrl.startsWith('http');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.16),
            AppColors.richNavy.withValues(alpha: 0.50),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Column(
        children: [
          if (hasVideoUrl) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.play_circle_outline_rounded,
                        size: 16,
                        color: color,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Demo Video URL',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    videoUrl,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      height: 1.35,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse(videoUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(
                        Icons.ondemand_video_rounded,
                        size: 16,
                        color: AppColors.sky,
                      ),
                      label: const Text(
                        'Watch Demo Video',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: AppColors.sky,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          const Text(
            'Interested in this innovation?',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.golden, AppColors.warmEmber],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Sign In to Interact',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ),
          ),
          if (product.externalLink != null && product.externalLink!.isNotEmpty) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => launchUrl(Uri.parse(product.externalLink!), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.sky),
              label: const Text(
                'Open External Reference',
                style: TextStyle(fontFamily: 'Poppins', color: AppColors.sky),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DemoCinematicDeckPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final Widget child;

  const _DemoCinematicDeckPanel({
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
                        height: 240,
                        child: PageView.builder(
                          controller: pageCtrl,
                          itemCount: product.images.length,
                          onPageChanged: onPageChanged,
                          itemBuilder: (context, i) => AnimatedBuilder(
                            animation: pageCtrl,
                            builder: (context, child) {
                              double value = 1.0;
                              if (pageCtrl.hasClients && pageCtrl.page != null) {
                                value = (1 - ((pageCtrl.page! - i).abs() * 0.18))
                                    .clamp(0.82, 1.0);
                              }
                              return Transform.translate(
                                offset: Offset(0, (1 - value) * 12),
                                child: Transform.scale(
                                  scale: value,
                                  child: Opacity(
                                    opacity: (0.55 + value * 0.45)
                                        .clamp(0.0, 1.0),
                                    child: child,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.35),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    product.images[i],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                              ),
                            ),
                          ),
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
              final isCompact = constraints.maxWidth < 560;
              final tileWidth = isCompact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: tileWidth,
                    child: _DemoDetailTile(
                      icon: Icons.category_rounded,
                      title: 'Category Stream',
                      value: product.category,
                      color: color,
                      subtitle: 'Primary innovation field',
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _DemoDetailTile(
                      icon: Icons.verified_user_rounded,
                      title: 'KYC Verified',
                      value: product.kycStatus.toUpperCase(),
                      color: product.isVerifiedInnovator
                          ? AppColors.teal
                          : AppColors.golden,
                      subtitle: product.isVerifiedInnovator
                          ? 'Identity attested'
                          : 'Awaiting verification',
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _DemoDetailTile(
                      icon: Icons.calendar_today_rounded,
                      title: 'Launch Date',
                      value:
                          '${product.createdAt.day}/${product.createdAt.month}/${product.createdAt.year}',
                      color: AppColors.sky,
                      subtitle: 'First listed on platform',
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _DemoDetailTile(
                      icon: Icons.bar_chart_rounded,
                      title: 'Status Signal',
                      value: product.status.toUpperCase(),
                      color: AppColors.teal,
                      subtitle: 'Live market momentum',
                    ),
                  ),
                ],
              );
            },
          ),
        );
      case 3:
        final productRoute = '/product/${product.id}';
        final isHttpHost =
            Uri.base.scheme == 'http' || Uri.base.scheme == 'https';
        final qrTargetUrl = isHttpHost
            ? '${Uri.base.origin}/#${productRoute}'
            : 'https://hiraya.app$productRoute';

        return _DeckCard(
          title: 'Scan Product QR',
          icon: Icons.qr_code_2_rounded,
          color: color,
          child: _ProductQrCard(
            qrData: qrTargetUrl,
            color: color,
            expanded: qrExpanded,
            onToggle: onToggleQr,
            productRoute: productRoute,
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
              color: Colors.white.withValues(alpha: 0.62),
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
      child: Column(
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
    );
  }
}

class _DemoDetailTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _DemoDetailTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.14),
            AppColors.darkSurface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.06, end: 0);
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
