import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/login_skeleton.dart';
// ignore_for_file: unused_element

// ═══════════════════════════════════════════════════════════
// LoginScreen — cinematic two-panel login
// ═══════════════════════════════════════════════════════════
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
  bool _rememberMe    = false;
  bool _showSkeleton  = true;
  String? _prevError;

  late AnimationController _bgCtrl;    // 8s gradient cycle
  late AnimationController _orbCtrl;   // 6s orb float
  late AnimationController _glowCtrl;  // 3s right-panel ambient glow
  late AnimationController _shakeCtrl;
  late Animation<double>   _shakeAnim;

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _orbCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));

    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -11.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -11.0, end: 11.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 11.0, end: -7.0),  weight: 2),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 3.5),   weight: 1),
      TweenSequenceItem(tween: Tween(begin: 3.5, end: 0.0),    weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.linear));

    Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _showSkeleton = false);
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _bgCtrl.dispose();
    _orbCtrl.dispose();
    _glowCtrl.dispose();
    _shakeCtrl.dispose();
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
    final size      = MediaQuery.of(context).size;

    if (authState.error != null && authState.error != _prevError) {
      _prevError = authState.error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _shakeCtrl.forward(from: 0);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 700),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          child: child,
        ),
        child: _showSkeleton
            ? const LoginSkeleton(key: ValueKey('skeleton'))
            : _buildMain(authState, size),
      ),
    );
  }

  Widget _buildMain(AuthState authState, Size size) {
    final wide = size.width > 900;
    return Row(
      key: const ValueKey('main'),
      children: [
        if (wide)
          Expanded(
            flex: 5,
            child: _LeftPanel(bgCtrl: _bgCtrl, orbCtrl: _orbCtrl),
          ),
        Expanded(
          flex: wide ? 4 : 1,
          child: _buildFormPanel(authState),
        ),
      ],
    );
  }

  Widget _buildFormPanel(AuthState authState) {
    return AnimatedBuilder(
      animation: _glowCtrl,
      builder: (_, child) {
        final t = _glowCtrl.value;
        return Container(
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.03 + t * 0.04),
                blurRadius: 60,
                offset: const Offset(-20, 0),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 52),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Back to Home ──────────────────────
                  const _BackToHomeButton()
                      .animate()
                      .fadeIn(duration: 380.ms, delay: 0.ms)
                      .slideX(begin: -0.08, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 32),

                  // ── Title block ───────────────────────
                  _buildTitle()
                      .animate(delay: 60.ms)
                      .fadeIn(duration: 440.ms)
                      .slideY(begin: 0.14, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 6),
                  const Text(
                    'Enter your credentials to continue your journey',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Colors.black38,
                      height: 1.55,
                    ),
                  ).animate(delay: 80.ms).fadeIn(duration: 400.ms),
                  const SizedBox(height: 28),

                  // ── Email ─────────────────────────────
                  AuthTextField(
                    label: 'Email Address',
                    controller: _emailCtrl,
                    hint: 'you@example.com',
                    keyboardType: TextInputType.emailAddress,
                    prefix: const Icon(Icons.email_outlined,
                        size: 18, color: Colors.black38),
                    validator: (v) {
                      if (v == null ||
                          !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  )
                      .animate(delay: 120.ms)
                      .fadeIn(duration: 420.ms)
                      .slideY(begin: 0.10, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 16),

                  // ── Password ──────────────────────────
                  AuthTextField(
                    label: 'Password',
                    controller: _passwordCtrl,
                    isPassword: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter your password';
                      return null;
                    },
                  )
                      .animate(delay: 175.ms)
                      .fadeIn(duration: 420.ms)
                      .slideY(begin: 0.10, end: 0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 14),

                  // ── Remember me + Forgot ──────────────
                  Row(
                    children: [
                      _AnimatedCheckbox(
                        value: _rememberMe,
                        onChanged: (v) =>
                            setState(() => _rememberMe = v ?? false),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Remember me',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.black45,
                        ),
                      ),
                      const Spacer(),
                      const _ForgotPasswordButton(),
                    ],
                  ).animate(delay: 215.ms).fadeIn(duration: 380.ms),

                  // ── Error banner ──────────────────────
                  if (authState.error != null) ...[
                    const SizedBox(height: 14),
                    AnimatedBuilder(
                      animation: _shakeAnim,
                      builder: (_, child) => Transform.translate(
                          offset: Offset(_shakeAnim.value, 0),
                          child: child!),
                      child: _ErrorBanner(message: authState.error!),
                    ).animate().fadeIn(duration: 280.ms).slideY(begin: -0.08, end: 0),
                  ],

                  const SizedBox(height: 22),

                  // ── Sign In button ────────────────────
                  _LoginButton(isLoading: authState.isLoading, onTap: _login)
                      .animate(delay: 255.ms)
                      .fadeIn(duration: 420.ms)
                      .slideY(begin: 0.10, end: 0, curve: Curves.easeOutCubic),

                  const SizedBox(height: 22),

                  // ── Divider ───────────────────────────
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.lightGray)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'or continue with',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.black.withValues(alpha: 0.28),
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.lightGray)),
                    ],
                  ).animate(delay: 295.ms).fadeIn(duration: 380.ms),
                  const SizedBox(height: 16),

                  // ── Social sign-in row ────────────────
                  const Row(
                    children: [
                      Expanded(child: _SocialButton(label: 'Google', icon: Icons.g_mobiledata_rounded)),
                      SizedBox(width: 12),
                      Expanded(child: _SocialButton(label: 'Apple',  icon: Icons.apple_rounded)),
                    ],
                  ).animate(delay: 330.ms).fadeIn(duration: 380.ms),
                  const SizedBox(height: 26),

                  // ── Create account ────────────────────
                  const Center(child: _CreateAccountLink())
                      .animate(delay: 370.ms)
                      .fadeIn(duration: 380.ms),
                  const SizedBox(height: 28),

                  // ── Trust badges ──────────────────────
                  const _TrustBadgesRow()
                      .animate(delay: 420.ms)
                      .fadeIn(duration: 400.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sign In',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            height: 1.1,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.teal, AppColors.sky]),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Left Panel — live animated gradient + floating orbs + content
// ═══════════════════════════════════════════════════════════
class _LeftPanel extends StatelessWidget {
  final AnimationController bgCtrl;
  final AnimationController orbCtrl;

  const _LeftPanel({required this.bgCtrl, required this.orbCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([bgCtrl, orbCtrl]),
      builder: (_, child) {
        final bg  = bgCtrl.value;
        final orb = orbCtrl.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(AppColors.navy,               const Color(0xFF041F33), bg)!,
                Color.lerp(const Color(0xFF064663), const Color(0xFF053E5E), bg)!,
                Color.lerp(AppColors.teal,               const Color(0xFF0D5A4F), bg)!,
              ],
            ),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // ── Dot-grid texture ──────────────────────
              Positioned.fill(
                child: CustomPaint(painter: _DotGridPainter()),
              ),
              // ── Scanline overlay ──────────────────────
              Positioned.fill(
                child: CustomPaint(painter: _ScanlinePainter()),
              ),
              // ── Vignette top gradient ─────────────────
              Positioned(
                top: 0, left: 0, right: 0,
                height: 160,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // ── Orb 1 — teal (large, top-left) ───────
              _Orb(
                color: AppColors.teal,
                size: 380,
                alpha: 0.20,
                x: -90,
                y: -90.0 + math.sin(orb * math.pi * 2) * 22,
                alignRight: false,
                alignBottom: false,
              ),
              // ── Orb 2 — sky (mid, bottom-right) ──────
              _Orb(
                color: AppColors.sky,
                size: 260,
                alpha: 0.14,
                x: -50,
                y: 60.0 + math.sin((orb + 0.5) * math.pi * 2) * 18,
                alignRight: true,
                alignBottom: true,
              ),
              // ── Orb 3 — golden (small, bottom-left) ──
              _Orb(
                color: AppColors.golden,
                size: 180,
                alpha: 0.11,
                x: 30,
                y: -20.0 + math.sin((orb + 0.25) * math.pi * 2) * 14,
                alignRight: false,
                alignBottom: true,
              ),
              // ── Static content ────────────────────────
              child!,
            ],
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 56),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Image.asset('assets/images/logo/final-logo.png', height: 72)
                .animate().fadeIn(duration: 600.ms),
            const SizedBox(height: 22),

            // "HIRAYA" with per-letter stagger
            const _LetterStagger(
              text: 'HIRAYA',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 52,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 10,
              ),
              baseDelay: 100,
              letterDelay: 65,
            ),
            const SizedBox(height: 10),
            const Text(
              'Where Innovation\nMeets Opportunity',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                color: Colors.white60,
                height: 1.65,
              ),
            ).animate(delay: 560.ms).fadeIn(duration: 600.ms),
            const SizedBox(height: 44),

            // Welcome text
            const Text(
              'Welcome back!',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.golden,
                letterSpacing: 0.3,
              ),
            )
                .animate(delay: 640.ms)
                .fadeIn(duration: 600.ms)
                .slideX(begin: -0.08, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 6),
            const Text(
              'Sign in to continue your innovation journey.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.white54,
                height: 1.55,
              ),
            ).animate(delay: 700.ms).fadeIn(duration: 600.ms),
            const SizedBox(height: 44),

            // Stats strip
            const _LeftStatsStrip()
                .animate(delay: 780.ms)
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Back to Home Button — arrow slides left on hover
// ═══════════════════════════════════════════════════════════
class _BackToHomeButton extends StatefulWidget {
  const _BackToHomeButton();

  @override
  State<_BackToHomeButton> createState() => _BackToHomeButtonState();
}

class _BackToHomeButtonState extends State<_BackToHomeButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go('/'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.navy.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSlide(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                offset: _hovered ? const Offset(-0.25, 0) : Offset.zero,
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 16,
                  color: _hovered ? AppColors.navy : Colors.black45,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Back to Home',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: _hovered ? FontWeight.w600 : FontWeight.w500,
                  color: _hovered ? AppColors.navy : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Forgot Password Button — animated underline on hover
// ═══════════════════════════════════════════════════════════
class _ForgotPasswordButton extends StatefulWidget {
  const _ForgotPasswordButton();

  @override
  State<_ForgotPasswordButton> createState() => _ForgotPasswordButtonState();
}

class _ForgotPasswordButtonState extends State<_ForgotPasswordButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go('/forgot-password'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Forgot Password?',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _hovered ? AppColors.navy : AppColors.teal,
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 1.5,
              width: _hovered ? 112 : 0,
              decoration: BoxDecoration(
                color: AppColors.teal,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Animated Checkbox — spring bounce on toggle, teal glow
// ═══════════════════════════════════════════════════════════
class _AnimatedCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _AnimatedCheckbox({required this.value, required this.onChanged});

  @override
  State<_AnimatedCheckbox> createState() => _AnimatedCheckboxState();
}

class _AnimatedCheckboxState extends State<_AnimatedCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    // Spring bounce: 1.0 → 0.75 → 1.18 → 1.0
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.72), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.72, end: 1.20), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 1.20, end: 1.0),  weight: 1),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.linear));
  }

  @override
  void didUpdateWidget(_AnimatedCheckbox old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value) {
      _ctrl.forward(from: 0);
    }
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
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: widget.value ? AppColors.teal : Colors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: widget.value ? AppColors.teal : AppColors.lightGray,
              width: 1.5,
            ),
            boxShadow: widget.value
                ? [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.30),
                      blurRadius: 8,
                    )
                  ]
                : [],
          ),
          child: widget.value
              ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Error Banner — red tinted card with icon
// ═══════════════════════════════════════════════════════════
class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.crimson.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.crimson.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.crimson.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.crimson,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: AppColors.crimson,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Login Button — gradient fill, shimmer sweep on hover,
//                arrow slides in, loading dots when busy
// ═══════════════════════════════════════════════════════════
class _LoginButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _LoginButton({required this.isLoading, required this.onTap});

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.isLoading
          ? SystemMouseCursors.wait
          : SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovered = true);
        if (!widget.isLoading) _shimmerCtrl.repeat();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _shimmerCtrl
          ..stop()
          ..reset();
      },
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            height: 54,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _hovered && !widget.isLoading
                    ? [AppColors.teal, const Color(0xFF0A4E44)]
                    : [AppColors.navy, const Color(0xFF054468)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: (_hovered ? AppColors.teal : AppColors.navy)
                      .withValues(alpha: _hovered ? 0.42 : 0.28),
                  blurRadius: _hovered ? 22 : 8,
                  offset: const Offset(0, 4),
                  spreadRadius: _hovered ? 1 : 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  // Shimmer sweep
                  if (_hovered && !widget.isLoading)
                    AnimatedBuilder(
                      animation: _shimmerCtrl,
                      builder: (ctx, _) => Positioned(
                        left: -80 + _shimmerCtrl.value * 580,
                        top: 0,
                        bottom: 0,
                        width: 80,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.14),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Label / loading state
                  Center(
                    child: widget.isLoading
                        ? const _LoadingDots()
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutBack,
                                child: _hovered
                                    ? const Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 17,
                                        ),
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Loading Dots — three bouncing dots for loading state
// ═══════════════════════════════════════════════════════════
class _LoadingDots extends StatelessWidget {
  const _LoadingDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        )
            .animate(
              delay: Duration(milliseconds: 140 * i),
              onPlay: (ctrl) => ctrl.repeat(reverse: true),
            )
            .slideY(
              begin: 0,
              end: -0.65,
              duration: 390.ms,
              curve: Curves.easeInOut,
            );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Create Account Link — hover underline sweep + color shift
// ═══════════════════════════════════════════════════════════
class _CreateAccountLink extends StatefulWidget {
  const _CreateAccountLink();

  @override
  State<_CreateAccountLink> createState() => _CreateAccountLinkState();
}

class _CreateAccountLinkState extends State<_CreateAccountLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Don't have an account? ",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: () => context.go('/signup'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Create one',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _hovered ? AppColors.navy : AppColors.teal,
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 1.5,
                  width: _hovered ? 70 : 0,
                  decoration: BoxDecoration(
                    color: AppColors.teal,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// _Orb — positioned radial-gradient circle
// ═══════════════════════════════════════════════════════════
class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  final double alpha;
  final double x;
  final double y;
  final bool alignRight;
  final bool alignBottom;

  const _Orb({
    required this.color,
    required this.size,
    required this.alpha,
    required this.x,
    required this.y,
    required this.alignRight,
    required this.alignBottom,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top:    alignBottom ? null : y,
      bottom: alignBottom ? y   : null,
      left:   alignRight  ? null : x,
      right:  alignRight  ? x   : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: alpha), Colors.transparent],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// _DotGridPainter — 28px grid of 1px dots
// ═══════════════════════════════════════════════════════════
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => false;
}

// ═══════════════════════════════════════════════════════════
// _ScanlinePainter — horizontal lines every 4px, ultra-faint
// ═══════════════════════════════════════════════════════════
class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.025)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter old) => false;
}

// ═══════════════════════════════════════════════════════════
// _LetterStagger — animates each letter of a text string
//                  individually with a cascade delay
// ═══════════════════════════════════════════════════════════
class _LetterStagger extends StatelessWidget {
  final String text;
  final TextStyle style;
  final int baseDelay;
  final int letterDelay;

  const _LetterStagger({
    required this.text,
    required this.style,
    this.baseDelay = 100,
    this.letterDelay = 65,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(text.length, (i) {
        return Text(text[i], style: style)
            .animate(delay: Duration(milliseconds: baseDelay + i * letterDelay))
            .fadeIn(duration: 480.ms)
            .slideY(begin: 0.35, end: 0, curve: Curves.easeOutBack);
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// _LeftStatsStrip — frosted glass stats row on left panel
// ═══════════════════════════════════════════════════════════
class _LeftStatsStrip extends StatelessWidget {
  const _LeftStatsStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(value: '500+', label: 'Innovations'),
          _StatDivider(),
          _StatItem(value: '120+', label: 'Innovators'),
          _StatDivider(),
          _StatItem(value: '6',    label: 'Categories'),
          _StatDivider(),
          _StatItem(value: '100%', label: 'Secure'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.golden,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// _SocialButton — ghost outline button for social sign-in
// ═══════════════════════════════════════════════════════════
class _SocialButton extends StatefulWidget {
  final String label;
  final IconData icon;

  const _SocialButton({required this.label, required this.icon});

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown:   (_) => setState(() => _pressed = true),
        onTapUp:     (_) => setState(() => _pressed = false),
        onTapCancel: ()  => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 110),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 46,
            decoration: BoxDecoration(
              color: _hovered
                  ? AppColors.navy.withValues(alpha: 0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hovered ? AppColors.navy.withValues(alpha: 0.35) : AppColors.lightGray,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon,
                    size: 20,
                    color: _hovered ? AppColors.navy : Colors.black45),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _hovered ? AppColors.navy : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// _TrustBadgesRow — SSL / RA10173 / KYC verified badges
// ═══════════════════════════════════════════════════════════
class _TrustBadgesRow extends StatelessWidget {
  const _TrustBadgesRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _TrustBadge(icon: Icons.lock_outline_rounded,     label: 'SSL Secured'),
          _TrustBadgeDivider(),
          _TrustBadge(icon: Icons.gavel_rounded,            label: 'RA 10173'),
          _TrustBadgeDivider(),
          _TrustBadge(icon: Icons.verified_user_outlined,   label: 'KYC Verified'),
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.teal),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
      ],
    );
  }
}

class _TrustBadgeDivider extends StatelessWidget {
  const _TrustBadgeDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: AppColors.lightGray,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Grid Painter (kept for legacy compat)
// ═══════════════════════════════════════════════════════════
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
