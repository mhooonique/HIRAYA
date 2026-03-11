import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  static const List<Map<String, dynamic>> _categories = [
    {
      'name': 'Agriculture',
      'icon': Icons.grass_rounded,
      'color': AppColors.teal,
      'desc': 'Sustainable farming & agri-tech solutions',
      'count': '94',
    },
    {
      'name': 'Healthcare',
      'icon': Icons.medical_services_rounded,
      'color': AppColors.crimson,
      'desc': 'Medical innovations improving Filipino lives',
      'count': '87',
    },
    {
      'name': 'Energy',
      'icon': Icons.bolt_rounded,
      'color': AppColors.golden,
      'desc': 'Clean & renewable energy technologies',
      'count': '62',
    },
    {
      'name': 'Construction',
      'icon': Icons.foundation_rounded,
      'color': AppColors.navy,
      'desc': 'Smart infrastructure & building solutions',
      'count': '51',
    },
    {
      'name': 'Product Design',
      'icon': Icons.design_services_rounded,
      'color': AppColors.sky,
      'desc': 'Creative product development & prototyping',
      'count': '78',
    },
    {
      'name': 'Information Technology',
      'icon': Icons.computer_rounded,
      'color': Color(0xFF1B4B8A),
      'desc': 'Software, AI, and digital transformation',
      'count': '113',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.offWhite,
      padding: const EdgeInsets.symmetric(vertical: 88, horizontal: 24),
      child: Column(
        children: [
          // Section header
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.teal, AppColors.sky],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'EXPLORE SECTORS',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Innovation Categories',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              // Gradient underline
              Container(
                width: 56,
                height: 3,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.teal, AppColors.sky],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Six sectors driving the future of the Philippines',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  color: Colors.black45,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .slideY(begin: 0.2, end: 0),

          const SizedBox(height: 52),

          // Grid
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
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.6,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return _CategoryCard(
                  name: cat['name'] as String,
                  icon: cat['icon'] as IconData,
                  color: cat['color'] as Color,
                  desc: cat['desc'] as String,
                  count: cat['count'] as String,
                  index: index,
                );
              },
            );
          }),

          const SizedBox(height: 44),

          // Explore All button
          _ExploreAllButton(),
        ],
      ),
    );
  }
}

class _ExploreAllButton extends StatefulWidget {
  @override
  State<_ExploreAllButton> createState() => _ExploreAllButtonState();
}

class _ExploreAllButtonState extends State<_ExploreAllButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 110),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.navy : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _hovered
                    ? AppColors.navy
                    : AppColors.navy.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.20),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      )
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Explore All Categories',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _hovered ? Colors.white : AppColors.navy,
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  child: _hovered
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 15),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: 400.ms).fadeIn(duration: 500.ms);
  }
}

class _CategoryCard extends StatefulWidget {
  final String name;
  final IconData icon;
  final Color color;
  final String desc;
  final String count;
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

class _CategoryCardState extends State<_CategoryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 270),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translate(0.0, _hovered ? -6.0 : 0.0),
        decoration: BoxDecoration(
          color: _hovered ? widget.color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered
                ? widget.color
                : AppColors.lightGray,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.30)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: _hovered ? 26 : 8,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Icon with scale animation
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 270),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _hovered
                          ? Colors.white.withValues(alpha: 0.22)
                          : widget.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      widget.icon,
                      color: _hovered ? Colors.white : widget.color,
                      size: _hovered ? 30 : 26,
                    ),
                  ),
                  const Spacer(),
                  // Count badge
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: _hovered
                          ? Colors.white.withValues(alpha: 0.20)
                          : widget.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.count} items',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _hovered ? Colors.white : widget.color,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _hovered ? Colors.white : AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.desc,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12.5,
                            color: _hovered
                                ? Colors.white.withValues(alpha: 0.70)
                                : Colors.black45,
                            height: 1.4,
                          ),
                        ),
                      ),
                      // Arrow slides right on hover
                      AnimatedSlide(
                        offset: _hovered
                            ? const Offset(0.2, 0)
                            : Offset.zero,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: _hovered
                              ? Colors.white70
                              : AppColors.lightGray,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: 90 * widget.index))
          .fadeIn(duration: 500.ms)
          .slideY(begin: 0.22, end: 0, curve: Curves.easeOutCubic),
    );
  }
}