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
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final success = await ref
        .read(authProvider.notifier)
        .login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (success && mounted) {
      final role = ref.read(authProvider).user?.role ?? 'client';
      switch (role) {
        case 'admin':
          context.go('/admin');
          break;
        case 'innovator':
          context.go('/innovator/dashboard');
          break;
        default:
          context.go('/client/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Row(
        children: [
          // Left decorative panel
          if (size.width > 900)
            Expanded(
              flex: 2,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.navy, Color(0xFF064663), AppColors.teal],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.05,
                        child: CustomPaint(painter: _GridPainter()),
                      ),
                    ),
                    // Decorative circles
                    Positioned(
                      top: -60,
                      right: -60,
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.teal.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -40,
                      left: -40,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.sky.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                              'assets/images/logo/final-logo.png',
                              height: 80),
                          const SizedBox(height: 24),
                          const Text('HIRAYA',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 8)),
                          const SizedBox(height: 12),
                          const Text(
                              'Where Innovation\nMeets Opportunity',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 20,
                                  color: Colors.white60,
                                  height: 1.5)),
                          const SizedBox(height: 48),
                          const Text('Welcome back!',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.golden)),
                          const SizedBox(height: 8),
                          const Text(
                              'Sign in to continue your innovation journey.',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: Colors.white54)),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms),
            ),

          // Right — login form
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
                        // Back to home
                        TextButton.icon(
                          onPressed: () => context.go('/'),
                          icon: const Icon(Icons.arrow_back,
                              size: 16, color: AppColors.navy),
                          label: const Text('Back to Home',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: AppColors.navy,
                                  fontSize: 13)),
                        ),
                        const SizedBox(height: 24),

                        const Text('Sign In',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy))
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 6),
                        const Text('Enter your credentials to continue',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: Colors.black45)),

                        const SizedBox(height: 32),

                        AuthTextField(
                          label: 'Email Address',
                          controller: _emailCtrl,
                          hint: 'you@example.com',
                          keyboardType: TextInputType.emailAddress,
                          prefix: const Icon(Icons.email_outlined,
                              size: 18, color: Colors.black38),
                          validator: (v) {
                            if (v == null ||
                                !RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                    .hasMatch(v)) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        )
                            .animate(delay: 100.ms)
                            .fadeIn()
                            .slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 16),

                        AuthTextField(
                          label: 'Password',
                          controller: _passwordCtrl,
                          isPassword: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Enter your password';
                            }
                            return null;
                          },
                        )
                            .animate(delay: 200.ms)
                            .fadeIn()
                            .slideY(begin: 0.1, end: 0),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (v) =>
                                      setState(() => _rememberMe = v ?? false),
                                  activeColor: AppColors.teal,
                                ),
                                const Text('Remember me',
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        color: Colors.black54)),
                              ],
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => context.go('/forgot-password'),
                              child: const Text('Forgot Password?',
                                  style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      color: AppColors.teal,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Error
                        if (authState.error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.crimson.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.crimson.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.crimson, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(authState.error!,
                                      style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                          color: AppColors.crimson)),
                                ),
                              ],
                            ),
                          ),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.navy,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                            ),
                            child: authState.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text('Sign In',
                                    style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: Colors.white)),
                          ),
                        )
                            .animate(delay: 300.ms)
                            .fadeIn()
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 24),

                        // Divider
                        const Row(
                          children: [
                            Expanded(
                                child:
                                    Divider(color: AppColors.lightGray)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('or',
                                  style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 13,
                                      color: Colors.black38)),
                            ),
                            Expanded(
                                child:
                                    Divider(color: AppColors.lightGray)),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Don't have account
                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  color: Colors.black54),
                              children: [
                                const TextSpan(
                                    text: 'Don\'t have an account? '),
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () => context.go('/signup'),
                                    child: const Text('Create one',
                                        style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.teal)),
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

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
