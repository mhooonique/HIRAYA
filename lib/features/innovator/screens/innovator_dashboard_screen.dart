import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/product_model.dart';
import '../providers/innovator_provider.dart';
import '../../auth/providers/auth_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  CONSTANTS
// ─────────────────────────────────────────────────────────────────────────────
const _kDraftKey = 'hiraya_post_innovation_draft';

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

const _sidebarItems = <_SideNavItem>[
  _SideNavItem(Icons.dashboard_rounded, 'Dashboard', 0),
  _SideNavItem(Icons.lightbulb_rounded, 'My Innovations', 1),
  _SideNavItem(Icons.add_circle_rounded, 'Post Innovation', 2),
  _SideNavItem(Icons.person_rounded, 'Profile', 3),
  _SideNavItem(Icons.storefront_rounded, 'Marketplace', 4),
  _SideNavItem(Icons.chat_bubble_rounded, 'Messages', 5),
];

const _tabAccentColors = <int, Color>{
  0: AppColors.navy,
  1: AppColors.teal,
  2: Color(0xFF136F63),
  3: AppColors.sky,
  4: AppColors.golden,
  5: AppColors.sky,
};

class _SideNavItem {
  final IconData icon;
  final String label;
  final int index;
  const _SideNavItem(this.icon, this.label, this.index);
}

// ═════════════════════════════════════════════════════════════════════════════
//  MAIN SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class InnovatorDashboardScreen extends ConsumerStatefulWidget {
  const InnovatorDashboardScreen({super.key});

  @override
  ConsumerState<InnovatorDashboardScreen> createState() =>
      _InnovatorDashboardState();
}

class _InnovatorDashboardState extends ConsumerState<InnovatorDashboardScreen>
    with TickerProviderStateMixin {
  int _selectedTab = 0;
  bool _showSkeleton = true;

  late final AnimationController _sidebarGlowCtrl;

  @override
  void initState() {
    super.initState();
    _sidebarGlowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _showSkeleton = false);
    });
  }

  @override
  void dispose() {
    _sidebarGlowCtrl.dispose();
    super.dispose();
  }

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        ref.read(innovatorProvider.notifier).clearMessages();
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!,
              style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.crimson,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        ref.read(innovatorProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: _showSkeleton
            ? const _InnovatorSkeleton(key: ValueKey('skel'))
            : KeyedSubtree(
                key: const ValueKey('live'),
                child: Row(
                  children: [
                    _CinematicSidebar(
                      selectedTab: _selectedTab,
                      onTabChange: (i) =>
                          setState(() => _selectedTab = i),
                      user: user,
                      glowCtrl: _sidebarGlowCtrl,
                      ref: ref,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          _CinematicTopBar(
                            user: user,
                            tabIndex: _selectedTab,
                          ),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration:
                                  const Duration(milliseconds: 380),
                              switchInCurve: Curves.easeOutCubic,
                              transitionBuilder: (child, anim) {
                                final scale = Tween<double>(
                                        begin: 0.96, end: 1.0)
                                    .animate(anim);
                                return FadeTransition(
                                  opacity: anim,
                                  child: ScaleTransition(
                                    scale: scale,
                                    alignment: Alignment.topCenter,
                                    child: child,
                                  ),
                                );
                              },
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
              ),
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
          onSubmit: (name, desc, cat) =>
              ref.read(innovatorProvider.notifier).submitProduct(
                    name: name,
                    description: desc,
                    category: cat,
                  ),
          isLoading: state.isLoading,
        );
      case 3:
        return _InnovatorProfile(user: ref.watch(authProvider).user);
      case 4:
        return const _MarketplaceTab();
      case 5:
        return const _MessagesTab();
      default:
        return _DashboardOverview(
          state: state,
          onPostNew: () => setState(() => _selectedTab = 2),
        );
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  SKELETON SCREEN
// ═════════════════════════════════════════════════════════════════════════════
class _InnovatorSkeleton extends StatelessWidget {
  const _InnovatorSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Sidebar skeleton ──
        Container(
          width: 260,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.navy, Color(0xFF0A4A6E)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(4, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 28),
              // Logo placeholder
              _LSkel(w: 140, h: 36, r: 10)
                  .animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 1400.ms),
              const SizedBox(height: 28),
              const Divider(
                  height: 1,
                  color: Colors.white10,
                  indent: 20,
                  endIndent: 20),
              const SizedBox(height: 20),
              // Nav items
              for (int i = 0; i < 6; i++) ...[
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _LSkel(w: double.infinity, h: 44, r: 12)
                      .animate(
                          delay: Duration(milliseconds: 80 * i),
                          onPlay: (c) => c.repeat())
                      .shimmer(duration: 1400.ms),
                ),
              ],
              const Spacer(),
              // Bottom buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: _LSkel(w: double.infinity, h: 44, r: 10)
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 1400.ms),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: _LSkel(w: double.infinity, h: 44, r: 10)
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 1400.ms),
              ),
            ],
          ),
        ),
        // ── Content skeleton ──
        Expanded(
          child: Column(
            children: [
              // Top bar skeleton
              Container(
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                      bottom:
                          BorderSide(color: AppColors.lightGray.withValues(alpha: 0.5))),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  children: [
                    _LSkel(w: 240, h: 20, r: 8)
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 1400.ms),
                    const Spacer(),
                    _LSkel(w: 36, h: 36, r: 18)
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 1400.ms),
                    const SizedBox(width: 12),
                    _LSkel(w: 36, h: 36, r: 18)
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 1400.ms),
                  ],
                ),
              ),
              // Hero banner skeleton
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: _LSkel(w: double.infinity, h: 160, r: 20)
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(duration: 1400.ms),
              ),
              // Stat cards skeleton
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Row(
                  children: List.generate(
                    4,
                    (i) => Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i < 3 ? 16 : 0),
                        child: _LSkel(w: double.infinity, h: 110, r: 16)
                            .animate(
                                delay: Duration(milliseconds: 100 * i),
                                onPlay: (c) => c.repeat())
                            .shimmer(duration: 1400.ms),
                      ),
                    ),
                  ),
                ),
              ),
              // Content rows skeleton
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: List.generate(
                      3,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _LSkel(w: double.infinity, h: 72, r: 14)
                            .animate(
                                delay: Duration(milliseconds: 120 * i),
                                onPlay: (c) => c.repeat())
                            .shimmer(duration: 1400.ms),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  CINEMATIC SIDEBAR
// ═════════════════════════════════════════════════════════════════════════════
class _CinematicSidebar extends StatelessWidget {
  final int selectedTab;
  final void Function(int) onTabChange;
  final dynamic user;
  final AnimationController glowCtrl;
  final WidgetRef ref;

  const _CinematicSidebar({
    required this.selectedTab,
    required this.onTabChange,
    this.user,
    required this.glowCtrl,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: glowCtrl,
      child: _buildContent(context),
      builder: (context, child) {
        final glow = 0.15 + glowCtrl.value * 0.1;
        return Container(
          width: 260,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.navy, Color(0xFF0A4A6E)],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: glow),
                blurRadius: 30,
                offset: const Offset(4, 0),
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    return Stack(
      children: [
        // ── Dot grid texture ──
        Positioned.fill(
          child: CustomPaint(
            painter: _SidebarDotGridPainter(),
          ),
        ),
        // ── Ambient teal orb ──
        Positioned(
          bottom: -40,
          left: -40,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.teal.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        // ── Content ──
        Column(
          children: [
            const SizedBox(height: 24),
            // ── Logo ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Image.asset(
                        'assets/images/logo/final-logo.png',
                        height: 30),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HIRAYA',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 3,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.teal, Color(0xFF1A9B89)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'INNOVATOR',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .slideX(begin: -0.15, end: 0),
            const SizedBox(height: 24),
            // ── User card ──
            if (user != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.teal, Color(0xFF1A9B89)],
                          ),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 2),
                        ),
                        child: Center(
                          child: Text(
                            user.firstName
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.firstName,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '@${user.username}',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: -0.1, end: 0),
            const SizedBox(height: 20),
            Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.08),
              indent: 20,
              endIndent: 20,
            ),
            const SizedBox(height: 12),
            // ── Nav items ──
            for (final item in _sidebarItems)
              _AnimatedSidebarItem(
                item: item,
                isActive: selectedTab == item.index,
                onTap: () => onTabChange(item.index),
              )
                  .animate(
                      delay: Duration(milliseconds: 300 + item.index * 60))
                  .fadeIn(duration: 400.ms)
                  .slideX(begin: -0.12, end: 0),
            const Spacer(),
            // ── Bottom action ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SidebarBottomBtn(
                icon: Icons.logout_rounded,
                label: 'Logout',
                color: AppColors.crimson,
                onTap: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ],
    );
  }
}

// ── Animated sidebar item ─────────────────────────────────────────────────────
class _AnimatedSidebarItem extends StatefulWidget {
  final _SideNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _AnimatedSidebarItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_AnimatedSidebarItem> createState() => _AnimatedSidebarItemState();
}

class _AnimatedSidebarItemState extends State<_AnimatedSidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    final hover = _hovered && !active;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              gradient: active
                  ? const LinearGradient(
                      colors: [AppColors.teal, Color(0xFF1A9B89)],
                    )
                  : null,
              color: active
                  ? null
                  : hover
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white.withValues(alpha: 0.2)
                        : hover
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.item.icon,
                    color: active
                        ? Colors.white
                        : hover
                            ? Colors.white.withValues(alpha: 0.85)
                            : Colors.white.withValues(alpha: 0.45),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.item.label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight:
                        active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? Colors.white
                        : hover
                            ? Colors.white.withValues(alpha: 0.9)
                            : Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                if (active) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sidebar bottom button ─────────────────────────────────────────────────────
class _SidebarBottomBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SidebarBottomBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_SidebarBottomBtn> createState() => _SidebarBottomBtnState();
}

class _SidebarBottomBtnState extends State<_SidebarBottomBtn> {
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
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Icon(widget.icon,
                  color: _hovered
                      ? widget.color
                      : Colors.white.withValues(alpha: 0.5),
                  size: 17),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _hovered
                      ? widget.color
                      : Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  CINEMATIC TOP BAR
// ═════════════════════════════════════════════════════════════════════════════
class _CinematicTopBar extends StatelessWidget {
  final dynamic user;
  final int tabIndex;
  const _CinematicTopBar({this.user, required this.tabIndex});

  String get _tabTitle {
    switch (tabIndex) {
      case 0: return 'Dashboard';
      case 1: return 'My Innovations';
      case 2: return 'Post Innovation';
      case 3: return 'Profile';
      case 4: return 'Marketplace';
      case 5: return 'Messages';
      default: return 'Dashboard';
    }
  }

  IconData get _tabIcon {
    switch (tabIndex) {
      case 0: return Icons.dashboard_rounded;
      case 1: return Icons.lightbulb_rounded;
      case 2: return Icons.add_circle_rounded;
      case 3: return Icons.person_rounded;
      case 4: return Icons.storefront_rounded;
      case 5: return Icons.chat_bubble_rounded;
      default: return Icons.dashboard_rounded;
    }
  }

  Color get _accentColor => _tabAccentColors[tabIndex] ?? AppColors.teal;

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Breadcrumb with per-tab accent
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.1),
                  accent.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Icon(_tabIcon, size: 16, color: accent,
                      key: ValueKey(_tabIcon)),
                ),
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    _tabTitle,
                    key: ValueKey(_tabTitle),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Welcome back, ${user?.firstName ?? 'Innovator'}! 👋',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.black.withValues(alpha: 0.4),
            ),
          ),
          const Spacer(),
          // Action icons
          _NavIconBtn(
            icon: Icons.notifications_outlined,
            badge: 3,
            onTap: () {},
          ),
          const SizedBox(width: 6),
          _NavIconBtn(
            icon: Icons.search_rounded,
            onTap: () {},
          ),
          const SizedBox(width: 14),
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [accent, accent.withValues(alpha: 0.7)],
              ),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.25),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Text(
                user?.firstName?.substring(0, 1)?.toUpperCase() ?? 'I',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
        // ── Per-tab accent stripe ──
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent, accent.withValues(alpha: 0.3)],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Nav icon button ───────────────────────────────────────────────────────────
class _NavIconBtn extends StatefulWidget {
  final IconData icon;
  final int? badge;
  final VoidCallback onTap;

  const _NavIconBtn({required this.icon, this.badge, required this.onTap});

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
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.navy.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: _hovered ? AppColors.navy : Colors.black45,
              ),
              if (widget.badge != null && widget.badge! > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.crimson,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.badge}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  DASHBOARD OVERVIEW
// ═════════════════════════════════════════════════════════════════════════════
class _DashboardOverview extends StatefulWidget {
  final InnovatorState state;
  final VoidCallback onPostNew;
  const _DashboardOverview({required this.state, required this.onPostNew});

  @override
  State<_DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<_DashboardOverview>
    with TickerProviderStateMixin {
  late final AnimationController _heroCtrl;
  late final AnimationController _orbCtrl;

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state.stats;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── PARALLAX HERO BANNER ──
          _HeroBanner(
            user: null,
            heroCtrl: _heroCtrl,
            orbCtrl: _orbCtrl,
            onPostNew: widget.onPostNew,
          ),
          const SizedBox(height: 28),
          // ── Primary stat cards ──
          Row(
            children: [
              _AnimatedStatCard(
                label: 'Total Submissions',
                value: s['total'] ?? 0,
                icon: Icons.inventory_2_rounded,
                gradient: const [AppColors.navy, Color(0xFF0A4A6E)],
                index: 0,
              ),
              const SizedBox(width: 16),
              _AnimatedStatCard(
                label: 'Approved & Live',
                value: s['approved'] ?? 0,
                icon: Icons.check_circle_rounded,
                gradient: const [AppColors.teal, Color(0xFF1A9B89)],
                index: 1,
              ),
              const SizedBox(width: 16),
              _AnimatedStatCard(
                label: 'Pending Review',
                value: s['pending'] ?? 0,
                icon: Icons.pending_rounded,
                gradient: const [AppColors.golden, Color(0xFFFFD45C)],
                index: 2,
              ),
              const SizedBox(width: 16),
              _AnimatedStatCard(
                label: 'Rejected',
                value: s['rejected'] ?? 0,
                icon: Icons.cancel_rounded,
                gradient: const [AppColors.crimson, Color(0xFFFF4444)],
                index: 3,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Engagement stats ──
          Row(
            children: [
              _EngagementCard(
                label: 'Total Likes',
                value: '${s['totalLikes']}',
                icon: Icons.favorite_rounded,
                color: AppColors.crimson,
                index: 0,
              ),
              const SizedBox(width: 16),
              _EngagementCard(
                label: 'Total Views',
                value: '${s['totalViews']}',
                icon: Icons.remove_red_eye_rounded,
                color: AppColors.sky,
                index: 1,
              ),
              const SizedBox(width: 16),
              _EngagementCard(
                label: 'Interests Received',
                value: '${s['totalInterests']}',
                icon: Icons.handshake_rounded,
                color: AppColors.teal,
                index: 2,
              ),
              const SizedBox(width: 16),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 32),

          // ── Recent innovations ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.navy, Color(0xFF0A4A6E)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.lightbulb_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Recent Innovations',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const Spacer(),
              _GradientBtn(
                label: 'Post New',
                icon: Icons.add_rounded,
                gradient: const [AppColors.teal, Color(0xFF1A9B89)],
                onTap: widget.onPostNew,
                compact: true,
              ),
            ],
          ).animate(delay: 400.ms).fadeIn(duration: 400.ms),
          const SizedBox(height: 16),
          ...widget.state.myProducts.take(3).toList().asMap().entries.map(
                (e) => _RecentProductRow(product: e.value, index: e.key),
              ),
        ],
      ),
    );
  }
}

// ── Hero banner ───────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final dynamic user;
  final AnimationController heroCtrl;
  final AnimationController orbCtrl;
  final VoidCallback onPostNew;
  const _HeroBanner({
    required this.user,
    required this.heroCtrl,
    required this.orbCtrl,
    required this.onPostNew,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([heroCtrl, orbCtrl]),
      child: _buildHeroContent(context),
      builder: (context, child) {
        final fade = CurvedAnimation(
            parent: heroCtrl, curve: Curves.easeOutCubic);
        final slideY = Tween<double>(begin: 18, end: 0)
            .animate(CurvedAnimation(
                parent: heroCtrl, curve: Curves.easeOutCubic));
        final orbX = orbCtrl.value * 12;
        final orbY = orbCtrl.value * 8;
        return FadeTransition(
          opacity: fade,
          child: Transform.translate(
            offset: Offset(0, slideY.value),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // ── Gradient background ──
                  Container(
                    height: 168,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.navy,
                          Color(0xFF0A4A6E),
                          AppColors.teal,
                        ],
                        stops: [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                  // ── Dot grid ──
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _SidebarDotGridPainter(),
                    ),
                  ),
                  // ── Floating orbs ──
                  Positioned(
                    right: -20 + orbX,
                    top: -30 + orbY,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.teal.withValues(alpha: 0.25),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30 - orbX * 0.5,
                    bottom: -20 - orbY * 0.5,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.sky.withValues(alpha: 0.18),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // ── HIRAYA watermark ──
                  Positioned(
                    right: 24,
                    bottom: 16,
                    child: Opacity(
                      opacity: 0.06,
                      child: Text(
                        'HIRAYA',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 8,
                        ),
                      ),
                    ),
                  ),
                  // ── Content ──
                  child!,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroContent(BuildContext context) {
    return SizedBox(
      height: 168,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        child: Row(
          children: [
            // ── Left: logo + greeting ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Image.asset(
                          'assets/images/logo/final-logo.png',
                          height: 22,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Text(
                          'INNOVATOR PORTAL',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your Innovation Hub',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track, manage and grow your innovations',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            // ── Right: CTA ──
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: onPostNew,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppColors.navy.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.rocket_launch_rounded,
                            color: AppColors.teal, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Post Innovation',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Animated stat card (counts up from 0→value) ──────────────────────────────
class _AnimatedStatCard extends StatefulWidget {
  final String label;
  final int value;
  final IconData icon;
  final List<Color> gradient;
  final int index;

  const _AnimatedStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.index,
  });

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(20),
          transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hovered
                  ? widget.gradient.first.withValues(alpha: 0.3)
                  : AppColors.lightGray,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? widget.gradient.first.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: _hovered ? 20 : 8,
                offset: Offset(0, _hovered ? 8 : 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: widget.gradient),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradient.first.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 18),
              ),
              const SizedBox(height: 14),
              AnimatedBuilder(
                animation: _anim,
                builder: (context, _) {
                  final v = (_anim.value * widget.value).round();
                  return Text(
                    '$v',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  );
                },
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.38),
                ),
              ),
            ],
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: 60 * widget.index))
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.12, end: 0),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final int index;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.index,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(20),
          transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hovered
                  ? widget.gradient.first.withValues(alpha: 0.3)
                  : AppColors.lightGray,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? widget.gradient.first.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: _hovered ? 20 : 8,
                offset: Offset(0, _hovered ? 8 : 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient:
                      LinearGradient(colors: widget.gradient),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color:
                          widget.gradient.first.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(widget.icon,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(height: 14),
              Text(
                widget.value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.38),
                ),
              ),
            ],
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: 60 * widget.index))
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.12, end: 0),
    );
  }
}

// ── Engagement card ───────────────────────────────────────────────────────────
class _EngagementCard extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int index;

  const _EngagementCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.index,
  });

  @override
  State<_EngagementCard> createState() => _EngagementCardState();
}

class _EngagementCardState extends State<_EngagementCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.3)
                  : AppColors.lightGray,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? widget.color.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: _hovered ? 16 : 6,
                offset: Offset(0, _hovered ? 6 : 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon,
                    color: widget.color, size: 16),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.value,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.black.withValues(alpha: 0.38),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      )
          .animate(
              delay: Duration(milliseconds: 300 + 60 * widget.index))
          .fadeIn(duration: 400.ms)
          .slideY(begin: 0.1, end: 0),
    );
  }
}

// ── Recent product row ────────────────────────────────────────────────────────
class _RecentProductRow extends StatefulWidget {
  final ProductModel product;
  final int index;
  const _RecentProductRow({required this.product, required this.index});

  @override
  State<_RecentProductRow> createState() => _RecentProductRowState();
}

class _RecentProductRowState extends State<_RecentProductRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color =
        AppColors.categoryColors[widget.product.category] ?? AppColors.navy;
    final grad = _categoryGradients[widget.product.category] ??
        [AppColors.navy, const Color(0xFF0A4A6E)];
    final statusColor = widget.product.status == 'approved'
        ? AppColors.teal
        : widget.product.status == 'pending'
            ? AppColors.golden
            : AppColors.crimson;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered
                  ? color.withValues(alpha: 0.3)
                  : AppColors.lightGray,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? color.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: _hovered ? 16 : 4,
                offset: Offset(0, _hovered ? 6 : 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: grad),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: grad.first.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _categoryIcons[widget.product.category] ??
                      Icons.lightbulb_rounded,
                  color: Colors.white,
                  size: 18,
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
                        color: _hovered ? color : AppColors.navy,
                      ),
                    ),
                    Text(
                      widget.product.category,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.black.withValues(alpha: 0.38),
                      ),
                    ),
                  ],
                ),
              ),
              _MiniStat(
                  icon: Icons.favorite_rounded,
                  value: '${widget.product.likes}',
                  color: AppColors.crimson),
              const SizedBox(width: 12),
              _MiniStat(
                  icon: Icons.remove_red_eye_rounded,
                  value: '${widget.product.views}',
                  color: Colors.black38),
              const SizedBox(width: 12),
              _MiniStat(
                  icon: Icons.handshake_rounded,
                  value: '${widget.product.interestCount}',
                  color: AppColors.teal),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  widget.product.status.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 500 + 60 * widget.index))
        .fadeIn(duration: 400.ms);
  }
}

// ── Gradient button ───────────────────────────────────────────────────────────
class _GradientBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
  final bool compact;

  const _GradientBtn({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.compact = false,
  });

  @override
  State<_GradientBtn> createState() => _GradientBtnState();
}

class _GradientBtnState extends State<_GradientBtn>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          builder: (context, child) => Transform.scale(
            scale: 1.0 - _pressCtrl.value * 0.04,
            child: child,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 14 : 18,
              vertical: widget.compact ? 8 : 12,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: widget.gradient),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: widget.gradient.first.withValues(
                      alpha: _hovered ? 0.35 : 0.2),
                  blurRadius: _hovered ? 16 : 8,
                  offset: Offset(0, _hovered ? 6 : 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: widget.compact ? 12 : 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      );
}

// ═════════════════════════════════════════════════════════════════════════════
//  MY INNOVATIONS — search + filter + cinematic cards
// ═════════════════════════════════════════════════════════════════════════════
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
  bool _searchFocused = false;

  static const _statuses = [
    'All',
    'approved',
    'pending',
    'rejected'
  ];
  static const _categories = [
    'All',
    'Agriculture',
    'Healthcare',
    'Energy',
    'Construction',
    'Product Design',
    'Information Technology'
  ];
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
      list = list
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q))
          .toList();
    }
    if (_statusFilter != 'All') {
      list = list.where((p) => p.status == _statusFilter).toList();
    }
    if (_categoryFilter != 'All') {
      list = list.where((p) => p.category == _categoryFilter).toList();
    }
    switch (_sortBy) {
      case 'Most Liked':
        list.sort((a, b) => b.likes.compareTo(a.likes));
        break;
      case 'Most Views':
        list.sort((a, b) => b.views.compareTo(a.views));
        break;
      default:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Column(
      children: [
        // ── Toolbar ──
        Container(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.navy, Color(0xFF0A4A6E)]),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.navy.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.lightbulb_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'My Innovations',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppColors.teal, Color(0xFF1A9B89)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${filtered.length}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // ── Search bar ──
              Focus(
                onFocusChange: (f) =>
                    setState(() => _searchFocused = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _searchFocused
                          ? AppColors.teal
                          : AppColors.lightGray,
                      width: _searchFocused ? 1.5 : 1,
                    ),
                    color: _searchFocused
                        ? AppColors.teal.withValues(alpha: 0.03)
                        : AppColors.offWhite,
                    boxShadow: _searchFocused
                        ? [
                            BoxShadow(
                              color:
                                  AppColors.teal.withValues(alpha: 0.1),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                          fontFamily: 'Poppins', fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search your innovations...',
                        hintStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.black26,
                        ),
                        prefixIcon: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          child: Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: _searchFocused
                                ? AppColors.teal
                                : Colors.black26,
                          ),
                        ),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    size: 16),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        filled: false,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // ── Filters ──
              Row(
                children: [
                  _CinematicFilterChip(
                    label: 'Status',
                    value: _statusFilter,
                    options: _statuses,
                    onChanged: (v) =>
                        setState(() => _statusFilter = v),
                  ),
                  const SizedBox(width: 10),
                  _CinematicFilterChip(
                    label: 'Category',
                    value: _categoryFilter,
                    options: _categories,
                    onChanged: (v) =>
                        setState(() => _categoryFilter = v),
                  ),
                  const SizedBox(width: 10),
                  _CinematicFilterChip(
                    label: 'Sort',
                    value: _sortBy,
                    options: _sortOptions,
                    onChanged: (v) => setState(() => _sortBy = v),
                    icon: Icons.sort_rounded,
                  ),
                ],
              ),
            ],
          ),
        ),
        // ── List ──
        Expanded(
          child: filtered.isEmpty
              ? _EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No matches found',
                  subtitle: 'Try adjusting your search or filters.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) =>
                      _ProductDetailCard(product: filtered[i], index: i),
                ),
        ),
      ],
    );
  }
}

// ── Cinematic filter chip ─────────────────────────────────────────────────────
class _CinematicFilterChip extends StatefulWidget {
  final String label;
  final String value;
  final List<String> options;
  final void Function(String) onChanged;
  final IconData? icon;

  const _CinematicFilterChip({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.icon,
  });

  @override
  State<_CinematicFilterChip> createState() =>
      _CinematicFilterChipState();
}

class _CinematicFilterChipState extends State<_CinematicFilterChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.value != widget.options.first;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: PopupMenuButton<String>(
        initialValue: widget.value,
        onSelected: widget.onChanged,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (_) => widget.options
            .map(
              (o) => PopupMenuItem(
                value: o,
                child: Row(
                  children: [
                    if (o == widget.value)
                      const Icon(Icons.check, size: 14, color: AppColors.teal),
                    if (o == widget.value) const SizedBox(width: 8),
                    Text(o,
                        style: const TextStyle(
                            fontFamily: 'Poppins', fontSize: 13)),
                  ],
                ),
              ),
            )
            .toList(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(
                    colors: [AppColors.teal, Color(0xFF1A9B89)])
                : null,
            color: isActive
                ? null
                : _hovered
                    ? AppColors.navy.withValues(alpha: 0.06)
                    : AppColors.offWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? Colors.transparent
                  : _hovered
                      ? AppColors.navy.withValues(alpha: 0.15)
                      : AppColors.lightGray,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null)
                Icon(widget.icon,
                    size: 14,
                    color: isActive ? Colors.white : Colors.black45),
              if (widget.icon != null) const SizedBox(width: 6),
              Text(
                isActive ? widget.value : widget.label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : Colors.black54,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.black38),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Product detail card ───────────────────────────────────────────────────────
class _ProductDetailCard extends StatefulWidget {
  final ProductModel product;
  final int index;
  const _ProductDetailCard({required this.product, required this.index});

  @override
  State<_ProductDetailCard> createState() => _ProductDetailCardState();
}

class _ProductDetailCardState extends State<_ProductDetailCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color =
        AppColors.categoryColors[widget.product.category] ?? AppColors.navy;
    final grad = _categoryGradients[widget.product.category] ??
        [AppColors.navy, const Color(0xFF0A4A6E)];
    final statusColor = widget.product.status == 'approved'
        ? AppColors.teal
        : widget.product.status == 'pending'
            ? AppColors.golden
            : AppColors.crimson;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(20),
          transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hovered
                  ? color.withValues(alpha: 0.3)
                  : AppColors.lightGray,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? color.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: _hovered ? 20 : 8,
                offset: Offset(0, _hovered ? 8 : 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: grad),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: grad.first.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _categoryIcons[widget.product.category] ??
                          Icons.lightbulb_rounded,
                      color: Colors.white,
                      size: 18,
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
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _hovered ? color : AppColors.navy,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                gradient:
                                    LinearGradient(colors: grad),
                                borderRadius:
                                    BorderRadius.circular(4),
                              ),
                              child: Text(
                                widget.product.category,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${widget.product.createdAt.day}/${widget.product.createdAt.month}/${widget.product.createdAt.year}',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color:
                                    Colors.black.withValues(alpha: 0.35),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      widget.product.status.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.product.description,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.black.withValues(alpha: 0.5),
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              Divider(
                  height: 1,
                  color: AppColors.lightGray.withValues(alpha: 0.5)),
              const SizedBox(height: 14),
              Row(
                children: [
                  _MiniStat(
                      icon: Icons.favorite_rounded,
                      value: '${widget.product.likes} likes',
                      color: AppColors.crimson),
                  const SizedBox(width: 16),
                  _MiniStat(
                      icon: Icons.remove_red_eye_rounded,
                      value: '${widget.product.views} views',
                      color: Colors.black38),
                  const SizedBox(width: 16),
                  _MiniStat(
                      icon: Icons.handshake_rounded,
                      value:
                          '${widget.product.interestCount} interests',
                      color: AppColors.teal),
                  const Spacer(),
                  if (widget.product.status == 'approved')
                    _ViewLiveBtn(
                      onTap: () => context
                          .go('/product/${widget.product.id}'),
                      color: color,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 60 * widget.index))
        .fadeIn(duration: 400.ms);
  }
}

// ── View Live button ──────────────────────────────────────────────────────────
class _ViewLiveBtn extends StatefulWidget {
  final VoidCallback onTap;
  final Color color;
  const _ViewLiveBtn({required this.onTap, required this.color});

  @override
  State<_ViewLiveBtn> createState() => _ViewLiveBtnState();
}

class _ViewLiveBtnState extends State<_ViewLiveBtn> {
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
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered ? widget.color : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.color.withValues(alpha: _hovered ? 1 : 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.open_in_new_rounded,
                  size: 14,
                  color: _hovered ? Colors.white : widget.color),
              const SizedBox(width: 6),
              Text(
                'View Live',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _hovered ? Colors.white : widget.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  POST INNOVATION
// ═════════════════════════════════════════════════════════════════════════════
class _PostInnovation extends StatefulWidget {
  final Future<bool> Function(String, String, String) onSubmit;
  final bool isLoading;
  const _PostInnovation({required this.onSubmit, required this.isLoading});

  @override
  State<_PostInnovation> createState() => _PostInnovationState();
}

class _PostInnovationState extends State<_PostInnovation> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedCategory = 'Agriculture';

  final List<_PickedFile> _images = [];
  _PickedFile? _video;
  bool _hasDraft = false;

  static const _categories = [
    'Agriculture',
    'Healthcare',
    'Energy',
    'Construction',
    'Product Design',
    'Information Technology',
  ];

  @override
  void initState() {
    super.initState();
    _loadDraft();
    _nameCtrl.addListener(_saveDraft);
    _descCtrl.addListener(_saveDraft);
    _linkCtrl.addListener(_saveDraft);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  // ── Draft persistence ──
  Future<void> _loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kDraftKey);
    if (raw == null) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      setState(() {
        _nameCtrl.text = m['name'] ?? '';
        _descCtrl.text = m['desc'] ?? '';
        _linkCtrl.text = m['link'] ?? '';
        _selectedCategory = m['category'] ?? 'Agriculture';
        _hasDraft =
            _nameCtrl.text.isNotEmpty || _descCtrl.text.isNotEmpty;
      });
    } catch (_) {}
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kDraftKey,
      jsonEncode({
        'name': _nameCtrl.text,
        'desc': _descCtrl.text,
        'link': _linkCtrl.text,
        'category': _selectedCategory,
      }),
    );
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDraftKey);
    setState(() => _hasDraft = false);
  }

  // ── Image picker ──
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
    final toAdd = result.files.take(remaining);
    for (final f in toAdd) {
      if ((f.size / 1024 / 1024) > 5) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${f.name} exceeds 5MB limit — skipped.',
                style: const TextStyle(fontFamily: 'Poppins')),
            backgroundColor: AppColors.crimson,
          ));
        }
        continue;
      }
      if (f.bytes != null) {
        setState(() => _images.add(_PickedFile(
            name: f.name, bytes: f.bytes!, sizeKb: f.size ~/ 1024)));
      }
    }
  }

  // ── Video picker ──
  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mov'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    final sizeMb = f.size / 1024 / 1024;
    if (sizeMb > 100) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Video too large. Max ~100MB.'),
            backgroundColor: AppColors.crimson));
      }
      return;
    }
    if (f.bytes != null) {
      setState(() => _video = _PickedFile(
          name: f.name, bytes: f.bytes!, sizeKb: f.size ~/ 1024));
    }
  }

  // ── Submit ──
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_images.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please upload at least 5 images.',
            style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppColors.crimson,
      ));
      return;
    }
    final success = await widget.onSubmit(
      _nameCtrl.text.trim(),
      _descCtrl.text.trim(),
      _selectedCategory,
    );
    if (success && mounted) {
      _nameCtrl.clear();
      _descCtrl.clear();
      _linkCtrl.clear();
      setState(() {
        _images.clear();
        _video = null;
        _selectedCategory = 'Agriculture';
      });
      await _clearDraft();
    }
  }

  InputDecoration _inputDec(String hint, {Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            fontFamily: 'Poppins', fontSize: 13, color: Colors.black26),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightGray)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightGray)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.teal, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.crimson)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.crimson, width: 2)),
      );

  @override
  Widget build(BuildContext context) {
    final catGrad = _categoryGradients[_selectedCategory] ??
        [AppColors.navy, const Color(0xFF0A4A6E)];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    colors: catGrad),
                                borderRadius:
                                    BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: catGrad.first
                                        .withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                  Icons.rocket_launch_rounded,
                                  color: Colors.white,
                                  size: 20),
                            ),
                            const SizedBox(width: 14),
                            const Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Post an Innovation',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navy,
                                  ),
                                ),
                                Text(
                                  'Submit your innovation for admin review.',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 13,
                                    color: Colors.black45,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_hasDraft)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.golden.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.golden
                                .withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_note_rounded,
                              size: 16, color: AppColors.golden),
                          const SizedBox(width: 6),
                          const Text(
                            'Draft restored',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AppColors.golden,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              _nameCtrl.clear();
                              _descCtrl.clear();
                              _linkCtrl.clear();
                              _clearDraft();
                            },
                            child: const Icon(Icons.close,
                                size: 14, color: AppColors.golden),
                          ),
                        ],
                      ),
                    ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.06, end: 0),

              const SizedBox(height: 28),

              // ── BASIC INFO ──
              const _SectionHeader(
                  'Basic Information', Icons.info_outline_rounded),
              const SizedBox(height: 16),

              const _FormLabel('Innovation Name *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                maxLength: 120,
                style: const TextStyle(
                    fontFamily: 'Poppins', fontSize: 14),
                decoration:
                    _inputDec('e.g. Smart Solar Irrigation System'),
                validator: (v) => v == null || v.trim().length < 5
                    ? 'Minimum 5 characters'
                    : null,
              ),

              const SizedBox(height: 16),

              const _FormLabel('Category *'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightGray),
                ),
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  underline: const SizedBox(),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: AppColors.darkGray,
                  ),
                  onChanged: (v) => setState(() {
                    _selectedCategory = v ?? _selectedCategory;
                    _saveDraft();
                  }),
                  items: _categories.map((c) {
                    final cc =
                        AppColors.categoryColors[c] ?? AppColors.navy;
                    final cIcon =
                        _categoryIcons[c] ?? Icons.category_rounded;
                    return DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: cc.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(6),
                            ),
                            child:
                                Icon(cIcon, size: 14, color: cc),
                          ),
                          const SizedBox(width: 10),
                          Text(c),
                        ],
                      ),
                    );
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
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    height: 1.5),
                decoration: _inputDec(
                    'Describe your innovation — what it does, who it helps, and why it matters...'),
                validator: (v) => v == null || v.trim().length < 30
                    ? 'Minimum 30 characters'
                    : null,
              ),

              const SizedBox(height: 28),

              // ── IMAGES ──
              _SectionHeader('Images', Icons.photo_library_rounded,
                  badge: '${_images.length}/10 · Min 5 required'),
              const SizedBox(height: 8),
              Text(
                'JPEG, PNG, WebP · Max 5 MB each · First image = cover thumbnail · Drag to reorder',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.38),
                ),
              ),
              const SizedBox(height: 12),

              if (_images.isNotEmpty)
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _images.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = _images.removeAt(oldIndex);
                      _images.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (ctx, i) {
                    final f = _images[i];
                    return _ImageSlotTile(
                      key: ValueKey(f.name + i.toString()),
                      file: f,
                      index: i,
                      isCover: i == 0,
                      onRemove: () =>
                          setState(() => _images.removeAt(i)),
                    );
                  },
                ),

              if (_images.length < 10)
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            AppColors.teal.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.add_photo_alternate_rounded,
                            size: 28,
                            color: AppColors.teal
                                .withValues(alpha: 0.6)),
                        const SizedBox(height: 6),
                        Text(
                          _images.isEmpty
                              ? 'Click to add images (5–10 required)'
                              : 'Add more images (${10 - _images.length} remaining)',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: AppColors.teal
                                .withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 28),

              // ── VIDEO ──
              const _SectionHeader(
                  'Short Video', Icons.videocam_rounded,
                  badge: 'Optional · 30–60 sec · MP4/MOV'),
              const SizedBox(height: 12),

              if (_video != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.sky.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.sky.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.video_file_rounded,
                          color: AppColors.sky, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(_video!.name,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.navy,
                                )),
                            Text('${_video!.sizeKb} KB',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: Colors.black38,
                                )),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 18, color: AppColors.crimson),
                        onPressed: () =>
                            setState(() => _video = null),
                      ),
                    ],
                  ),
                )
              else
                GestureDetector(
                  onTap: _pickVideo,
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.lightGray, width: 1.5),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.video_call_rounded,
                            size: 28, color: Colors.black26),
                        SizedBox(height: 6),
                        Text(
                          'Click to add a short preview video',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Colors.black38,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'MP4 or MOV · 30–60 seconds recommended',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Colors.black26,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 28),

              // ── QR / EXTERNAL LINK ──
              const _SectionHeader(
                  'QR Code / External Link', Icons.link_rounded,
                  badge: 'Optional'),
              const SizedBox(height: 8),
              Text(
                'Paste a URL pointing to a full demo, pitch deck, or presentation hosted externally (YouTube, Google Drive, Canva, etc.)',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.38),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _linkCtrl,
                style: const TextStyle(
                    fontFamily: 'Poppins', fontSize: 14),
                decoration: _inputDec(
                  'https://drive.google.com/... or https://youtu.be/...',
                  suffix: _linkCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () =>
                              setState(() => _linkCtrl.clear()))
                      : const Icon(Icons.open_in_new_rounded,
                          size: 16, color: Colors.black26),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final uri = Uri.tryParse(v.trim());
                  if (uri == null ||
                      !uri.hasAbsolutePath ||
                      (!uri.scheme.startsWith('http'))) {
                    return 'Enter a valid URL (https://...)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // ── SUBMIT ──
              _ProgressBar(
                images: _images.length,
                hasName: _nameCtrl.text.trim().length >= 5,
                hasDesc: _descCtrl.text.trim().length >= 30,
              ),
              const SizedBox(height: 20),

              _SubmitButton(
                isLoading: widget.isLoading,
                gradient: catGrad,
                onTap: _submit,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Submit button ─────────────────────────────────────────────────────────────
class _SubmitButton extends StatefulWidget {
  final bool isLoading;
  final List<Color> gradient;
  final VoidCallback onTap;
  const _SubmitButton(
      {required this.isLoading,
      required this.gradient,
      required this.onTap});

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late final AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) {
          _pressCtrl.reverse();
          if (!widget.isLoading) widget.onTap();
        },
        onTapCancel: () => _pressCtrl.reverse(),
        child: AnimatedBuilder(
          animation: _pressCtrl,
          builder: (context, child) => Transform.scale(
            scale: 1.0 - _pressCtrl.value * 0.03,
            child: child,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: widget.gradient),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: widget.gradient.first
                      .withValues(alpha: _hovered ? 0.4 : 0.2),
                  blurRadius: _hovered ? 20 : 10,
                  offset: Offset(0, _hovered ? 8 : 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                else
                  const Icon(Icons.rocket_launch_rounded,
                      color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(
                  widget.isLoading
                      ? 'Submitting...'
                      : 'Submit for Admin Review',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white,
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

// ── Image slot tile ───────────────────────────────────────────────────────────
class _ImageSlotTile extends StatelessWidget {
  final _PickedFile file;
  final int index;
  final bool isCover;
  final VoidCallback onRemove;

  const _ImageSlotTile({
    super.key,
    required this.file,
    required this.index,
    required this.isCover,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCover
              ? AppColors.teal.withValues(alpha: 0.5)
              : AppColors.lightGray,
          width: isCover ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_handle_rounded,
              color: Colors.black26, size: 20),
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(file.bytes,
                width: 52, height: 42, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                      width: 52,
                      height: 42,
                      color: AppColors.lightGray,
                      child: const Icon(Icons.broken_image,
                          size: 20, color: Colors.black26),
                    )),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(file.name,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy,
                    ),
                    overflow: TextOverflow.ellipsis),
                Text('${file.sizeKb} KB',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.black38,
                    )),
              ],
            ),
          ),
          if (isCover)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.teal, Color(0xFF1A9B89)]),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Cover',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 16, color: AppColors.crimson),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

// ── Progress bar ──────────────────────────────────────────────────────────────
class _ProgressBar extends StatelessWidget {
  final int images;
  final bool hasName;
  final bool hasDesc;

  const _ProgressBar(
      {required this.images,
      required this.hasName,
      required this.hasDesc});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _Step('Name', hasName),
      _Step('Description', hasDesc),
      _Step('5+ Images', images >= 5),
    ];
    final done = steps.where((s) => s.done).length;
    final progress = done / steps.length;
    final complete = done == steps.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: complete
              ? AppColors.teal.withValues(alpha: 0.3)
              : AppColors.lightGray,
        ),
        boxShadow: complete
            ? [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.08),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                complete
                    ? Icons.check_circle_rounded
                    : Icons.pending_rounded,
                size: 18,
                color: complete ? AppColors.teal : AppColors.golden,
              ),
              const SizedBox(width: 8),
              const Text(
                'Submission readiness',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
              const Spacer(),
              Text(
                '$done/${steps.length}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: complete ? AppColors.teal : AppColors.golden,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.lightGray,
              color: complete ? AppColors.teal : AppColors.golden,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: steps
                .map(
                  (s) => Expanded(
                    child: Row(
                      children: [
                        Icon(
                          s.done
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 14,
                          color: s.done
                              ? AppColors.teal
                              : Colors.black26,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          s.label,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: s.done
                                ? AppColors.teal
                                : Colors.black38,
                            fontWeight: s.done
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _Step {
  final String label;
  final bool done;
  const _Step(this.label, this.done);
}

// ═════════════════════════════════════════════════════════════════════════════
//  PROFILE
// ═════════════════════════════════════════════════════════════════════════════
class _InnovatorProfile extends StatelessWidget {
  final dynamic user;
  const _InnovatorProfile({this.user});

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.teal));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.navy, Color(0xFF0A4A6E)]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'My Profile',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideX(
                begin: -0.08, end: 0),
            const SizedBox(height: 28),
            // ── Profile card ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.lightGray),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ── Banner ──
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.navy, AppColors.teal],
                      ),
                    ),
                    child: CustomPaint(
                      painter: _ProfileBannerPainter(),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  // ── Avatar overlap ──
                  Transform.translate(
                    offset: const Offset(0, -36),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.teal
                                    .withValues(alpha: 0.25),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.teal,
                                  Color(0xFF1A9B89)
                                ],
                              ),
                              border: Border.all(
                                  color: Colors.white, width: 3),
                            ),
                            child: Center(
                              child: Text(
                                user.firstName
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                        Text(
                          '@${user.username}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color:
                                Colors.black.withValues(alpha: 0.4),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.teal,
                                Color(0xFF1A9B89)
                              ],
                            ),
                            borderRadius:
                                BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.teal
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'Innovator',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24),
                          child: Divider(
                              color: AppColors.lightGray
                                  .withValues(alpha: 0.5)),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24),
                          child: Column(
                            children: [
                              _ProfileRow(
                                  label: 'Email',
                                  value: user.email,
                                  icon: Icons.email_outlined),
                              _ProfileRow(
                                  label: 'KYC Status',
                                  value: user.kycStatus.toUpperCase(),
                                  icon:
                                      Icons.verified_user_rounded),
                              _ProfileRow(
                                  label: 'Account Status',
                                  value: user.userStatus == 1
                                      ? 'Active'
                                      : 'Pending',
                                  icon: Icons.circle_rounded),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate(delay: 200.ms).fadeIn(duration: 500.ms).slideY(
                begin: 0.06, end: 0),
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
  const _ProfileRow(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: AppColors.teal),
            ),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.black.withValues(alpha: 0.4),
                )),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                )),
          ],
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
//  HELPERS & PAINTERS
// ═════════════════════════════════════════════════════════════════════════════
class _PickedFile {
  final String name;
  final Uint8List bytes;
  final int sizeKb;
  const _PickedFile(
      {required this.name, required this.bytes, required this.sizeKb});
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? badge;
  const _SectionHeader(this.title, this.icon, {this.badge});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.navy, Color(0xFF0A4A6E)]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text(title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            )),
        if (badge != null) ...[
          const SizedBox(width: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.offWhite,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.lightGray),
            ),
            child: Text(badge!,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Colors.black45,
                )),
          ),
        ],
      ],
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;
  const _FormLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.navy,
      ));
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 60),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.lightGray),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                )),
            const SizedBox(height: 8),
            Text(subtitle,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.black.withValues(alpha: 0.38),
                )),
          ],
        ),
      );
}

// ── Skeleton bar helper ───────────────────────────────────────────────────────
class _LSkel extends StatelessWidget {
  final double w;
  final double h;
  final double r;
  const _LSkel({required this.w, required this.h, required this.r});

  @override
  Widget build(BuildContext context) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(r),
        ),
      );
}

// ── Sidebar dot grid painter ──────────────────────────────────────────────────
class _SidebarDotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Profile banner painter ────────────────────────────────────────────────────
class _ProfileBannerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
    // Decorative circles
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.3),
      40,
      Paint()..color = Colors.white.withValues(alpha: 0.04),
    );
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.7),
      30,
      Paint()..color = Colors.white.withValues(alpha: 0.03),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═════════════════════════════════════════════════════════════════════════════
//  MARKETPLACE TAB
// ═════════════════════════════════════════════════════════════════════════════
class _MarketplaceTab extends ConsumerStatefulWidget {
  const _MarketplaceTab();

  @override
  ConsumerState<_MarketplaceTab> createState() => _MarketplaceTabState();
}

class _MarketplaceTabState extends ConsumerState<_MarketplaceTab> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _selectedCategory = 'All';

  static const _categories = [
    'All',
    'Agriculture',
    'Healthcare',
    'Energy',
    'Construction',
    'Product Design',
    'Information Technology',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(innovatorProvider).myProducts;
    final filtered = allProducts.where((p) {
      final matchQ = _query.isEmpty ||
          p.name.toLowerCase().contains(_query.toLowerCase());
      final matchC = _selectedCategory == 'All' ||
          (p.category ?? '') == _selectedCategory;
      return matchQ && matchC;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.golden, Color(0xFFFFD45C)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.golden.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Marketplace',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  Text(
                    'Browse and discover innovations',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.38),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Full marketplace link
              GestureDetector(
                onTap: () => GoRouter.of(context).go('/marketplace'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.golden, Color(0xFFFFD45C)]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.golden.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.open_in_new_rounded,
                          color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Full Marketplace',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.06, end: 0),
          const SizedBox(height: 24),

          // ── Search box ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.lightGray),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.navy,
              ),
              decoration: InputDecoration(
                hintText: 'Search innovations...',
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                prefixIcon: Icon(Icons.search_rounded,
                    color: AppColors.golden.withValues(alpha: 0.8), size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded,
                            color:
                                Colors.black.withValues(alpha: 0.3),
                            size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ).animate(delay: 100.ms).fadeIn(duration: 350.ms),
          const SizedBox(height: 16),

          // ── Category chips ──
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final selected = cat == _selectedCategory;
                final catColor = _selectedCategory == 'All'
                    ? AppColors.golden
                    : (_categoryGradients[cat]?.first ?? AppColors.golden);
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? LinearGradient(colors: [
                              catColor,
                              catColor.withValues(alpha: 0.7),
                            ])
                          : null,
                      color: selected
                          ? null
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? Colors.transparent
                            : AppColors.lightGray,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: catColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [],
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected
                            ? Colors.white
                            : Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                );
              },
            ),
          ).animate(delay: 150.ms).fadeIn(duration: 350.ms),
          const SizedBox(height: 24),

          // ── Product grid ──
          if (filtered.isEmpty)
            _EmptyState(
              icon: Icons.storefront_outlined,
              title: 'No Products Found',
              subtitle: 'Try a different search or category filter.',
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms)
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
              ),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final p = filtered[i];
                return _MarketplaceCard(product: p, index: i);
              },
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}

// ── Marketplace product card ───────────────────────────────────────────────────
class _MarketplaceCard extends StatefulWidget {
  final ProductModel product;
  final int index;
  const _MarketplaceCard({required this.product, required this.index});

  @override
  State<_MarketplaceCard> createState() => _MarketplaceCardState();
}

class _MarketplaceCardState extends State<_MarketplaceCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.product.category ?? '';
    final gradColors =
        _categoryGradients[cat] ?? [AppColors.navy, const Color(0xFF0A4A6E)];
    final catIcon = _categoryIcons[cat] ?? Icons.category_rounded;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -5 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered
                ? gradColors.first.withValues(alpha: 0.3)
                : AppColors.lightGray,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? gradColors.first.withValues(alpha: 0.14)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: _hovered ? 24 : 8,
              offset: Offset(0, _hovered ? 10 : 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient:
                          LinearGradient(colors: gradColors),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color:
                              gradColors.first.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child:
                        Icon(catIcon, color: Colors.white, size: 16),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: gradColors.first.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: gradColors.first
                              .withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      cat.isNotEmpty ? cat : 'General',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: gradColors.first,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                widget.product.name.isEmpty ? 'Untitled' : widget.product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.product.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Colors.black.withValues(alpha: 0.38),
                ),
              ),
            ],
          ),
        ),
      )
          .animate(
              delay: Duration(milliseconds: 40 * widget.index))
          .fadeIn(duration: 350.ms)
          .slideY(begin: 0.1, end: 0),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  MESSAGES TAB
// ═════════════════════════════════════════════════════════════════════════════
class _MessagesTab extends ConsumerWidget {
  const _MessagesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sample placeholder conversations — in real app hook to messaging provider
    final conversations = [
      _MockConversation(
        name: 'Admin Team',
        lastMsg: 'Your innovation has been reviewed.',
        time: '2m ago',
        unread: 3,
        gradColors: [AppColors.navy, const Color(0xFF0A4A6E)],
        initial: 'A',
      ),
      _MockConversation(
        name: 'Maria Santos',
        lastMsg: 'I am interested in your energy solution.',
        time: '1h ago',
        unread: 1,
        gradColors: [AppColors.teal, const Color(0xFF1A9B89)],
        initial: 'M',
      ),
      _MockConversation(
        name: 'Juan Dela Cruz',
        lastMsg: 'Can we schedule a meeting?',
        time: '3h ago',
        unread: 0,
        gradColors: [AppColors.sky, const Color(0xFF5BA8E5)],
        initial: 'J',
      ),
      _MockConversation(
        name: 'Investor Network',
        lastMsg: 'Funding opportunity available.',
        time: 'Yesterday',
        unread: 2,
        gradColors: [AppColors.golden, const Color(0xFFFFD45C)],
        initial: 'I',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.sky, Color(0xFF5BA8E5)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sky.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.chat_bubble_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Messages',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                  Text(
                    'Your conversations at a glance',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.black.withValues(alpha: 0.38),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => GoRouter.of(context).go('/messages'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.sky, Color(0xFF5BA8E5)]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sky.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.open_in_new_rounded,
                          color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Full Messaging',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.06, end: 0),
          const SizedBox(height: 24),

          // ── Conversation list ──
          ...conversations.asMap().entries.map((e) {
            final i = e.key;
            final c = e.value;
            return _ConversationTile(convo: c, index: i);
          }),
        ],
      ),
    );
  }
}

class _MockConversation {
  final String name;
  final String lastMsg;
  final String time;
  final int unread;
  final List<Color> gradColors;
  final String initial;
  const _MockConversation({
    required this.name,
    required this.lastMsg,
    required this.time,
    required this.unread,
    required this.gradColors,
    required this.initial,
  });
}

class _ConversationTile extends StatefulWidget {
  final _MockConversation convo;
  final int index;
  const _ConversationTile({required this.convo, required this.index});

  @override
  State<_ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<_ConversationTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.convo;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        transform:
            Matrix4.translationValues(_hovered ? 4 : 0, 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? c.gradColors.first.withValues(alpha: 0.3)
                : AppColors.lightGray,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? c.gradColors.first.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: _hovered ? 16 : 6,
              offset: Offset(_hovered ? 4 : 0, _hovered ? 6 : 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Avatar ──
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: c.gradColors),
                boxShadow: [
                  BoxShadow(
                    color: c.gradColors.first.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  c.initial,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // ── Content ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        c.name,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: c.unread > 0
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: AppColors.navy,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        c.time,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: c.unread > 0
                              ? c.gradColors.first
                              : Colors.black.withValues(alpha: 0.35),
                          fontWeight: c.unread > 0
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.lastMsg,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: c.unread > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: c.unread > 0
                                ? AppColors.navy
                                : Colors.black.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      if (c.unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                                colors: c.gradColors),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: c.gradColors.first
                                    .withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${c.unread}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _hovered ? 1.0 : 0.0,
              child: Icon(
                Icons.chevron_right_rounded,
                color: c.gradColors.first,
                size: 20,
              ),
            ),
          ],
        ),
      )
          .animate(
              delay: Duration(milliseconds: 60 * widget.index))
          .fadeIn(duration: 350.ms)
          .slideX(begin: 0.06, end: 0),
    );
  }
}
