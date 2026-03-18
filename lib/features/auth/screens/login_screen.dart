// lib/features/auth/screens/login_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  bool  _rememberMe   = false;
  late AnimationController _orbCtrl;
  late AnimationController _gradientCtrl;
  late AnimationController _shimmerCtrl;
  final _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
    _gradientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _orbCtrl.dispose();
    _gradientCtrl.dispose();
    _shimmerCtrl.dispose();
    _passwordFocusNode.dispose();
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

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (!mounted) return;
      if (next.needsGoogleSignup && !(prev?.needsGoogleSignup ?? false)) {
        context.go('/signup');
        return;
      }
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
      backgroundColor: AppColors.deepVoid,
      body: Row(
        children: [
          // ── Left decorative panel ──────────────────────────────────────
          if (size.width > 900)
            Expanded(
              flex: 2,
              child: _LeftPanel(orbCtrl: _orbCtrl, gradientCtrl: _gradientCtrl),
            ),

          // ── Right — login Form ─────────────────────────────────────────
          Expanded(
            flex: 3,
            child: _buildRightPanel(authState, isPending, isRejected, size),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel(AuthState authState, bool isPending, bool isRejected, Size size) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.darkSurface,
            const Color(0xFF0F1F2E),
            AppColors.midnight,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Subtle pattern overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.02,
              child: CustomPaint(painter: _GridPainter()),
            ),
          ),
          // Subtle corner glow
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.golden.withValues(alpha: 0.06),
                    blurRadius: 120,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: _buildGlassCard(authState, isPending, isRejected),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(AuthState authState, bool isPending, bool isRejected) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: AppColors.darkSurface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderDark, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: AppColors.golden.withValues(alpha: 0.04),
            blurRadius: 60,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back link
            TextButton.icon(
              onPressed: () => context.go('/'),
              icon: Icon(Icons.arrow_back, size: 16, color: Colors.white.withValues(alpha: 0.50)),
              label: Text('Back to Home',
                  style: TextStyle(fontFamily: 'Poppins', color: Colors.white.withValues(alpha: 0.50), fontSize: 13)),
            ).animate().fadeIn(duration: 400.ms),
            const SizedBox(height: 20),

            // Title
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Colors.white, Color(0xFFCBD5E1)],
              ).createShader(b),
              child: const Text('Sign In',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                )),
            ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 6),
            Text('Sign in to your HIRAYA account',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.45),
              )),
            const SizedBox(height: 32),

            // Pending banner
            if (isPending)
              _StatusBanner(
                icon: Icons.hourglass_top_rounded,
                color: AppColors.golden,
                title: 'Account Pending Approval',
                message: 'Your account is awaiting admin approval. You\'ll receive a Gmail notification once approved.',
              ).animate().fadeIn().slideY(begin: -0.1, end: 0),

            // Rejected banner
            if (isRejected)
              _StatusBanner(
                icon: Icons.block_rounded,
                color: AppColors.crimson,
                title: 'Account Rejected',
                message: 'Your account registration was not approved. Contact support for assistance.',
              ).animate().fadeIn().slideY(begin: -0.1, end: 0),

            if (!isPending && !isRejected) ...[
              // Email field
              _GoldenTextField(
                label: 'Email Address',
                controller: _emailCtrl,
                hint: 'you@gmail.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (v) => (v == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v))
                    ? 'Enter a valid email'
                    : null,
              ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.15, end: 0),
              const SizedBox(height: 16),

              // Password field with strength indicator
              _GoldenTextField(
                label: 'Password',
                controller: _passwordCtrl,
                isPassword: true,
                focusNode: _passwordFocusNode,
                validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.15, end: 0),
              const SizedBox(height: 14),

              // Remember me + Forgot password
              Row(
                children: [
                  _AnimatedCheckbox(
                    value: _rememberMe,
                    onChanged: (v) => setState(() => _rememberMe = v ?? false),
                    label: 'Remember me',
                  ),
                  const Spacer(),
                  _HoverTextButton(
                    text: 'Forgot Password?',
                    onTap: () => context.go('/forgot-password'),
                  ),
                ],
              ).animate(delay: 250.ms).fadeIn(),
              const SizedBox(height: 10),

              // Error
              if (authState.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.crimson.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.crimson.withValues(alpha: 0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: AppColors.crimson, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(authState.error!,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: AppColors.crimson))),
                  ]),
                ).animate().fadeIn().slideY(begin: -0.1, end: 0),

              // Sign In button
              _GoldenSignInButton(
                isLoading: authState.isLoading,
                onTap: _login,
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2, end: 0),

              const SizedBox(height: 24),

              Row(children: [
                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.10))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white.withValues(alpha: 0.30))),
                ),
                Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.10))),
              ]),
              const SizedBox(height: 16),

              _GoogleSignInButton(),
              const SizedBox(height: 24),
            ],

            Center(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.white.withValues(alpha: 0.45)),
                  children: [
                    const TextSpan(text: 'Don\'t have an account? '),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => context.go('/signup'),
                        child: const Text('Create one',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.golden,
                            )),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Left Panel ────────────────────────────────────────────────────────────────
class _LeftPanel extends StatelessWidget {
  final AnimationController orbCtrl;
  final AnimationController gradientCtrl;
  const _LeftPanel({required this.orbCtrl, required this.gradientCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([orbCtrl, gradientCtrl]),
      builder: (_, __) {
        final t  = orbCtrl.value;
        final gt = gradientCtrl.value;
        return Container(
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end:   Alignment.bottomRight,
              colors: [
                AppColors.deepVoid,
                Color.lerp(AppColors.richNavy, const Color(0xFF071E30), gt)!,
                Color.lerp(const Color(0xFF0A2240), const Color(0xFF051428), gt)!,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Grid texture
              Positioned.fill(
                child: Opacity(
                  opacity: 0.025,
                  child: CustomPaint(painter: _GridPainter()),
                ),
              ),
              // Orb 1 — teal top-right
              Positioned(
                top: -60 + t * 40,
                right: -80 + t * 30,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.15),
                        blurRadius: 200,
                        spreadRadius: 30,
                      ),
                    ],
                  ),
                ),
              ),
              // Orb 2 — golden bottom-left
              Positioned(
                bottom: -60 + t * 35,
                left: -60 + t * 20,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.golden.withValues(alpha: 0.10),
                        blurRadius: 160,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
              // Orb 3 — crimson mid
              Positioned(
                top: 200 + t * 50,
                left: -30 + t * 15,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.crimson.withValues(alpha: 0.07),
                        blurRadius: 100,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 56),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo + brand
                    Image.asset('assets/images/logo/final-logo.png', height: 64)
                        .animate().fadeIn(duration: 600.ms),
                    const SizedBox(height: 14),
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [AppColors.golden, AppColors.warmEmber],
                      ).createShader(b),
                      child: const Text('HIRAYA',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 5,
                        )),
                    ).animate().fadeIn(duration: 600.ms, delay: 100.ms),
                    Text('Innovation Marketplace',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.40),
                        letterSpacing: 2.5,
                      )).animate().fadeIn(duration: 600.ms, delay: 150.ms),

                    const Spacer(),

                    // Floating showcase card
                    _InnovationShowcaseCard()
                        .animate(delay: 400.ms).fadeIn(duration: 700.ms).slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 32),

                    // Animated stats
                    Row(
                      children: [
                        _StatBadge(value: '500+', label: 'Innovations')
                            .animate(delay: 600.ms).fadeIn(duration: 500.ms).slideX(begin: -0.2, end: 0),
                        const SizedBox(width: 16),
                        _StatBadge(value: '120+', label: 'Innovators')
                            .animate(delay: 700.ms).fadeIn(duration: 500.ms).slideX(begin: -0.2, end: 0),
                        const SizedBox(width: 16),
                        _StatBadge(value: '15+', label: 'Universities')
                            .animate(delay: 800.ms).fadeIn(duration: 500.ms).slideX(begin: -0.2, end: 0),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Trust indicators
                    Wrap(spacing: 12, runSpacing: 10, children: [
                      _TrustPill(icon: Icons.shield_rounded, label: 'Secure', color: AppColors.teal),
                      _TrustPill(icon: Icons.verified_rounded, label: 'Verified', color: AppColors.golden),
                      _TrustPill(icon: Icons.flag_rounded, label: 'Philippine-made', color: AppColors.crimson),
                    ]).animate(delay: 900.ms).fadeIn(duration: 600.ms),
                    const SizedBox(height: 16),

                    Text('Trusted by 15 Philippine universities',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.35),
                        letterSpacing: 0.5,
                      )).animate(delay: 1000.ms).fadeIn(duration: 600.ms),
                    const SizedBox(height: 4),
                    Text('© 2025 HIRAYA Innovation Marketplace',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.20),
                      )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ).animate().fadeIn(duration: 600.ms);
  }
}

// ── Innovation Showcase Card ──────────────────────────────────────────────────
class _InnovationShowcaseCard extends StatelessWidget {
  const _InnovationShowcaseCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDark, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.golden.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.golden.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lightbulb_rounded, color: AppColors.golden, size: 18),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Featured Innovation',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.golden,
                  letterSpacing: 0.5,
                )),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.teal.withValues(alpha: 0.30)),
              ),
              child: const Text('LIVE',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teal,
                  letterSpacing: 1,
                )),
            ),
          ]),
          const SizedBox(height: 14),
          const Text('AgriSense AI Platform',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            )),
          const SizedBox(height: 4),
          Text('Precision agriculture using AI for Filipino farmers',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.50),
            )),
          const SizedBox(height: 14),
          Row(children: [
            _MiniTag(label: 'Agriculture', color: AppColors.teal),
            const SizedBox(width: 8),
            _MiniTag(label: 'AI/ML', color: AppColors.sky),
            const Spacer(),
            Text('₱2.4M raised',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.golden.withValues(alpha: 0.90),
              )),
          ]),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  final Color color;
  const _MiniTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        )),
    );
  }
}

// ── Stat Badge ────────────────────────────────────────────────────────────────
class _StatBadge extends StatelessWidget {
  final String value, label;
  const _StatBadge({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [AppColors.golden, AppColors.warmEmber],
          ).createShader(b),
          child: Text(value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            )),
        ),
        Text(label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.40),
          )),
      ],
    );
  }
}

// ── Golden Text Field ─────────────────────────────────────────────────────────
class _GoldenTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final FocusNode? focusNode;

  const _GoldenTextField({
    required this.label,
    required this.controller,
    this.hint,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.focusNode,
  });

  @override
  State<_GoldenTextField> createState() => _GoldenTextFieldState();
}

class _GoldenTextFieldState extends State<_GoldenTextField> {
  bool _obscure = true;
  bool _focused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(() {
      if (mounted) setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _focused
                ? AppColors.golden
                : Colors.white.withValues(alpha: 0.60),
            letterSpacing: 0.5,
          )),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: AppColors.golden.withValues(alpha: 0.15),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.isPassword ? _obscure : false,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.white,
            ),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.25),
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon,
                      size: 18,
                      color: _focused
                          ? AppColors.golden.withValues(alpha: 0.70)
                          : Colors.white.withValues(alpha: 0.30))
                  : null,
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.white.withValues(alpha: 0.30),
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.borderDark,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.golden, width: 1.5),
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
          ),
        ),
      ],
    );
  }
}

// ── Animated Checkbox ─────────────────────────────────────────────────────────
class _AnimatedCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  const _AnimatedCheckbox({required this.value, required this.onChanged, required this.label});

  @override
  State<_AnimatedCheckbox> createState() => _AnimatedCheckboxState();
}

class _AnimatedCheckboxState extends State<_AnimatedCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 200.ms);
    if (widget.value) _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedCheckbox old) {
    super.didUpdateWidget(old);
    widget.value ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onChanged(!widget.value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: 200.ms,
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: widget.value
                  ? AppColors.golden
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: widget.value
                    ? AppColors.golden
                    : Colors.white.withValues(alpha: 0.30),
                width: 1.5,
              ),
            ),
            child: widget.value
                ? const Icon(Icons.check, size: 12, color: AppColors.navy)
                : null,
          ),
          const SizedBox(width: 8),
          Text(widget.label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.55),
            )),
        ],
      ),
    );
  }
}

// ── Hover Text Button ─────────────────────────────────────────────────────────
class _HoverTextButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  const _HoverTextButton({required this.text, required this.onTap});

  @override
  State<_HoverTextButton> createState() => _HoverTextButtonState();
}

class _HoverTextButtonState extends State<_HoverTextButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: 200.ms,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.golden,
            decoration: _hovered ? TextDecoration.underline : TextDecoration.none,
            decorationColor: AppColors.golden,
          ),
          child: Text(widget.text),
        ),
      ),
    );
  }
}

// ── Golden Sign In Button ─────────────────────────────────────────────────────
class _GoldenSignInButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _GoldenSignInButton({required this.isLoading, required this.onTap});

  @override
  State<_GoldenSignInButton> createState() => _GoldenSignInButtonState();
}

class _GoldenSignInButtonState extends State<_GoldenSignInButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.isLoading ? SystemMouseCursors.wait : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : _hovered ? 1.02 : 1.0,
          duration: 200.ms,
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: 200.ms,
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: widget.isLoading
                  ? null
                  : const LinearGradient(
                      colors: [AppColors.golden, AppColors.warmEmber],
                    ),
              color: widget.isLoading ? Colors.white.withValues(alpha: 0.08) : null,
              borderRadius: BorderRadius.circular(13),
              boxShadow: !widget.isLoading && _hovered
                  ? [
                      BoxShadow(
                        color: AppColors.golden.withValues(alpha: 0.40),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: AppColors.golden.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Stack(
              children: [
                // Shimmer on hover
                if (_hovered && !widget.isLoading)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: ShaderMask(
                        shaderCallback: (b) => LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.15),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                          begin: const Alignment(-1, 0),
                          end: const Alignment(1, 0),
                        ).createShader(b),
                        child: Container(color: Colors.white),
                      ),
                    ).animate(onPlay: (c) => c.repeat()).shimmer(
                      duration: 1500.ms,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Sign In',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.navy,
                          )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Google Sign In Button ─────────────────────────────────────────────────────
class _GoogleSignInButton extends ConsumerStatefulWidget {
  @override
  ConsumerState<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<_GoogleSignInButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: isLoading ? null : () => ref.read(authProvider.notifier).loginWithGoogle(),
        child: AnimatedContainer(
          duration: 200.ms,
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? Colors.white.withValues(alpha: 0.25)
                  : AppColors.borderDark,
              width: 1,
            ),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            // Google multicolor G
            SizedBox(
              width: 22,
              height: 22,
              child: CustomPaint(painter: _GoogleLogoPainter()),
            ),
            const SizedBox(width: 12),
            Text('Continue with Google',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.80),
              )),
          ]),
        ),
      ),
    );
  }
}

// ── Google Logo Painter ───────────────────────────────────────────────────────
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Blue segment
    final bluePaint = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        -math.pi / 6, math.pi * 2 / 3, true, bluePaint);

    // Red segment
    final redPaint = Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.fill;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        math.pi / 2, math.pi * 2 / 3, true, redPaint);

    // Yellow segment
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.fill;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius),
        math.pi * 7 / 6, math.pi * 2 / 3, true, yellowPaint);

    // White center
    canvas.drawCircle(center, radius * 0.55,
        Paint()..color = Colors.white.withValues(alpha: 0.08));

    // White G line (right side gap for Google arc)
    final gPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.45
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.55),
      -0.2,
      0.0,
      false,
      gPaint,
    );
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter old) => false;
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

// ── Trust Pill ────────────────────────────────────────────────────────────────
class _TrustPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _TrustPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color.withValues(alpha: 0.70)),
        const SizedBox(width: 5),
        Text(label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.80),
          )),
      ]),
    );
  }
}

// ── Status Banner ─────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final IconData icon;
  final Color    color;
  final String   title, message;

  const _StatusBanner({required this.icon, required this.color, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(message,
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white.withValues(alpha: 0.60), height: 1.4)),
        ])),
      ]),
    );
  }
}

// ── Grid Painter ──────────────────────────────────────────────────────────────
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
