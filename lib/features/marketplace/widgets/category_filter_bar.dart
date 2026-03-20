import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// CategoryFilterBar — cinematic dark theme v2
// Horizontal scrollable pill chips with:
//  - Icon + label + count badge per chip
//  - Category-colored active state (filled bg + border)
//  - Dark glass inactive state
//  - Animated color transitions when switching
//  - Scroll-edge fade overlays
//  - Staggered entrance animations
// ═══════════════════════════════════════════════════════════
class CategoryFilterBar extends StatefulWidget {
  final String selected;
  final void Function(String) onSelect;

  const CategoryFilterBar({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  static const List<Map<String, dynamic>> cats = [
    {'name': 'All', 'icon': Icons.apps_rounded, 'count': null},
    {'name': 'Agri-Aqua and Forestry', 'icon': Icons.grass_rounded, 'count': null},
    {'name': 'Food Processing and Nutrition', 'icon': Icons.restaurant_menu_rounded, 'count': null},
    {'name': 'Health and Medical Sciences', 'icon': Icons.medical_services_rounded, 'count': null},
    {'name': 'Energy, Utilities, and Environment', 'icon': Icons.bolt_rounded, 'count': null},
    {'name': 'Advanced Manufacturing and Engineering', 'icon': Icons.foundation_rounded, 'count': null},
    {'name': 'Creative Industries and Product Design', 'icon': Icons.design_services_rounded, 'count': null},
    {'name': 'Information and Communications Technology (ICT)', 'icon': Icons.computer_rounded, 'count': null},
  ];

  @override
  State<CategoryFilterBar> createState() => _CategoryFilterBarState();
}

class _CategoryFilterBarState extends State<CategoryFilterBar> {
  final ScrollController _scrollCtrl = ScrollController();
  final List<GlobalKey> _chipKeys = List.generate(
    CategoryFilterBar.cats.length,
    (_) => GlobalKey(),
  );
  bool _showLeftFade = false;
  bool _showRightFade = true;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients &&
          _scrollCtrl.position.hasContentDimensions) {
        setState(() {
          _showRightFade = _scrollCtrl.position.maxScrollExtent > 0;
        });
      }
    });
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final offset = _scrollCtrl.offset;
    final max = _scrollCtrl.position.maxScrollExtent;
    setState(() {
      _showLeftFade = offset > 8;
      _showRightFade = offset < max - 8;
    });
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Stack(
        children: [
          // ── Scrollable chips ─────────────────────────────
          ListView.separated(
            controller: _scrollCtrl,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            itemCount: CategoryFilterBar.cats.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = CategoryFilterBar.cats[index];
              final isSelected = widget.selected == cat['name'];
              return _CategoryChip(
                chipKey: _chipKeys[index],
                name: cat['name'] as String,
                icon: cat['icon'] as IconData,
                count: cat['count'] as int?,
                isSelected: isSelected,
                onTap: () {
                  widget.onSelect(cat['name'] as String);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final ctx = _chipKeys[index].currentContext;
                    if (ctx != null) {
                      Scrollable.ensureVisible(
                        ctx,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        alignment: 0.5,
                      );
                    }
                  });
                },
                index: index,
              );
            },
          ),

          // ── Left fade overlay ────────────────────────────
          if (_showLeftFade)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 40,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.deepVoid,
                        AppColors.deepVoid.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ── Right fade overlay ───────────────────────────
          if (_showRightFade)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 40,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.deepVoid.withValues(alpha: 0),
                        AppColors.deepVoid,
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Individual category chip — dark glass style with count badge
// ═══════════════════════════════════════════════════════════
class _CategoryChip extends StatefulWidget {
  final Key? chipKey;
  final String name;
  final IconData icon;
  final int? count;
  final bool isSelected;
  final VoidCallback onTap;
  final int index;

  const _CategoryChip({
    this.chipKey,
    required this.name,
    required this.icon,
    this.count,
    required this.isSelected,
    required this.onTap,
    required this.index,
  });

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;

  late AnimationController _colorCtrl;
  late Animation<double> _colorAnim;

  @override
  void initState() {
    super.initState();
    _colorCtrl = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
      value: widget.isSelected ? 1.0 : 0.0,
    );
    _colorAnim =
        CurvedAnimation(parent: _colorCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(_CategoryChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _colorCtrl.forward();
      } else {
        _colorCtrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _colorCtrl.dispose();
    super.dispose();
  }

  Color get _categoryColor {
    if (widget.name == 'All') return AppColors.golden;
    return AppColors.categoryColors[widget.name] ?? AppColors.teal;
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor;

    double scale = 1.0;
    if (widget.isSelected) scale = 1.04;
    if (_hovered && !widget.isSelected) scale = 1.02;
    if (_pressed) scale = 0.95;
    final lift = _hovered && !widget.isSelected ? -2.0 : 0.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        key: widget.chipKey,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: Transform.translate(
          offset: Offset(0, lift),
          child: AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: AnimatedBuilder(
              animation: _colorAnim,
              builder: (context, child) {
                final t = _colorAnim.value;
                final bgColor = Color.lerp(
                  const Color(0xFF0B1929),
                  catColor.withValues(alpha: 0.14),
                  t,
                )!;
                final borderColor = Color.lerp(
                  _hovered
                      ? Colors.white.withValues(alpha: 0.20)
                      : Colors.white.withValues(alpha: 0.10),
                  catColor.withValues(alpha: 0.70),
                  t,
                )!;
                final contentColor = Color.lerp(
                  _hovered
                      ? Colors.white.withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.55),
                  catColor,
                  t,
                )!;
                final boxShadows = t > 0
                    ? [
                        BoxShadow(
                          color: catColor.withValues(alpha: 0.25 * t),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                          spreadRadius: 0,
                        ),
                      ]
                    : (_hovered
                        ? [
                            BoxShadow(
                              color: catColor.withValues(alpha: 0.10),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : <BoxShadow>[]);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: boxShadows,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(widget.icon, size: 15, color: contentColor),
                            const SizedBox(width: 7),
                            Text(
                              widget.name,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight:
                                    widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: contentColor,
                              ),
                            ),
                            if (widget.count != null) ...[
                              const SizedBox(width: 7),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: widget.isSelected
                                      ? catColor.withValues(alpha: 0.20)
                                      : Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${widget.count}',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: widget.isSelected
                                        ? catColor
                                        : Colors.white.withValues(alpha: 0.70),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: -8,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            height: 2,
                            margin: EdgeInsets.symmetric(
                              horizontal: widget.isSelected ? 8 : 24,
                            ),
                            decoration: BoxDecoration(
                              gradient: widget.isSelected
                                  ? LinearGradient(
                                      colors: [
                                        catColor.withValues(alpha: 0.95),
                                        AppColors.golden.withValues(alpha: 0.85),
                                      ],
                                    )
                                  : null,
                              color: widget.isSelected
                                  ? null
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 35))
        .fadeIn(duration: 340.ms)
        .slideX(begin: -0.08, end: 0, curve: Curves.easeOutCubic);
  }
}
