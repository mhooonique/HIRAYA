import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/widgets/notification_bell.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  MOCK DATA MODELS
// ─────────────────────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────────────────────
//  PROVIDERS (local state — to be wired to API later)
// ─────────────────────────────────────────────────────────────────────────────
final _wishlistProvider = StateProvider<List<ProductModel>>((ref) => _dummyProducts.take(3).toList());
final _bookmarksProvider = StateProvider<List<ProductModel>>((ref) => [_dummyProducts[1], _dummyProducts[3]]);
final _interestsProvider = StateProvider<List<_InterestItem>>((ref) => _dummyInterests);

// ── Dummy data ────────────────────────────────────────────────────────────────
final _dummyProducts = [
  ProductModel(id: 1, name: 'Smart Rice Monitoring System', description: 'IoT-based soil and water monitoring for rice yield optimization using low-cost sensors.', category: 'Agriculture', images: [], likes: 142, views: 890, interestCount: 23, status: 'approved', innovatorName: 'Juan dela Cruz', innovatorUsername: 'juandc', innovatorId: 2, kycStatus: 'verified', createdAt: DateTime.now().subtract(const Duration(days: 5))),
  ProductModel(id: 2, name: 'AI-Assisted Diabetic Retinopathy Screener', description: 'Machine learning model trained on 50,000+ fundus images for early-stage diabetic retinopathy detection.', category: 'Healthcare', images: [], likes: 98, views: 1240, interestCount: 31, status: 'approved', innovatorName: 'Maria Santos', innovatorUsername: 'mariasantos', innovatorId: 3, kycStatus: 'verified', createdAt: DateTime.now().subtract(const Duration(days: 12))),
  ProductModel(id: 3, name: 'Modular Solar Microgrids', description: 'Plug-and-play solar microgrid kits for off-grid Barangay electrification in Mindanao.', category: 'Energy', images: [], likes: 204, views: 3100, interestCount: 67, status: 'approved', innovatorName: 'Carlo Reyes', innovatorUsername: 'carloreyes', innovatorId: 4, kycStatus: 'verified', createdAt: DateTime.now().subtract(const Duration(days: 3))),
  ProductModel(id: 4, name: 'BambooCrete — Bamboo-Reinforced Concrete', description: 'Sustainable structural concrete using bamboo fiber reinforcement for low-cost rural housing.', category: 'Construction', images: [], likes: 76, views: 510, interestCount: 14, status: 'approved', innovatorName: 'Ana Villanueva', innovatorUsername: 'anavillanueva', innovatorId: 5, kycStatus: 'unverified', createdAt: DateTime.now().subtract(const Duration(days: 20))),
  ProductModel(id: 5, name: 'HydroFarm Sensor Array', description: 'Automated nutrient and pH monitoring for hydroponic farms with mobile dashboard integration.', category: 'Agriculture', images: [], likes: 55, views: 320, interestCount: 9, status: 'approved', innovatorName: 'Juan dela Cruz', innovatorUsername: 'juandc', innovatorId: 2, kycStatus: 'verified', createdAt: DateTime.now().subtract(const Duration(days: 8))),
  ProductModel(id: 6, name: 'TeleRehab Platform', description: 'Remote physical therapy platform connecting patients with licensed therapists via video and motion tracking.', category: 'Healthcare', images: [], likes: 133, views: 870, interestCount: 28, status: 'approved', innovatorName: 'Dr. Liza Cruz', innovatorUsername: 'lizacruz', innovatorId: 6, kycStatus: 'verified', createdAt: DateTime.now().subtract(const Duration(days: 1))),
];

final _dummyInterests = [
  _InterestItem(productId: 3, productName: 'Modular Solar Microgrids', category: 'Energy', innovatorName: 'Carlo Reyes', status: 'accepted', sentAt: DateTime.now().subtract(const Duration(days: 2))),
  _InterestItem(productId: 1, productName: 'Smart Rice Monitoring System', category: 'Agriculture', innovatorName: 'Juan dela Cruz', status: 'pending', sentAt: DateTime.now().subtract(const Duration(days: 4))),
  _InterestItem(productId: 4, productName: 'BambooCrete', category: 'Construction', innovatorName: 'Ana Villanueva', status: 'declined', sentAt: DateTime.now().subtract(const Duration(days: 10))),
];

// ─────────────────────────────────────────────────────────────────────────────
//  MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ClientDashboardScreen extends ConsumerStatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  ConsumerState<ClientDashboardScreen> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends ConsumerState<ClientDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _tabs = const [
    Tab(icon: Icon(Icons.explore_rounded, size: 18), text: 'Discover'),
    Tab(icon: Icon(Icons.favorite_rounded, size: 18), text: 'Wishlist'),
    Tab(icon: Icon(Icons.bookmark_rounded, size: 18), text: 'Bookmarks'),
    Tab(icon: Icon(Icons.handshake_rounded, size: 18), text: 'My Interests'),
    Tab(icon: Icon(Icons.person_rounded, size: 18), text: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final wishlist = ref.watch(_wishlistProvider);
    final bookmarks = ref.watch(_bookmarksProvider);
    final interests = ref.watch(_interestsProvider);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          _ClientTopBar(user: user, tabController: _tabController, tabs: _tabs),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _DiscoverTab(
                  onWishlist: (p) {
                    final list = ref.read(_wishlistProvider);
                    final exists = list.any((x) => x.id == p.id);
                    ref.read(_wishlistProvider.notifier).state = exists
                        ? list.where((x) => x.id != p.id).toList()
                        : [...list, p];
                    _showSnack(exists ? 'Removed from wishlist' : 'Added to wishlist',
                        exists ? AppColors.crimson : AppColors.teal);
                  },
                  onBookmark: (p) {
                    final list = ref.read(_bookmarksProvider);
                    final exists = list.any((x) => x.id == p.id);
                    ref.read(_bookmarksProvider.notifier).state = exists
                        ? list.where((x) => x.id != p.id).toList()
                        : [...list, p];
                    _showSnack(exists ? 'Bookmark removed' : 'Bookmarked privately',
                        exists ? AppColors.crimson : AppColors.navy);
                  },
                  wishlistIds: wishlist.map((p) => p.id).toSet(),
                  bookmarkIds: bookmarks.map((p) => p.id).toSet(),
                ),
                _WishlistTab(
                  items: wishlist,
                  onRemove: (p) {
                    ref.read(_wishlistProvider.notifier).state =
                        ref.read(_wishlistProvider).where((x) => x.id != p.id).toList();
                    _showSnack('Removed from wishlist', AppColors.crimson);
                  },
                ),
                _BookmarksTab(
                  items: bookmarks,
                  onRemove: (p) {
                    ref.read(_bookmarksProvider.notifier).state =
                        ref.read(_bookmarksProvider).where((x) => x.id != p.id).toList();
                    _showSnack('Bookmark removed', AppColors.crimson);
                  },
                ),
                _InterestsTab(items: interests),
                _ClientProfile(user: user),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TOP APP BAR + TAB BAR
// ─────────────────────────────────────────────────────────────────────────────
class _ClientTopBar extends StatelessWidget {
  final dynamic user;
  final TabController tabController;
  final List<Tab> tabs;

  const _ClientTopBar({
    required this.user,
    required this.tabController,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.lightGray)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
          child: Row(children: [
            Image.asset('assets/images/logo/final-logo.png', height: 32),
            const SizedBox(width: 10),
            const Text('HIRAYA',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy, letterSpacing: 3)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.sky.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: const Text('Client', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.sky)),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.navy),
              onPressed: () => context.go('/messages'),
              tooltip: 'Messages',
            ),
            IconButton(
              icon: const Icon(Icons.storefront_rounded, color: AppColors.navy),
              onPressed: () => context.go('/marketplace'),
              tooltip: 'Browse Marketplace',
            ),
            const NotificationBell(),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => tabController.animateTo(4),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.sky.withValues(alpha: 0.2),
                child: Text(
                  (user?.firstName ?? 'C').substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.sky),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ]),
        ),
        TabBar(
          controller: tabController,
          tabs: tabs,
          labelColor: AppColors.navy,
          unselectedLabelColor: Colors.black38,
          labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w400),
          indicatorColor: AppColors.sky,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TAB 1 — DISCOVER
// ─────────────────────────────────────────────────────────────────────────────
class _DiscoverTab extends StatefulWidget {
  final void Function(ProductModel) onWishlist;
  final void Function(ProductModel) onBookmark;
  final Set<int> wishlistIds;
  final Set<int> bookmarkIds;

  const _DiscoverTab({
    required this.onWishlist, required this.onBookmark,
    required this.wishlistIds, required this.bookmarkIds,
  });

  @override
  State<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<_DiscoverTab> {
  String _categoryFilter = 'All';

  static const _categories = [
    'All', 'Agriculture', 'Healthcare', 'Energy',
    'Construction', 'Product Design', 'Information Technology'
  ];

  List<ProductModel> get _filtered {
    var list = List<ProductModel>.from(_dummyProducts);
    if (_categoryFilter != 'All') {
      list = list.where((p) => p.category == _categoryFilter).toList();
    }
    list.sort((a, b) => (b.likes * 2 + b.views).compareTo(a.likes * 2 + a.views));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(children: [
              // ── Search field — read-only, navigates to /search on tap ──
              SizedBox(
                height: 44,
                child: TextField(
                  readOnly: true,
                  onTap: () => context.push('/search'),
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search innovations, innovators...',
                    hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black38),
                    prefixIcon: const Icon(Icons.search, size: 20, color: Colors.black38),
                    filled: true,
                    fillColor: AppColors.offWhite,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.sky, width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) {
                    final c = _categories[i];
                    final isActive = _categoryFilter == c;
                    final color = c == 'All' ? AppColors.navy : (AppColors.categoryColors[c] ?? AppColors.navy);
                    return GestureDetector(
                      onTap: () => setState(() => _categoryFilter = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? color : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isActive ? color : AppColors.lightGray),
                        ),
                        child: Text(c, style: TextStyle(
                            fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600,
                            color: isActive ? Colors.white : Colors.black54)),
                      ),
                    );
                  },
                ),
              ),
            ]),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(children: [
              const Icon(Icons.local_fire_department_rounded, color: AppColors.crimson, size: 18),
              const SizedBox(width: 6),
              Text(
                _categoryFilter == 'All' ? 'Trending Now' : 'Top in $_categoryFilter',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.crimson.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
                child: Text('${filtered.length}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.crimson)),
              ),
            ]),
          ),
        ),

        filtered.isEmpty
            ? const SliverFillRemaining(
                child: _EmptyState(icon: Icons.search_off_rounded, title: 'No results', subtitle: 'Try a different search or category.'),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _DiscoverCard(
                      product: filtered[i],
                      index: i,
                      isWishlisted: widget.wishlistIds.contains(filtered[i].id),
                      isBookmarked: widget.bookmarkIds.contains(filtered[i].id),
                      onWishlist: () => widget.onWishlist(filtered[i]),
                      onBookmark: () => widget.onBookmark(filtered[i]),
                    ),
                    childCount: filtered.length,
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

class _DiscoverCard extends StatelessWidget {
  final ProductModel product;
  final int index;
  final bool isWishlisted;
  final bool isBookmarked;
  final VoidCallback onWishlist;
  final VoidCallback onBookmark;

  const _DiscoverCard({
    required this.product, required this.index,
    required this.isWishlisted, required this.isBookmarked,
    required this.onWishlist, required this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = AppColors.categoryColors[product.category] ?? AppColors.navy;
    return GestureDetector(
      onTap: () => context.go('/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.lightGray),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 110,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Stack(children: [
              Center(child: Icon(Icons.lightbulb_rounded, size: 40, color: catColor.withValues(alpha: 0.3))),
              Positioned(top: 10, left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: catColor, borderRadius: BorderRadius.circular(6)),
                  child: Text(product.category, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
              Positioned(top: 6, right: 6,
                child: Row(children: [
                  _ActionBtn(
                    icon: isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                    color: isBookmarked ? AppColors.navy : Colors.black45,
                    onTap: onBookmark,
                  ),
                  const SizedBox(width: 4),
                  _ActionBtn(
                    icon: isWishlisted ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                    color: isWishlisted ? AppColors.crimson : Colors.black45,
                    onTap: onWishlist,
                  ),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.navy),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Row(children: [
                if (product.kycStatus == 'verified') const Icon(Icons.verified_rounded, size: 12, color: AppColors.teal),
                if (product.kycStatus == 'verified') const SizedBox(width: 3),
                Expanded(child: Text(product.innovatorName,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.black45),
                    overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 8),
              const Divider(height: 1, color: AppColors.lightGray),
              const SizedBox(height: 8),
              Row(children: [
                _MiniStat(icon: Icons.favorite_rounded, value: '${product.likes}', color: AppColors.crimson),
                const SizedBox(width: 10),
                _MiniStat(icon: Icons.remove_red_eye_rounded, value: '${product.views}', color: Colors.black38),
                const SizedBox(width: 10),
                _MiniStat(icon: Icons.handshake_rounded, value: '${product.interestCount}', color: AppColors.teal),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.sky.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: const Text('View', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.sky)),
                ),
              ]),
            ]),
          ),
        ]),
      ).animate(delay: Duration(milliseconds: 50 * index)).fadeIn(duration: 350.ms).slideY(begin: 0.05, end: 0),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)],
      ),
      child: Icon(icon, size: 16, color: color),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  TAB 2 — WISHLIST
// ─────────────────────────────────────────────────────────────────────────────
class _WishlistTab extends StatelessWidget {
  final List<ProductModel> items;
  final void Function(ProductModel) onRemove;
  const _WishlistTab({required this.items, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _TabHeader(icon: Icons.favorite_rounded, iconColor: AppColors.crimson, title: 'Wishlist', subtitle: 'Products you\'re keeping an eye on', count: items.length),
      Expanded(
        child: items.isEmpty
            ? const _EmptyState(icon: Icons.favorite_outline_rounded, title: 'Your wishlist is empty', subtitle: 'Heart a product from Discover to save it here.')
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: items.length,
                itemBuilder: (ctx, i) => _SavedProductRow(
                  product: items[i], index: i,
                  actionIcon: Icons.favorite_rounded, actionColor: AppColors.crimson,
                  actionTooltip: 'Remove from wishlist', onAction: () => onRemove(items[i]),
                ),
              ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TAB 3 — BOOKMARKS
// ─────────────────────────────────────────────────────────────────────────────
class _BookmarksTab extends StatelessWidget {
  final List<ProductModel> items;
  final void Function(ProductModel) onRemove;
  const _BookmarksTab({required this.items, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _TabHeader(icon: Icons.bookmark_rounded, iconColor: AppColors.navy, title: 'Bookmarks', subtitle: 'Private saves — innovators are not notified', count: items.length),
      Expanded(
        child: items.isEmpty
            ? const _EmptyState(icon: Icons.bookmark_outline_rounded, title: 'No bookmarks yet', subtitle: 'Bookmark a product to privately save it for later.')
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: items.length,
                itemBuilder: (ctx, i) => _SavedProductRow(
                  product: items[i], index: i,
                  actionIcon: Icons.bookmark_remove_rounded, actionColor: AppColors.navy,
                  actionTooltip: 'Remove bookmark', onAction: () => onRemove(items[i]),
                ),
              ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED — Saved product row
// ─────────────────────────────────────────────────────────────────────────────
class _SavedProductRow extends StatelessWidget {
  final ProductModel product;
  final int index;
  final IconData actionIcon;
  final Color actionColor;
  final String actionTooltip;
  final VoidCallback onAction;

  const _SavedProductRow({
    required this.product, required this.index,
    required this.actionIcon, required this.actionColor,
    required this.actionTooltip, required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = AppColors.categoryColors[product.category] ?? AppColors.navy;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(color: catColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.lightbulb_rounded, color: catColor, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product.name, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: catColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: Text(product.category, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: catColor)),
            ),
            const SizedBox(width: 6),
            if (product.kycStatus == 'verified') const Icon(Icons.verified_rounded, size: 11, color: AppColors.teal),
            const SizedBox(width: 3),
            Expanded(child: Text(product.innovatorName, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.black45), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            _MiniStat(icon: Icons.favorite_rounded, value: '${product.likes}', color: AppColors.crimson),
            const SizedBox(width: 10),
            _MiniStat(icon: Icons.remove_red_eye_rounded, value: '${product.views}', color: Colors.black38),
          ]),
        ])),
        const SizedBox(width: 12),
        Column(children: [
          IconButton(icon: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.sky), onPressed: () => context.go('/product/${product.id}'), tooltip: 'View product'),
          IconButton(icon: Icon(actionIcon, size: 18, color: actionColor), onPressed: onAction, tooltip: actionTooltip),
        ]),
      ]),
    ).animate(delay: Duration(milliseconds: 50 * index)).fadeIn(duration: 300.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TAB 4 — MY INTERESTS
// ─────────────────────────────────────────────────────────────────────────────
class _InterestsTab extends StatelessWidget {
  final List<_InterestItem> items;
  const _InterestsTab({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _TabHeader(icon: Icons.handshake_rounded, iconColor: AppColors.teal, title: 'My Interests', subtitle: 'Formal interest requests you have sent', count: items.length),
      if (items.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(children: [
            _StatusPill('Accepted', items.where((i) => i.status == 'accepted').length, AppColors.teal),
            const SizedBox(width: 10),
            _StatusPill('Pending', items.where((i) => i.status == 'pending').length, AppColors.golden),
            const SizedBox(width: 10),
            _StatusPill('Declined', items.where((i) => i.status == 'declined').length, AppColors.crimson),
          ]),
        ),
      Expanded(
        child: items.isEmpty
            ? const _EmptyState(icon: Icons.handshake_outlined, title: 'No interests sent yet', subtitle: 'Express interest on a product to start a conversation.')
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: items.length,
                itemBuilder: (ctx, i) => _InterestRow(item: items[i], index: i),
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
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$count', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: color)),
    ]),
  );
}

class _InterestRow extends StatelessWidget {
  final _InterestItem item;
  final int index;
  const _InterestRow({required this.item, required this.index});

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'just now';
  }

  @override
  Widget build(BuildContext context) {
    final catColor = AppColors.categoryColors[item.category] ?? AppColors.navy;
    final statusColor = item.status == 'accepted' ? AppColors.teal : item.status == 'pending' ? AppColors.golden : AppColors.crimson;
    final statusIcon = item.status == 'accepted' ? Icons.check_circle_rounded : item.status == 'pending' ? Icons.pending_rounded : Icons.cancel_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: item.status == 'accepted' ? AppColors.teal.withValues(alpha: 0.3) : AppColors.lightGray),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: catColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.lightbulb_rounded, color: catColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.productName, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.navy),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('by ${item.innovatorName}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black45)),
          const SizedBox(height: 3),
          Text('Sent ${_timeAgo(item.sentAt)}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.black38)),
        ])),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(statusIcon, size: 12, color: statusColor),
              const SizedBox(width: 4),
              Text(item.status.toUpperCase(), style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
            ]),
          ),
          if (item.status == 'accepted') ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => context.go('/messages'),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppColors.sky.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 12, color: AppColors.sky),
                  SizedBox(width: 4),
                  Text('Message', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.sky)),
                ]),
              ),
            ),
          ],
        ]),
      ]),
    ).animate(delay: Duration(milliseconds: 60 * index)).fadeIn(duration: 350.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TAB 5 — PROFILE
// ─────────────────────────────────────────────────────────────────────────────
class _ClientProfile extends ConsumerWidget {
  final dynamic user;
  const _ClientProfile({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read directly from provider — never rely on passed-in user prop
    final u = ref.watch(authProvider).user;
    final firstName = u?.firstName ?? 'Client';
    final fullName = u != null ? '${u.firstName} ${u.lastName}' : 'Client';
    final username = u?.username ?? '—';
    final email = u?.email ?? '—';
    final kycStatus = u?.kycStatus ?? 'unverified';
    final userStatus = u?.userStatus ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('My Profile', style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.lightGray)),
            child: Column(children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: AppColors.sky.withValues(alpha: 0.15),
                child: Text(firstName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.sky)),
              ),
              const SizedBox(height: 14),
              Text(fullName, style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy)),
              Text('@$username', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black45)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: AppColors.sky.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.person_rounded, color: AppColors.sky, size: 14),
                  SizedBox(width: 6),
                  Text('Client / Investor', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.sky)),
                ]),
              ),
              const SizedBox(height: 20),
              const Divider(color: AppColors.lightGray),
              const SizedBox(height: 14),
              _ProfileRow(label: 'Email', value: email, icon: Icons.email_outlined),
              _ProfileRow(label: 'KYC Status', value: kycStatus.toUpperCase(), icon: Icons.verified_user_rounded),
              _ProfileRow(label: 'Account Status', value: userStatus == 1 ? 'Active' : 'Pending', icon: Icons.circle_rounded),
            ]),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () { ref.read(authProvider.notifier).logout(); context.go('/login'); },
              icon: const Icon(Icons.logout_rounded, color: AppColors.crimson, size: 18),
              label: const Text('Logout', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.crimson)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppColors.crimson.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _ProfileRow({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(children: [
      Icon(icon, size: 16, color: AppColors.sky),
      const SizedBox(width: 12),
      Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black45)),
      const Spacer(),
      Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _TabHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final int count;

  const _TabHeader({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.count});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
    color: Colors.white,
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text('$count', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: iconColor)),
          ),
        ]),
        Text(subtitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black38)),
      ])),
    ]),
  );
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _MiniStat({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 3),
      Text(value, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 60, color: AppColors.lightGray),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.navy)),
      const SizedBox(height: 6),
      Text(subtitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black38), textAlign: TextAlign.center),
    ]),
  );
}