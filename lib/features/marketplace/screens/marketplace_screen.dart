import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/marketplace_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/category_filter_bar.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() =>
      _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(
        () => setState(() => _scrollOffset = _scrollCtrl.offset));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketplaceProvider);
    final notifier = ref.read(marketplaceProvider.notifier);
    final products = state.filtered;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: NestedScrollView(
        controller: _scrollCtrl,
        headerSliverBuilder: (context, innerScrolled) => [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.navy,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.navy, AppColors.teal],
                  ),
                ),
                child: Stack(
                  children: [
                    // Grid texture
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.04,
                        child: CustomPaint(
                            painter: _GridPainter()),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          24, 80, 24, 24),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        mainAxisAlignment:
                            MainAxisAlignment.end,
                        children: [
                          const Text(
                            'Marketplace',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ).animate().fadeIn(duration: 500.ms),
                          const Text(
                            'Discover Filipino innovations',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            title: Row(
              children: [
                GestureDetector(
                  onTap: () => context.go('/'),
                  child: Image.asset(
                    'assets/images/logo/final-logo.png',
                    height: 32,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'HIRAYA',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white),
                onPressed: () {},
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => context.go('/login'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.teal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        body: RefreshIndicator(
          onRefresh: notifier.loadProducts,
          color: AppColors.teal,
          child: CustomScrollView(
            slivers: [
              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      24, 20, 24, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.lightGray),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: notifier.setSearch,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                            decoration: const InputDecoration(
                              hintText:
                                  'Search innovations, innovators...',
                              hintStyle: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: Colors.black26,
                              ),
                              prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: Colors.black38,
                                  size: 20),
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Sort button
                      PopupMenuButton<String>(
                        onSelected: notifier.setSort,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                        child: Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.lightGray),
                          ),
                          child: const Icon(
                              Icons.sort_rounded,
                              color: AppColors.navy,
                              size: 20),
                        ),
                        itemBuilder: (_) => [
                          _sortItem(
                              'newest', 'Newest First',
                              Icons.access_time_rounded),
                          _sortItem(
                              'most_liked', 'Most Liked',
                              Icons.favorite_rounded),
                          _sortItem(
                              'most_viewed', 'Most Viewed',
                              Icons.remove_red_eye_rounded),
                          _sortItem(
                              'most_interest',
                              'Most Interest',
                              Icons.trending_up_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Category filter
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.only(bottom: 16),
                  child: CategoryFilterBar(
                    selected: state.selectedCategory,
                    onSelect: notifier.setCategory,
                  ),
                ),
              ),

              // Stats bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        '${products.length} innovations found',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.black45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      if (state.selectedCategory != 'All' ||
                          state.searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            notifier.setSearch('');
                            notifier.setCategory('All');
                          },
                          child: const Text(
                            'Clear filters',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: AppColors.crimson,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                  child: SizedBox(height: 16)),

              // Loading
              if (state.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.teal),
                  ),
                )
              // Empty
              else if (products.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: AppColors.lightGray),
                        SizedBox(height: 16),
                        Text(
                          'No innovations found',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try a different category or search term',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              // Grid
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      24, 0, 24, 32),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ProductCard(
                        product: products[index],
                        index: index,
                        onLike: () => notifier
                            .likeProduct(products[index].id),
                      ),
                      childCount: products.length,
                    ),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 1200
                              ? 4
                              : MediaQuery.of(context).size.width >
                                      800
                                  ? 3
                                  : MediaQuery.of(context)
                                              .size
                                              .width >
                                          500
                                      ? 2
                                      : 1,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 0.72,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _sortItem(
      String value, String label, IconData icon) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.navy),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Poppins', fontSize: 13)),
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