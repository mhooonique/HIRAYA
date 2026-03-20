// lib/features/auth/screens/unified_auth_screen.dart
//
// UnifiedAuthScreen — Login + Signup + Forgot Password in one screen with smooth
// slide transitions. Desktop: Left decorative panel + Right form card.
// Mobile: Full-screen form card with brand header.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/ph_address_data.dart';
import '../../../core/services/api_service.dart';
import '../providers/auth_provider.dart';

// ── Auth Mode ─────────────────────────────────────────────────────────────────

enum AuthMode { login, signup, forgotPassword }

// =============================================================================
// UnifiedAuthScreen — public entry point
// =============================================================================

class UnifiedAuthScreen extends ConsumerStatefulWidget {
  const UnifiedAuthScreen({super.key, this.initialMode = AuthMode.login});

  final AuthMode initialMode;

  @override
  ConsumerState<UnifiedAuthScreen> createState() => _UnifiedAuthScreenState();
}

class _UnifiedAuthScreenState extends ConsumerState<UnifiedAuthScreen>
    with TickerProviderStateMixin {
  late AuthMode _mode;
  late final PageController _pageCtrl;

  // Animation controllers shared across modes
  late AnimationController _orbCtrl;
  late AnimationController _gradientCtrl;
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _mode     = widget.initialMode;
    _pageCtrl = PageController(initialPage: _modeIndex(_mode));

    _orbCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 7))
      ..repeat(reverse: true);
    _gradientCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat(reverse: true);
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _orbCtrl.dispose();
    _gradientCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  int _modeIndex(AuthMode m) => switch (m) {
    AuthMode.login => 0,
    AuthMode.signup => 1,
    AuthMode.forgotPassword => 2,
  };

  void _switchMode(AuthMode to) {
    if (_mode == to) return;
    setState(() => _mode = to);
    _pageCtrl.animateToPage(
      _modeIndex(to),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size      = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: AppColors.deepVoid,
      body: isDesktop
          ? Row(
              children: [
                // Left decorative panel (desktop only)
                Expanded(
                  flex: 2,
                  child: _LeftPanel(
                    orbCtrl:      _orbCtrl,
                    gradientCtrl: _gradientCtrl,
                  ),
                ),
                // Right: sliding form pane
                Expanded(
                  flex: 3,
                  child: _RightShell(
                    pageCtrl:    _pageCtrl,
                    mode:        _mode,
                    onSwitchMode: _switchMode,
                    shimmerCtrl: _shimmerCtrl,
                  ),
                ),
              ],
            )
          : _RightShell(
              pageCtrl:    _pageCtrl,
              mode:        _mode,
              onSwitchMode: _switchMode,
              shimmerCtrl: _shimmerCtrl,
              isMobile:    true,
            ),
    );
  }
}

// =============================================================================
// Right shell — PageView with login / signup / forgotPassword pages
// =============================================================================

class _RightShell extends ConsumerWidget {
  const _RightShell({
    required this.pageCtrl,
    required this.mode,
    required this.onSwitchMode,
    required this.shimmerCtrl,
    this.isMobile = false,
  });

  final PageController              pageCtrl;
  final AuthMode                    mode;
  final ValueChanged<AuthMode>      onSwitchMode;
  final AnimationController         shimmerCtrl;
  final bool                        isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: [AppColors.darkSurface, Color(0xFF0F1F2E), AppColors.midnight],
        ),
      ),
      child: Stack(
        children: [
          // Grid texture
          Positioned.fill(
            child: Opacity(
              opacity: 0.02,
              child: CustomPaint(painter: _GridPainter()),
            ),
          ),
          // Corner glow
          Positioned(
            top:   -80,
            right: -80,
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:       AppColors.golden.withValues(alpha: 0.06),
                    blurRadius:  120,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          // Mobile brand header
          if (isMobile)
            Positioned(
              top:  56,
              left: 0, right: 0,
              child: Column(
                children: [
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [AppColors.golden, AppColors.warmEmber],
                    ).createShader(b),
                    child: const Text(
                      'Digital Platform',
                      style: TextStyle(
                        fontFamily:  'Poppins',
                        fontSize:    22,
                        fontWeight:  FontWeight.w900,
                        color:       Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Where Filipino Innovation Soars',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize:   11,
                      color:      Colors.white.withValues(alpha: 0.35),
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 500.ms),
            ),
          Positioned(
            top: isMobile ? 116 : 26,
            left: 0,
            right: 0,
            child: Center(
              child: _ModeDock(
                mode: mode,
                onModeTap: onSwitchMode,
              ),
            ),
          ),
          // Page content
          PageView(
            controller: pageCtrl,
            physics:    const NeverScrollableScrollPhysics(),
            children: [
              // Page 0: Login
              _LoginPage(
                onForgotTap:  () => onSwitchMode(AuthMode.forgotPassword),
                onCreateTap: () => onSwitchMode(AuthMode.signup),
                shimmerCtrl:  shimmerCtrl,
                isMobile:     isMobile,
              ),
              // Page 1: Signup
              _SignupPage(
                onBackToLogin: () => onSwitchMode(AuthMode.login),
                onForgotTap: () => onSwitchMode(AuthMode.forgotPassword),
                isMobile: isMobile,
              ),
              // Page 2: Forgot Password
              _ForgotPasswordPage(
                onBackToLogin: () => onSwitchMode(AuthMode.login),
                onCreateTap: () => onSwitchMode(AuthMode.signup),
                isMobile:      isMobile,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeDock extends StatelessWidget {
  const _ModeDock({
    required this.mode,
    required this.onModeTap,
  });

  final AuthMode mode;
  final ValueChanged<AuthMode> onModeTap;

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String tooltip, AuthMode value) {
      final active = mode == value;
      return Expanded(
        child: Tooltip(
          message: tooltip,
          child: GestureDetector(
            onTap: () => onModeTap(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: 44,
              decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(
                        colors: [AppColors.golden, AppColors.warmEmber],
                      )
                    : null,
                color: active
                    ? null
                    : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.08),
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.golden.withValues(alpha: 0.30),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                icon,
                size: 18,
                color: active
                    ? AppColors.navy
                    : Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
          ),
          child: Row(
            children: [
              item(Icons.login_rounded, 'Sign In', AuthMode.login),
              const SizedBox(width: 6),
              item(Icons.person_add_alt_1_rounded, 'Create Account', AuthMode.signup),
              const SizedBox(width: 6),
              item(Icons.lock_reset_rounded, 'Recover Access', AuthMode.forgotPassword),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 450.ms).slideY(begin: -0.12, end: 0);
  }
}

// =============================================================================
// Login Page
// =============================================================================

class _LoginPage extends ConsumerStatefulWidget {
  const _LoginPage({
    required this.onForgotTap,
    required this.onCreateTap,
    required this.shimmerCtrl,
    required this.isMobile,
  });

  final VoidCallback        onForgotTap;
  final VoidCallback        onCreateTap;
  final AnimationController shimmerCtrl;
  final bool                isMobile;

  @override
  ConsumerState<_LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<_LoginPage> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  final _passFocus    = FocusNode();
  bool  _rememberMe   = false;
  bool  _obscurePass  = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passFocus.dispose();
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
    final isPending  = authState.loginStatus == LoginStatus.pending;
    final isRejected = authState.loginStatus == LoginStatus.rejected;

    ref.listen<AuthState>(authProvider, (prev, next) {
      if (!mounted) return;
      if (next.needsGoogleSignup && !(prev?.needsGoogleSignup ?? false)) {
        widget.onCreateTap();
        return;
      }
      if (next.requires2fa && !(prev?.requires2fa ?? false)) {
        context.go('/otp');
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

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left:   32, right: 32,
          top:    widget.isMobile ? 164 : 32,
          bottom: 32,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: _GlassCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back link
                  TextButton.icon(
                    onPressed: () => context.go('/'),
                    icon: Icon(Icons.arrow_back, size: 16,
                        color: Colors.white.withValues(alpha: 0.45)),
                    label: Text('Back to Home',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.45),
                        )),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 20),

                  // Title
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [Colors.white, Color(0xFFCBD5E1)],
                    ).createShader(b),
                    child: const Text('Sign In',
                      style: TextStyle(
                        fontFamily:  'Poppins',
                        fontSize:    32,
                        fontWeight:  FontWeight.w800,
                        color:       Colors.white,
                        letterSpacing: -0.5,
                      )),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 6),
                  Text('Sign in to your Digital Platform account',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.45),
                    )),
                  const SizedBox(height: 28),

                  // Banners
                  if (isPending)
                    _StatusBanner(
                      icon: Icons.hourglass_top_rounded,
                      color: AppColors.golden,
                      title: 'Account Pending Approval',
                      message: 'Your account is awaiting admin approval.',
                    ).animate().fadeIn().slideY(begin: -0.1, end: 0),
                  if (isRejected)
                    _StatusBanner(
                      icon: Icons.block_rounded,
                      color: AppColors.crimson,
                      title: 'Account Rejected',
                      message: 'Your registration was not approved. Contact support.',
                    ).animate().fadeIn().slideY(begin: -0.1, end: 0),

                  if (!isPending && !isRejected) ...[
                    // Email
                    _AuthTextField(
                      label:        'Email Address',
                      controller:   _emailCtrl,
                      hint:         'you@gmail.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon:   Icons.email_outlined,
                      validator: (v) =>
                          (v == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v))
                              ? 'Enter a valid email'
                              : null,
                    ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.15, end: 0),
                    const SizedBox(height: 16),

                    // Password
                    _AuthTextField(
                      label:      'Password',
                      controller: _passwordCtrl,
                      isPassword: true,
                      focusNode:  _passFocus,
                      obscure:    _obscurePass,
                      onObscureToggle: () =>
                          setState(() => _obscurePass = !_obscurePass),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Enter your password' : null,
                    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.15, end: 0),
                    const SizedBox(height: 14),

                    // Remember me + Forgot
                    Row(
                      children: [
                        _AnimatedCheckbox(
                          value:     _rememberMe,
                          onChanged: (v) => setState(() => _rememberMe = v ?? false),
                          label:     'Remember me',
                        ),
                        const Spacer(),
                        _HoverTextButton(
                          text:  'Forgot Password?',
                          onTap: widget.onForgotTap,
                        ),
                      ],
                    ).animate(delay: 250.ms).fadeIn(),
                    const SizedBox(height: 10),

                    // Error
                    if (authState.error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin:  const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.crimson.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.crimson.withValues(alpha: 0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.crimson, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(authState.error!,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: AppColors.crimson,
                              )),
                          ),
                        ]),
                      ).animate().fadeIn().slideY(begin: -0.1, end: 0),

                    // Sign In button
                    _GoldenButton(
                      label:     'Sign In',
                      icon:      Icons.login_rounded,
                      isLoading: authState.isLoading,
                      onTap:     _login,
                    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 24),

                    // Divider
                    Row(children: [
                      Expanded(child: Divider(
                          color: Colors.white.withValues(alpha: 0.10))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize:   13,
                            color: Colors.white.withValues(alpha: 0.30),
                          )),
                      ),
                      Expanded(child: Divider(
                          color: Colors.white.withValues(alpha: 0.10))),
                    ]),
                    const SizedBox(height: 16),

                    // Google
                    _GoogleButton(ref: ref),
                    const SizedBox(height: 24),
                  ],

                  // Create account
                  Center(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize:   14,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                        children: [
                          const TextSpan(text: 'Don\'t have an account? '),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: widget.onCreateTap,
                              child: const Text('Create one',
                                style: TextStyle(
                                  fontFamily:  'Poppins',
                                  fontSize:    14,
                                  fontWeight:  FontWeight.w700,
                                  color:       AppColors.golden,
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
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Signup Page (quick account setup, then continue to full KYC flow)
// =============================================================================

class _SignupPage extends ConsumerStatefulWidget {
  const _SignupPage({
    required this.onBackToLogin,
    required this.onForgotTap,
    required this.isMobile,
  });

  final VoidCallback onBackToLogin;
  final VoidCallback onForgotTap;
  final bool         isMobile;

  @override
  ConsumerState<_SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<_SignupPage> {
  final _data = SignupData();
  int _step = 1;
  int _prevStep = 1;
  String? _stepError;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String? _selectedSuffix;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _phoneSending = false;
  bool _phoneOtpSent = false;
  bool _phoneVerified = false;
  String _verificationId = '';
  String? _phoneOtpError;

  String? _govIdBase64;
  String? _govIdFileName;
  String? _selfieBase64;
  String? _selfieFileName;
  String? _selectedProvince;
  String? _selectedCity;
  DateTime? _dateOfBirth;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPassCtrl.dispose();
    _phoneCtrl.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    if (auth.needsGoogleSignup) {
      _emailCtrl.text = auth.googlePrefillEmail;
      _firstNameCtrl.text = auth.googlePrefillFirstName;
      _lastNameCtrl.text = auth.googlePrefillLastName;
      _data
        ..isGoogleSignup = true
        ..googleId = auth.googlePrefillGoogleId;
      ref.read(authProvider.notifier).clearGooglePrefill();
    }
  }

  int get _totalSteps => _data.isGoogleSignup ? 6 : 7;

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  int get _passwordScore {
    final password = _passwordCtrl.text;
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    return score;
  }

  bool get _passwordsMatch =>
      _confirmPassCtrl.text.isNotEmpty &&
      _passwordCtrl.text == _confirmPassCtrl.text;

  void _goStep(int step) {
    setState(() {
      _prevStep = _step;
      _step = step;
      _stepError = null;
    });
  }

  void _next() {
    setState(() => _stepError = null);

    switch (_step) {
      case 1:
        if (_data.role.isEmpty) {
          setState(() => _stepError = 'Please choose a role to continue.');
          return;
        }
        break;

      case 2:
        _data
          ..firstName = _firstNameCtrl.text.trim()
          ..lastName = _lastNameCtrl.text.trim()
          ..middleName = _middleNameCtrl.text.trim()
          ..suffix = _selectedSuffix ?? ''
          ..username = _usernameCtrl.text.trim()
          ..email = _emailCtrl.text.trim();

        if (_data.firstName.isEmpty || _data.lastName.isEmpty ||
            _data.username.isEmpty || _data.email.isEmpty) {
          setState(() => _stepError = 'Please fill in all required fields.');
          return;
        }
        if (_data.username.length < 4 || _data.username.length > 30) {
          setState(() => _stepError = 'Username must be 4–30 characters.');
          return;
        }
        if (!_data.email.endsWith('@gmail.com')) {
          setState(() => _stepError = 'Only @gmail.com addresses are accepted.');
          return;
        }
        if (_data.isGoogleSignup) {
          _goStep(4);
          return;
        }
        break;

      case 3:
        _data.password = _passwordCtrl.text;
        if (_data.password.length < 8) {
          setState(() => _stepError = 'Password must be at least 8 characters.');
          return;
        }
        if (_data.password != _confirmPassCtrl.text) {
          setState(() => _stepError = 'Passwords do not match.');
          return;
        }
        break;

      case 4:
        _data.phone = _phoneCtrl.text.trim();
        if (_data.phone.isEmpty) {
          setState(() => _stepError = 'Phone number is required.');
          return;
        }
        if (!_phoneVerified) {
          setState(() => _stepError = 'Please verify your phone number first.');
          return;
        }
        break;

      case 5:
        if (_dateOfBirth == null || _selectedProvince == null || _selectedCity == null) {
          setState(() => _stepError = 'Complete date of birth, province, and city.');
          return;
        }
        if (_govIdBase64 == null || _selfieBase64 == null) {
          setState(() => _stepError = 'Government ID and selfie are both required.');
          return;
        }
        _data
          ..dateOfBirth = '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}'
          ..province = _selectedProvince!
          ..city = _selectedCity!
          ..govIdBase64 = _govIdBase64
          ..govIdFileName = _govIdFileName
          ..selfieBase64 = _selfieBase64
          ..selfieFileName = _selfieFileName;
        break;

      case 6:
        if (!_data.privacyAccepted || !_data.dataConsentAccepted) {
          setState(() => _stepError = 'You need to accept all consent terms to continue.');
          return;
        }
        break;

      case 7:
        _submitSignup();
        return;
    }

    _goStep(_step + 1);
  }

  void _back() {
    if (_step == 1) {
      widget.onBackToLogin();
      return;
    }
    if (_step == 4 && _data.isGoogleSignup) {
      _goStep(2);
      return;
    }
    _goStep(_step - 1);
  }

  Future<void> _sendPhoneOtp() async {
    final rawPhone = _phoneCtrl.text.trim();
    if (rawPhone.isEmpty) {
      setState(() => _stepError = 'Enter a phone number first.');
      return;
    }

    final fullPhone = '${_data.countryCode}$rawPhone';
    setState(() {
      _phoneSending = true;
      _phoneOtpError = null;
    });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: fullPhone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (mounted) {
          setState(() {
            _phoneVerified = true;
            _phoneSending = false;
            _phoneOtpSent = false;
          });
        }
      },
      verificationFailed: (e) {
        if (mounted) {
          setState(() {
            _phoneSending = false;
            _phoneOtpError = e.message ?? 'Verification failed. Check your phone number.';
          });
        }
      },
      codeSent: (verificationId, _) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _phoneOtpSent = true;
            _phoneSending = false;
          });
        }
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> _verifyPhoneOtp() async {
    if (_otpCode.length < 6) return;
    setState(() {
      _phoneSending = true;
      _phoneOtpError = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpCode,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) {
        setState(() {
          _phoneVerified = true;
          _phoneSending = false;
          _phoneOtpSent = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _phoneSending = false;
          _phoneOtpError = 'Invalid verification code. Try again.';
        });
      }
    }
  }

  void _onOtpChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '').split('');
      for (int i = 0; i < 6 && i < digits.length; i++) {
        _otpControllers[i].text = digits[i];
      }
      final next = digits.length < 6 ? digits.length : 5;
      _otpFocusNodes[next].requestFocus();
      setState(() {});
      if (_otpCode.length == 6) _verifyPhoneOtp();
      return;
    }

    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }
    setState(() {});
    if (_otpCode.length == 6) _verifyPhoneOtp();
  }

  Future<void> _pickFile(bool isGovId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    final file = result.files.single;
    final base64 = base64Encode(file.bytes!);

    setState(() {
      if (isGovId) {
        _govIdBase64 = base64;
        _govIdFileName = file.name;
      } else {
        _selfieBase64 = base64;
        _selfieFileName = file.name;
      }
    });
  }

  bool _isImageFile(String? fileName) {
    if (fileName == null) return false;
    return RegExp(r'\.(jpg|jpeg|png|webp)$', caseSensitive: false).hasMatch(fileName);
  }

  Uint8List? _safeDecode(String? b64) {
    if (b64 == null) return null;
    try {
      return base64Decode(b64);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1950, 1, 1),
      lastDate: DateTime.now(),
      helpText: 'Select your birth date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.golden,
              onPrimary: AppColors.navy,
              surface: AppColors.darkSurface,
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.darkSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  void _showAttachmentPreview(String title, String? b64, String? fileName) {
    final bytes = _safeDecode(b64);
    if (bytes == null || !_isImageFile(fileName)) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                fileName ?? 'Attached image',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InteractiveViewer(
                  maxScale: 4,
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConsentModule({
    required String title,
    required List<_ConsentClause> clauses,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.80,
        maxChildSize: 0.94,
        minChildSize: 0.60,
        expand: false,
        builder: (context, controller) => Container(
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.golden.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.gavel_rounded, color: AppColors.golden, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  itemCount: clauses.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final clause = clauses[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clause.title,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.golden,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            clause.body,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.62),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ).animate(delay: Duration(milliseconds: i * 40)).fadeIn(duration: 240.ms);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _GoldenButton(
                  label: 'I Understand',
                  icon: Icons.check_rounded,
                  isLoading: false,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitSignup() async {
    setState(() => _stepError = null);
    await ref.read(authProvider.notifier).signup(_data);
    if (!mounted) return;

    final auth = ref.read(authProvider);
    if (auth.error != null) {
      setState(() => _stepError = auth.error);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.teal.withValues(alpha: 0.32)),
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 40),
              ),
              const SizedBox(height: 14),
              const Text(
                'Registration Submitted',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your account is now pending admin approval. We will notify you through Gmail once approved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.55),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              _GoldenButton(
                label: 'Back to Sign In',
                icon: Icons.arrow_back_rounded,
                isLoading: false,
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onBackToLogin();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final displayStep = (_data.isGoogleSignup && _step >= 4) ? _step - 1 : _step;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 32,
          right: 32,
          top: widget.isMobile ? 176 : 92,
          bottom: 32,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: _back,
                  icon: Icon(Icons.arrow_back, size: 16, color: Colors.white.withValues(alpha: 0.45)),
                  label: Text(
                    _step == 1 ? 'Back to Sign In' : 'Previous Step',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ).animate().fadeIn(duration: 280.ms),
                const SizedBox(height: 8),
                const Text(
                  'Create Your Account',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ).animate().fadeIn(duration: 380.ms).slideY(begin: 0.08, end: 0),
                const SizedBox(height: 8),
                Text(
                  '${_stepTitle(_step)} • Step $displayStep of $_totalSteps',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.46),
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: displayStep / _totalSteps,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.07),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.golden),
                  ),
                ),
                const SizedBox(height: 18),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  transitionBuilder: (child, anim) => SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(_step > _prevStep ? 0.08 : -0.08, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: _buildStepBody(),
                  ),
                ),

                if (_stepError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.crimson.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.crimson.withValues(alpha: 0.32)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.crimson, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _stepError!,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: AppColors.crimson,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                _GoldenButton(
                  label: _step == 7 ? 'Submit Application' : 'Continue',
                  icon: _step == 7 ? Icons.check_rounded : Icons.arrow_forward_rounded,
                  onTap: _next,
                  isLoading: authState.isLoading,
                ),
                const SizedBox(height: 12),
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                      children: [
                        const TextSpan(text: 'Already have an account? '),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: widget.onBackToLogin,
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.golden,
                              ),
                            ),
                          ),
                        ),
                        const TextSpan(text: '  •  '),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: widget.onForgotTap,
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.teal,
                              ),
                            ),
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
    );
  }

  String _stepTitle(int step) {
    switch (step) {
      case 1:
        return 'Choose Your Role';
      case 2:
        return 'Basic Information';
      case 3:
        return 'Create Password';
      case 4:
        return 'Phone Verification';
      case 5:
        return 'Identity Verification';
      case 6:
        return 'Terms & Consent';
      case 7:
        return 'Review & Submit';
      default:
        return 'Registration';
    }
  }

  Widget _buildStepBody() {
    switch (_step) {
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select how you will use Digital Platform.',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white54),
            ),
            const SizedBox(height: 12),
            _roleOption('client', 'Client', 'Browse and invest in innovative projects', Icons.person_outline_rounded),
            const SizedBox(height: 10),
            _roleOption('innovator', 'Innovator', 'Showcase and pitch your innovations', Icons.lightbulb_outline_rounded),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _AuthTextField(label: 'First Name', controller: _firstNameCtrl, hint: 'Juan', prefixIcon: Icons.person_outline)),
                const SizedBox(width: 10),
                Expanded(child: _AuthTextField(label: 'Last Name', controller: _lastNameCtrl, hint: 'Dela Cruz', prefixIcon: Icons.badge_outlined)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _AuthTextField(label: 'Middle Name', controller: _middleNameCtrl, hint: 'Optional', prefixIcon: Icons.account_circle_outlined)),
                const SizedBox(width: 10),
                Expanded(
                  child: _SuffixPicker(
                    value: _selectedSuffix,
                    onChanged: (v) => setState(() => _selectedSuffix = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _AuthTextField(label: 'Username', controller: _usernameCtrl, hint: 'minimum 4 chars', prefixIcon: Icons.alternate_email_rounded),
            const SizedBox(height: 10),
            _AuthTextField(
              label: 'Email (Gmail)',
              controller: _emailCtrl,
              hint: 'you@gmail.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            _AuthTextField(
              label: 'Password',
              controller: _passwordCtrl,
              isPassword: true,
              obscure: _obscurePass,
              onObscureToggle: () => setState(() => _obscurePass = !_obscurePass),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            _PasswordGuidePanel(
              password: _passwordCtrl.text,
              score: _passwordScore,
            ),
            const SizedBox(height: 10),
            _AuthTextField(
              label: 'Confirm Password',
              controller: _confirmPassCtrl,
              isPassword: true,
              obscure: _obscureConfirm,
              onObscureToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _confirmPassCtrl.text.isEmpty
                    ? Colors.white.withValues(alpha: 0.03)
                    : _passwordsMatch
                        ? AppColors.teal.withValues(alpha: 0.14)
                        : AppColors.crimson.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _confirmPassCtrl.text.isEmpty
                      ? Colors.white.withValues(alpha: 0.10)
                      : _passwordsMatch
                          ? AppColors.teal.withValues(alpha: 0.45)
                          : AppColors.crimson.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _confirmPassCtrl.text.isEmpty
                        ? Icons.lock_clock_rounded
                        : _passwordsMatch
                            ? Icons.verified_rounded
                            : Icons.error_outline_rounded,
                    color: _confirmPassCtrl.text.isEmpty
                        ? Colors.white54
                        : _passwordsMatch
                            ? AppColors.teal
                            : AppColors.crimson,
                    size: 17,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _confirmPassCtrl.text.isEmpty
                          ? 'Confirm your password to validate match.'
                          : _passwordsMatch
                              ? 'Passwords match. You are ready to continue.'
                              : 'Passwords do not match yet. Please review both fields.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight:
                            _passwordsMatch ? FontWeight.w700 : FontWeight.w500,
                        color: _confirmPassCtrl.text.isEmpty
                            ? Colors.white.withValues(alpha: 0.56)
                            : _passwordsMatch
                                ? AppColors.teal
                                : AppColors.crimson,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.teal.withValues(alpha: 0.18),
                    AppColors.golden.withValues(alpha: 0.10),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.teal.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sms_rounded, color: AppColors.teal, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Secure phone verification protects your account with multi-factor authentication.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.70),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: _CountryCodePicker(
                    value: _data.countryCode,
                    onChanged: (v) => setState(() => _data.countryCode = v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AuthTextField(
                    label: 'Phone Number',
                    controller: _phoneCtrl,
                    hint: '9XXXXXXXXX',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _phoneSending ? null : _sendPhoneOtp,
                    icon: const Icon(Icons.sms_outlined, size: 16),
                    label: Text(_phoneOtpSent ? 'Resend Code' : 'Send OTP'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.teal.withValues(alpha: 0.45)),
                      foregroundColor: AppColors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: _phoneVerified
                          ? AppColors.teal.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _phoneVerified
                            ? AppColors.teal.withValues(alpha: 0.45)
                            : Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _phoneVerified ? Icons.check_circle_rounded : Icons.timelapse_rounded,
                          size: 16,
                          color: _phoneVerified ? AppColors.teal : Colors.white54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _phoneVerified ? 'Verified' : 'Waiting Verification',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _phoneVerified ? AppColors.teal : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_phoneOtpSent) ...[
              const SizedBox(height: 12),
              Text(
                'Enter the 6-digit code sent to ${_data.countryCode}${_phoneCtrl.text.trim()}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  final filled = _otpControllers[index].text.isNotEmpty;
                  return SizedBox(
                    width: 42,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      decoration: BoxDecoration(
                        color: filled
                            ? AppColors.golden.withValues(alpha: 0.16)
                            : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: filled
                              ? AppColors.golden.withValues(alpha: 0.70)
                              : Colors.white.withValues(alpha: 0.12),
                        ),
                        boxShadow: filled
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.golden.withValues(alpha: 0.20),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : const [],
                      ),
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _otpFocusNodes[index],
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                        ),
                        onChanged: (v) => _onOtpChanged(index, v),
                      ),
                    ),
                  );
                }),
              ),
            ],
            if (_phoneOtpError != null) ...[
              const SizedBox(height: 8),
              Text(
                _phoneOtpError!,
                style: const TextStyle(fontFamily: 'Poppins', color: AppColors.crimson, fontSize: 12),
              ),
            ],
          ],
        );
      case 5:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DatePickerTile(
              date: _dateOfBirth,
              onTap: _pickDateOfBirth,
              subtitle: 'Tap to open the interactive calendar picker',
            ),
            const SizedBox(height: 10),
            _ProvincePicker(
              value: _selectedProvince,
              onChanged: (v) => setState(() {
                _selectedProvince = v;
                _selectedCity = null;
              }),
            ),
            const SizedBox(height: 10),
            _CityPicker(
              province: _selectedProvince,
              value: _selectedCity,
              onChanged: (v) => setState(() => _selectedCity = v),
            ),
            const SizedBox(height: 10),
            _UploadTile(
              title: 'Government ID',
              fileName: _govIdFileName,
              onTap: () => _pickFile(true),
              hoverMessage:
                  'Accepted IDs: Philippine Passport, Driver\'s License, SSS ID, PhilSys National ID, UMID, Voter\'s ID, PRC License, School/Student ID.',
            ),
            const SizedBox(height: 10),
            _UploadTile(
              title: 'Selfie Photo',
              fileName: _selfieFileName,
              onTap: () => _pickFile(false),
              hoverMessage:
                  'Upload a clear photo of yourself while holding your valid government ID. Your face and ID details must be visible.',
            ),
            if ((_govIdBase64 != null && _isImageFile(_govIdFileName)) ||
                (_selfieBase64 != null && _isImageFile(_selfieFileName))) ...[
              const SizedBox(height: 12),
              const Text(
                'Preview Attachments',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.golden,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _AttachmentPreviewTile(
                      title: 'Government ID',
                      fileName: _govIdFileName,
                      bytes: _safeDecode(_govIdBase64),
                      showPreview: _isImageFile(_govIdFileName),
                      onPreview: () => _showAttachmentPreview('Government ID', _govIdBase64, _govIdFileName),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AttachmentPreviewTile(
                      title: 'Selfie Photo',
                      fileName: _selfieFileName,
                      bytes: _safeDecode(_selfieBase64),
                      showPreview: _isImageFile(_selfieFileName),
                      onPreview: () => _showAttachmentPreview('Selfie Photo', _selfieBase64, _selfieFileName),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      case 6:
        return Column(
          children: [
            _ConsentTile(
              value: _data.privacyAccepted,
              onChanged: (v) => setState(() => _data.privacyAccepted = v ?? false),
              label: 'I agree to the Privacy Notice.',
              linkLabel: 'Open Privacy Notice',
              onLabelTap: () => _showConsentModule(
                title: 'Privacy Notice',
                clauses: const [
                  _ConsentClause(
                    title: 'Clause 1.1: Scope of Data Collection',
                    body:
                        'Digital Platform collects only information required for account creation and identity verification. By registering, the user consents to secure storage of login information for system access and communication.',
                  ),
                  _ConsentClause(
                    title: 'Clause 1.2: Data Retention and Deletion',
                    body:
                        'User login information is retained while the account is active. Upon written termination request, personal identifiers are purged within thirty (30) days in compliance with National Privacy Commission standards.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _ConsentTile(
              value: _data.dataConsentAccepted,
              onChanged: (v) => setState(() => _data.dataConsentAccepted = v ?? false),
              label: 'I agree to Data Consent terms.',
              linkLabel: 'Open Data Consent Terms',
              onLabelTap: () => _showConsentModule(
                title: 'Terms of Service and Consent (Q3 Clauses)',
                clauses: const [
                  _ConsentClause(
                    title: 'Clause 2.1: Innovator\'s Warranty of Ownership',
                    body:
                        'Innovators warrant legal rights or authorized licenses to uploaded technologies and assume liability for specification accuracy and non-infringement.',
                  ),
                  _ConsentClause(
                    title: 'Clause 2.2: Public vs. Restricted Visibility',
                    body:
                        'Basic descriptions and high-level benefits are public for discovery, while detailed manuals or proprietary schematics remain protected and access-restricted.',
                  ),
                  _ConsentClause(
                    title: 'Clause 2.3: Non-Transfer of Rights',
                    body:
                        'Uploading to Digital Platform does not transfer ownership to the platform or administrator. Licensing and technology transfer are executed externally between innovator and client.',
                  ),
                  _ConsentClause(
                    title: 'Clause 3.1 and 3.2: Security and MFA',
                    body:
                        'Users are responsible for account credential confidentiality and must report unauthorized access. Multi-factor authentication is required for Client, Innovator, and Admin roles.',
                  ),
                  _ConsentClause(
                    title: 'Clause 4.1 and 4.2: Administrative Moderation',
                    body:
                        'Administrators may verify technology legitimacy and remove fraudulent or misleading submissions. Users are categorized by role, with feature restrictions enforced via role-based access.',
                  ),
                  _ConsentClause(
                    title: 'Clause 5.1 and 5.2: Liability and External Links',
                    body:
                        'Technology listings are provided as-is. Digital Platform is not liable for production or ROI losses from adoption outcomes, and is not responsible for privacy/content of external government portals.',
                  ),
                ],
              ),
            ),
          ],
        );
      case 7:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _ReviewStatPill(
                    icon: Icons.shield_rounded,
                    label: 'KYC Ready',
                    color: AppColors.teal,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ReviewStatPill(
                    icon: Icons.rule_folder_rounded,
                    label: 'Consent Complete',
                    color: AppColors.golden,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.golden.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: AppColors.golden, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Review your details carefully before submission.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.66),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _ReviewRow(label: 'Role', value: _data.role),
            _ReviewRow(label: 'Name', value: '${_data.firstName} ${_data.lastName}'),
            _ReviewRow(label: 'Username', value: _data.username),
            _ReviewRow(label: 'Email', value: _data.email),
            _ReviewRow(label: 'Phone', value: '${_data.countryCode} ${_data.phone}'),
            _ReviewRow(label: 'Birth Date', value: _data.dateOfBirth),
            _ReviewRow(label: 'Province / City', value: '${_data.province} / ${_data.city}'),
            _ReviewRow(label: 'Government ID', value: _govIdFileName ?? 'Attached'),
            _ReviewRow(label: 'Selfie', value: _selfieFileName ?? 'Attached'),
            if ((_govIdBase64 != null && _isImageFile(_govIdFileName)) ||
                (_selfieBase64 != null && _isImageFile(_selfieFileName))) ...[
              const SizedBox(height: 8),
              const Text(
                'Attached Files Preview',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.golden,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _AttachmentPreviewTile(
                      title: 'Government ID',
                      fileName: _govIdFileName,
                      bytes: _safeDecode(_govIdBase64),
                      showPreview: _isImageFile(_govIdFileName),
                      onPreview: () => _showAttachmentPreview('Government ID', _govIdBase64, _govIdFileName),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AttachmentPreviewTile(
                      title: 'Selfie Photo',
                      fileName: _selfieFileName,
                      bytes: _safeDecode(_selfieBase64),
                      showPreview: _isImageFile(_selfieFileName),
                      onPreview: () => _showAttachmentPreview('Selfie Photo', _selfieBase64, _selfieFileName),
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _roleOption(String value, String title, String subtitle, IconData icon) {
    final selected = _data.role == value;
    return GestureDetector(
      onTap: () => setState(() => _data.role = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    AppColors.golden.withValues(alpha: 0.2),
                    AppColors.warmEmber.withValues(alpha: 0.08),
                  ],
                )
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.golden.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: selected ? AppColors.golden : Colors.white54),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.golden : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.44),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? AppColors.golden : Colors.white24,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _SuffixPicker extends StatelessWidget {
  const _SuffixPicker({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text('Suffix', style: TextStyle(color: Colors.white.withValues(alpha: 0.34), fontFamily: 'Poppins')),
          dropdownColor: AppColors.midnight,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
          style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 14),
          items: const [
            DropdownMenuItem(value: 'Jr', child: Text('Jr')),
            DropdownMenuItem(value: 'Sr', child: Text('Sr')),
            DropdownMenuItem(value: 'II', child: Text('II')),
            DropdownMenuItem(value: 'III', child: Text('III')),
            DropdownMenuItem(value: 'IV', child: Text('IV')),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _CountryCodePicker extends StatelessWidget {
  const _CountryCodePicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.midnight,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
          style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 14),
          items: const [
            DropdownMenuItem(value: '+63', child: Text('+63')),
            DropdownMenuItem(value: '+1', child: Text('+1')),
            DropdownMenuItem(value: '+65', child: Text('+65')),
          ],
          onChanged: (v) => v != null ? onChanged(v) : null,
        ),
      ),
    );
  }
}

class _ProvincePicker extends StatelessWidget {
  const _ProvincePicker({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text('Province / Region', style: TextStyle(color: Colors.white.withValues(alpha: 0.34), fontFamily: 'Poppins')),
          isExpanded: true,
          dropdownColor: AppColors.midnight,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
          style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 14),
            items: phAddressData.keys
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _CityPicker extends StatelessWidget {
  const _CityPicker({required this.province, required this.value, required this.onChanged});

  final String? province;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cities = province == null ? const <String>[] : (phAddressData[province] ?? const <String>[]);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text('City / Municipality', style: TextStyle(color: Colors.white.withValues(alpha: 0.34), fontFamily: 'Poppins')),
          isExpanded: true,
          dropdownColor: AppColors.midnight,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70),
          style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 14),
          items: cities.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: cities.isEmpty ? null : onChanged,
        ),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.date,
    required this.onTap,
    this.subtitle,
  });

  final DateTime? date;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.04),
              AppColors.golden.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.golden.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_available_rounded,
                    color: AppColors.golden, size: 18),
                const SizedBox(width: 10),
                Text(
                  date == null
                      ? 'Date of Birth'
                      : '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: date == null
                        ? Colors.white.withValues(alpha: 0.50)
                        : Colors.white,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.48),
                  size: 18,
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.title,
    required this.fileName,
    required this.onTap,
    this.hoverMessage,
  });

  final String title;
  final String? fileName;
  final VoidCallback onTap;
  final String? hoverMessage;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: hoverMessage ?? '',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.upload_file_rounded,
                        color: Colors.white70, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        fileName ?? title,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: fileName == null
                              ? Colors.white.withValues(alpha: 0.40)
                              : AppColors.teal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: Colors.white.withValues(alpha: 0.50),
                    ),
                  ],
                ),
                if (hoverMessage != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Hover for upload guide',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.40),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachmentPreviewTile extends StatelessWidget {
  const _AttachmentPreviewTile({
    required this.title,
    required this.fileName,
    required this.bytes,
    required this.showPreview,
    required this.onPreview,
  });

  final String title;
  final String? fileName;
  final Uint8List? bytes;
  final bool showPreview;
  final VoidCallback onPreview;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: showPreview ? onPreview : null,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 6),
            if (showPreview && bytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 1.35,
                  child: Image.memory(bytes!, fit: BoxFit.cover),
                ),
              )
            else
              Container(
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Icon(Icons.description_outlined, color: Colors.white.withValues(alpha: 0.40), size: 20),
              ),
            const SizedBox(height: 6),
            Text(
              fileName ?? 'Not attached',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fileName == null ? Colors.white.withValues(alpha: 0.32) : AppColors.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsentClause {
  const _ConsentClause({required this.title, required this.body});

  final String title;
  final String body;
}

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.linkLabel,
    this.onLabelTap,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  final String linkLabel;
  final VoidCallback? onLabelTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Checkbox(value: value, activeColor: AppColors.golden, onChanged: onChanged),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onLabelTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.golden.withValues(alpha: 0.24),
                          AppColors.warmEmber.withValues(alpha: 0.16),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.golden.withValues(alpha: 0.50),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_stories_rounded,
                            size: 14, color: AppColors.golden),
                        const SizedBox(width: 6),
                        Text(
                          linkLabel,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.golden,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.42),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewStatPill extends StatelessWidget {
  const _ReviewStatPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordGuidePanel extends StatelessWidget {
  const _PasswordGuidePanel({
    required this.password,
    required this.score,
  });

  final String password;
  final int score;

  @override
  Widget build(BuildContext context) {
    final checks = <(String, bool)>[
      ('8+ characters', password.length >= 8),
      ('Uppercase letter', RegExp(r'[A-Z]').hasMatch(password)),
      ('Lowercase letter', RegExp(r'[a-z]').hasMatch(password)),
      ('Number', RegExp(r'[0-9]').hasMatch(password)),
      ('Special symbol', RegExp(r'[^A-Za-z0-9]').hasMatch(password)),
    ];

    final barColor = switch (score) {
      <= 1 => AppColors.crimson,
      2 || 3 => AppColors.golden,
      _ => AppColors.teal,
    };

    final label = switch (score) {
      <= 1 => 'Weak',
      2 || 3 => 'Improving',
      4 => 'Good',
      _ => 'Strong',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Password Strength',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.70),
                ),
              ),
              const Spacer(),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final active = i < score;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                  height: 5,
                  decoration: BoxDecoration(
                    color: active
                        ? barColor
                        : Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: checks.map((item) {
              final passed = item.$2;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: passed
                      ? AppColors.teal.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: passed
                        ? AppColors.teal.withValues(alpha: 0.45)
                        : Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      passed
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 12,
                      color: passed ? AppColors.teal : Colors.white38,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      item.$1,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight:
                            passed ? FontWeight.w700 : FontWeight.w500,
                        color: passed
                            ? AppColors.teal
                            : Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Forgot Password Page
// =============================================================================

class _ForgotPasswordPage extends StatefulWidget {
  const _ForgotPasswordPage({
    required this.onBackToLogin,
    required this.onCreateTap,
    required this.isMobile,
  });

  final VoidCallback onBackToLogin;
  final VoidCallback onCreateTap;
  final bool         isMobile;

  @override
  State<_ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<_ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  bool  _sent      = false;
  bool  _loading   = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService()
          .post('auth/forgot-password', {'email': _emailCtrl.text.trim()});
      if (!mounted) return;
      if (res['error'] != null) {
        setState(() => _error = res['error']);
      } else {
        setState(() => _sent = true);
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left:   32, right: 32,
          top:    widget.isMobile ? 164 : 32,
          bottom: 32,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: _GlassCard(
            child: _sent ? _buildSuccessState() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          TextButton.icon(
            onPressed: widget.onBackToLogin,
            icon: Icon(Icons.arrow_back, size: 16,
                color: Colors.white.withValues(alpha: 0.45)),
            label: Text('Back to Sign In',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize:   13,
                color: Colors.white.withValues(alpha: 0.45),
              )),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 20),

          // Title
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Colors.white, Color(0xFFCBD5E1)],
            ).createShader(b),
            child: const Text('Reset Password',
              style: TextStyle(
                fontFamily:  'Poppins',
                fontSize:    32,
                fontWeight:  FontWeight.w800,
                color:       Colors.white,
                letterSpacing: -0.5,
              )),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 8),
          Text(
            'Enter your email and we\'ll send you a reset link.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize:   14,
              color: Colors.white.withValues(alpha: 0.45),
            )),
          const SizedBox(height: 32),

          // Email icon visual
          Center(
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.teal, Color(0xFF0E5A50)],
                  begin: Alignment.topLeft,
                  end:   Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color:      AppColors.teal.withValues(alpha: 0.30),
                    blurRadius: 24,
                    offset:     const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.lock_reset_rounded,
                  color: Colors.white, size: 32),
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 100.ms).scale(
              begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 28),

          // Email field
          _AuthTextField(
            label:        'Email Address',
            controller:   _emailCtrl,
            hint:         'you@gmail.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon:   Icons.email_outlined,
            validator: (v) =>
                (v == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v))
                    ? 'Enter a valid email'
                    : null,
          ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.15, end: 0),
          const SizedBox(height: 8),

          // Error
          if (_error != null)
            Container(
              padding:  const EdgeInsets.all(12),
              margin:   const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color:  AppColors.crimson.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.crimson.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline,
                    color: AppColors.crimson, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_error!,
                    style: const TextStyle(
                      fontFamily: 'Poppins', fontSize: 13, color: AppColors.crimson)),
                ),
              ]),
            ).animate().fadeIn(),
          const SizedBox(height: 24),

          // Send button
          _GoldenButton(
            label:     'Send Reset Link',
            icon:      Icons.send_rounded,
            isLoading: _loading,
            onTap:     _send,
            color:     AppColors.teal,
          ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2, end: 0),
          const SizedBox(height: 14),
          Center(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
                children: [
                  const TextSpan(text: 'Need an account? '),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: widget.onCreateTap,
                      child: const Text(
                        'Create one',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          color: AppColors.golden,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        const SizedBox(height: 8),
        // Success icon
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.teal, Color(0xFF0E5A50)],
              begin: Alignment.topLeft,
              end:   Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color:      AppColors.teal.withValues(alpha: 0.35),
                blurRadius: 28,
                offset:     const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.mark_email_read_rounded,
              color: Colors.white, size: 36),
        ).animate().scale(begin: const Offset(0.7, 0.7), duration: 500.ms,
            curve: Curves.easeOutBack).fadeIn(),
        const SizedBox(height: 24),
        const Text('Email Sent!',
          style: TextStyle(
            fontFamily:  'Poppins',
            fontSize:    26,
            fontWeight:  FontWeight.w800,
            color:       Colors.white,
          )).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 12),
        Text(
          'We\'ve sent a password reset link to\n${_emailCtrl.text}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize:   14,
            color: Colors.white.withValues(alpha: 0.50),
            height: 1.5,
          )).animate().fadeIn(delay: 350.ms),
        const SizedBox(height: 32),
        _GoldenButton(
          label:     'Back to Sign In',
          icon:      Icons.arrow_back_rounded,
          isLoading: false,
          onTap:     widget.onBackToLogin,
          color:     AppColors.teal,
        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }
}

// =============================================================================
// Left Decorative Panel (desktop)
// =============================================================================

class _LeftPanel extends StatelessWidget {
  const _LeftPanel({required this.orbCtrl, required this.gradientCtrl});

  final AnimationController orbCtrl;
  final AnimationController gradientCtrl;

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
                Color.lerp(AppColors.richNavy,    const Color(0xFF071E30), gt)!,
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
              // Teal orb — top right
              Positioned(
                top: -60 + t * 40, right: -80 + t * 30,
                child: _Orb(AppColors.teal,   0.15, 320),
              ),
              // Golden orb — bottom left
              Positioned(
                bottom: -60 + t * 35, left: -60 + t * 20,
                child: _Orb(AppColors.golden, 0.10, 280),
              ),
              // Crimson orb — mid
              Positioned(
                top: 200 + t * 50, left: -30 + t * 15,
                child: _Orb(AppColors.crimson, 0.07, 160),
              ),
              // Sky orb — top left
              Positioned(
                top: 80 - t * 20, left: 60 + t * 15,
                child: _Orb(AppColors.sky, 0.06, 120),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 56),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Image.asset('assets/images/logo/final-logo.png', height: 64)
                        .animate().fadeIn(duration: 600.ms),
                    const SizedBox(height: 14),
                    // Brand name
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [AppColors.golden, AppColors.warmEmber],
                      ).createShader(b),
                      child: const Text('Digital Platform',
                        style: TextStyle(
                          fontFamily:  'Poppins',
                          fontSize:    28,
                          fontWeight:  FontWeight.w900,
                          color:       Colors.white,
                          letterSpacing: 0.5,
                        )),
                    ).animate().fadeIn(duration: 600.ms, delay: 100.ms),
                    Text('Where Filipino Innovation Soars',
                      style: TextStyle(
                        fontFamily:  'Poppins',
                        fontSize:    11,
                        color:       Colors.white.withValues(alpha: 0.38),
                        letterSpacing: 1.5,
                      )).animate().fadeIn(duration: 600.ms, delay: 150.ms),

                    const Spacer(),

                    // Showcase card
                    _ShowcaseCard()
                        .animate(delay: 400.ms)
                        .fadeIn(duration: 700.ms)
                        .slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 28),

                    // Stats
                    Row(
                      children: [
                        _StatBadge(value: '500+',  label: 'Innovations'),
                        const SizedBox(width: 12),
                        _StatBadge(value: '120+',  label: 'Innovators'),
                        const SizedBox(width: 12),
                        _StatBadge(value: '15+',   label: 'Universities'),
                      ],
                    ).animate(delay: 600.ms).fadeIn(duration: 500.ms).slideX(begin: -0.2, end: 0),
                    const SizedBox(height: 20),

                    // Trust pills
                    Wrap(spacing: 10, runSpacing: 8, children: [
                      _TrustPill(icon: Icons.shield_rounded,   label: 'Secure',          color: AppColors.teal),
                      _TrustPill(icon: Icons.verified_rounded, label: 'Verified',         color: AppColors.golden),
                      _TrustPill(icon: Icons.flag_rounded,     label: 'Philippine-made',  color: AppColors.crimson),
                    ]).animate(delay: 800.ms).fadeIn(duration: 600.ms),
                    const SizedBox(height: 14),

                    Text('© 2025 Digital Platform',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize:   11,
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

// Helper orb widget
class _Orb extends StatelessWidget {
  const _Orb(this.color, this.alpha, this.size);
  final Color  color;
  final double alpha;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color:       color.withValues(alpha: alpha),
            blurRadius:  size * 0.6,
            spreadRadius: size * 0.1,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Showcase card (left panel)
// =============================================================================

class _ShowcaseCard extends StatelessWidget {
  const _ShowcaseCard();

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
            color:      AppColors.golden.withValues(alpha: 0.08),
            blurRadius: 30,
            offset:     const Offset(0, 8),
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
              child: const Icon(Icons.lightbulb_rounded,
                  color: AppColors.golden, size: 18),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Featured Innovation',
                style: TextStyle(
                  fontFamily:  'Poppins',
                  fontSize:    12,
                  fontWeight:  FontWeight.w600,
                  color:       AppColors.golden,
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
                  fontFamily:  'Poppins',
                  fontSize:    9,
                  fontWeight:  FontWeight.w700,
                  color:       AppColors.teal,
                  letterSpacing: 1,
                )),
            ),
          ]),
          const SizedBox(height: 14),
          const Text('AgriSense AI Platform',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize:   16,
              fontWeight: FontWeight.w700,
              color:      Colors.white,
            )),
          const SizedBox(height: 4),
          Text('Precision agriculture using AI for Filipino farmers',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize:   12,
              color: Colors.white.withValues(alpha: 0.50),
            )),
          const SizedBox(height: 14),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Agri-Aqua and Forestry',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize:   10,
                  fontWeight: FontWeight.w600,
                  color:      AppColors.teal,
                )),
            ),
            const Spacer(),
            Row(children: [
              const Icon(Icons.star_rounded, color: AppColors.golden, size: 14),
              const SizedBox(width: 4),
              Text('4.9',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize:   12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.70),
                )),
            ]),
          ]),
        ],
      ),
    );
  }
}

// =============================================================================
// Shared UI Components
// =============================================================================

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: AppColors.darkSurface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderDark, width: 1),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.40),
            blurRadius: 40,
            offset:     const Offset(0, 16),
          ),
          BoxShadow(
            color:      AppColors.golden.withValues(alpha: 0.04),
            blurRadius: 60,
          ),
        ],
      ),
      child: child,
    );
  }
}

// ── Text Field ─────────────────────────────────────────────────────────────────

class _AuthTextField extends StatefulWidget {
  const _AuthTextField({
    required this.label,
    required this.controller,
    this.hint          = '',
    this.keyboardType  = TextInputType.text,
    this.prefixIcon    = Icons.text_fields,
    this.isPassword    = false,
    this.obscure       = false,
    this.focusNode,
    this.onObscureToggle,
    this.validator,
    this.onChanged,
  });

  final String                   label;
  final TextEditingController    controller;
  final String                   hint;
  final TextInputType            keyboardType;
  final IconData                 prefixIcon;
  final bool                     isPassword;
  final bool                     obscure;
  final FocusNode?               focusNode;
  final VoidCallback?            onObscureToggle;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>?    onChanged;

  @override
  State<_AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<_AuthTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
          style: TextStyle(
            fontFamily:  'Poppins',
            fontSize:    13,
            fontWeight:  FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.70),
          )),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (f) => setState(() => _focused = f),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppColors.richNavy.withValues(alpha: _focused ? 0.80 : 0.60),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused
                    ? AppColors.golden.withValues(alpha: 0.50)
                    : AppColors.borderDark,
                width: _focused ? 1.5 : 1.0,
              ),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color:      AppColors.golden.withValues(alpha: 0.08),
                        blurRadius: 12,
                      ),
                    ]
                  : [],
            ),
            child: TextFormField(
              controller:   widget.controller,
              obscureText:  widget.isPassword ? widget.obscure : false,
              keyboardType: widget.keyboardType,
              focusNode:    widget.focusNode,
              validator:    widget.validator,
              onChanged:    widget.onChanged,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize:   15,
                color:      Colors.white,
              ),
              decoration: InputDecoration(
                hintText:      widget.hint,
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white.withValues(alpha: 0.25),
                ),
                border:          InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                prefixIcon: Icon(widget.prefixIcon,
                  color: _focused
                      ? AppColors.golden.withValues(alpha: 0.70)
                      : Colors.white.withValues(alpha: 0.30),
                  size: 20,
                ),
                suffixIcon: widget.isPassword
                    ? IconButton(
                        icon: Icon(
                          widget.obscure
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: Colors.white.withValues(alpha: 0.35),
                          size: 20,
                        ),
                        onPressed: widget.onObscureToggle,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Golden/Teal submit button ──────────────────────────────────────────────────

class _GoldenButton extends StatefulWidget {
  const _GoldenButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onTap,
    this.color,
  });

  final String   label;
  final IconData icon;
  final bool     isLoading;
  final VoidCallback onTap;
  final Color?   color;

  @override
  State<_GoldenButton> createState() => _GoldenButtonState();
}

class _GoldenButtonState extends State<_GoldenButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isGolden = widget.color == null;
    final c1 = isGolden ? AppColors.golden    : (widget.color ?? AppColors.teal);
    final c2 = isGolden ? AppColors.warmEmber : (widget.color ?? AppColors.teal);

    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width:  double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [c1, c2],
              begin:  Alignment.centerLeft,
              end:    Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color:      c1.withValues(alpha: 0.40),
                      blurRadius: 24,
                      offset:     const Offset(0, 8),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth:  2.5,
                      valueColor:   AlwaysStoppedAnimation<Color>(AppColors.navy),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon, size: 18, color: AppColors.navy),
                      const SizedBox(width: 10),
                      Text(widget.label,
                        style: const TextStyle(
                          fontFamily:  'Poppins',
                          fontSize:    15,
                          fontWeight:  FontWeight.w700,
                          color:       AppColors.navy,
                        )),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Google sign-in button ──────────────────────────────────────────────────────

class _GoogleButton extends StatefulWidget {
  const _GoogleButton({required this.ref});
  final WidgetRef ref;

  @override
  State<_GoogleButton> createState() => _GoogleButtonState();
}

class _GoogleButtonState extends State<_GoogleButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.ref.read(authProvider.notifier).loginWithGoogle(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width:  double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _hovered ? 0.10 : 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: _hovered ? 0.28 : 0.14),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Google "G" icon via text
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Text('G',
                    style: TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w900,
                      color:      Color(0xFF4285F4),
                    )),
                ),
              ),
              const SizedBox(width: 12),
              Text('Continue with Google',
                style: TextStyle(
                  fontFamily:  'Poppins',
                  fontSize:    14,
                  fontWeight:  FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Animated checkbox ──────────────────────────────────────────────────────────

class _AnimatedCheckbox extends StatelessWidget {
  const _AnimatedCheckbox({
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool                   value;
  final ValueChanged<bool?>    onChanged;
  final String                 label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 18, height: 18,
            decoration: BoxDecoration(
              color: value
                  ? AppColors.golden
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: value
                    ? AppColors.golden
                    : Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: value
                ? const Icon(Icons.check_rounded,
                    color: AppColors.navy, size: 12)
                : null,
          ),
          const SizedBox(width: 8),
          Text(label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize:   13,
              color: Colors.white.withValues(alpha: 0.55),
            )),
        ],
      ),
    );
  }
}

// ── Hover text button ──────────────────────────────────────────────────────────

class _HoverTextButton extends StatefulWidget {
  const _HoverTextButton({required this.text, required this.onTap});
  final String       text;
  final VoidCallback onTap;

  @override
  State<_HoverTextButton> createState() => _HoverTextButtonState();
}

class _HoverTextButtonState extends State<_HoverTextButton> {
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:  SystemMouseCursors.click,
      onEnter: (_) => setState(() => _h = true),
      onExit:  (_) => setState(() => _h = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: TextStyle(
            fontFamily:  'Poppins',
            fontSize:    13,
            fontWeight:  FontWeight.w600,
            color: _h ? AppColors.golden : AppColors.golden.withValues(alpha: 0.75),
          ),
          child: Text(widget.text),
        ),
      ),
    );
  }
}

// ── Status banner ──────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color    color;
  final String   title;
  final String   message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin:  const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize:   13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  )),
                const SizedBox(height: 2),
                Text(message,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize:   12,
                    color: Colors.white.withValues(alpha: 0.55),
                    height: 1.4,
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat badge ─────────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  const _StatBadge({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(value,
            style: const TextStyle(
              fontFamily:  'Poppins',
              fontSize:    16,
              fontWeight:  FontWeight.w800,
              color:       AppColors.golden,
            )),
          Text(label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize:   9,
              color: Colors.white.withValues(alpha: 0.40),
              letterSpacing: 0.5,
            )),
        ],
      ),
    );
  }
}

// ── Trust pill ─────────────────────────────────────────────────────────────────

class _TrustPill extends StatelessWidget {
  const _TrustPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String   label;
  final Color    color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(label,
            style: TextStyle(
              fontFamily:  'Poppins',
              fontSize:    11,
              fontWeight:  FontWeight.w600,
              color:       color,
            )),
        ],
      ),
    );
  }
}

// ── Grid painter ───────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color       = Colors.white
      ..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}
