import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  static const List<String> _labels = [
    'Role',
    'Info',
    'Security',
    'Contact',
    'Identity',
    'Consent',
    'Review',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(totalSteps * 2 - 1, (index) {
            if (index.isOdd) {
              // Connector line
              final stepIndex = index ~/ 2;
              final isCompleted = stepIndex < currentStep - 1;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: 2,
                  color: isCompleted ? AppColors.teal : AppColors.lightGray,
                ),
              );
            }
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < currentStep - 1;
            final isCurrent = stepIndex == currentStep - 1;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isCurrent ? 36 : 28,
              height: isCurrent ? 36 : 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.teal
                    : isCurrent
                        ? AppColors.navy
                        : AppColors.lightGray,
                boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: AppColors.navy.withOpacity(0.3),
                          blurRadius: 8,
                        )
                      ]
                    : [],
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          color: isCurrent ? Colors.white : Colors.black38,
                          fontSize: isCurrent ? 14 : 12,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ).animate(delay: Duration(milliseconds: 50 * stepIndex)).scale();
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Step $currentStep of $totalSteps — ${_labels[currentStep - 1]}',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Colors.black45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}