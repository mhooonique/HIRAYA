import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LandingNavbar — Enhanced with scroll progress bar, animated underlines,
// custom categories overlay, pulsing CTA, logo shimmer, mobile slide panel.
// ─────────────────────────────────────────────────────────────────────────────

class LandingNavbar extends StatefulWidget {
  final double scrollOffset;
  final VoidCallback? onAboutTap;
  final VoidCallback? onCategoriesTap;

  const LandingNavbar({
    super.key,
    required this.scrollOffset,
    this.onAboutTap,
    this.onCategoriesTap,
  });

  @override
  State<LandingNavbar> createState() => _LandingNavbarState();
}

class _LandingNavbarState extends State<LandingNavbar>
    with TickerProviderStateMixin {
  // Scroll-progress bar
  late AnimationController _progressController;

  // Logo shimmer (one-shot)
  late AnimationController _logoShimmerController;

  // Mobile drawer overlay
  OverlayEntry? _mobileDrawerOverlay;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _logoShimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward(); // one-shot on load
  }

  @override
  void didUpdateWidget(LandingNavbar old) {
    super.didUpdateWidget(old);
    // Clamp progress 0.0–1.0 (assume ~3000px page height)
    final progress = (widget.scrollOffset / 3000).clamp(0.0, 1.0);
    _progressController.animateTo(
      progress,
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    _logoShimmerController.dispose();
    _mobileDrawerOverlay?.remove();
    super.dispose();
  }

  void _openMobileDrawer(BuildContext context) {
    _mobileDrawerOverlay?.remove();
    _mobileDrawerOverlay = null;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _MobileDrawerOverlay(
        onClose: () {
          entry.remove();
          _mobileDrawerOverlay = null;
        },
        onAboutTap: widget.onAboutTap,
      ),
    );
    overlay.insert(entry);
    _mobileDrawerOverlay = entry;
  }

  @override
  Widget build(BuildContext context) {
    final isScrolled = widget.scrollOffset > 50;
    final isMobile = MediaQuery.of(context).size.width <= 768;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Golden scroll-progress bar ─────────────────────────
        AnimatedBuilder(
          animation: _progressController,
          builder: (_, __) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // Track
                    Container(
                      height: 2,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                    // Progress fill with shimmer sweep
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 80),
                      height: 2,
                      width: constraints.maxWidth * _progressController.value,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.golden,
                            AppColors.warmEmber,
                            AppColors.golden,
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.golden.withValues(alpha: 0.60),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),

        // ── Main navbar ────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isScrolled
                ? AppColors.deepVoid.withValues(alpha: 0.97)
                : Colors.transparent,
            border: isScrolled
                ? Border(
                    bottom: BorderSide(
                      color: AppColors.golden.withValues(alpha: 0.12),
                      width: 1,
                    ),
                  )
                : null,
            boxShadow: isScrolled
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                    ),
                    BoxShadow(
                      color: AppColors.golden.withValues(alpha: 0.04),
                      blurRadius: 40,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: SafeArea(
            child: SizedBox(
              height: 70,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 32,
                ),
                child: Row(
                  children: [
                    // ── Logo + wordmark ────────────────────────
                    _AnimatedLogo(controller: _logoShimmerController,
                        isMobile: isMobile),
                    const Spacer(),

                    // ── Desktop nav ────────────────────────────
                    if (!isMobile) ...[
                      _NavLink(
                        label: 'Marketplace',
                        onTap: () => context.go('/marketplace'),
                        showNotificationDot: true,
                      ),
                      _NavLink(
                        label: 'About',
                        onTap: widget.onAboutTap ?? () => context.go('/'),
                      ),
                      _CategoriesDropdown(
                          onCategoriesTap: widget.onCategoriesTap),
                      const SizedBox(width: 20),
                      _SignInButton(onTap: () => context.go('/login')),
                      const SizedBox(width: 10),
                      _PulsingCTAButton(onTap: () => context.go('/signup')),
                    ] else
                      // ── Mobile hamburger ───────────────────
                      IconButton(
                        icon: Icon(
                          Icons.menu_rounded,
                          color: Colors.white.withValues(alpha: 0.90),
                          size: 28,
                        ),
                        onPressed: () => _openMobileDrawer(context),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logo with one-shot shimmer animation
// ─────────────────────────────────────────────────────────────────────────────

class _AnimatedLogo extends StatelessWidget {
  final AnimationController controller;
  final bool isMobile;
  const _AnimatedLogo({required this.controller, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/logo/final-logo.png',
          height: isMobile ? 32 : 38,
        ),
        const SizedBox(width: 10),
        AnimatedBuilder(
          animation: controller,
          builder: (_, __) {
            // Shimmer sweep: golden → white-gold → golden moving left→right
            final t = controller.value;
            return ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment(-1.5 + t * 3, 0),
                end: Alignment(-0.5 + t * 3, 0),
                colors: const [
                  AppColors.golden,
                  AppColors.goldSheen,
                  Color(0xFFFFEF80),
                  AppColors.golden,
                ],
                stops: const [0.0, 0.35, 0.50, 1.0],
              ).createShader(bounds),
              child: Text(
                'HIRAYA',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav link with animated underline (slides in from left on hover)
// ─────────────────────────────────────────────────────────────────────────────

class _NavLink extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool showNotificationDot;
  const _NavLink({
    required this.label,
    this.onTap,
    this.showNotificationDot = false,
  });

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _underlineCtrl;
  late Animation<double> _underlineAnim;

  @override
  void initState() {
    super.initState();
    _underlineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _underlineAnim = CurvedAnimation(
      parent: _underlineCtrl,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _underlineCtrl.dispose();
    super.dispose();
  }

  void _onEnter(_) {
    setState(() => _hovered = true);
    _underlineCtrl.forward();
  }

  void _onExit(_) {
    setState(() => _hovered = false);
    _underlineCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: _onEnter,
      onExit: _onExit,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Label + optional notification dot
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(
                      color: _hovered
                          ? AppColors.golden
                          : Colors.white.withValues(alpha: 0.80),
                      fontFamily: 'Poppins',
                      fontWeight:
                          _hovered ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                    child: Text(widget.label),
                  ),
                  if (widget.showNotificationDot)
                    Positioned(
                      top: -3,
                      right: -8,
                      child: _PulsingDot(),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              // Animated underline sliding from left
              AnimatedBuilder(
                animation: _underlineAnim,
                builder: (_, __) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 2,
                      width: _underlineAnim.value * 50, // grows to full text width approx
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.golden, AppColors.warmEmber],
                        ),
                        borderRadius: BorderRadius.circular(1),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.golden.withValues(alpha: 0.50),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing red notification dot for Marketplace link
// ─────────────────────────────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: false);

    _scale = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
    _opacity = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 10,
      height: 10,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ripple ring
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Transform.scale(
              scale: _scale.value,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.crimson.withValues(alpha: _opacity.value),
                ),
              ),
            ),
          ),
          // Solid core dot
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.crimson,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign In button — golden border on hover
// ─────────────────────────────────────────────────────────────────────────────

class _SignInButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SignInButton({required this.onTap});

  @override
  State<_SignInButton> createState() => _SignInButtonState();
}

class _SignInButtonState extends State<_SignInButton> {
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
          curve: Curves.easeOutCubic,
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                  ? AppColors.golden
                  : Colors.white.withValues(alpha: 0.30),
              width: 1.5,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.golden.withValues(alpha: 0.18),
                      blurRadius: 12,
                    )
                  ]
                : [],
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: _hovered ? AppColors.golden : Colors.white,
            ),
            child: const Text('Sign In'),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Get Started — pulsing glow CTA button
// ─────────────────────────────────────────────────────────────────────────────

class _PulsingCTAButton extends StatefulWidget {
  final VoidCallback onTap;
  const _PulsingCTAButton({required this.onTap});

  @override
  State<_PulsingCTAButton> createState() => _PulsingCTAButtonState();
}

class _PulsingCTAButtonState extends State<_PulsingCTAButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _glowAnim,
          builder: (_, child) {
            final glowStrength = 0.25 + _glowAnim.value * 0.35;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.golden, AppColors.warmEmber],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.golden
                        .withValues(alpha: glowStrength),
                    blurRadius: _hovered ? 24 : 12 + _glowAnim.value * 8,
                    spreadRadius: _hovered ? 2 : 0,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: const Text(
            'Get Started',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.navy,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Categories Overlay Dropdown
// ─────────────────────────────────────────────────────────────────────────────

class _CategoriesDropdown extends StatefulWidget {
  final VoidCallback? onCategoriesTap;
  const _CategoriesDropdown({this.onCategoriesTap});

  @override
  State<_CategoriesDropdown> createState() => _CategoriesDropdownState();
}

class _CategoriesDropdownState extends State<_CategoriesDropdown>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  OverlayEntry? _overlayEntry;
  late AnimationController _dropdownCtrl;
  late Animation<double> _dropdownAnim;

  static const _categories = [
    {
      'label': 'Agriculture',
      'icon': Icons.grass_rounded,
      'count': '87',
      'color': AppColors.teal,
    },
    {
      'label': 'Healthcare',
      'icon': Icons.medical_services_rounded,
      'count': '64',
      'color': AppColors.crimson,
    },
    {
      'label': 'Energy',
      'icon': Icons.bolt_rounded,
      'count': '52',
      'color': AppColors.golden,
    },
    {
      'label': 'Construction',
      'icon': Icons.foundation_rounded,
      'count': '41',
      'color': AppColors.navy,
    },
    {
      'label': 'Product Design',
      'icon': Icons.design_services_rounded,
      'count': '78',
      'color': AppColors.sky,
    },
    {
      'label': 'Information Technology',
      'icon': Icons.computer_rounded,
      'count': '93',
      'color': Color(0xFF1B4B8A),
    },
  ];

  @override
  void initState() {
    super.initState();
    _dropdownCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _dropdownAnim = CurvedAnimation(
      parent: _dropdownCtrl,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _dropdownCtrl.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _openDropdown(BuildContext context) {
    if (_overlayEntry != null) {
      _closeDropdown();
      return;
    }
    widget.onCategoriesTap?.call();

    final RenderBox button = context.findRenderObject()! as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final buttonOffset =
        button.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonSize = button.size;

    _overlayEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // Dismiss tap area
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          // Dropdown panel
          Positioned(
            top: buttonOffset.dy + buttonSize.height + 8,
            left: buttonOffset.dx - 80,
            child: _CategoryDropdownPanel(
              animation: _dropdownAnim,
              categories: _categories,
              onSelect: (label) {
                _closeDropdown();
                if (context.mounted) {
                  context.go('/marketplace?category=$label');
                }
              },
              onViewAll: () {
                _closeDropdown();
                if (context.mounted) {
                  context.go('/marketplace');
                }
              },
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _dropdownCtrl.forward(from: 0);
    setState(() {});
  }

  void _closeDropdown() {
    _dropdownCtrl.reverse().then((_) {
      _removeOverlay();
      if (mounted) setState(() {});
    });
  }

  bool get _isOpen => _overlayEntry != null;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => _openDropdown(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(
                      color: (_hovered || _isOpen)
                          ? AppColors.golden
                          : Colors.white.withValues(alpha: 0.80),
                      fontFamily: 'Poppins',
                      fontWeight: (_hovered || _isOpen)
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontSize: 14,
                    ),
                    child: const Text('Categories'),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _isOpen ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: (_hovered || _isOpen)
                          ? AppColors.golden
                          : Colors.white.withValues(alpha: 0.60),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 2,
                width: (_hovered || _isOpen) ? 60 : 0,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.golden, AppColors.warmEmber],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Categories dropdown panel — 2x3 grid, glass morphism dark bg
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryDropdownPanel extends StatelessWidget {
  final Animation<double> animation;
  final List<Map<String, dynamic>> categories;
  final ValueChanged<String> onSelect;
  final VoidCallback onViewAll;

  const _CategoryDropdownPanel({
    required this.animation,
    required this.categories,
    required this.onSelect,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, -12 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 380,
          decoration: BoxDecoration(
            color: const Color(0xFF081424).withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.golden.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.golden.withValues(alpha: 0.06),
                blurRadius: 40,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      Icon(Icons.category_rounded,
                          color: AppColors.golden.withValues(alpha: 0.70),
                          size: 14),
                      const SizedBox(width: 8),
                      Text(
                        'BROWSE CATEGORIES',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color:
                              AppColors.golden.withValues(alpha: 0.70),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Thin divider
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                const SizedBox(height: 8),

                // 2x3 Grid
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.6,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (_, i) {
                      final cat = categories[i];
                      return _CategoryGridItem(
                        label: cat['label'] as String,
                        icon: cat['icon'] as IconData,
                        count: cat['count'] as String,
                        color: cat['color'] as Color,
                        onTap: () => onSelect(cat['label'] as String),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),
                // Thin divider
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: Colors.white.withValues(alpha: 0.06),
                ),

                // "View All" row
                _ViewAllRow(onTap: onViewAll),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category grid item — hover glow in category color
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryGridItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final String count;
  final Color color;
  final VoidCallback onTap;

  const _CategoryGridItem({
    required this.label,
    required this.icon,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  State<_CategoryGridItem> createState() => _CategoryGridItemState();
}

class _CategoryGridItemState extends State<_CategoryGridItem> {
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
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.06),
              width: 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.20),
                      blurRadius: 12,
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: widget.color.withValues(
                      alpha: _hovered ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  widget.icon,
                  size: 14,
                  color: widget.color
                      .withValues(alpha: _hovered ? 1.0 : 0.60),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _hovered
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.75),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${widget.count} innovations',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        color: _hovered
                            ? widget.color.withValues(alpha: 0.80)
                            : Colors.white.withValues(alpha: 0.35),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// View All row at bottom of dropdown
// ─────────────────────────────────────────────────────────────────────────────

class _ViewAllRow extends StatefulWidget {
  final VoidCallback onTap;
  const _ViewAllRow({required this.onTap});

  @override
  State<_ViewAllRow> createState() => _ViewAllRowState();
}

class _ViewAllRowState extends State<_ViewAllRow> {
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
          duration: const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: _hovered
              ? AppColors.golden.withValues(alpha: 0.06)
              : Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _hovered
                      ? AppColors.golden
                      : Colors.white.withValues(alpha: 0.50),
                ),
                child: const Text('View All Categories'),
              ),
              const SizedBox(width: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: _hovered
                      ? AppColors.golden
                      : Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile Drawer Overlay — slides in from right
// ─────────────────────────────────────────────────────────────────────────────

class _MobileDrawerOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback? onAboutTap;

  const _MobileDrawerOverlay({
    required this.onClose,
    this.onAboutTap,
  });

  @override
  State<_MobileDrawerOverlay> createState() => _MobileDrawerOverlayState();
}

class _MobileDrawerOverlayState extends State<_MobileDrawerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;
  bool _categoriesExpanded = false;

  static const _categories = [
    {'label': 'Agriculture', 'icon': Icons.grass_rounded},
    {'label': 'Healthcare', 'icon': Icons.medical_services_rounded},
    {'label': 'Energy', 'icon': Icons.bolt_rounded},
    {'label': 'Construction', 'icon': Icons.foundation_rounded},
    {'label': 'Product Design', 'icon': Icons.design_services_rounded},
    {'label': 'Information Technology', 'icon': Icons.computer_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slideAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl, curve: const Interval(0.0, 0.5)),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _close() {
    _ctrl.reverse().then((_) => widget.onClose());
  }

  void _navigateTo(BuildContext context, String path) {
    _close();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (context.mounted) context.go(path);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = (screenWidth * 0.82).clamp(0.0, 340.0);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        return Stack(
          children: [
            // Scrim
            Positioned.fill(
              child: GestureDetector(
                onTap: _close,
                child: Container(
                  color: Colors.black
                      .withValues(alpha: 0.55 * _fadeAnim.value),
                ),
              ),
            ),
            // Slide panel from right
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: panelWidth,
              child: Transform.translate(
                offset: Offset(panelWidth * _slideAnim.value, 0),
                child: child,
              ),
            ),
          ],
        );
      },
      child: _buildPanel(context, panelWidth),
    );
  }

  Widget _buildPanel(BuildContext context, double panelWidth) {
    return Container(
      width: panelWidth,
      decoration: BoxDecoration(
        color: AppColors.richNavy,
        border: Border(
          left: BorderSide(
            color: AppColors.golden.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.50),
            blurRadius: 30,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Branded header ───────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 20, 16, 16),
              child: Row(
                children: [
                  Image.asset('assets/images/logo/final-logo.png',
                      height: 32),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        const LinearGradient(
                      colors: [
                        AppColors.golden,
                        AppColors.warmEmber
                      ],
                    ).createShader(bounds),
                    child: const Text(
                      'HIRAYA',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _close,
                    child: Icon(
                      Icons.close_rounded,
                      color:
                          Colors.white.withValues(alpha: 0.50),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              height: 1,
              margin:
                  const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.golden.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Nav items ────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MobileNavItem(
                      icon: Icons.storefront_rounded,
                      label: 'Marketplace',
                      onTap: () =>
                          _navigateTo(context, '/marketplace'),
                    ),
                    _MobileNavItem(
                      icon: Icons.info_outline_rounded,
                      label: 'About',
                      onTap: () {
                        _close();
                        Future.delayed(
                            const Duration(milliseconds: 200),
                            () => widget.onAboutTap?.call());
                      },
                    ),

                    // Categories accordion
                    _MobileCategoryAccordion(
                      expanded: _categoriesExpanded,
                      onToggle: () => setState(
                          () => _categoriesExpanded =
                              !_categoriesExpanded),
                      categories: _categories,
                      onSelectCategory: (label) =>
                          _navigateTo(context,
                              '/marketplace?category=$label'),
                    ),

                    const SizedBox(height: 16),
                    Divider(
                        color:
                            Colors.white.withValues(alpha: 0.08)),
                    const SizedBox(height: 12),

                    // Tagline
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'Where Filipino Innovation Soars',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.white
                              .withValues(alpha: 0.30),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Auth buttons ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () =>
                          _navigateTo(context, '/login'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.golden,
                        side: BorderSide(
                            color: AppColors.golden
                                .withValues(alpha: 0.50)),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(10)),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.golden,
                            AppColors.warmEmber
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                      child: ElevatedButton(
                        onPressed: () =>
                            _navigateTo(context, '/signup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile nav item
// ─────────────────────────────────────────────────────────────────────────────

class _MobileNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MobileNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_MobileNavItem> createState() => _MobileNavItemState();
}

class _MobileNavItemState extends State<_MobileNavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _pressed
              ? AppColors.golden.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(widget.icon,
                color: Colors.white.withValues(alpha: 0.55),
                size: 20),
            const SizedBox(width: 14),
            Text(
              widget.label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile categories accordion
// ─────────────────────────────────────────────────────────────────────────────

class _MobileCategoryAccordion extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final List<Map<String, dynamic>> categories;
  final ValueChanged<String> onSelectCategory;

  const _MobileCategoryAccordion({
    required this.expanded,
    required this.onToggle,
    required this.categories,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: expanded
                  ? AppColors.golden.withValues(alpha: 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.category_outlined,
                    color: expanded
                        ? AppColors.golden.withValues(alpha: 0.80)
                        : Colors.white.withValues(alpha: 0.55),
                    size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Categories',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: expanded
                          ? AppColors.golden
                          : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: expanded
                        ? AppColors.golden
                        : Colors.white.withValues(alpha: 0.40),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Animated accordion content
        AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(
                      left: 16, top: 4, bottom: 4),
                  child: Column(
                    children: categories.map((cat) {
                      return _MobileCategorySubItem(
                        label: cat['label'] as String,
                        icon: cat['icon'] as IconData,
                        onTap: () =>
                            onSelectCategory(cat['label'] as String),
                      );
                    }).toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile category sub-item (inside accordion)
// ─────────────────────────────────────────────────────────────────────────────

class _MobileCategorySubItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _MobileCategorySubItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_MobileCategorySubItem> createState() =>
      _MobileCategorySubItemState();
}

class _MobileCategorySubItemState
    extends State<_MobileCategorySubItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: _pressed
              ? AppColors.golden.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(widget.icon,
                size: 15,
                color: Colors.white.withValues(alpha: 0.40)),
            const SizedBox(width: 10),
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.70),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
