import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';
import '../../marketplace/providers/marketplace_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketplaceProvider);
    final products = state.products;
    final product = products.isEmpty
        ? null
        : products.cast<ProductModel?>().firstWhere(
            (p) => p?.id == widget.productId,
            orElse: () => null);

    if (product == null) {
      return Scaffold(
        backgroundColor: AppColors.offWhite,
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

    return Scaffold(
      backgroundColor: AppColors.offWhite,
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
              background: Container(
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
                        child: CustomPaint(
                            painter: _GridPainter()),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          24, 100, 24, 24),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        mainAxisAlignment:
                            MainAxisAlignment.end,
                        children: [
                          // Category + KYC
                          Row(
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withValues(alpha: 0.2),
                                  borderRadius:
                                      BorderRadius.circular(20),
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
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.teal,
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.verified_rounded,
                                          color: Colors.white,
                                          size: 12),
                                      SizedBox(width: 4),
                                      Text('Verified',
                                          style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 11,
                                              fontWeight:
                                                  FontWeight.w600,
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
                                  value:
                                      '${product.likes}',
                                  label: 'Likes'),
                              const SizedBox(width: 20),
                              _HeroStat(
                                  icon: Icons
                                      .remove_red_eye_rounded,
                                  value: '${product.views}',
                                  label: 'Views'),
                              const SizedBox(width: 20),
                              _HeroStat(
                                  icon: Icons
                                      .trending_up_rounded,
                                  value:
                                      '${product.interestCount}',
                                  label: 'Interests'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Body content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Innovator card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppColors.lightGray),
                      boxShadow: [
                        BoxShadow(
                          color:
                              Colors.black.withValues(alpha: 0.04),
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
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navy,
                                ),
                              ),
                              Text(
                                '@${product.innovatorUsername}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              context.go('/login'),
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
                  ).animate().fadeIn(duration: 400.ms),

                  const SizedBox(height: 24),

                  // About section
                  const _SectionTitle(title: 'About this Innovation'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppColors.lightGray),
                    ),
                    child: Text(
                      product.description,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.black54,
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

                  const SizedBox(height: 100),
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
          color: Colors.white,
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
                      : AppColors.offWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _liked
                        ? AppColors.crimson
                        : AppColors.lightGray,
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

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.navy,
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
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
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: Colors.black38,
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