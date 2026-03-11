import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class LandingNavbar extends StatefulWidget {
  final double scrollOffset;
  final double scrollProgress;
  const LandingNavbar({
    super.key,
    required this.scrollOffset,
    this.scrollProgress = 0,
  });

  @override
  State<LandingNavbar> createState() => _LandingNavbarState();
}

class _LandingNavbarState extends State<LandingNavbar>
    with SingleTickerProviderStateMixin {
  bool _logoHovered = false;
  late AnimationController _logoCtrl;
  late Animation<double> _logoPulse;

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2800))
      ..repeat(reverse: true);
    _logoPulse = Tween(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isScrolled = widget.scrollOffset > 50;
    final progress = widget.scrollProgress;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
      AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isScrolled
            ? AppColors.navy.withValues(alpha: 0.97)
            : Colors.transparent,
        boxShadow: isScrolled
            ? [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 2))
              ]
            : [],
        border: isScrolled
            ? Border(
                bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08)))
            : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 11),
          child: Row(
            children: [
              // Logo + brand
              MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _logoHovered = true),
                onExit: (_) => setState(() => _logoHovered = false),
                child: GestureDetector(
                  onTap: () => context.go('/'),
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: _logoPulse,
                        builder: (_, child) => Transform.scale(
                          scale:
                              _logoHovered ? 1.09 : _logoPulse.value,
                          child: child,
                        ),
                        child: Image.asset(
                            'assets/images/logo/final-logo.png',
                            height: 38),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'HIRAYA',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 3.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (MediaQuery.of(context).size.width > 768) ...[
                _NavLink(
                    label: 'Marketplace',
                    onTap: () => context.go('/marketplace')),
                const _NavLink(label: 'About'),
                const _NavLink(label: 'Categories'),
                const SizedBox(width: 20),
                _SignInNavButton(onTap: () => context.go('/login')),
                const SizedBox(width: 10),
                _GetStartedNavButton(
                    onTap: () => context.go('/signup')),
              ] else
                _MobileMenuButton(),
            ],
          ),
        ),
      ),
    ),
    // ── Scroll Progress Bar ──────────────────────────────────
    LayoutBuilder(
      builder: (ctx, box) => SizedBox(
        height: 2,
        width: box.maxWidth,
        child: Stack(
          children: [
            Container(
              width: box.maxWidth,
              height: 2,
              color: Colors.white.withValues(alpha: isScrolled ? 0.06 : 0),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 80),
              curve: Curves.linear,
              width: box.maxWidth * progress,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.teal,
                    AppColors.sky,
                    AppColors.golden.withValues(alpha: 0.9),
                  ],
                ),
                boxShadow: progress > 0.01
                    ? [
                        BoxShadow(
                          color: AppColors.teal.withValues(alpha: 0.7),
                          blurRadius: 6,
                        )
                      ]
                    : [],
              ),
            ),
          ],
        ),
      ),
    ),
    ],
  );
  }
}

// ═══════════════════════════════════════════════════════════
// Nav Link — hover underline grows from center
// ═══════════════════════════════════════════════════════════
class _NavLink extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  const _NavLink({required this.label, this.onTap});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: _hovered ? Colors.white : Colors.white70,
                  fontFamily: 'Poppins',
                  fontWeight:
                      _hovered ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 2,
                width: _hovered ? 22 : 0,
                decoration: BoxDecoration(
                  color: AppColors.golden,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Sign In button — ghost fill on hover
// ═══════════════════════════════════════════════════════════
class _SignInNavButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SignInNavButton({required this.onTap});

  @override
  State<_SignInNavButton> createState() => _SignInNavButtonState();
}

class _SignInNavButtonState extends State<_SignInNavButton> {
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
          padding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: _hovered
                  ? Colors.white.withValues(alpha: 0.60)
                  : Colors.white.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            'Sign In',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
              color: _hovered ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Get Started — gradient + shimmer + arrow reveal
// ═══════════════════════════════════════════════════════════
class _GetStartedNavButton extends StatefulWidget {
  final VoidCallback onTap;
  const _GetStartedNavButton({required this.onTap});

  @override
  State<_GetStartedNavButton> createState() =>
      _GetStartedNavButtonState();
}

class _GetStartedNavButtonState extends State<_GetStartedNavButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;
  late AnimationController _shimCtrl;

  @override
  void initState() {
    super.initState();
    _shimCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900));
  }

  @override
  void dispose() {
    _shimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovered = true);
        _shimCtrl.repeat();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _shimCtrl
          ..stop()
          ..reset();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 9),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _hovered
                    ? [AppColors.teal, const Color(0xFF0F9A8A)]
                    : [AppColors.teal, const Color(0xFF0C7A6E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(9),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                          color:
                              AppColors.teal.withValues(alpha: 0.40),
                          blurRadius: 14,
                          offset: const Offset(0, 4))
                    ]
                  : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Stack(
                children: [
                  if (_hovered)
                    AnimatedBuilder(
                      animation: _shimCtrl,
                      builder: (_, __) => Positioned(
                        left: -50.0 + _shimCtrl.value * 200,
                        top: 0,
                        bottom: 0,
                        width: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.transparent,
                              Colors.white
                                  .withValues(alpha: 0.18),
                              Colors.transparent,
                            ]),
                          ),
                        ),
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Get Started',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: Colors.white,
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        child: _hovered
                            ? const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 14),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Mobile menu
// ═══════════════════════════════════════════════════════════
class _MobileMenuButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
      onPressed: () => showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.navy,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => _MobileMenuSheet(),
      ),
    );
  }
}

class _MobileMenuSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          _MobileLink(
              label: 'Marketplace',
              icon: Icons.store_rounded,
              onTap: () {
                Navigator.pop(context);
                context.go('/marketplace');
              }),
          const _MobileLink(
              label: 'About', icon: Icons.info_outline_rounded),
          const _MobileLink(
              label: 'Categories',
              icon: Icons.category_rounded),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.white.withValues(alpha: 0.10),
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Sign In',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/signup');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Get Started',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MobileLink extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  const _MobileLink(
      {required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.white60, size: 20),
      title: Text(label,
          style: const TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded,
          color: Colors.white24, size: 14),
    );
  }
}