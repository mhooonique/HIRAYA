// lib/features/auth/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  bool  _rememberMe   = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authProvider.notifier).login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState  = ref.watch(authProvider);
    final size       = MediaQuery.of(context).size;
    final isPending  = authState.loginStatus == LoginStatus.pending;
    final isRejected = authState.loginStatus == LoginStatus.rejected;

    // ── Listen for Google "needs signup" → redirect to signup screen ──
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (!mounted) return;

      // Google sign-in determined user is new → go to signup with prefill
      if (next.needsGoogleSignup && !(prev?.needsGoogleSignup ?? false)) {
        context.go('/signup');
        return;
      }

      // 2FA required → go to OTP screen
      if (next.requires2fa && !(prev?.requires2fa ?? false)) {
        context.go('/otp', extra: {
          'userId':        next.pendingUserId,
          'token':         next.pendingToken,
          'otpType':       next.otpType,
          'phone':         next.pendingPhone,
          'maskedContact': next.otpType == 'sms'
              ? _maskPhone(next.pendingPhone ?? '')
              : _maskEmail(authState.user?.email ?? _emailCtrl.text),
        });
        return;
      }

      // Fully logged in → go to dashboard
      if (next.isLoggedIn && !(prev?.isLoggedIn ?? false)) {
        final role = next.user?.role ?? 'client';
        context.go(role == 'admin'
            ? '/admin'
            : role == 'innovator'
                ? '/innovator/dashboard'
                : '/client/dashboard');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Row(
        children: [
          // ── Left decorative panel ──────────────────────────────────────
          if (size.width > 900)
            Expanded(
              flex: 2,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end:   Alignment.bottomRight,
                    colors: [AppColors.navy, Color(0xFF064663), AppColors.teal],
                  ),
                ),
                child: Stack(children: [
                  Positioned.fill(child: Opacity(opacity: 0.05, child: CustomPaint(painter: _GridPainter()))),
                  Positioned(top: -60, right: -60, child: Container(
                    width: 250, height: 250,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.teal.withValues(alpha: 0.15)),
                  )),
                  Positioned(bottom: -40, left: -40, child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.sky.withValues(alpha: 0.1)),
                  )),
                  Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisAlignment:  MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset('assets/images/logo/final-logo.png', height: 80),
                        const SizedBox(height: 24),
                        const Text('HIRAYA', style: TextStyle(fontFamily: 'Poppins', fontSize: 48, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 8)),
                        const SizedBox(height: 12),
                        const Text('Where Innovation\nMeets Opportunity', style: TextStyle(fontFamily: 'Poppins', fontSize: 20, color: Colors.white60, height: 1.5)),
                        const SizedBox(height: 48),
                        const Text('Welcome back!', style: TextStyle(fontFamily: 'Poppins', fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.golden)),
                        const SizedBox(height: 8),
                        const Text('Sign in to continue your innovation journey.', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.white54)),
                      ],
                    ),
                  ),
                ]),
              ).animate().fadeIn(duration: 600.ms),
            ),

          // ── Right — login form ─────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton.icon(
                          onPressed: () => context.go('/'),
                          icon:  const Icon(Icons.arrow_back, size: 16, color: AppColors.navy),
                          label: const Text('Back to Home', style: TextStyle(fontFamily: 'Poppins', color: AppColors.navy, fontSize: 13)),
                        ),
                        const SizedBox(height: 24),

                        const Text('Sign In', style: TextStyle(fontFamily: 'Poppins', fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.navy))
                            .animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
                        const SizedBox(height: 6),
                        const Text('Enter your credentials to continue', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.black45)),
                        const SizedBox(height: 32),

                        // Pending banner
                        if (isPending)
                          _StatusBanner(
                            icon: Icons.hourglass_top_rounded, color: AppColors.golden,
                            title: 'Account Pending Approval',
                            message: 'Your account is awaiting admin approval. You\'ll receive a Gmail notification once approved.',
                          ).animate().fadeIn().slideY(begin: -0.1, end: 0),

                        // Rejected banner
                        if (isRejected)
                          _StatusBanner(
                            icon: Icons.block_rounded, color: AppColors.crimson,
                            title: 'Account Rejected',
                            message: 'Your account registration was not approved. Contact support for assistance.',
                          ).animate().fadeIn().slideY(begin: -0.1, end: 0),

                        if (!isPending && !isRejected) ...[
                          AuthTextField(
                            label: 'Email Address', controller: _emailCtrl,
                            hint: 'you@gmail.com', keyboardType: TextInputType.emailAddress,
                            prefix: const Icon(Icons.email_outlined, size: 18, color: Colors.black38),
                            validator: (v) => (v == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) ? 'Enter a valid email' : null,
                          ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 16),

                          AuthTextField(
                            label: 'Password', controller: _passwordCtrl, isPassword: true,
                            validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
                          ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 12),

                          Row(children: [
                            Row(children: [
                              Checkbox(value: _rememberMe, onChanged: (v) => setState(() => _rememberMe = v ?? false), activeColor: AppColors.teal),
                              const Text('Remember me', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black54)),
                            ]),
                            const Spacer(),
                            TextButton(
                              onPressed: () => context.go('/forgot-password'),
                              child: const Text('Forgot Password?', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.teal, fontWeight: FontWeight.w600)),
                            ),
                          ]),
                          const SizedBox(height: 8),

                          // Generic error
                          if (authState.error != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin:  const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color:        AppColors.crimson.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border:       Border.all(color: AppColors.crimson.withValues(alpha: 0.3)),
                              ),
                              child: Row(children: [
                                const Icon(Icons.error_outline, color: AppColors.crimson, size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(authState.error!, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.crimson))),
                              ]),
                            ),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: authState.isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.navy,
                                padding:         const EdgeInsets.symmetric(vertical: 16),
                                shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation:       4,
                              ),
                              child: authState.isLoading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Sign In', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white)),
                            ),
                          ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2, end: 0),

                          const SizedBox(height: 24),

                          const Row(children: [
                            Expanded(child: Divider(color: AppColors.lightGray)),
                            Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black38))),
                            Expanded(child: Divider(color: AppColors.lightGray)),
                          ]),
                          const SizedBox(height: 16),

                          _GoogleSignInButton(),
                          const SizedBox(height: 20),
                        ],

                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.black54),
                              children: [
                                const TextSpan(text: 'Don\'t have an account? '),
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () => context.go('/signup'),
                                    child: const Text('Create one', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.teal)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
String _maskPhone(String phone) {
  if (phone.length < 4) return phone;
  return '${phone.substring(0, phone.length - 4).replaceAll(RegExp(r'\d'), '*')}${phone.substring(phone.length - 4)}';
}

String _maskEmail(String email) {
  final parts = email.split('@');
  if (parts.length != 2) return email;
  final name   = parts[0];
  final domain = parts[1];
  if (name.length <= 2) return email;
  return '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}@$domain';
}

// ─── Status Banner ────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   title, message;

  const _StatusBanner({required this.icon, required this.color, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(message, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black54, height: 1.4)),
        ])),
      ]),
    );
  }
}

// ─── Google Sign-In Button ────────────────────────────────────────────────────
class _GoogleSignInButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authProvider).isLoading;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : () => ref.read(authProvider.notifier).loginWithGoogle(),
        style: OutlinedButton.styleFrom(
          padding:         const EdgeInsets.symmetric(vertical: 14),
          side:            const BorderSide(color: AppColors.lightGray),
          shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 22, height: 22,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4285F4)),
            child: const Center(child: Text('G', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white))),
          ),
          const SizedBox(width: 12),
          const Text('Continue with Google', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        ]),
      ),
    );
  }
}

// ─── Grid Painter ─────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += spacing) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}