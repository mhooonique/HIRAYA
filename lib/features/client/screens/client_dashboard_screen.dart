import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';
import '../../auth/providers/auth_provider.dart';
// ignore_for_file: unused_element

// ═══════════════════════════════════════════════════════════
//  MOCK DATA MODELS
// ═══════════════════════════════════════════════════════════
class _InterestItem {
  final int productId;
  final String productName;
  final String category;
  final String innovatorName;
  final String status; // pending | accepted | declined
  final DateTime sentAt;
  const _InterestItem({
    required this.productId,
    required this.productName,
    required this.category,
    required this.innovatorName,
    required this.status,
    required this.sentAt,
  });
}

// ═══════════════════════════════════════════════════════════
//  PROVIDERS
// ═══════════════════════════════════════════════════════════
final _wishlistProvider =
    StateProvider<List<ProductModel>>((ref) => _dummyProducts.take(3).toList());
final _bookmarksProvider = StateProvider<List<ProductModel>>(
    (ref) => [_dummyProducts[1], _dummyProducts[3]]);
final _interestsProvider =
    StateProvider<List<_InterestItem>>((ref) => _dummyInterests);

// ── Dummy products ──────────────────────────────────────────
final _dummyProducts = [
  ProductModel(
      id: 1,
      name: 'Smart Rice Monitoring System',
      description:
          'IoT-based soil and water monitoring for rice yield optimization using low-cost sensors.',
      category: 'Agriculture',
      images: [],
      likes: 142,
      views: 890,
      interestCount: 23,
      status: 'approved',
      innovatorName: 'Juan dela Cruz',
      innovatorUsername: 'juandc',
      innovatorId: 2,
      kycStatus: 'verified',
      createdAt: DateTime.now().subtract(const Duration(days: 5))),
  ProductModel(
      id: 2,
      name: 'AI-Assisted Diabetic Retinopathy Screener',
      description:
          'Machine learning model trained on 50,000+ fundus images for early-stage diabetic retinopathy detection.',
      category: 'Healthcare',
      images: [],
      likes: 98,
      views: 1240,
      interestCount: 31,
      status: 'approved',
      innovatorName: 'Maria Santos',
      innovatorUsername: 'mariasantos',
      innovatorId: 3,
      kycStatus: 'verified',
      createdAt: DateTime.now().subtract(const Duration(days: 12))),
  ProductModel(
      id: 3,
      name: 'Modular Solar Microgrids',
      description:
          'Plug-and-play solar microgrid kits for off-grid Barangay electrification in Mindanao.',
      category: 'Energy',
      images: [],
      likes: 204,
      views: 3100,
      interestCount: 67,
      status: 'approved',
      innovatorName: 'Carlo Reyes',
      innovatorUsername: 'carloreyes',
      innovatorId: 4,
      kycStatus: 'verified',
      createdAt: DateTime.now().subtract(const Duration(days: 3))),
  ProductModel(
      id: 4,
      name: 'BambooCrete — Bamboo-Reinforced Concrete',
      description:
          'Sustainable structural concrete using bamboo fiber reinforcement for low-cost rural housing.',
      category: 'Construction',
      images: [],
      likes: 76,
      views: 510,
      interestCount: 14,
      status: 'approved',
      innovatorName: 'Ana Villanueva',
      innovatorUsername: 'anavillanueva',
      innovatorId: 5,
      kycStatus: 'unverified',
      createdAt: DateTime.now().subtract(const Duration(days: 20))),
  ProductModel(
      id: 5,
      name: 'HydroFarm Sensor Array',
      description:
          'Automated nutrient and pH monitoring for hydroponic farms with mobile dashboard integration.',
      category: 'Agriculture',
      images: [],
      likes: 55,
      views: 320,
      interestCount: 9,
      status: 'approved',
      innovatorName: 'Juan dela Cruz',
      innovatorUsername: 'juandc',
      innovatorId: 2,
      kycStatus: 'verified',
      createdAt: DateTime.now().subtract(const Duration(days: 8))),
  ProductModel(
      id: 6,
      name: 'TeleRehab Platform',
      description:
          'Remote physical therapy platform connecting patients with licensed therapists via video and motion tracking.',
      category: 'Healthcare',
      images: [],
      likes: 133,
      views: 870,
      interestCount: 28,
      status: 'approved',
      innovatorName: 'Dr. Liza Cruz',
      innovatorUsername: 'lizacruz',
      innovatorId: 6,
      kycStatus: 'verified',
      createdAt: DateTime.now().subtract(const Duration(days: 1))),
];

final _dummyInterests = [
  _InterestItem(
      productId: 3,
      productName: 'Modular Solar Microgrids',
      category: 'Energy',
      innovatorName: 'Carlo Reyes',
      status: 'accepted',
      sentAt: DateTime.now().subtract(const Duration(days: 2))),
  _InterestItem(
      productId: 1,
      productName: 'Smart Rice Monitoring System',
      category: 'Agriculture',
      innovatorName: 'Juan dela Cruz',
      status: 'pending',
      sentAt: DateTime.now().subtract(const Duration(days: 4))),
  _InterestItem(
      productId: 4,
      productName: 'BambooCrete',
      category: 'Construction',
      innovatorName: 'Ana Villanueva',
      status: 'declined',
      sentAt: DateTime.now().subtract(const Duration(days: 10))),
];

// ═══════════════════════════════════════════════════════════
//  CATEGORY META
// ═══════════════════════════════════════════════════════════
const _categoryIcons = <String, IconData>{
  'All': Icons.apps_rounded,
  'Agriculture': Icons.grass_rounded,
  'Healthcare': Icons.local_hospital_rounded,
  'Energy': Icons.bolt_rounded,
  'Construction': Icons.domain_rounded,
  'Product Design': Icons.design_services_rounded,
  'Information Technology': Icons.memory_rounded,
};

const _categoryGradients = <String, List<Color>>{
  'Agriculture': [Color(0xFF136F63), Color(0xFF1A9B89)],
  'Healthcare': [Color(0xFFD00000), Color(0xFFFF4444)],
  'Energy': [Color(0xFFFFBA08), Color(0xFFFFD45C)],
  'Construction': [Color(0xFF032B43), Color(0xFF0A4A6E)],
  'Product Design': [Color(0xFF3F88C5), Color(0xFF5BA8E5)],
  'Information Technology': [Color(0xFF1B4B8A), Color(0xFF2E6DB0)],
};

// ═══════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════════
class ClientDashboardScreen extends ConsumerStatefulWidget {
  const ClientDashboardScreen({super.key});
  @override
  ConsumerState<ClientDashboardScreen> createState() =>
      _ClientDashboardState();
}

class _ClientDashboardState extends ConsumerState<ClientDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _showSkeleton = true;

  // Navbar ambient animation
  late AnimationController _navGlowCtrl;

  static const _tabConfigs = [
    _TabConfig(Icons.explore_rounded, 'Discover'),
    _TabConfig(Icons.favorite_rounded, 'Wishlist'),
    _TabConfig(Icons.bookmark_rounded, 'Bookmarks'),
    _TabConfig(Icons.handshake_rounded, 'My Interests'),
    _TabConfig(Icons.person_rounded, 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _navGlowCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);

    // Skeleton dissolve — 1800 ms
    Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _showSkeleton = false);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _navGlowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          child: child,
        ),
        child: _showSkeleton
            ? const _DashboardSkeleton(key: ValueKey('skel'))
            : _buildDashboard(),
      ),
    );
  }

  Widget _buildDashboard() {
    final user = ref.watch(authProvider).user;
    final wishlist = ref.watch(_wishlistProvider);
    final bookmarks = ref.watch(_bookmarksProvider);
    final interests = ref.watch(_interestsProvider);

    return Column(
      key: const ValueKey('dash'),
      children: [
        _CinematicTopBar(
          user: user,
          tabController: _tabController,
          tabConfigs: _tabConfigs,
          glowCtrl: _navGlowCtrl,
          onProfileTap: () => _tabController.animateTo(4),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _DiscoverTab(
                onWishlist: (p) => _toggleWishlist(p),
                onBookmark: (p) => _toggleBookmark(p),
                wishlistIds: wishlist.map((p) => p.id).toSet(),
                bookmarkIds: bookmarks.map((p) => p.id).toSet(),
              ),
              _WishlistTab(
                  items: wishlist, onRemove: (p) => _removeWishlist(p)),
              _BookmarksTab(
                  items: bookmarks, onRemove: (p) => _removeBookmark(p)),
              _InterestsTab(items: interests),
              _ClientProfile(user: user),
            ],
          ),
        ),
      ],
    );
  }

  void _toggleWishlist(ProductModel p) {
    final list = ref.read(_wishlistProvider);
    final exists = list.any((x) => x.id == p.id);
    ref.read(_wishlistProvider.notifier).state =
        exists ? list.where((x) => x.id != p.id).toList() : [...list, p];
    _snack(
      exists ? 'Removed from wishlist' : 'Added to wishlist',
      exists ? AppColors.crimson : AppColors.teal,
      exists ? Icons.heart_broken_rounded : Icons.favorite_rounded,
    );
  }

  void _removeWishlist(ProductModel p) {
    ref.read(_wishlistProvider.notifier).state =
        ref.read(_wishlistProvider).where((x) => x.id != p.id).toList();
    _snack('Removed from wishlist', AppColors.crimson, Icons.heart_broken_rounded);
  }

  void _toggleBookmark(ProductModel p) {
    final list = ref.read(_bookmarksProvider);
    final exists = list.any((x) => x.id == p.id);
    ref.read(_bookmarksProvider.notifier).state =
        exists ? list.where((x) => x.id != p.id).toList() : [...list, p];
    _snack(
      exists ? 'Bookmark removed' : 'Bookmarked privately',
      exists ? AppColors.crimson : AppColors.navy,
      exists ? Icons.bookmark_remove_rounded : Icons.bookmark_added_rounded,
    );
  }

  void _removeBookmark(ProductModel p) {
    ref.read(_bookmarksProvider.notifier).state =
        ref.read(_bookmarksProvider).where((x) => x.id != p.id).toList();
    _snack('Bookmark removed', AppColors.crimson, Icons.bookmark_remove_rounded);
  }

  void _snack(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 10),
          Text(msg,
              style: const TextStyle(
                  fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
        ]),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// ── tab config helper ───────────────────────────────────────
class _TabConfig {
  final IconData icon;
  final String label;
  const _TabConfig(this.icon, this.label);
}

// ═══════════════════════════════════════════════════════════
//  CINEMATIC TOP BAR + ANIMATED TAB BAR
// ═══════════════════════════════════════════════════════════
class _CinematicTopBar extends StatefulWidget {
  final dynamic user;
  final TabController tabController;
  final List<_TabConfig> tabConfigs;
  final AnimationController glowCtrl;
  final VoidCallback onProfileTap;

  const _CinematicTopBar({
    required this.user,
    required this.tabController,
    required this.tabConfigs,
    required this.glowCtrl,
    required this.onProfileTap,
  });

  @override
  State<_CinematicTopBar> createState() => _CinematicTopBarState();
}

class _CinematicTopBarState extends State<_CinematicTopBar>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  final _searchCtrl = TextEditingController();
  bool _searchFocused = false;
  late FocusNode _searchFocus;

  @override
  void initState() {
    super.initState();
    _searchFocus = FocusNode()
      ..addListener(() {
        setState(() => _searchFocused = _searchFocus.hasFocus);
      });
    widget.tabController.addListener(() {
      if (mounted) setState(() => _selectedTab = widget.tabController.index);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.user?.firstName ?? 'C';
    final initial = firstName.substring(0, 1).toUpperCase();

    return AnimatedBuilder(
      animation: widget.glowCtrl,
      builder: (_, child) {
        final t = widget.glowCtrl.value;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.04 + t * 0.03),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: AppColors.sky.withValues(alpha: 0.02 + t * 0.02),
                blurRadius: 40,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Column(
        children: [
          // ── Brand row ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 16, 0),
            child: Row(
              children: [
                // Brand mark
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.navy, AppColors.teal],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navy.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('H',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text('HIRAYA',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy,
                            letterSpacing: 3)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.sky.withValues(alpha: 0.15),
                            AppColors.teal.withValues(alpha: 0.10),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.sky.withValues(alpha: 0.3)),
                      ),
                      child: const Text('Client',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.sky)),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideX(begin: -0.06, end: 0, curve: Curves.easeOutCubic),

                const Spacer(),

                // ── Action icons ──────────────────────────────
                _NavIconBtn(
                  icon: Icons.chat_bubble_rounded,
                  tooltip: 'Messages',
                  onTap: () => context.go('/messages'),
                  badge: 3,
                ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
                const SizedBox(width: 2),
                _NavIconBtn(
                  icon: Icons.storefront_rounded,
                  tooltip: 'Marketplace',
                  onTap: () => context.go('/marketplace'),
                ).animate(delay: 150.ms).fadeIn(duration: 400.ms),
                const SizedBox(width: 2),
                _NavIconBtn(
                  icon: Icons.notifications_rounded,
                  tooltip: 'Notifications',
                  onTap: () {},
                  badge: 1,
                ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
                const SizedBox(width: 10),

                // ── Avatar ────────────────────────────────────
                GestureDetector(
                  onTap: widget.onProfileTap,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.sky, AppColors.teal],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.sky.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                  ),
                )
                    .animate(delay: 250.ms)
                    .fadeIn(duration: 400.ms)
                    .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1, 1),
                        curve: Curves.easeOutBack),

                const SizedBox(width: 8),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Animated custom tab bar ────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: List.generate(widget.tabConfigs.length, (i) {
                final cfg = widget.tabConfigs[i];
                final isSelected = _selectedTab == i;
                return Expanded(
                  child: _AnimatedTabItem(
                    icon: cfg.icon,
                    label: cfg.label,
                    isSelected: isSelected,
                    index: i,
                    onTap: () => widget.tabController.animateTo(i),
                  ),
                );
              }),
            ),
          ),

          // ── Gradient line underline ───────────────────────
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.lightGray.withValues(alpha: 0.6),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Custom animated tab item ────────────────────────────────
class _AnimatedTabItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final int index;
  final VoidCallback onTap;

  const _AnimatedTabItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.index,
    required this.onTap,
  });

  @override
  State<_AnimatedTabItem> createState() => _AnimatedTabItemState();
}

class _AnimatedTabItemState extends State<_AnimatedTabItem>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color activeColor = _tabActiveColor(widget.index);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) {
          _pressCtrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _pressCtrl.reverse(),
        child: AnimatedBuilder(
          animation: _pressCtrl,
          builder: (_, child) => Transform.scale(
            scale: 1.0 - _pressCtrl.value * 0.04,
            child: child,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: widget.isSelected
                      ? activeColor
                      : Colors.transparent,
                  width: 2.5,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with animated background pill
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? activeColor.withValues(alpha: 0.10)
                        : _hovered
                            ? activeColor.withValues(alpha: 0.05)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.icon,
                    size: 18,
                    color: widget.isSelected
                        ? activeColor
                        : _hovered
                            ? activeColor.withValues(alpha: 0.7)
                            : Colors.black38,
                  ),
                ),
                const SizedBox(height: 3),
                // Label
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: widget.isSelected
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: widget.isSelected
                        ? activeColor
                        : _hovered
                            ? Colors.black54
                            : Colors.black38,
                  ),
                  child: Text(widget.label),
                ),
              ],
            ),
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: 60 + widget.index * 50))
          .fadeIn(duration: 350.ms)
          .slideY(begin: 0.10, end: 0, curve: Curves.easeOutBack),
    );
  }

  Color _tabActiveColor(int i) {
    switch (i) {
      case 0:
        return AppColors.navy;
      case 1:
        return AppColors.crimson;
      case 2:
        return AppColors.navy;
      case 3:
        return AppColors.teal;
      case 4:
        return AppColors.sky;
      default:
        return AppColors.navy;
    }
  }
}

// ── Nav icon button with optional badge ────────────────────
class _NavIconBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final int badge;
  const _NavIconBtn(
      {required this.icon,
      required this.tooltip,
      required this.onTap,
      this.badge = 0});

  @override
  State<_NavIconBtn> createState() => _NavIconBtnState();
}

class _NavIconBtnState extends State<_NavIconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _hovered
                  ? AppColors.navy.withValues(alpha: 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    widget.icon,
                    size: 20,
                    color: _hovered ? AppColors.navy : Colors.black54,
                  ),
                ),
                if (widget.badge > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: AppColors.crimson,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${widget.badge}',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
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
}

// ═══════════════════════════════════════════════════════════
//  SKELETON SCREEN
// ═══════════════════════════════════════════════════════════
class _DashboardSkeleton extends StatefulWidget {
  const _DashboardSkeleton({super.key});
  @override
  State<_DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<_DashboardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          // ── Navbar skeleton ─────────────────────────────────
          _buildNavSkeleton(),
          // ── Content skeleton ─────────────────────────────────
          Expanded(child: _buildContentSkeleton()),
        ],
      ),
    );
  }

  Widget _buildNavSkeleton() {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, child) {
        final t = _pulseCtrl.value;
        return Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(24, 14, 16, 12),
          child: child,
        );
      },
      child: Column(
        children: [
          Row(
            children: [
              // Logo box
              _LSkel(w: 36, h: 36, radius: 10)
                  .animate()
                  .fadeIn(duration: 400.ms),
              const SizedBox(width: 10),
              _LSkel(w: 90, h: 18, radius: 6)
                  .animate(delay: 50.ms)
                  .fadeIn(duration: 400.ms),
              const SizedBox(width: 8),
              _LSkel(w: 46, h: 22, radius: 6)
                  .animate(delay: 80.ms)
                  .fadeIn(duration: 400.ms),
              const Spacer(),
              // Icon buttons
              ...List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: _LSkel(w: 40, h: 40, radius: 10)
                      .animate(delay: Duration(milliseconds: 100 + i * 50))
                      .fadeIn(duration: 350.ms),
                ),
              ),
              const SizedBox(width: 8),
              // Avatar
              _LSkel(w: 36, h: 36, radius: 18)
                  .animate(delay: 280.ms)
                  .fadeIn(duration: 350.ms),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 14),
          // Tab bar skeleton — 5 tabs
          Row(
            children: List.generate(
              5,
              (i) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      _LSkel(w: 22, h: 22, radius: 8)
                          .animate(
                              delay: Duration(milliseconds: 120 + i * 55))
                          .fadeIn(duration: 350.ms),
                      const SizedBox(height: 5),
                      _LSkel(w: 52, h: 10, radius: 5)
                          .animate(
                              delay: Duration(milliseconds: 160 + i * 55))
                          .fadeIn(duration: 350.ms),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Bottom line
          Container(
            height: 1,
            color: AppColors.lightGray.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSkeleton() {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        // ── Search + categories ───────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Column(
              children: [
                // Search bar
                _LSkel(w: double.infinity, h: 44, radius: 12)
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 450.ms),
                const SizedBox(height: 14),
                // Category chips
                Row(
                  children: List.generate(
                    5,
                    (i) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _LSkel(
                              w: 72.0 + i * 10,
                              h: 34,
                              radius: 20)
                          .animate(
                              delay: Duration(milliseconds: 260 + i * 60))
                          .fadeIn(duration: 380.ms),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // ── Section label ─────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Row(
              children: [
                _LSkel(w: 20, h: 20, radius: 10)
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 380.ms),
                const SizedBox(width: 8),
                _LSkel(w: 140, h: 18, radius: 7)
                    .animate(delay: 320.ms)
                    .fadeIn(duration: 380.ms),
              ],
            ),
          ),
        ),
        // ── Card grid ─────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _CardSkeleton()
                  .animate(delay: Duration(milliseconds: 340 + i * 60))
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
              childCount: 6,
            ),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 360,
              mainAxisExtent: 260,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Card skeleton ───────────────────────────────────────────
class _CardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.lightGray.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.lightGray.withValues(alpha: 0.4),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Stack(
              children: [
                Positioned(
                    top: 10,
                    left: 10,
                    child: _LSkel(w: 80, h: 22, radius: 8)),
                Positioned(
                    top: 8,
                    right: 8,
                    child: Row(children: [
                      _LSkel(w: 30, h: 30, radius: 15),
                      const SizedBox(width: 6),
                      _LSkel(w: 30, h: 30, radius: 15),
                    ])),
              ],
            ),
          ),
          // Content area
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LSkel(w: double.infinity, h: 14, radius: 7)
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                        duration: 1400.ms,
                        color: Colors.white.withValues(alpha: 0.7),
                        blendMode: BlendMode.srcATop),
                const SizedBox(height: 8),
                _LSkel(w: 120, h: 11, radius: 5)
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                        duration: 1400.ms,
                        color: Colors.white.withValues(alpha: 0.7),
                        blendMode: BlendMode.srcATop),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.lightGray),
                const SizedBox(height: 10),
                Row(children: [
                  _LSkel(w: 36, h: 11, radius: 5),
                  const SizedBox(width: 10),
                  _LSkel(w: 36, h: 11, radius: 5),
                  const Spacer(),
                  _LSkel(w: 44, h: 22, radius: 8),
                ]),
              ],
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1600.ms,
          color: Colors.white.withValues(alpha: 0.45),
          blendMode: BlendMode.srcATop,
        );
  }
}

// ═══════════════════════════════════════════════════════════
//  TAB 1 — DISCOVER
// ═══════════════════════════════════════════════════════════
class _DiscoverTab extends StatefulWidget {
  final void Function(ProductModel) onWishlist;
  final void Function(ProductModel) onBookmark;
  final Set<int> wishlistIds;
  final Set<int> bookmarkIds;

  const _DiscoverTab({
    required this.onWishlist,
    required this.onBookmark,
    required this.wishlistIds,
    required this.bookmarkIds,
  });

  @override
  State<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<_DiscoverTab> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _categoryFilter = 'All';
  bool _searchActive = false;

  static const _categories = [
    'All',
    'Agriculture',
    'Healthcare',
    'Energy',
    'Construction',
    'Product Design',
    'Information Technology'
  ];

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      setState(() => _searchActive = _searchFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<ProductModel> get _filtered {
    var list = List<ProductModel>.from(_dummyProducts);
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q) ||
              p.innovatorName.toLowerCase().contains(q))
          .toList();
    }
    if (_categoryFilter != 'All') {
      list = list.where((p) => p.category == _categoryFilter).toList();
    }
    list.sort((a, b) =>
        (b.likes * 2 + b.views).compareTo(a.likes * 2 + a.views));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return CustomScrollView(
      slivers: [
        // ── Search + category bar ─────────────────────────
        SliverToBoxAdapter(
          child: _SearchAndFilterBar(
            controller: _searchCtrl,
            focusNode: _searchFocus,
            isActive: _searchActive,
            categoryFilter: _categoryFilter,
            categories: _categories,
            onChanged: (_) => setState(() {}),
            onClear: () {
              _searchCtrl.clear();
              setState(() {});
            },
            onCategorySelect: (c) =>
                setState(() => _categoryFilter = c),
          ),
        ),

        // ── Section heading ───────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            child: Row(children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: AppColors.crimson, size: 20),
              const SizedBox(width: 8),
              Text(
                _categoryFilter == 'All'
                    ? 'Trending Now'
                    : 'Top in $_categoryFilter',
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy),
              ),
              const SizedBox(width: 8),
              _CountBadge(filtered.length, AppColors.crimson),
            ]),
          ),
        ),

        // ── Grid ─────────────────────────────────────────
        filtered.isEmpty
            ? const SliverFillRemaining(
                child: _EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No results',
                    subtitle:
                        'Try a different search or category.'),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _DiscoverCard(
                      product: filtered[i],
                      index: i,
                      isWishlisted:
                          widget.wishlistIds.contains(filtered[i].id),
                      isBookmarked:
                          widget.bookmarkIds.contains(filtered[i].id),
                      onWishlist: () => widget.onWishlist(filtered[i]),
                      onBookmark: () => widget.onBookmark(filtered[i]),
                    ),
                    childCount: filtered.length,
                  ),
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 360,
                    mainAxisExtent: 266,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                ),
              ),
      ],
    );
  }
}

// ── Cinematic search + filter bar ──────────────────────────
class _SearchAndFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isActive;
  final String categoryFilter;
  final List<String> categories;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final ValueChanged<String> onCategorySelect;

  const _SearchAndFilterBar({
    required this.controller,
    required this.focusNode,
    required this.isActive,
    required this.categoryFilter,
    required this.categories,
    required this.onChanged,
    required this.onClear,
    required this.onCategorySelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: isActive
                ? AppColors.sky.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: isActive ? 20 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.sky.withValues(alpha: 0.04)
                  : AppColors.offWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive
                    ? AppColors.sky.withValues(alpha: 0.5)
                    : AppColors.lightGray,
                width: isActive ? 1.5 : 1.0,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.sky.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : [],
            ),
            height: 48,
            child: Row(
              children: [
                const SizedBox(width: 14),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  child: Icon(
                    Icons.search_rounded,
                    size: 20,
                    color:
                        isActive ? AppColors.sky : Colors.black38,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: onChanged,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: AppColors.navy),
                    decoration: InputDecoration(
                      hintText:
                          'Search innovations, innovators...',
                      hintStyle: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.black.withValues(alpha: 0.30)),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: onClear,
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.lightGray
                            .withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                          size: 14, color: Colors.black45),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Category chips with icons
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final c = categories[i];
                final isActive = categoryFilter == c;
                final catColor = c == 'All'
                    ? AppColors.navy
                    : (AppColors.categoryColors[c] ?? AppColors.navy);
                final gradColors = c == 'All'
                    ? [AppColors.navy, AppColors.teal]
                    : (_categoryGradients[c] ??
                        [catColor, catColor]);
                final catIcon = _categoryIcons[c] ?? Icons.category;

                return GestureDetector(
                  onTap: () => onCategorySelect(c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 0),
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? LinearGradient(colors: gradColors)
                          : null,
                      color: isActive ? null : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? Colors.transparent
                            : AppColors.lightGray,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: catColor
                                    .withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          catIcon,
                          size: 13,
                          color: isActive
                              ? Colors.white
                              : catColor.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          c,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? Colors.white
                                : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product discovery card — cinematic hover ────────────────
class _DiscoverCard extends StatefulWidget {
  final ProductModel product;
  final int index;
  final bool isWishlisted;
  final bool isBookmarked;
  final VoidCallback onWishlist;
  final VoidCallback onBookmark;

  const _DiscoverCard({
    required this.product,
    required this.index,
    required this.isWishlisted,
    required this.isBookmarked,
    required this.onWishlist,
    required this.onBookmark,
  });

  @override
  State<_DiscoverCard> createState() => _DiscoverCardState();
}

class _DiscoverCardState extends State<_DiscoverCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _hoverCtrl;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.product.category;
    final catColor = AppColors.categoryColors[cat] ?? AppColors.navy;
    final gradColors =
        _categoryGradients[cat] ?? [catColor, catColor];

    return MouseRegion(
      onEnter: (_) {
        setState(() => _hovered = true);
        _hoverCtrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _hoverCtrl.reverse();
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/product/${widget.product.id}'),
        child: AnimatedBuilder(
          animation: _hoverCtrl,
          builder: (_, child) => Transform.translate(
            offset: Offset(0, -_hoverCtrl.value * 4),
            child: child,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _hovered
                    ? catColor.withValues(alpha: 0.35)
                    : AppColors.lightGray,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: catColor.withValues(alpha: 0.14),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                        spreadRadius: -2,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Image / category banner ────────────────
                Container(
                  height: 116,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        gradColors[0].withValues(alpha: 0.10),
                        gradColors[1].withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                  ),
                  child: Stack(
                    children: [
                      // Background icon
                      Positioned(
                        bottom: -8,
                        right: 8,
                        child: Icon(
                          _categoryIcons[cat] ?? Icons.lightbulb_rounded,
                          size: 70,
                          color: catColor.withValues(alpha: 0.07),
                        ),
                      ),
                      // Category badge
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: gradColors),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: catColor.withValues(alpha: 0.30),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _categoryIcons[cat] ??
                                    Icons.category,
                                size: 10,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.product.category,
                                style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Action buttons
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Row(children: [
                          _ActionBtn(
                            icon: widget.isBookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_outline_rounded,
                            color: widget.isBookmarked
                                ? AppColors.navy
                                : Colors.black45,
                            onTap: widget.onBookmark,
                          ),
                          const SizedBox(width: 4),
                          _ActionBtn(
                            icon: widget.isWishlisted
                                ? Icons.favorite_rounded
                                : Icons.favorite_outline_rounded,
                            color: widget.isWishlisted
                                ? AppColors.crimson
                                : Colors.black45,
                            onTap: widget.onWishlist,
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),

                // ── Content ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _hovered
                              ? catColor
                              : AppColors.navy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(children: [
                        if (widget.product.kycStatus == 'verified')
                          Icon(Icons.verified_rounded,
                              size: 12, color: AppColors.teal),
                        if (widget.product.kycStatus == 'verified')
                          const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            widget.product.innovatorName,
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: Colors.black45),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      Divider(
                          height: 1,
                          color: AppColors.lightGray
                              .withValues(alpha: 0.8)),
                      const SizedBox(height: 10),
                      Row(children: [
                        _MiniStat(
                            icon: Icons.favorite_rounded,
                            value: '${widget.product.likes}',
                            color: AppColors.crimson),
                        const SizedBox(width: 10),
                        _MiniStat(
                            icon: Icons.remove_red_eye_rounded,
                            value: '${widget.product.views}',
                            color: Colors.black38),
                        const SizedBox(width: 10),
                        _MiniStat(
                            icon: Icons.handshake_rounded,
                            value:
                                '${widget.product.interestCount}',
                            color: AppColors.teal),
                        const Spacer(),
                        _ViewBtn(color: catColor),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate(
              delay: Duration(milliseconds: 40 * widget.index))
          .fadeIn(duration: 380.ms)
          .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
    );
  }
}

class _ViewBtn extends StatefulWidget {
  final Color color;
  const _ViewBtn({required this.color});

  @override
  State<_ViewBtn> createState() => _ViewBtnState();
}

class _ViewBtnState extends State<_ViewBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _hovered
              ? widget.color
              : widget.color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'View',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _hovered ? Colors.white : widget.color,
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => Transform.scale(
            scale: 1.0 - _ctrl.value * 0.12,
            child: child,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.92),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.09),
                    blurRadius: 5),
              ],
            ),
            child: Icon(widget.icon, size: 15, color: widget.color),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  TAB 2 — WISHLIST
// ═══════════════════════════════════════════════════════════
class _WishlistTab extends StatelessWidget {
  final List<ProductModel> items;
  final void Function(ProductModel) onRemove;
  const _WishlistTab({required this.items, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _TabHeader(
        icon: Icons.favorite_rounded,
        iconColor: AppColors.crimson,
        gradColors: const [AppColors.crimson, Color(0xFFFF6B6B)],
        title: 'Wishlist',
        subtitle: "Products you're keeping an eye on",
        count: items.length,
      ),
      Expanded(
        child: items.isEmpty
            ? const _EmptyState(
                icon: Icons.favorite_outline_rounded,
                title: 'Your wishlist is empty',
                subtitle:
                    'Heart a product from Discover to save it here.')
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: items.length,
                itemBuilder: (ctx, i) => _SavedProductRow(
                  product: items[i],
                  index: i,
                  actionIcon: Icons.favorite_rounded,
                  actionColor: AppColors.crimson,
                  actionTooltip: 'Remove from wishlist',
                  onAction: () => onRemove(items[i]),
                ),
              ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════
//  TAB 3 — BOOKMARKS
// ═══════════════════════════════════════════════════════════
class _BookmarksTab extends StatelessWidget {
  final List<ProductModel> items;
  final void Function(ProductModel) onRemove;
  const _BookmarksTab({required this.items, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _TabHeader(
        icon: Icons.bookmark_rounded,
        iconColor: AppColors.navy,
        gradColors: const [AppColors.navy, AppColors.teal],
        title: 'Bookmarks',
        subtitle: 'Private saves — innovators are not notified',
        count: items.length,
      ),
      Expanded(
        child: items.isEmpty
            ? const _EmptyState(
                icon: Icons.bookmark_outline_rounded,
                title: 'No bookmarks yet',
                subtitle:
                    'Bookmark a product to privately save it for later.')
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: items.length,
                itemBuilder: (ctx, i) => _SavedProductRow(
                  product: items[i],
                  index: i,
                  actionIcon: Icons.bookmark_remove_rounded,
                  actionColor: AppColors.navy,
                  actionTooltip: 'Remove bookmark',
                  onAction: () => onRemove(items[i]),
                ),
              ),
      ),
    ]);
  }
}

// ── Shared saved product row ────────────────────────────────
class _SavedProductRow extends StatefulWidget {
  final ProductModel product;
  final int index;
  final IconData actionIcon;
  final Color actionColor;
  final String actionTooltip;
  final VoidCallback onAction;

  const _SavedProductRow({
    required this.product,
    required this.index,
    required this.actionIcon,
    required this.actionColor,
    required this.actionTooltip,
    required this.onAction,
  });

  @override
  State<_SavedProductRow> createState() => _SavedProductRowState();
}

class _SavedProductRowState extends State<_SavedProductRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final catColor =
        AppColors.categoryColors[widget.product.category] ??
            AppColors.navy;
    final gradColors = _categoryGradients[widget.product.category] ??
        [catColor, catColor];

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/product/${widget.product.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered
                  ? catColor.withValues(alpha: 0.30)
                  : AppColors.lightGray,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: catColor.withValues(alpha: 0.10),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6)
                  ],
          ),
          child: Row(children: [
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    gradColors[0].withValues(alpha: 0.12),
                    gradColors[1].withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _categoryIcons[widget.product.category] ??
                    Icons.lightbulb_rounded,
                color: catColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color:
                          _hovered ? catColor : AppColors.navy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        gradient:
                            LinearGradient(colors: gradColors),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        widget.product.category,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (widget.product.kycStatus == 'verified')
                      const Icon(Icons.verified_rounded,
                          size: 11, color: AppColors.teal),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        widget.product.innovatorName,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Colors.black45),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    _MiniStat(
                        icon: Icons.favorite_rounded,
                        value: '${widget.product.likes}',
                        color: AppColors.crimson),
                    const SizedBox(width: 10),
                    _MiniStat(
                        icon: Icons.remove_red_eye_rounded,
                        value: '${widget.product.views}',
                        color: Colors.black38),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(children: [
              _IconTapBtn(
                icon: Icons.open_in_new_rounded,
                color: AppColors.sky,
                onTap: () =>
                    context.go('/product/${widget.product.id}'),
                tooltip: 'View product',
              ),
              const SizedBox(height: 4),
              _IconTapBtn(
                icon: widget.actionIcon,
                color: widget.actionColor,
                onTap: widget.onAction,
                tooltip: widget.actionTooltip,
              ),
            ]),
          ]),
        )
            .animate(
                delay: Duration(milliseconds: 50 * widget.index))
            .fadeIn(duration: 320.ms)
            .slideX(begin: 0.04, end: 0, curve: Curves.easeOutCubic),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  TAB 4 — MY INTERESTS
// ═══════════════════════════════════════════════════════════
class _InterestsTab extends StatelessWidget {
  final List<_InterestItem> items;
  const _InterestsTab({required this.items});

  @override
  Widget build(BuildContext context) {
    final accepted = items.where((i) => i.status == 'accepted').length;
    final pending = items.where((i) => i.status == 'pending').length;
    final declined = items.where((i) => i.status == 'declined').length;

    return Column(children: [
      _TabHeader(
        icon: Icons.handshake_rounded,
        iconColor: AppColors.teal,
        gradColors: const [AppColors.teal, AppColors.sky],
        title: 'My Interests',
        subtitle: 'Formal interest requests you have sent',
        count: items.length,
      ),
      if (items.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Row(children: [
            _StatusPill('Accepted', accepted, AppColors.teal),
            const SizedBox(width: 10),
            _StatusPill('Pending', pending, AppColors.golden),
            const SizedBox(width: 10),
            _StatusPill('Declined', declined, AppColors.crimson),
          ]),
        ),
      Expanded(
        child: items.isEmpty
            ? const _EmptyState(
                icon: Icons.handshake_outlined,
                title: 'No interests sent yet',
                subtitle:
                    'Express interest on a product to start a conversation.')
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: items.length,
                itemBuilder: (ctx, i) =>
                    _InterestRow(item: items[i], index: i),
              ),
      ),
    ]);
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _StatusPill(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$count',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ),
          ),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ]),
      );
}

class _InterestRow extends StatefulWidget {
  final _InterestItem item;
  final int index;
  const _InterestRow({required this.item, required this.index});

  @override
  State<_InterestRow> createState() => _InterestRowState();
}

class _InterestRowState extends State<_InterestRow> {
  bool _hovered = false;

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'just now';
  }

  @override
  Widget build(BuildContext context) {
    final catColor =
        AppColors.categoryColors[widget.item.category] ??
            AppColors.navy;
    final gradColors =
        _categoryGradients[widget.item.category] ??
            [catColor, catColor];

    final statusColor = widget.item.status == 'accepted'
        ? AppColors.teal
        : widget.item.status == 'pending'
            ? AppColors.golden
            : AppColors.crimson;
    final statusIcon = widget.item.status == 'accepted'
        ? Icons.check_circle_rounded
        : widget.item.status == 'pending'
            ? Icons.pending_rounded
            : Icons.cancel_rounded;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? statusColor.withValues(alpha: 0.30)
                : widget.item.status == 'accepted'
                    ? AppColors.teal.withValues(alpha: 0.20)
                    : AppColors.lightGray,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.10),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6)
                ],
        ),
        child: Row(children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gradColors[0].withValues(alpha: 0.13),
                  gradColors[1].withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _categoryIcons[widget.item.category] ??
                  Icons.lightbulb_rounded,
              color: catColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.productName,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text('by ${widget.item.innovatorName}',
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.black45)),
                const SizedBox(height: 3),
                Text('Sent ${_timeAgo(widget.item.sentAt)}',
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.black38)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: statusColor.withValues(alpha: 0.25)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(statusIcon, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(widget.item.status.toUpperCase(),
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor)),
              ]),
            ),
            if (widget.item.status == 'accepted') ...[
              const SizedBox(height: 6),
              _ChatBtn(onTap: () => context.go('/messages')),
            ],
          ]),
        ]),
      )
          .animate(
              delay: Duration(milliseconds: 60 * widget.index))
          .fadeIn(duration: 360.ms)
          .slideX(begin: 0.04, end: 0, curve: Curves.easeOutCubic),
    );
  }
}

class _ChatBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _ChatBtn({required this.onTap});

  @override
  State<_ChatBtn> createState() => _ChatBtnState();
}

class _ChatBtnState extends State<_ChatBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.sky
                : AppColors.sky.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 12,
                color: _hovered ? Colors.white : AppColors.sky),
            const SizedBox(width: 4),
            Text('Message',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _hovered ? Colors.white : AppColors.sky)),
          ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  TAB 5 — PROFILE
// ═══════════════════════════════════════════════════════════
class _ClientProfile extends ConsumerStatefulWidget {
  final dynamic user;
  const _ClientProfile({this.user});

  @override
  ConsumerState<_ClientProfile> createState() => _ClientProfileState();
}

class _ClientProfileState extends ConsumerState<_ClientProfile> {
  bool _logoutHovered = false;

  @override
  Widget build(BuildContext context) {
    final u = ref.watch(authProvider).user;
    final firstName = u?.firstName ?? 'Client';
    final fullName =
        u != null ? '${u.firstName} ${u.lastName}' : 'Client';
    final username = u?.username ?? '—';
    final email = u?.email ?? '—';
    final kycStatus = u?.kycStatus ?? 'unverified';
    final userStatus = u?.userStatus ?? 0;
    final initial = firstName.substring(0, 1).toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────
            const Text('My Profile',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy))
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),

            const SizedBox(height: 24),

            // ── Profile card ─────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: AppColors.lightGray.withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.05),
                    blurRadius: 30,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ── Gradient banner ──────────────────────
                  Container(
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.navy, AppColors.teal],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24)),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                            child: CustomPaint(
                                painter: _ProfileBannerPainter())),
                      ],
                    ),
                  ),

                  // ── Avatar overlapping banner ─────────────
                  Transform.translate(
                    offset: const Offset(0, -36),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppColors.sky, AppColors.teal],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                                color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.sky.withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white),
                            ),
                          ),
                        )
                            .animate()
                            .scale(
                              begin: const Offset(0.7, 0.7),
                              end: const Offset(1, 1),
                              curve: Curves.easeOutBack,
                              duration: 500.ms,
                            )
                            .fadeIn(duration: 350.ms),
                        const SizedBox(height: 4),
                        Text(
                          fullName,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy),
                        ).animate(delay: 80.ms).fadeIn(duration: 380.ms),
                        const SizedBox(height: 2),
                        Text('@$username',
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: Colors.black45))
                            .animate(delay: 120.ms)
                            .fadeIn(duration: 350.ms),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.sky.withValues(alpha: 0.12),
                                AppColors.teal.withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.sky
                                    .withValues(alpha: 0.25)),
                          ),
                          child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.person_rounded,
                                    color: AppColors.sky, size: 14),
                                SizedBox(width: 6),
                                Text('Client / Investor',
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.sky)),
                              ]),
                        ).animate(delay: 160.ms).fadeIn(duration: 350.ms),
                      ],
                    ),
                  ),

                  // ── Info rows ─────────────────────────────
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      children: [
                        const Divider(color: AppColors.lightGray),
                        const SizedBox(height: 12),
                        _ProfileRow(
                            label: 'Email',
                            value: email,
                            icon: Icons.email_outlined,
                            color: AppColors.sky),
                        _ProfileRow(
                            label: 'KYC Status',
                            value: kycStatus.toUpperCase(),
                            icon: Icons.verified_user_rounded,
                            color: kycStatus == 'verified'
                                ? AppColors.teal
                                : AppColors.golden),
                        _ProfileRow(
                            label: 'Account Status',
                            value:
                                userStatus == 1 ? 'Active' : 'Pending',
                            icon: Icons.circle_rounded,
                            color: userStatus == 1
                                ? AppColors.teal
                                : AppColors.golden),
                      ],
                    ),
                  ),
                ],
              ),
            )
                .animate(delay: 100.ms)
                .fadeIn(duration: 450.ms)
                .slideY(
                    begin: 0.06,
                    end: 0,
                    curve: Curves.easeOutCubic),

            const SizedBox(height: 20),

            // ── Logout button ─────────────────────────────
            MouseRegion(
              onEnter: (_) => setState(() => _logoutHovered = true),
              onExit: (_) => setState(() => _logoutHovered = false),
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _logoutHovered
                        ? AppColors.crimson.withValues(alpha: 0.06)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _logoutHovered
                          ? AppColors.crimson.withValues(alpha: 0.5)
                          : AppColors.crimson.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded,
                          color: AppColors.crimson,
                          size: _logoutHovered ? 19 : 17),
                      const SizedBox(width: 8),
                      const Text('Logout',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.crimson)),
                    ],
                  ),
                ),
              ),
            )
                .animate(delay: 200.ms)
                .fadeIn(duration: 400.ms)
                .slideY(
                    begin: 0.06,
                    end: 0,
                    curve: Curves.easeOutCubic),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _ProfileRow(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.black45)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy)),
        ]),
      );
}

// Profile banner painter — subtle dot pattern
class _ProfileBannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, p);
      }
    }
  }

  @override
  bool shouldRepaint(_ProfileBannerPainter old) => false;
}

// ═══════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ═══════════════════════════════════════════════════════════

// ── Tab section header ──────────────────────────────────────
class _TabHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final List<Color> gradColors;
  final String title;
  final String subtitle;
  final int count;

  const _TabHeader({
    required this.icon,
    required this.iconColor,
    required this.gradColors,
    required this.title,
    required this.subtitle,
    required this.count,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
              bottom: BorderSide(
                  color: AppColors.lightGray.withValues(alpha: 0.5))),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradColors),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Text(title,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy)),
                  const SizedBox(width: 8),
                  _CountBadge(count, iconColor),
                ]),
                Text(subtitle,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.black38)),
              ])),
        ]),
      )
          .animate()
          .fadeIn(duration: 380.ms)
          .slideY(begin: -0.06, end: 0, curve: Curves.easeOutCubic);
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;
  const _CountBadge(this.count, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$count',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color),
        ),
      );
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      );
}

class _IconTapBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;
  const _IconTapBtn(
      {required this.icon,
      required this.color,
      required this.onTap,
      required this.tooltip});

  @override
  State<_IconTapBtn> createState() => _IconTapBtnState();
}

class _IconTapBtnState extends State<_IconTapBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.10)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.icon,
                size: 17, color: widget.color),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState(
      {required this.icon,
      required this.title,
      required this.subtitle});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.lightGray.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon,
                  size: 36, color: AppColors.lightGray),
            )
                .animate()
                .scale(
                    begin: const Offset(0.7, 0.7),
                    end: const Offset(1, 1),
                    curve: Curves.easeOutBack,
                    duration: 400.ms)
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 18),
            Text(title,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy))
                .animate(delay: 80.ms)
                .fadeIn(duration: 350.ms),
            const SizedBox(height: 6),
            Text(subtitle,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Colors.black38),
                textAlign: TextAlign.center)
                .animate(delay: 120.ms)
                .fadeIn(duration: 350.ms),
          ],
        ),
      );
}

// ── Skeleton helpers ────────────────────────────────────────
class _LSkel extends StatelessWidget {
  final double w;
  final double h;
  final double radius;
  final Color? baseColor;

  const _LSkel(
      {required this.w,
      required this.h,
      required this.radius,
      this.baseColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: baseColor ?? AppColors.lightGray.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(radius),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1400.ms,
          color: Colors.white.withValues(alpha: 0.70),
          blendMode: BlendMode.srcATop,
        );
  }
}

// ── Right dot grid painter for right panel ──────────────────
class _RightDotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.navy.withValues(alpha: 0.028)
      ..style = PaintingStyle.fill;
    const spacing = 32.0;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, p);
      }
    }
  }

  @override
  bool shouldRepaint(_RightDotGridPainter old) => false;
}

// ── Parallax math helper ─────────────────────────────────────
double _parallax(double t, double amplitude) =>
    math.sin(t * math.pi * 2) * amplitude;
