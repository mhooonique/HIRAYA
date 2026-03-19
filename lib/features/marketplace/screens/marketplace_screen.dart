
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/shimmer_skeleton.dart';
import '../providers/marketplace_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/category_filter_bar.dart';
import '../../auth/providers/auth_provider.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  final String? initialCategory;
  const MarketplaceScreen({super.key, this.initialCategory});

  @override
  ConsumerState<MarketplaceScreen> createState() =>
      _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen>
    with TickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final FocusNode _searchFocus = FocusNode();
  double _scrollOffset = 0;
  bool _searchFocused = false;
  bool _filterBarSticky = false;

  // Desktop hero height 300px, mobile 220px
  static const double _heroHeightDesktop = 300.0;
  static const double _heroHeightMobile = 220.0;

  late AnimationController _orbCtrl;
  late Animation<double> _orbAnim;

  late AnimationController _gradientCtrl;
  late Animation<double> _gradientAnim;

  @override
  void initState() {
    super.initState();

    _scrollCtrl.addListener(_onScroll);
    _searchFocus.addListener(
        () => setState(() => _searchFocused = _searchFocus.hasFocus));

    _orbCtrl = AnimationController(
      duration: const Duration(seconds: 7),
      vsync: this,
    )..repeat(reverse: true);
    _orbAnim = CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut);

    _gradientCtrl = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
    _gradientAnim =
        CurvedAnimation(parent: _gradientCtrl, curve: Curves.easeInOut);

    // Apply initial category filter from nav (e.g. /marketplace?category=Agriculture)
    if (widget.initialCategory != null && widget.initialCategory!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(marketplaceProvider.notifier).setCategory(widget.initialCategory!);
      });
    }
  }

  void _onScroll() {
    final offset = _scrollCtrl.offset;
    final w = MediaQuery.of(context).size.width;
    final heroH =
        w > 900 ? _heroHeightDesktop : _heroHeightMobile;
    setState(() {
      _scrollOffset = offset;
      _filterBarSticky = offset > heroH - 10;
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _searchFocus.dispose();
    _orbCtrl.dispose();
    _gradientCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketplaceProvider);
    final notifier = ref.read(marketplaceProvider.notifier);
    final products = state.filtered;
    final auth = ref.watch(authProvider);
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w > 900;

    return Scaffold(
<<<<<<< HEAD
      backgroundColor: AppColors.deepVoid,
      // ── Scroll-to-top FAB ─────────────────────────────────
      floatingActionButton: AnimatedOpacity(
        opacity: _scrollOffset > 300 ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.golden, AppColors.warmEmber],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.golden.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton.small(
            onPressed: () => _scrollCtrl.animateTo(
              0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.keyboard_arrow_up_rounded,
                color: AppColors.navy, size: 22),
          ),
        ).animate().scaleXY(begin: 0.6, end: 1.0, curve: Curves.easeOutBack),
      ),

      body: Stack(
        children: [
          // ── Main scrollable content ──────────────────────
          RefreshIndicator(
            onRefresh: notifier.loadProducts,
            color: AppColors.golden,
            backgroundColor: AppColors.midnight,
            child: CustomScrollView(
              controller: _scrollCtrl,
              slivers: [
                // ── Cinematic HERO section ─────────────────
                SliverToBoxAdapter(
                  child: _HeroSection(
                    orbAnim: _orbAnim,
                    gradientAnim: _gradientAnim,
                    searchCtrl: _searchCtrl,
                    searchFocus: _searchFocus,
                    searchFocused: _searchFocused,
                    onSearch: notifier.setSearch,
                    onClearSearch: () {
                      _searchCtrl.clear();
                      notifier.setSearch('');
                      setState(() {});
                    },
                    selectedCategory: state.selectedCategory,
                    onClearFilters: () {
                      _searchCtrl.clear();
                      notifier.setSearch('');
                      notifier.setCategory('All');
                    },
                    isDesktop: isDesktop,
                    auth: auth,
                    onLogoTap: () => context.go('/'),
                    onSignIn: () => context.go('/login'),
=======
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
leading: IconButton(
  icon: Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Icon(Icons.arrow_back_rounded,
        color: Colors.white, size: 18),
  ),
  onPressed: () {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  },
),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.navy, AppColors.teal],
>>>>>>> origin/master
                  ),
                ),

                // ── Category filter bar (non-sticky position) ──
                SliverToBoxAdapter(
                  child: Container(
                    color: AppColors.deepVoid,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filter bar
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 4),
                          child: CategoryFilterBar(
                            selected: state.selectedCategory,
                            onSelect: notifier.setCategory,
                          ),
                        ),
                        // Product count + sort row
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 4, 20, 12),
                          child: _CountAndSortRow(
                            count: products.length,
                            selectedSort: state.sortBy,
                            onSort: notifier.setSort,
                            hasFilters: state.selectedCategory != 'All' ||
                                state.searchQuery.isNotEmpty,
                            onClearFilters: () {
                              _searchCtrl.clear();
                              notifier.setSearch('');
                              notifier.setCategory('All');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Loading skeleton ───────────────────────
                if (state.isLoading)
                  SliverPadding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: ShimmerSkeleton.productCard(),
                        ),
                        childCount: 6,
                      ),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _crossAxisCount(w),
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.68,
                      ),
                    ),
                  )

                // ── Empty state ────────────────────────────
                else if (products.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyState(
                      hasFilters: state.selectedCategory != 'All' ||
                          state.searchQuery.isNotEmpty,
                      onClearFilters: () {
                        _searchCtrl.clear();
                        notifier.setSearch('');
                        notifier.setCategory('All');
                      },
                    ),
                  )

                // ── Product grid ───────────────────────────
                else
                  SliverPadding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 48),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => ProductCard(
                          product: products[index],
                          index: index,
                        ),
                        childCount: products.length,
                      ),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _crossAxisCount(w),
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.68,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Sticky filter bar (docks to top after scrolling past hero) ──
          if (_filterBarSticky)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _StickyFilterBar(
                selected: state.selectedCategory,
                onSelect: notifier.setCategory,
                count: products.length,
                selectedSort: state.sortBy,
                onSort: notifier.setSort,
                hasFilters: state.selectedCategory != 'All' ||
                    state.searchQuery.isNotEmpty,
                onClearFilters: () {
                  _searchCtrl.clear();
                  notifier.setSearch('');
                  notifier.setCategory('All');
                },
              ).animate().slideY(
                    begin: -0.3,
                    end: 0,
                    duration: 220.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ),
        ],
      ),
    );
  }

  int _crossAxisCount(double w) {
    if (w > 1200) return 4;
    if (w > 800) return 3;
    if (w > 500) return 2;
    return 1;
  }
}

// ═══════════════════════════════════════════════════════════
// HERO SECTION — cinematic 300px desktop / 220px mobile
// ═══════════════════════════════════════════════════════════
class _HeroSection extends StatelessWidget {
  final Animation<double> orbAnim;
  final Animation<double> gradientAnim;
  final TextEditingController searchCtrl;
  final FocusNode searchFocus;
  final bool searchFocused;
  final void Function(String) onSearch;
  final VoidCallback onClearSearch;
  final String selectedCategory;
  final VoidCallback onClearFilters;
  final bool isDesktop;
  final dynamic auth;
  final VoidCallback onLogoTap;
  final VoidCallback onSignIn;

  const _HeroSection({
    required this.orbAnim,
    required this.gradientAnim,
    required this.searchCtrl,
    required this.searchFocus,
    required this.searchFocused,
    required this.onSearch,
    required this.onClearSearch,
    required this.selectedCategory,
    required this.onClearFilters,
    required this.isDesktop,
    required this.auth,
    required this.onLogoTap,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final heroHeight = isDesktop ? 300.0 : 220.0;
    final hPad = isDesktop ? 80.0 : 24.0;

    return AnimatedBuilder(
      animation: Listenable.merge([orbAnim, gradientAnim]),
      builder: (context, _) {
        final o = orbAnim.value;
        final g = gradientAnim.value;

        return SizedBox(
          height: heroHeight,
          child: Stack(
            children: [
              // ── Animated gradient background ─────────────
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(
                            AppColors.deepVoid, AppColors.richNavy, g)!,
                        Color.lerp(AppColors.midnight,
                            const Color(0xFF071E2E), g)!,
                        Color.lerp(
                            AppColors.richNavy, const Color(0xFF0A2240), g)!,
                      ],
                      stops: [0.0, 0.5 + g * 0.15, 1.0],
                    ),
                  ),
                ),
              ),

              // ── Grid texture overlay ──────────────────────
              Positioned.fill(
                child: Opacity(
                  opacity: 0.025,
                  child: CustomPaint(painter: _GridPainter()),
                ),
              ),

              // ── Animated golden orb — top right ──────────
              Positioned(
                right: -50 + o * 25,
                top: -50 + o * 18,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.golden
                            .withValues(alpha: 0.08 + o * 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Animated teal orb — bottom left ──────────
              Positioned(
                left: -30 + o * 12,
                bottom: -20 + o * 22,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.teal.withValues(alpha: 0.07 + o * 0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Floating warm ember orb — center ─────────
              Positioned(
                right: 100 + o * 35,
                bottom: 30 - o * 12,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.warmEmber
                            .withValues(alpha: 0.05 + o * 0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Sky orb — top left ────────────────────────
              Positioned(
                left: 80 + o * 15,
                top: 20 - o * 8,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.sky.withValues(alpha: 0.06 + o * 0.03),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Bottom gradient fade to body ──────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 60,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.deepVoid,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Content ───────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // NavBar row
                    SizedBox(
                      height: 70,
                      child: Row(
                        children: [
                          // Logo
                          GestureDetector(
                            onTap: onLogoTap,
                            child: Row(children: [
                              Image.asset(
                                'assets/images/logo/final-logo.png',
                                height: 32,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Digital Platform',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ]),
                          ),
                          const Spacer(),
                          if (!auth.isLoggedIn)
                            GestureDetector(
                              onTap: onSignIn,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.golden,
                                      AppColors.warmEmber,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.golden
                                          .withValues(alpha: 0.30),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navy,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Hero content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Brand pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.10),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.storefront_rounded,
                                    color: AppColors.golden, size: 12),
                                SizedBox(width: 5),
                                Text(
                                  'INNOVATION MARKETPLACE',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.golden,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 500.ms, delay: 50.ms)
                              .slideX(
                                  begin: -0.15,
                                  end: 0,
                                  curve: Curves.easeOutCubic),
                          const SizedBox(height: 10),

                          // Main title with gradient shader
                          ShaderMask(
                            shaderCallback: (bounds) =>
                                const LinearGradient(
                              colors: [
                                AppColors.golden,
                                AppColors.warmEmber,
                                Colors.white,
                              ],
                              stops: [0.0, 0.45, 1.0],
                            ).createShader(bounds),
                            child: Text(
                              'Explore Innovations',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: isDesktop ? 36 : 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 650.ms, delay: 100.ms)
                              .slideX(
                                  begin: -0.2,
                                  end: 0,
                                  curve: Curves.easeOutCubic),
                          const SizedBox(height: 6),
                          Text(
                            'Discover Filipino innovations ready for the world',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: isDesktop ? 14 : 12,
                              color: Colors.white.withValues(alpha: 0.55),
                              letterSpacing: 0.2,
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 650.ms, delay: 250.ms)
                              .slideX(
                                  begin: -0.15,
                                  end: 0,
                                  curve: Curves.easeOutCubic),
                          const SizedBox(height: 16),

                          // Glass morphism search bar
                          _HeroSearchBar(
                            controller: searchCtrl,
                            focusNode: searchFocus,
                            focused: searchFocused,
                            onChanged: onSearch,
                            onClear: onClearSearch,
                          )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 350.ms)
                              .slideY(
                                  begin: 0.15,
                                  end: 0,
                                  curve: Curves.easeOutCubic),

                          // Active filter chip
                          if (selectedCategory != 'All') ...[
                            const SizedBox(height: 10),
                            _ActiveFilterChip(
                              category: selectedCategory,
                              onRemove: onClearFilters,
                            )
                                .animate()
                                .fadeIn(duration: 300.ms)
                                .scale(
                                    begin: const Offset(0.85, 0.85),
                                    curve: Curves.easeOutBack),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Glass morphism search bar for hero
// ═══════════════════════════════════════════════════════════
class _HeroSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final void Function(String) onChanged;
  final VoidCallback onClear;

  const _HeroSearchBar({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: focused ? 0.10 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focused
              ? AppColors.golden.withValues(alpha: 0.70)
              : Colors.white.withValues(alpha: 0.12),
          width: focused ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: focused
                ? AppColors.golden.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.25),
            blurRadius: focused ? 20 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText: 'Search innovations, innovators...',
          hintStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.30),
          ),
          prefixIcon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              Icons.search_rounded,
              key: ValueKey(focused),
              color: focused
                  ? AppColors.golden
                  : Colors.white.withValues(alpha: 0.40),
              size: 20,
            ),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Active filter chip shown below search bar
// ═══════════════════════════════════════════════════════════
class _ActiveFilterChip extends StatelessWidget {
  final String category;
  final VoidCallback onRemove;

  const _ActiveFilterChip(
      {required this.category, required this.onRemove});

  Color get _color =>
      AppColors.categoryColors[category] ?? AppColors.teal;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list_rounded, size: 12, color: _color),
            const SizedBox(width: 5),
            Text(
              category,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _color,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.close_rounded, size: 12, color: _color),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Count + Sort row
// ═══════════════════════════════════════════════════════════
class _CountAndSortRow extends StatelessWidget {
  final int count;
  final String selectedSort;
  final void Function(String) onSort;
  final bool hasFilters;
  final VoidCallback onClearFilters;

  const _CountAndSortRow({
    required this.count,
    required this.selectedSort,
    required this.onSort,
    required this.hasFilters,
    required this.onClearFilters,
  });

  String get _sortLabel {
    switch (selectedSort) {
      case 'most_liked':
        return 'Most Liked';
      case 'most_viewed':
        return 'Most Viewed';
      case 'most_interest':
        return 'Most Interest';
      default:
        return 'Newest First';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Count badge
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.golden.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: AppColors.golden.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lightbulb_rounded,
                  size: 12, color: AppColors.golden),
              const SizedBox(width: 5),
              Text(
                '$count Innovation${count == 1 ? '' : 's'} Found',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.golden,
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 100.ms)
            .slideX(begin: -0.1, end: 0, curve: Curves.easeOutCubic),

        const Spacer(),

        // Clear filter chip
        if (hasFilters) ...[
          _ClearFilterChip(onTap: onClearFilters),
          const SizedBox(width: 10),
        ],

        // Sort dropdown
        _SortDropdown(
          selected: selectedSort,
          label: _sortLabel,
          onSort: onSort,
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 150.ms)
            .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Sort dropdown with glassmorphism styling
// ═══════════════════════════════════════════════════════════
class _SortDropdown extends StatefulWidget {
  final String selected;
  final String label;
  final void Function(String) onSort;

  const _SortDropdown({
    required this.selected,
    required this.label,
    required this.onSort,
  });

  @override
  State<_SortDropdown> createState() => _SortDropdownState();
}

class _SortDropdownState extends State<_SortDropdown> {
  bool _hovered = false;

  PopupMenuItem<String> _sortItem(
      String value, String label, IconData icon) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.golden),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: PopupMenuButton<String>(
        onSelected: widget.onSort,
        color: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
              color: Colors.white.withValues(alpha: 0.10)),
        ),
        elevation: 8,
        itemBuilder: (_) => [
          _sortItem('newest', 'Newest First',
              Icons.access_time_rounded),
          _sortItem('most_liked', 'Most Liked',
              Icons.favorite_rounded),
          _sortItem('most_viewed', 'Most Viewed',
              Icons.remove_red_eye_rounded),
          _sortItem('most_interest', 'Most Interest',
              Icons.trending_up_rounded),
        ],
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.darkSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered
                  ? AppColors.golden.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.20),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sort_rounded,
                size: 15,
                color: Colors.white.withValues(alpha: 0.65),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.70),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 15,
                color: Colors.white.withValues(alpha: 0.40),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Sticky filter bar — docks to top after hero scrolls away
// ═══════════════════════════════════════════════════════════
class _StickyFilterBar extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;
  final int count;
  final String selectedSort;
  final void Function(String) onSort;
  final bool hasFilters;
  final VoidCallback onClearFilters;

  const _StickyFilterBar({
    required this.selected,
    required this.onSelect,
    required this.count,
    required this.selectedSort,
    required this.onSort,
    required this.hasFilters,
    required this.onClearFilters,
  });

  String get _sortLabel {
    switch (selectedSort) {
      case 'most_liked':
        return 'Most Liked';
      case 'most_viewed':
        return 'Most Viewed';
      case 'most_interest':
        return 'Most Interest';
      default:
        return 'Newest';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.midnight.withValues(alpha: 0.97),
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CategoryFilterBar(
                selected: selected, onSelect: onSelect),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Row(
                children: [
                  Text(
                    '$count found',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.golden.withValues(alpha: 0.80),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (hasFilters) ...[
                    _ClearFilterChip(onTap: onClearFilters),
                    const SizedBox(width: 10),
                  ],
                  _SortDropdown(
                    selected: selectedSort,
                    label: _sortLabel,
                    onSort: onSort,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Empty state illustration
// ═══════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClearFilters;

  const _EmptyState(
      {required this.hasFilters, required this.onClearFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated illustration container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glow ring
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.golden.withValues(alpha: 0.06),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Icon(
                    hasFilters
                        ? Icons.search_off_rounded
                        : Icons.lightbulb_outline_rounded,
                    size: 52,
                    color: Colors.white.withValues(alpha: 0.20),
                  ),
                ],
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(
                    begin: 1.0,
                    end: 1.06,
                    duration: 1600.ms,
                    curve: Curves.easeInOut),
            const SizedBox(height: 24),
            Text(
              hasFilters
                  ? 'No innovations found'
                  : 'No innovations yet',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try a different category or search term'
                  : 'Innovations will appear here once listed',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.40),
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 400.ms)
                .slideY(begin: 0.2, end: 0),
            if (hasFilters) ...[
              const SizedBox(height: 24),
              GestureDetector(
                onTap: onClearFilters,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.golden, AppColors.warmEmber],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.golden.withValues(alpha: 0.30),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Clear Filters',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms)
                  .scale(
                      begin: const Offset(0.85, 0.85),
                      curve: Curves.easeOutBack),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Clear filter chip
// ═══════════════════════════════════════════════════════════
class _ClearFilterChip extends StatefulWidget {
  final VoidCallback onTap;
  const _ClearFilterChip({required this.onTap});

  @override
  State<_ClearFilterChip> createState() => _ClearFilterChipState();
}

class _ClearFilterChipState extends State<_ClearFilterChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.crimson.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.crimson.withValues(alpha: 0.28),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close_rounded,
                  size: 11, color: AppColors.crimson),
              SizedBox(width: 4),
              Text(
                'Clear',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: AppColors.crimson,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn().scale(
        begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
  }
}

// ═══════════════════════════════════════════════════════════
// Grid painter for subtle texture overlay
// ═══════════════════════════════════════════════════════════
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

// ═══════════════════════════════════════════════════════════
// Animated Logo (kept for backwards compatibility)
// ═══════════════════════════════════════════════════════════
class _AnimatedLogo extends StatefulWidget {
  final VoidCallback onTap;
  const _AnimatedLogo({required this.onTap});

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    )..repeat(reverse: true);
    _pulse =
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) => AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.golden.withValues(
                      alpha: (_hovered ? 0.55 : 0.18) * _pulse.value),
                  blurRadius: _hovered ? 26 : 14,
                  spreadRadius: _hovered ? 5 : 1,
                ),
              ],
            ),
            child: AnimatedScale(
              scale: _hovered ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Image.asset(
                'assets/images/logo/final-logo.png',
                height: 34,
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .scaleXY(
            begin: 0.6,
            end: 1.0,
            curve: Curves.easeOutBack,
            duration: 600.ms);
  }
}

// ignore: unused_element
class _AnimatedSignInButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AnimatedSignInButton({required this.onTap});

  @override
  State<_AnimatedSignInButton> createState() =>
      _AnimatedSignInButtonState();
}

class _AnimatedSignInButtonState extends State<_AnimatedSignInButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.golden.withValues(alpha: _hovered ? 1.0 : 0.85),
                AppColors.warmEmber.withValues(alpha: _hovered ? 1.0 : 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.golden
                    .withValues(alpha: _hovered ? 0.45 : 0.25),
                blurRadius: _hovered ? 20 : 10,
              ),
            ],
          ),
          child: const Text(
            'Sign In',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 300.ms)
        .slideX(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }
}

// ignore: unused_element
class _AnimatedNotificationBell extends StatefulWidget {
  final VoidCallback onTap;
  const _AnimatedNotificationBell({required this.onTap});

  @override
  State<_AnimatedNotificationBell> createState() =>
      _AnimatedNotificationBellState();
}

class _AnimatedNotificationBellState
    extends State<_AnimatedNotificationBell>
    with TickerProviderStateMixin {
  late AnimationController _ringCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _ringAnim;
  late Animation<double> _glowAnim;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );
    _ringAnim = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 0.18), weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: 0.18, end: -0.16), weight: 2),
      TweenSequenceItem(
          tween: Tween(begin: -0.16, end: 0.12), weight: 2),
      TweenSequenceItem(
          tween: Tween(begin: 0.12, end: -0.08), weight: 2),
      TweenSequenceItem(
          tween: Tween(begin: -0.08, end: 0.0), weight: 1),
    ]).animate(
        CurvedAnimation(parent: _ringCtrl, curve: Curves.easeInOut));

    _glowCtrl = AnimationController(
      duration: const Duration(milliseconds: 1900),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnim =
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);

    _scheduleAutoRing();
  }

  void _scheduleAutoRing() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 6));
      if (mounted) _ringCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          _ringCtrl.forward(from: 0);
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_ringAnim, _glowAnim]),
          builder: (context, _) => SizedBox(
            width: 44,
            height: 44,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white
                    .withValues(alpha: _hovered ? 0.10 : 0.05),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.golden.withValues(
                        alpha: (_hovered ? 0.40 : 0.12) +
                            _glowAnim.value * 0.15),
                    blurRadius: (_hovered ? 18.0 : 10.0) +
                        _glowAnim.value * 8,
                  ),
                ],
              ),
              child: Transform.rotate(
                angle: _ringAnim.value,
                alignment: Alignment.topCenter,
                child: const Icon(
                  Icons.notifications_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
