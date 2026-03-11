import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class LandingFooter extends StatelessWidget {
  const LandingFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    return Container(
      color: const Color(0xFF080E14),
      child: Column(
        children: [
          // Gradient divider
          Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.teal,
                  AppColors.golden,
                  AppColors.teal,
                  Colors.transparent,
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 40),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand column
                      Expanded(
                        flex: 2,
                        child: _BrandColumn(),
                      ),
                      const SizedBox(width: 48),
                      // Navigation column
                      const Expanded(
                        child: _FooterLinks(
                          title: 'Platform',
                          links: [
                            ('Marketplace', '/marketplace'),
                            ('Sign In', '/login'),
                            ('Create Account', '/signup'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Categories column
                      const Expanded(
                        child: _FooterLinks(
                          title: 'Categories',
                          links: [
                            ('Agriculture', null),
                            ('Healthcare', null),
                            ('Energy', null),
                            ('Construction', null),
                            ('Information Technology', null),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Legal column
                      const Expanded(
                        child: _FooterLinks(
                          title: 'Legal',
                          links: [
                            ('Privacy Policy', null),
                            ('Terms of Use', null),
                            ('RA 10173', null),
                            ('Contact Us', null),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BrandColumn(),
                      const SizedBox(height: 36),
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _FooterLinks(
                              title: 'Platform',
                              links: [
                                ('Marketplace', '/marketplace'),
                                ('Sign In', '/login'),
                                ('Create Account', '/signup'),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _FooterLinks(
                              title: 'Legal',
                              links: [
                                ('Privacy Policy', null),
                                ('Terms of Use', null),
                                ('Contact Us', null),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),

          // Gradient divider
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.06),
          ),

          // Bottom bar
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 8,
              children: [
                const Text(
                  '© 2026 HIRAYA · Department of Science and Technology · All rights reserved.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white24,
                    fontSize: 11.5,
                    letterSpacing: 0.2,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Made with  ',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white24,
                          fontSize: 11.5),
                    ),
                    const Icon(Icons.favorite_rounded,
                        color: AppColors.crimson, size: 13),
                    const Text(
                      '  for Filipino Innovators',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white24,
                          fontSize: 11.5),
                    ),
                  ],
                ),
                _BackToTopButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandColumn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset('assets/images/logo/final-logo.png', height: 38),
            const SizedBox(width: 10),
            const Text(
              'HIRAYA',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text(
          'Where Innovation\nMeets Opportunity.',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white38,
            fontSize: 13,
            height: 1.7,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 18),
        // Social icons
        Row(
          children: [
            _SocialIcon(icon: Icons.language_rounded),
            const SizedBox(width: 10),
            _SocialIcon(icon: Icons.alternate_email_rounded),
            const SizedBox(width: 10),
            _SocialIcon(icon: Icons.send_rounded),
          ],
        ),
        const SizedBox(height: 24),
        // Newsletter subscribe
        const _NewsletterRow(),
      ],
    );
  }
}

class _SocialIcon extends StatefulWidget {
  final IconData icon;
  const _SocialIcon({required this.icon});

  @override
  State<_SocialIcon> createState() => _SocialIconState();
}

class _SocialIconState extends State<_SocialIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _hovered
              ? AppColors.teal.withValues(alpha: 0.20)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: _hovered
                ? AppColors.teal.withValues(alpha: 0.50)
                : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Icon(
          widget.icon,
          size: 16,
          color: _hovered ? AppColors.teal : Colors.white38,
        ),
      ),
    );
  }
}

class _FooterLinks extends StatelessWidget {
  final String title;
  final List<(String, String?)> links;
  const _FooterLinks({required this.title, required this.links});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Colors.white38,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        ...links.map((l) => _FooterLink(label: l.$1, route: l.$2)),
      ],
    );
  }
}

class _FooterLink extends StatefulWidget {
  final String label;
  final String? route;
  const _FooterLink({required this.label, this.route});

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.route != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.route != null
            ? () => context.go(widget.route!)
            : null,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: _hovered ? Colors.white70 : Colors.white30,
              fontWeight:
                  _hovered ? FontWeight.w500 : FontWeight.w400,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}
// ═══════════════════════════════════════════════════════════
// Newsletter subscribe row
// ═══════════════════════════════════════════════════════════
class _NewsletterRow extends StatefulWidget {
  const _NewsletterRow();

  @override
  State<_NewsletterRow> createState() => _NewsletterRowState();
}

class _NewsletterRowState extends State<_NewsletterRow> {
  final TextEditingController _ctrl = TextEditingController();
  bool _submitted = false;
  bool _btnHovered = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.teal.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.teal.withValues(alpha: 0.35)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 16),
            SizedBox(width: 8),
            Text(
              'You\'re on the list!',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                color: AppColors.teal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'STAY UPDATED',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white38,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white70,
                    fontSize: 12.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'your@email.com',
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white.withValues(alpha: 0.25),
                      fontSize: 12.5,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _btnHovered = true),
              onExit: (_) => setState(() => _btnHovered = false),
              child: GestureDetector(
                onTap: _submit,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: _btnHovered
                        ? AppColors.teal
                        : AppColors.teal.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Center(
                    child: Text(
                      'Subscribe',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Back-to-top button
// ═══════════════════════════════════════════════════════════
class _BackToTopButton extends StatefulWidget {
  @override
  State<_BackToTopButton> createState() => _BackToTopButtonState();
}

class _BackToTopButtonState extends State<_BackToTopButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {
          // Scroll to the top via primary scroll controller if available
          final scrollable = PrimaryScrollController.maybeOf(context);
          scrollable?.animateTo(
            0,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOutCubic,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: _hovered ? 0.20 : 0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSlide(
                offset: _hovered
                    ? const Offset(0, -0.15)
                    : Offset.zero,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: Colors.white38,
                  size: 14,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Back to top',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Colors.white30,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
