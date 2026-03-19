import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LandingFooter — Complete redesign (Task VII)
// Wave divider • Newsletter strip • Animated stats bar • 4-column links
// Partner marquee • Shimmer divider • Bottom bar with language selector
// ─────────────────────────────────────────────────────────────────────────────

class LandingFooter extends StatelessWidget {
  const LandingFooter({super.key});

  static double _hPad(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return 40;
    if (width >= 860) return 28;
    return 20;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _PhilippineMapPainter())),
        Column(
          children: [
            const _WaveDivider(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF020508),
                    AppColors.richNavy.withValues(alpha: 0.50),
                    const Color(0xFF020509),
                  ],
                ),
              ),
              child: Column(
                children: [
                  const _NewsletterStrip(),
                  const _StatsBar(),
                  Container(
                    height: 1,
                    margin: EdgeInsets.symmetric(horizontal: _hPad(context)),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.white.withValues(alpha: 0.06), Colors.transparent],
                      ),
                    ),
                  ),
                  const _MainContent(),
                  const _PartnerStrip(),
                  const SizedBox(height: 12),
                  const _ShimmerDivider(),
                  const SizedBox(height: 24),
                  const _BottomBar(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WaveDivider extends StatelessWidget {
  const _WaveDivider();

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF020508), AppColors.richNavy.withValues(alpha: 0.80), const Color(0xFF020508)],
          ),
        ),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.55);
    path.cubicTo(size.width * 0.15, size.height * 0.10, size.width * 0.30, size.height * 1.00, size.width * 0.50, size.height * 0.50);
    path.cubicTo(size.width * 0.70, size.height * 0.00, size.width * 0.85, size.height * 0.90, size.width, size.height * 0.45);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _PhilippineMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.golden.withValues(alpha: 0.022)
      ..style = PaintingStyle.fill;
    final cx = size.width * 0.82;
    final cy = size.height * 0.42;
    final luzon = Path()
      ..moveTo(cx, cy - size.height * 0.28)
      ..cubicTo(cx + size.width * 0.04, cy - size.height * 0.22, cx + size.width * 0.06, cy - size.height * 0.10, cx + size.width * 0.03, cy - size.height * 0.02)
      ..cubicTo(cx + size.width * 0.01, cy + size.height * 0.04, cx - size.width * 0.03, cy + size.height * 0.05, cx - size.width * 0.02, cy - size.height * 0.04)
      ..cubicTo(cx - size.width * 0.05, cy - size.height * 0.12, cx - size.width * 0.04, cy - size.height * 0.22, cx, cy - size.height * 0.28)
      ..close();
    canvas.drawPath(luzon, paint);
    final visayas = Path()
      ..moveTo(cx - size.width * 0.04, cy + size.height * 0.07)
      ..cubicTo(cx, cy + size.height * 0.06, cx + size.width * 0.05, cy + size.height * 0.09, cx + size.width * 0.02, cy + size.height * 0.14)
      ..cubicTo(cx - size.width * 0.01, cy + size.height * 0.16, cx - size.width * 0.06, cy + size.height * 0.13, cx - size.width * 0.04, cy + size.height * 0.07)
      ..close();
    canvas.drawPath(visayas, paint);
    final mindanao = Path()
      ..moveTo(cx - size.width * 0.03, cy + size.height * 0.18)
      ..cubicTo(cx + size.width * 0.04, cy + size.height * 0.17, cx + size.width * 0.07, cy + size.height * 0.27, cx + size.width * 0.02, cy + size.height * 0.33)
      ..cubicTo(cx - size.width * 0.03, cy + size.height * 0.35, cx - size.width * 0.08, cy + size.height * 0.28, cx - size.width * 0.03, cy + size.height * 0.18)
      ..close();
    canvas.drawPath(mindanao, paint);
    final dotPaint = Paint()..color = AppColors.teal.withValues(alpha: 0.06)..style = PaintingStyle.fill;
    for (final pos in [[0.78, 0.30], [0.80, 0.38], [0.76, 0.50], [0.81, 0.58], [0.79, 0.66], [0.83, 0.45]]) {
      canvas.drawCircle(Offset(size.width * pos[0], size.height * pos[1]), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Newsletter Strip
// ─────────────────────────────────────────────────────────────────────────────

class _NewsletterStrip extends StatefulWidget {
  const _NewsletterStrip();

  @override
  State<_NewsletterStrip> createState() => _NewsletterStripState();
}

class _NewsletterStripState extends State<_NewsletterStrip> {
  final _emailController = TextEditingController();
  final _focusNode = FocusNode();
  bool _focused = false;
  bool _submitted = false;
  bool _buttonHovered = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _focused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _subscribe() {
    if (_emailController.text.trim().isNotEmpty) setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPad = LandingFooter._hPad(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 48, horizontal: horizontalPad),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.richNavy.withValues(alpha: 0.90), AppColors.deepVoid.withValues(alpha: 0.98), AppColors.richNavy.withValues(alpha: 0.70)],
        ),
        border: Border(bottom: BorderSide(color: AppColors.golden.withValues(alpha: 0.06))),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          return isWide
              ? Row(children: [Expanded(flex: 2, child: _buildHeading()), const SizedBox(width: 48), Expanded(flex: 3, child: _buildForm())])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildHeading(), const SizedBox(height: 28), _buildForm()]);
        },
      ),
    ).animate().fadeIn(duration: 700.ms, curve: Curves.easeOutCubic).slideY(begin: 0.08, curve: Curves.easeOutCubic);
  }

  Widget _buildHeading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 36, height: 3, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.golden, AppColors.warmEmber]), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 14),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(colors: [AppColors.golden, AppColors.warmEmber]).createShader(bounds),
          child: const Text('Stay Updated on\nFilipino Innovations', style: TextStyle(fontFamily: 'Poppins', fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5, height: 1.25)),
        ),
        const SizedBox(height: 12),
        Text('Get the latest breakthroughs, innovation spotlights,\nand platform updates delivered to your inbox.',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white.withValues(alpha: 0.42), height: 1.70)),
      ],
    );
  }

  Widget _buildForm() {
    if (_submitted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.teal.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.teal.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.teal.withValues(alpha: 0.85), size: 20),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("You're in!", style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.teal.withValues(alpha: 0.90))),
              Text('Thank you for subscribing to Digital Platform.', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white.withValues(alpha: 0.40))),
            ])),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.96, 0.96), curve: Curves.easeOutCubic);
    }

    return Row(
      children: [
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: _focused ? 0.07 : 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _focused ? AppColors.teal.withValues(alpha: 0.50) : Colors.white.withValues(alpha: 0.09), width: _focused ? 1.5 : 1.0),
              boxShadow: _focused ? [BoxShadow(color: AppColors.teal.withValues(alpha: 0.10), blurRadius: 14, spreadRadius: 1)] : [],
            ),
            child: TextField(
              controller: _emailController,
              focusNode: _focusNode,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter your email address',
                hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white.withValues(alpha: 0.28)),
                prefixIcon: Icon(Icons.mail_outline_rounded, color: _focused ? AppColors.teal.withValues(alpha: 0.70) : Colors.white.withValues(alpha: 0.25), size: 18),
                filled: false,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
              ),
              onSubmitted: (_) => _subscribe(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _SubscribeButton(hovered: _buttonHovered, onHoverChange: (v) => setState(() => _buttonHovered = v), onTap: _subscribe),
      ],
    );
  }
}

class _SubscribeButton extends StatelessWidget {
  final bool hovered;
  final ValueChanged<bool> onHoverChange;
  final VoidCallback onTap;
  const _SubscribeButton({required this.hovered, required this.onHoverChange, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => onHoverChange(true),
      onExit: (_) => onHoverChange(false),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: hovered ? 26 : 22, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.golden, AppColors.warmEmber]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: hovered
                ? [BoxShadow(color: AppColors.golden.withValues(alpha: 0.40), blurRadius: 20, offset: const Offset(0, 6))]
                : [BoxShadow(color: AppColors.golden.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Subscribe', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.navy)),
              if (hovered) ...[const SizedBox(width: 6), const Icon(Icons.arrow_forward_rounded, color: AppColors.navy, size: 16)],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Bar
// ─────────────────────────────────────────────────────────────────────────────

class _StatsBar extends StatefulWidget {
  const _StatsBar();

  @override
  State<_StatsBar> createState() => _StatsBarState();
}

class _StatsBarState extends State<_StatsBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  static const _stats = [
    {'target': 1200, 'suffix': '+', 'label': 'Innovators'},
    {'target': 50, 'suffix': '+', 'label': 'Universities'},
    {'target': 6, 'suffix': '', 'label': 'Categories'},
    {'target': 10000, 'suffix': '+', 'label': 'Connections'},
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 400), () { if (mounted) _ctrl.forward(); });
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final horizontalPad = LandingFooter._hPad(context);
    return Container(
      padding: EdgeInsets.symmetric(vertical: 28, horizontal: horizontalPad),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 560;
          if (!isWide) {
            return Wrap(
              spacing: 0, runSpacing: 16,
              children: List.generate(_stats.length, (i) => SizedBox(
                width: constraints.maxWidth / 2,
                child: _AnimatedStatItem(controller: _ctrl, target: _stats[i]['target'] as int, suffix: _stats[i]['suffix'] as String, label: _stats[i]['label'] as String, delay: i * 0.12),
              )),
            );
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < _stats.length; i++) ...[
                Expanded(child: _AnimatedStatItem(controller: _ctrl, target: _stats[i]['target'] as int, suffix: _stats[i]['suffix'] as String, label: _stats[i]['label'] as String, delay: i * 0.12)),
                if (i < _stats.length - 1) _DiamondSeparator(),
              ],
            ],
          );
        },
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 100.ms, curve: Curves.easeOutCubic);
  }
}

class _AnimatedStatItem extends StatelessWidget {
  final AnimationController controller;
  final int target;
  final String suffix;
  final String label;
  final double delay;
  const _AnimatedStatItem({required this.controller, required this.target, required this.suffix, required this.label, required this.delay});

  @override
  Widget build(BuildContext context) {
    final delayedAnim = CurvedAnimation(parent: controller, curve: Interval(delay, math.min(delay + 0.6, 1.0), curve: Curves.easeOutCubic));
    return AnimatedBuilder(
      animation: delayedAnim,
      builder: (context, _) {
        final current = (target * delayedAnim.value).round();
        final displayValue = target >= 1000 ? '${(current / 1000).toStringAsFixed(current >= 1000 ? 0 : 1)}K' : '$current';
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(colors: [AppColors.golden, AppColors.warmEmber]).createShader(bounds),
              child: Text('$displayValue$suffix', style: const TextStyle(fontFamily: 'Poppins', fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.0)),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.38), letterSpacing: 0.5)),
          ],
        );
      },
    );
  }
}

class _DiamondSeparator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(width: 6, height: 6, margin: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: AppColors.golden.withValues(alpha: 0.40), borderRadius: BorderRadius.circular(1))),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Content
// ─────────────────────────────────────────────────────────────────────────────

class _MainContent extends StatelessWidget {
  const _MainContent();

  @override
  Widget build(BuildContext context) {
    final horizontalPad = LandingFooter._hPad(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 56, horizontal: horizontalPad),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          final isMedium = constraints.maxWidth > 520;
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 260, child: _BrandColumn()),
                const SizedBox(width: 40),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [_buildPlatformColumn(context), _buildCompanyColumn(context), _buildLegalColumn(context)],
                  ),
                ),
              ],
            );
          } else if (isMedium) {
            return Column(
              children: [
                _BrandColumn(),
                const SizedBox(height: 40),
                Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildPlatformColumn(context), _buildCompanyColumn(context), _buildLegalColumn(context)]),
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_BrandColumn(), const SizedBox(height: 40), _buildPlatformColumn(context), const SizedBox(height: 32), _buildCompanyColumn(context), const SizedBox(height: 32), _buildLegalColumn(context)],
            );
          }
        },
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 150.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildPlatformColumn(BuildContext context) => _FooterLinkGroup(
    title: 'Platform',
    links: [
      _FooterLink(label: 'Marketplace', onTap: () => context.go('/marketplace')),
      _FooterLink(label: 'Browse Innovations', onTap: () => context.go('/marketplace')),
      const _FooterLink(label: 'Featured'),
      const _FooterLink(label: 'Categories'),
    ],
  );

  Widget _buildCompanyColumn(BuildContext context) => const _FooterLinkGroup(
    title: 'Company',
    links: [
      _FooterLink(label: 'About Us'), _FooterLink(label: 'How It Works'),
      _FooterLink(label: 'Blog'), _FooterLink(label: 'Press Kit'), _FooterLink(label: 'Careers'),
    ],
  );

  Widget _buildLegalColumn(BuildContext context) => const _FooterLinkGroup(
    title: 'Legal & Support',
    links: [
      _FooterLink(label: 'Privacy Policy'), _FooterLink(label: 'Terms of Service'),
      _FooterLink(label: 'Cookie Policy'), _FooterLink(label: 'Help Center'), _FooterLink(label: 'Contact'),
    ],
  );
}

class _BrandColumn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.golden, AppColors.warmEmber]),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: AppColors.golden.withValues(alpha: 0.25), blurRadius: 12)],
              ),
              child: const Center(child: Text('DP', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.navy, letterSpacing: 0.5))),
            ),
            const SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(colors: [AppColors.golden, AppColors.warmEmber]).createShader(bounds),
              child: const Text('Digital Platform', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text('Where Filipino Innovation Soars', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.golden.withValues(alpha: 0.60), letterSpacing: 0.3)),
        const SizedBox(height: 6),
        const Text('Proudly Made in the Philippines 🇵🇭', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0x66FFFFFF), letterSpacing: 0.2)),
        const SizedBox(height: 20),
        SizedBox(width: 240, child: Text('The premier innovation marketplace connecting Filipino inventors, researchers, and enterprise clients.',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white.withValues(alpha: 0.33), height: 1.70))),
        const SizedBox(height: 24),
        const _SocialIconsRow(),
        const SizedBox(height: 24),
        const _OfficialContactPanel(),
        const SizedBox(height: 20),
        _AppBadges(),
      ],
    );
  }
}

class _SocialIconsRow extends StatelessWidget {
  const _SocialIconsRow();

  static const _socials = [
    {
      'icon': Icons.facebook_rounded,
      'label': 'DOST NorMin Facebook',
      'color': Color(0xFF1877F2),
      'url': 'https://facebook.com/DOSTNorMinPH'
    },
    {
      'icon': Icons.language_rounded,
      'label': 'DOST Region X Website',
      'color': Color(0xFF3F88C5),
      'url': 'https://region10.dost.gov.ph/'
    },
    {
      'icon': Icons.mail_outline_rounded,
      'label': 'Message Us',
      'color': Color(0xFF136F63),
      'url': 'mailto:dmbalanayjr@region10.dost.gov.ph'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _socials.map((s) => Padding(
        padding: const EdgeInsets.only(right: 10),
        child: _SocialIconButton(
          icon: s['icon'] as IconData,
          label: s['label'] as String,
          hoverColor: s['color'] as Color,
          url: s['url'] as String,
        ),
      )).toList(),
    );
  }
}

class _SocialIconButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color hoverColor;
  final String url;
  const _SocialIconButton({required this.icon, required this.label, required this.hoverColor, required this.url});

  @override
  State<_SocialIconButton> createState() => _SocialIconButtonState();
}

class _SocialIconButtonState extends State<_SocialIconButton> with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.20).animate(CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() { _scaleCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.label,
      textStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) { setState(() => _hovered = true); _scaleCtrl.forward(); },
        onExit: (_) { setState(() => _hovered = false); _scaleCtrl.reverse(); },
        child: ScaleTransition(
          scale: _scaleAnim,
          child: GestureDetector(
            onTap: () => launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: _hovered ? widget.hoverColor.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
                border: Border.all(color: _hovered ? widget.hoverColor.withValues(alpha: 0.50) : Colors.white.withValues(alpha: 0.08)),
                boxShadow: _hovered ? [BoxShadow(color: widget.hoverColor.withValues(alpha: 0.25), blurRadius: 14, spreadRadius: 1)] : [],
              ),
              child: Icon(widget.icon, size: 17, color: _hovered ? widget.hoverColor : Colors.white.withValues(alpha: 0.38)),
            ),
          ),
        ),
      ),
    );
  }
}

class _OfficialContactPanel extends StatelessWidget {
  const _OfficialContactPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DOST Region X Contact',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.golden,
            ),
          ),
          const SizedBox(height: 8),
          _ContactLine(
            icon: Icons.mail_outline_rounded,
            label: 'dmbalanayjr@region10.dost.gov.ph',
            onTap: () => launchUrl(Uri.parse('mailto:dmbalanayjr@region10.dost.gov.ph')),
          ),
          _ContactLine(
            icon: Icons.alternate_email_rounded,
            label: 'digitalplatform@region10.dost.gov.ph',
            onTap: () => launchUrl(Uri.parse('mailto:digitalplatform@region10.dost.gov.ph')),
          ),
          _ContactLine(
            icon: Icons.phone_rounded,
            label: '0917 857 9186',
            onTap: () => launchUrl(Uri.parse('tel:09178579186')),
          ),
          _ContactLine(
            icon: Icons.location_on_outlined,
            label: 'J.V. Seriña St., Carmen, Cagayan de Oro City, Misamis Oriental, Philippines',
            onTap: () => launchUrl(Uri.parse('https://maps.google.com/?q=J.V.+Serina+St.,+Carmen,+Cagayan+de+Oro+City')),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => launchUrl(Uri.parse('mailto:dmbalanayjr@region10.dost.gov.ph')),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.golden, AppColors.warmEmber]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 14, color: AppColors.navy),
                  SizedBox(width: 6),
                  Text(
                    'Message Us',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.12, end: 0);
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.55)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.58),
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBadges extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 10, runSpacing: 10,
      children: [
        _AppBadge(icon: Icons.apple_rounded, label: 'App Store', sub: 'Download on the'),
        _AppBadge(icon: Icons.android_rounded, label: 'Google Play', sub: 'Get it on'),
      ],
    );
  }
}

class _AppBadge extends StatefulWidget {
  final IconData icon;
  final String label;
  final String sub;
  const _AppBadge({required this.icon, required this.label, required this.sub});

  @override
  State<_AppBadge> createState() => _AppBadgeState();
}

class _AppBadgeState extends State<_AppBadge> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: _hovered ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _hovered ? Colors.white.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.09)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: Colors.white.withValues(alpha: 0.60), size: 20),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.sub, style: TextStyle(fontFamily: 'Poppins', fontSize: 9, color: Colors.white.withValues(alpha: 0.38), letterSpacing: 0.2)),
              Text(widget.label, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.75))),
            ]),
          ],
        ),
      ),
    );
  }
}

class _FooterLinkGroup extends StatelessWidget {
  final String title;
  final List<_FooterLink> links;
  const _FooterLinkGroup({required this.title, required this.links});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 3, height: 14, decoration: BoxDecoration(gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.golden, AppColors.warmEmber]), borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title.toUpperCase(), style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.golden.withValues(alpha: 0.75), letterSpacing: 1.8)),
        ]),
        const SizedBox(height: 18),
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
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: _hovered ? (Matrix4.identity()..translateByDouble(4.0, 0, 0, 1)) : Matrix4.identity(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: _hovered ? Colors.white : Colors.white.withValues(alpha: 0.38), fontWeight: _hovered ? FontWeight.w500 : FontWeight.w400),
                  child: Text(widget.label),
                ),
                if (_hovered) ...[const SizedBox(width: 4), Container(height: 1, width: 12, decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.golden, AppColors.warmEmber])))],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Partner Strip
// ─────────────────────────────────────────────────────────────────────────────

class _PartnerStrip extends StatefulWidget {
  const _PartnerStrip();

  @override
  State<_PartnerStrip> createState() => _PartnerStripState();
}

class _PartnerStripState extends State<_PartnerStrip> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _autoScrollCtrl;

  static const _partners = ['UP Diliman', 'DLSU', 'Ateneo de Manila', 'UST', 'MAPÚA', 'UPLB', 'PUP', 'FEU Tech', 'DOST', 'DICT Philippines', 'DTI Philippines', 'UP Cebu'];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _autoScrollCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))
      ..addListener(_onAutoScroll)
      ..repeat();
  }

  void _onAutoScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;
    _scrollController.jumpTo(_autoScrollCtrl.value * maxScroll);
  }

  @override
  void dispose() {
    _autoScrollCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final horizontalPad = LandingFooter._hPad(context);
    return Column(
      children: [
        Text('TRUSTED BY', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2.5, color: Colors.white.withValues(alpha: 0.22))),
        const SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent], stops: const [0.0, 0.08, 0.92, 1.0]).createShader(bounds),
            blendMode: BlendMode.dstIn,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: horizontalPad),
              itemCount: _partners.length * 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _PartnerPill(name: _partners[index % _partners.length]),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    ).animate().fadeIn(duration: 600.ms, delay: 200.ms, curve: Curves.easeOutCubic);
  }
}

class _PartnerPill extends StatefulWidget {
  final String name;
  const _PartnerPill({required this.name});

  @override
  State<_PartnerPill> createState() => _PartnerPillState();
}

class _PartnerPillState extends State<_PartnerPill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.golden.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _hovered ? AppColors.golden.withValues(alpha: 0.32) : Colors.white.withValues(alpha: 0.07)),
        ),
        child: Text(widget.name, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: _hovered ? AppColors.golden.withValues(alpha: 0.90) : Colors.white.withValues(alpha: 0.28), letterSpacing: 0.3)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer Divider
// ─────────────────────────────────────────────────────────────────────────────

class _ShimmerDivider extends StatefulWidget {
  const _ShimmerDivider();

  @override
  State<_ShimmerDivider> createState() => _ShimmerDividerState();
}

class _ShimmerDividerState extends State<_ShimmerDivider> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final horizontalPad = LandingFooter._hPad(context);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Container(
          height: 1.5,
          margin: EdgeInsets.symmetric(horizontal: horizontalPad),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, AppColors.golden.withValues(alpha: 0.15), AppColors.goldSheen.withValues(alpha: 0.85), AppColors.warmEmber.withValues(alpha: 0.50), AppColors.golden.withValues(alpha: 0.15), Colors.transparent],
              stops: [0.0, (t - 0.25).clamp(0.0, 1.0), t.clamp(0.0, 1.0), (t + 0.05).clamp(0.0, 1.0), (t + 0.25).clamp(0.0, 1.0), 1.0],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar();

  @override
  Widget build(BuildContext context) {
    final horizontalPad = LandingFooter._hPad(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPad),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('© 2025 Digital Platform. All rights reserved.', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white.withValues(alpha: 0.28))),
                const Spacer(),
                const _MadeWithHeartBadge(),
                const Spacer(),
                const _LanguageSelector(),
              ],
            );
          }
          return Column(
            children: [
              const _MadeWithHeartBadge(),
              const SizedBox(height: 12),
              Text('© 2025 Digital Platform. All rights reserved.', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white.withValues(alpha: 0.25)), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const _LanguageSelector(),
            ],
          );
        },
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 300.ms, curve: Curves.easeOutCubic);
  }
}

class _MadeWithHeartBadge extends StatefulWidget {
  const _MadeWithHeartBadge();

  @override
  State<_MadeWithHeartBadge> createState() => _MadeWithHeartBadgeState();
}

class _MadeWithHeartBadgeState extends State<_MadeWithHeartBadge> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
  }

  @override
  void dispose() { _shimmerCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (context, _) {
        final t = _shimmerCtrl.value;
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft, end: Alignment.centerRight,
            colors: [Colors.white.withValues(alpha: 0.35), AppColors.golden.withValues(alpha: 0.90), AppColors.warmEmber.withValues(alpha: 0.80), Colors.white.withValues(alpha: 0.35)],
            stops: [0.0, (t - 0.15).clamp(0.0, 1.0), t.clamp(0.0, 1.0), 1.0],
          ).createShader(bounds),
          child: const Text('Made with ♥ in the Philippines', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 0.3)),
        );
      },
    );
  }
}

class _LanguageSelector extends StatefulWidget {
  const _LanguageSelector();

  @override
  State<_LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<_LanguageSelector> {
  String _selected = 'English';
  bool _hovered = false;
  static const _languages = ['English', 'Filipino'];

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: PopupMenuButton<String>(
        onSelected: (val) => setState(() => _selected = val),
        tooltip: 'Select language',
        color: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.borderDark)),
        itemBuilder: (context) => _languages.map((lang) => PopupMenuItem<String>(
          value: lang,
          child: Text(lang, style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: lang == _selected ? AppColors.golden : Colors.white.withValues(alpha: 0.75), fontWeight: lang == _selected ? FontWeight.w600 : FontWeight.w400)),
        )).toList(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered ? Colors.white.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _hovered ? Colors.white.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.language_rounded, size: 14, color: Colors.white.withValues(alpha: 0.45)),
              const SizedBox(width: 6),
              Text(_selected, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.55))),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Colors.white.withValues(alpha: 0.30)),
            ],
          ),
        ),
      ),
    );
  }
}
