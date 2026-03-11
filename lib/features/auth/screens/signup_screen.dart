import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/step_indicator.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/password_strength_meter.dart';
import '../widgets/signup_skeleton.dart';
// ignore_for_file: unused_element

// ═══════════════════════════════════════════════════════════
// SignupScreen — cinematic multi-step registration
// ═══════════════════════════════════════════════════════════
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with TickerProviderStateMixin {
  int _currentStep = 1;
  final int _totalSteps = 7;
  final SignupData _data = SignupData();
  final _formKey = GlobalKey<FormState>();
  bool _showSkeleton = true;

  // Text controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _noMiddleName = false;
  String _selectedSuffix = 'None';
  bool _passwordMatch = false;
  String _passwordValue = '';

  // Animation controllers
  late AnimationController _bgCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _orbCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);

    Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _showSkeleton = false);
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _phoneCtrl.dispose();
    _bgCtrl.dispose();
    _orbCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_formKey.currentState?.validate() ?? false) {
      _saveCurrentStep();
      if (_currentStep < _totalSteps) {
        setState(() => _currentStep++);
      } else {
        _submit();
      }
    }
  }

  void _back() {
    if (_currentStep > 1) setState(() => _currentStep--);
  }

  void _saveCurrentStep() {
    switch (_currentStep) {
      case 2:
        _data.firstName = _firstNameCtrl.text.trim();
        _data.lastName = _lastNameCtrl.text.trim();
        _data.middleName =
            _noMiddleName ? '' : _middleNameCtrl.text.trim();
        _data.suffix =
            _selectedSuffix == 'None' ? '' : _selectedSuffix;
        _data.username = _usernameCtrl.text.trim();
        _data.email = _emailCtrl.text.trim();
        break;
      case 3:
        _data.password = _passwordCtrl.text;
        break;
      case 4:
        _data.phone = _phoneCtrl.text.trim();
        break;
    }
  }

  Future<void> _submit() async {
    _saveCurrentStep();
    final success = await ref.read(authProvider.notifier).signup(_data);
    if (success && mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.teal, AppColors.sky],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.teal.withValues(alpha: 0.30),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 36),
            )
                .animate()
                .scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                  duration: 500.ms,
                )
                .fadeIn(duration: 300.ms),
            const SizedBox(height: 20),
            const Text(
              'Registration Submitted!',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.navy,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 8),
            const Text(
              'Your account is pending admin approval.\nYou will receive an email once approved.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Go to Login',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ).animate(delay: 400.ms).fadeIn(duration: 400.ms).slideY(
                begin: 0.15, end: 0, curve: Curves.easeOutCubic),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 700),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: CurvedAnimation(
              parent: anim, curve: Curves.easeOutCubic),
          child: child,
        ),
        child: _showSkeleton
            ? const SignupSkeleton(key: ValueKey('skeleton'))
            : _buildMain(),
      ),
    );
  }

  Widget _buildMain() {
    final authState = ref.watch(authProvider);
    final wide = MediaQuery.of(context).size.width > 900;

    return Row(
      key: const ValueKey('main'),
      children: [
        if (wide)
          Expanded(
            flex: 2,
            child: _LeftPanel(bgCtrl: _bgCtrl, orbCtrl: _orbCtrl),
          ),
        Expanded(
          flex: 3,
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
                color: AppColors.teal
                    .withValues(alpha: 0.03 + t * 0.04),
                blurRadius: 60,
                offset: const Offset(-20, 0),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Subtle right-panel dot grid
          Positioned.fill(
            child: CustomPaint(painter: _RightDotGridPainter()),
          ),
          // Ambient orb — top-right teal
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.teal.withValues(alpha: 0.055),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Ambient orb — bottom-left sky
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.sky.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main form — floating card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 36),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color:
                          AppColors.lightGray.withValues(alpha: 0.45),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy
                            .withValues(alpha: 0.06),
                        blurRadius: 48,
                        offset: const Offset(0, 12),
                        spreadRadius: -6,
                      ),
                      BoxShadow(
                        color: AppColors.teal
                            .withValues(alpha: 0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Back to Login ────────────────
                        const _BackToLoginButton()
                            .animate()
                            .fadeIn(duration: 380.ms)
                            .slideX(
                                begin: -0.08,
                                end: 0,
                                curve: Curves.easeOutCubic),

                        const SizedBox(height: 20),

                        // ── Step progress bar ────────────
                        _StepProgressBar(
                          current: _currentStep,
                          total: _totalSteps,
                        ).animate().fadeIn(duration: 500.ms),

                        const SizedBox(height: 20),

                        // ── Step indicator ───────────────
                        StepIndicator(
                          currentStep: _currentStep,
                          totalSteps: _totalSteps,
                        ),

                        const SizedBox(height: 32),

                        // ── Step content — fade + scale ──
                        AnimatedSwitcher(
                          duration:
                              const Duration(milliseconds: 480),
                          transitionBuilder: (child, anim) {
                            final curved = CurvedAnimation(
                                parent: anim,
                                curve: Curves.easeOutCubic);
                            return FadeTransition(
                              opacity: curved,
                              child: ScaleTransition(
                                scale: Tween<double>(
                                        begin: 0.96, end: 1.0)
                                    .animate(curved),
                                alignment: Alignment.topCenter,
                                child: child,
                              ),
                            );
                          },
                          layoutBuilder: (current, previous) =>
                              Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              ...previous,
                              if (current != null) current,
                            ],
                          ),
                          child: KeyedSubtree(
                            key: ValueKey(_currentStep),
                            child: _buildStep(),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── Error banner ─────────────────
                        if (authState.error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin:
                                const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.crimson
                                  .withValues(alpha: 0.08),
                              borderRadius:
                                  BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.crimson
                                      .withValues(alpha: 0.25)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: AppColors.crimson
                                        .withValues(alpha: 0.12),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                      Icons.error_outline_rounded,
                                      color: AppColors.crimson,
                                      size: 16),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    authState.error!,
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
                          )
                              .animate()
                              .fadeIn(duration: 280.ms)
                              .slideY(begin: -0.08, end: 0),

                        // ── Navigation buttons ───────────
                        _NavigationRow(
                          currentStep: _currentStep,
                          totalSteps: _totalSteps,
                          isLoading: authState.isLoading,
                          onBack: _back,
                          onNext: _next,
                        ),

                        const SizedBox(height: 8),

                        // ── Keyboard hint ────────────────
                        Center(
                          child: Text(
                            'Press Enter to continue',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Colors.black.withValues(
                                  alpha: 0.20),
                              letterSpacing: 0.3,
                            ),
                          ),
                        )
                            .animate(delay: 600.ms)
                            .fadeIn(duration: 500.ms),
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

  Widget _buildStep() {
    switch (_currentStep) {
      case 1:
        return _Step1Role(
          selectedRole: _data.role,
          onSelect: (role) => setState(() => _data.role = role),
        );
      case 2:
        return _Step2BasicInfo(
          firstNameCtrl: _firstNameCtrl,
          lastNameCtrl: _lastNameCtrl,
          middleNameCtrl: _middleNameCtrl,
          usernameCtrl: _usernameCtrl,
          emailCtrl: _emailCtrl,
          noMiddleName: _noMiddleName,
          selectedSuffix: _selectedSuffix,
          onNoMiddleNameChanged: (v) =>
              setState(() => _noMiddleName = v),
          onSuffixChanged: (v) =>
              setState(() => _selectedSuffix = v ?? 'None'),
        );
      case 3:
        return _Step3Security(
          passwordCtrl: _passwordCtrl,
          confirmCtrl: _confirmPasswordCtrl,
          passwordValue: _passwordValue,
          passwordMatch: _passwordMatch,
          onPasswordChanged: (v) =>
              setState(() => _passwordValue = v),
          onConfirmChanged: (v) => setState(() =>
              _passwordMatch =
                  v == _passwordCtrl.text && v.isNotEmpty),
        );
      case 4:
        return _Step4Contact(
          phoneCtrl: _phoneCtrl,
          countryCode: _data.countryCode,
          onCountryCodeChanged: (v) =>
              setState(() => _data.countryCode = v),
        );
      case 5:
        return const _Step5Identity();
      case 6:
        return _Step6Consent(
          privacyAccepted: _data.privacyAccepted,
          dataConsentAccepted: _data.dataConsentAccepted,
          onPrivacyChanged: (v) =>
              setState(() => _data.privacyAccepted = v ?? false),
          onDataConsentChanged: (v) =>
              setState(() => _data.dataConsentAccepted = v ?? false),
        );
      case 7:
        return _Step7Review(data: _data);
      default:
        return const SizedBox();
    }
  }
}

// ═══════════════════════════════════════════════════════════
// Left Panel — cinematic gradient + orbs + grid + content
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
        final bg = bgCtrl.value;
        final orb = orbCtrl.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(AppColors.navy,
                    const Color(0xFF041F33), bg)!,
                Color.lerp(const Color(0xFF064663),
                    const Color(0xFF053E5E), bg)!,
                Color.lerp(AppColors.teal,
                    const Color(0xFF0D5A4F), bg)!,
              ],
            ),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Dot-grid texture
              Positioned.fill(
                  child:
                      CustomPaint(painter: _DotGridPainter())),
              // Scanline overlay
              Positioned.fill(
                  child:
                      CustomPaint(painter: _ScanlinePainter())),
              // Vignette top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
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
              // Orb 1 — teal (large, top-left)
              _Orb(
                color: AppColors.teal,
                size: 380,
                alpha: 0.20,
                x: -90,
                y: -90.0 +
                    math.sin(orb * math.pi * 2) * 22,
                alignRight: false,
                alignBottom: false,
              ),
              // Orb 2 — sky (mid, bottom-right)
              _Orb(
                color: AppColors.sky,
                size: 260,
                alpha: 0.14,
                x: -50,
                y: 60.0 +
                    math.sin((orb + 0.5) * math.pi * 2) * 18,
                alignRight: true,
                alignBottom: true,
              ),
              // Orb 3 — golden (small, bottom-left)
              _Orb(
                color: AppColors.golden,
                size: 180,
                alpha: 0.11,
                x: 30,
                y: -20.0 +
                    math.sin((orb + 0.25) * math.pi * 2) * 14,
                alignRight: false,
                alignBottom: true,
              ),
              // Static content
              child!,
            ],
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 52, vertical: 56),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo
            Image.asset('assets/images/logo/final-logo.png',
                    height: 72)
                .animate()
                .fadeIn(duration: 600.ms),
            const SizedBox(height: 22),

            // "HIRAYA" per-letter stagger
            const _LetterStagger(
              text: 'HIRAYA',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 52,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 10,
                shadows: [
                  Shadow(
                    color: AppColors.teal,
                    blurRadius: 30,
                  ),
                  Shadow(
                    color: AppColors.sky,
                    blurRadius: 60,
                  ),
                ],
              ),
              baseDelay: 100,
              letterDelay: 65,
            ),
            const SizedBox(height: 10),

            // Tagline
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

            // CTA heading
            const Text(
              'Join Our Platform',
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
                .slideX(
                    begin: -0.08,
                    end: 0,
                    curve: Curves.easeOutCubic),
            const SizedBox(height: 6),
            const Text(
              'Create your account and start your\ninnovation journey.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.white54,
                height: 1.55,
              ),
            ).animate(delay: 700.ms).fadeIn(duration: 600.ms),
            const SizedBox(height: 44),

            // Trust badges
            ..._buildTrustBadges(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTrustBadges() {
    const badges = [
      (Icons.verified_user_rounded, 'KYC Verified Platform'),
      (Icons.shield_rounded, 'RA 10173 Compliant'),
      (Icons.lock_rounded, 'Secure & Encrypted'),
    ];
    return badges.asMap().entries.map((e) {
      final i = e.key;
      final b = e.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(b.$1,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              b.$2,
              style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
            ),
          ],
        ),
      )
          .animate(
              delay: Duration(milliseconds: 780 + i * 80))
          .fadeIn(duration: 500.ms)
          .slideX(
              begin: -0.08,
              end: 0,
              curve: Curves.easeOutCubic);
    }).toList();
  }
}

// ═══════════════════════════════════════════════════════════
// Back to Login — arrow slides left on hover
// ═══════════════════════════════════════════════════════════
class _BackToLoginButton extends StatefulWidget {
  const _BackToLoginButton();

  @override
  State<_BackToLoginButton> createState() =>
      _BackToLoginButtonState();
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
        onTap: () => context.go('/login'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 7),
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
                offset: _hovered
                    ? const Offset(-0.25, 0)
                    : Offset.zero,
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 16,
                  color:
                      _hovered ? AppColors.navy : Colors.black45,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Back to Login',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight:
                      _hovered ? FontWeight.w600 : FontWeight.w500,
                  color:
                      _hovered ? AppColors.navy : Colors.black45,
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
// Navigation Row — Back + Continue / Submit buttons
// ═══════════════════════════════════════════════════════════
class _NavigationRow extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _NavigationRow({
    required this.currentStep,
    required this.totalSteps,
    required this.isLoading,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (currentStep > 1) ...[
          Expanded(child: _BackButton(onTap: onBack)),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: 2,
          child: _ContinueButton(
            label: currentStep == totalSteps
                ? 'Submit Registration'
                : 'Continue',
            isLoading: isLoading,
            onTap: onNext,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Back Button — subtle hover lift
// ═══════════════════════════════════════════════════════════
class _BackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
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
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 52,
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.navy.withValues(alpha: 0.04)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered
                  ? AppColors.navy.withValues(alpha: 0.25)
                  : AppColors.lightGray,
            ),
          ),
          child: Center(
            child: Text(
              'Back',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color:
                    _hovered ? AppColors.navy : AppColors.darkGray,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Continue Button — shimmer sweep on hover, gradient shift,
//                   arrow expand, scale press feedback
// ═══════════════════════════════════════════════════════════
class _ContinueButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _ContinueButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;
  late AnimationController _shimCtrl;

  @override
  void initState() {
    super.initState();
    _shimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void dispose() {
    _shimCtrl.dispose();
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
        if (!widget.isLoading) _shimCtrl.repeat();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _shimCtrl
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
                  color: (_hovered
                              ? AppColors.teal
                              : AppColors.navy)
                          .withValues(
                              alpha: _hovered ? 0.42 : 0.28),
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
                      animation: _shimCtrl,
                      builder: (ctx, _) => Positioned(
                        left:
                            -80 + _shimCtrl.value * 580,
                        top: 0,
                        bottom: 0,
                        width: 80,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(
                                    alpha: 0.14),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Label / loading
                  Center(
                    child: widget.isLoading
                        ? const _LoadingDots()
                        : Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Text(
                                widget.label,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              AnimatedSize(
                                duration:
                                    const Duration(
                                        milliseconds: 200),
                                curve: Curves.easeOutBack,
                                child: _hovered
                                    ? const Padding(
                                        padding:
                                            EdgeInsets.only(
                                                left: 8),
                                        child: Icon(
                                          Icons
                                              .arrow_forward_rounded,
                                          color:
                                              Colors.white,
                                          size: 18,
                                        ),
                                      )
                                    : const SizedBox
                                        .shrink(),
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
// Loading Dots — 3-dot bounce
// ═══════════════════════════════════════════════════════════
class _LoadingDots extends StatelessWidget {
  const _LoadingDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        )
            .animate(
              onPlay: (c) => c.repeat(),
              delay: Duration(milliseconds: i * 160),
            )
            .slideY(
              begin: 0,
              end: -0.5,
              duration: 400.ms,
              curve: Curves.easeInOut,
            )
            .then()
            .slideY(
              begin: -0.5,
              end: 0,
              duration: 400.ms,
              curve: Curves.easeInOut,
            );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Step Progress Bar — thin gradient bar showing % complete
// ═══════════════════════════════════════════════════════════
class _StepProgressBar extends StatelessWidget {
  final int current;
  final int total;

  const _StepProgressBar({
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = current / total;
    return LayoutBuilder(builder: (ctx, constraints) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Track
          Stack(
            children: [
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.lightGray.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 550),
                curve: Curves.easeOutCubic,
                height: 4,
                width: constraints.maxWidth * progress,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.teal, AppColors.sky, AppColors.golden],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.45),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              // Glowing head dot
              AnimatedPositioned(
                duration: const Duration(milliseconds: 550),
                curve: Curves.easeOutCubic,
                left: (constraints.maxWidth * progress - 5)
                    .clamp(0.0, constraints.maxWidth - 5),
                top: -3,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color.lerp(
                      AppColors.sky,
                      AppColors.golden,
                      progress,
                    )!,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.sky.withValues(alpha: 0.55),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Percentage label
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero)
                    .animate(CurvedAnimation(
                        parent: anim, curve: Curves.easeOutCubic)),
                child: child,
              ),
            ),
            child: Text(
              key: ValueKey(current),
              '${(progress * 100).round()}% complete',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color.lerp(
                  AppColors.teal,
                  AppColors.golden,
                  progress,
                )!,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════
// STEP 1: Role Selection
// ═══════════════════════════════════════════════════════════
class _Step1Role extends StatelessWidget {
  final String selectedRole;
  final void Function(String) onSelect;

  const _Step1Role(
      {required this.selectedRole, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create Your Account',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(
            begin: 0.12,
            end: 0,
            curve: Curves.easeOutCubic),
        const SizedBox(height: 4),
        Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.teal, AppColors.sky]),
            borderRadius: BorderRadius.circular(4),
          ),
        ).animate(delay: 80.ms).fadeIn(duration: 350.ms).slideX(
            begin: -0.5,
            end: 0,
            curve: Curves.easeOutCubic),
        const SizedBox(height: 10),
        const Text(
          'Choose how you want to use HIRAYA',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.black45),
        ).animate(delay: 100.ms).fadeIn(duration: 380.ms),
        const SizedBox(height: 32),
        _RoleCard(
          title: 'Innovator',
          subtitle:
              'I have an innovation or product to showcase',
          icon: Icons.lightbulb_rounded,
          color: AppColors.teal,
          selected: selectedRole == 'innovator',
          onTap: () => onSelect('innovator'),
        )
            .animate(delay: 160.ms)
            .fadeIn(duration: 420.ms)
            .slideY(
                begin: 0.10,
                end: 0,
                curve: Curves.easeOutCubic),
        const SizedBox(height: 16),
        _RoleCard(
          title: 'Client / Investor',
          subtitle:
              'I am looking to discover and invest in innovations',
          icon: Icons.business_center_rounded,
          color: AppColors.navy,
          selected: selectedRole == 'client',
          onTap: () => onSelect('client'),
        )
            .animate(delay: 240.ms)
            .fadeIn(duration: 420.ms)
            .slideY(
                begin: 0.10,
                end: 0,
                curve: Curves.easeOutCubic),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Role Card — hover lift, glow, spring scale on tap
// ═══════════════════════════════════════════════════════════
class _RoleCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _tapCtrl;
  late Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _tapScale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.96), weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: 0.96, end: 1.03), weight: 2),
      TweenSequenceItem(
          tween: Tween(begin: 1.03, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
        parent: _tapCtrl, curve: Curves.linear));
  }

  @override
  void didUpdateWidget(_RoleCard old) {
    super.didUpdateWidget(old);
    if (widget.selected != old.selected && widget.selected) {
      _tapCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    final sel = widget.selected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _tapScale,
          builder: (_, child) => Transform.scale(
            scale: _tapScale.value,
            child: child,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: sel
                  ? c.withValues(alpha: 0.08)
                  : _hovered
                      ? c.withValues(alpha: 0.03)
                      : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: sel
                    ? c
                    : _hovered
                        ? c.withValues(alpha: 0.35)
                        : AppColors.lightGray,
                width: sel ? 2 : 1,
              ),
              boxShadow: [
                if (sel)
                  BoxShadow(
                    color: c.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                if (_hovered && !sel)
                  BoxShadow(
                    color: c.withValues(alpha: 0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration:
                      const Duration(milliseconds: 280),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: sel
                        ? c
                        : _hovered
                            ? c.withValues(alpha: 0.12)
                            : AppColors.lightGray,
                    borderRadius:
                        BorderRadius.circular(12),
                    boxShadow: sel
                        ? [
                            BoxShadow(
                              color: c.withValues(
                                  alpha: 0.35),
                              blurRadius: 12,
                            )
                          ]
                        : [],
                  ),
                  child: Icon(widget.icon,
                      color: sel || _hovered
                          ? (sel
                              ? Colors.white
                              : c)
                          : Colors.black38,
                      size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: sel
                                ? c
                                : _hovered
                                    ? c
                                    : AppColors.darkGray,
                          )),
                      const SizedBox(height: 4),
                      Text(widget.subtitle,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Colors.black45,
                          )),
                    ],
                  ),
                ),
                AnimatedScale(
                  scale: sel ? 1.0 : 0.0,
                  duration:
                      const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  child: Icon(
                      Icons.check_circle_rounded,
                      color: c,
                      size: 24),
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
// STEP 2: Basic Info
// ═══════════════════════════════════════════════════════════
class _Step2BasicInfo extends StatelessWidget {
  final TextEditingController firstNameCtrl;
  final TextEditingController lastNameCtrl;
  final TextEditingController middleNameCtrl;
  final TextEditingController usernameCtrl;
  final TextEditingController emailCtrl;
  final bool noMiddleName;
  final String selectedSuffix;
  final void Function(bool) onNoMiddleNameChanged;
  final void Function(String?) onSuffixChanged;

  const _Step2BasicInfo({
    required this.firstNameCtrl,
    required this.lastNameCtrl,
    required this.middleNameCtrl,
    required this.usernameCtrl,
    required this.emailCtrl,
    required this.noMiddleName,
    required this.selectedSuffix,
    required this.onNoMiddleNameChanged,
    required this.onSuffixChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Basic Information',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy))
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(
                begin: 0.12,
                end: 0,
                curve: Curves.easeOutCubic),
        const SizedBox(height: 4),
        Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.teal, AppColors.sky]),
            borderRadius: BorderRadius.circular(4),
          ),
        ).animate(delay: 60.ms).fadeIn(duration: 350.ms).slideX(
            begin: -0.5,
            end: 0,
            curve: Curves.easeOutCubic),
        const SizedBox(height: 8),
        const Text(
          'Enter your name exactly as it appears on your government-issued ID.',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.black45),
        ).animate(delay: 80.ms).fadeIn(duration: 380.ms),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: AuthTextField(
                label: 'First Name *',
                controller: firstNameCtrl,
                hint: 'Juan',
                maxLength: 50,
                validator: (v) {
                  if (v == null || v.trim().length < 2) {
                    return 'Minimum 2 characters';
                  }
                  if (!RegExp(r"^[a-zA-Z\s\-']+$")
                      .hasMatch(v)) {
                    return 'Letters only';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AuthTextField(
                label: 'Last Name *',
                controller: lastNameCtrl,
                hint: 'dela Cruz',
                maxLength: 50,
                validator: (v) {
                  if (v == null || v.trim().length < 2) {
                    return 'Minimum 2 characters';
                  }
                  return null;
                },
              ),
            ),
          ],
        ).animate(delay: 140.ms).fadeIn(duration: 400.ms).slideY(
            begin: 0.08,
            end: 0,
            curve: Curves.easeOutCubic),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AuthTextField(
                label: 'Middle Name',
                controller: middleNameCtrl,
                hint: 'Santos',
                maxLength: 50,
                readOnly: noMiddleName,
                validator: (_) => null,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Suffix',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                        color: AppColors.lightGray),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: selectedSuffix,
                    underline: const SizedBox(),
                    items: [
                      'None',
                      'Jr.',
                      'Sr.',
                      'II',
                      'III',
                      'IV'
                    ]
                        .map((s) => DropdownMenuItem(
                            value: s, child: Text(s)))
                        .toList(),
                    onChanged: onSuffixChanged,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: AppColors.darkGray),
                  ),
                ),
              ],
            ),
          ],
        ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(
            begin: 0.08,
            end: 0,
            curve: Curves.easeOutCubic),
        Row(
          children: [
            Checkbox(
              value: noMiddleName,
              onChanged: (v) =>
                  onNoMiddleNameChanged(v ?? false),
              activeColor: AppColors.teal,
            ),
            const Text('No middle name',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Colors.black54)),
          ],
        ),
        const SizedBox(height: 8),
        AuthTextField(
          label: 'Username *',
          controller: usernameCtrl,
          hint: 'juan_delacruz',
          maxLength: 30,
          validator: (v) {
            if (v == null || v.trim().length < 4) {
              return 'Minimum 4 characters';
            }
            if (!RegExp(r'^[a-z0-9_]+$').hasMatch(v)) {
              return 'Lowercase letters, numbers, underscore only';
            }
            return null;
          },
          prefix: const Icon(Icons.alternate_email,
              size: 18, color: Colors.black38),
        ).animate(delay: 260.ms).fadeIn(duration: 400.ms).slideY(
            begin: 0.08,
            end: 0,
            curve: Curves.easeOutCubic),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Email Address *',
          controller: emailCtrl,
          hint: 'juan@example.com',
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null ||
                !RegExp(r'^[^@]+@[^@]+\.[^@]+')
                    .hasMatch(v)) {
              return 'Enter a valid email address';
            }
            return null;
          },
          prefix: const Icon(Icons.email_outlined,
              size: 18, color: Colors.black38),
        ).animate(delay: 320.ms).fadeIn(duration: 400.ms).slideY(
            begin: 0.08,
            end: 0,
            curve: Curves.easeOutCubic),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// STEP 3: Security
// ═══════════════════════════════════════════════════════════
class _Step3Security extends StatelessWidget {
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final String passwordValue;
  final bool passwordMatch;
  final void Function(String) onPasswordChanged;
  final void Function(String) onConfirmChanged;

  const _Step3Security({
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.passwordValue,
    required this.passwordMatch,
    required this.onPasswordChanged,
    required this.onConfirmChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Create Password',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy))
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(
                begin: 0.12,
                end: 0,
                curve: Curves.easeOutCubic),
        const SizedBox(height: 4),
        Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.teal, AppColors.sky]),
            borderRadius: BorderRadius.circular(4),
          ),
        ).animate(delay: 60.ms).fadeIn(duration: 350.ms).slideX(
            begin: -0.5,
            end: 0,
            curve: Curves.easeOutCubic),
        const SizedBox(height: 8),
        const Text(
          'Use a strong password to keep your account secure.',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.black45),
        ).animate(delay: 80.ms).fadeIn(duration: 380.ms),
        const SizedBox(height: 24),
        AuthTextField(
          label: 'Password *',
          controller: passwordCtrl,
          isPassword: true,
          onChanged: onPasswordChanged,
          validator: (v) {
            if (v == null || v.length < 8) {
              return 'Minimum 8 characters';
            }
            return null;
          },
        ).animate(delay: 140.ms).fadeIn(duration: 420.ms).slideY(
            begin: 0.10,
            end: 0,
            curve: Curves.easeOutCubic),
        PasswordStrengthMeter(password: passwordValue),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Confirm Password *',
          controller: confirmCtrl,
          isPassword: true,
          onChanged: onConfirmChanged,
          validator: (v) {
            if (v != passwordCtrl.text) {
              return 'Passwords do not match';
            }
            return null;
          },
          suffix: passwordValue.isNotEmpty
              ? Icon(
                  passwordMatch
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: passwordMatch
                      ? AppColors.teal
                      : AppColors.crimson,
                  size: 20,
                )
              : null,
        ).animate(delay: 200.ms).fadeIn(duration: 420.ms).slideY(
            begin: 0.10,
            end: 0,
            curve: Curves.easeOutCubic),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// STEP 4: Contact
// ═══════════════════════════════════════════════════════════
class _Step4Contact extends StatelessWidget {
  final TextEditingController phoneCtrl;
  final String countryCode;
  final void Function(String) onCountryCodeChanged;

  const _Step4Contact({
    required this.phoneCtrl,
    required this.countryCode,
    required this.onCountryCodeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Contact Details',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy))
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(
                begin: 0.12,
                end: 0,
                curve: Curves.easeOutCubic),
        const SizedBox(height: 4),
        Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.teal, AppColors.sky]),
            borderRadius: BorderRadius.circular(4),
          ),
        ).animate(delay: 60.ms).fadeIn(duration: 350.ms).slideX(
            begin: -0.5,
            end: 0,
            curve: Curves.easeOutCubic),
        const SizedBox(height: 8),
        const Text(
          'Your phone number will be used for account verification.',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.black45),
        ).animate(delay: 80.ms).fadeIn(duration: 380.ms),
        const SizedBox(height: 24),
        const Text('Phone Number *',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy))
            .animate(delay: 120.ms)
            .fadeIn(duration: 380.ms),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border:
                    Border.all(color: AppColors.lightGray),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: countryCode,
                underline: const SizedBox(),
                items: ['+63', '+1', '+44', '+61', '+81']
                    .map((c) => DropdownMenuItem(
                        value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    onCountryCodeChanged(v ?? '+63'),
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: AppColors.darkGray),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AuthTextField(
                label: '',
                controller: phoneCtrl,
                hint: '9XXXXXXXXX',
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.trim().length < 7) {
                    return 'Enter a valid phone number';
                  }
                  return null;
                },
              ),
            ),
          ],
        ).animate(delay: 160.ms).fadeIn(duration: 420.ms).slideY(
            begin: 0.10,
            end: 0,
            curve: Curves.easeOutCubic),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.sky.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.sky.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline,
                  color: AppColors.sky, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'OTP verification via SMS will be available after admin approval.',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.sky),
                ),
              ),
            ],
          ),
        ).animate(delay: 240.ms).fadeIn(duration: 400.ms),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// STEP 5: Identity Verification
// ═══════════════════════════════════════════════════════════
class _Step5Identity extends StatelessWidget {
  const _Step5Identity();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Identity Verification',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy))
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(
                begin: 0.12,
                end: 0,
                curve: Curves.easeOutCubic),
        const SizedBox(height: 4),
        Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.teal, AppColors.sky]),
            borderRadius: BorderRadius.circular(4),
          ),
        ).animate(delay: 60.ms).fadeIn(duration: 350.ms).slideX(
            begin: -0.5,
            end: 0,
            curve: Curves.easeOutCubic),
        const SizedBox(height: 8),
        const Text(
          'Upload a valid government-issued ID for KYC verification.',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.black45),
        ).animate(delay: 80.ms).fadeIn(duration: 380.ms),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.golden.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color:
                    AppColors.golden.withValues(alpha: 0.4)),
          ),
          child: const Row(
            children: [
              Icon(Icons.pending_actions_rounded,
                  color: AppColors.golden, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'KYC verification is pending supervisor approval. You may skip this step for now.',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.black54),
                ),
              ),
            ],
          ),
        ).animate(delay: 120.ms).fadeIn(duration: 400.ms),
        const SizedBox(height: 24),
        _UploadBox(
          label: 'Government-Issued ID',
          sublabel:
              'PhilSys, Passport, Driver\'s License, SSS/GSIS, PRC, Voter\'s ID',
          icon: Icons.badge_rounded,
        )
            .animate(delay: 180.ms)
            .fadeIn(duration: 420.ms)
            .slideY(
                begin: 0.10,
                end: 0,
                curve: Curves.easeOutCubic),
        const SizedBox(height: 16),
        _UploadBox(
          label: 'Selfie Holding ID',
          sublabel: 'Clear photo of you holding your ID',
          icon: Icons.face_rounded,
        )
            .animate(delay: 260.ms)
            .fadeIn(duration: 420.ms)
            .slideY(
                begin: 0.10,
                end: 0,
                curve: Curves.easeOutCubic),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Upload Box — hover state with border color shift
// ═══════════════════════════════════════════════════════════
class _UploadBox extends StatefulWidget {
  final String label;
  final String sublabel;
  final IconData icon;

  const _UploadBox({
    required this.label,
    required this.sublabel,
    required this.icon,
  });

  @override
  State<_UploadBox> createState() => _UploadBoxState();
}

class _UploadBoxState extends State<_UploadBox> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.teal.withValues(alpha: 0.03)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered
                  ? AppColors.teal.withValues(alpha: 0.40)
                  : AppColors.lightGray,
              width: _hovered ? 2 : 1.5,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: AppColors.teal
                          .withValues(alpha: 0.10),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              AnimatedScale(
                scale: _hovered ? 1.12 : 1.0,
                duration:
                    const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: Icon(widget.icon,
                    size: 40,
                    color: _hovered
                        ? AppColors.teal
                        : AppColors.lightGray),
              ),
              const SizedBox(height: 12),
              Text(widget.label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _hovered
                        ? AppColors.teal
                        : AppColors.navy,
                  )),
              const SizedBox(height: 4),
              Text(widget.sublabel,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.black38),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {},
                icon:
                    const Icon(Icons.upload_rounded, size: 16),
                label: const Text('Upload File',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.teal,
                  side: const BorderSide(
                      color: AppColors.teal),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8)),
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
// STEP 6: Consent
// ═══════════════════════════════════════════════════════════
class _Step6Consent extends StatelessWidget {
  final bool privacyAccepted;
  final bool dataConsentAccepted;
  final void Function(bool?) onPrivacyChanged;
  final void Function(bool?) onDataConsentChanged;

  const _Step6Consent({
    required this.privacyAccepted,
    required this.dataConsentAccepted,
    required this.onPrivacyChanged,
    required this.onDataConsentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Privacy & Consent',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy))
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(
                begin: 0.12,
                end: 0,
                curve: Curves.easeOutCubic),
        const SizedBox(height: 4),
        Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.teal, AppColors.sky]),
            borderRadius: BorderRadius.circular(4),
          ),
        ).animate(delay: 60.ms).fadeIn(duration: 350.ms).slideX(
            begin: -0.5,
            end: 0,
            curve: Curves.easeOutCubic),
        const SizedBox(height: 8),
        const Text(
          'Please read and accept the following before creating your account.',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.black45),
        ).animate(delay: 80.ms).fadeIn(duration: 380.ms),
        const SizedBox(height: 24),
        _ConsentCard(
          title: 'Privacy Policy & Terms of Service',
          description:
              'I have read and agree to HIRAYA\'s Privacy Policy and Terms of Service. I understand how my data will be used and stored.',
          accepted: privacyAccepted,
          onChanged: onPrivacyChanged,
          icon: Icons.policy_rounded,
          color: AppColors.navy,
        )
            .animate(delay: 140.ms)
            .fadeIn(duration: 420.ms)
            .slideY(
                begin: 0.10,
                end: 0,
                curve: Curves.easeOutCubic),
        const SizedBox(height: 16),
        _ConsentCard(
          title: 'Data Processing Consent',
          description:
              'I consent to HIRAYA collecting and processing my personal data, including identity documents, for KYC verification purposes under RA 10173 (Data Privacy Act of 2012).',
          accepted: dataConsentAccepted,
          onChanged: onDataConsentChanged,
          icon: Icons.shield_rounded,
          color: AppColors.teal,
        )
            .animate(delay: 220.ms)
            .fadeIn(duration: 420.ms)
            .slideY(
                begin: 0.10,
                end: 0,
                curve: Curves.easeOutCubic),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.offWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.lightGray),
          ),
          child: const Text(
            'Both checkboxes are required. Neither is pre-checked in accordance with RA 10173 informed consent requirements.',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.black45,
                height: 1.5),
          ),
        ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Consent Card — spring check animation on toggle
// ═══════════════════════════════════════════════════════════
class _ConsentCard extends StatefulWidget {
  final String title;
  final String description;
  final bool accepted;
  final void Function(bool?) onChanged;
  final IconData icon;
  final Color color;

  const _ConsentCard({
    required this.title,
    required this.description,
    required this.accepted,
    required this.onChanged,
    required this.icon,
    required this.color,
  });

  @override
  State<_ConsentCard> createState() => _ConsentCardState();
}

class _ConsentCardState extends State<_ConsentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkCtrl;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _checkScale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.7), weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: 0.7, end: 1.15), weight: 2),
      TweenSequenceItem(
          tween: Tween(begin: 1.15, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
        parent: _checkCtrl, curve: Curves.linear));
  }

  @override
  void didUpdateWidget(_ConsentCard old) {
    super.didUpdateWidget(old);
    if (widget.accepted != old.accepted) {
      _checkCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _checkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    final sel = widget.accepted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: sel
            ? c.withValues(alpha: 0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: sel ? c : AppColors.lightGray,
          width: sel ? 1.5 : 1,
        ),
        boxShadow: sel
            ? [
                BoxShadow(
                  color: c.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _checkScale,
            builder: (_, child) => Transform.scale(
              scale: _checkScale.value,
              child: child,
            ),
            child: Checkbox(
              value: sel,
              onChanged: widget.onChanged,
              activeColor: c,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(widget.icon, color: c, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(widget.title,
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: c)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(widget.description,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.black54,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// STEP 7: Review
// ═══════════════════════════════════════════════════════════
class _Step7Review extends StatelessWidget {
  final SignupData data;

  const _Step7Review({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review Your Details',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy))
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(
                begin: 0.12,
                end: 0,
                curve: Curves.easeOutCubic),
        const SizedBox(height: 4),
        Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.teal, AppColors.sky]),
            borderRadius: BorderRadius.circular(4),
          ),
        ).animate(delay: 60.ms).fadeIn(duration: 350.ms).slideX(
            begin: -0.5,
            end: 0,
            curve: Curves.easeOutCubic),
        const SizedBox(height: 8),
        const Text(
          'Please confirm everything is correct before submitting.',
          style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.black45),
        ).animate(delay: 80.ms).fadeIn(duration: 380.ms),
        const SizedBox(height: 24),
        _ReviewSection(
          title: 'Account Type',
          items: {
            'Role': data.role.isEmpty
                ? '—'
                : data.role.toUpperCase(),
          },
        )
            .animate(delay: 140.ms)
            .fadeIn(duration: 420.ms)
            .slideY(
                begin: 0.10,
                end: 0,
                curve: Curves.easeOutCubic),
        _ReviewSection(
          title: 'Basic Information',
          items: {
            'Name':
                '${data.firstName} ${data.middleName.isEmpty ? '' : '${data.middleName} '}${data.lastName}${data.suffix.isEmpty ? '' : ', ${data.suffix}'}',
            'Username': data.username.isEmpty
                ? '—'
                : '@${data.username}',
            'Email':
                data.email.isEmpty ? '—' : data.email,
          },
        )
            .animate(delay: 200.ms)
            .fadeIn(duration: 420.ms)
            .slideY(
                begin: 0.10,
                end: 0,
                curve: Curves.easeOutCubic),
        _ReviewSection(
          title: 'Contact',
          items: {
            'Phone':
                '${data.countryCode} ${data.phone.isEmpty ? '—' : data.phone}',
          },
        )
            .animate(delay: 260.ms)
            .fadeIn(duration: 420.ms)
            .slideY(
                begin: 0.10,
                end: 0,
                curve: Curves.easeOutCubic),
        _ReviewSection(
          title: 'Consent',
          items: {
            'Privacy Policy': data.privacyAccepted
                ? '✓ Accepted'
                : '✗ Not accepted',
            'Data Consent': data.dataConsentAccepted
                ? '✓ Accepted'
                : '✗ Not accepted',
          },
        )
            .animate(delay: 320.ms)
            .fadeIn(duration: 420.ms)
            .slideY(
                begin: 0.10,
                end: 0,
                curve: Curves.easeOutCubic),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color:
                    AppColors.teal.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline,
                  color: AppColors.teal, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your account will be reviewed by an Admin before activation. You\'ll receive a confirmation email.',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.black54,
                      height: 1.5),
                ),
              ),
            ],
          ),
        ).animate(delay: 380.ms).fadeIn(duration: 400.ms),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Review Section — clean card with teal header
// ═══════════════════════════════════════════════════════════
class _ReviewSection extends StatelessWidget {
  final String title;
  final Map<String, String> items;

  const _ReviewSection(
      {required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teal,
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          ...items.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(e.key,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.black45)),
                    ),
                    Expanded(
                      child: Text(e.value,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkGray)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Dot Grid Painter — 28px grid of subtle dots
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
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => false;
}

// ═══════════════════════════════════════════════════════════
// Right-panel dot grid — very subtle navy dots on light bg
// ═══════════════════════════════════════════════════════════
class _RightDotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.navy.withValues(alpha: 0.028)
      ..style = PaintingStyle.fill;
    const spacing = 32.0;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_RightDotGridPainter old) => false;
}

// ═══════════════════════════════════════════════════════════
// Scanline Painter — horizontal lines for cinematic feel
// ═══════════════════════════════════════════════════════════
class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 0.5;
    const spacing = 4.0;
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter old) => false;
}

// ═══════════════════════════════════════════════════════════
// Orb — soft radial gradient circle
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
      left: alignRight ? null : x,
      right: alignRight ? x : null,
      top: alignBottom ? null : y,
      bottom: alignBottom ? y : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: alpha * 0.4),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Letter Stagger — per-character fadeIn + slideUp
// ═══════════════════════════════════════════════════════════
class _LetterStagger extends StatelessWidget {
  final String text;
  final TextStyle style;
  final int baseDelay;
  final int letterDelay;

  const _LetterStagger({
    required this.text,
    required this.style,
    required this.baseDelay,
    required this.letterDelay,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: text.split('').asMap().entries.map((e) {
        final i = e.key;
        final ch = e.value;
        return Text(ch, style: style)
            .animate(
                delay: Duration(
                    milliseconds: baseDelay + i * letterDelay))
            .fadeIn(duration: 380.ms)
            .slideY(
                begin: 0.35,
                end: 0,
                curve: Curves.easeOutBack);
      }).toList(),
    );
  }
}
