// lib/features/admin/screens/admin_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/theme_provider.dart';
import 'analytics_screen.dart';
import '../providers/admin_provider.dart';
import '../providers/analytics_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/widgets/notification_bell.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(adminProvider.notifier).loadAll());
  }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(adminProvider);
    final notifier = ref.read(adminProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1923),
      body: Row(
        children: [
          _AdminSidebar(
            activeTab:    state.activeTab,
            onTabChange:  notifier.setTab,
            pendingCount: state.stats.pendingProducts,
          ),
          Expanded(
            child: Column(
              children: [
                _AdminTopBar(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: KeyedSubtree(
                      key:   ValueKey(state.activeTab),
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
          products:  state.pendingProducts,
          onApprove: notifier.approveProduct,
          onReject:  notifier.rejectProduct,
        );
      case 'users':
        return _UsersTab(
          users:     state.users,
          onApprove: notifier.approveUser,
          onReject:  notifier.rejectUser,
          onDelete:  notifier.deleteUser,
          onPromote:  notifier.promoteToAdmin,
          onDemote:   notifier.demoteFromAdmin,
        );
      case 'analytics':
        return const AnalyticsScreen();
      default:
        return _DashboardTab(state: state);
    }
  }
}

// ─── SIDEBAR ──────────────────────────────────────────────────────────────────
class _AdminSidebar extends ConsumerWidget {
  final String activeTab;
  final void Function(String) onTabChange;
  final int pendingCount;

  const _AdminSidebar({
    required this.activeTab,
    required this.onTabChange,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 240,
      color: const Color(0xFF0A1118),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppColors.golden, AppColors.warmEmber],
                ).createShader(bounds),
                child: const Text(
                  'Digital Platform',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.crimson.withValues(alpha: 0.35)),
                ),
                child: const Text('ADMIN PANEL', style: TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.crimson, letterSpacing: 1.5)),
              ),
            ]),
          ),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
          _SidebarItem(icon: Icons.dashboard_rounded,       label: 'Dashboard',       tab: 'dashboard', activeTab: activeTab, onTap: onTabChange),
          _SidebarItem(icon: Icons.pending_actions_rounded, label: 'Pending Reviews', tab: 'products',  activeTab: activeTab, onTap: onTabChange, badge: pendingCount > 0 ? pendingCount : null),
          _SidebarItem(icon: Icons.people_rounded,          label: 'Users',           tab: 'users',     activeTab: activeTab, onTap: onTabChange),
          _SidebarItem(icon: Icons.bar_chart_rounded,       label: 'Analytics',       tab: 'analytics', activeTab: activeTab, onTap: onTabChange),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: () => context.push('/marketplace'),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
                child: const Row(children: [
                  Icon(Icons.storefront_rounded, color: Colors.white54, size: 18),
                  SizedBox(width: 10),
                  Text('View Marketplace', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white54)),
                ]),
              ),
            ),
          ),
          _AdminThemeToggle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: GestureDetector(
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:        AppColors.crimson.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border:       Border.all(color: AppColors.crimson.withValues(alpha: 0.3)),
                ),
                child: const Row(children: [
                  Icon(Icons.logout_rounded, color: AppColors.crimson, size: 18),
                  SizedBox(width: 10),
                  Text('Logout', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.crimson, fontWeight: FontWeight.w600)),
                ]),
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
  final String label, tab, activeTab;
  final void Function(String) onTap;
  final int? badge;

  const _SidebarItem({required this.icon, required this.label, required this.tab, required this.activeTab, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    final isActive = activeTab == tab;
    return GestureDetector(
      onTap: () => onTap(tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin:   const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding:  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:        isActive ? AppColors.teal.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border:       isActive ? Border.all(color: AppColors.teal.withValues(alpha: 0.3)) : null,
        ),
        child: Row(children: [
          Icon(icon, color: isActive ? AppColors.teal : Colors.white38, size: 18),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: isActive ? FontWeight.w700 : FontWeight.w400, color: isActive ? Colors.white : Colors.white54))),
          if (badge != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: AppColors.crimson, borderRadius: BorderRadius.circular(10)),
              child: Text('$badge', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
        ]),
      ),
    );
  }
}

// ─── SIDEBAR THEME TOGGLE ─────────────────────────────────────────────────────
class _AdminThemeToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: () => ref.read(themeProvider.notifier).toggle(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.golden.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? AppColors.golden.withValues(alpha: 0.3)
                  : Colors.white12,
            ),
          ),
          child: Row(children: [
            Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: isDark ? AppColors.golden : Colors.white54,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isDark ? 'Dark Mode' : 'Light Mode',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: isDark ? AppColors.golden : Colors.white54,
                ),
              ),
            ),
            Switch(
              value: isDark,
              onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: AppColors.golden,
              inactiveThumbColor: Colors.white38,
              inactiveTrackColor: Colors.white12,
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── TOP BAR ──────────────────────────────────────────────────────────────────
class _AdminTopBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = ref.watch(authProvider).user?.email ?? 'admin';
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(color: Color(0xFF0A1118), border: Border(bottom: BorderSide(color: Colors.white10))),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.crimson.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.crimson.withValues(alpha: 0.30)),
          ),
          child: const Text('ADMIN', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.crimson, letterSpacing: 1.5)),
        ),
        const SizedBox(width: 12),
        const Text('Control Panel', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppColors.golden.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.golden.withValues(alpha: 0.25))),
          child: const Row(children: [
            Icon(Icons.admin_panel_settings_rounded, color: AppColors.golden, size: 14),
            SizedBox(width: 6),
            Text('Super Admin', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.golden, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(width: 8),
        const NotificationBell(),
      ]),
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
          const Text('Dashboard', style: TextStyle(fontFamily: 'Poppins', fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 6),
          Text('System overview — ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white38)),
          const SizedBox(height: 28),
          GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 1100 ? 4 : 2,
            crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.6,
            children: [
              _StatCard(icon: Icons.people_rounded,          label: 'Total Users',      value: '${state.stats.totalUsers}',      color: AppColors.sky,     index: 0),
              _StatCard(icon: Icons.lightbulb_rounded,       label: 'Live Innovations', value: '${state.stats.totalProducts}',   color: AppColors.teal,    index: 1),
              _StatCard(icon: Icons.pending_actions_rounded, label: 'Pending Review',   value: '${state.stats.pendingProducts}', color: AppColors.golden,  index: 2, urgent: state.stats.pendingProducts > 0),
              _StatCard(icon: Icons.handshake_rounded,       label: 'Total Interests',  value: '${state.stats.totalInterests}',  color: AppColors.crimson, index: 3),
            ],
          ),
          const SizedBox(height: 28),
          if (state.pendingProducts.isNotEmpty) ...[
            Row(children: [
              const Text('Pending Approvals', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppColors.golden.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                child: Text('${state.pendingProducts.length} waiting', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.golden)),
              ),
            ]),
            const SizedBox(height: 16),
            ...state.pendingProducts.take(3).toList().asMap().entries.map((e) => _PendingRow(product: e.value, index: e.key)),
          ],
          const SizedBox(height: 28),
          const Text('Category Breakdown', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 16),
          _CategoryBreakdown(),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon; final String label, value; final Color color; final int index; final bool urgent;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color, required this.index, this.urgent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151F2B), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: urgent ? color.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.06), width: urgent ? 1.5 : 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 18)),
          if (urgent) Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        ]),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
          Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white38)),
        ]),
      ]),
    ).animate(delay: Duration(milliseconds: 80 * index)).fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0);
  }
}

class _PendingRow extends StatelessWidget {
  final ProductModel product; final int index;
  const _PendingRow({required this.product, required this.index});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColors[product.category] ?? AppColors.navy;
    return Container(
      margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF151F2B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.lightbulb_rounded, color: color, size: 16)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product.name,          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          Text(product.innovatorName, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white38)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.golden.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
            child: const Text('PENDING', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.golden))),
      ]),
    ).animate(delay: Duration(milliseconds: 60 * index)).fadeIn();
  }
}

class _CategoryBreakdown extends ConsumerWidget {
  const _CategoryBreakdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(analyticsProvider).categoryDistribution;
    final isLoading = ref.watch(analyticsProvider).isLoading;

    if (isLoading && cats.isEmpty) {
      return Container(
        height: 100,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFF151F2B), borderRadius: BorderRadius.circular(16)),
        child: const Center(child: CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2)),
      );
    }
    if (cats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: const Color(0xFF151F2B), borderRadius: BorderRadius.circular(16)),
        child: const Center(child: Text('No approved products yet', style: TextStyle(fontFamily: 'Poppins', color: Colors.white38))),
      );
    }

    final total = cats.fold<int>(0, (sum, c) => sum + ((c['count'] as num?)?.toInt() ?? 0));
    final palette = [AppColors.teal, AppColors.crimson, AppColors.golden, AppColors.sky, AppColors.navy, const Color(0xFF9B59B6), const Color(0xFF1B4B8A)];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF151F2B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Column(children: cats.asMap().entries.map((entry) {
        final cat   = entry.value;
        final count = (cat['count'] as num?)?.toInt() ?? 0;
        final pct   = total > 0 ? count / total : 0.0;
        final color = AppColors.categoryColors[cat['category'] as String? ?? ''] ?? palette[entry.key % palette.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(children: [
            SizedBox(width: 160, child: Text(cat['category'] as String? ?? '', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white54), overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 12),
            Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: pct, backgroundColor: Colors.white.withValues(alpha: 0.06), valueColor: AlwaysStoppedAnimation<Color>(color), minHeight: 6))),
            const SizedBox(width: 12),
            Text('$count', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        );
      }).toList()),
    );
  }
}

// ─── PRODUCTS TAB ─────────────────────────────────────────────────────────────
class _ProductsTab extends StatelessWidget {
  final List<ProductModel> products;
  final Future<String?> Function(int) onApprove, onReject;
  const _ProductsTab({required this.products, required this.onApprove, required this.onReject});

  void _handleResult(BuildContext context, String? error) {
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppColors.crimson,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Pending Reviews', style: TextStyle(fontFamily: 'Poppins', fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(width: 12),
          if (products.isNotEmpty)
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.golden.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Text('${products.length}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.golden))),
        ]),
        const SizedBox(height: 24),
        if (products.isEmpty)
          Container(padding: const EdgeInsets.all(40), decoration: BoxDecoration(color: const Color(0xFF151F2B), borderRadius: BorderRadius.circular(16)),
              child: const Center(child: Column(children: [
                Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 48), SizedBox(height: 12),
                Text('All caught up!', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)), SizedBox(height: 6),
                Text('No pending products to review.', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white38)),
              ])))
        else
          ...products.asMap().entries.map((e) => _ProductReviewCard(
            product:   e.value,
            index:     e.key,
            onApprove: () async => _handleResult(context, await onApprove(e.value.id)),
            onReject:  () async => _handleResult(context, await onReject(e.value.id)),
          )),
      ]),
    );
  }
}

class _ProductReviewCard extends StatelessWidget {
  final ProductModel product; final int index; final VoidCallback onApprove, onReject;
  const _ProductReviewCard({required this.product, required this.index, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColors[product.category] ?? AppColors.navy;
    return Container(
      margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF151F2B), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.lightbulb_rounded, color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            Text('${product.category} · by ${product.innovatorName}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white38)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: AppColors.golden.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.golden.withValues(alpha: 0.3))),
              child: const Text('PENDING', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.golden))),
        ]),
        const SizedBox(height: 14),
        Text(product.description, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white54, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 16),
        const Divider(color: Colors.white10, height: 1),
        const SizedBox(height: 16),
        Row(children: [
          TextButton(
            onPressed: () => _showProductDetail(context, product.id, onApprove, onReject),
            child: const Text('View Details',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.sky)),
          ),
          const Spacer(),
          Expanded(child: OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.crimson),
            label: const Text('Reject', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.crimson)),
            style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.crimson.withValues(alpha: 0.4)), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          )),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: ElevatedButton.icon(
            onPressed: onApprove,
            icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
            label: const Text('Approve & Publish', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          )),
        ]),
      ]),
    ).animate(delay: Duration(milliseconds: 80 * index)).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

// ─── USERS TAB ────────────────────────────────────────────────────────────────
class _UsersTab extends StatelessWidget {
  final List<UserModel> users;
  final Future<String?> Function(int) onApprove, onReject, onDelete, onPromote, onDemote;

  const _UsersTab({required this.users, required this.onApprove, required this.onReject, required this.onDelete, required this.onPromote, required this.onDemote});

  void _handleResult(BuildContext context, String? error) {
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppColors.crimson,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _confirmPromote(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF151F2B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.admin_panel_settings_rounded, color: AppColors.golden, size: 24),
          SizedBox(width: 10),
          Text('Promote to Admin', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('You are about to grant admin privileges to:', style: TextStyle(fontFamily: 'Poppins', color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.golden.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.golden.withValues(alpha: 0.3))),
            child: Row(children: [
              CircleAvatar(radius: 20, backgroundColor: AppColors.golden.withValues(alpha: 0.2),
                  child: Text(user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: AppColors.golden))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.fullName, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14)),
                Text(user.email,   style: const TextStyle(fontFamily: 'Poppins', color: Colors.white38, fontSize: 12)),
              ])),
            ]),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text('Admin users have full access to manage users, products, and platform settings.', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.orange))),
            ]),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: Colors.white54))),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              _handleResult(context, await onPromote(user.id));
            },
            icon:  const Icon(Icons.admin_panel_settings_rounded, size: 16, color: Colors.white),
            label: const Text('Yes, Make Admin', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.golden, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ],
      ),
    );
  }

  void _confirmDemote(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF151F2B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.remove_moderator_rounded, color: Colors.white54, size: 24),
          SizedBox(width: 10),
          Text('Remove Admin Access', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18)),
        ]),
        content: Text(
          'Remove admin access from ${user.fullName}? They will be restored to their original role.',
          style: const TextStyle(fontFamily: 'Poppins', color: Colors.white54, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: Colors.white54))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _handleResult(context, await onDemote(user.id));
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A3444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Remove Admin', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('User Management', style: TextStyle(fontFamily: 'Poppins', fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: AppColors.sky.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Text('${users.length} total', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.sky))),
        ]),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(10)),
          child: const Row(children: [
            Expanded(flex: 3, child: _TableHeader('Name / Username')),
            Expanded(flex: 3, child: _TableHeader('Email')),
            Expanded(flex: 1, child: _TableHeader('Role')),
            Expanded(flex: 1, child: _TableHeader('KYC')),
            Expanded(flex: 1, child: _TableHeader('Status')),
            SizedBox(width: 200),
          ]),
        ),
        const SizedBox(height: 8),
        if (users.isEmpty)
          Container(padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: const Color(0xFF151F2B), borderRadius: BorderRadius.circular(12)),
              child: const Center(child: Text('No users found.', style: TextStyle(fontFamily: 'Poppins', color: Colors.white38))))
        else
          ...users.asMap().entries.map((e) => _UserRow(
            user:         e.value,
            index:        e.key,
            onApprove:    () async => _handleResult(context, await onApprove(e.value.id)),
            onReject:     () async => _handleResult(context, await onReject(e.value.id)),
            onDelete:     () => _confirmDelete(context, e.value, onDelete),
            onView:       () => _showUserDetail(context, e.value),
            onPromote:    () => _confirmPromote(context, e.value),
            onDemote:     () => _confirmDemote(context, e.value),
          )),
      ]),
    );
  }

  void _confirmDelete(BuildContext context, UserModel user, Future<String?> Function(int) onDelete) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF151F2B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.crimson, size: 24),
          SizedBox(width: 10),
          Text('Delete Account', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.white, fontSize: 18)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('You are about to permanently delete this account:', style: TextStyle(fontFamily: 'Poppins', color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.crimson.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.crimson.withValues(alpha: 0.3))),
            child: Row(children: [
              CircleAvatar(radius: 20, backgroundColor: AppColors.crimson.withValues(alpha: 0.2),
                  child: Text(user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: AppColors.crimson))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.fullName,       style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14)),
                Text(user.email,          style: const TextStyle(fontFamily: 'Poppins', color: Colors.white38, fontSize: 12)),
                Text('@${user.username}', style: const TextStyle(fontFamily: 'Poppins', color: Colors.white24, fontSize: 11)),
              ])),
            ]),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
            child: const Row(children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text('This action cannot be undone. All data including KYC documents will be permanently removed.', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.orange))),
            ]),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'Poppins', color: Colors.white54)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final err = await onDelete(user.id);
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(err, style: const TextStyle(fontFamily: 'Poppins')),
                  backgroundColor: AppColors.crimson,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ));
              }
            },
            icon:  const Icon(Icons.delete_forever_rounded, size: 16, color: Colors.white),
            label: const Text('Yes, Delete Account', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.crimson, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ],
      ),
    );
  }

  void _showUserDetail(BuildContext context, UserModel user) {
    showDialog(
      context: context,
      builder: (_) => _UserDetailDialog(userId: user.id, user: user),
    );
  }
}

// ─── User detail dialog ───────────────────────────────────────────────────────
class _UserDetailDialog extends ConsumerStatefulWidget {
  final int userId;
  final UserModel user;
  const _UserDetailDialog({required this.userId, required this.user});

  @override
  ConsumerState<_UserDetailDialog> createState() => _UserDetailDialogState();
}

class _UserDetailDialogState extends ConsumerState<_UserDetailDialog> {
  UserModel? _fullUser;
  bool _loading = true;

  // KYC lazy load state
  String? _govIdBase64;
  String? _govIdFilename;
  String? _selfieBase64;
  String? _selfieFilename;
  bool _kycLoading = false;
  bool _kycLoaded  = false;

  @override
  void initState() {
    super.initState();
    _loadFullUser();
  }

  Future<void> _loadFullUser() async {
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.get('admin/users/${widget.userId}', auth: true);
      final rawData = res['data'];
      if (res['success'] == true && rawData is Map<String, dynamic>) {
        if (mounted) setState(() {
          _fullUser        = UserModel.fromJson(rawData);
          _govIdFilename   = rawData['gov_id_filename']  as String?;
          _selfieFilename  = rawData['selfie_filename']  as String?;
          _loading         = false;
        });
      } else {
        if (mounted) setState(() { _fullUser = widget.user; _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _fullUser = widget.user; _loading = false; });
    }
  }

  Future<void> _loadKyc() async {
    if (_kycLoaded || _kycLoading) return;
    setState(() => _kycLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.get('admin/users/${widget.userId}/kyc', auth: true);
      if (res['success'] == true) {
        final data = res['data'] as Map<String, dynamic>;
        if (mounted) setState(() {
          _govIdBase64    = data['gov_id_base64']   as String?;
          _govIdFilename  = data['gov_id_filename']  as String?;
          _selfieBase64   = data['selfie_base64']    as String?;
          _selfieFilename = data['selfie_filename']  as String?;
          _kycLoaded  = true;
          _kycLoading = false;
        });
      } else {
        if (mounted) setState(() => _kycLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _kycLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _fullUser ?? widget.user;
    return Dialog(
      backgroundColor: const Color(0xFF151F2B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 560,
        constraints: const BoxConstraints(maxHeight: 700),
        child: _loading
            ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: AppColors.teal)))
            : Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 28, 20, 0),
                  child: Row(children: [
                    CircleAvatar(radius: 28, backgroundColor: AppColors.teal.withValues(alpha: 0.2),
                        child: Text(user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.teal))),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(user.fullName,       style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                      Text('@${user.username}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white38)),
                    ])),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, color: Colors.white38)),
                  ]),
                ),
                const Divider(color: Colors.white10, height: 28),
                Expanded(child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _DetailRow(icon: Icons.email_rounded,       label: 'Email',   value: user.email),
                    _DetailRow(icon: Icons.phone_rounded,       label: 'Phone',   value: user.phone.isNotEmpty ? user.phone : '—'),
                    _DetailRow(icon: Icons.cake_rounded,        label: 'Date of Birth', value: user.dateOfBirth ?? '—'),
                    _DetailRow(icon: Icons.location_on_rounded, label: 'Address',
                        value: (user.city != null && user.province != null)
                            ? '${user.city}, ${user.province}'
                            : (user.city ?? user.province ?? '—')),
                    _DetailRow(icon: Icons.badge_rounded,       label: 'Role',    value: user.role.toUpperCase()),
                    _DetailRow(icon: Icons.verified_rounded,    label: 'KYC',     value: user.kycStatus.toUpperCase()),
                    _DetailRow(icon: Icons.toggle_on_rounded,   label: 'Status',
                        value: user.userStatus == 1 ? 'ACTIVE' : user.userStatus == 2 ? 'REJECTED' : 'PENDING APPROVAL'),
                    const SizedBox(height: 20),
                    const Text('KYC Documents',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 12),
                    if (_govIdFilename == null && _selfieFilename == null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
                        child: const Row(children: [
                          Icon(Icons.info_outline_rounded, color: Colors.white38, size: 18),
                          SizedBox(width: 10),
                          Text('No KYC documents submitted yet.',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white38)),
                        ]),
                      )
                    else
                      Column(children: [
                        if (_govIdFilename != null)
                          _KycImageCard(
                            label:      'Government-Issued ID',
                            filename:   _govIdFilename!,
                            base64Data: _govIdBase64,
                            onExpand:   _loadKyc,
                            isLoading:  _kycLoading,
                          ),
                        if (_govIdFilename != null && _selfieFilename != null)
                          const SizedBox(height: 12),
                        if (_selfieFilename != null)
                          _KycImageCard(
                            label:      'Selfie with ID',
                            filename:   _selfieFilename!,
                            base64Data: _selfieBase64,
                            onExpand:   _loadKyc,
                            isLoading:  _kycLoading,
                          ),
                      ]),
                  ]),
                )),
              ]),
      ),
    );
  }
}

// ─── KYC Image Card ───────────────────────────────────────────────────────────
class _KycImageCard extends StatefulWidget {
  final String  label;
  final String  filename;
  final String? base64Data;
  final Future<void> Function() onExpand;
  final bool isLoading;

  const _KycImageCard({
    required this.label,
    required this.filename,
    required this.base64Data,
    required this.onExpand,
    required this.isLoading,
  });

  @override
  State<_KycImageCard> createState() => _KycImageCardState();
}

class _KycImageCardState extends State<_KycImageCard> {
  bool _expanded = false;
  bool get _isPdf => widget.filename.toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
      child: Column(children: [
        GestureDetector(
          onTap: () async {
            if (!_expanded) await widget.onExpand();
            setState(() => _expanded = !_expanded);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8)),
                  child: Icon(_isPdf ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                      color: AppColors.teal, size: 18)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.label,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
                        fontWeight: FontWeight.w600, color: Colors.white)),
                Text(widget.filename,
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 11,
                        color: Colors.white38),
                    overflow: TextOverflow.ellipsis),
              ])),
              if (widget.isLoading && _expanded)
                const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.teal))
              else
                Icon(_expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white38),
            ]),
          ),
        ),
        if (_expanded && !_isPdf)
          widget.base64Data != null
              ? ClipRRect(
                  borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12)),
                  child: Image.memory(
                    base64Decode(widget.base64Data!),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: Colors.white.withValues(alpha: 0.04),
                        child: const Center(
                            child: Text('Could not load image',
                                style: TextStyle(color: Colors.white38)))),
                  ),
                )
              : const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2),
                ),
        if (_expanded && _isPdf)
          Container(
            height: 80,
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8)),
            child: const Center(
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.picture_as_pdf_rounded, color: AppColors.crimson, size: 28),
              SizedBox(width: 10),
              Text('PDF document submitted',
                  style: TextStyle(
                      fontFamily: 'Poppins', color: AppColors.crimson, fontSize: 13)),
            ])),
          ),
      ]),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon; final String label, value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, color: Colors.white38, size: 16),
        const SizedBox(width: 10),
        Text('$label:', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white38)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white))),
      ]),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white38, letterSpacing: 0.5));
  }
}

class _UserRow extends StatelessWidget {
  final UserModel user; final int index;
  final VoidCallback onApprove, onReject, onDelete, onView, onPromote, onDemote;
  const _UserRow({required this.user, required this.index, required this.onApprove, required this.onReject, required this.onDelete, required this.onView, required this.onPromote, required this.onDemote});

  @override
  Widget build(BuildContext context) {
    final roleColor = user.role == 'innovator' ? AppColors.teal : user.role == 'admin' ? AppColors.crimson : AppColors.sky;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(color: const Color(0xFF151F2B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.04))),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          CircleAvatar(radius: 16, backgroundColor: roleColor.withValues(alpha: 0.15),
              child: Text(user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: roleColor))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.fullName,       style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white), overflow: TextOverflow.ellipsis),
            Text('@${user.username}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white38)),
          ])),
        ])),
        Expanded(flex: 3, child: Text(user.email, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white54), overflow: TextOverflow.ellipsis)),
        Expanded(flex: 1, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
          child: Text(user.role.toUpperCase(), style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: roleColor)),
        )),
        Expanded(flex: 1, child: _StatusDot(label: user.kycStatus, color: user.kycStatus == 'verified' ? AppColors.teal : user.kycStatus == 'pending' ? AppColors.golden : Colors.white38)),
        Expanded(flex: 1, child: _StatusDot(
          label: user.userStatus == 1 ? 'Active' : user.userStatus == 2 ? 'Rejected' : 'Pending',
          color: user.userStatus == 1 ? AppColors.teal : user.userStatus == 2 ? AppColors.crimson : AppColors.golden,
        )),
        SizedBox(
          width: 260,
          child: Row(children: [
            SizedBox(width: 36, child: IconButton(
              onPressed: onView, padding: EdgeInsets.zero,
              icon: const Icon(Icons.badge_outlined, color: AppColors.sky, size: 18),
              tooltip: 'View personal info',
            )),
            SizedBox(width: 36, child: IconButton(
              onPressed: () => context.push('/profile/${user.id}'),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.person_search_rounded, color: Colors.white38, size: 18),
              tooltip: 'View public profile',
            )),
            if (user.userStatus == 0) ...[
              const SizedBox(width: 2),
              SizedBox(width: 58, child: ElevatedButton(onPressed: onApprove,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Approve', style: TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)))),
              const SizedBox(width: 2),
              SizedBox(width: 48, child: OutlinedButton(onPressed: onReject,
                  style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.crimson.withValues(alpha: 0.5)), padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Reject', style: TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.crimson)))),
            ] else ...[
              if (user.role != 'admin')
                SizedBox(width: 72, child: TextButton(
                  onPressed: onPromote, style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                  child: const Text('Make Admin', style: TextStyle(fontFamily: 'Poppins', fontSize: 9, color: AppColors.golden)),
                ))
              else
                SizedBox(width: 72, child: TextButton(
                  onPressed: onDemote, style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                  child: const Text('Demote', style: TextStyle(fontFamily: 'Poppins', fontSize: 9, color: Colors.white38)),
                )),
              const SizedBox(width: 2),
            ],
            const Spacer(),
            SizedBox(width: 32, child: IconButton(
              onPressed: onDelete, padding: EdgeInsets.zero,
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white24, size: 18),
              hoverColor: AppColors.crimson.withValues(alpha: 0.1),
              tooltip: 'Delete account',
            )),
          ]),
        ),
      ]),
    ).animate(delay: Duration(milliseconds: 40 * index)).fadeIn(duration: 300.ms);
  }
}

class _StatusDot extends StatelessWidget {
  final String label; final Color color;
  const _StatusDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: color)),
    ]);
  }
}

// ─── Product detail dialog ────────────────────────────────────────────────────
void _showProductDetail(
  BuildContext context,
  int productId,
  VoidCallback onApprove,
  VoidCallback onReject,
) {
  showDialog(
    context: context,
    builder: (_) => _AdminProductDetailDialog(
      productId: productId,
      onApprove: onApprove,
      onReject:  onReject,
    ),
  );
}

class _AdminProductDetailDialog extends ConsumerStatefulWidget {
  final int          productId;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _AdminProductDetailDialog({
    required this.productId,
    required this.onApprove,
    required this.onReject,
  });

  @override
  ConsumerState<_AdminProductDetailDialog> createState() =>
      _AdminProductDetailDialogState();
}

class _AdminProductDetailDialogState
    extends ConsumerState<_AdminProductDetailDialog> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.get('admin/products/${widget.productId}', auth: true);
      if (mounted) {
        setState(() {
          _data    = res['success'] == true ? res['data'] as Map<String, dynamic> : res;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF151F2B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 640,
        constraints: const BoxConstraints(maxHeight: 760),
        child: _loading
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator(color: AppColors.teal)),
              )
            : _data == null
                ? const SizedBox(
                    height: 200,
                    child: Center(
                      child: Text('Failed to load product details.',
                          style: TextStyle(fontFamily: 'Poppins', color: Colors.white38)),
                    ),
                  )
                : Column(children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 28, 20, 0),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.golden.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.lightbulb_rounded, color: AppColors.golden, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_data!['name'] ?? '—',
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                          Text('${_data!['category'] ?? '—'} · by ${_data!['innovator_name'] ?? '—'}',
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white38)),
                        ])),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Colors.white38),
                        ),
                      ]),
                    ),
                    const Divider(color: Colors.white10, height: 28),
                    Expanded(child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
                          child: Row(children: [
                            CircleAvatar(radius: 20, backgroundColor: AppColors.teal.withValues(alpha: 0.15),
                                child: Text((_data!['innovator_name'] as String? ?? '?').isNotEmpty ? (_data!['innovator_name'] as String)[0].toUpperCase() : '?',
                                    style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: AppColors.teal))),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(_data!['innovator_name'] ?? '—', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13)),
                              Text('@${_data!['innovator_username'] ?? '—'}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white38)),
                              if ((_data!['innovator_email'] ?? '').toString().isNotEmpty)
                                Text(_data!['innovator_email'].toString(), style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.sky)),
                              if ((_data!['innovator_phone'] ?? '').toString().isNotEmpty)
                                Text(_data!['innovator_phone'].toString(), style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white38)),
                            ])),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: _data!['kyc_status'] == 'verified' ? AppColors.teal.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                              child: Text((_data!['kyc_status'] ?? 'unverified').toString().toUpperCase(),
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w700, color: _data!['kyc_status'] == 'verified' ? AppColors.teal : Colors.orange)),
                            ),
                          ]),
                        ),
                        const SizedBox(height: 20),
                        const Text('Description',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white54)),
                        const SizedBox(height: 8),
                        Text((_data!['description'] ?? '').toString().isNotEmpty ? _data!['description'].toString() : '—',
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.white, height: 1.6)),
                        const SizedBox(height: 20),
                        if ((_data!['external_link'] ?? '').toString().isNotEmpty) ...[
                          const Text('External Link',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white54)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => launchUrl(Uri.parse(_data!['external_link'].toString())),
                            child: Text(_data!['external_link'].toString(),
                                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.sky, decoration: TextDecoration.underline, decorationColor: AppColors.sky)),
                          ),
                          const SizedBox(height: 20),
                        ],
                        if ((_data!['images'] as List?)?.isNotEmpty == true) ...[
                          Text('Images (${(_data!['images'] as List).length})',
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white54)),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 160,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: (_data!['images'] as List).length,
                              itemBuilder: (ctx, i) {
                                final b64 = (_data!['images'] as List)[i] as String? ?? '';
                                return Container(
                                  width: 200,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: b64.isNotEmpty
                                        ? Image.memory(base64Decode(b64), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white24)))
                                        : const Center(child: Icon(Icons.image_not_supported_rounded, color: Colors.white24)),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        if ((_data!['video_base64'] ?? '').toString().isNotEmpty) ...[
                          const Text('Video',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white54)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.06))),
                            child: Row(children: [
                              const Icon(Icons.videocam_rounded, color: AppColors.sky, size: 20),
                              const SizedBox(width: 10),
                              Expanded(child: Text(_data!['video_filename']?.toString() ?? 'video file', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white70))),
                              const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 16),
                            ]),
                          ),
                          const SizedBox(height: 20),
                        ],
                        Row(children: [
                          _DetailRow(icon: Icons.favorite_rounded,       label: 'Likes',     value: '${_data!['likes'] ?? 0}'),
                          const SizedBox(width: 24),
                          _DetailRow(icon: Icons.remove_red_eye_rounded, label: 'Views',     value: '${_data!['views'] ?? 0}'),
                          const SizedBox(width: 24),
                          _DetailRow(icon: Icons.handshake_rounded,      label: 'Interests', value: '${_data!['interest_count'] ?? 0}'),
                        ]),
                        const SizedBox(height: 8),
                      ]),
                    )),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                      child: Row(children: [
                        Expanded(child: OutlinedButton.icon(
                          onPressed: () { Navigator.pop(context); widget.onReject(); },
                          icon:  const Icon(Icons.close_rounded, size: 16, color: AppColors.crimson),
                          label: const Text('Reject', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.crimson)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.crimson.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        )),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: ElevatedButton.icon(
                          onPressed: () { Navigator.pop(context); widget.onApprove(); },
                          icon:  const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                          label: const Text('Approve & Publish', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        )),
                      ]),
                    ),
                  ]),
      ),
    );
  }
}