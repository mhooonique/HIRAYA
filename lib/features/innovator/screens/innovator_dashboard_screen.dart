// lib/features/innovator/screens/innovator_dashboard_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/widgets/user_avatar.dart';
import '../providers/innovator_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/widgets/notification_bell.dart';
import 'dart:typed_data';


class InnovatorDashboardScreen extends ConsumerStatefulWidget {
  const InnovatorDashboardScreen({super.key});

  @override
  ConsumerState<InnovatorDashboardScreen> createState() =>
      _InnovatorDashboardState();
}

class _InnovatorDashboardState
    extends ConsumerState<InnovatorDashboardScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final istate = ref.watch(innovatorProvider);
    final user = ref.watch(authProvider).user;

    ref.listen(innovatorProvider, (prev, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.successMessage!,
              style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.teal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
        ref.read(innovatorProvider.notifier).clearMessages();
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!,
              style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.crimson,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
        ref.read(innovatorProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.midnight,
      body: Row(
        children: [
          _InnovatorSidebar(
            selectedTab: _selectedTab,
            onTabChange: (i) => setState(() => _selectedTab = i),
            user: user,
          ),
          Expanded(
            child: Column(
              children: [
                _InnovatorTopBar(user: user),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: KeyedSubtree(
                      key: ValueKey(_selectedTab),
                      child: _buildTab(istate),
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

  Widget _buildTab(InnovatorState state) {
    switch (_selectedTab) {
      case 0:
        return _DashboardOverview(
          state: state,
          onPostNew: () => setState(() => _selectedTab = 2),
        );
      case 1:
        return _MyInnovations(state: state);
      case 2:
        return _PostInnovation(
          onSubmit: (name, desc, cat, images, videoB64, videoFn, link, qr) =>
              ref.read(innovatorProvider.notifier).submitProduct(
                name: name, description: desc, category: cat,
                images: images, videoBase64: videoB64,
                videoFilename: videoFn, externalLink: link, qrImage: qr,
              ),
          isLoading: state.isLoading,
        );
      case 3:
        return _InnovatorProfile(user: ref.watch(authProvider).user);
      default:
        return _DashboardOverview(
          state: state,
          onPostNew: () => setState(() => _selectedTab = 2),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SIDEBAR
// ─────────────────────────────────────────────────────────────────────────────
class _InnovatorSidebar extends ConsumerWidget {
  final int selectedTab;
  final void Function(int) onTabChange;
  final dynamic user;

  const _InnovatorSidebar({
    required this.selectedTab,
    required this.onTabChange,
    this.user,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: AppColors.midnight,
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.golden, AppColors.warmEmber],
              ).createShader(bounds),
              child: const Text(
                'Digital Platform',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),
            ),
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          if (user != null)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.teal.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppColors.teal, Color(0xFF0E5A50)]),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        user.firstName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.firstName,
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                            overflow: TextOverflow.ellipsis),
                        const Text('Innovator',
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.teal)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          _SideTab(icon: Icons.dashboard_rounded, label: 'Dashboard', index: 0, selected: selectedTab, onTap: onTabChange),
          _SideTab(icon: Icons.lightbulb_rounded, label: 'My Innovations', index: 1, selected: selectedTab, onTap: onTabChange),
          _SideTab(icon: Icons.add_circle_rounded, label: 'Post Innovation', index: 2, selected: selectedTab, onTap: onTabChange),
          _SideTab(icon: Icons.person_rounded, label: 'Profile', index: 3, selected: selectedTab, onTap: onTabChange),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: GestureDetector(
              onTap: () => context.push('/search'),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
                child: Row(children: [
                  Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.40), size: 18),
                  const SizedBox(width: 10),
                  Text('Search', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white.withValues(alpha: 0.50))),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(12),
            child: GestureDetector(
              onTap: () => context.push('/marketplace'),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
                child: Row(children: [
                  Icon(Icons.storefront_rounded, color: Colors.white.withValues(alpha: 0.40), size: 18),
                  const SizedBox(width: 10),
                  Text('Marketplace', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white.withValues(alpha: 0.50))),
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: GestureDetector(
              onTap: () => context.go('/messaging'),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.sky.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.sky.withValues(alpha: 0.2)),
                ),
                child: const Row(children: [
                  Icon(Icons.chat_bubble_rounded, color: AppColors.sky, size: 18),
                  SizedBox(width: 10),
                  Text('Messages', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.sky, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            child: GestureDetector(
              onTap: () {
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.crimson.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.crimson.withValues(alpha: 0.2)),
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

class _SideTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selected;
  final void Function(int) onTap;

  const _SideTab({
    required this.icon, required this.label,
    required this.index, required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = selected == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isActive ? AppColors.teal.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isActive ? Border.all(color: AppColors.teal.withValues(alpha: 0.35)) : null,
        ),
        child: Row(children: [
          Icon(icon, color: isActive ? AppColors.teal : Colors.white.withValues(alpha: 0.35), size: 18),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(
            fontFamily: 'Poppins', fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.50),
          )),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  TOP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _InnovatorTopBar extends StatelessWidget {
  final dynamic user;
  const _InnovatorTopBar({this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.midnight,
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Row(children: [
        Text('Welcome back, ${user?.firstName ?? 'Innovator'}!',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
        const Spacer(),
        const NotificationBell(),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DASHBOARD OVERVIEW
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardOverview extends StatelessWidget {
  final InnovatorState state;
  final VoidCallback onPostNew;
  const _DashboardOverview({required this.state, required this.onPostNew});

  @override
  Widget build(BuildContext context) {
    final s = state.stats;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dashboard', style: TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 4),
          Text('Your innovation activity at a glance', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white.withValues(alpha: 0.45))),
          const SizedBox(height: 24),
          Row(children: [
            _IStatCard(label: 'Total Submissions', value: '${s['total']}', icon: Icons.inventory_2_rounded, color: AppColors.navy, index: 0),
            const SizedBox(width: 16),
            _IStatCard(label: 'Approved & Live', value: '${s['approved']}', icon: Icons.check_circle_rounded, color: AppColors.teal, index: 1),
            const SizedBox(width: 16),
            _IStatCard(label: 'Pending Review', value: '${s['pending']}', icon: Icons.pending_rounded, color: AppColors.golden, index: 2),
            const SizedBox(width: 16),
            _IStatCard(label: 'Rejected', value: '${s['rejected']}', icon: Icons.cancel_rounded, color: AppColors.crimson, index: 3),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _IStatCard(label: 'Total Likes', value: '${s['totalLikes']}', icon: Icons.favorite_rounded, color: AppColors.crimson, index: 4),
            const SizedBox(width: 16),
            _IStatCard(label: 'Total Views', value: '${s['totalViews']}', icon: Icons.remove_red_eye_rounded, color: AppColors.sky, index: 5),
            const SizedBox(width: 16),
            _IStatCard(label: 'Interests Received', value: '${s['totalInterests']}', icon: Icons.handshake_rounded, color: AppColors.teal, index: 6),
            const SizedBox(width: 16),
            const Expanded(child: SizedBox()),
          ]),
          const SizedBox(height: 28),
          Row(children: [
            const Text('My Innovations', style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            const Spacer(),
            TextButton.icon(
              onPressed: onPostNew,
              icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.teal),
              label: const Text('Post New', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.teal, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 12),
          ...state.myProducts.take(3).toList().asMap().entries.map(
            (e) => _MyProductRow(product: e.value, index: e.key),
          ),
        ],
      ),
    );
  }
}

class _IStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int index;

  const _IStatCard({required this.label, required this.value, required this.icon, required this.color, required this.index});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
          Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white.withValues(alpha: 0.40))),
        ]),
      ).animate(delay: Duration(milliseconds: 60 * index)).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
    );
  }
}

class _MyProductRow extends StatelessWidget {
  final ProductModel product;
  final int index;
  const _MyProductRow({required this.product, required this.index});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.categoryColors[product.category] ?? AppColors.navy;
    final statusColor = product.status == 'approved' ? AppColors.teal : product.status == 'pending' ? AppColors.golden : AppColors.crimson;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.lightbulb_rounded, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product.name, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          Text(product.category, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
        ])),
        _MiniStat(icon: Icons.favorite_rounded, value: '${product.likes}', color: AppColors.crimson),
        const SizedBox(width: 12),
        _MiniStat(icon: Icons.remove_red_eye_rounded, value: '${product.views}', color: Colors.white38),
        const SizedBox(width: 12),
        _MiniStat(icon: Icons.handshake_rounded, value: '${product.interestCount}', color: AppColors.teal),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
          ),
          child: Text(product.status.toUpperCase(), style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
        ),
      ]),
    ).animate(delay: Duration(milliseconds: 60 * index)).fadeIn();
  }
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
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 3),
      Text(value, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  MY INNOVATIONS
// ─────────────────────────────────────────────────────────────────────────────
class _MyInnovations extends StatefulWidget {
  final InnovatorState state;
  const _MyInnovations({required this.state});

  @override
  State<_MyInnovations> createState() => _MyInnovationsState();
}

class _MyInnovationsState extends State<_MyInnovations> {
  final _searchCtrl = TextEditingController();
  String _statusFilter = 'All';
  String _categoryFilter = 'All';
  String _sortBy = 'Newest';

  static const _statuses = ['All', 'approved', 'pending', 'rejected'];
  static const _categories = ['All', 'Agri-Aqua and Forestry', 'Food Processing and Nutrition', 'Health and Medical Sciences', 'Energy, Utilities, and Environment', 'Advanced Manufacturing and Engineering', 'Creative Industries and Product Design', 'Information and Communications Technology (ICT)'];
  static const _sortOptions = ['Newest', 'Most Liked', 'Most Views'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ProductModel> get _filtered {
    var list = List<ProductModel>.from(widget.state.myProducts);
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((p) => p.name.toLowerCase().contains(q) || p.description.toLowerCase().contains(q)).toList();
    }
    if (_statusFilter != 'All') {
      list = list.where((p) => p.status == _statusFilter).toList();
    }
    if (_categoryFilter != 'All') {
      list = list.where((p) => p.category == _categoryFilter).toList();
    }
    switch (_sortBy) {
      case 'Most Liked':  list.sort((a, b) => b.likes.compareTo(a.likes)); break;
      case 'Most Views':  list.sort((a, b) => b.views.compareTo(a.views)); break;
      default:            list.sort((a, b) => b.createdAt.compareTo(a.createdAt)); break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          color: AppColors.midnight,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('My Innovations', style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Text('${filtered.length}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.teal)),
              ),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              height: 42,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search your innovations...',
                  hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white.withValues(alpha: 0.35)),
                  prefixIcon: Icon(Icons.search, size: 18, color: Colors.white.withValues(alpha: 0.35)),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(icon: Icon(Icons.clear, size: 16, color: Colors.white.withValues(alpha: 0.50)), onPressed: () { _searchCtrl.clear(); setState(() {}); })
                      : null,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.teal, width: 1.5)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              _FilterChip(label: 'Status',   value: _statusFilter,   options: _statuses,     onChanged: (v) => setState(() => _statusFilter = v)),
              const SizedBox(width: 10),
              _FilterChip(label: 'Category', value: _categoryFilter, options: _categories,   onChanged: (v) => setState(() => _categoryFilter = v)),
              const SizedBox(width: 10),
              _FilterChip(label: 'Sort',     value: _sortBy,         options: _sortOptions,  onChanged: (v) => setState(() => _sortBy = v), icon: Icons.sort_rounded),
            ]),
          ]),
        ),
        Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
        Expanded(
          child: filtered.isEmpty
              ? const _EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No matches found',
                  subtitle: 'Try adjusting your search or filters.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _ProductDetailRow(product: filtered[i], index: i),
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final void Function(String) onChanged;
  final IconData? icon;

  const _FilterChip({
    required this.label, required this.value,
    required this.options, required this.onChanged, this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value != options.first;
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (_) => options.map((o) => PopupMenuItem(
        value: o,
        child: Row(children: [
          if (o == value) const Icon(Icons.check, size: 14, color: AppColors.teal),
          if (o == value) const SizedBox(width: 8),
          Text(o, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
        ]),
      )).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.teal.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? AppColors.teal.withValues(alpha: 0.40) : Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) Icon(icon, size: 14, color: isActive ? AppColors.teal : Colors.white.withValues(alpha: 0.45)),
          if (icon != null) const SizedBox(width: 6),
          Text(
            isActive ? value : label,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600,
                color: isActive ? AppColors.teal : Colors.white.withValues(alpha: 0.55)),
          ),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: isActive ? AppColors.teal : Colors.white.withValues(alpha: 0.35)),
        ]),
      ),
    );
  }
}

class _ProductDetailRow extends ConsumerWidget {
  final ProductModel product;
  final int index;
  const _ProductDetailRow({required this.product, required this.index});

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.crimson, size: 22),
          SizedBox(width: 10),
          Text('Delete Post', style: TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 17)),
        ]),
        content: Text(
          'Are you sure you want to delete "${product.name}"? This cannot be undone.',
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(fontFamily: 'Poppins', color: Colors.black45)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              final err = await ref
                  .read(innovatorProvider.notifier)
                  .deleteProduct(product.id);
              if (err != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(err,
                      style: const TextStyle(fontFamily: 'Poppins')),
                  backgroundColor: AppColors.crimson,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
              }
            },
            icon: const Icon(Icons.delete_forever_rounded,
                size: 16, color: Colors.white),
            label: const Text('Delete',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.crimson,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = AppColors.categoryColors[product.category] ?? AppColors.navy;
    final statusColor = product.status == 'approved'
        ? AppColors.teal
        : product.status == 'pending'
            ? AppColors.golden
            : AppColors.crimson;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 10),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.lightbulb_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.name, style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            Text('${product.category} · ${product.createdAt.day}/${product.createdAt.month}/${product.createdAt.year}',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white.withValues(alpha: 0.38))),
          ])),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(product.status.toUpperCase(),
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor)),
          ),
        ]),
        const SizedBox(height: 12),
        Text(product.description,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white.withValues(alpha: 0.50), height: 1.5),
            maxLines: 2, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 14),
        Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
        const SizedBox(height: 14),
        Row(children: [
          _MiniStat(
              icon: Icons.favorite_rounded,
              value: '${product.likes} likes',
              color: AppColors.crimson),
          const SizedBox(width: 16),
          _MiniStat(icon: Icons.remove_red_eye_rounded, value: '${product.views} views', color: Colors.white38),
            _MiniStat(icon: Icons.remove_red_eye_rounded, value: '${product.views} views', color: Colors.white38),
          const SizedBox(width: 16),
          _MiniStat(
              icon: Icons.handshake_rounded,
              value: '${product.interestCount} interests',
              color: AppColors.teal),
          const Spacer(),
          if (product.status == 'approved')
            TextButton.icon(
              onPressed: () => context.go('/product/${product.id}'),
              icon: const Icon(Icons.open_in_new_rounded,
                  size: 14, color: AppColors.sky),
              label: const Text('View Live',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.sky,
                      fontWeight: FontWeight.w600)),
            ),
          IconButton(
            onPressed: () => _confirmDelete(context, ref),
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: Colors.black26),
            tooltip: 'Delete post',
            hoverColor: AppColors.crimson.withValues(alpha: 0.08),
          ),
        ]),
      ]),
    ).animate(delay: Duration(milliseconds: 60 * index)).fadeIn(duration: 400.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  POST INNOVATION
// ─────────────────────────────────────────────────────────────────────────────
class _PostInnovation extends ConsumerStatefulWidget {
  final Future<bool> Function(
    String name,
    String desc,
    String cat,
    List<String> images,
    String? videoBase64,
    String? videoFilename,
    String? externalLink,
    String? qrImage,
  ) onSubmit;
  final bool isLoading;

  const _PostInnovation({required this.onSubmit, required this.isLoading});

  @override
  ConsumerState<_PostInnovation> createState() => _PostInnovationState();
}

class _PostInnovationState extends ConsumerState<_PostInnovation> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _formKey  = GlobalKey<FormState>();

  String _selectedCategory = 'Agri-Aqua and Forestry';

  final List<_PickedFile> _images = [];
  _PickedFile? _video;
  bool _draftRestored = false;

  Timer? _debounce;

  static const _categories = [
    'Agri-Aqua and Forestry', 'Food Processing and Nutrition', 'Health and Medical Sciences', 'Energy, Utilities, and Environment',
    'Advanced Manufacturing and Engineering', 'Creative Industries and Product Design', 'Information and Communications Technology (ICT)',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreDraft());
    _nameCtrl.addListener(_onFieldChanged);
    _descCtrl.addListener(_onFieldChanged);
    _linkCtrl.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  void _restoreDraft() {
    final draft = ref.read(innovatorProvider).draft;
    if (draft == null) return;
    setState(() {
      _nameCtrl.text    = draft.name;
      _descCtrl.text    = draft.description;
      _linkCtrl.text    = draft.externalLink ?? '';
      _selectedCategory = draft.category;
      _draftRestored    = true;
    });
  }

  void _onFieldChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), _saveDraft);
  }

  Future<void> _saveDraft() async {
    await ref.read(innovatorProvider.notifier).saveDraft(
      name:          _nameCtrl.text.trim(),
      description:   _descCtrl.text.trim(),
      category:      _selectedCategory,
      images:        _images.map((f) => base64Encode(f.bytes)).toList(),
      externalLink:  _linkCtrl.text.trim().isNotEmpty ? _linkCtrl.text.trim() : null,
      videoBase64:   _video != null ? base64Encode(_video!.bytes) : null,
      videoFilename: _video?.name,
    );
  }

  Future<void> _pickImages() async {
    if (_images.length >= 10) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      allowMultiple: true,
      withData: true,
    );
    if (result == null) return;
    final remaining = 10 - _images.length;
    for (final f in result.files.take(remaining)) {
      if (f.bytes == null) continue;

      final bytes  = f.bytes!;
      final sizeKb = bytes.length ~/ 1024;

      if ((bytes.length / 1024 / 1024) > 5) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${f.name} exceeds 5 MB — skipped.',
              style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.crimson,
        ));
        continue;
      }

      setState(() => _images.add(
        _PickedFile(name: f.name, bytes: bytes, sizeKb: sizeKb),
      ));
    }
    _onFieldChanged();
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mov'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    if ((f.size / 1024 / 1024) > 100) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Video too large. Max 100 MB.'),
        backgroundColor: AppColors.crimson,
      ));
      return;
    }
    if (f.bytes != null) {
      setState(() => _video = _PickedFile(name: f.name, bytes: f.bytes!, sizeKb: f.size ~/ 1024));
      _onFieldChanged();
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_images.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please upload at least 5 images.', style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppColors.crimson,
      ));
      return;
    }
    final success = await widget.onSubmit(
      _nameCtrl.text.trim(),
      _descCtrl.text.trim(),
      _selectedCategory,
      _images.map((f) => base64Encode(f.bytes)).toList(),
      _video != null ? base64Encode(_video!.bytes) : null,
      _video?.name,
      _linkCtrl.text.trim().isNotEmpty ? _linkCtrl.text.trim() : null,
      null,
    );
    if (success && mounted) {
      _nameCtrl.clear();
      _descCtrl.clear();
      _linkCtrl.clear();
      setState(() { _images.clear(); _video = null; _selectedCategory = 'Agri-Aqua and Forestry'; _draftRestored = false; });
    }
  }

  InputDecoration _inputDec(String hint, {Widget? suffix}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black26),
    suffixIcon: suffix,
    filled: true, fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.teal, width: 2)),
    errorBorder:   OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.crimson)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.crimson, width: 2)),
  );

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(innovatorProvider).isSavingDraft;
    final catColor = AppColors.categoryColors[_selectedCategory] ?? AppColors.navy;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            Row(children: [
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Post an Innovation', style: TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy)),
                SizedBox(height: 4),
                Text('Submit your innovation for admin review.', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black45)),
              ])),
              if (_draftRestored || isSaving)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.golden.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.golden.withValues(alpha: 0.4)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    isSaving
                        ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.golden))
                        : const Icon(Icons.edit_note_rounded, size: 14, color: AppColors.golden),
                    const SizedBox(width: 6),
                    Text(isSaving ? 'Saving draft...' : 'Draft restored',
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.golden, fontWeight: FontWeight.w600)),
                    if (!isSaving && _draftRestored) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          _nameCtrl.clear(); _descCtrl.clear(); _linkCtrl.clear();
                          setState(() { _images.clear(); _video = null; _draftRestored = false; });
                          ref.read(innovatorProvider.notifier).discardDraft();
                        },
                        child: const Icon(Icons.close, size: 13, color: AppColors.golden),
                      ),
                    ],
                  ]),
                ),
            ]),

            const SizedBox(height: 28),
            const _SectionHeader('Basic Information', Icons.info_outline_rounded),
            const SizedBox(height: 16),
            const _FormLabel('Innovation Name *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameCtrl,
              maxLength: 120,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: _inputDec('e.g. Smart Solar Irrigation System'),
              validator: (v) => v == null || v.trim().length < 5 ? 'Minimum 5 characters' : null,
            ),
            const SizedBox(height: 16),
            const _FormLabel('Category *'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.lightGray)),
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                underline: const SizedBox(),
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.darkGray),
                onChanged: (v) { setState(() => _selectedCategory = v ?? _selectedCategory); _onFieldChanged(); },
                items: _categories.map((c) {
                  final cc = AppColors.categoryColors[c] ?? AppColors.navy;
                  return DropdownMenuItem(value: c, child: Row(children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: cc)),
                    const SizedBox(width: 10),
                    Text(c),
                  ]));
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            const _FormLabel('Description *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              maxLines: 5,
              maxLength: 1000,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, height: 1.5),
              decoration: _inputDec('Describe your innovation — what it does, who it helps, and why it matters...'),
              validator: (v) => v == null || v.trim().length < 30 ? 'Minimum 30 characters' : null,
            ),
            const SizedBox(height: 28),
            _SectionHeader('Images', Icons.photo_library_rounded,
                badge: '${_images.length}/10 · Min 5 required'),
            const SizedBox(height: 8),
            const Text(
              'JPEG, PNG, WebP · Max 5 MB each · First image = cover thumbnail · Drag to reorder',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black38),
            ),
            const SizedBox(height: 12),
            if (_images.isNotEmpty)
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _images.length,
                onReorder: (oldIdx, newIdx) {
                  setState(() {
                    if (newIdx > oldIdx) newIdx--;
                    final item = _images.removeAt(oldIdx);
                    _images.insert(newIdx, item);
                  });
                  _onFieldChanged();
                },
                itemBuilder: (ctx, i) => _ImageSlotTile(
                  key: ValueKey('${_images[i].name}$i'),
                  file: _images[i],
                  index: i,
                  isCover: i == 0,
                  onRemove: () { setState(() => _images.removeAt(i)); _onFieldChanged(); },
                ),
              ),
            if (_images.length < 10)
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.teal.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Column(children: [
                    Icon(Icons.add_photo_alternate_rounded, size: 28, color: AppColors.teal.withValues(alpha: 0.6)),
                    const SizedBox(height: 6),
                    Text(
                      _images.isEmpty ? 'Click to add images (5–10 required)' : 'Add more (${10 - _images.length} remaining)',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.teal.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
                    ),
                  ]),
                ),
              ),
            const SizedBox(height: 28),
            const _SectionHeader('Short Video', Icons.videocam_rounded, badge: 'Optional · 30–60 sec · MP4/MOV'),
            const SizedBox(height: 12),
            if (_video != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.sky.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.sky.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.video_file_rounded, color: AppColors.sky, size: 22),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_video!.name, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy)),
                    Text('${_video!.sizeKb} KB', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.black38)),
                  ])),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.crimson),
                    onPressed: () { setState(() => _video = null); _onFieldChanged(); },
                  ),
                ]),
              )
            else
              GestureDetector(
                onTap: _pickVideo,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightGray, width: 1.5),
                  ),
                  child: const Column(children: [
                    Icon(Icons.video_call_rounded, size: 28, color: Colors.black26),
                    SizedBox(height: 6),
                    Text('Click to add a short preview video', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black38)),
                    SizedBox(height: 2),
                    Text('MP4 or MOV · 30–60 seconds recommended', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.black26)),
                  ]),
                ),
              ),
            const SizedBox(height: 28),
            const _SectionHeader('QR Code / External Link', Icons.link_rounded, badge: 'Optional'),
            const SizedBox(height: 8),
            const Text(
              'Paste a URL to a full demo, pitch deck, or presentation (YouTube, Google Drive, Canva, etc.)\nA QR code will be auto-generated from this link.',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black38, height: 1.5),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _linkCtrl,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: _inputDec('https://drive.google.com/... or https://youtu.be/...').copyWith(
                suffixIcon: _linkCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () => setState(() => _linkCtrl.clear()))
                    : const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.black26),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final uri = Uri.tryParse(v.trim());
                if (uri == null || !uri.scheme.startsWith('http')) return 'Enter a valid URL (https://...)';
                return null;
              },
            ),
            const SizedBox(height: 32),
            _ProgressBar(
              images:  _images.length,
              hasName: _nameCtrl.text.trim().length >= 5,
              hasDesc: _descCtrl.text.trim().length >= 30,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.isLoading ? null : _submit,
                icon: widget.isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 18),
                label: Text(
                  widget.isLoading ? 'Submitting...' : 'Submit for Admin Review',
                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: catColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PROFILE
// ─────────────────────────────────────────────────────────────────────────────
class _InnovatorProfile extends ConsumerWidget {
  final dynamic user;
  const _InnovatorProfile({this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (user == null) return const Center(child: CircularProgressIndicator(color: AppColors.teal));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('My Profile', style: TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.lightGray)),
            child: Column(children: [
              UserAvatar(
                name:         user.firstName as String,
                avatarBase64: user.avatarBase64 as String?,
                radius:       40,
                backgroundColor: AppColors.teal.withValues(alpha: 0.15),
                foregroundColor: AppColors.teal,
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
              ),
              const SizedBox(height: 16),
              Text(user.fullName, style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy)),
              Text('@${user.username}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.black45)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.verified_rounded, color: AppColors.teal, size: 14),
                  SizedBox(width: 6),
                  Text('Innovator', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.teal)),
                ]),
              ),
              const SizedBox(height: 20),
              const Divider(color: AppColors.lightGray),
              const SizedBox(height: 16),
              _ProfileRow(label: 'Email', value: user.email, icon: Icons.email_outlined),
              _ProfileRow(label: 'KYC Status', value: user.kycStatus.toUpperCase(), icon: Icons.verified_user_rounded),
              _ProfileRow(label: 'Account Status', value: user.userStatus == 1 ? 'Active' : 'Pending', icon: Icons.circle_rounded),
            ]),
          ),
          const SizedBox(height: 20),
          _SocialLinksCard(socialLinks: user.socialLinks),
          const SizedBox(height: 20),
          const _ThemeToggleCard(),
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
      Icon(icon, size: 16, color: AppColors.teal),
      const SizedBox(width: 12),
      Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black45)),
      const Spacer(),
      Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy)),
    ]),
  );
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
    ('facebook',  'Facebook',    Icons.facebook_rounded),
    ('instagram', 'Instagram',   Icons.camera_alt_rounded),
    ('linkedin',  'LinkedIn',    Icons.work_rounded),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.share_rounded, size: 16, color: AppColors.navy),
          const SizedBox(width: 8),
          const Text('Social Links', style: TextStyle(
              fontFamily: 'Poppins', fontSize: 15,
              fontWeight: FontWeight.w700, color: AppColors.navy)),
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
                Icon(f.$3, size: 16,
                    color: (_ctrls[f.$1]!.text.isEmpty) ? Colors.black26 : AppColors.navy),
                const SizedBox(width: 10),
                Text(f.$2, style: const TextStyle(
                    fontFamily: 'Poppins', fontSize: 13, color: Colors.black45)),
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
                    ? const SizedBox(width: 16, height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save', style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 13,
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ],
      ]),
    );
  }
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
    final color  = isDark ? AppColors.golden : AppColors.teal;
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
          activeColor: AppColors.teal,
          inactiveThumbColor: AppColors.navy.withValues(alpha: 0.5),
          inactiveTrackColor: AppColors.lightGray,
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────
class _ImageSlotTile extends StatelessWidget {
  final _PickedFile file;
  final int         index;
  final bool        isCover;
  final VoidCallback onRemove;
  const _ImageSlotTile({super.key, required this.file, required this.index, required this.isCover, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCover ? AppColors.teal.withValues(alpha: 0.5) : AppColors.lightGray,
          width: isCover ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        const Icon(Icons.drag_handle_rounded, color: Colors.black26, size: 20),
        const SizedBox(width: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(file.bytes, width: 52, height: 42, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(width: 52, height: 42, color: AppColors.lightGray,
              child: const Icon(Icons.broken_image, size: 20, color: Colors.black26)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(file.name, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy), overflow: TextOverflow.ellipsis),
          Text('${file.sizeKb} KB', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.black38)),
        ])),
        if (isCover)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: const Text('Cover', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.teal)),
          ),
        const SizedBox(width: 8),
        IconButton(icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.crimson), onPressed: onRemove),
      ]),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int  images;
  final bool hasName;
  final bool hasDesc;
  const _ProgressBar({required this.images, required this.hasName, required this.hasDesc});

  @override
  Widget build(BuildContext context) {
    final steps    = [_Step('Name', hasName), _Step('Description', hasDesc), _Step('5+ Images', images >= 5)];
    final done     = steps.where((s) => s.done).length;
    final progress = done / steps.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.lightGray)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Submission readiness', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy)),
          const Spacer(),
          Text('$done/${steps.length}', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w700,
              color: done == steps.length ? AppColors.teal : AppColors.golden)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: progress, minHeight: 6, backgroundColor: AppColors.lightGray,
              color: done == steps.length ? AppColors.teal : AppColors.golden),
        ),
        const SizedBox(height: 12),
        Row(children: steps.map((s) => Expanded(child: Row(children: [
          Icon(s.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 14, color: s.done ? AppColors.teal : Colors.black26),
          const SizedBox(width: 4),
          Text(s.label, style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
              color: s.done ? AppColors.teal : Colors.black38,
              fontWeight: s.done ? FontWeight.w600 : FontWeight.w400)),
        ]))).toList()),
      ]),
    );
  }
}

class _Step { final String label; final bool done; const _Step(this.label, this.done); }

class _PickedFile {
  final String    name;
  final Uint8List bytes;
  final int       sizeKb;
  const _PickedFile({required this.name, required this.bytes, required this.sizeKb});
}

class _SectionHeader extends StatelessWidget {
  final String  title;
  final IconData icon;
  final String? badge;
  const _SectionHeader(this.title, this.icon, {this.badge});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: AppColors.navy.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: AppColors.navy)),
    const SizedBox(width: 10),
    Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
    if (badge != null) ...[
      const SizedBox(width: 10),
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: AppColors.offWhite, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.lightGray)),
          child: Text(badge!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.black45))),
    ],
  ]);
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy));
}

// ─────────────────────────────────────────────────────────────────────────────
//  EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const SizedBox(height: 60),
      Icon(icon, size: 64, color: AppColors.lightGray),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy)),
      const SizedBox(height: 8),
      Text(subtitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black38)),
    ]),
  );
}