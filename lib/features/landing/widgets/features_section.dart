import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  static const List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.verified_user_rounded,
      'title': 'Verified Innovators',
      'desc': 'KYC-verified profiles you can trust. Every innovator is identity-confirmed before listing.',
      'color': AppColors.teal,
      'tag': 'Trust',
    },
    {
      'icon': Icons.message_rounded,
      'title': 'Direct Messaging',
      'desc': 'Connect privately with innovators. No shared contacts — safe and in-platform.',
      'color': AppColors.sky,
      'tag': 'Connect',
    },
    {
      'icon': Icons.trending_up_rounded,
      'title': 'Smart Discovery',
      'desc': 'Trending products, advanced filters, and category-based discovery tools at your fingertips.',
      'color': AppColors.crimson,
      'tag': 'Discover',
    },
    {
      'icon': Icons.shield_rounded,
      'title': 'RA 10173 Compliant',
      'desc': 'Your data is protected under the Philippine Data Privacy Act. Always secure.',
      'color': AppColors.golden,
      'tag': 'Secure',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      // Dark section for cinematic contrast
      color: AppColors.navy,
      padding: const EdgeInsets.symmetric(vertical: 88, horizontal: 24),
      child: Column(
        children: [
          // Section header
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.teal.withValues(alpha: 0.30)),
                ),
                child: const Text(
                  'WHY HIRAYA',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teal,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Built for Filipino Innovators',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Every feature is designed to empower local innovation and connect it with opportunity.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  color: Colors.white54,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.15, end: 0),

          const SizedBox(height: 56),

          LayoutBuilder(builder: (context, constraints) {
            final crossCount = constraints.maxWidth > 700 ? 4 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossCount,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
                childAspectRatio: 0.88,
              ),
              itemCount: _features.length,
              itemBuilder: (context, index) {
                final f = _features[index];
                return _FeatureCard(
                  icon: f['icon'] as IconData,
                  title: f['title'] as String,
                  desc: f['desc'] as String,
                  color: f['color'] as Color,
                  tag: f['tag'] as String,
                  index: index,
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  final String tag;
  final int index;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
    required this.tag,
    required this.index,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translate(0.0, _hovered ? -5.0 : 0.0),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: _hovered
              ? const Color(0xFF06293F)
              : const Color(0xFF042235),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered
                ? widget.color.withValues(alpha: 0.45)
                : Colors.white.withValues(alpha: 0.07),
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.20),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: _hovered ? 0.22 : 0.13),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(widget.icon,
                      color: widget.color,
                      size: _hovered ? 30 : 26),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.tag.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: widget.color,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              widget.title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
                color: _hovered ? Colors.white : Colors.white.withValues(alpha: 0.90),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.desc,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12.5,
                color: _hovered
                    ? Colors.white60
                    : Colors.white.withValues(alpha: 0.38),
                height: 1.6,
              ),
            ),
            const Spacer(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 2,
              width: _hovered ? 40 : 18,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 80 * widget.index))
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.18, end: 0, curve: Curves.easeOutCubic);
  }
}