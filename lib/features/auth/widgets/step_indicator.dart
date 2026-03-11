import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Animated 7-step indicator — cinematic, stable, professional.
///
/// Design principles:
///   • ALL circles fixed 30 px — zero size-jump wobble
///   • Active step:    navy fill + dual glow shadow + radiating pulse ring
///   • Completed step: teal fill + spring-bounce checkmark
///   • Future step:    light gray fill + muted step number
///   • Connector:      gradient fill animates on completion (500 ms easeOutCubic)
///   • Step label:     AnimatedSwitcher fade + slide-up on every step change
class StepIndicator extends StatefulWidget {
  final int currentStep;
  final int totalSteps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  State<StepIndicator> createState() => _StepIndicatorState();
}

class _StepIndicatorState extends State<StepIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;
  int _prevStep = 1;

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
  void initState() {
    super.initState();
    _prevStep = widget.currentStep;

    // Soft radiating ring around the active circle — no size change on circle
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Spring checkmark bounce when a step is newly completed
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.20), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 1.20, end: 0.92), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.00), weight: 1),
    ]).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.linear));
  }

  @override
  void didUpdateWidget(StepIndicator old) {
    super.didUpdateWidget(old);
    if (widget.currentStep != old.currentStep) {
      _prevStep = old.currentStep;
      if (widget.currentStep > old.currentStep) {
        _bounceCtrl.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Circles + connector row ──────────────────────────
        Row(
          children: List.generate(widget.totalSteps * 2 - 1, (i) {
            if (i.isOdd) return _buildConnector(i ~/ 2);
            return _buildCircle(i ~/ 2);
          }),
        ),

        const SizedBox(height: 10),

        // ── Step label — cross-fades + slides up on change ───
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          transitionBuilder: (child, anim) {
            final curved =
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.28),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
          child: Text(
            'Step ${widget.currentStep} of ${widget.totalSteps}'
            ' — ${_labels[widget.currentStep - 1]}',
            key: ValueKey(widget.currentStep),
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.black45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ── Connector with animated gradient fill ─────────────────
  Widget _buildConnector(int stepBeforeIdx) {
    final isCompleted = stepBeforeIdx < widget.currentStep - 1;
    return Expanded(
      child: LayoutBuilder(builder: (ctx, constraints) {
        return Stack(
          children: [
            // Background track
            Container(
              height: 2.5,
              decoration: BoxDecoration(
                color: AppColors.lightGray.withValues(alpha: 0.50),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Animated teal→sky fill
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              height: 2.5,
              width: isCompleted ? constraints.maxWidth : 0,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.teal, AppColors.sky],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        );
      }),
    );
  }

  // ── Fixed-size circle — color + glow only, no size jump ───
  Widget _buildCircle(int stepIdx) {
    final isCompleted = stepIdx < widget.currentStep - 1;
    final isCurrent = stepIdx == widget.currentStep - 1;
    final justCompleted = isCompleted &&
        stepIdx == _prevStep - 1 &&
        widget.currentStep > _prevStep;

    // Fixed 30 px — never expands or shrinks
    const double size = 30.0;

    final Color fill = isCompleted
        ? AppColors.teal
        : isCurrent
            ? AppColors.navy
            : AppColors.lightGray.withValues(alpha: 0.55);

    final Widget inner = isCompleted
        ? _buildCheckmark(justCompleted)
        : Text(
            '${stepIdx + 1}',
            style: TextStyle(
              color: isCurrent
                  ? Colors.white
                  : Colors.black.withValues(alpha: 0.35),
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
            ),
          );

    // Core circle — only color + shadow animate, NOT size
    Widget circle = AnimatedContainer(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.28),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : isCompleted
                ? [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.22),
                      blurRadius: 8,
                    ),
                  ]
                : [],
      ),
      child: Center(child: inner),
    );

    // Radiating pulse ring sits OUTSIDE the circle — circle size never changes
    if (isCurrent) {
      circle = Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            child: const SizedBox(),
            builder: (_, __) {
              final t = Curves.easeOut.transform(_pulseCtrl.value);
              return Container(
                width: size + 6 + t * 12,
                height: size + 6 + t * 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.navy.withValues(alpha: 0.15 * (1 - t)),
                    width: 1.5,
                  ),
                ),
              );
            },
          ),
          circle,
        ],
      );
    }

    // Entrance stagger — fade + spring scale on initial render
    return circle
        .animate(delay: Duration(milliseconds: 50 + stepIdx * 50))
        .fadeIn(duration: 350.ms)
        .scale(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        );
  }

  // ── Spring-bounce checkmark on newly completed step ───────
  Widget _buildCheckmark(bool justCompleted) {
    const icon = Icon(Icons.check_rounded, color: Colors.white, size: 13);
    if (!justCompleted) return icon;
    return AnimatedBuilder(
      animation: _bounceAnim,
      builder: (_, child) => Transform.scale(
        scale: _bounceAnim.value.clamp(0.0, 2.0),
        child: child,
      ),
      child: icon,
    );
  }
}
