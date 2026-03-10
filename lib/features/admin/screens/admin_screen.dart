import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/user_model.dart';
import 'analytics_screen.dart';
import '../providers/admin_provider.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(adminProvider.notifier).loadAll());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminProvider);
    final notifier = ref.read(adminProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      body: Row(
        children: [
          // Sidebar
          _AdminSidebar(
            activeTab: state.activeTab,
            onTabChange: notifier.setTab,
            pendingCount: state.stats.pendingProducts,
          ),

          // Main content
          Expanded(
            child: Column(
              children: [
                // Top bar
                _AdminTopBar(),
                // Content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: KeyedSubtree(
                      key: ValueKey(state.activeTab),
                      child: _buildTab(state, notifier),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(AdminState state, AdminNotifier notifier) {
    switch (state.activeTab) {
      case 'dashboard':
        return _DashboardTab(state: state);
      case 'products':
        return _ProductsTab(
          products: state.pendingProducts,
          onApprove: notifier.approveProduct,
          onReject: notifier.rejectProduct,
        );
      case 'users':
        return _UsersTab(
          users: state.users,
          onApprove: notifier.approveUser,
        );
      case 'analytics':
        return const AnalyticsScreen();
      default:
        return _DashboardTab(state: state);
    }
  }
}

// ─── SIDEBAR ──────────────────────────────────────────────────────────────────
class _AdminSidebar extends StatelessWidget {
  final String activeTab;
  final void Function(String) onTabChange;
  final int pendingCount;

  const _AdminSidebar({
    required this.activeTab,
    required this.onTabChange,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: const Color(0xFF0A1118),
      child: Column(
        children: [
          // Logo
          Container(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
            child: Row(
              children: [
                Image.asset('assets/images/logo/final-logo.png',
                    height: 36),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HIRAYA',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 2,
                        )),
                    Text('Admin Panel',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: AppColors.golden,
                          letterSpacing: 1,
                        )),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),

          _SidebarItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            tab: 'dashboard',
            activeTab: activeTab,
            onTap: onTabChange,
          ),
          _SidebarItem(
            icon: Icons.pending_actions_rounded,
            label: 'Pending Reviews',
            tab: 'products',
            activeTab: activeTab,
            onTap: onTabChange,
            badge: pendingCount > 0 ? pendingCount : null,
          ),
          _SidebarItem(
            icon: Icons.people_rounded,
            label: 'Users',
            tab: 'users',
            activeTab: activeTab,
            onTap: onTabChange,
          ),
          _SidebarItem(
            icon: Icons.bar_chart_rounded,
            label: 'Analytics',
            tab: 'analytics',
            activeTab: activeTab,
            onTap: onTabChange,
          ),

          const Spacer(),

          // Back to marketplace
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () => context.go('/marketplace'),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.storefront_rounded,
                        color: Colors.white54, size: 18),
                    SizedBox(width: 10),
                    Text('View Marketplace',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.white54,
                        )),
                  ],
                ),
              ),
            ),
          ),

          // Logout
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: GestureDetector(
              onTap: () => context.go('/login'),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.crimson
                          .withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout_rounded,
                        color: AppColors.crimson, size: 18),
                    SizedBox(width: 10),
                    Text('Logout',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: AppColors.crimson,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tab;
  final String activeTab;
  final void Function(String) onTap;
  final int? badge;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.tab,
    required this.activeTab,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = activeTab == tab;
    return GestureDetector(
      onTap: () => onTap(tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.teal.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? Border.all(
                  color: AppColors.teal.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                color:
                    isActive ? AppColors.teal : Colors.white38,
                size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: isActive
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: isActive ? Colors.white : Colors.white54,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.crimson,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── TOP BAR ──────────────────────────────────────────────────────────────────
class _AdminTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1118),
        border: Border(
            bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          const Text(
            'Admin Panel',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.teal.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_rounded,
                    color: AppColors.teal, size: 14),
                SizedBox(width: 6),
                Text('admin@hiraya.com',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.teal,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DASHBOARD TAB ────────────────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  final AdminState state;
  const _DashboardTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dashboard',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              )).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 6),
          Text(
            'System overview — ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.white38,
            ),
          ),

          const SizedBox(height: 28),

          // Stats grid
          GridView.count(
            shrinkWrap: true,
            crossAxisCount:
                MediaQuery.of(context).size.width > 1100 ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.6,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _StatCard(
                icon: Icons.people_rounded,
                label: 'Total Users',
                value: '${state.stats.totalUsers}',
                color: AppColors.sky,
                index: 0,
              ),
              _StatCard(
                icon: Icons.lightbulb_rounded,
                label: 'Live Innovations',
                value: '${state.stats.totalProducts}',
                color: AppColors.teal,
                index: 1,
              ),
              _StatCard(
                icon: Icons.pending_actions_rounded,
                label: 'Pending Review',
                value: '${state.stats.pendingProducts}',
                color: AppColors.golden,
                index: 2,
                urgent: state.stats.pendingProducts > 0,
              ),
              _StatCard(
                icon: Icons.handshake_rounded,
                label: 'Total Interests',
                value: '${state.stats.totalInterests}',
                color: AppColors.crimson,
                index: 3,
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Recent pending
          if (state.pendingProducts.isNotEmpty) ...[
            Row(
              children: [
                const Text('Pending Approvals',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    )),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.golden.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${state.pendingProducts.length} waiting',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.golden,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...state.pendingProducts
                .take(3)
                .toList()
                .asMap()
                .entries
                .map((e) => _PendingRow(
                      product: e.value,
                      index: e.key,
                    )),
          ],

          const SizedBox(height: 28),

          // Category breakdown
          const Text('Category Breakdown',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              )),
          const SizedBox(height: 16),
          _CategoryBreakdown(),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final int index;
  final bool urgent;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.index,
    this.urgent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151F2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: urgent
              ? color.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.06),
          width: urgent ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              if (urgent)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 80 * index))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }
}

class _PendingRow extends StatelessWidget {
  final ProductModel product;
  final int index;
  const _PendingRow({required this.product, required this.index});

  @override
  Widget build(BuildContext context) {
    final color =
        AppColors.categoryColors[product.category] ?? AppColors.navy;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF151F2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.lightbulb_rounded,
                color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
                Text(product.innovatorName,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.white38)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.golden.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('PENDING',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.golden)),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 60 * index))
        .fadeIn();
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final List<Map<String, dynamic>> _cats = const [
    {'name': 'Agriculture', 'count': 1, 'color': AppColors.teal},
    {'name': 'Healthcare', 'count': 1, 'color': AppColors.crimson},
    {'name': 'Energy', 'count': 1, 'color': AppColors.golden},
    {
      'name': 'Construction',
      'count': 1,
      'color': AppColors.navy
    },
    {
      'name': 'Product Design',
      'count': 1,
      'color': AppColors.sky
    },
    {
      'name': 'Information Technology',
      'count': 1,
      'color': Color(0xFF1B4B8A)
    },
  ];

  @override
  Widget build(BuildContext context) {
    final total =
        _cats.fold<int>(0, (sum, c) => sum + (c['count'] as int));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151F2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: _cats
            .asMap()
            .entries
            .map((entry) {
              final cat = entry.value;
              final pct = total > 0
                  ? (cat['count'] as int) / total
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    SizedBox(
                      width: 150,
                      child: Text(
                        cat['name'],
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.06),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(
                                  cat['color'] as Color),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${cat['count']}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            })
            .toList(),
      ),
    );
  }
}

// ─── PRODUCTS TAB ─────────────────────────────────────────────────────────────
class _ProductsTab extends StatelessWidget {
  final List<ProductModel> products;
  final Future<void> Function(int) onApprove;
  final Future<void> Function(int) onReject;

  const _ProductsTab({
    required this.products,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Pending Reviews',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  )),
              const SizedBox(width: 12),
              if (products.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.golden.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${products.length}',
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.golden)),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (products.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: const Color(0xFF151F2B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: AppColors.teal, size: 48),
                    SizedBox(height: 12),
                    Text('All caught up!',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        )),
                    SizedBox(height: 6),
                    Text('No pending products to review.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.white38,
                        )),
                  ],
                ),
              ),
            )
          else
            ...products.asMap().entries.map((e) =>
                _ProductReviewCard(
                  product: e.value,
                  index: e.key,
                  onApprove: () => onApprove(e.value.id),
                  onReject: () => onReject(e.value.id),
                )),
        ],
      ),
    );
  }
}

class _ProductReviewCard extends StatelessWidget {
  final ProductModel product;
  final int index;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ProductReviewCard({
    required this.product,
    required this.index,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        AppColors.categoryColors[product.category] ?? AppColors.navy;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151F2B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.lightbulb_rounded,
                    color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    Text(
                        '${product.category} · by ${product.innovatorName}',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.white38)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color:
                      AppColors.golden.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.golden
                          .withValues(alpha: 0.3)),
                ),
                child: const Text('PENDING',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.golden)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            product.description,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.white54,
                height: 1.5),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.crimson),
                  label: const Text('Reject',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          color: AppColors.crimson)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color:
                            AppColors.crimson.withValues(alpha: 0.4)),
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_rounded,
                      size: 16, color: Colors.white),
                  label: const Text('Approve & Publish',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 80 * index))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0);
  }
}

// ─── USERS TAB ────────────────────────────────────────────────────────────────
class _UsersTab extends StatelessWidget {
  final List<UserModel> users;
  final Future<void> Function(int) onApprove;

  const _UsersTab(
      {required this.users, required this.onApprove});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('User Management',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              )),
          const SizedBox(height: 24),

          // Table header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Expanded(
                    flex: 3,
                    child: _TableHeader('Name / Username')),
                Expanded(
                    flex: 3,
                    child: _TableHeader('Email')),
                Expanded(
                    flex: 1,
                    child: _TableHeader('Role')),
                Expanded(
                    flex: 1,
                    child: _TableHeader('KYC')),
                Expanded(
                    flex: 1,
                    child: _TableHeader('Status')),
                SizedBox(width: 90),
              ],
            ),
          ),

          const SizedBox(height: 8),

          if (users.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF151F2B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('No users found.',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white38)),
              ),
            )
          else
            ...users.asMap().entries.map((e) => _UserRow(
                  user: e.value,
                  index: e.key,
                  onApprove: () => onApprove(e.value.id),
                )),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white38,
          letterSpacing: 0.5,
        ));
  }
}

class _UserRow extends StatelessWidget {
  final UserModel user;
  final int index;
  final VoidCallback onApprove;

  const _UserRow({
    required this.user,
    required this.index,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    final roleColor = user.role == 'innovator'
        ? AppColors.teal
        : user.role == 'admin'
            ? AppColors.crimson
            : AppColors.sky;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF151F2B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          // Name
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      roleColor.withValues(alpha: 0.15),
                  child: Text(
                    user.firstName.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: roleColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis),
                      Text('@${user.username}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Colors.white38,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Email
          Expanded(
            flex: 3,
            child: Text(user.email,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.white54,
                ),
                overflow: TextOverflow.ellipsis),
          ),
          // Role
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                user.role.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: roleColor,
                ),
              ),
            ),
          ),
          // KYC
          Expanded(
            flex: 1,
            child: _StatusDot(
              label: user.kycStatus,
              color: user.kycStatus == 'verified'
                  ? AppColors.teal
                  : user.kycStatus == 'pending'
                      ? AppColors.golden
                      : Colors.white38,
            ),
          ),
          // Account status
          Expanded(
            flex: 1,
            child: _StatusDot(
              label: user.userStatus == 1
                  ? 'Active'
                  : 'Pending',
              color: user.userStatus == 1
                  ? AppColors.teal
                  : AppColors.golden,
            ),
          ),
          // Action
          SizedBox(
            width: 90,
            child: user.userStatus == 0
                ? ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(8)),
                    ),
                    child: const Text('Approve',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  )
                : const Text('—',
                    style: TextStyle(color: Colors.white24)),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 40 * index))
        .fadeIn(duration: 300.ms);
  }
}

class _StatusDot extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
                shape: BoxShape.circle, color: color)),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: color)),
      ],
    );
  }
}