import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class CategoryFilterBar extends StatelessWidget {
  final String selected;
  final void Function(String) onSelect;

  const CategoryFilterBar({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  static const List<Map<String, dynamic>> _cats = [
    {'name': 'All', 'icon': Icons.apps_rounded},
    {'name': 'Agriculture', 'icon': Icons.grass_rounded},
    {'name': 'Healthcare', 'icon': Icons.medical_services_rounded},
    {'name': 'Energy', 'icon': Icons.bolt_rounded},
    {'name': 'Construction', 'icon': Icons.foundation_rounded},
    {'name': 'Product Design', 'icon': Icons.design_services_rounded},
    {
      'name': 'Information Technology',
      'icon': Icons.computer_rounded
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _cats[index];
          final isSelected = selected == cat['name'];
          final color = cat['name'] == 'All'
              ? AppColors.navy
              : AppColors.categoryColors[cat['name']] ??
                  AppColors.navy;

          return GestureDetector(
            onTap: () => onSelect(cat['name']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected ? color : AppColors.lightGray,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    size: 15,
                    color: isSelected ? Colors.white : Colors.black45,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat['name'],
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color:
                          isSelected ? Colors.white : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}