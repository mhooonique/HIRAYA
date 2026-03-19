import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _sent = false;
  bool _loading = false;
  late AnimationController _orbCtrl;

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final res = await ApiService().post('auth/forgot-password', {
        'email': _emailCtrl.text.trim(),
      });
      if (!mounted) return;
      if (res['error'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['error'],
                style: const TextStyle(fontFamily: 'Poppins')),
            backgroundColor: AppColors.crimson,
          ),
        );
      } else {
        setState(() => _sent = true);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection error. Is XAMPP running?'),
          backgroundColor: AppColors.crimson,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w >= 900;

    return Scaffold(
      backgroundColor: AppColors.deepVoid,
      body: isDesktop ? _buildDesktop() : _buildMobile(),
    );
  }

  // ─── Desktop two-panel layout ───────────────────────────────
  Widget _buildDesktop() {
    return Row(
      children: [
        // Left brand panel
        Expanded(flex: 5, child: _buildBrandPanel()),
        // Right form panel
        Expanded(flex: 6, child: _buildFormPanel()),
      ],
    );
  }

  Widget _buildMobile() {
    return Stack(
      children: [
        // Dark cinematic background
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.deepVoid, AppColors.richNavy, Color(0xFF0A2240)],
              ),
            ),
          ),
        ),
        // Orbs
        AnimatedBuilder(
          animation: _orbCtrl,
          builder: (_, __) {
            final t = _orbCtrl.value;
            return Stack(children: [
              Positioned(
                right: -60 + t * 20,
                top: 60 + t * 30,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.golden.withValues(alpha: 0.12),
                        blurRadius: 120,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: -40 + t * 15,
                bottom: 80 + t * 20,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.14),
                        blurRadius: 100,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ]);
          },
        ),
        // Content
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackLink(light: true),
                const SizedBox(height: 32),
                _buildKeyIcon(),
                const SizedBox(height: 28),
                _sent ? _buildSuccessContent(light: true) : _buildFormContent(light: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Brand panel (left) ─────────────────────────────────────
  Widget _buildBrandPanel() {
    return AnimatedBuilder(
      animation: _orbCtrl,
      builder: (_, __) {
        final t = _orbCtrl.value;
        return Container(
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.deepVoid,
                AppColors.richNavy,
                Color(0xFF0A2240),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Teal orb top-left
              Positioned(
                left: -80 + t * 20,
                top: 80 + t * 40,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.14),
                        blurRadius: 180,
                        spreadRadius: 30,
                      ),
                    ],
                  ),
                ),
              ),
              // Golden orb bottom-right
              Positioned(
                right: -60 + t * 25,
                bottom: 120 + t * 35,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.golden.withValues(alpha: 0.10),
                        blurRadius: 150,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Digital Platform logo
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppColors.golden, AppColors.warmEmber],
                      ).createShader(bounds),
                      child: const Text(
                        'Digital Platform',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Key icon badge
                    _buildKeyIcon(),
                    const SizedBox(height: 32),
                    const Text(
                      'Forgot your\npassword?',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 16),
                    Text(
                      'No worries. Enter your email and we\'ll send a secure reset link to get you back in.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.55),
                        height: 1.6,
                      ),
                    )
                        .animate(delay: 100.ms)
                        .fadeIn(duration: 600.ms),
                    const SizedBox(height: 36),
                    // Info pills
                    _InfoPill(
                      icon: Icons.timer_outlined,
                      label: 'Link expires in 15 minutes',
                    ),
                    const SizedBox(height: 10),
                    _InfoPill(
                      icon: Icons.lock_outline_rounded,
                      label: 'Single-use security token',
                    ),
                    const SizedBox(height: 10),
                    _InfoPill(
                      icon: Icons.verified_user_outlined,
                      label: 'DOST-affiliated secure system',
                    ),
                    const Spacer(),
                    Text(
                      '© 2025 Digital Platform',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Key icon badge ──────────────────────────────────────────
  Widget _buildKeyIcon() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.golden.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.golden.withValues(alpha: 0.30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.golden.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.vpn_key_rounded,
          color: AppColors.golden,
          size: 34,
        ),
      ),
    )
        .animate()
        .scale(begin: const Offset(0.8, 0.8), duration: 500.ms, curve: Curves.easeOutBack)
        .fadeIn(duration: 400.ms);
  }

  // ─── Form panel (right) ──────────────────────────────────────
  Widget _buildFormPanel() {
    return Container(
      color: const Color(0xFF0F1F2E),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackLink(light: true),
                const SizedBox(height: 40),
                if (_sent)
                  _buildSuccessContent(light: false)
                else
                  _buildFormContent(light: false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Back link ───────────────────────────────────────────────
  Widget _buildBackLink({required bool light}) {
    return GestureDetector(
      onTap: () => context.go('/login'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 14,
            color: Colors.white.withValues(alpha: 0.55),
          ),
          const SizedBox(width: 6),
          Text(
            'Back to Login',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.55),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Form content ────────────────────────────────────────────
  Widget _buildFormContent({required bool light}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reset Password',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .slideY(begin: 0.15, end: 0),
          const SizedBox(height: 8),
          Text(
            'Enter your registered email address.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.50),
              height: 1.5,
            ),
          )
              .animate(delay: 80.ms)
              .fadeIn(duration: 500.ms),
          const SizedBox(height: 36),
          AuthTextField(
            label: 'Email Address',
            controller: _emailCtrl,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            prefix: Icon(
              Icons.email_outlined,
              size: 18,
              color: Colors.white.withValues(alpha: 0.40),
            ),
            validator: (v) {
              if (v == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          // Send button
          _SendButton(loading: _loading, onTap: _send),
          const SizedBox(height: 20),
          // Helper note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.golden.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.golden.withValues(alpha: 0.20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.golden.withValues(alpha: 0.70),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'The reset link expires in 15 minutes and can only be used once.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.golden.withValues(alpha: 0.65),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )
              .animate(delay: 200.ms)
              .fadeIn(duration: 500.ms),
        ],
      ),
    );
  }

  // ─── Success content ─────────────────────────────────────────
  Widget _buildSuccessContent({required bool light}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Check icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.teal.withValues(alpha: 0.30),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.20),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.mark_email_read_rounded,
              color: AppColors.teal,
              size: 40,
            ),
          ),
        )
            .animate()
            .scale(begin: const Offset(0.7, 0.7), duration: 500.ms, curve: Curves.elasticOut)
            .fadeIn(duration: 400.ms),
        const SizedBox(height: 28),
        const Text(
          'Check Your Email',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms, delay: 100.ms)
            .slideY(begin: 0.15, end: 0),
        const SizedBox(height: 12),
        Text(
          'A password reset link has been sent to:',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.50),
            height: 1.5,
          ),
        )
            .animate(delay: 150.ms)
            .fadeIn(duration: 500.ms),
        const SizedBox(height: 8),
        // Email display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.teal.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.email_outlined, size: 16, color: AppColors.teal.withValues(alpha: 0.70)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _emailCtrl.text,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        )
            .animate(delay: 200.ms)
            .fadeIn(duration: 500.ms),
        const SizedBox(height: 12),
        Text(
          'The link expires in 15 minutes and is single-use only.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.40),
            height: 1.5,
          ),
        )
            .animate(delay: 250.ms)
            .fadeIn(duration: 500.ms),
        const SizedBox(height: 36),
        // Back to login button
        _BackToLoginButton(onTap: () => context.go('/login')),
      ],
    );
  }
}

// ─── Send Button ─────────────────────────────────────────────
class _SendButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onTap;
  const _SendButton({required this.loading, required this.onTap});

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.loading ? null : widget.onTap,
        child: AnimatedScale(
          scale: _hovered ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.golden, AppColors.warmEmber],
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: AppColors.golden.withValues(alpha: 0.45),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: AppColors.golden.withValues(alpha: 0.20),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: widget.loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.navy,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Send Reset Link',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Back to Login Button ────────────────────────────────────
class _BackToLoginButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BackToLoginButton({required this.onTap});

  @override
  State<_BackToLoginButton> createState() => _BackToLoginButtonState();
}

class _BackToLoginButtonState extends State<_BackToLoginButton> {
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
            color: _hovered
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: Colors.white.withValues(alpha: _hovered ? 0.30 : 0.15),
              width: 1.5,
            ),
          ),
          child: const Center(
            child: Text(
              'Back to Login',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Info Pill ───────────────────────────────────────────────
class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.40)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.40),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 300.ms);
  }
}
