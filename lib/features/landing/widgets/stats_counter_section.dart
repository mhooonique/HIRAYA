// lib/features/landing/widgets/stats_counter_section.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

// ═══════════════════════════════════════════════════════════
// StatsCounterSection — Animated platform statistics bar
// Count-up numbers • Golden separators • Glassmorphic cards
// ═══════════════════════════════════════════════════════════

class StatsCounterSection extends StatefulWidget {
  const StatsCounterSection({super.key});

  @override
  State<StatsCounterSection> createState() => _StatsCounterSectionState();
}

class _StatsCounterSectionState extends State<StatsCounterSection>
    with TickerProviderStateMixin {
  late AnimationController _counterCtrl;
  late Animation<double> _counterAnim;
  late AnimationController _orbCtrl;
  bool _hasAnimated = false;

  static const _stats = [
    _StatData(value: 500, suffix: '+', label: 'Innovations', icon: Icons.lightbulb_rounded, color: AppColors.golden),
    _StatData(value: 200, suffix: '+', label: 'Innovators', icon: Icons.people_rounded, color: AppColors.teal),
    _StatData(value: 15, suffix: '+', label: 'Universities', icon: Icons.school_rounded, color: AppColors.sky),
    _StatData(value: 6, suffix: '', label: 'Categories', icon: Icons.category_rounded, color: AppColors.warmEmber),
  ];

  @override
  void initState() {
    super.initState();
    _counterCtrl = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _counterAnim = CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOutCubic);
    _orbCtrl = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);

    // Auto-trigger after short delay (will also be triggered by scroll in real scenario)
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && !_hasAnimated) {
        _hasAnimated = true;
        _counterCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _counterCtrl.dispose();
    _orbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 900;

    return AnimatedBuilder(
      animation: _orbCtrl,
      builder: (_, __) {
        final t = _orbCtrl.value;
        return Container(
          width: double.infinity,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.richNavy, AppColors.midnight, AppColors.deepVoid],
            ),
          ),
          child: Stack(
            children: [
              // Ambient orbs
              Positioned(
                left: -50 + t * 30,
                top: -30 + t * 20,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.golden.withValues(alpha: 0.06),
                        blurRadius: 100,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: -40 + t * 25,
                bottom: -20 + t * 15,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.06),
                        blurRadius: 90,
                        spreadRadius: 15,
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 80 : 24,
                  vertical: isDesktop ? 56 : 40,
                ),
                child: isDesktop
                    ? _buildDesktopRow()
                    : _buildMobileGrid(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < _stats.length; i++) ...[
          Expanded(child: _StatItem(stat: _stats[i], anim: _counterAnim, index: i)),
          if (i < _stats.length - 1)
            _VerticalSeparator(),
        ],
      ],
    );
  }

  Widget _buildMobileGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: List.generate(
        _stats.length,
        (i) => _StatItem(stat: _stats[i], anim: _counterAnim, index: i),
      ),
    );
  }
}

// ── Vertical Separator ────────────────────────────────────────────────────
class _VerticalSeparator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.golden.withValues(alpha: 0.35),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

// ── Stat Data ─────────────────────────────────────────────────────────────
class _StatData {
  final int value;
  final String suffix;
  final String label;
  final IconData icon;
  final Color color;
  const _StatData({
    required this.value,
    required this.suffix,
    required this.label,
    required this.icon,
    required this.color,
  });
}

// ── Stat Item ─────────────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final _StatData stat;
  final Animation<double> anim;
  final int index;

  const _StatItem({required this.stat, required this.anim, required this.index});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final currentVal = (stat.value * anim.value).round();
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: stat.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: stat.color.withValues(alpha: 0.25)),
              ),
              child: Center(
                child: Icon(stat.icon, color: stat.color, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            // Count
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [stat.color, stat.color.withValues(alpha: 0.75)],
              ).createShader(bounds),
              child: Text(
                '$currentVal${stat.suffix}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Label
            Text(
              stat.label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.50),
                letterSpacing: 0.3,
              ),
            ),
          ],
        );
      },
    )
        .animate(delay: Duration(milliseconds: index * 100))
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic);
  }
}
