import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class CtaSection extends StatefulWidget {
  const CtaSection({super.key});

  @override
  State<CtaSection> createState() => _CtaSectionState();
}

class _CtaSectionState extends State<CtaSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _orbCtrl;

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _orbCtrl,
      builder: (_, child) {
        final t = _orbCtrl.value;
        return Container(
          width: double.infinity,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.richNavy,
                AppColors.deepVoid,
                Color(0xFF0A1A2E),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Golden orb — top right
              Positioned(
                right: -60 + t * 30,
                top: -80 + t * 40,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.golden.withValues(alpha: 0.12),
                        blurRadius: 200,
                        spreadRadius: 40,
                      ),
                    ],
                  ),
                ),
              ),
              // Teal orb — bottom left
              Positioned(
                left: -40 + t * 20,
                bottom: -60 + t * 30,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.10),
                        blurRadius: 160,
                        spreadRadius: 30,
                      ),
                    ],
                  ),
                ),
              ),
              // Border top line
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.golden.withValues(alpha: 0.40),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 32),
        child: Column(
          children: [
            // Eyebrow
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.golden.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.golden.withValues(alpha: 0.30),
                ),
              ),
              child: const Text(
                'JOIN THE MOVEMENT',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.golden,
                  letterSpacing: 2,
                ),
              ),
            ).animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 24),

            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.white, AppColors.golden, Colors.white],
                stops: [0.0, 0.5, 1.0],
              ).createShader(bounds),
              child: const Text(
                'Ready to Showcase\nYour Innovation?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 100.ms)
                .slideY(begin: 0.15, end: 0),

            const SizedBox(height: 20),

            Text(
              'Join hundreds of Filipino innovators on HIRAYA.\nYour next big idea deserves a global audience.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontFamily: 'Poppins',
                fontSize: 16,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

            const SizedBox(height: 48),

            // CTA buttons
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _CtaButton(
                  label: 'Create Your Account',
                  icon: Icons.rocket_launch_rounded,
                  isGolden: true,
                  onTap: () => context.go('/signup'),
                ),
                _CtaButton(
                  label: 'Explore Marketplace',
                  icon: Icons.storefront_rounded,
                  isGolden: false,
                  onTap: () => context.go('/marketplace'),
                ),
              ],
            )
                .animate(delay: 350.ms)
                .fadeIn(duration: 500.ms)
                .scale(begin: const Offset(0.93, 0.93)),

            const SizedBox(height: 48),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CtaStat(value: '120+', label: 'Innovators', color: AppColors.teal),
                _CtaDivider(),
                _CtaStat(value: '6', label: 'Sectors', color: AppColors.golden),
                _CtaDivider(),
                _CtaStat(value: '🇵🇭', label: 'Nationwide', color: AppColors.sky, isEmoji: true),
              ],
            ).animate(delay: 500.ms).fadeIn(duration: 500.ms),
          ],
        ),
      ),
    );
  }
}

class _CtaButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isGolden;
  final VoidCallback onTap;

  const _CtaButton({
    required this.label,
    required this.icon,
    required this.isGolden,
    required this.onTap,
  });

  @override
  State<_CtaButton> createState() => _CtaButtonState();
}

class _CtaButtonState extends State<_CtaButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          decoration: BoxDecoration(
            gradient: widget.isGolden
                ? const LinearGradient(
                    colors: [AppColors.golden, AppColors.warmEmber],
                  )
                : null,
            color: widget.isGolden
                ? null
                : Colors.white.withValues(alpha: _hovered ? 0.10 : 0.06),
            borderRadius: BorderRadius.circular(14),
            border: widget.isGolden
                ? null
                : Border.all(
                    color: Colors.white.withValues(alpha: _hovered ? 0.30 : 0.15),
                    width: 1.5,
                  ),
            boxShadow: widget.isGolden && _hovered
                ? [
                    BoxShadow(
                      color: AppColors.golden.withValues(alpha: 0.45),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    )
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.isGolden ? AppColors.navy : Colors.white,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: widget.isGolden ? AppColors.navy : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CtaStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final bool isEmoji;

  const _CtaStat({
    required this.value,
    required this.label,
    required this.color,
    this.isEmoji = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        isEmoji
            ? Text(value, style: const TextStyle(fontSize: 28))
            : Text(
                value,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: color,
                  height: 1,
                ),
              ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
      ],
    );
  }
}

class _CtaDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 28),
      color: Colors.white.withValues(alpha: 0.10),
    );
  }
}
