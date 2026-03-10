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
    },
    {
      'name': 'Healthcare',
      'icon': Icons.medical_services_rounded,
      'color': AppColors.crimson,
      'desc': 'Medical innovations improving Filipino lives',
    },
    {
      'name': 'Energy',
      'icon': Icons.bolt_rounded,
      'color': AppColors.golden,
      'desc': 'Clean & renewable energy technologies',
    },
    {
      'name': 'Construction',
      'icon': Icons.foundation_rounded,
      'color': AppColors.navy,
      'desc': 'Smart infrastructure & building solutions',
    },
    {
      'name': 'Product Design',
      'icon': Icons.design_services_rounded,
      'color': AppColors.sky,
      'desc': 'Creative product development & prototyping',
    },
    {
      'name': 'Information Technology',
      'icon': Icons.computer_rounded,
      'color': Color(0xFF1B4B8A),
      'desc': 'Software, AI, and digital transformation',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.offWhite,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          // Section header
          Column(
            children: [
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.teal,
                  borderRadius: BorderRadius.circular(2),
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
              const SizedBox(height: 12),
              const Text(
                'Six sectors driving the future of the Philippines',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
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

          const SizedBox(height: 56),

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
                  name: cat['name'],
                  icon: cat['icon'],
                  color: cat['color'],
                  desc: cat['desc'],
                  index: index,
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String name;
  final IconData icon;
  final Color color;
  final String desc;
  final int index;

  const _CategoryCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.desc,
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
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translate(0.0, _hovered ? -6.0 : 0.0),
        decoration: BoxDecoration(
          color: _hovered ? widget.color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered ? widget.color : AppColors.lightGray,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? widget.color.withOpacity(0.3)
                  : Colors.black.withOpacity(0.06),
              blurRadius: _hovered ? 24 : 8,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _hovered
                          ? Colors.white.withOpacity(0.2)
                          : widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      color: _hovered ? Colors.white : widget.color,
                      size: 28,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: _hovered ? Colors.white70 : AppColors.lightGray,
                    size: 20,
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
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _hovered ? Colors.white : AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.desc,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: _hovered ? Colors.white70 : Colors.black45,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: 100 * widget.index))
          .fadeIn(duration: 600.ms)
          .slideY(begin: 0.3, end: 0),
    );
  }
}