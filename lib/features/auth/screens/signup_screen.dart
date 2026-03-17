// lib/features/auth/screens/signup_screen.dart

import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/ph_address_data.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
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

  @override
  void initState() {
    super.initState();
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
                     _usernameCtrl, _emailCtrl, _passwordCtrl, _confirmPassCtrl, _phoneCtrl]) c.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes)  f.dispose();
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

  void _goStep(int s) => setState(() { _step = s; _stepError = null; });

  // ── Phone OTP (Firebase) ─────────────────────────────────────────────────────
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

  void _onOtpKeyPress(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _otpControllers[index].text.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
      _otpControllers[index - 1].clear();
      setState(() {});
    }
  }

  // ── KYC file picker ──────────────────────────────────────────────────────────
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

  // ── Submit ───────────────────────────────────────────────────────────────────
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
      context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF00897B), size: 64),
          const SizedBox(height: 16),
          const Text('Registration Submitted!', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF0A2540)), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Your account is pending admin approval.\nYou will receive a Gmail notification once approved.', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black54, height: 1.5), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); context.go('/login'); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), minimumSize: const Size(double.infinity, 48)),
            child: const Text('Go to Login', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ]),
      ),
    );
  }

  // ── Constants ────────────────────────────────────────────────────────────────
  static const _teal  = Color(0xFF00897B);
  static const _dark  = Color(0xFF0A2540);
  static const _bg    = Color(0xFFF5F7FA);
  static const _white = Colors.white;

  InputDecoration _field(String label, {String? hint, IconData? icon, String? helper}) =>
      InputDecoration(
        labelText:   label,
        hintText:    hint,
        helperText:  helper,
        helperStyle: const TextStyle(fontSize: 11, color: Colors.black45),
        prefixIcon:  icon != null ? Icon(icon, color: _teal) : null,
        filled:      true,
        fillColor:   _white,
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _teal, width: 1.5)),
        labelStyle: const TextStyle(color: Colors.black54),
      );

  @override
  Widget build(BuildContext context) {
    final auth  = ref.watch(authProvider);
    final total = _data.isGoogleSignup ? 6 : 7;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(total),
          if (_stepError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Colors.red.shade50,
              child: Row(children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_stepError!, style: const TextStyle(color: Colors.red, fontSize: 13))),
              ]),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: _buildCurrentStep(),
            ),
          ),
          _buildNavButtons(auth),
        ]),
      ),
    );
  }

  Widget _buildHeader(int total) {
    final displayStep = (_data.isGoogleSignup && _step >= 4) ? _step - 1 : _step;
    return Container(
      color: _dark,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          IconButton(onPressed: _back, icon: const Icon(Icons.arrow_back_ios, color: _white, size: 18)),
          const SizedBox(width: 4),
          Text('Step $displayStep of $total', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          TextButton(onPressed: () => context.go('/login'), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
        ]),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _step / (_data.isGoogleSignup ? 6 : 7),
          backgroundColor: Colors.white24,
          valueColor: const AlwaysStoppedAnimation<Color>(_teal),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ]),
    );
  }

  Widget _buildNavButtons(AuthState auth) => Container(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
    decoration: const BoxDecoration(color: _white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))]),
    child: SizedBox(
      width: double.infinity, height: 52,
      child: ElevatedButton(
        onPressed: auth.isLoading ? null : _next,
        style: ElevatedButton.styleFrom(
          backgroundColor:         _teal,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: auth.isLoading
            ? const CircularProgressIndicator(color: _white, strokeWidth: 2)
            : Text(
                _step == (_data.isGoogleSignup ? 6 : 7) ? 'Submit Application' : 'Continue',
                style: const TextStyle(color: _white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    ),
  );

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

  // ── Step 1: Role ─────────────────────────────────────────────────────────────
  Widget _buildStep1() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Choose Your Role', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _dark)),
      const SizedBox(height: 8),
      const Text('Select how you will use the HIRAYA platform.', style: TextStyle(color: Colors.black54)),
      const SizedBox(height: 24),
      _RoleCard(title: 'Client',    description: 'Browse and invest in innovative projects', icon: Icons.person_outline,    selected: _data.role == 'client',    onTap: () => setState(() => _data.role = 'client')),
      const SizedBox(height: 12),
      _RoleCard(title: 'Innovator', description: 'Showcase and pitch your innovations',      icon: Icons.lightbulb_outline, selected: _data.role == 'innovator', onTap: () => setState(() => _data.role = 'innovator')),
      const SizedBox(height: 32),
      const Divider(),
      const SizedBox(height: 16),
      const Center(child: Text('Or continue with Google', style: TextStyle(color: Colors.black45, fontSize: 13))),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity, height: 48,
        child: OutlinedButton.icon(
          onPressed: () async {
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
          icon:  const Icon(Icons.g_mobiledata, size: 24, color: Colors.red),
          label: const Text('Sign up with Google', style: TextStyle(color: _dark)),
          style: OutlinedButton.styleFrom(
            side:  BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    ],
  );

  // ── Step 2: Basic Info ────────────────────────────────────────────────────────
  Widget _buildStep2() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Basic Information', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _dark)),
      const SizedBox(height: 16),
      if (_data.isGoogleSignup)
        Container(
          padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue.shade200)),
          child: Row(children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
            const SizedBox(width: 8),
            const Expanded(child: Text('Pre-filled from Google. Add username and middle name.', style: TextStyle(color: Colors.black54, fontSize: 12))),
          ]),
        ),
      TextField(controller: _firstNameCtrl,  decoration: _field('First Name *',  icon: Icons.person_outline)),
      const SizedBox(height: 12),
      TextField(controller: _lastNameCtrl,   decoration: _field('Last Name *',   icon: Icons.person_outline)),
      const SizedBox(height: 12),
      TextField(controller: _middleNameCtrl, decoration: _field('Middle Name',   hint: 'Optional')),
      const SizedBox(height: 12),
      TextField(controller: _suffixCtrl,     decoration: _field('Suffix',        hint: 'Jr., Sr., III (Optional)')),
      const SizedBox(height: 12),
      TextField(controller: _usernameCtrl,   decoration: _field('Username *',    icon: Icons.alternate_email)),
      const SizedBox(height: 12),
      TextField(
        controller:   _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        readOnly:     _data.isGoogleSignup,
        decoration:   _field(
          'Gmail Address *', icon: Icons.email_outlined,
          helper: 'Must be @gmail.com — approval status and OTP codes sent here',
        ).copyWith(
          suffixIcon: _data.isGoogleSignup ? const Icon(Icons.lock_outline, color: Colors.black38, size: 18) : null,
        ),
      ),
    ],
  );

  // ── Step 3: Password (manual only) ───────────────────────────────────────────
  Widget _buildStep3() {
    final password = _passwordCtrl.text;

    // Strength calculation
    int strength = 0;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#\$&*~%^()_\-+=\[\]{}|;:,.<>?]').hasMatch(password)) strength++;

    final strengthLabel = ['', 'Weak', 'Fair', 'Good', 'Strong'][strength];
    final strengthColor = [
      Colors.transparent,
      Colors.red,
      Colors.orange,
      Colors.lightGreen,
      const Color(0xFF00897B),
    ][strength];

    final requirements = [
      {'label': 'At least 8 characters',      'met': password.length >= 8},
      {'label': 'One uppercase letter (A-Z)', 'met': RegExp(r'[A-Z]').hasMatch(password)},
      {'label': 'One number (0-9)',           'met': RegExp(r'[0-9]').hasMatch(password)},
      {'label': 'One special character',      'met': RegExp(r'[!@#\$&*~%^()_\-+=\[\]{}|;:,.<>?]').hasMatch(password)},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Create Password',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _dark)),
        const SizedBox(height: 8),
        const Text('Choose a strong password for your account.',
            style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 24),

        // Password field
        TextField(
          controller: _passwordCtrl,
          obscureText: _obscurePass,
          onChanged: (_) => setState(() {}),
          decoration: _field('Password *', icon: Icons.lock_outline).copyWith(
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
              icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility,
                  color: Colors.black38),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Strength bar
        if (password.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: strength / 4,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  strengthLabel,
                  key: ValueKey(strengthLabel),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: strengthColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Requirements checklist
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Password requirements:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: Colors.black54)),
                const SizedBox(height: 8),
                ...requirements.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        (r['met'] as bool) ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        key: ValueKey(r['met']),
                        size: 16,
                        color: (r['met'] as bool) ? const Color(0xFF00897B) : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(r['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: (r['met'] as bool) ? Colors.black87 : Colors.black38,
                          fontWeight: (r['met'] as bool) ? FontWeight.w500 : FontWeight.normal,
                        )),
                  ]),
                )),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Confirm password
        TextField(
          controller: _confirmPassCtrl,
          obscureText: _obscureConfirm,
          onChanged: (_) => setState(() {}),
          decoration: _field('Confirm Password *', icon: Icons.lock_outline).copyWith(
            suffixIcon: IconButton(
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  color: Colors.black38),
            ),
            suffixIconConstraints: const BoxConstraints(),
          ),
        ),

        // Match indicator
        if (_confirmPassCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(children: [
            Icon(
              _passwordCtrl.text == _confirmPassCtrl.text
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              size: 15,
              color: _passwordCtrl.text == _confirmPassCtrl.text
                  ? const Color(0xFF00897B)
                  : Colors.red,
            ),
            const SizedBox(width: 6),
            Text(
              _passwordCtrl.text == _confirmPassCtrl.text
                  ? 'Passwords match'
                  : 'Passwords do not match',
              style: TextStyle(
                fontSize: 12,
                color: _passwordCtrl.text == _confirmPassCtrl.text
                    ? const Color(0xFF00897B)
                    : Colors.red,
              ),
            ),
          ]),
        ],
      ],
    );
  }

  // ── Step 4: Phone + OTP (both manual and Google) ─────────────────────────────
  Widget _buildStep4() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Phone Verification', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _dark)),
      const SizedBox(height: 8),
      const Text("We'll send a one-time code to verify your number.", style: TextStyle(color: Colors.black54)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(10), margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.amber.shade300)),
        child: const Row(children: [
          Icon(Icons.info_outline, color: Colors.amber, size: 15),
          SizedBox(width: 8),
          Expanded(child: Text('Phone verification is required for all users regardless of signup method.', style: TextStyle(fontSize: 12, color: Colors.black54))),
        ]),
      ),
      const SizedBox(height: 8),

      if (_phoneVerified)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade300)),
          child: Row(children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 10),
            Text('${_data.countryCode} ${_phoneCtrl.text}  ✓ Verified', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
          ]),
        )
      else ...[
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(12)),
            child: DropdownButton<String>(
              value: _data.countryCode, underline: const SizedBox(), isDense: true,
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
          Expanded(child: TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: _field('Phone Number *', icon: Icons.phone_outlined))),
        ]),
        const SizedBox(height: 12),

        if (!_phoneOtpSent)
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: _phoneSending ? null : _sendPhoneOtp,
              style: ElevatedButton.styleFrom(backgroundColor: _teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _phoneSending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: _white, strokeWidth: 2))
                  : const Text('Send Verification Code', style: TextStyle(color: _white)),
            ),
          )
        else ...[
          const SizedBox(height: 16),
          Text('Enter the 6-digit code sent to ${_data.countryCode}${_phoneCtrl.text}',
              style: const TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) => _SmallOtpBox(
              controller: _otpControllers[i], focusNode: _otpFocusNodes[i],
              onChanged:  (v) => _onOtpDigitChanged(i, v),
              onKey:      (e) => _onOtpKeyPress(i, e),
              isFilled:   _otpControllers[i].text.isNotEmpty,
            )),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: _phoneSending || _phoneOtpCode.length < 6 ? null : _verifyPhoneOtp,
              style: ElevatedButton.styleFrom(backgroundColor: _teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _phoneSending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: _white, strokeWidth: 2))
                  : const Text('Verify Code', style: TextStyle(color: _white)),
            ),
          ),
          TextButton(onPressed: _phoneSending ? null : _sendPhoneOtp, child: const Text('Resend code', style: TextStyle(color: _teal))),
        ],

        if (_phoneOtpError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_phoneOtpError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
      ],
    ],
  );

  // ── Step 5: KYC ──────────────────────────────────────────────────────────────
  Widget _buildStep5() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Identity Verification', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _dark)),
      const SizedBox(height: 8),
      const Text('Upload your documents and provide your personal details.', style: TextStyle(color: Colors.black54)),
      const SizedBox(height: 20),

      // Date of Birth
      const Text('Date of Birth *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _dark)),
      const SizedBox(height: 6),
      GestureDetector(
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: _dateOfBirth ?? DateTime(now.year - 18, now.month, now.day),
            firstDate: DateTime(1900),
            lastDate: DateTime(now.year - 13, now.month, now.day),
          );
          if (picked != null) setState(() => _dateOfBirth = picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black26),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.black45),
            const SizedBox(width: 10),
            Text(
              _dateOfBirth != null
                  ? '${_dateOfBirth!.month.toString().padLeft(2,'0')}/${_dateOfBirth!.day.toString().padLeft(2,'0')}/${_dateOfBirth!.year}'
                  : 'Select date of birth',
              style: TextStyle(color: _dateOfBirth != null ? _dark : Colors.black38, fontSize: 14),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 16),

      // Province dropdown
      DropdownButtonFormField<String>(
        value: _selectedProvince,
        decoration: InputDecoration(
          labelText: 'Province / Region *',
          prefixIcon: const Icon(Icons.map_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        isExpanded: true,
        items: phProvinces.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
        onChanged: (val) => setState(() {
          _selectedProvince = val;
          _selectedCity = null; // reset city when province changes
        }),
      ),
      const SizedBox(height: 16),

      // City dropdown (filtered by selected province)
      DropdownButtonFormField<String>(
        value: _selectedCity,
        decoration: InputDecoration(
          labelText: 'City / Municipality *',
          prefixIcon: const Icon(Icons.location_city_outlined),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        isExpanded: true,
        disabledHint: const Text('Select a province first', style: TextStyle(color: Colors.black38)),
        items: _selectedProvince == null
            ? null
            : citiesFor(_selectedProvince!).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: _selectedProvince == null ? null : (val) => setState(() => _selectedCity = val),
      ),
      const SizedBox(height: 24),

      // Documents
      Container(
        padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
        child: const Row(children: [
          Icon(Icons.info_outline, color: Colors.red, size: 16),
          SizedBox(width: 8),
          Expanded(child: Text('Both documents are required. You cannot proceed without uploading them.', style: TextStyle(fontSize: 12, color: Colors.black54))),
        ]),
      ),
      _UploadBox(label: 'Government-Issued ID', hint: "Passport, Driver's License, SSS, PhilSys, etc.", icon: Icons.credit_card, fileName: _govIdFileName,  onPick: () => _pickFile(true)),
      const SizedBox(height: 16),
      _UploadBox(label: 'Selfie Holding Your ID', hint: 'Hold your ID clearly next to your face',       icon: Icons.camera_front_rounded,  fileName: _selfieFileName, onPick: () => _pickFile(false)),
    ],
  );

  // ── Step 6: Consent ───────────────────────────────────────────────────────────
  Widget _buildStep6() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Terms & Consent', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _dark)),
      const SizedBox(height: 8),
      const Text('Please review and accept the following.', style: TextStyle(color: Colors.black54)),
      const SizedBox(height: 24),
      _ConsentTile(title: 'Privacy Policy', subtitle: 'I have read and agree to the HIRAYA Privacy Policy and Terms of Service.', value: _data.privacyAccepted, onChanged: (v) => setState(() => _data.privacyAccepted = v ?? false)),
      const SizedBox(height: 12),
      _ConsentTile(title: 'Data Processing Consent', subtitle: 'I consent to HIRAYA collecting and processing my personal data including KYC documents under RA 10173.', value: _data.dataConsentAccepted, onChanged: (v) => setState(() => _data.dataConsentAccepted = v ?? false)),
    ],
  );

  // ── Step 7: Review ────────────────────────────────────────────────────────────
  Widget _buildStep7() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Review Application', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _dark)),
      const SizedBox(height: 8),
      const Text('Please confirm your information before submitting.', style: TextStyle(color: Colors.black54)),
      const SizedBox(height: 24),
      _ReviewSection('Account', [
        _ReviewRow('Role',  _data.role.toUpperCase()),
        _ReviewRow('Email', _data.email),
        if (_data.isGoogleSignup) _ReviewRow('Login Method', 'Google'),
      ]),
      const SizedBox(height: 16),
      _ReviewSection('Personal Info', [
        _ReviewRow('Name',          '${_data.firstName} ${_data.middleName.isNotEmpty ? '${_data.middleName} ' : ''}${_data.lastName}${_data.suffix.isNotEmpty ? ', ${_data.suffix}' : ''}'.trim()),
        _ReviewRow('Username',      '@${_data.username}'),
        _ReviewRow('Phone',         '${_data.countryCode}${_data.phone} ✓'),
        _ReviewRow('Date of Birth', _data.dateOfBirth),
        _ReviewRow('Address',       '${_data.city}, ${_data.province}'),
      ]),
      const SizedBox(height: 16),
      _ReviewSection('KYC Documents', [
        _ReviewRow('Government ID',  _govIdFileName  ?? '—'),
        if (_govIdBase64 != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              base64Decode(_govIdBase64!),
              height: 160,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
        ],
        _ReviewRow('Selfie with ID', _selfieFileName ?? '—'),
        if (_selfieBase64 != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              base64Decode(_selfieBase64!),
              height: 160,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ]),
      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _teal.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: _teal.withOpacity(0.3))),
        child: const Row(children: [
          Icon(Icons.hourglass_top, color: _teal, size: 20),
          SizedBox(width: 10),
          Expanded(child: Text('After submission, an admin will review your KYC documents. You will receive an email at your Gmail once approved.', style: TextStyle(fontSize: 13, color: _dark))),
        ]),
      ),
    ],
  );
}

// ── Small OTP Box ─────────────────────────────────────────────────────────────
class _SmallOtpBox extends StatelessWidget {
  final TextEditingController     controller;
  final FocusNode                 focusNode;
  final ValueChanged<String>      onChanged;
  final ValueChanged<RawKeyEvent> onKey;
  final bool                      isFilled;

  const _SmallOtpBox({required this.controller, required this.focusNode, required this.onChanged, required this.onKey, required this.isFilled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42, height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isFilled ? const Color(0xFF00897B) : Colors.grey.shade300, width: isFilled ? 2 : 1),
      ),
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: onKey,
        child: TextField(
          controller: controller, focusNode: focusNode, onChanged: onChanged,
          textAlign: TextAlign.center, maxLength: 1, keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0A2540)),
          decoration: const InputDecoration(counterText: '', border: InputBorder.none),
        ),
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final String title, description; final IconData icon; final bool selected; final VoidCallback onTap;
  const _RoleCard({required this.title, required this.description, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF00897B).withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? const Color(0xFF00897B) : Colors.grey.shade300, width: selected ? 2 : 1),
      ),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: selected ? const Color(0xFF00897B) : Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(icon, color: selected ? Colors.white : Colors.grey, size: 22)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? const Color(0xFF00897B) : const Color(0xFF0A2540))),
          Text(description, style: const TextStyle(color: Colors.black45, fontSize: 12)),
        ])),
        if (selected) const Icon(Icons.check_circle, color: Color(0xFF00897B)),
      ]),
    ),
  );
}

class _UploadBox extends StatelessWidget {
  final String label, hint; final IconData icon; final String? fileName; final VoidCallback onPick;
  const _UploadBox({required this.label, required this.hint, required this.icon, this.fileName, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final uploaded = fileName != null;
    return GestureDetector(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: uploaded ? const Color(0xFF00897B).withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: uploaded ? const Color(0xFF00897B) : Colors.grey.shade300, width: uploaded ? 2 : 1),
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: uploaded ? const Color(0xFF00897B) : Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(uploaded ? Icons.check : icon, color: uploaded ? Colors.white : Colors.grey, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A2540))),
            Text(uploaded ? fileName! : hint,
                style: TextStyle(color: uploaded ? const Color(0xFF00897B) : Colors.black45, fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ])),
          Text(uploaded ? 'Replace' : 'Upload', style: const TextStyle(color: Color(0xFF00897B), fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _ConsentTile extends StatelessWidget {
  final String title, subtitle; final bool value; final ValueChanged<bool?> onChanged;
  const _ConsentTile({required this.title, required this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: value ? const Color(0xFF00897B) : Colors.grey.shade300, width: value ? 1.5 : 1),
    ),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Checkbox(value: value, onChanged: onChanged, activeColor: const Color(0xFF00897B)),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A2540))),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
      ])),
    ]),
  );
}

Widget _ReviewSection(String title, List<Widget> rows) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0A2540), fontSize: 15)),
    const SizedBox(height: 8),
    Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: Column(children: rows),
    ),
  ],
);

Widget _ReviewRow(String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 6),
  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.black45, fontSize: 13))),
    Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF0A2540), fontSize: 13))),
  ]),
);