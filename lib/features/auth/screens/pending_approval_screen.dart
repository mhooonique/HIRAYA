// lib/features/auth/screens/pending_approval_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class PendingApprovalScreen extends ConsumerStatefulWidget {
  const PendingApprovalScreen({super.key});

  @override
  ConsumerState<PendingApprovalScreen> createState() =>
      _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends ConsumerState<PendingApprovalScreen>
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
    return Scaffold(
      backgroundColor: AppColors.deepVoid,
      body: AnimatedBuilder(
        animation: _orbCtrl,
        builder: (_, child) {
          final t = _orbCtrl.value;
          return Stack(
            children: [
              // Background gradient
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.deepVoid,
                        AppColors.richNavy,
                        Color(0xFF0A1E30),
                      ],
                    ),
                  ),
                ),
              ),
              // Golden orb top-right
              Positioned(
                right: -80 + t * 25,
                top: -40 + t * 40,
                child: Container(
                  width: 360,
                  height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.golden.withValues(alpha: 0.10),
                        blurRadius: 200,
                        spreadRadius: 30,
                      ),
                    ],
                  ),
                ),
              ),
              // Teal orb bottom-left
              Positioned(
                left: -60 + t * 20,
                bottom: 60 + t * 30,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.10),
                        blurRadius: 160,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
              child!,
            ],
          );
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hourglass icon badge
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.golden.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: AppColors.golden.withValues(alpha: 0.30),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.golden.withValues(alpha: 0.18),
                            blurRadius: 40,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.hourglass_top_rounded,
                          color: AppColors.golden,
                          size: 48,
                        ),
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.7, 0.7),
                          duration: 600.ms,
                          curve: Curves.elasticOut,
                        )
                        .fadeIn(duration: 400.ms),

                    const SizedBox(height: 36),

                    // Title
                    const Text(
                      'Application Submitted!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 200.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 12),

                    // Subtitle
                    Text(
                      'Your account is now pending admin review.\nThis usually takes 1–2 business days.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.50),
                        height: 1.6,
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

                    const SizedBox(height: 36),

                    // Status timeline
                    _StatusTimeline()
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 380.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 28),

                    // Info card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.golden.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.golden.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.email_outlined,
                            text:
                                "You'll receive a Gmail notification once your account is approved or rejected.",
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.verified_outlined,
                            text:
                                'Make sure your KYC documents are clear and valid to speed up the process.',
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 450.ms),

                    const SizedBox(height: 36),

                    // Back to Home
                    _ActionButton(
                      label: 'Back to Home',
                      icon: Icons.home_rounded,
                      isGolden: true,
                      onTap: () {
                        ref.read(authProvider.notifier).clearPendingStatus();
                        context.go('/');
                      },
                    ).animate().fadeIn(duration: 500.ms, delay: 520.ms),

                    const SizedBox(height: 12),

                    // Already approved
                    GestureDetector(
                      onTap: () {
                        ref.read(authProvider.notifier).clearPendingStatus();
                        context.go('/login');
                      },
                      child: Text(
                        'Already approved? Sign in',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: AppColors.teal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ).animate().fadeIn(duration: 500.ms, delay: 580.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Status Timeline ─────────────────────────────────────────
class _StatusTimeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          _TimelineStep(
            icon: Icons.how_to_reg_rounded,
            label: 'Registered',
            color: AppColors.teal,
            done: true,
          ),
          _TimelineLine(color: AppColors.golden.withValues(alpha: 0.30)),
          _TimelineStep(
            icon: Icons.pending_outlined,
            label: 'Under Review',
            color: AppColors.golden,
            done: false,
            active: true,
          ),
          _TimelineLine(color: Colors.white.withValues(alpha: 0.15)),
          _TimelineStep(
            icon: Icons.check_circle_outline_rounded,
            label: 'Approved',
            color: Colors.white.withValues(alpha: 0.25),
            done: false,
          ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool done;
  final bool active;

  const _TimelineStep({
    required this.icon,
    required this.label,
    required this.color,
    required this.done,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: done || active ? 0.15 : 0.06),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: done || active ? 0.50 : 0.20),
                width: active ? 2.0 : 1.0,
              ),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TimelineLine extends StatelessWidget {
  final Color color;
  const _TimelineLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 1.5,
        margin: const EdgeInsets.only(bottom: 18),
        color: color,
      ),
    );
  }
}

// ─── Info Row ────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.golden.withValues(alpha: 0.75), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.55),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Action Button ───────────────────────────────────────────
class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isGolden;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isGolden,
    required this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
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
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: widget.isGolden
                ? const LinearGradient(
                    colors: [AppColors.golden, AppColors.warmEmber],
                  )
                : null,
            color: widget.isGolden
                ? null
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(13),
            border: widget.isGolden
                ? null
                : Border.all(
                    color: Colors.white
                        .withValues(alpha: _hovered ? 0.30 : 0.15),
                    width: 1.5,
                  ),
            boxShadow: widget.isGolden && _hovered
                ? [
                    BoxShadow(
                      color: AppColors.golden.withValues(alpha: 0.40),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.isGolden ? AppColors.navy : Colors.white,
              ),
              const SizedBox(width: 8),
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
