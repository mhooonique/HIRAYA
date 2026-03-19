// lib/features/landing/widgets/landing_navbar.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LandingNavbar — Complete redesign: glassmorphic frosted glass, golden shimmer
// logo "Digital Platform", scroll-progress bar at bottom, animated categories
// dropdown (list with colored left borders), mobile slide drawer.
// Brand display name: "Digital Platform" (internal code name: HIRAYA unchanged).
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
  late AnimationController _progressCtrl;
  late AnimationController _shimmerCtrl;
  OverlayEntry? _mobileDrawerOverlay;

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..forward();
  }

  @override
  void didUpdateWidget(LandingNavbar old) {
    super.didUpdateWidget(old);
    final progress = (widget.scrollOffset / 3000).clamp(0.0, 1.0);
    _progressCtrl.animateTo(
      progress,
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _shimmerCtrl.dispose();
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
    final width = MediaQuery.of(context).size.width;
    final isMobile = width <= 900;
    final isCompactDesktop = !isMobile && width < 1220;
    final horizontalPad = isMobile ? 16.0 : (isCompactDesktop ? 24.0 : 32.0);

    final navContent = SizedBox(
      height: 68,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPad),
        child: Row(
          children: [
            _AnimatedLogo(shimmerCtrl: _shimmerCtrl, isMobile: isMobile),
            const Spacer(),
            if (!isMobile) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NavLink(label: 'Home', onTap: () => context.go('/'))
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 350.ms)
                      .slideX(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                  _NavLink(
                    label: 'Marketplace',
                    onTap: () => context.go('/marketplace'),
                  )
                      .animate(delay: 200.ms)
                      .fadeIn(duration: 350.ms)
                      .slideX(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                  _CategoriesDropdown(onCategoriesTap: widget.onCategoriesTap)
                      .animate(delay: 300.ms)
                      .fadeIn(duration: 350.ms)
                      .slideX(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                  if (!isCompactDesktop)
                    _NavLink(
                      label: 'About',
                      onTap: widget.onAboutTap ?? () => context.go('/'),
                    )
                        .animate(delay: 400.ms)
                        .fadeIn(duration: 350.ms)
                        .slideX(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
                ],
              ),
              SizedBox(width: isCompactDesktop ? 8 : 20),
              if (!isCompactDesktop)
                _LoginButton(onTap: () => context.go('/login'))
                    .animate(delay: 500.ms)
                    .fadeIn(duration: 300.ms),
              if (!isCompactDesktop) const SizedBox(width: 10),
              _GetStartedButton(onTap: () => context.go('/signup'))
                  .animate(delay: 600.ms)
                  .fadeIn(duration: 300.ms),
            ] else
              _HamburgerButton(onTap: () => _openMobileDrawer(context)),
          ],
        ),
      ),
    );

    final blurredNav = isScrolled
        ? ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: navContent,
            ),
          )
        : navContent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isScrolled
                ? const Color(0xFF050A12).withValues(alpha: 0.92)
                : Colors.transparent,
            border: isScrolled
                ? Border(
                    bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
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
                  ]
                : [],
          ),
          child: blurredNav,
        ),
        _ScrollProgressBar(controller: _progressCtrl),
      ],
    );
  }
}

class _ScrollProgressBar extends StatelessWidget {
  final AnimationController controller;
  const _ScrollProgressBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => LayoutBuilder(
        builder: (context, constraints) {
          final fallbackWidth = MediaQuery.sizeOf(context).width;
          final maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : fallbackWidth;
          final safeWidth = maxWidth > 0 ? maxWidth : 0.0;
          final fillWidth = safeWidth * controller.value;
          final glowLeft = (fillWidth - 16).clamp(
            0.0,
            safeWidth > 16 ? safeWidth - 16 : 0.0,
          );

          if (safeWidth <= 0) {
            return const SizedBox(height: 2);
          }

          return SizedBox(
            width: safeWidth,
            height: 2,
            child: Stack(
              children: [
                Container(color: Colors.white.withValues(alpha: 0.04)),
                Container(
                  width: fillWidth,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.golden, AppColors.warmEmber, AppColors.golden],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                if (controller.value > 0.01)
                  Positioned(
                    left: glowLeft,
                    top: -4,
                    child: Container(
                      width: 16,
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            AppColors.golden.withValues(alpha: 0.90),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedLogo extends StatefulWidget {
  final AnimationController shimmerCtrl;
  final bool isMobile;
  const _AnimatedLogo({required this.shimmerCtrl, required this.isMobile});

  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _pulseScale = Tween<double>(begin: 1.0, end: 2.4).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.80, end: 0.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go('/'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: _hovered ? 1.06 : 1.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Image.asset(
                'assets/images/logo/final-logo.png',
                height: widget.isMobile ? 30 : 36,
              ),
            ),
            const SizedBox(width: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: widget.shimmerCtrl,
                  builder: (_, __) {
                    final t = widget.shimmerCtrl.value;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            begin: Alignment(-1.5 + t * 3.5, 0),
                            end: Alignment(-0.2 + t * 3.5, 0),
                            colors: const [
                              AppColors.golden,
                              AppColors.goldSheen,
                              Color(0xFFFFEF90),
                              AppColors.warmEmber,
                              AppColors.golden,
                            ],
                            stops: const [0.0, 0.25, 0.50, 0.75, 1.0],
                          ).createShader(bounds),
                          child: Text(
                            'Digital',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.white,
                              fontSize: widget.isMobile ? 16 : 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Platform',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white,
                            fontSize: widget.isMobile ? 16 : 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 14,
                  height: 14,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) => Transform.scale(
                          scale: _pulseScale.value,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.golden
                                  .withValues(alpha: _pulseOpacity.value),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.golden,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        )
            .animate()
            .fadeIn(duration: 500.ms, curve: Curves.easeOutCubic)
            .slideX(begin: -0.3, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  const _NavLink({required this.label, this.onTap});

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
      duration: const Duration(milliseconds: 240),
    );
    _underlineAnim = CurvedAnimation(parent: _underlineCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _underlineCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovered = true);
        _underlineCtrl.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _underlineCtrl.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: TextStyle(
                    color: _hovered ? Colors.white : Colors.white.withValues(alpha: 0.70),
                    fontFamily: 'Poppins',
                    fontWeight: _hovered ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                  child: Text(widget.label),
                ),
                const SizedBox(height: 3),
                AnimatedBuilder(
                  animation: _underlineAnim,
                  builder: (_, __) {
                    final maxW = (widget.label.length * 8.4).clamp(30.0, 120.0);
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        height: 2,
                        width: _underlineAnim.value * maxW,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.golden, AppColors.warmEmber],
                          ),
                          borderRadius: BorderRadius.circular(1),
                          boxShadow: _hovered
                              ? [BoxShadow(color: AppColors.golden.withValues(alpha: 0.55), blurRadius: 5)]
                              : [],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatefulWidget {
  final VoidCallback onTap;
  const _LoginButton({required this.onTap});

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> {
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
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.teal.withValues(alpha: 0.10) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: _hovered ? AppColors.teal : AppColors.teal.withValues(alpha: 0.60),
              width: 1.5,
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: AppColors.teal.withValues(alpha: 0.22), blurRadius: 14)]
                : [],
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: _hovered ? Colors.white : Colors.white.withValues(alpha: 0.85),
            ),
            child: const Text('Login'),
          ),
        ),
      ),
    );
  }
}

class _GetStartedButton extends StatefulWidget {
  final VoidCallback onTap;
  const _GetStartedButton({required this.onTap});

  @override
  State<_GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<_GetStartedButton>
    with TickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _glowCtrl;
  late AnimationController _shimmerCtrl;
  late Animation<double> _glowAnim;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _shimmerAnim = CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovered = true);
        _shimmerCtrl.forward(from: 0);
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _shimmerCtrl.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_glowAnim, _shimmerAnim]),
          builder: (_, child) {
            final baseGlow = 0.22 + _glowAnim.value * 0.28;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.golden, AppColors.warmEmber]),
                borderRadius: BorderRadius.circular(9),
                border: _hovered
                    ? Border.all(color: AppColors.teal.withValues(alpha: 0.70), width: 1.5)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.golden.withValues(alpha: _hovered ? 0.45 : baseGlow),
                    blurRadius: _hovered ? 28 : 12 + _glowAnim.value * 8,
                    spreadRadius: _hovered ? 2 : 0,
                  ),
                  if (_hovered)
                    BoxShadow(color: AppColors.teal.withValues(alpha: 0.30), blurRadius: 20, spreadRadius: 1),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Stack(
                  children: [
                    child!,
                    Positioned.fill(
                      child: Transform.translate(
                        offset: Offset(-80 + _shimmerAnim.value * 260, 0),
                        child: Container(
                          width: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.28),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          child: const Text(
            'Get Started',
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navy),
          ),
        ),
      ),
    );
  }
}

class _HamburgerButton extends StatefulWidget {
  final VoidCallback onTap;
  const _HamburgerButton({required this.onTap});

  @override
  State<_HamburgerButton> createState() => _HamburgerButtonState();
}

class _HamburgerButtonState extends State<_HamburgerButton> {
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
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _hovered ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _hovered ? Colors.white.withValues(alpha: 0.15) : Colors.transparent),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MenuLine(hovered: _hovered, shorter: false),
              const SizedBox(height: 5),
              _MenuLine(hovered: _hovered, shorter: true),
              const SizedBox(height: 5),
              _MenuLine(hovered: _hovered, shorter: false),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuLine extends StatelessWidget {
  final bool hovered;
  final bool shorter;
  const _MenuLine({required this.hovered, required this.shorter});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: 2,
      width: hovered ? (shorter ? 14 : 20) : (shorter ? 16 : 22),
      decoration: BoxDecoration(
        color: hovered ? AppColors.golden : Colors.white.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

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

  static const List<Map<String, dynamic>> _categories = [
    {'label': 'Agri-Aqua and Forestry', 'icon': Icons.grass_rounded, 'color': AppColors.teal},
    {'label': 'Food Processing and Nutrition', 'icon': Icons.restaurant_menu_rounded, 'color': Color(0xFFFF8C42)},
    {'label': 'Health and Medical Sciences', 'icon': Icons.medical_services_rounded, 'color': AppColors.crimson},
    {'label': 'Energy, Utilities, and Environment', 'icon': Icons.bolt_rounded, 'color': AppColors.golden},
    {'label': 'Advanced Manufacturing and Engineering', 'icon': Icons.foundation_rounded, 'color': AppColors.navy},
    {'label': 'Creative Industries and Product Design', 'icon': Icons.design_services_rounded, 'color': AppColors.sky},
    {'label': 'Information and Communications Technology (ICT)', 'icon': Icons.computer_rounded, 'color': Color(0xFF1B4B8A)},
  ];

  @override
  void initState() {
    super.initState();
    _dropdownCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _dropdownAnim = CurvedAnimation(parent: _dropdownCtrl, curve: Curves.easeOutCubic);
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
    final RenderBox overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final buttonOffset = button.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonSize = button.size;

    _overlayEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: buttonOffset.dy + buttonSize.height + 6,
            left: buttonOffset.dx - 60,
            child: _CategoryDropdownPanel(
              animation: _dropdownAnim,
              categories: _categories,
              onSelect: (label) {
                _closeDropdown();
                if (context.mounted) context.go('/marketplace?category=$label');
              },
              onViewAll: () {
                _closeDropdown();
                if (context.mounted) context.go('/marketplace');
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
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: TextStyle(
                        color: (_hovered || _isOpen) ? Colors.white : Colors.white.withValues(alpha: 0.70),
                        fontFamily: 'Poppins',
                        fontWeight: (_hovered || _isOpen) ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                      child: const Text('Categories'),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _isOpen ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: (_hovered || _isOpen) ? Colors.white : Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 2,
                  width: (_hovered || _isOpen) ? 72 : 0,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.golden, AppColors.warmEmber]),
                    borderRadius: BorderRadius.circular(1),
                    boxShadow: (_hovered || _isOpen)
                        ? [BoxShadow(color: AppColors.golden.withValues(alpha: 0.55), blurRadius: 5)]
                        : [],
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
      builder: (_, child) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, -16 * (1 - animation.value)),
          child: child,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          decoration: BoxDecoration(
            color: const Color(0xFF080F1A).withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.golden.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.65), blurRadius: 44, offset: const Offset(0, 14)),
              BoxShadow(color: AppColors.golden.withValues(alpha: 0.05), blurRadius: 60),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.golden.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(Icons.category_rounded, color: AppColors.golden, size: 12),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'BROWSE CATEGORIES',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.golden, letterSpacing: 1.5),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.white.withValues(alpha: 0.08), Colors.transparent],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: categories.asMap().entries.map((entry) {
                      final i = entry.key;
                      final cat = entry.value;
                      return _CategoryListItem(
                        label: cat['label'] as String,
                        icon: cat['icon'] as IconData,
                        color: cat['color'] as Color,
                        onTap: () => onSelect(cat['label'] as String),
                      )
                          .animate(delay: Duration(milliseconds: i * 50))
                          .fadeIn(duration: 280.ms)
                          .slideY(begin: 0.10, end: 0, curve: Curves.easeOutCubic, duration: 260.ms);
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.white.withValues(alpha: 0.08), Colors.transparent],
                    ),
                  ),
                ),
                _ViewAllRow(onTap: onViewAll),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryListItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CategoryListItem({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  State<_CategoryListItem> createState() => _CategoryListItemState();
}

class _CategoryListItemState extends State<_CategoryListItem> {
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
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: _hovered ? widget.color.withValues(alpha: 0.10) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 3,
                height: 38,
                decoration: BoxDecoration(
                  color: _hovered ? widget.color : widget.color.withValues(alpha: 0.35),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: _hovered ? 0.20 : 0.08),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(widget.icon, size: 14, color: widget.color.withValues(alpha: _hovered ? 1.0 : 0.60)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: _hovered ? FontWeight.w600 : FontWeight.w500,
                    color: _hovered ? Colors.white : Colors.white.withValues(alpha: 0.72),
                  ),
                  child: Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _hovered ? 1.0 : 0.0,
                child: AnimatedSlide(
                  offset: _hovered ? Offset.zero : const Offset(-0.3, 0),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(Icons.arrow_forward_ios_rounded, size: 11, color: widget.color),
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
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          color: _hovered ? AppColors.golden.withValues(alpha: 0.06) : Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _hovered ? AppColors.golden : Colors.white.withValues(alpha: 0.45),
                ),
                child: const Text('View All Categories'),
              ),
              const SizedBox(width: 6),
              AnimatedSlide(
                offset: _hovered ? const Offset(0.3, 0) : Offset.zero,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: _hovered ? AppColors.golden : Colors.white.withValues(alpha: 0.30),
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
// Mobile Drawer Overlay
// ─────────────────────────────────────────────────────────────────────────────

class _MobileDrawerOverlay extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback? onAboutTap;
  const _MobileDrawerOverlay({required this.onClose, this.onAboutTap});

  @override
  State<_MobileDrawerOverlay> createState() => _MobileDrawerOverlayState();
}

class _MobileDrawerOverlayState extends State<_MobileDrawerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slideAnim;
  late Animation<double> _fadeAnim;
  bool _categoriesExpanded = false;

  static const List<Map<String, dynamic>> _categories = [
    {'label': 'Agri-Aqua and Forestry', 'icon': Icons.grass_rounded, 'color': AppColors.teal},
    {'label': 'Food Processing and Nutrition', 'icon': Icons.restaurant_menu_rounded, 'color': Color(0xFFFF8C42)},
    {'label': 'Health and Medical Sciences', 'icon': Icons.medical_services_rounded, 'color': AppColors.crimson},
    {'label': 'Energy, Utilities, and Environment', 'icon': Icons.bolt_rounded, 'color': AppColors.golden},
    {'label': 'Advanced Manufacturing and Engineering', 'icon': Icons.foundation_rounded, 'color': AppColors.navy},
    {'label': 'Creative Industries and Product Design', 'icon': Icons.design_services_rounded, 'color': AppColors.sky},
    {'label': 'Information and Communications Technology (ICT)', 'icon': Icons.computer_rounded, 'color': Color(0xFF1B4B8A)},
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slideAnim = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5)));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _close() => _ctrl.reverse().then((_) => widget.onClose());

  void _navigateTo(BuildContext context, String path) {
    _close();
    Future.delayed(const Duration(milliseconds: 180), () {
      if (context.mounted) context.go(path);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = (screenWidth * 0.82).clamp(0.0, 360.0);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8 * _fadeAnim.value, sigmaY: 8 * _fadeAnim.value),
                child: Container(color: Colors.black.withValues(alpha: 0.55 * _fadeAnim.value)),
              ),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: panelWidth,
            child: Transform.translate(
              offset: Offset(panelWidth * _slideAnim.value, 0),
              child: Opacity(opacity: _fadeAnim.value.clamp(0.0, 1.0), child: child),
            ),
          ),
        ],
      ),
      child: _buildPanel(context, panelWidth),
    );
  }

  Widget _buildPanel(BuildContext context, double panelWidth) {
    return Container(
      width: panelWidth,
      decoration: BoxDecoration(
        color: AppColors.richNavy,
        border: Border(left: BorderSide(color: AppColors.golden.withValues(alpha: 0.14), width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.60), blurRadius: 44, offset: const Offset(-8, 0))],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
              child: Row(
                children: [
                  Image.asset('assets/images/logo/final-logo.png', height: 30),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [AppColors.golden, AppColors.goldSheen, AppColors.warmEmber],
                          ).createShader(bounds),
                          child: const Text('Digital', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 4),
                        const Text('Platform', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _close,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                      ),
                      child: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.65), size: 18),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, AppColors.golden.withValues(alpha: 0.22), Colors.transparent]),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MobileNavItem(icon: Icons.home_rounded, label: 'Home', onTap: () => _navigateTo(context, '/'), delay: 60),
                    _MobileNavItem(icon: Icons.storefront_rounded, label: 'Marketplace', onTap: () => _navigateTo(context, '/marketplace'), delay: 120),
                    _MobileNavItem(
                      icon: Icons.info_outline_rounded,
                      label: 'About',
                      onTap: () { _close(); Future.delayed(const Duration(milliseconds: 180), () => widget.onAboutTap?.call()); },
                      delay: 180,
                    ),
                    _MobileCategoryAccordion(
                      expanded: _categoriesExpanded,
                      onToggle: () => setState(() => _categoriesExpanded = !_categoriesExpanded),
                      categories: _categories,
                      onSelectCategory: (label) => _navigateTo(context, '/marketplace?category=$label'),
                      delay: 240,
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.white.withValues(alpha: 0.08)),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'Where Filipino Innovation Soars',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white.withValues(alpha: 0.28), fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _navigateTo(context, '/login'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: AppColors.teal.withValues(alpha: 0.70), width: 1.5),
                        backgroundColor: AppColors.teal.withValues(alpha: 0.05),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Login', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.golden, AppColors.warmEmber]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ElevatedButton(
                        onPressed: () => _navigateTo(context, '/signup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Get Started', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.navy)),
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

class _MobileNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int delay;
  const _MobileNavItem({required this.icon, required this.label, required this.onTap, this.delay = 0});

  @override
  State<_MobileNavItem> createState() => _MobileNavItemState();
}

class _MobileNavItemState extends State<_MobileNavItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _pressed ? AppColors.golden.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(widget.icon, color: Colors.white.withValues(alpha: 0.50), size: 20),
            const SizedBox(width: 14),
            Text(widget.label, style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.delay))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.15, end: 0, duration: 280.ms, curve: Curves.easeOutCubic);
  }
}

class _MobileCategoryAccordion extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final List<Map<String, dynamic>> categories;
  final ValueChanged<String> onSelectCategory;
  final int delay;
  const _MobileCategoryAccordion({
    required this.expanded, required this.onToggle, required this.categories,
    required this.onSelectCategory, this.delay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: expanded ? AppColors.golden.withValues(alpha: 0.06) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.category_outlined, color: expanded ? AppColors.golden.withValues(alpha: 0.80) : Colors.white.withValues(alpha: 0.50), size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Text('Categories', style: TextStyle(fontFamily: 'Poppins', color: expanded ? AppColors.golden : Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  child: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: expanded ? AppColors.golden : Colors.white.withValues(alpha: 0.38)),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
                  child: Column(
                    children: categories.map((cat) => _MobileCategorySubItem(
                      label: cat['label'] as String,
                      icon: cat['icon'] as IconData,
                      color: cat['color'] as Color,
                      onTap: () => onSelectCategory(cat['label'] as String),
                    )).toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.15, end: 0, duration: 280.ms, curve: Curves.easeOutCubic);
  }
}

class _MobileCategorySubItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MobileCategorySubItem({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  State<_MobileCategorySubItem> createState() => _MobileCategorySubItemState();
}

class _MobileCategorySubItemState extends State<_MobileCategorySubItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 1),
        decoration: BoxDecoration(
          color: _pressed ? widget.color.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(width: 3, height: 16, decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.70), borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Icon(widget.icon, size: 15, color: widget.color.withValues(alpha: 0.55)),
            const SizedBox(width: 8),
            Expanded(child: Text(widget.label, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white.withValues(alpha: 0.68)))),
          ],
        ),
      ),
    );
  }
}
