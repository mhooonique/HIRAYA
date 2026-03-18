import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// CategoryGrid — Innovation category browser (Enhanced v2)
// ═══════════════════════════════════════════════════════════
class CategoryGrid extends StatefulWidget {
  const CategoryGrid({super.key});

  @override
  State<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<CategoryGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _orbCtrl;
  late Animation<double> _orbAnim;

  static const List<Map<String, dynamic>> _categories = [
    {
      'name': 'Agriculture',
      'icon': Icons.grass_rounded,
      'color': AppColors.teal,
      'desc': 'Sustainable farming & agri-tech solutions',
      'count': 42,
    },
    {
      'name': 'Healthcare',
      'icon': Icons.medical_services_rounded,
      'color': AppColors.crimson,
      'desc': 'Medical innovations improving Filipino lives',
      'count': 38,
    },
    {
      'name': 'Energy',
      'icon': Icons.bolt_rounded,
      'color': AppColors.golden,
      'desc': 'Clean & renewable energy technologies',
      'count': 29,
    },
    {
      'name': 'Construction',
      'icon': Icons.foundation_rounded,
      'color': AppColors.sky,
      'desc': 'Smart infrastructure & building solutions',
      'count': 21,
    },
    {
      'name': 'Product Design',
      'icon': Icons.design_services_rounded,
      'color': Color(0xFF7C6AF0),
      'desc': 'Creative product development & prototyping',
      'count': 33,
    },
    {
      'name': 'Information Technology',
      'icon': Icons.computer_rounded,
      'color': Color(0xFF3A8FD5),
      'desc': 'Software, AI, and digital transformation',
      'count': 57,
    },
  ];

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
    _orbAnim = CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.deepVoid, AppColors.midnight],
        ),
      ),
      child: Column(
        children: [
          // ── Mini hero section (200px) ──────────────────────
          _buildHeroBanner(context),

          // ── Category grid ──────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
            child: Column(
              children: [
                LayoutBuilder(builder: (context, constraints) {
                  final crossCount = constraints.maxWidth > 900
                      ? 3
                      : constraints.maxWidth > 600
                          ? 2
                          : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossCount,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                      childAspectRatio: crossCount == 1 ? 2.2 : 1.30,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      return _CategoryCard(
                        name: cat['name'] as String,
                        icon: cat['icon'] as IconData,
                        color: cat['color'] as Color,
                        desc: cat['desc'] as String,
                        count: cat['count'] as int,
                        index: index,
                      );
                    },
                  );
                }),

                const SizedBox(height: 60),

                // ── Bottom CTA strip ────────────────────────
                _buildCtaStrip(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Mini hero banner (200px) ──────────────────────────────
  Widget _buildHeroBanner(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _orbAnim,
      builder: (_, child) {
        final t = _orbAnim.value;
        return SizedBox(
          height: 200,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Gradient background
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.richNavy,
                        Color(0xFF061A2E),
                        AppColors.deepVoid,
                      ],
                    ),
                  ),
                ),
              ),

              // Subtle grid overlay
              Positioned.fill(
                child: Opacity(
                  opacity: 0.025,
                  child: CustomPaint(painter: _MiniGridPainter()),
                ),
              ),

              // Teal orb — top right
              Positioned(
                right: -40 + t * 16,
                top: -30 + t * 10,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.14),
                        blurRadius: 120,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // Golden orb — left
              Positioned(
                left: -30 + t * 10,
                bottom: -20 + t * 8,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.golden.withValues(alpha: 0.10),
                        blurRadius: 100,
                        spreadRadius: 16,
                      ),
                    ],
                  ),
                ),
              ),

              // Sky orb — center
              Positioned(
                left: size.width * 0.42 + t * 6,
                top: 10 - t * 6,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sky.withValues(alpha: 0.08),
                        blurRadius: 80,
                        spreadRadius: 12,
                      ),
                    ],
                  ),
                ),
              ),

              // Category color accent dots strip
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.teal.withValues(alpha: 0.50),
                        AppColors.golden.withValues(alpha: 0.50),
                        AppColors.crimson.withValues(alpha: 0.50),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              child!,
            ],
          ),
        );
      },
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Eyebrow pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.teal.withValues(alpha: 0.35),
                  ),
                ),
                child: const Text(
                  'BROWSE BY SECTOR',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teal,
                    letterSpacing: 2,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 100.ms)
                  .slideY(begin: -0.2, end: 0),

              const SizedBox(height: 14),

              const Text(
                'Innovation Categories',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.8,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 250.ms)
                  .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: 10),

              Text(
                'Six sectors driving the future of the Philippines',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.50),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Bottom CTA strip ──────────────────────────────────────
  Widget _buildCtaStrip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.teal.withValues(alpha: 0.08),
            AppColors.golden.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderDark,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Explore all categories in the marketplace',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.70),
            ),
          ),
          const SizedBox(width: 16),
          _CtaStripButton(
            label: 'View All Categories',
            onTap: () => context.go('/marketplace'),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic);
  }
}

// ═══════════════════════════════════════════════════════════
// CTA Strip button
// ═══════════════════════════════════════════════════════════
class _CtaStripButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _CtaStripButton({required this.label, required this.onTap});

  @override
  State<_CtaStripButton> createState() => _CtaStripButtonState();
}

class _CtaStripButtonState extends State<_CtaStripButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.golden, AppColors.warmEmber],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.golden.withValues(alpha: 0.40),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View All Categories',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, color: AppColors.navy, size: 15),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Category card — larger with count badge + hover reveal
// ═══════════════════════════════════════════════════════════
class _CategoryCard extends StatefulWidget {
  final String name;
  final IconData icon;
  final Color color;
  final String desc;
  final int count;
  final int index;

  const _CategoryCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.desc,
    required this.count,
    required this.index,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovered = true);
        _scaleCtrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _scaleCtrl.reverse();
      },
      child: GestureDetector(
        onTap: () => context.go('/marketplace?category=${widget.name}'),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            transform:
                Matrix4.translationValues(0.0, _hovered ? -6.0 : 0.0, 0.0),
            decoration: BoxDecoration(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.10)
                  : AppColors.darkSurface.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _hovered
                    ? widget.color.withValues(alpha: 0.55)
                    : AppColors.borderDark,
                width: 1.5,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.28),
                        blurRadius: 36,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: widget.color.withValues(alpha: 0.08),
                        blurRadius: 60,
                        spreadRadius: 10,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.20),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Stack(
              children: [
                // Subtle inner glow on hover
                if (_hovered)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: RadialGradient(
                          center: Alignment.topLeft,
                          radius: 1.5,
                          colors: [
                            widget.color.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: icon + count badge + arrow
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: widget.color.withValues(
                                alpha: _hovered ? 0.22 : 0.10,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: widget.color.withValues(
                                  alpha: _hovered ? 0.45 : 0.18,
                                ),
                              ),
                            ),
                            child: Icon(
                              widget.icon,
                              color: widget.color,
                              size: 28,
                            ),
                          ),

                          const Spacer(),

                          // Count badge (animated)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: widget.color.withValues(
                                alpha: _hovered ? 0.20 : 0.10,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: widget.color.withValues(
                                  alpha: _hovered ? 0.40 : 0.20,
                                ),
                              ),
                            ),
                            child: Text(
                              '${widget.count} Innovations',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: widget.color,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Name & desc
                      Text(
                        widget.name,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _hovered ? widget.color : Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.desc,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.white.withValues(
                            alpha: _hovered ? 0.65 : 0.40,
                          ),
                          height: 1.45,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 14),

                      // Bottom "Explore" row — revealed on hover
                      AnimatedOpacity(
                        opacity: _hovered ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: AnimatedSlide(
                          offset:
                              _hovered ? Offset.zero : const Offset(0, 0.3),
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: Row(
                            children: [
                              Text(
                                'Explore ${widget.name}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: widget.color,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: widget.color,
                                size: 13,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
              .animate(delay: Duration(milliseconds: 100 * widget.index))
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.3, end: 0),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Mini grid painter for hero banner
// ═══════════════════════════════════════════════════════════
class _MiniGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5;
    const spacing = 36.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_MiniGridPainter old) => false;
}
