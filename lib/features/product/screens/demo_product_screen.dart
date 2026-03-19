// lib/features/product/screens/demo_product_screen.dart
//
// Shown when user taps a DUMMY product — cinematic showcase view.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;

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
    final secondaryText = Colors.white.withValues(alpha: 0.62);

    return Scaffold(
      backgroundColor: AppColors.deepVoid,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.midnight,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              onPressed: _goBack,
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.science_rounded,
                          color: AppColors.golden,
                          size: 14,
                        ),
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
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHero(product, color),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                MediaQuery.sizeOf(context).width >= 900 ? 28 : 20,
                22,
                MediaQuery.sizeOf(context).width >= 900 ? 28 : 20,
                40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDemoNotice()
                      .animate()
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 1080;

                      if (!isWide) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInnovatorCard(product, color),
                            const SizedBox(height: 16),
                            _buildSnapshotPanel(product, color),
                            const SizedBox(height: 22),
                            _buildGallerySection(product, color),
                            if (product.videoBase64 != null &&
                                product.videoBase64!.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _buildVideoSection(product, color),
                            ],
                            const SizedBox(height: 22),
                            _buildAboutSection(product, secondaryText),
                            if (product.externalLink != null &&
                                product.externalLink!.isNotEmpty) ...[
                              const SizedBox(height: 22),
                              _buildExternalLinkSection(product),
                            ],
                            const SizedBox(height: 22),
                            _buildStatsPanel(product),
                            const SizedBox(height: 22),
                            _buildCallToAction(product, color, secondaryText),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildGallerySection(product, color),
                                if (product.videoBase64 != null &&
                                    product.videoBase64!.isNotEmpty) ...[
                                  const SizedBox(height: 22),
                                  _buildVideoSection(product, color),
                                ],
                                const SizedBox(height: 22),
                                _buildAboutSection(product, secondaryText),
                                if (product.externalLink != null &&
                                    product.externalLink!.isNotEmpty) ...[
                                  const SizedBox(height: 22),
                                  _buildExternalLinkSection(product),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                _buildInnovatorCard(product, color),
                                const SizedBox(height: 14),
                                _buildSnapshotPanel(product, color),
                                const SizedBox(height: 14),
                                _buildStatsPanel(product),
                                const SizedBox(height: 14),
                                _buildCallToAction(
                                  product,
                                  color,
                                  secondaryText,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(ProductModel product, Color color) {
    return Stack(
      children: [
        Positioned.fill(
          child: product.images.isNotEmpty
              ? Image.network(
                  product.images.first,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _heroFallback(color),
                )
              : _heroFallback(color),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.22),
                  Colors.black.withValues(alpha: 0.35),
                  Colors.black.withValues(alpha: 0.82),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          left: -60,
          top: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [color.withValues(alpha: 0.18), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          right: -50,
          bottom: 20,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.golden.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 104, 24, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.42)),
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
              const SizedBox(height: 12),
              Text(
                product.name,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: -0.6,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.08, end: 0),
              const SizedBox(height: 12),
              Wrap(
                spacing: 18,
                runSpacing: 10,
                children: [
                  _HeroStat(
                    icon: Icons.favorite_rounded,
                    value: '${product.likes}',
                    label: 'Likes',
                  ),
                  _HeroStat(
                    icon: Icons.remove_red_eye_rounded,
                    value: '${product.views}',
                    label: 'Views',
                  ),
                  _HeroStat(
                    icon: Icons.trending_up_rounded,
                    value: '${product.interestCount}',
                    label: 'Interests',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroFallback(Color color) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.deepVoid,
            AppColors.richNavy,
            color.withValues(alpha: 0.30),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
    );
  }

  Widget _buildDemoNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.golden.withValues(alpha: 0.12),
            AppColors.warmEmber.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.golden.withValues(alpha: 0.42)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.golden, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'This is a showcase post. Sign in to interact with real innovations.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.golden,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInnovatorCard(ProductModel product, Color color) {
    return _GlassPanel(
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12),
              ],
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: color.withValues(alpha: 0.18),
              child: Text(
                product.innovatorName.isNotEmpty
                    ? product.innovatorName[0].toUpperCase()
                    : 'I',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontSize: 18,
                ),
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
                    color: Colors.white.withValues(alpha: 0.38),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.36)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, color: AppColors.teal, size: 12),
                SizedBox(width: 4),
                Text(
                  'Verified',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.teal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0);
  }

  Widget _buildSnapshotPanel(ProductModel product, Color color) {
    return _GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeading(
                title: 'Innovation Snapshot',
                icon: Icons.auto_awesome_rounded,
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _SnapshotTile(
                    label: 'Category',
                    value: product.category,
                    color: color,
                    icon: Icons.category_rounded,
                  ),
                  _SnapshotTile(
                    label: 'Status',
                    value: 'SHOWCASE',
                    color: AppColors.golden,
                    icon: Icons.stars_rounded,
                  ),
                  _SnapshotTile(
                    label: 'Region',
                    value: 'Philippines',
                    color: AppColors.sky,
                    icon: Icons.location_on_rounded,
                  ),
                  _SnapshotTile(
                    label: 'Audience',
                    value: 'Clients',
                    color: AppColors.teal,
                    icon: Icons.groups_rounded,
                  ),
                ],
              ),
            ],
          ),
        )
        .animate(delay: 80.ms)
        .fadeIn(duration: 380.ms)
        .slideY(begin: 0.06, end: 0);
  }

  Widget _buildGallerySection(ProductModel product, Color color) {
    if (product.images.isEmpty) {
      return const SizedBox.shrink();
    }

    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            title: 'Gallery',
            icon: Icons.photo_library_rounded,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            child: PageView.builder(
              controller: _pageCtrl,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: product.images.length,
              itemBuilder: (_, index) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GestureDetector(
                    onTap: () => _openImagePreview(product.images[index]),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          product.images[index],
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) {
                              return child;
                            }
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: color,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => DecoratedBox(
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                            ),
                            child: Icon(
                              Icons.image_rounded,
                              color: color,
                              size: 42,
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
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.45),
                                ],
                                stops: const [0.55, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ],
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
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == index ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? AppColors.golden
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildVideoSection(ProductModel product, Color color) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            title: 'Video Demo',
            icon: Icons.videocam_rounded,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => launchUrl(
              Uri.parse(product.videoBase64!),
              mode: LaunchMode.externalApplication,
            ),
            child: Container(
              width: double.infinity,
              height: 132,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.82),
                    color.withValues(alpha: 0.45),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.play_circle_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                  SizedBox(width: 14),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Watch Demo Video',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Opens in browser',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 90.ms).fadeIn().slideY(begin: 0.05, end: 0);
  }

  Widget _buildAboutSection(ProductModel product, Color secondaryText) {
    return _GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeading(
                title: 'About this Innovation',
                icon: Icons.lightbulb_rounded,
              ),
              const SizedBox(height: 12),
              Text(
                product.description,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: secondaryText,
                  height: 1.75,
                ),
              ),
            ],
          ),
        )
        .animate(delay: 120.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.04, end: 0);
  }

  Widget _buildExternalLinkSection(ProductModel product) {
    return _GlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(title: 'Learn More', icon: Icons.link_rounded),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => launchUrl(
              Uri.parse(product.externalLink!),
              mode: LaunchMode.externalApplication,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.sky.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.sky.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.open_in_new_rounded,
                    color: AppColors.sky,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      product.externalLink!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.sky,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.42),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: 130.ms).fadeIn(duration: 420.ms);
  }

  Widget _buildStatsPanel(ProductModel product) {
    return _GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeading(
                title: 'Engagement',
                icon: Icons.analytics_rounded,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.favorite_rounded,
                      value: '${product.likes}',
                      label: 'Likes',
                      color: AppColors.crimson,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.remove_red_eye_rounded,
                      value: '${product.views}',
                      label: 'Views',
                      color: AppColors.sky,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricTile(
                      icon: Icons.handshake_rounded,
                      value: '${product.interestCount}',
                      label: 'Interests',
                      color: AppColors.teal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate(delay: 140.ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.04, end: 0);
  }

  Widget _buildCallToAction(
    ProductModel product,
    Color color,
    Color secondaryText,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.18),
            AppColors.richNavy.withValues(alpha: 0.45),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.rocket_launch_rounded, color: color, size: 36),
          const SizedBox(height: 12),
          const Text(
            'Interested in this innovation?',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in to connect with the innovator, express interest, and explore more.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 16),
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
        ],
      ),
    ).animate(delay: 160.ms).fadeIn(duration: 420.ms).slideY(begin: 0.05, end: 0);
  }

  void _openImagePreview(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

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
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.58),
          ),
        ),
      ],
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeading({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.golden),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _SnapshotTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SnapshotTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 13, color: color),
          ),
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
                    color: Colors.white.withValues(alpha: 0.34),
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

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.44),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  final Widget child;

  const _GlassPanel({required this.child});

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
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
