import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/widgets/notification_bell.dart';
import '../../marketplace/providers/marketplace_provider.dart';
import '../../marketplace/widgets/category_filter_bar.dart';
import '../../marketplace/widgets/product_card.dart';
import '../providers/client_provider.dart';

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
//  PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────
// Wishlist and bookmarks are now handled by clientProvider (real API).
// Interests remain a local empty list until wired to the API.
final _interestsProvider = StateProvider<List<_InterestItem>>((ref) => const []);

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
    final cState = ref.watch(clientProvider);
    final wishlist = cState.wishlist;
    final bookmarks = cState.bookmarks;
    final interests = ref.watch(_interestsProvider);

    return Scaffold(
      backgroundColor: AppColors.midnight,
      body: Column(
        children: [
          _ClientTopBar(user: user, tabController: _tabController, tabs: _tabs),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const _DiscoverTab(),
                _WishlistTab(
                  items: wishlist,
                  onRemove: (p) {
                    ref.read(clientProvider.notifier).toggleWishlist(p);
                    _showSnack('Removed from wishlist', AppColors.crimson);
                  },
                ),
                _BookmarksTab(
                  items: bookmarks,
                  onRemove: (p) {
                    ref.read(clientProvider.notifier).toggleBookmark(p);
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
      decoration: BoxDecoration(
        color: AppColors.midnight,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
          child: Row(children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.golden, AppColors.warmEmber],
              ).createShader(bounds),
              child: const Text(
                'HIRAYA',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.sky.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.sky.withValues(alpha: 0.30)),
              ),
              child: const Text(
                'Client',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.sky),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.chat_bubble_rounded, color: Colors.white.withValues(alpha: 0.70)),
              onPressed: () => context.go('/messages'),
              tooltip: 'Messages',
            ),
            IconButton(
              icon: Icon(Icons.storefront_rounded, color: Colors.white.withValues(alpha: 0.70)),
              onPressed: () => context.go('/marketplace'),
              tooltip: 'Browse Marketplace',
            ),
            const NotificationBell(),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => tabController.animateTo(4),
<<<<<<< HEAD
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.sky, Color(0xFF1A6BAD)],
                  ),
                  shape: BoxShape.circle,
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
                    (user?.firstName ?? 'C').substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
=======
              child: UserAvatar(
                name:         user?.firstName ?? 'C',
                avatarBase64: user?.avatarBase64,
                radius:       16,
                backgroundColor: AppColors.sky.withValues(alpha: 0.2),
                foregroundColor: AppColors.sky,
>>>>>>> origin/master
              ),
            ),
            const SizedBox(width: 8),
          ]),
        ),
        TabBar(
          controller: tabController,
          tabs: tabs,
          labelColor: AppColors.golden,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.40),
          labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w400),
          indicatorColor: AppColors.golden,
          indicatorWeight: 2.5,
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
class _DiscoverTab extends ConsumerStatefulWidget {
  const _DiscoverTab();
  @override
  ConsumerState<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends ConsumerState<_DiscoverTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(marketplaceProvider.notifier).loadProducts());
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(marketplaceProvider);
    final notifier = ref.read(marketplaceProvider.notifier);
    final products = state.filtered;

    return Column(children: [
      // Search bar
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: GestureDetector(
          onTap: () => context.push('/search'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(children: [
              Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.35), size: 20),
              const SizedBox(width: 12),
              Text('Search innovations, innovators...', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.white.withValues(alpha: 0.35))),
            ]),
          ),
        ),
      ),

      // Category filter
      CategoryFilterBar(
        selected: state.selectedCategory,
        onSelect: notifier.setCategory,
      ),

      const SizedBox(height: 8),

      // Count + sort
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          Text('${products.length} innovations', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white.withValues(alpha: 0.45))),
          const Spacer(),
          PopupMenuButton<String>(
            onSelected: notifier.setSort,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: const Color(0xFF1A2A3A),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.sort_rounded, size: 16, color: Colors.white.withValues(alpha: 0.60)),
                const SizedBox(width: 6),
                Text('Sort', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white.withValues(alpha: 0.60))),
              ]),
            ),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'newest',        child: Text('Newest First',  style: TextStyle(fontFamily: 'Poppins', fontSize: 13))),
              const PopupMenuItem(value: 'most_liked',    child: Text('Most Liked',    style: TextStyle(fontFamily: 'Poppins', fontSize: 13))),
              const PopupMenuItem(value: 'most_viewed',   child: Text('Most Viewed',   style: TextStyle(fontFamily: 'Poppins', fontSize: 13))),
              const PopupMenuItem(value: 'most_interest', child: Text('Most Interest', style: TextStyle(fontFamily: 'Poppins', fontSize: 13))),
            ],
          ),
        ]),
      ),

      const SizedBox(height: 12),

      // Grid
      Expanded(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
            : products.isEmpty
                ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.search_off_rounded, size: 56, color: AppColors.lightGray),
                    SizedBox(height: 12),
                    Text('No innovations found', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
                  ]))
                : RefreshIndicator(
                    onRefresh: notifier.loadProducts,
                    color: AppColors.teal,
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 1000 ? 3 : MediaQuery.of(context).size.width > 600 ? 2 : 1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: products.length,
                      itemBuilder: (_, i) => ProductCard(product: products[i], index: i),
                    ),
                  ),
      ),
    ]);
  }
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
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(color: catColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.lightbulb_rounded, color: catColor, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product.name, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: catColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
              child: Text(product.category, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: catColor)),
            ),
            const SizedBox(width: 6),
            if (product.kycStatus == 'verified') const Icon(Icons.verified_rounded, size: 11, color: AppColors.teal),
            const SizedBox(width: 3),
            Expanded(child: Text(product.innovatorName, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white.withValues(alpha: 0.40)), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            _MiniStat(icon: Icons.favorite_rounded, value: '${product.likes}', color: AppColors.crimson),
            const SizedBox(width: 10),
            _MiniStat(icon: Icons.remove_red_eye_rounded, value: '${product.views}', color: Colors.white38),
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
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.status == 'accepted'
              ? AppColors.teal.withValues(alpha: 0.30)
              : Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: catColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.lightbulb_rounded, color: catColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.productName, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('by ${item.innovatorName}', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
          const SizedBox(height: 3),
          Text('Sent ${_timeAgo(item.sentAt)}', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white.withValues(alpha: 0.30))),
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
          const Text('My Profile', style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Column(children: [
<<<<<<< HEAD
              Container(
                width: 76, height: 76,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.sky, Color(0xFF1A6BAD)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.sky.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 6))],
                ),
                child: Center(child: Text(firstName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white))),
=======
              UserAvatar(
                name:         firstName,
                avatarBase64: u?.avatarBase64,
                radius:       38,
                backgroundColor: AppColors.sky.withValues(alpha: 0.15),
                foregroundColor: AppColors.sky,
                uploadable:   true,
                onUpload: (base64) async {
                  final err = await ref.read(authProvider.notifier).updateAvatar(base64);
                  if (err != null && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(err), backgroundColor: Colors.red),
                    );
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile picture updated!')),
                    );
                  }
                },
>>>>>>> origin/master
              ),
              const SizedBox(height: 14),
              Text(fullName, style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
              Text('@$username', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white.withValues(alpha: 0.45))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.sky.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.sky.withValues(alpha: 0.30)),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.person_rounded, color: AppColors.sky, size: 14),
                  SizedBox(width: 6),
                  Text('Client / Investor', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.sky)),
                ]),
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.white.withValues(alpha: 0.10)),
              const SizedBox(height: 14),
              _ProfileRow(label: 'Email', value: email, icon: Icons.email_outlined),
              _ProfileRow(label: 'KYC Status', value: kycStatus.toUpperCase(), icon: Icons.verified_user_rounded),
              _ProfileRow(label: 'Account Status', value: userStatus == 1 ? 'Active' : 'Pending', icon: Icons.circle_rounded),
            ]),
          ),
          const SizedBox(height: 20),
          _SocialLinksCard(socialLinks: u?.socialLinks ?? {}),
          const SizedBox(height: 20),
          const _ThemeToggleCard(),
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
      Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white.withValues(alpha: 0.45))),
      const Spacer(),
      Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  THEME TOGGLE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ThemeToggleCard extends ConsumerWidget {
  const _ThemeToggleCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final bg     = isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.navy.withValues(alpha: 0.04);
    final border = isDark ? Colors.white12 : AppColors.lightGray;
    final label  = isDark ? 'Dark Mode' : 'Light Mode';
    final sub    = isDark ? 'Switch to light' : 'Switch to dark';
    final icon   = isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded;
    final color  = isDark ? AppColors.golden : AppColors.sky;
    final textPrimary   = isDark ? Colors.white : AppColors.navy;
    final textSecondary = isDark ? Colors.white38 : Colors.black38;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
          Text(sub,   style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: textSecondary)),
        ]),
        const Spacer(),
        Switch(
          value: isDark,
          onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
          activeColor: AppColors.sky,
          inactiveThumbColor: AppColors.navy.withValues(alpha: 0.5),
          inactiveTrackColor: AppColors.lightGray,
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SOCIAL LINKS CARD
// ─────────────────────────────────────────────────────────────────────────────
class _SocialLinksCard extends ConsumerStatefulWidget {
  final Map<String, String> socialLinks;
  const _SocialLinksCard({required this.socialLinks});

  @override
  ConsumerState<_SocialLinksCard> createState() => _SocialLinksCardState();
}

class _SocialLinksCardState extends ConsumerState<_SocialLinksCard> {
  bool _editing = false;
  bool _saving = false;
  late final Map<String, TextEditingController> _ctrls;

  static const _fields = [
    ('facebook',  'Facebook',  Icons.facebook_rounded),
    ('instagram', 'Instagram', Icons.camera_alt_rounded),
    ('linkedin',  'LinkedIn',  Icons.work_rounded),
    ('x',         'X / Twitter', Icons.close_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _ctrls = {
      for (final f in _fields)
        f.$1: TextEditingController(text: widget.socialLinks[f.$1] ?? ''),
    };
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final body = {for (final f in _fields) f.$1: _ctrls[f.$1]!.text.trim()};
      await ref.read(apiServiceProvider).put('users/me/social', body, auth: true);
      setState(() { _editing = false; _saving = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Social links updated', style: TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.share_rounded, size: 16, color: Colors.white.withValues(alpha: 0.60)),
          const SizedBox(width: 8),
          Text('Social Links', style: TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.85))),
          const Spacer(),
          if (!_editing)
            TextButton.icon(
              onPressed: () => setState(() => _editing = true),
              icon: const Icon(Icons.edit_rounded, size: 14),
              label: const Text('Edit', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
            ),
        ]),
        const SizedBox(height: 12),
        for (final f in _fields) ...[
          if (_editing)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextFormField(
                controller: _ctrls[f.$1],
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                decoration: InputDecoration(
                  labelText: f.$2,
                  labelStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                  prefixIcon: Icon(f.$3, size: 18, color: AppColors.navy),
                  hintText: 'https://...',
                  hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black38),
                  filled: true, fillColor: AppColors.offWhite,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.lightGray)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.lightGray)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.teal, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Icon(f.$3, size: 16, color: (_ctrls[f.$1]!.text.isEmpty) ? Colors.black26 : AppColors.navy),
                const SizedBox(width: 10),
                Text(f.$2, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black45)),
                const Spacer(),
                Flexible(
                  child: Text(
                    _ctrls[f.$1]!.text.isEmpty ? 'Not set' : _ctrls[f.$1]!.text,
                    style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 12,
                      color: _ctrls[f.$1]!.text.isEmpty ? Colors.black26 : AppColors.sky,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),
        ],
        if (_editing) ...[
          const SizedBox(height: 4),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => setState(() => _editing = false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.lightGray),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ],
      ]),
    );
  }
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
    color: AppColors.midnight,
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(6)),
            child: Text('$count', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: iconColor)),
          ),
        ]),
        Text(subtitle, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white.withValues(alpha: 0.40))),
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
      Icon(icon, size: 60, color: Colors.white.withValues(alpha: 0.15)),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 6),
      Text(subtitle, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white.withValues(alpha: 0.40)), textAlign: TextAlign.center),
    ]),
  );
}