// lib/features/landing/widgets/category_grid.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// CategoryGrid — Innovation category browser (Enhanced v3)
// Glassmorphic cards • Hover lift + glow • Animated underline
// Color-coded per category • Stagger entry • Count badges
// ═══════════════════════════════════════════════════════════

class CategoryGrid extends StatefulWidget {
  const CategoryGrid({super.key});

  @override
  State<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<CategoryGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _orbCtrl;

  static const List<Map<String, dynamic>> _categories = [
    {
      'name': 'Agriculture',
      'icon': Icons.grass_rounded,
      'color': AppColors.teal,
      'desc': 'Sustainable farming & agri-tech innovations for Filipino farmers',
      'count': 42,
      'tag': 'Most Active',
    },
    {
      'name': 'Healthcare',
      'icon': Icons.medical_services_rounded,
      'color': AppColors.crimson,
      'desc': 'Medical breakthroughs improving lives across the Philippines',
      'count': 38,
      'tag': 'High Demand',
    },
    {
      'name': 'Energy',
      'icon': Icons.bolt_rounded,
      'color': AppColors.golden,
      'desc': 'Clean & renewable energy solutions for communities',
      'count': 29,
      'tag': 'Growing',
    },
    {
      'name': 'Construction',
      'icon': Icons.foundation_rounded,
      'color': AppColors.sky,
      'desc': 'Smart infrastructure and resilient building technologies',
      'count': 21,
      'tag': 'Expanding',
    },
    {
      'name': 'Product Design',
      'icon': Icons.design_services_rounded,
      'color': Color(0xFF7C6AF0),
      'desc': 'Creative product development, prototyping, and local craftsmanship',
      'count': 33,
      'tag': 'Creative',
    },
    {
      'name': 'Information Technology',
      'icon': Icons.computer_rounded,
      'color': Color(0xFF3A8FD5),
      'desc': 'Software, AI, and digital transformation for the modern era',
      'count': 57,
      'tag': 'Top Category',
    },
  ];

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      duration: const Duration(seconds: 7),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 900;
    final crossCount = isDesktop ? 3 : (w >= 600 ? 2 : 1);

    return AnimatedBuilder(
      animation: _orbCtrl,
      builder: (_, __) {
        final t = _orbCtrl.value;
        return Container(
          width: double.infinity,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.deepVoid, AppColors.midnight, AppColors.deepVoid],
            ),
          ),
          child: Stack(
            children: [
              // Ambient orbs
              Positioned(
                right: -80 + t * 40,
                top: 60 + t * 50,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.golden.withValues(alpha: 0.05),
                        blurRadius: 200,
                        spreadRadius: 60,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: -60 + t * 30,
                bottom: 40 + t * 40,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.05),
                        blurRadius: 150,
                        spreadRadius: 40,
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 80 : 24,
                  vertical: isDesktop ? 80 : 56,
                ),
                child: Column(
                  children: [
                    _buildHeader(isDesktop),
                    SizedBox(height: isDesktop ? 52 : 36),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: isDesktop ? 1.3 : (w >= 600 ? 1.2 : 1.5),
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (_, i) => _CategoryCard(
                        data: _categories[i],
                        index: i,
                      ),
                    ),
                    SizedBox(height: isDesktop ? 48 : 32),
                    // Browse all link
                    _BrowseAllButton(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.golden, AppColors.warmEmber],
          ).createShader(bounds),
          child: const Text(
            'EXPLORE BY CATEGORY',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 3,
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.3, end: 0),
        const SizedBox(height: 14),
        Text(
          'Discover Innovations\nby Industry',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: isDesktop ? 42 : 30,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.15,
            letterSpacing: -1.5,
          ),
        )
            .animate(delay: 100.ms)
            .fadeIn(duration: 600.ms)
            .slideY(begin: 0.2, end: 0),
        const SizedBox(height: 12),
        Text(
          '${_categories.fold<int>(0, (sum, c) => sum + (c['count'] as int))}+ innovations across ${_categories.length} categories — find the solutions that matter to you',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: isDesktop ? 15 : 13,
            color: Colors.white.withValues(alpha: 0.42),
            height: 1.6,
          ),
        )
            .animate(delay: 200.ms)
            .fadeIn(duration: 500.ms),
        const SizedBox(height: 20),
        // Animated golden underline
        _AnimatedUnderline()
            .animate(delay: 300.ms)
            .fadeIn(duration: 400.ms)
            .scaleX(begin: 0, end: 1, alignment: Alignment.center),
      ],
    );
  }
}

// ── Animated Underline ────────────────────────────────────────────────────
class _AnimatedUnderline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      width: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.transparent, AppColors.golden, Colors.transparent],
        ),
        borderRadius: BorderRadius.circular(1),
        boxShadow: [
          BoxShadow(
            color: AppColors.golden.withValues(alpha: 0.40),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

// ── Browse All Button ─────────────────────────────────────────────────────
class _BrowseAllButton extends StatefulWidget {
  @override
  State<_BrowseAllButton> createState() => _BrowseAllButtonState();
}

class _BrowseAllButtonState extends State<_BrowseAllButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go('/marketplace'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.golden.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _hovered
                  ? AppColors.golden.withValues(alpha: 0.55)
                  : AppColors.borderDark,
              width: 1.5,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.golden.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Browse All Innovations',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _hovered ? AppColors.golden : Colors.white.withValues(alpha: 0.60),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                transform: Matrix4.translationValues(_hovered ? 4 : 0, 0, 0),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: _hovered ? AppColors.golden : Colors.white.withValues(alpha: 0.40),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: 400.ms)
        .fadeIn(duration: 500.ms);
  }
}

// ── Category Card ─────────────────────────────────────────────────────────
class _CategoryCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final int index;

  const _CategoryCard({required this.data, required this.index});

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  void _onHoverEnter() {
    setState(() => _hovered = true);
    _shimmerCtrl.forward(from: 0);
  }

  void _onHoverExit() {
    setState(() => _hovered = false);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.data['name'] as String;
    final icon = widget.data['icon'] as IconData;
    final color = widget.data['color'] as Color;
    final desc = widget.data['desc'] as String;
    final count = widget.data['count'] as int;
    final tag = widget.data['tag'] as String;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _onHoverEnter(),
      onExit: (_) => _onHoverExit(),
      child: GestureDetector(
        onTap: () => context.go('/marketplace?category=${Uri.encodeComponent(name)}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _hovered ? -10 : 0, 0),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _hovered
                  ? color.withValues(alpha: 0.65)
                  : AppColors.borderDark,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? color.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.35),
                blurRadius: _hovered ? 40 : 14,
                offset: const Offset(0, 8),
                spreadRadius: _hovered ? 4 : 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                // Colored top strip
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    height: _hovered ? 5 : 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color,
                          color.withValues(alpha: 0.40),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: _hovered
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.40),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                  ),
                ),

                // Background watermark icon
                Positioned(
                  right: -16,
                  bottom: -16,
                  child: Icon(
                    icon,
                    size: 100,
                    color: color.withValues(alpha: _hovered ? 0.10 : 0.06),
                  ),
                ),

                // Card content
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon + tag row
                      Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: _hovered ? 0.22 : 0.14),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: color.withValues(alpha: _hovered ? 0.55 : 0.28),
                              ),
                              boxShadow: _hovered
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.30),
                                        blurRadius: 18,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Icon(icon, color: color, size: 24),
                            ),
                          ),
                          const Spacer(),
                          // Tag chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: color.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: color,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Category name
                      Text(
                        name,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _hovered ? Colors.white : Colors.white.withValues(alpha: 0.90),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Description — reveals on hover
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 250),
                        firstChild: Text(
                          '${count} innovations',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.38),
                          ),
                        ),
                        secondChild: Text(
                          desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.52),
                            height: 1.5,
                          ),
                        ),
                        crossFadeState: _hovered
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                      ),

                      const Spacer(),

                      // Bottom row
                      Row(
                        children: [
                          // Count badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: color.withValues(alpha: 0.28),
                              ),
                            ),
                            child: Text(
                              '$count innovations',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                          const Spacer(),
                          // Explore arrow
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            transform: Matrix4.translationValues(
                              _hovered ? 0 : 4, 0, 0),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: _hovered
                                  ? color
                                  : Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 80))
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic);
  }
}
