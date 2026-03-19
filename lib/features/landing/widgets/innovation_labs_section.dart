import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

class InnovationLabsSection extends StatefulWidget {
  const InnovationLabsSection({super.key});

  @override
  State<InnovationLabsSection> createState() => _InnovationLabsSectionState();
}

class _InnovationLabsSectionState extends State<InnovationLabsSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  static const _labs = [
    (
      title: 'Prototype Sprint Lab',
      desc: 'Rapidly validate ideas with mentors, client brief matching, and milestone tracking in one creative workspace.',
      icon: Icons.rocket_launch_rounded,
      color: AppColors.golden,
      metric: '24h'
    ),
    (
      title: 'Impact Sandbox',
      desc: 'Simulate adoption impact by sector and region so teams can prioritize the highest-value innovation outcomes.',
      icon: Icons.insights_rounded,
      color: AppColors.teal,
      metric: '12 sectors'
    ),
    (
      title: 'Collaboration Studio',
      desc: 'A shared board for innovators, clients, and universities to align requirements, constraints, and next actions.',
      icon: Icons.hub_rounded,
      color: AppColors.sky,
      metric: 'Live sync'
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 900;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 80 : 24,
            vertical: isDesktop ? 76 : 52,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.deepVoid, Color(0xFF061224), AppColors.deepVoid],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: -90 + t * 30,
                top: 10 + t * 30,
                child: _glow(AppColors.golden.withValues(alpha: 0.08), 220),
              ),
              Positioned(
                right: -90 + (1 - t) * 36,
                bottom: -30 + t * 24,
                child: _glow(AppColors.teal.withValues(alpha: 0.08), 200),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [AppColors.golden, AppColors.warmEmber],
                    ).createShader(b),
                    child: const Text(
                      'INNOVATION LABS',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Designed for faster\ninnovation execution',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: isDesktop ? 40 : 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.15,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'A new interactive section that extends the Digital Platform landing experience with practical pathways from discovery to collaboration.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.48),
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 30),
                  LayoutBuilder(
                    builder: (context, c) {
                      if (c.maxWidth < 840) {
                        return Column(
                          children: [
                            for (var i = 0; i < _labs.length; i++) ...[
                              _LabCard(data: _labs[i], index: i),
                              if (i != _labs.length - 1) const SizedBox(height: 14),
                            ],
                          ],
                        );
                      }
                      return Row(
                        children: [
                          for (var i = 0; i < _labs.length; i++) ...[
                            Expanded(child: _LabCard(data: _labs[i], index: i)),
                            if (i != _labs.length - 1) const SizedBox(width: 14),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _glow(Color c, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: c, blurRadius: size * 0.5, spreadRadius: size * 0.2)],
        ),
      );
}

class _LabCard extends StatefulWidget {
  const _LabCard({required this.data, required this.index});

  final ({String title, String desc, IconData icon, Color color, String metric}) data;
  final int index;

  @override
  State<_LabCard> createState() => _LabCardState();
}

class _LabCardState extends State<_LabCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translate(0.0, _hover ? -8.0 : 0.0)
          ..rotateZ(_hover ? (math.pi / 540) : 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hover ? d.color.withValues(alpha: 0.55) : AppColors.borderDark,
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: (_hover ? d.color : Colors.black).withValues(alpha: _hover ? 0.22 : 0.28),
              blurRadius: _hover ? 28 : 12,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: d.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(d.icon, color: d.color, size: 22),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                  ),
                  child: Text(
                    d.metric,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: d.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              d.title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              d.desc,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.48),
                height: 1.65,
              ),
            ),
          ],
        ),
      ).animate(delay: (120 + widget.index * 140).ms).fadeIn(duration: 520.ms).slideY(begin: 0.16, end: 0),
    );
  }
}
