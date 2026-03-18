import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/app_colors.dart';

/// Reusable section header with eyebrow, title, and subtitle.
/// Used inside page sections (not as a hero banner).
///
/// Animates with staggered fadeIn + slideY on first appearance.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    this.eyebrow,
    required this.title,
    this.subtitle,
    this.accentColor = AppColors.golden,
    this.alignment = TextAlign.center,
  });

  final String? eyebrow;
  final String title;
  final String? subtitle;
  final Color accentColor;
  final TextAlign alignment;

  CrossAxisAlignment get _crossAxisAlignment {
    switch (alignment) {
      case TextAlign.left:
      case TextAlign.start:
        return CrossAxisAlignment.start;
      case TextAlign.right:
      case TextAlign.end:
        return CrossAxisAlignment.end;
      default:
        return CrossAxisAlignment.center;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: _crossAxisAlignment,
      children: [
        // Eyebrow
        if (eyebrow != null) ...[
          Text(
            eyebrow!.toUpperCase(),
            textAlign: alignment,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 3,
              color: accentColor,
              fontFamily: 'Poppins',
            ),
          )
              .animate()
              .fadeIn(delay: 80.ms, duration: 450.ms)
              .slideY(begin: 0.25, end: 0, duration: 450.ms),
          const SizedBox(height: 10),
        ],

        // Title
        Text(
          title,
          textAlign: alignment,
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
            height: 1.2,
          ),
        )
            .animate()
            .fadeIn(delay: 180.ms, duration: 500.ms)
            .slideY(begin: 0.25, end: 0, duration: 500.ms),

        // Subtitle
        if (subtitle != null) ...[
          const SizedBox(height: 14),
          Text(
            subtitle!,
            textAlign: alignment,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Poppins',
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.7) ??
                  Colors.black.withValues(alpha: 0.7),
              height: 1.6,
            ),
          )
              .animate()
              .fadeIn(delay: 300.ms, duration: 500.ms)
              .slideY(begin: 0.25, end: 0, duration: 500.ms),
        ],
      ],
    );
  }
}
