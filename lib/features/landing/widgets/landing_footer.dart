import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LandingFooter — Heavily enhanced with newsletter, social links, stats strip,
// expanded link groups, partner row, animated divider, Philippine map painter,
// and "Made in the Philippines" bottom bar.
// ─────────────────────────────────────────────────────────────────────────────

class LandingFooter extends StatelessWidget {
  const LandingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Subtle Philippine-map background painter ───────────────
        Positioned.fill(
          child: CustomPaint(
            painter: _PhilippineMapPainter(),
          ),
        ),

        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF040810),
                AppColors.richNavy.withValues(alpha: 0.60),
                const Color(0xFF020509),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
<<<<<<< HEAD
              // ── Newsletter section ───────────────────────────────
              const _NewsletterSection(),

              // ── Animated shimmer divider ─────────────────────────
              const _ShimmerDivider(),

              // ── Stats strip ─────────────────────────────────────
              const _StatsStrip(),

              // ── Thin separator ───────────────────────────────────
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 32),
                color: Colors.white.withValues(alpha: 0.05),
              ),

              // ── Main content ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 56, horizontal: 32),
                child: Column(
                  children: [
                    LayoutBuilder(builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      return isWide
                          ? Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                _BrandColumn(),
                                const SizedBox(width: 60),
                                Expanded(child: _LinksRow()),
                              ],
                            )
                          : Column(
                              children: [
                                _BrandColumn(),
                                const SizedBox(height: 40),
                                _LinksRow(),
                              ],
                            );
                    }).animate().fadeIn(duration: 600.ms),

                    const SizedBox(height: 48),

                    // ── Partner logos row ────────────────────────
                    const _PartnerLogosRow(),

                    const SizedBox(height: 40),

                    // ── Social media row ─────────────────────────
                    const _SocialRow(),

                    const SizedBox(height: 40),

                    // ── Bottom bar ───────────────────────────────
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _BottomBar(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Philippine Map silhouette — subtle background CustomPainter
// ─────────────────────────────────────────────────────────────────────────────

class _PhilippineMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.golden.withValues(alpha: 0.025)
      ..style = PaintingStyle.fill;

    // Abstract archipelago silhouette — simplified organic shapes
    // representing the Philippine island groups (Luzon, Visayas, Mindanao)
    final cx = size.width * 0.78;
    final cy = size.height * 0.45;

    // Luzon (largest, top)
    final luzon = Path()
      ..moveTo(cx, cy - size.height * 0.28)
      ..cubicTo(
        cx + size.width * 0.04, cy - size.height * 0.22,
        cx + size.width * 0.06, cy - size.height * 0.10,
        cx + size.width * 0.03, cy - size.height * 0.02,
      )
      ..cubicTo(
        cx + size.width * 0.01, cy + size.height * 0.04,
        cx - size.width * 0.03, cy + size.height * 0.05,
        cx - size.width * 0.02, cy - size.height * 0.04,
      )
      ..cubicTo(
        cx - size.width * 0.05, cy - size.height * 0.12,
        cx - size.width * 0.04, cy - size.height * 0.22,
        cx, cy - size.height * 0.28,
      )
      ..close();
    canvas.drawPath(luzon, paint);

    // Visayas (middle cluster)
    final visayas = Path()
      ..moveTo(cx - size.width * 0.04, cy + size.height * 0.07)
      ..cubicTo(
        cx, cy + size.height * 0.06,
        cx + size.width * 0.05, cy + size.height * 0.09,
        cx + size.width * 0.02, cy + size.height * 0.14,
      )
      ..cubicTo(
        cx - size.width * 0.01, cy + size.height * 0.16,
        cx - size.width * 0.06, cy + size.height * 0.13,
        cx - size.width * 0.04, cy + size.height * 0.07,
      )
      ..close();
    canvas.drawPath(visayas, paint);

    // Mindanao (bottom, larger)
    final mindanao = Path()
      ..moveTo(cx - size.width * 0.03, cy + size.height * 0.18)
      ..cubicTo(
        cx + size.width * 0.04, cy + size.height * 0.17,
        cx + size.width * 0.07, cy + size.height * 0.27,
        cx + size.width * 0.02, cy + size.height * 0.33,
      )
      ..cubicTo(
        cx - size.width * 0.03, cy + size.height * 0.35,
        cx - size.width * 0.08, cy + size.height * 0.28,
        cx - size.width * 0.03, cy + size.height * 0.18,
      )
      ..close();
    canvas.drawPath(mindanao, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Newsletter signup section
// ─────────────────────────────────────────────────────────────────────────────

class _NewsletterSection extends StatefulWidget {
  const _NewsletterSection();

  @override
  State<_NewsletterSection> createState() => _NewsletterSectionState();
}

class _NewsletterSectionState extends State<_NewsletterSection> {
  final _controller = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _subscribe() {
    if (_controller.text.trim().isNotEmpty) {
      setState(() => _submitted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.richNavy.withValues(alpha: 0.80),
            AppColors.deepVoid.withValues(alpha: 0.95),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.golden.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth > 640;
        return isWide
            ? Row(
                children: [
                  Expanded(child: _newsletterText()),
                  const SizedBox(width: 40),
                  SizedBox(width: 360, child: _newsletterForm()),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _newsletterText(),
                  const SizedBox(height: 24),
                  _newsletterForm(),
                ],
              );
      }),
    ).animate().fadeIn(duration: 700.ms).slideY(begin: 0.1);
  }

  Widget _newsletterText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.golden, AppColors.warmEmber],
          ).createShader(bounds),
          child: const Text(
            'Stay Updated',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Stay updated with Filipino innovations\nand the latest breakthroughs from our community.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.45),
            height: 1.65,
          ),
        ),
      ],
    );
  }

  Widget _newsletterForm() {
    if (_submitted) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.teal.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColors.teal.withValues(alpha: 0.30)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded,
                color: AppColors.teal.withValues(alpha: 0.80),
                size: 18),
            const SizedBox(width: 10),
            Text(
              'You\'re subscribed!',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.teal.withValues(alpha: 0.90),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
    }

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'Enter your email address',
              hintStyle: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.30),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.10)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.10)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: AppColors.golden.withValues(alpha: 0.50),
                    width: 1.5),
              ),
            ),
            onSubmitted: (_) => _subscribe(),
          ),
        ),
        const SizedBox(width: 10),
        _SubscribeButton(onTap: _subscribe),
      ],
    );
  }
}

class _SubscribeButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SubscribeButton({required this.onTap});

  @override
  State<_SubscribeButton> createState() => _SubscribeButtonState();
}

class _SubscribeButtonState extends State<_SubscribeButton> {
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
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.golden, AppColors.warmEmber],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.golden.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: const Text(
            'Subscribe',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.navy,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated shimmer golden divider
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerDivider extends StatefulWidget {
  const _ShimmerDivider();

  @override
  State<_ShimmerDivider> createState() => _ShimmerDividerState();
}

class _ShimmerDividerState extends State<_ShimmerDivider>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _sweep;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _sweep = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sweep,
      builder: (_, __) {
        final t = _sweep.value;
        return Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppColors.golden.withValues(alpha: 0.20),
                AppColors.goldSheen.withValues(alpha: 0.80),
                AppColors.golden.withValues(alpha: 0.20),
                Colors.transparent,
              ],
              stops: [
                0.0,
                (t - 0.3).clamp(0.0, 1.0),
                t.clamp(0.0, 1.0),
                (t + 0.3).clamp(0.0, 1.0),
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Innovation stats strip
// ─────────────────────────────────────────────────────────────────────────────

class _StatsStrip extends StatelessWidget {
  const _StatsStrip();

  static const _stats = [
    {'value': '500+', 'label': 'Innovations'},
    {'value': '120+', 'label': 'Innovators'},
    {'value': '15', 'label': 'Universities'},
    {'value': '6', 'label': 'Sectors'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
      child: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;
        if (!isWide) {
          // Compact 2x2 grid on narrow screens
          return Wrap(
            spacing: 0,
            runSpacing: 12,
            children: _stats.map((s) => SizedBox(
              width: constraints.maxWidth / 2,
              child: _StatItem(value: s['value']!, label: s['label']!),
            )).toList(),
          );
        }
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < _stats.length; i++) ...[
              Expanded(
                child: _StatItem(
                  value: _stats[i]['value']!,
                  label: _stats[i]['label']!,
                ),
              ),
              if (i < _stats.length - 1)
                Container(
                  width: 1,
                  height: 32,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
            ],
          ],
        );
      }),
    ).animate().fadeIn(duration: 700.ms, delay: 100.ms);
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.golden, AppColors.warmEmber],
          ).createShader(bounds),
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.40),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Brand column
// ─────────────────────────────────────────────────────────────────────────────

class _BrandColumn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset('assets/images/logo/final-logo.png', height: 36),
            const SizedBox(width: 10),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.golden, AppColors.warmEmber],
              ).createShader(bounds),
              child: const Text(
                'HIRAYA',
=======
              Image.asset('assets/images/logo/final-logo.png', height: 36),
              const SizedBox(width: 12),
              const Text(
                'DIGITAL PLATFORM',
>>>>>>> origin/master
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Where Filipino Innovation Soars',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: AppColors.golden.withValues(alpha: 0.55),
            letterSpacing: 0.3,
          ),
<<<<<<< HEAD
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: 260,
          child: Text(
            'The Philippine Innovation Marketplace — connecting Filipino innovators with the world.',
=======
          const SizedBox(height: 20),
          const Text(
            '© 2026  DIGITAL PLATFORM. Department of Science and Technology. All rights reserved.',
>>>>>>> origin/master
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white.withValues(alpha: 0.38),
              fontSize: 13,
              height: 1.65,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Compliance badges
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _BadgeChip(icon: Icons.language_rounded, label: 'DOST'),
            _BadgeChip(icon: Icons.shield_rounded, label: 'RA 10173'),
            _BadgeChip(icon: Icons.verified_rounded, label: 'DICT'),
          ],
        ),
      ],
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BadgeChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: Colors.white.withValues(alpha: 0.35), size: 13),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white.withValues(alpha: 0.40),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Links row — Platform, Account, Resources, Support, Legal
// ─────────────────────────────────────────────────────────────────────────────

class _LinksRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 560;
      if (isWide) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildGroups(context),
        );
      }
      // Wrap into 2 columns on narrow
      return Wrap(
        spacing: 32,
        runSpacing: 28,
        children: _buildGroups(context)
            .map((w) => SizedBox(width: 130, child: w))
            .toList(),
      );
    });
  }

  List<Widget> _buildGroups(BuildContext context) {
    return [
      _FooterLinkGroup(
        title: 'Platform',
        links: [
          _FooterLink(
              label: 'Marketplace',
              onTap: () => context.go('/marketplace')),
          const _FooterLink(label: 'Innovations'),
          const _FooterLink(label: 'Innovators'),
        ],
      ),
      _FooterLinkGroup(
        title: 'Account',
        links: [
          _FooterLink(
              label: 'Sign In', onTap: () => context.go('/login')),
          _FooterLink(
              label: 'Register', onTap: () => context.go('/signup')),
        ],
      ),
      const _FooterLinkGroup(
        title: 'Resources',
        links: [
          _FooterLink(label: 'Blog'),
          _FooterLink(label: 'Case Studies'),
          _FooterLink(label: 'API Docs'),
        ],
      ),
      const _FooterLinkGroup(
        title: 'Support',
        links: [
          _FooterLink(label: 'Help Center'),
          _FooterLink(label: 'Contact Us'),
          _FooterLink(label: 'Report Issue'),
        ],
      ),
      const _FooterLinkGroup(
        title: 'Legal',
        links: [
          _FooterLink(label: 'Privacy Policy'),
          _FooterLink(label: 'Terms of Use'),
        ],
      ),
    ];
  }
}

class _FooterLinkGroup extends StatelessWidget {
  final String title;
  final List<_FooterLink> links;
  const _FooterLinkGroup(
      {required this.title, required this.links});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.golden.withValues(alpha: 0.70),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        ...links,
      ],
    );
  }
}

class _FooterLink extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  const _FooterLink({required this.label, this.onTap});

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: _hovered
                  ? AppColors.golden
                  : Colors.white.withValues(alpha: 0.40),
              fontWeight:
                  _hovered ? FontWeight.w600 : FontWeight.w400,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// University partner logos row (text-only badges)
// ─────────────────────────────────────────────────────────────────────────────

class _PartnerLogosRow extends StatelessWidget {
  const _PartnerLogosRow();

  static const _partners = [
    'UP Diliman',
    'DLSU',
    'ADMU',
    'UST',
    'MAPUA',
    'UPLB',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'UNIVERSITY PARTNERS',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: Colors.white.withValues(alpha: 0.25),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: _partners.map((p) => _PartnerBadge(name: p)).toList(),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms);
  }
}

class _PartnerBadge extends StatefulWidget {
  final String name;
  const _PartnerBadge({required this.name});

  @override
  State<_PartnerBadge> createState() => _PartnerBadgeState();
}

class _PartnerBadgeState extends State<_PartnerBadge> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: _hovered
              ? AppColors.golden.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered
                ? AppColors.golden.withValues(alpha: 0.30)
                : Colors.white.withValues(alpha: 0.07),
          ),
        ),
        child: Text(
          widget.name,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _hovered
                ? AppColors.golden.withValues(alpha: 0.90)
                : Colors.white.withValues(alpha: 0.30),
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Social media row
// ─────────────────────────────────────────────────────────────────────────────

class _SocialRow extends StatelessWidget {
  const _SocialRow();

  static const _socials = [
    {'icon': Icons.facebook_rounded, 'label': 'Facebook'},
    {'icon': Icons.alternate_email_rounded, 'label': 'Twitter / X'},
    {'icon': Icons.work_outline_rounded, 'label': 'LinkedIn'},
    {'icon': Icons.camera_alt_outlined, 'label': 'Instagram'},
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _socials.map((s) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _SocialIcon(
            icon: s['icon'] as IconData,
            label: s['label'] as String,
          ),
        );
      }).toList(),
    ).animate().fadeIn(duration: 600.ms, delay: 250.ms);
  }
}

class _SocialIcon extends StatefulWidget {
  final IconData icon;
  final String label;
  const _SocialIcon({required this.icon, required this.label});

  @override
  State<_SocialIcon> createState() => _SocialIconState();
}

class _SocialIconState extends State<_SocialIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.label,
      textStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        color: Colors.white,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.golden.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.04),
            shape: BoxShape.circle,
            border: Border.all(
              color: _hovered
                  ? AppColors.golden.withValues(alpha: 0.40)
                  : Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.golden.withValues(alpha: 0.20),
                      blurRadius: 12,
                    )
                  ]
                : [],
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: _hovered
                ? AppColors.golden
                : Colors.white.withValues(alpha: 0.40),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 560;
      return isWide
          ? Row(
              children: [
                // Made in PH badge
                _MadeInPHBadge(),
                const Spacer(),
                Text(
                  '© 2026 HIRAYA. All rights reserved.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white.withValues(alpha: 0.28),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Department of Science and Technology',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white.withValues(alpha: 0.18),
                    fontSize: 11,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _MadeInPHBadge(),
                const SizedBox(height: 10),
                Text(
                  '© 2026 HIRAYA. All rights reserved.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white.withValues(alpha: 0.28),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Department of Science and Technology',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white.withValues(alpha: 0.18),
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            );
    }).animate().fadeIn(duration: 500.ms, delay: 300.ms);
  }
}

class _MadeInPHBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '\u{1F1F5}\u{1F1ED}',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 6),
          Text(
            'Made in the Philippines',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.38),
            ),
          ),
        ],
      ),
    );
  }
}
