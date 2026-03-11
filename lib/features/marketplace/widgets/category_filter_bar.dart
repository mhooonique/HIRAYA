import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

class CategoryFilterBar extends StatefulWidget {
  final String selected;
  final void Function(String) onSelect;

  const CategoryFilterBar({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<CategoryFilterBar> createState() =>
      _CategoryFilterBarState();
}

class _CategoryFilterBarState extends State<CategoryFilterBar>
    with TickerProviderStateMixin {
  final ScrollController _scrollCtrl = ScrollController();
  final List<GlobalKey> _chipKeys = [];

  // Each chip gets its own press-tracking state
  final List<bool> _pressed = [];

  static const List<Map<String, dynamic>> _cats = [
    {
      'name': 'All',
      'icon': Icons.apps_rounded,
      'emoji': '🌐',
    },
    {
      'name': 'Agriculture',
      'icon': Icons.grass_rounded,
      'emoji': '🌾',
    },
    {
      'name': 'Healthcare',
      'icon': Icons.medical_services_rounded,
      'emoji': '🏥',
    },
    {
      'name': 'Energy',
      'icon': Icons.bolt_rounded,
      'emoji': '⚡',
    },
    {
      'name': 'Construction',
      'icon': Icons.foundation_rounded,
      'emoji': '🏗️',
    },
    {
      'name': 'Product Design',
      'icon': Icons.design_services_rounded,
      'emoji': '🎨',
    },
    {
      'name': 'Information Technology',
      'icon': Icons.computer_rounded,
      'emoji': '💻',
    },
  ];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _cats.length; i++) {
      _chipKeys.add(GlobalKey());
      _pressed.add(false);
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Color _colorFor(String name) {
    if (name == 'All') return AppColors.navy;
    return AppColors.categoryColors[name] ?? AppColors.navy;
  }

  void _handleSelect(int index, String name) {
    HapticFeedback.lightImpact();
    widget.onSelect(name);

    // Auto-scroll selected chip into view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _chipKeys[index];
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic,
          alignment: 0.5,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Chips row ────────────────────────────────────
        SizedBox(
          height: 52,
          child: ListView.separated(
            controller: _scrollCtrl,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            itemCount: _cats.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = _cats[index];
              final name = cat['name'] as String;
              final icon = cat['icon'] as IconData;
              final isSelected = widget.selected == name;
              final color = _colorFor(name);

              return _CategoryChip(
                key: _chipKeys[index],
                name: name,
                icon: icon,
                color: color,
                isSelected: isSelected,
                index: index,
                onTap: () => _handleSelect(index, name),
              );
            },
          ),
        ),

        // ── Active category detail strip ─────────────────
        if (widget.selected != 'All') ...[
          const SizedBox(height: 10),
          _ActiveCategoryBanner(
            name: widget.selected,
            color: _colorFor(widget.selected),
            icon: _cats.firstWhere(
                    (c) => c['name'] == widget.selected,
                    orElse: () => _cats[0])['icon'] as IconData,
            emoji: _cats.firstWhere(
                    (c) => c['name'] == widget.selected,
                    orElse: () => _cats[0])['emoji'] as String,
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Individual Category Chip
// ═══════════════════════════════════════════════════════════
class _CategoryChip extends StatefulWidget {
  final String name;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final int index;
  final VoidCallback onTap;

  const _CategoryChip({
    super.key,
    required this.name,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.index,
    required this.onTap,
  });

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleCtrl;
  late Animation<double> _rippleAnim;
  bool _pressed = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _rippleCtrl = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );
    _rippleAnim = CurvedAnimation(
        parent: _rippleCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _rippleCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _rippleCtrl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final color = widget.color;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _handleTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.90 : (_hovered && !isSelected ? 1.04 : 1.0),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutBack,
          child: AnimatedBuilder(
            animation: _rippleAnim,
            builder: (context, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 18 : 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color,
                            Color.lerp(color, Colors.black, 0.18)!,
                          ],
                        )
                      : null,
                  color: isSelected
                      ? null
                      : (_hovered
                          ? color.withValues(alpha: 0.07)
                          : Colors.white),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : (_hovered
                            ? color.withValues(alpha: 0.40)
                            : AppColors.lightGray),
                    width: isSelected ? 0 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.38),
                            blurRadius: 16,
                            offset: const Offset(0, 5),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: color.withValues(alpha: 0.15),
                            blurRadius: 32,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated icon container
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: isSelected
                          ? const EdgeInsets.all(4)
                          : EdgeInsets.zero,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.20)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        size: isSelected ? 14 : 15,
                        color: isSelected
                            ? Colors.white
                            : (_hovered ? color : Colors.black45),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: SizedBox(width: isSelected ? 7 : 5),
                    ),
                    // Label
                    Text(
                      widget.name,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (_hovered ? color : Colors.black54),
                        letterSpacing: isSelected ? 0.2 : 0,
                      ),
                    ),
                    // Selected checkmark
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutBack,
                      child: isSelected
                          ? Padding(
                              padding:
                                  const EdgeInsets.only(left: 5),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withValues(alpha: 0.28),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 9,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
            duration: 400.ms,
            delay: Duration(milliseconds: 60 * widget.index))
        .slideX(
            begin: 0.15,
            end: 0,
            duration: 400.ms,
            delay: Duration(milliseconds: 60 * widget.index),
            curve: Curves.easeOutCubic);
  }
}

// ═══════════════════════════════════════════════════════════
// Active Category Banner — slides in below filter row
// ═══════════════════════════════════════════════════════════
class _ActiveCategoryBanner extends StatelessWidget {
  final String name;
  final Color color;
  final IconData icon;
  final String emoji;

  const _ActiveCategoryBanner({
    required this.name,
    required this.color,
    required this.icon,
    required this.emoji,
  });

  String _descriptionFor(String name) {
    switch (name) {
      case 'Agriculture':
        return 'Innovations in farming, crop tech & food systems';
      case 'Healthcare':
        return 'Medical solutions improving Filipino health outcomes';
      case 'Energy':
        return 'Sustainable power & clean energy breakthroughs';
      case 'Construction':
        return 'Smart building materials & infrastructure tech';
      case 'Product Design':
        return 'Creative products for everyday Filipino life';
      case 'Information Technology':
        return 'Software, apps & digital solutions for the future';
      default:
        return 'Explore all innovations';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.18),
              end: Offset.zero,
            ).animate(CurvedAnimation(
                parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        child: Container(
          key: ValueKey(name),
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.09),
                color.withValues(alpha: 0.04),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.18),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Color dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.50),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Icon
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 8),
              // Text
              Expanded(
                child: Text(
                  _descriptionFor(name),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: color.withValues(alpha: 0.80),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Emoji badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
