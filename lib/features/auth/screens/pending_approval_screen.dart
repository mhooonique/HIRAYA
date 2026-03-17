// lib/features/auth/screens/pending_approval_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class PendingApprovalScreen extends ConsumerWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // ── Icon ──────────────────────────────────────────────────────
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color:        AppColors.golden.withValues(alpha: 0.12),
                  shape:        BoxShape.circle,
                  border:       Border.all(color: AppColors.golden.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: AppColors.golden, size: 48),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

              const SizedBox(height: 32),

              // ── Title ─────────────────────────────────────────────────────
              const Text(
                'Application Submitted!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily:  'Poppins',
                  fontSize:    28,
                  fontWeight:  FontWeight.w800,
                  color:       AppColors.navy,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

              const SizedBox(height: 12),

              // ── Subtitle ──────────────────────────────────────────────────
              const Text(
                'Your account is now pending admin review. This usually takes 1–2 business days.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize:   15,
                  color:      Colors.black45,
                  height:     1.6,
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 32),

              // ── Info card ─────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:        AppColors.golden.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border:       Border.all(color: AppColors.golden.withValues(alpha: 0.25)),
                ),
                child: Column(children: [
                  _InfoRow(icon: Icons.email_outlined,   text: 'You\'ll receive a Gmail notification once your account is approved or rejected.'),
                  const SizedBox(height: 12),
                  _InfoRow(icon: Icons.verified_outlined, text: 'Make sure your KYC documents are clear and valid to speed up the process.'),
                ]),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 40),

              // ── Back to Home button ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Clear pending state so router doesn't loop back here
                    ref.read(authProvider.notifier).clearPendingStatus();
                    context.go('/');
                  },
                  icon:  const Icon(Icons.home_rounded, color: Colors.white),
                  label: const Text(
                    'Back to Home',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.white, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    padding:         const EdgeInsets.symmetric(vertical: 16),
                    shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 12),

              // ── Already approved? Sign in ──────────────────────────────────
              TextButton(
                onPressed: () {
                  ref.read(authProvider.notifier).clearPendingStatus();
                  context.go('/login');
                },
                child: const Text(
                  'Already approved? Sign in',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.teal),
                ),
              ).animate().fadeIn(delay: 550.ms),

            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: AppColors.golden, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black54, height: 1.5))),
    ]);
  }
}