// lib/features/auth/screens/signup_screen.dart

import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/ph_address_data.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen>
    with TickerProviderStateMixin {
  int _step = 1;
  final _data = SignupData();

  final _firstNameCtrl   = TextEditingController();
  final _lastNameCtrl    = TextEditingController();
  final _middleNameCtrl  = TextEditingController();
  final _suffixCtrl      = TextEditingController();
  final _usernameCtrl    = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _passwordCtrl    = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _phoneCtrl       = TextEditingController();

  bool    _obscurePass    = true;
  bool    _obscureConfirm = true;
  String? _stepError;

  // Phone OTP
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes  = List.generate(6, (_) => FocusNode());
  bool   _phoneSending   = false;
  bool   _phoneOtpSent   = false;
  bool   _phoneVerified  = false;
  String _verificationId = '';
  String? _phoneOtpError;
  String get _phoneOtpCode => _otpControllers.map((c) => c.text).join();

  // KYC
  String? _govIdBase64, _govIdFileName, _selfieBase64, _selfieFileName;
  String? _selectedProvince;
  String? _selectedCity;
  DateTime? _dateOfBirth;

  // Animation
  late AnimationController _orbCtrl;
  late AnimationController _slideCtrl;
  int _prevStep = 1;

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat(reverse: true);
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyGooglePrefill());
  }

  void _applyGooglePrefill() {
    final auth = ref.read(authProvider);
    if (!auth.needsGoogleSignup) return;
    _data
      ..isGoogleSignup = true
      ..googleId       = auth.googlePrefillGoogleId
      ..email          = auth.googlePrefillEmail
      ..firstName      = auth.googlePrefillFirstName
      ..lastName       = auth.googlePrefillLastName;
    _emailCtrl.text     = auth.googlePrefillEmail;
    _firstNameCtrl.text = auth.googlePrefillFirstName;
    _lastNameCtrl.text  = auth.googlePrefillLastName;
    ref.read(authProvider.notifier).clearGooglePrefill();
    setState(() {});
  }

  @override
  void dispose() {
    for (final c in [_firstNameCtrl, _lastNameCtrl, _middleNameCtrl, _suffixCtrl,
                     _usernameCtrl, _emailCtrl, _passwordCtrl, _confirmPassCtrl, _phoneCtrl]) {
      c.dispose();
    }
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes)  f.dispose();
    _orbCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  // ── Navigation ───────────────────────────────────────────────────────────────
  void _next() {
    setState(() => _stepError = null);

    switch (_step) {
      case 1:
        if (_data.role.isEmpty) {
          setState(() => _stepError = 'Please select a role to continue');
          return;
        }
        break;

      case 2:
        _data
          ..firstName  = _firstNameCtrl.text.trim()
          ..lastName   = _lastNameCtrl.text.trim()
          ..middleName = _middleNameCtrl.text.trim()
          ..suffix     = _suffixCtrl.text.trim()
          ..username   = _usernameCtrl.text.trim()
          ..email      = _emailCtrl.text.trim();

        if (_data.firstName.isEmpty || _data.lastName.isEmpty ||
            _data.username.isEmpty  || _data.email.isEmpty) {
          setState(() => _stepError = 'Please fill in all required fields');
          return;
        }
        if (!_data.email.endsWith('@gmail.com')) {
          setState(() => _stepError = 'Only Gmail addresses (@gmail.com) are accepted');
          return;
        }
        if (_data.isGoogleSignup) { _goStep(4); return; }
        break;

      case 3:
        _data.password = _passwordCtrl.text;
        if (_data.password.length < 8) {
          setState(() => _stepError = 'Password must be at least 8 characters');
          return;
        }
        if (_data.password != _confirmPassCtrl.text) {
          setState(() => _stepError = 'Passwords do not match');
          return;
        }
        break;

      case 4:
        _data.phone = _phoneCtrl.text.trim();
        if (_data.phone.isEmpty) {
          setState(() => _stepError = 'Phone number is required');
          return;
        }
        if (!_phoneVerified) {
          setState(() => _stepError = 'Please verify your phone number to continue');
          return;
        }
        break;

      case 5:
        if (_dateOfBirth == null) {
          setState(() => _stepError = 'Date of birth is required');
          return;
        }
        if (_selectedProvince == null) {
          setState(() => _stepError = 'Province / Region is required');
          return;
        }
        if (_selectedCity == null) {
          setState(() => _stepError = 'City / Municipality is required');
          return;
        }
        if (_govIdBase64 == null || _selfieBase64 == null) {
          setState(() => _stepError = 'Both Government ID and Selfie are required');
          return;
        }
        _data
          ..dateOfBirth  = '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2,'0')}-${_dateOfBirth!.day.toString().padLeft(2,'0')}'
          ..city         = _selectedCity!
          ..province     = _selectedProvince!
          ..govIdBase64    = _govIdBase64
          ..govIdFileName  = _govIdFileName
          ..selfieBase64   = _selfieBase64
          ..selfieFileName = _selfieFileName;
        break;

      case 6:
        if (!_data.privacyAccepted || !_data.dataConsentAccepted) {
          setState(() => _stepError = 'You must accept all terms to continue');
          return;
        }
        break;

      case 7:
        _submit();
        return;
    }

    _goStep(_step + 1);
  }

  void _back() {
    if (_step == 1) { context.go('/login'); return; }
    if (_step == 4 && _data.isGoogleSignup) { _goStep(2); return; }
    _goStep(_step - 1);
  }

  void _goStep(int s) {
    setState(() {
      _prevStep = _step;
      _step = s;
      _stepError = null;
    });
    _slideCtrl.forward(from: 0);
  }

  // ── Phone OTP ─────────────────────────────────────────────────────────────────
  Future<void> _sendPhoneOtp() async {
    final rawPhone = _phoneCtrl.text.trim();
    if (rawPhone.isEmpty) {
      setState(() => _stepError = 'Enter your phone number first');
      return;
    }
    final fullPhone = '${_data.countryCode}$rawPhone';
    setState(() { _phoneSending = true; _phoneOtpError = null; });

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: fullPhone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (mounted) setState(() { _phoneVerified = true; _phoneSending = false; _phoneOtpSent = false; });
      },
      verificationFailed: (e) {
        if (mounted) setState(() { _phoneSending = false; _phoneOtpError = e.message ?? 'Verification failed. Check your number.'; });
      },
      codeSent: (vId, _) {
        if (mounted) setState(() { _verificationId = vId; _phoneOtpSent = true; _phoneSending = false; });
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> _verifyPhoneOtp() async {
    if (_phoneOtpCode.length < 6) return;
    setState(() { _phoneSending = true; _phoneOtpError = null; });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode:        _phoneOtpCode,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) setState(() { _phoneVerified = true; _phoneSending = false; _phoneOtpSent = false; });
    } catch (_) {
      if (mounted) setState(() { _phoneSending = false; _phoneOtpError = 'Invalid code. Try again.'; });
    }
  }

  void _onOtpDigitChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '').split('');
      for (int i = 0; i < 6 && i < digits.length; i++) _otpControllers[i].text = digits[i];
      final next = digits.length < 6 ? digits.length : 5;
      _otpFocusNodes[next].requestFocus();
      setState(() {});
      if (_phoneOtpCode.length == 6) _verifyPhoneOtp();
      return;
    }
    if (value.isNotEmpty && index < 5) _otpFocusNodes[index + 1].requestFocus();
    setState(() {});
  }

  void _onOtpKeyPress(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _otpControllers[index].text.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
      _otpControllers[index - 1].clear();
      setState(() {});
    }
  }

  // ── KYC file picker ───────────────────────────────────────────────────────────
  Future<void> _pickFile(bool isGovId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    final file   = result.files.single;
    final base64 = base64Encode(file.bytes!);
    setState(() {
      if (isGovId) { _govIdBase64  = base64; _govIdFileName  = file.name; }
      else         { _selfieBase64 = base64; _selfieFileName = file.name; }
    });
  }

  // ── Submit ────────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() => _stepError = null);
    await ref.read(authProvider.notifier).signup(_data);
    final auth = ref.read(authProvider);
    if (auth.error != null) {
      setState(() => _stepError = auth.error);
    } else if (mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.teal.withValues(alpha: 0.30), width: 1.5),
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 44),
            ).animate().scale(begin: const Offset(0.7, 0.7), duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 20),
            const Text('Registration Submitted!',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white),
              textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              'Your account is pending admin approval.\nYou will receive a Gmail notification once approved.',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white.withValues(alpha: 0.55), height: 1.5),
              textAlign: TextAlign.center),
            const SizedBox(height: 28),
            _DarkGoldenButton(
              label: 'Go to Login',
              onTap: () { Navigator.pop(context); context.go('/login'); },
            ),
          ]),
        ),
      ),
    );
  }

  // ── Step label helpers ────────────────────────────────────────────────────────
  int get _totalSteps => _data.isGoogleSignup ? 6 : 7;

  String _stepTitle(int step) {
    switch (step) {
      case 1: return 'Choose Your Role';
      case 2: return 'Basic Information';
      case 3: return 'Create Password';
      case 4: return 'Phone Verification';
      case 5: return 'Identity Verification';
      case 6: return 'Terms & Consent';
      case 7: return 'Review Application';
      default: return '';
    }
  }

  String _stepSubtitle(int step) {
    switch (step) {
      case 1: return 'How will you use HIRAYA?';
      case 2: return 'Tell us about yourself';
      case 3: return 'Secure your account';
      case 4: return 'Verify your phone number';
      case 5: return 'Upload your documents';
      case 6: return 'Review and accept terms';
      case 7: return 'Confirm your details';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final displayStep = (_data.isGoogleSignup && _step >= 4) ? _step - 1 : _step;
    final progress    = _step / _totalSteps;

    return Scaffold(
      backgroundColor: AppColors.deepVoid,
      body: Row(
        children: [
          // Left decorative panel (desktop only)
          if (MediaQuery.of(context).size.width > 900)
            Expanded(
              flex: 2,
              child: _SignupLeftPanel(
                orbCtrl: _orbCtrl,
                step: _step,
                stepTitle: _stepTitle(_step),
                stepSubtitle: _stepSubtitle(_step),
              ),
            ),

          // Right form panel
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.darkSurface, Color(0xFF0F1F2E), AppColors.midnight],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Opacity(opacity: 0.02, child: CustomPaint(painter: _GridPainter())),
                  ),
                  SafeArea(
                    child: Column(
                      children: [
                        // ── Progress header ──
                        _buildProgressHeader(displayStep, progress, auth),

                        // ── Error banner ──
                        if (_stepError != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.crimson.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.crimson.withValues(alpha: 0.30)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline, color: AppColors.crimson, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_stepError!,
                                  style: const TextStyle(fontFamily: 'Poppins', color: AppColors.crimson, fontSize: 13)),
                              ),
                            ]),
                          ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),

                        // ── Step content ──
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              transitionBuilder: (child, anim) => SlideTransition(
                                position: Tween<Offset>(
                                  begin: Offset(_step > _prevStep ? 0.08 : -0.08, 0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                                child: FadeTransition(opacity: anim, child: child),
                              ),
                              child: KeyedSubtree(
                                key: ValueKey(_step),
                                child: _buildCurrentStep(),
                              ),
                            ),
                          ),
                        ),

                        // ── Nav buttons ──
                        _buildNavButtons(auth),
                      ],
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

  Widget _buildProgressHeader(int displayStep, double progress, AuthState auth) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: AppColors.richNavy.withValues(alpha: 0.50),
        border: Border(
          bottom: BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GestureDetector(
            onTap: _back,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 14),
            ),
          ),
          const SizedBox(width: 12),
          Text('Step $displayStep of $_totalSteps',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            )),
          const Spacer(),
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text('Cancel',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 13,
              )),
          ),
        ]),
        const SizedBox(height: 10),
        // Step indicator dots
        Row(
          children: List.generate(_totalSteps, (i) {
            final isActive   = i + 1 == _step;
            final isComplete = i + 1 < _step;
            return Expanded(
              child: AnimatedContainer(
                duration: 300.ms,
                height: 3,
                margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 4 : 0),
                decoration: BoxDecoration(
                  color: isComplete
                      ? AppColors.golden
                      : isActive
                          ? AppColors.golden.withValues(alpha: 0.70)
                          : Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ]),
    );
  }

  Widget _buildNavButtons(AuthState auth) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        color: AppColors.darkSurface.withValues(alpha: 0.80),
        border: Border(top: BorderSide(color: AppColors.borderDark, width: 1)),
      ),
      child: _DarkGoldenButton(
        label: _step == _totalSteps ? 'Submit Application' : 'Continue',
        isLoading: auth.isLoading,
        onTap: auth.isLoading ? null : _next,
      ),
    );
  }

  Widget _buildCurrentStep() {
    return switch (_step) {
      1 => _buildStep1(),
      2 => _buildStep2(),
      3 => _buildStep3(),
      4 => _buildStep4(),
      5 => _buildStep5(),
      6 => _buildStep6(),
      7 => _buildStep7(),
      _ => const SizedBox(),
    };
  }

  // ── Step 1: Role ──────────────────────────────────────────────────────────────
  Widget _buildStep1() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _StepHeading(title: 'Choose Your Role', subtitle: 'Select how you will use the HIRAYA platform.')
          .animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
      const SizedBox(height: 24),

      _DarkRoleCard(
        title: 'Client',
        description: 'Browse and invest in innovative projects',
        icon: Icons.person_outline,
        selected: _data.role == 'client',
        onTap: () => setState(() => _data.role = 'client'),
      ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
      const SizedBox(height: 12),

      _DarkRoleCard(
        title: 'Innovator',
        description: 'Showcase and pitch your innovations',
        icon: Icons.lightbulb_outline,
        selected: _data.role == 'innovator',
        onTap: () => setState(() => _data.role = 'innovator'),
      ).animate(delay: 200.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

      const SizedBox(height: 32),
      Divider(color: AppColors.borderDark),
      const SizedBox(height: 20),

      Center(
        child: Text('Or continue with Google',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 13,
          )),
      ),
      const SizedBox(height: 14),

      _DarkGoogleButton(
        onTap: () async {
          if (_data.role.isEmpty) {
            setState(() => _stepError = 'Please select a role first');
            return;
          }
          setState(() => _stepError = null);
          await ref.read(authProvider.notifier).loginWithGoogle();
          if (!mounted) return;
          final auth = ref.read(authProvider);
          if (auth.needsGoogleSignup) {
            _data
              ..isGoogleSignup = true
              ..googleId       = auth.googlePrefillGoogleId
              ..email          = auth.googlePrefillEmail
              ..firstName      = auth.googlePrefillFirstName
              ..lastName       = auth.googlePrefillLastName;
            _emailCtrl.text     = auth.googlePrefillEmail;
            _firstNameCtrl.text = auth.googlePrefillFirstName;
            _lastNameCtrl.text  = auth.googlePrefillLastName;
            ref.read(authProvider.notifier).clearGooglePrefill();
            _goStep(2);
          } else if (auth.error != null) {
            setState(() => _stepError = auth.error);
          }
        },
      ).animate(delay: 300.ms).fadeIn(duration: 400.ms),

      const SizedBox(height: 24),
      Center(
        child: GestureDetector(
          onTap: () => context.go('/login'),
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.white.withValues(alpha: 0.40)),
              children: const [
                TextSpan(text: 'Already have an account? '),
                TextSpan(text: 'Sign In',
                  style: TextStyle(color: AppColors.golden, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  // ── Step 2: Basic Info ────────────────────────────────────────────────────────
  Widget _buildStep2() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _StepHeading(title: 'Basic Information', subtitle: 'Tell us about yourself.')
          .animate().fadeIn(duration: 400.ms),
      const SizedBox(height: 16),
      if (_data.isGoogleSignup)
        _InfoNote(
          message: 'Pre-filled from Google. Add your username and middle name.',
          color: AppColors.sky,
        ),
      const SizedBox(height: 4),
      _DarkField(controller: _firstNameCtrl,  label: 'First Name *',  icon: Icons.person_outline),
      const SizedBox(height: 12),
      _DarkField(controller: _lastNameCtrl,   label: 'Last Name *',   icon: Icons.person_outline),
      const SizedBox(height: 12),
      _DarkField(controller: _middleNameCtrl, label: 'Middle Name',   hint: 'Optional'),
      const SizedBox(height: 12),
      _DarkField(controller: _suffixCtrl,     label: 'Suffix',        hint: 'Jr., Sr., III (Optional)'),
      const SizedBox(height: 12),
      _DarkField(controller: _usernameCtrl,   label: 'Username *',    icon: Icons.alternate_email),
      const SizedBox(height: 12),
      _DarkField(
        controller: _emailCtrl,
        label: 'Gmail Address *',
        icon: Icons.email_outlined,
        helper: 'Must be @gmail.com',
        keyboardType: TextInputType.emailAddress,
        readOnly: _data.isGoogleSignup,
      ),
    ],
  );

  // ── Step 3: Password ──────────────────────────────────────────────────────────
  Widget _buildStep3() {
    final password = _passwordCtrl.text;
    int strength = 0;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#\$&*~%^()_\-+=\[\]{}|;:,.<>?]').hasMatch(password)) strength++;

    final strengthColors  = [Colors.transparent, AppColors.crimson, AppColors.golden, AppColors.sky, AppColors.teal];
    final strengthLabels  = ['', 'Weak', 'Fair', 'Good', 'Strong'];
    final strengthColor   = strengthColors[strength];
    final strengthLabel   = strengthLabels[strength];

    final requirements = [
      {'label': 'At least 8 characters',      'met': password.length >= 8},
      {'label': 'One uppercase letter (A-Z)', 'met': RegExp(r'[A-Z]').hasMatch(password)},
      {'label': 'One number (0-9)',           'met': RegExp(r'[0-9]').hasMatch(password)},
      {'label': 'One special character',      'met': RegExp(r'[!@#\$&*~%^()_\-+=\[\]{}|;:,.<>?]').hasMatch(password)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StepHeading(title: 'Create Password', subtitle: 'Choose a strong password for your account.')
            .animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 24),

        // Password field
        _DarkPasswordField(
          controller: _passwordCtrl,
          label: 'Password *',
          obscure: _obscurePass,
          onToggle: () => setState(() => _obscurePass = !_obscurePass),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),

        // Strength bar
        if (password.isNotEmpty) ...[
          Row(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: AnimatedContainer(
                  duration: 300.ms,
                  height: 4,
                  child: LinearProgressIndicator(
                    value: strength / 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedSwitcher(
              duration: 200.ms,
              child: Text(strengthLabel,
                key: ValueKey(strengthLabel),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: strengthColor,
                )),
            ),
          ]),
          const SizedBox(height: 14),

          // Requirements
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Password requirements:',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600,
                      color: AppColors.teal.withValues(alpha: 0.70))),
                const SizedBox(height: 10),
                ...requirements.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    AnimatedSwitcher(
                      duration: 200.ms,
                      child: Icon(
                        (r['met'] as bool) ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        key: ValueKey(r['met']),
                        size: 15,
                        color: (r['met'] as bool) ? AppColors.teal : Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(r['label'] as String,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: (r['met'] as bool)
                            ? Colors.white.withValues(alpha: 0.80)
                            : Colors.white.withValues(alpha: 0.35),
                        fontWeight: (r['met'] as bool) ? FontWeight.w500 : FontWeight.normal,
                      )),
                  ]),
                )),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Confirm password
        _DarkPasswordField(
          controller: _confirmPassCtrl,
          label: 'Confirm Password *',
          obscure: _obscureConfirm,
          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
          onChanged: (_) => setState(() {}),
        ),

        // Match indicator
        if (_confirmPassCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(children: [
            Icon(
              _passwordCtrl.text == _confirmPassCtrl.text
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              size: 14,
              color: _passwordCtrl.text == _confirmPassCtrl.text
                  ? AppColors.teal
                  : AppColors.crimson,
            ),
            const SizedBox(width: 6),
            Text(
              _passwordCtrl.text == _confirmPassCtrl.text
                  ? 'Passwords match'
                  : 'Passwords do not match',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: _passwordCtrl.text == _confirmPassCtrl.text
                    ? AppColors.teal
                    : AppColors.crimson,
              )),
          ]),
        ],
      ],
    );
  }

  // ── Step 4: Phone ─────────────────────────────────────────────────────────────
  Widget _buildStep4() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _StepHeading(title: 'Phone Verification', subtitle: "We'll send a one-time code to verify your number.")
          .animate().fadeIn(duration: 400.ms),
      const SizedBox(height: 8),
      _InfoNote(
        message: 'Phone verification is required for all users regardless of signup method.',
        color: AppColors.golden,
      ),
      const SizedBox(height: 16),

      if (_phoneVerified)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.teal.withValues(alpha: 0.30)),
          ),
          child: Row(children: [
            const Icon(Icons.check_circle, color: AppColors.teal, size: 20),
            const SizedBox(width: 10),
            Text('${_data.countryCode} ${_phoneCtrl.text}  ✓ Verified',
              style: const TextStyle(fontFamily: 'Poppins', color: AppColors.teal, fontWeight: FontWeight.w600)),
          ]),
        ).animate().scale(begin: const Offset(0.9, 0.9), duration: 400.ms, curve: Curves.easeOutBack)
      else ...[
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: DropdownButton<String>(
              value: _data.countryCode,
              underline: const SizedBox(),
              isDense: true,
              dropdownColor: AppColors.darkSurface,
              style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 14),
              items: const [
                DropdownMenuItem(value: '+63', child: Text('+63 🇵🇭')),
                DropdownMenuItem(value: '+1',  child: Text('+1  🇺🇸')),
                DropdownMenuItem(value: '+44', child: Text('+44 🇬🇧')),
                DropdownMenuItem(value: '+61', child: Text('+61 🇦🇺')),
              ],
              onChanged: (v) => setState(() => _data.countryCode = v ?? '+63'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _DarkField(
              controller: _phoneCtrl,
              label: 'Phone Number *',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
          ),
        ]),
        const SizedBox(height: 14),

        if (!_phoneOtpSent)
          _DarkGoldenButton(
            label: 'Send Verification Code',
            isLoading: _phoneSending,
            onTap: _phoneSending ? null : _sendPhoneOtp,
          )
        else ...[
          const SizedBox(height: 8),
          Text('Enter the 6-digit code sent to ${_data.countryCode}${_phoneCtrl.text}',
            style: TextStyle(fontFamily: 'Poppins', color: Colors.white.withValues(alpha: 0.50), fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) => _DarkOtpBox(
              controller: _otpControllers[i],
              focusNode: _otpFocusNodes[i],
              onChanged: (v) => _onOtpDigitChanged(i, v),
              onKey: (e) => _onOtpKeyPress(i, e),
              isFilled: _otpControllers[i].text.isNotEmpty,
            )),
          ),
          const SizedBox(height: 16),
          _DarkGoldenButton(
            label: 'Verify Code',
            isLoading: _phoneSending,
            onTap: (_phoneSending || _phoneOtpCode.length < 6) ? null : _verifyPhoneOtp,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _phoneSending ? null : _sendPhoneOtp,
              child: Text('Resend code',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.teal.withValues(alpha: 0.80),
                  fontWeight: FontWeight.w600,
                )),
            ),
          ),
        ],

        if (_phoneOtpError != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(_phoneOtpError!,
              style: const TextStyle(fontFamily: 'Poppins', color: AppColors.crimson, fontSize: 13)),
          ),
      ],
    ],
  );

  // ── Step 5: KYC ───────────────────────────────────────────────────────────────
  Widget _buildStep5() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _StepHeading(title: 'Identity Verification', subtitle: 'Upload your documents and provide personal details.')
          .animate().fadeIn(duration: 400.ms),
      const SizedBox(height: 20),

      // Date of Birth
      _DarkLabel(text: 'Date of Birth *'),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: _dateOfBirth ?? DateTime(now.year - 18, now.month, now.day),
            firstDate: DateTime(1900),
            lastDate: DateTime(now.year - 13, now.month, now.day),
            builder: (ctx, child) => Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.golden,
                  onPrimary: AppColors.navy,
                  surface: AppColors.darkSurface,
                ),
              ),
              child: child!,
            ),
          );
          if (picked != null) setState(() => _dateOfBirth = picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Row(children: [
            Icon(Icons.calendar_today_outlined, size: 18,
                color: _dateOfBirth != null ? AppColors.golden : Colors.white.withValues(alpha: 0.30)),
            const SizedBox(width: 10),
            Text(
              _dateOfBirth != null
                  ? '${_dateOfBirth!.month.toString().padLeft(2,'0')}/${_dateOfBirth!.day.toString().padLeft(2,'0')}/${_dateOfBirth!.year}'
                  : 'Select date of birth',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: _dateOfBirth != null ? Colors.white : Colors.white.withValues(alpha: 0.30),
                fontSize: 14,
              )),
          ]),
        ),
      ),
      const SizedBox(height: 16),

      // Province dropdown
      _DarkLabel(text: 'Province / Region *'),
      const SizedBox(height: 6),
      _DarkDropdown<String>(
        value: _selectedProvince,
        hint: 'Select province',
        icon: Icons.map_outlined,
        items: phProvinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
        onChanged: (val) => setState(() { _selectedProvince = val; _selectedCity = null; }),
      ),
      const SizedBox(height: 16),

      _DarkLabel(text: 'City / Municipality *'),
      const SizedBox(height: 6),
      _DarkDropdown<String>(
        value: _selectedCity,
        hint: _selectedProvince == null ? 'Select a province first' : 'Select city',
        icon: Icons.location_city_outlined,
        items: _selectedProvince == null
            ? null
            : citiesFor(_selectedProvince!).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: _selectedProvince == null ? null : (val) => setState(() => _selectedCity = val),
      ),
      const SizedBox(height: 24),

      _InfoNote(message: 'Both documents are required. You cannot proceed without uploading them.', color: AppColors.crimson),
      const SizedBox(height: 16),

      _DarkUploadBox(
        label: 'Government-Issued ID',
        hint: "Passport, Driver's License, SSS, PhilSys, etc.",
        icon: Icons.credit_card,
        fileName: _govIdFileName,
        onPick: () => _pickFile(true),
      ),
      const SizedBox(height: 16),
      _DarkUploadBox(
        label: 'Selfie Holding Your ID',
        hint: 'Hold your ID clearly next to your face',
        icon: Icons.camera_front_rounded,
        fileName: _selfieFileName,
        onPick: () => _pickFile(false),
      ),
    ],
  );

  // ── Step 6: Consent ───────────────────────────────────────────────────────────
  Widget _buildStep6() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _StepHeading(title: 'Terms & Consent', subtitle: 'Please review and accept the following.')
          .animate().fadeIn(duration: 400.ms),
      const SizedBox(height: 24),
      _DarkConsentTile(
        title: 'Privacy Policy',
        subtitle: 'I have read and agree to the HIRAYA Privacy Policy and Terms of Service.',
        value: _data.privacyAccepted,
        onChanged: (v) => setState(() => _data.privacyAccepted = v ?? false),
      ),
      const SizedBox(height: 12),
      _DarkConsentTile(
        title: 'Data Processing Consent',
        subtitle: 'I consent to HIRAYA collecting and processing my personal data including KYC documents under RA 10173.',
        value: _data.dataConsentAccepted,
        onChanged: (v) => setState(() => _data.dataConsentAccepted = v ?? false),
      ),
    ],
  );

  // ── Step 7: Review ────────────────────────────────────────────────────────────
  Widget _buildStep7() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _StepHeading(title: 'Review Application', subtitle: 'Confirm your information before submitting.')
          .animate().fadeIn(duration: 400.ms),
      const SizedBox(height: 24),

      _DarkReviewSection('Account', [
        _DarkReviewRow('Role',  _data.role.toUpperCase()),
        _DarkReviewRow('Email', _data.email),
        if (_data.isGoogleSignup) _DarkReviewRow('Login Method', 'Google'),
      ]),
      const SizedBox(height: 16),
      _DarkReviewSection('Personal Info', [
        _DarkReviewRow('Name', '${_data.firstName} ${_data.middleName.isNotEmpty ? '${_data.middleName} ' : ''}${_data.lastName}${_data.suffix.isNotEmpty ? ', ${_data.suffix}' : ''}'.trim()),
        _DarkReviewRow('Username', '@${_data.username}'),
        _DarkReviewRow('Phone',   '${_data.countryCode}${_data.phone} ✓'),
        _DarkReviewRow('Date of Birth', _data.dateOfBirth),
        _DarkReviewRow('Address', '${_data.city}, ${_data.province}'),
      ]),
      const SizedBox(height: 16),
      _DarkReviewSection('KYC Documents', [
        _DarkReviewRow('Government ID', _govIdFileName  ?? '—'),
        if (_govIdBase64 != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(base64Decode(_govIdBase64!), height: 140, width: double.infinity, fit: BoxFit.contain),
          ),
          const SizedBox(height: 12),
        ],
        _DarkReviewRow('Selfie with ID', _selfieFileName ?? '—'),
        if (_selfieBase64 != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(base64Decode(_selfieBase64!), height: 140, width: double.infinity, fit: BoxFit.contain),
          ),
        ],
      ]),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.golden.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.golden.withValues(alpha: 0.20)),
        ),
        child: Row(children: [
          const Icon(Icons.hourglass_top, color: AppColors.golden, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'After submission, an admin will review your KYC documents. You will receive an email at your Gmail once approved.',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white.withValues(alpha: 0.60), height: 1.4)),
          ),
        ]),
      ),
    ],
  );
}

// ── Signup Left Panel ─────────────────────────────────────────────────────────
class _SignupLeftPanel extends StatelessWidget {
  final AnimationController orbCtrl;
  final int step;
  final String stepTitle;
  final String stepSubtitle;

  const _SignupLeftPanel({
    required this.orbCtrl,
    required this.step,
    required this.stepTitle,
    required this.stepSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: orbCtrl,
      builder: (_, __) {
        final t = orbCtrl.value;
        return Container(
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end:   Alignment.bottomRight,
              colors: [AppColors.deepVoid, AppColors.richNavy, Color(0xFF0A2240)],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: Opacity(opacity: 0.025, child: CustomPaint(painter: _GridPainter()))),
              Positioned(
                top: -80 + t * 40,
                right: -60 + t * 25,
                child: Container(
                  width: 300, height: 300,
                  decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                    BoxShadow(color: AppColors.teal.withValues(alpha: 0.13), blurRadius: 180, spreadRadius: 30),
                  ]),
                ),
              ),
              Positioned(
                bottom: -60 + t * 30,
                left: -40 + t * 20,
                child: Container(
                  width: 260, height: 260,
                  decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                    BoxShadow(color: AppColors.golden.withValues(alpha: 0.09), blurRadius: 160, spreadRadius: 20),
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 56),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                        colors: [AppColors.golden, AppColors.warmEmber],
                      ).createShader(b),
                      child: const Text('HIRAYA',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
                    ),
                    const SizedBox(height: 4),
                    Text('Innovation Marketplace',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.white.withValues(alpha: 0.35), letterSpacing: 2)),

                    const Spacer(),

                    // Step icon
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: Container(
                        key: ValueKey(step),
                        width: 68, height: 68,
                        decoration: BoxDecoration(
                          color: AppColors.golden.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.golden.withValues(alpha: 0.25), width: 1.5),
                          boxShadow: [BoxShadow(color: AppColors.golden.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 8))],
                        ),
                        child: Icon(_stepIcon(step), color: AppColors.golden, size: 30),
                      ).animate().scale(begin: const Offset(0.8, 0.8), duration: 400.ms, curve: Curves.easeOutBack),
                    ),
                    const SizedBox(height: 24),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: Column(
                        key: ValueKey(step),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stepTitle,
                            style: const TextStyle(
                              fontFamily: 'Poppins', fontSize: 26, fontWeight: FontWeight.w800,
                              color: Colors.white, height: 1.2, letterSpacing: -0.5,
                            )),
                          const SizedBox(height: 10),
                          Text(stepSubtitle,
                            style: TextStyle(
                              fontFamily: 'Poppins', fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.50), height: 1.5,
                            )),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Trust pills
                    Wrap(spacing: 10, runSpacing: 8, children: [
                      _LeftTrustPill(icon: Icons.shield_rounded, label: 'Secure', color: AppColors.teal),
                      _LeftTrustPill(icon: Icons.verified_user_outlined, label: 'KYC Verified', color: AppColors.golden),
                      _LeftTrustPill(icon: Icons.flag_rounded, label: 'Philippine-made', color: AppColors.crimson),
                    ]),
                    const Spacer(),

                    Text('© 2025 HIRAYA Innovation Marketplace',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white.withValues(alpha: 0.20))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _stepIcon(int step) {
    switch (step) {
      case 1:  return Icons.people_outline_rounded;
      case 2:  return Icons.person_outline_rounded;
      case 3:  return Icons.lock_outline_rounded;
      case 4:  return Icons.phone_outlined;
      case 5:  return Icons.badge_outlined;
      case 6:  return Icons.gavel_rounded;
      case 7:  return Icons.fact_check_outlined;
      default: return Icons.lightbulb_outline;
    }
  }
}

class _LeftTrustPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _LeftTrustPill({required this.icon, required this.label, required this.color});

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
        Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.80))),
      ]),
    );
  }
}

// ── Shared dark form widgets ──────────────────────────────────────────────────

class _StepHeading extends StatelessWidget {
  final String title, subtitle;
  const _StepHeading({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
      const SizedBox(height: 4),
      Text(subtitle, style: TextStyle(fontFamily: 'Poppins', color: Colors.white.withValues(alpha: 0.45), fontSize: 13)),
    ]);
  }
}

class _DarkLabel extends StatelessWidget {
  final String text;
  const _DarkLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text,
      style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.60), letterSpacing: 0.3));
  }
}

class _InfoNote extends StatelessWidget {
  final String message;
  final Color color;
  const _InfoNote({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        Icon(Icons.info_outline, color: color.withValues(alpha: 0.70), size: 15),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message,
            style: TextStyle(fontFamily: 'Poppins', color: Colors.white.withValues(alpha: 0.60), fontSize: 12, height: 1.4)),
        ),
      ]),
    );
  }
}

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helper;
  final IconData? icon;
  final TextInputType keyboardType;
  final bool readOnly;

  const _DarkField({
    required this.controller,
    required this.label,
    this.hint,
    this.helper,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperStyle: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.white.withValues(alpha: 0.35)),
        labelStyle: TextStyle(fontFamily: 'Poppins', color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white.withValues(alpha: 0.30), size: 18) : null,
        suffixIcon: readOnly ? Icon(Icons.lock_outline, color: Colors.white.withValues(alpha: 0.25), size: 16) : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderDark)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.golden, width: 1.5)),
      ),
    );
  }
}

class _DarkPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final ValueChanged<String>? onChanged;

  const _DarkPasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontFamily: 'Poppins', color: Colors.white.withValues(alpha: 0.45), fontSize: 13),
        prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withValues(alpha: 0.30), size: 18),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.white.withValues(alpha: 0.30), size: 18),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderDark)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.golden, width: 1.5)),
      ),
    );
  }
}

class _DarkDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final IconData? icon;
  final List<DropdownMenuItem<T>>? items;
  final ValueChanged<T?>? onChanged;

  const _DarkDropdown({
    this.value,
    required this.hint,
    this.icon,
    this.items,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint,
              style: TextStyle(fontFamily: 'Poppins', color: Colors.white.withValues(alpha: 0.30), fontSize: 14)),
          isExpanded: true,
          dropdownColor: AppColors.darkSurface,
          style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 14),
          icon: Icon(Icons.expand_more_rounded, color: Colors.white.withValues(alpha: 0.30)),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DarkGoldenButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;

  const _DarkGoldenButton({required this.label, this.isLoading = false, this.onTap});

  @override
  State<_DarkGoldenButton> createState() => _DarkGoldenButtonState();
}

class _DarkGoldenButtonState extends State<_DarkGoldenButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.onTap != null && !widget.isLoading;
    return MouseRegion(
      cursor: active ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: active ? widget.onTap : null,
        child: AnimatedScale(
          scale: _hovered && active ? 1.01 : 1.0,
          duration: 200.ms,
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: 200.ms,
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: active
                  ? const LinearGradient(colors: [AppColors.golden, AppColors.warmEmber])
                  : null,
              color: active ? null : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(13),
              boxShadow: active && _hovered
                  ? [BoxShadow(color: AppColors.golden.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 6))]
                  : [BoxShadow(color: AppColors.golden.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.navy, strokeWidth: 2.5))
                  : Text(widget.label,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: active ? AppColors.navy : Colors.white.withValues(alpha: 0.30),
                      )),
            ),
          ),
        ),
      ),
    );
  }
}

class _DarkGoogleButton extends StatefulWidget {
  final VoidCallback onTap;
  const _DarkGoogleButton({required this.onTap});

  @override
  State<_DarkGoogleButton> createState() => _DarkGoogleButtonState();
}

class _DarkGoogleButtonState extends State<_DarkGoogleButton> {
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
          duration: 200.ms,
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: _hovered ? Colors.white.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _hovered ? Colors.white.withValues(alpha: 0.20) : AppColors.borderDark),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.g_mobiledata, size: 24, color: Color(0xFF4285F4)),
            const SizedBox(width: 10),
            Text('Sign up with Google',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.75))),
          ]),
        ),
      ),
    );
  }
}

class _DarkOtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKey;
  final bool isFilled;

  const _DarkOtpBox({
    required this.controller, required this.focusNode,
    required this.onChanged, required this.onKey, required this.isFilled,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 200.ms,
      width: 44, height: 54,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isFilled ? AppColors.golden.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFilled ? AppColors.golden.withValues(alpha: 0.60) : AppColors.borderDark,
          width: isFilled ? 2.0 : 1.0,
        ),
        boxShadow: isFilled
            ? [BoxShadow(color: AppColors.golden.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))]
            : [],
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: onKey,
        child: TextField(
          controller: controller, focusNode: focusNode, onChanged: onChanged,
          textAlign: TextAlign.center, maxLength: 1, keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            fontFamily: 'Poppins',
            color: isFilled ? AppColors.golden : Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
          decoration: const InputDecoration(counterText: '', border: InputBorder.none),
        ),
      ),
    );
  }
}

class _DarkRoleCard extends StatelessWidget {
  final String title, description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _DarkRoleCard({
    required this.title, required this.description,
    required this.icon, required this.selected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 250.ms,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? AppColors.golden.withValues(alpha: 0.07) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.golden.withValues(alpha: 0.50) : AppColors.borderDark,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: AppColors.golden.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 4))]
              : [],
        ),
        child: Row(children: [
          AnimatedContainer(
            duration: 250.ms,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected ? AppColors.golden.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: selected ? AppColors.golden : Colors.white.withValues(alpha: 0.40), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.golden : Colors.white,
                fontSize: 15,
              )),
            const SizedBox(height: 2),
            Text(description,
              style: TextStyle(fontFamily: 'Poppins', color: Colors.white.withValues(alpha: 0.45), fontSize: 12)),
          ])),
          if (selected)
            const Icon(Icons.check_circle, color: AppColors.golden, size: 20),
        ]),
      ),
    );
  }
}

class _DarkUploadBox extends StatelessWidget {
  final String label, hint;
  final IconData icon;
  final String? fileName;
  final VoidCallback onPick;

  const _DarkUploadBox({
    required this.label, required this.hint,
    required this.icon, this.fileName, required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final uploaded = fileName != null;
    return GestureDetector(
      onTap: onPick,
      child: AnimatedContainer(
        duration: 250.ms,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: uploaded ? AppColors.teal.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: uploaded ? AppColors.teal.withValues(alpha: 0.40) : AppColors.borderDark,
            width: uploaded ? 2 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: uploaded ? AppColors.teal.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(uploaded ? Icons.check : icon,
                color: uploaded ? AppColors.teal : Colors.white.withValues(alpha: 0.40), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13)),
            Text(uploaded ? fileName! : hint,
              style: TextStyle(fontFamily: 'Poppins', color: uploaded ? AppColors.teal : Colors.white.withValues(alpha: 0.35), fontSize: 12),
              overflow: TextOverflow.ellipsis),
          ])),
          Text(uploaded ? 'Replace' : 'Upload',
            style: TextStyle(fontFamily: 'Poppins', color: AppColors.golden, fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _DarkConsentTile extends StatelessWidget {
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _DarkConsentTile({
    required this.title, required this.subtitle,
    required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 200.ms,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: value ? AppColors.teal.withValues(alpha: 0.06) : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? AppColors.teal.withValues(alpha: 0.35) : AppColors.borderDark,
          width: value ? 1.5 : 1,
        ),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: 200.ms,
            width: 20, height: 20, margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: value ? AppColors.teal : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: value ? AppColors.teal : Colors.white.withValues(alpha: 0.30), width: 1.5),
            ),
            child: value ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: value ? Colors.white : Colors.white.withValues(alpha: 0.70), fontSize: 14)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontFamily: 'Poppins', color: Colors.white.withValues(alpha: 0.45), fontSize: 12, height: 1.4)),
        ])),
      ]),
    );
  }
}

Widget _DarkReviewSection(String title, List<Widget> rows) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title,
      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.white, fontSize: 14)),
    const SizedBox(height: 8),
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(children: rows),
    ),
  ]);
}

Widget _DarkReviewRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 120,
        child: Text(label,
          style: TextStyle(fontFamily: 'Poppins', color: Colors.white.withValues(alpha: 0.40), fontSize: 12))),
      Expanded(
        child: Text(value,
          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.white, fontSize: 13))),
    ]),
  );
}

// ── Grid Painter ──────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..strokeWidth = 0.5;
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
