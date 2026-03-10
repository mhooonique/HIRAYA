import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  static const _features = [
    {
      'icon': Icons.verified_user_rounded,
      'title': 'Verified Innovators',
      'desc': 'KYC-verified profiles you can trust. Every innovator is identity-confirmed.',
      'color': AppColors.teal,
    },
    {
      'icon': Icons.message_rounded,
      'title': 'Direct Messaging',
      'desc': 'Connect privately with innovators. No shared contacts — safe and in-platform.',
      'color': AppColors.sky,
    },
    {
      'icon': Icons.trending_up_rounded,
      'title': 'Smart Discovery',
      'desc': 'Trending products, advanced filters, and category-based discovery tools.',
      'color': AppColors.crimson,
    },
    {
      'icon': Icons.shield_rounded,
      'title': 'RA 10173 Compliant',
      'desc': 'Your data is protected under the Philippine Data Privacy Act.',
      'color': AppColors.navy,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.offWhite,
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Column(
        children: [
          const Text(
            'Why HIRAYA?',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ).animate().fadeIn(duration: 600.ms),

          const SizedBox(height: 48),

          LayoutBuilder(builder: (context, constraints) {
            final crossCount = constraints.maxWidth > 700 ? 4 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 0.9,
              ),
              itemCount: _features.length,
              itemBuilder: (context, index) {
                final f = _features[index];
                return Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.lightGray),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: (f['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(f['icon'] as IconData, color: f['color'] as Color, size: 28),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        f['title'] as String,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        f['desc'] as String,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.black45,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate(delay: Duration(milliseconds: 100 * index))
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.2, end: 0);
              },
            );
          }),
        ],
      ),
    );
  }
}