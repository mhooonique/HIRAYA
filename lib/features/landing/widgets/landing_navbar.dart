// lib/features/landing/widgets/landing_navbar.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LandingNavbar — Premium: frosted glass, magnetic hover, shimmer CTA,
// staggered dropdown, scroll-progress glow bar, mobile slide drawer.
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
    final isMobile = MediaQuery.of(context).size.width <= 768;

    final navBody = SizedBox(
      height: 70,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
        child: Row(
          children: [
            _AnimatedLogo(shimmerCtrl: _shimmerCtrl, isMobile: isMobile),
            const Spacer(),
            if (!isMobile) ...[
              _NavLink(
                label: 'Marketplace',
                onTap: () => context.go('/marketplace'),
                showDot: true,
              ),
              _NavLink(
                label: 'About',
                onTap: widget.onAboutTap ?? () => context.go('/'),
              ),
              _CategoriesDropdown(onCategoriesTap: widget.onCategoriesTap),
              const SizedBox(width: 16),
              _SignInButton(onTap: () => context.go('/login')),
              const SizedBox(width: 8),
              _CTAButton(onTap: () => context.go('/signup')),
            ] else
              _HamburgerButton(onTap: () => _openMobileDrawer(context)),
          ],
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Scroll progress bar ────────────────────────────────
        _ScrollProgressBar(controller: _progressCtrl),

        // ── Main navbar ────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isScrolled
                ? AppColors.deepVoid.withValues(alpha: 0.88)
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
                      color: Colors.black.withValues(alpha: 0.30),
                      blurRadius: 20,
                    ),
                    BoxShadow(
                      color: AppColors.golden.withValues(alpha: 0.04),
                      blurRadius: 40,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: isScrolled
              ? ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: navBody,
                  ),
                )
              : navBody,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scroll progress bar with animated shimmer at leading edge
// ─────────────────────────────────────────────────────────────────────────────

class _ScrollProgressBar extends StatelessWidget {
  final AnimationController controller;
  const _ScrollProgressBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => LayoutBuilder(
        builder: (context, constraints) {
          final fillWidth = constraints.maxWidth * controller.value;
          return SizedBox(
            height: 2,
            child: Stack(
              children: [
                // Track
                Container(color: Colors.white.withValues(alpha: 0.04)),
                // Fill
                Container(
                  width: fillWidth,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.golden,
                        AppColors.warmEmber,
                        AppColors.golden,
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                // Shimmer glow dot at leading edge
                if (controller.value > 0.01)
                  Positioned(
                    left: (fillWidth - 16).clamp(0.0, constraints.maxWidth),
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

// ─────────────────────────────────────────────────────────────────────────────
// Animated Logo — one-shot shimmer + hover glow + tap bounce
// ─────────────────────────────────────────────────────────────────────────────

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
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
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
        onTap: () => context.go('/'),
        child: AnimatedBuilder(
          animation: Listenable.merge([widget.shimmerCtrl, _glowAnim]),
          builder: (_, __) {
            final t = widget.shimmerCtrl.value;
            final g = _glowAnim.value;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo image with hover glow ring
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: _hovered
                        ? [
                            BoxShadow(
                              color: AppColors.golden.withValues(
                                  alpha: (0.30 + g * 0.25)),
                              blurRadius: 20 + g * 10,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: AnimatedScale(
                    scale: _hovered ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    child: Image.asset(
                      'assets/images/logo/final-logo.png',
                      height: widget.isMobile ? 32 : 38,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Wordmark with shimmer sweep
                ShaderMask(
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
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: widget.isMobile ? 18 : 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                    child: const Text('HIRAYA'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav link — pill hover bg + sliding underline + text animation
// ─────────────────────────────────────────────────────────────────────────────

class _NavLink extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool showDot;
  const _NavLink({required this.label, this.onTap, this.showDot = false});

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
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _hovered
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _hovered
                    ? Colors.white.withValues(alpha: 0.09)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Label + dot
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
                    if (widget.showDot)
                      Positioned(
                        top: -3,
                        right: -8,
                        child: _PulsingDot(),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                // Sliding underline
                AnimatedBuilder(
                  animation: _underlineAnim,
                  builder: (_, __) => Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 2,
                      width: _underlineAnim.value * 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.golden, AppColors.warmEmber],
                        ),
                        borderRadius: BorderRadius.circular(1),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.golden.withValues(alpha: 0.55),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing red dot for Marketplace link
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
    )..repeat();
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
// Sign In button — border outline → golden fill on hover
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
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.golden.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: _hovered
                  ? AppColors.golden
                  : Colors.white.withValues(alpha: 0.30),
              width: 1.5,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.golden.withValues(alpha: 0.20),
                      blurRadius: 14,
                    ),
                  ]
                : [],
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
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
// Get Started CTA — pulsing glow + shimmer sweep on hover
// ─────────────────────────────────────────────────────────────────────────────

class _CTAButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CTAButton({required this.onTap});

  @override
  State<_CTAButton> createState() => _CTAButtonState();
}

class _CTAButtonState extends State<_CTAButton>
    with TickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _glowCtrl;
  late AnimationController _shimmerCtrl;
  late Animation<double> _glowAnim;
  late Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _shimmerAnim = CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  void _onEnter(_) {
    setState(() => _hovered = true);
    _shimmerCtrl.forward(from: 0);
  }

  void _onExit(_) {
    setState(() => _hovered = false);
    _shimmerCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: _onEnter,
      onExit: _onExit,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge([_glowAnim, _shimmerAnim]),
          builder: (_, child) {
            final glowStrength = 0.25 + _glowAnim.value * 0.35;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.golden, AppColors.warmEmber],
                ),
                borderRadius: BorderRadius.circular(9),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.golden.withValues(alpha: glowStrength),
                    blurRadius: _hovered
                        ? 26
                        : 12 + _glowAnim.value * 8,
                    spreadRadius: _hovered ? 2 : 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Stack(
                  children: [
                    child!,
                    // Shimmer sweep overlay
                    Positioned.fill(
                      child: Transform.translate(
                        offset: Offset(
                          -80 + _shimmerAnim.value * (80 + 160),
                          0,
                        ),
                        child: Container(
                          width: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.25),
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
// Hamburger button — animated lines
// ─────────────────────────────────────────────────────────────────────────────

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
            color: _hovered
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MenuLine(hovered: _hovered, offset: -1),
              const SizedBox(height: 5),
              _MenuLine(hovered: _hovered, offset: 0, shorter: true),
              const SizedBox(height: 5),
              _MenuLine(hovered: _hovered, offset: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuLine extends StatelessWidget {
  final bool hovered;
  final double offset;
  final bool shorter;
  const _MenuLine({
    required this.hovered,
    required this.offset,
    this.shorter = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: 2,
      width: hovered
          ? (shorter ? 14 : 20)
          : (shorter ? 16 : 22),
      margin: EdgeInsets.only(
        left: hovered ? (offset.abs() * 4) : 0,
      ),
      decoration: BoxDecoration(
        color: hovered ? AppColors.golden : Colors.white.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Categories dropdown
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
      'color': Color(0xFF4B8EF0),
    },
  ];

  @override
  void initState() {
    super.initState();
    _dropdownCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
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
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: buttonOffset.dy + buttonSize.height + 8,
            left: buttonOffset.dx - 80,
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: (_hovered || _isOpen)
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (_hovered || _isOpen)
                    ? Colors.white.withValues(alpha: 0.09)
                    : Colors.transparent,
                width: 1,
              ),
            ),
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
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
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
                  duration: const Duration(milliseconds: 200),
                  height: 2,
                  width: (_hovered || _isOpen) ? 64 : 0,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.golden, AppColors.warmEmber],
                    ),
                    borderRadius: BorderRadius.circular(1),
                    boxShadow: (_hovered || _isOpen)
                        ? [
                            BoxShadow(
                              color: AppColors.golden.withValues(alpha: 0.55),
                              blurRadius: 5,
                            ),
                          ]
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

// ─────────────────────────────────────────────────────────────────────────────
// Categories dropdown panel — glassmorphism dark bg, staggered item entrance
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
      builder: (_, child) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, -14 * (1 - animation.value)),
          child: child,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 400,
          decoration: BoxDecoration(
            color: const Color(0xFF080F1A).withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.golden.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.60),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.golden.withValues(alpha: 0.05),
                blurRadius: 60,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.golden.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(
                          Icons.category_rounded,
                          color: AppColors.golden,
                          size: 13,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'BROWSE CATEGORIES',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.golden,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${categories.length} categories',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            color: Colors.white.withValues(alpha: 0.40),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 2x3 Grid with staggered entrance
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.7,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 7,
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
                      )
                          .animate(delay: Duration(milliseconds: i * 45))
                          .fadeIn(duration: 300.ms)
                          .slideY(
                            begin: 0.12,
                            end: 0,
                            curve: Curves.easeOutCubic,
                            duration: 280.ms,
                          );
                    },
                  ),
                ),

                const SizedBox(height: 10),
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Category grid item — hover glow + icon brightening
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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.14)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.07),
              width: 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.25),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: widget.color.withValues(
                      alpha: _hovered ? 0.22 : 0.10),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _hovered
                      ? [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.30),
                            blurRadius: 8,
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  widget.icon,
                  size: 15,
                  color: widget.color.withValues(
                      alpha: _hovered ? 1.0 : 0.55),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _hovered
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.75),
                      ),
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 9,
                        color: _hovered
                            ? widget.color.withValues(alpha: 0.85)
                            : Colors.white.withValues(alpha: 0.35),
                      ),
                      child: Text('${widget.count} innovations'),
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
// View All row
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
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          color: _hovered
              ? AppColors.golden.withValues(alpha: 0.07)
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
              AnimatedSlide(
                offset: _hovered ? const Offset(0.3, 0) : Offset.zero,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
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
// Mobile Drawer Overlay — slides from right
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
      duration: const Duration(milliseconds: 340),
    );
    _slideAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5)),
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
    Future.delayed(const Duration(milliseconds: 180), () {
      if (context.mounted) context.go(path);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final panelWidth = (screenWidth * 0.82).clamp(0.0, 340.0);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Stack(
        children: [
          // Scrim
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              child: Container(
                color: Colors.black.withValues(alpha: 0.60 * _fadeAnim.value),
              ),
            ),
          ),
          // Slide panel
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
      ),
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
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 40,
            offset: const Offset(-6, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
              child: Row(
                children: [
                  Image.asset('assets/images/logo/final-logo.png', height: 32),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [AppColors.golden, AppColors.warmEmber],
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
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.60),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
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

            // Nav items
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MobileNavItem(
                      icon: Icons.storefront_rounded,
                      label: 'Marketplace',
                      onTap: () => _navigateTo(context, '/marketplace'),
                    ),
                    _MobileNavItem(
                      icon: Icons.info_outline_rounded,
                      label: 'About',
                      onTap: () {
                        _close();
                        Future.delayed(
                          const Duration(milliseconds: 180),
                          () => widget.onAboutTap?.call(),
                        );
                      },
                    ),
                    _MobileCategoryAccordion(
                      expanded: _categoriesExpanded,
                      onToggle: () => setState(
                        () => _categoriesExpanded = !_categoriesExpanded,
                      ),
                      categories: _categories,
                      onSelectCategory: (label) =>
                          _navigateTo(context, '/marketplace?category=$label'),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.white.withValues(alpha: 0.08)),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'Where Filipino Innovation Soars',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.30),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Auth buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _navigateTo(context, '/login'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.golden,
                        side: BorderSide(
                            color: AppColors.golden.withValues(alpha: 0.50)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
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
                          colors: [AppColors.golden, AppColors.warmEmber],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ElevatedButton(
                        onPressed: () => _navigateTo(context, '/signup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _pressed
              ? AppColors.golden.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(widget.icon,
                color: Colors.white.withValues(alpha: 0.55), size: 20),
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
// Mobile category accordion
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
        GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: expanded
                  ? AppColors.golden.withValues(alpha: 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.category_outlined,
                  color: expanded
                      ? AppColors.golden.withValues(alpha: 0.80)
                      : Colors.white.withValues(alpha: 0.55),
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Categories',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: expanded ? AppColors.golden : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
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
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          child: expanded
              ? Padding(
                  padding:
                      const EdgeInsets.only(left: 16, top: 4, bottom: 4),
                  child: Column(
                    children: categories
                        .map((cat) => _MobileCategorySubItem(
                              label: cat['label'] as String,
                              icon: cat['icon'] as IconData,
                              onTap: () => onSelectCategory(
                                  cat['label'] as String),
                            ))
                        .toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile category sub-item
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

class _MobileCategorySubItemState extends State<_MobileCategorySubItem> {
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                size: 15, color: Colors.white.withValues(alpha: 0.40)),
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
