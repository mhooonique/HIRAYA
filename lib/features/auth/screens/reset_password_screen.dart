import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;
  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConf = true;
  bool _loading = false;
  bool _done = false;
  String? _error;
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
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (widget.token.isEmpty) {
      setState(() => _error = 'Invalid or missing reset token.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiService().post('auth/reset-password', {
        'token': widget.token,
        'password': _passCtrl.text,
      });
      if (!mounted) return;
      if (res['error'] != null) {
        setState(() => _error = res['error']);
      } else {
        setState(() => _done = true);
      }
    } catch (_) {
      setState(() => _error = 'Connection error. Is XAMPP running?');
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

  Widget _buildDesktop() {
    return Row(
      children: [
        Expanded(flex: 5, child: _buildBrandPanel()),
        Expanded(flex: 6, child: _buildFormPanel()),
      ],
    );
  }

  Widget _buildMobile() {
    return AnimatedBuilder(
      animation: _orbCtrl,
      builder: (_, child) {
        final t = _orbCtrl.value;
        return Stack(
          children: [
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
            Positioned(
              right: -60 + t * 20,
              top: 40 + t * 30,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.12),
                      blurRadius: 120,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: -40 + t * 15,
              bottom: 100 + t * 20,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.golden.withValues(alpha: 0.10),
                      blurRadius: 100,
                      spreadRadius: 10,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBackLink(),
              const SizedBox(height: 32),
              _buildShieldIcon(),
              const SizedBox(height: 28),
              _done ? _buildSuccessContent() : _buildFormContent(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Brand panel ─────────────────────────────────────────────
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
              colors: [AppColors.deepVoid, AppColors.richNavy, Color(0xFF0A2240)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                left: -80 + t * 20,
                top: 80 + t * 40,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.13),
                        blurRadius: 180,
                        spreadRadius: 30,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: -60 + t * 25,
                bottom: 100 + t * 35,
                child: Container(
                  width: 240,
                  height: 240,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 60),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [AppColors.golden, AppColors.warmEmber],
                      ).createShader(bounds),
                      child: const Text(
                        'HIRAYA',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _buildShieldIcon(),
                    const SizedBox(height: 32),
                    const Text(
                      'Set Your New\nPassword',
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
                      'Choose a strong, unique password to secure your HIRAYA account.',
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
                    _InfoPill(icon: Icons.security_rounded, label: 'Minimum 8 characters'),
                    const SizedBox(height: 10),
                    _InfoPill(icon: Icons.text_fields_rounded, label: 'One uppercase letter required'),
                    const SizedBox(height: 10),
                    _InfoPill(icon: Icons.pin_rounded, label: 'One number required'),
                    const Spacer(),
                    Text(
                      '© 2025 HIRAYA Innovation Marketplace',
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

  // ─── Shield icon ─────────────────────────────────────────────
  Widget _buildShieldIcon() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.teal.withValues(alpha: 0.30),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.shield_rounded, color: AppColors.teal, size: 34),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.8, 0.8),
          duration: 500.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 400.ms);
  }

  // ─── Form panel ──────────────────────────────────────────────
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
                _buildBackLink(),
                const SizedBox(height: 40),
                if (_done) _buildSuccessContent() else _buildFormContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackLink() {
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
  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set New Password',
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
            'Choose a strong password for your account.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.50),
              height: 1.5,
            ),
          )
              .animate(delay: 80.ms)
              .fadeIn(duration: 500.ms),
          const SizedBox(height: 32),

          // Error banner
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.crimson.withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.crimson.withValues(alpha: 0.80),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: AppColors.crimson.withValues(alpha: 0.80),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),
          ],

          // New password
          _DarkTextField(
            controller: _passCtrl,
            label: 'New Password',
            obscure: _obscurePass,
            onToggleObscure: () => setState(() => _obscurePass = !_obscurePass),
            prefixIcon: Icons.lock_outline_rounded,
            validator: (v) {
              if (v == null || v.length < 8) return 'At least 8 characters required';
              if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Include at least one uppercase letter';
              if (!RegExp(r'[0-9]').hasMatch(v)) return 'Include at least one number';
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Confirm password
          _DarkTextField(
            controller: _confirmCtrl,
            label: 'Confirm Password',
            obscure: _obscureConf,
            onToggleObscure: () => setState(() => _obscureConf = !_obscureConf),
            prefixIcon: Icons.lock_outline_rounded,
            validator: (v) {
              if (v != _passCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Requirements box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.teal.withValues(alpha: 0.20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Password requirements:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.teal.withValues(alpha: 0.80),
                  ),
                ),
                const SizedBox(height: 8),
                _ReqRow(text: 'At least 8 characters'),
                _ReqRow(text: 'One uppercase letter (A-Z)'),
                _ReqRow(text: 'One number (0-9)'),
              ],
            ),
          )
              .animate(delay: 200.ms)
              .fadeIn(duration: 500.ms),

          const SizedBox(height: 28),

          // Submit button
          _ResetButton(loading: _loading, onTap: _submit),
        ],
      ),
    );
  }

  // ─── Success content ─────────────────────────────────────────
  Widget _buildSuccessContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              Icons.check_circle_rounded,
              color: AppColors.teal,
              size: 40,
            ),
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.7, 0.7),
              duration: 500.ms,
              curve: Curves.elasticOut,
            )
            .fadeIn(duration: 400.ms),
        const SizedBox(height: 28),
        const Text(
          'Password Reset!',
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
          'Your password has been updated successfully.\nYou can now log in with your new password.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.50),
            height: 1.6,
          ),
        )
            .animate(delay: 150.ms)
            .fadeIn(duration: 500.ms),
        const SizedBox(height: 36),
        _GoToLoginButton(onTap: () => context.go('/login')),
      ],
    );
  }
}

// ─── Dark text field ─────────────────────────────────────────
class _DarkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final IconData prefixIcon;
  final FormFieldValidator<String>? validator;

  const _DarkTextField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggleObscure,
    required this.prefixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(
        fontFamily: 'Poppins',
        color: Colors.white,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white.withValues(alpha: 0.45),
          fontSize: 13,
        ),
        prefixIcon: Icon(prefixIcon, size: 18, color: Colors.white.withValues(alpha: 0.35)),
        suffixIcon: IconButton(
          onPressed: onToggleObscure,
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.white.withValues(alpha: 0.35),
            size: 18,
          ),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.crimson.withValues(alpha: 0.60),
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.crimson, width: 1.5),
        ),
        errorStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          color: AppColors.crimson.withValues(alpha: 0.80),
        ),
      ),
      validator: validator,
    );
  }
}

// ─── Reset Button ────────────────────────────────────────────
class _ResetButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onTap;
  const _ResetButton({required this.loading, required this.onTap});

  @override
  State<_ResetButton> createState() => _ResetButtonState();
}

class _ResetButtonState extends State<_ResetButton> {
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
                colors: [AppColors.teal, Color(0xFF0E5A50)],
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.45),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.20),
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
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Reset Password',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Go to Login Button ──────────────────────────────────────
class _GoToLoginButton extends StatefulWidget {
  final VoidCallback onTap;
  const _GoToLoginButton({required this.onTap});

  @override
  State<_GoToLoginButton> createState() => _GoToLoginButtonState();
}

class _GoToLoginButtonState extends State<_GoToLoginButton> {
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
                : [],
          ),
          child: const Center(
            child: Text(
              'Go to Login',
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
    );
  }
}

// ─── Req Row ─────────────────────────────────────────────────
class _ReqRow extends StatelessWidget {
  final String text;
  const _ReqRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 13,
            color: AppColors.teal.withValues(alpha: 0.70),
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.50),
            ),
          ),
        ],
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
    ).animate().fadeIn(duration: 500.ms, delay: 300.ms);
  }
}
