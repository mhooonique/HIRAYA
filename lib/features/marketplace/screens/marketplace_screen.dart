import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/marketplace_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/category_filter_bar.dart';
import '../widgets/marketplace_skeleton.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

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

  late AnimationController _headerGradientCtrl;
  late Animation<double> _headerGradientAnim;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(
        () => setState(() => _scrollOffset = _scrollCtrl.offset));
    _searchFocus.addListener(
        () => setState(() => _searchFocused = _searchFocus.hasFocus));

    _headerGradientCtrl = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    _headerGradientAnim = CurvedAnimation(
      parent: _headerGradientCtrl,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _searchFocus.dispose();
    _headerGradientCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketplaceProvider);
    final notifier = ref.read(marketplaceProvider.notifier);
    final products = state.filtered;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      floatingActionButton: AnimatedOpacity(
        opacity: _scrollOffset > 220 ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: FloatingActionButton.small(
          onPressed: () => _scrollCtrl.animateTo(
            0,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
          ),
          backgroundColor: AppColors.navy,
          elevation: 6,
          child: const Icon(Icons.keyboard_arrow_up_rounded,
              color: Colors.white, size: 22),
        )
            .animate()
            .scaleXY(
                begin: 0.6,
                end: 1.0,
                curve: Curves.easeOutBack),
      ),
      body: NestedScrollView(
        controller: _scrollCtrl,
        headerSliverBuilder: (context, innerScrolled) => [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            elevation: _scrollOffset > 10 ? 10 : 0,
            shadowColor: AppColors.navy.withValues(alpha: 0.45),
            backgroundColor: AppColors.navy,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: AnimatedBuilder(
                animation: _headerGradientAnim,
                builder: (context, _) {
                  final t = _headerGradientAnim.value;
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(AppColors.navy,
                              const Color(0xFF06314F), t)!,
                          Color.lerp(AppColors.teal,
                              const Color(0xFF0F7A6E), t)!,
                          Color.lerp(
                              const Color(0xFF0B526A),
                              AppColors.navy,
                              t)!,
                        ],
                        stops: [0.0, 0.55 + t * 0.2, 1.0],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Animated grid texture
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.05,
                            child: CustomPaint(
                                painter: _GridPainter()),
                          ),
                        ),
                        // Floating decorative orb — top-right
                        Positioned(
                          right: -50,
                          top: -50,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.teal
                                  .withValues(
                                      alpha: 0.07 + t * 0.07),
                            ),
                          ),
                        ),
                        // Floating decorative orb — bottom-left
                        Positioned(
                          left: -30,
                          bottom: 10,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(
                                  alpha: 0.03 + t * 0.04),
                            ),
                          ),
                        ),

                        // Header text
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(
                                  24, 80, 24, 28),
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
                                  letterSpacing: 0.5,
                                ),
                              )
                                  .animate()
                                  .fadeIn(
                                      duration: 650.ms,
                                      delay: 100.ms)
                                  .slideX(
                                      begin: -0.25,
                                      end: 0,
                                      curve:
                                          Curves.easeOutCubic),
                              const SizedBox(height: 4),
                              const Text(
                                'Discover Filipino innovations',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: Colors.white60,
                                  letterSpacing: 0.3,
                                ),
                              )
                                  .animate()
                                  .fadeIn(
                                      duration: 650.ms,
                                      delay: 280.ms)
                                  .slideX(
                                      begin: -0.2,
                                      end: 0,
                                      curve:
                                          Curves.easeOutCubic),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // ── NavBar: Logo + Title ──────────────────────
            title: Row(
              children: [
                _AnimatedLogo(onTap: () => context.go('/')),
                const SizedBox(width: 10),
                const Text(
                  'HIRAYA',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 2.5,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 550.ms, delay: 150.ms)
                    .slideX(
                        begin: -0.1,
                        end: 0,
                        curve: Curves.easeOutCubic),
              ],
            ),
            // ── NavBar: Actions ───────────────────────────
            actions: [
              _AnimatedNotificationBell(onTap: () {}),
              const SizedBox(width: 8),
              _AnimatedSignInButton(
                  onTap: () => context.go('/login')),
              const SizedBox(width: 12),
            ],
          ),
        ],
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 420),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: child,
          ),
          child: state.isLoading
              ? const MarketplaceSkeleton()
              : RefreshIndicator(
          key: const ValueKey('content'),
          onRefresh: notifier.loadProducts,
          color: AppColors.teal,
          child: CustomScrollView(
            slivers: [
              // ── Search + Sort ──────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      24, 20, 24, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(14),
                            border: Border.all(
                              color: _searchFocused
                                  ? AppColors.teal
                                  : AppColors.lightGray,
                              width: _searchFocused ? 2.0 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _searchFocused
                                    ? AppColors.teal
                                        .withValues(alpha: 0.18)
                                    : Colors.black
                                        .withValues(alpha: 0.04),
                                blurRadius:
                                    _searchFocused ? 18 : 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchCtrl,
                            focusNode: _searchFocus,
                            onChanged: notifier.setSearch,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'Search innovations, innovators...',
                              hintStyle: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: Colors.black26,
                              ),
                              prefixIcon: AnimatedSwitcher(
                                duration: const Duration(
                                    milliseconds: 200),
                                transitionBuilder:
                                    (child, anim) =>
                                        ScaleTransition(
                                            scale: anim,
                                            child: child),
                                child: Icon(
                                  Icons.search_rounded,
                                  key:
                                      ValueKey(_searchFocused),
                                  color: _searchFocused
                                      ? AppColors.teal
                                      : Colors.black38,
                                  size: 20,
                                ),
                              ),
                              suffixIcon:
                                  _searchCtrl.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                              Icons.close_rounded,
                                              size: 18,
                                              color:
                                                  Colors.black38),
                                          onPressed: () {
                                            _searchCtrl.clear();
                                            notifier
                                                .setSearch('');
                                            setState(() {});
                                          },
                                        )
                                      : null,
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(
                                duration: 500.ms, delay: 200.ms)
                            .slideY(
                                begin: 0.12,
                                end: 0,
                                curve: Curves.easeOutCubic),
                      ),
                      const SizedBox(width: 10),
                      // Sort button
                      PopupMenuButton<String>(
                        onSelected: notifier.setSort,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14)),
                        elevation: 4,
                        child: AnimatedContainer(
                          duration:
                              const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.lightGray),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                              Icons.sort_rounded,
                              color: AppColors.navy,
                              size: 20),
                        )
                            .animate()
                            .fadeIn(
                                duration: 500.ms, delay: 300.ms)
                            .slideY(
                                begin: 0.12,
                                end: 0,
                                curve: Curves.easeOutCubic),
                        itemBuilder: (_) => [
                          _sortItem(
                              'newest',
                              'Newest First',
                              Icons.access_time_rounded),
                          _sortItem('most_liked', 'Most Liked',
                              Icons.favorite_rounded),
                          _sortItem(
                              'most_viewed',
                              'Most Viewed',
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

              // ── Category filter ──────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CategoryFilterBar(
                    selected: state.selectedCategory,
                    onSelect: notifier.setCategory,
                  ),
                ),
              ),

              // ── Animated Stats Strip ─────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      24, 0, 24, 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.navy.withValues(alpha: 0.06),
                          AppColors.teal.withValues(alpha: 0.04),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.navy
                            .withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        _StatChip(
                          icon: Icons.lightbulb_rounded,
                          label: '${products.length}',
                          sublabel: 'innovations',
                          color: AppColors.teal,
                        ),
                        const _StatDivider(),
                        const _StatChip(
                          icon: Icons.people_rounded,
                          label: '120+',
                          sublabel: 'innovators',
                          color: AppColors.navy,
                        ),
                        const _StatDivider(),
                        const _StatChip(
                          icon: Icons.category_rounded,
                          label: '6',
                          sublabel: 'categories',
                          color: AppColors.sky,
                        ),
                        const Spacer(),
                        if (state.selectedCategory != 'All' ||
                            state.searchQuery.isNotEmpty)
                          _ClearFilterChip(
                            onTap: () {
                              _searchCtrl.clear();
                              notifier.setSearch('');
                              notifier.setCategory('All');
                            },
                          ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 150.ms)
                    .slideY(
                        begin: 0.1,
                        end: 0,
                        curve: Curves.easeOutCubic),
              ),

              // ── (legacy stats bar placeholder — kept for alignment) ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24),
                  child: Row(
                    children: [
                      const Spacer(),
                      if (false) // handled above
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.crimson
                                  .withValues(alpha: 0.08),
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.close_rounded,
                                    size: 14,
                                    color: AppColors.crimson),
                                SizedBox(width: 4),
                                Text(
                                  'Clear filters',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: AppColors.crimson,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn()
                            .scale(
                                begin: const Offset(0.8, 0.8),
                                curve: Curves.easeOutBack),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // ── Loading ──────────────────────────────────
              if (state.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.teal),
                  ),
                )
              // ── Empty state ──────────────────────────────
              else if (products.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: AppColors.lightGray,
                        )
                            .animate(
                                onPlay: (c) =>
                                    c.repeat(reverse: true))
                            .scaleXY(
                                begin: 1.0,
                                end: 1.08,
                                duration: 1500.ms,
                                curve: Curves.easeInOut),
                        const SizedBox(height: 16),
                        const Text(
                          'No innovations found',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        )
                            .animate()
                            .fadeIn()
                            .slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 8),
                        const Text(
                          'Try a different category or search term',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Colors.black38,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 100.ms)
                            .slideY(begin: 0.2, end: 0),
                      ],
                    ),
                  ),
                )
              // ── Product Grid ─────────────────────────────
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
                      crossAxisCount: MediaQuery.of(context)
                                  .size
                                  .width >
                              1200
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

// ═══════════════════════════════════════════════════════════
// Stat Chip — used in the animated metrics strip
// ═══════════════════════════════════════════════════════════
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 13, color: color),
        ),
        const SizedBox(width: 7),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1.1,
              ),
            ),
            Text(
              sublabel,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: Colors.black38,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 450.ms)
        .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic);
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: 1,
      height: 28,
      color: AppColors.lightGray,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Clear Filter Chip — animated entrance + press effect
// ═══════════════════════════════════════════════════════════
class _ClearFilterChip extends StatefulWidget {
  final VoidCallback onTap;
  const _ClearFilterChip({required this.onTap});

  @override
  State<_ClearFilterChip> createState() =>
      _ClearFilterChipState();
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
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.crimson.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.crimson.withValues(alpha: 0.25),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close_rounded,
                  size: 13, color: AppColors.crimson),
              SizedBox(width: 5),
              Text(
                'Clear filters',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.crimson,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn()
        .scale(
            begin: const Offset(0.8, 0.8),
            curve: Curves.easeOutBack);
  }
}

// ═══════════════════════════════════════════════════════════
// Animated Logo — pulse glow, hover scale, entrance animation
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
    _pulse = CurvedAnimation(
        parent: _pulseCtrl, curve: Curves.easeInOut);
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
                  color: AppColors.teal.withValues(
                      alpha: (_hovered ? 0.65 : 0.22) *
                          _pulse.value),
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

// ═══════════════════════════════════════════════════════════
// Animated Notification Bell — swing, badge bounce, glow pulse
// ═══════════════════════════════════════════════════════════
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
  late AnimationController _badgeCtrl;
  late AnimationController _glowCtrl;
  late AnimationController _rippleCtrl;

  late Animation<double> _ringAnim;
  late Animation<double> _badgeScale;
  late Animation<double> _glowAnim;
  late Animation<double> _rippleAnim;

  bool _pressed = false;
  bool _hovered = false;
  final int _count = 3;

  @override
  void initState() {
    super.initState();

    // Bell swing
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
    ]).animate(CurvedAnimation(
        parent: _ringCtrl, curve: Curves.easeInOut));

    // Badge entrance
    _badgeCtrl = AnimationController(
      duration: const Duration(milliseconds: 550),
      vsync: this,
    );
    _badgeScale = CurvedAnimation(
        parent: _badgeCtrl, curve: Curves.elasticOut);
    Future.delayed(const Duration(milliseconds: 900),
        () => mounted ? _badgeCtrl.forward() : null);

    // Glow pulse
    _glowCtrl = AnimationController(
      duration: const Duration(milliseconds: 1900),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(
        parent: _glowCtrl, curve: Curves.easeInOut);

    // Tap ripple
    _rippleCtrl = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: this,
    );
    _rippleAnim = CurvedAnimation(
        parent: _rippleCtrl, curve: Curves.easeOut);

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
    _badgeCtrl.dispose();
    _glowCtrl.dispose();
    _rippleCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _ringCtrl.forward(from: 0);
    _rippleCtrl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _handleTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.85 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedBuilder(
            animation: Listenable.merge(
                [_ringAnim, _glowAnim, _rippleAnim]),
            builder: (context, _) {
              return SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Ripple ring on tap
                    if (_rippleAnim.value > 0)
                      Positioned.fill(
                        child: Opacity(
                          opacity:
                              (1 - _rippleAnim.value) * 0.6,
                          child: Transform.scale(
                            scale:
                                1.0 + _rippleAnim.value * 1.4,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.teal,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Glow + bell
                    AnimatedContainer(
                      duration:
                          const Duration(milliseconds: 200),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(
                            alpha: _hovered ? 0.15 : 0.08),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal.withValues(
                                alpha:
                                    (_hovered ? 0.45 : 0.18) +
                                        _glowAnim.value * 0.18),
                            blurRadius: (_hovered ? 18 : 10) +
                                _glowAnim.value * 8,
                            spreadRadius: _hovered ? 2 : 0,
                          ),
                        ],
                      ),
                      child: Transform.rotate(
                        angle: _ringAnim.value,
                        alignment: Alignment.topCenter,
                        child: Icon(
                          Icons.notifications_rounded,
                          color: Colors.white,
                          size: 22,
                          shadows: [
                            Shadow(
                              color: AppColors.teal
                                  .withValues(alpha: 0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Badge
                    Positioned(
                      top: 2,
                      right: 2,
                      child: ScaleTransition(
                        scale: _badgeScale,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.crimson,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.crimson
                                    .withValues(alpha: 0.55),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$_count',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 250.ms)
        .slideX(
            begin: 0.2,
            end: 0,
            curve: Curves.easeOutCubic,
            duration: 600.ms);
  }
}

// ═══════════════════════════════════════════════════════════
// Animated Sign In Button — shimmer sweep, glow, hover scale
// ═══════════════════════════════════════════════════════════
class _AnimatedSignInButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AnimatedSignInButton({required this.onTap});

  @override
  State<_AnimatedSignInButton> createState() =>
      _AnimatedSignInButtonState();
}

class _AnimatedSignInButtonState
    extends State<_AnimatedSignInButton>
    with TickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _shimmerAnim;
  late Animation<double> _glowAnim;
  bool _hovered = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _shimmerAnim = CurvedAnimation(
        parent: _shimmerCtrl, curve: Curves.easeInOut);

    _glowCtrl = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(
        parent: _glowCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
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
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.91 : (_hovered ? 1.06 : 1.0),
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutBack,
          child: AnimatedBuilder(
            animation: Listenable.merge(
                [_shimmerAnim, _glowAnim]),
            builder: (context, _) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _hovered
                        ? [
                            const Color(0xFF1A9E8F),
                            AppColors.teal,
                          ]
                        : [
                            AppColors.teal,
                            AppColors.teal
                                .withValues(alpha: 0.85),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(
                        alpha: 0.12 +
                            _shimmerAnim.value * 0.28),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withValues(
                          alpha: (_hovered ? 0.60 : 0.22) +
                              _glowAnim.value * 0.18),
                      blurRadius: _hovered
                          ? 22
                          : 10 + _glowAnim.value * 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Shimmer sweep
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(8),
                        child: Opacity(
                          opacity: 0.22,
                          child: Transform.translate(
                            offset: Offset(
                              -90 +
                                  (_shimmerAnim.value * 180),
                              0,
                            ),
                            child: Container(
                              width: 40,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(
                                        alpha: 0),
                                    Colors.white.withValues(
                                        alpha: 0.9),
                                    Colors.white.withValues(
                                        alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Label
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.login_rounded,
                            color: Colors.white, size: 15),
                        const SizedBox(width: 6),
                        const Text(
                          'Sign In',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: 13,
                            letterSpacing: 0.4,
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(
                              milliseconds: 200),
                          child: _hovered
                              ? const Padding(
                                  padding: EdgeInsets.only(
                                      left: 4),
                                  child: Icon(
                                    Icons
                                        .arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 13,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 650.ms, delay: 300.ms)
        .slideX(
            begin: 0.25,
            end: 0,
            curve: Curves.easeOutCubic,
            duration: 650.ms);
  }
}

// ═══════════════════════════════════════════════════════════
// Grid Background Painter
// ═══════════════════════════════════════════════════════════
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