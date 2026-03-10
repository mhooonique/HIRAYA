import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/step_indicator.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/password_strength_meter.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  int _currentStep = 1;
  final int _totalSteps = 7;
  final SignupData _data = SignupData();
  final _formKey = GlobalKey<FormState>();

  // Controllers
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
        _data.middleName = _noMiddleName ? '' : _middleNameCtrl.text.trim();
        _data.suffix = _selectedSuffix == 'None' ? '' : _selectedSuffix;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.teal, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Registration Submitted!',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.navy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your account is pending admin approval. You will receive an email once approved.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Go to Login',
                  style: TextStyle(
                      fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Row(
        children: [
          // Left panel — desktop only
          if (MediaQuery.of(context).size.width > 900)
            Expanded(
              flex: 2,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.navy, AppColors.teal],
                  ),
                ),
                child: Stack(
                  children: [
                    // Grid texture
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.05,
                        child: CustomPaint(painter: _GridPainter()),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/logo/final-logo.png',
                            height: 80,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'HIRAYA',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 8,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Where Innovation\nMeets Opportunity',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 48),
                          _buildSideFeature(
                              Icons.verified_user_rounded, 'KYC Verified Platform'),
                          const SizedBox(height: 16),
                          _buildSideFeature(
                              Icons.shield_rounded, 'RA 10173 Compliant'),
                          const SizedBox(height: 16),
                          _buildSideFeature(
                              Icons.lock_rounded, 'Secure & Encrypted'),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms),
            ),

          // Right panel — form
          Expanded(
            flex: 3,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back to login
                        TextButton.icon(
                          onPressed: () => context.go('/login'),
                          icon: const Icon(Icons.arrow_back, size: 16,
                              color: AppColors.navy),
                          label: const Text('Back to Login',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: AppColors.navy,
                                  fontSize: 13)),
                        ),

                        const SizedBox(height: 16),

                        // Step indicator
                        StepIndicator(
                          currentStep: _currentStep,
                          totalSteps: _totalSteps,
                        ),

                        const SizedBox(height: 32),

                        // Step content
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          transitionBuilder: (child, anim) => SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.1, 0),
                              end: Offset.zero,
                            ).animate(anim),
                            child: FadeTransition(opacity: anim, child: child),
                          ),
                          child: KeyedSubtree(
                            key: ValueKey(_currentStep),
                            child: _buildStep(),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Error
                        if (authState.error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.crimson.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.crimson.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.crimson, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    authState.error!,
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

                        // Navigation buttons
                        Row(
                          children: [
                            if (_currentStep > 1)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _back,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: AppColors.lightGray),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Back',
                                      style: TextStyle(
                                          fontFamily: 'Poppins',
                                          color: AppColors.navy,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ),
                            if (_currentStep > 1) const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: authState.isLoading ? null : _next,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.teal,
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
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _currentStep == _totalSteps
                                            ? 'Submit Registration'
                                            : 'Continue',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ],
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

  Widget _buildSideFeature(IconData icon, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'Poppins',
              fontSize: 14,
            )),
      ],
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
          onNoMiddleNameChanged: (v) => setState(() => _noMiddleName = v),
          onSuffixChanged: (v) => setState(() => _selectedSuffix = v ?? 'None'),
        );
      case 3:
        return _Step3Security(
          passwordCtrl: _passwordCtrl,
          confirmCtrl: _confirmPasswordCtrl,
          passwordValue: _passwordValue,
          passwordMatch: _passwordMatch,
          onPasswordChanged: (v) => setState(() => _passwordValue = v),
          onConfirmChanged: (v) => setState(
              () => _passwordMatch = v == _passwordCtrl.text && v.isNotEmpty),
        );
      case 4:
        return _Step4Contact(
          phoneCtrl: _phoneCtrl,
          countryCode: _data.countryCode,
          onCountryCodeChanged: (v) => setState(() => _data.countryCode = v),
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

// ─── STEP 1: Role Selection ───────────────────────────────────────────────────
class _Step1Role extends StatelessWidget {
  final String selectedRole;
  final void Function(String) onSelect;

  const _Step1Role({required this.selectedRole, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Create Your Account',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.navy)),
        const SizedBox(height: 8),
        const Text('Choose how you want to use HIRAYA',
            style: TextStyle(
                fontFamily: 'Poppins', fontSize: 14, color: Colors.black45)),
        const SizedBox(height: 32),
        _RoleCard(
          title: 'Innovator',
          subtitle: 'I have an innovation or product to showcase',
          icon: Icons.lightbulb_rounded,
          color: AppColors.teal,
          selected: selectedRole == 'innovator',
          onTap: () => onSelect('innovator'),
        ),
        const SizedBox(height: 16),
        _RoleCard(
          title: 'Client / Investor',
          subtitle: 'I am looking to discover and invest in innovations',
          icon: Icons.business_center_rounded,
          color: AppColors.navy,
          selected: selectedRole == 'client',
          onTap: () => onSelect('client'),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : AppColors.lightGray,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 12)]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? color : AppColors.lightGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: selected ? Colors.white : Colors.black38, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: selected ? color : AppColors.darkGray)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Colors.black45)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: color, size: 24),
          ],
        ),
      ),
    );
  }
}

// ─── STEP 2: Basic Info ───────────────────────────────────────────────────────
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
                color: AppColors.navy)),
        const SizedBox(height: 6),
        const Text(
            'Enter your name exactly as it appears on your government-issued ID.',
            style: TextStyle(
                fontFamily: 'Poppins', fontSize: 13, color: Colors.black45)),
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
                  if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(v)) {
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
        ),
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
                DropdownButton<String>(
                  value: selectedSuffix,
                  items: ['None', 'Jr.', 'Sr.', 'II', 'III', 'IV']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: onSuffixChanged,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: AppColors.darkGray),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: noMiddleName,
              onChanged: (v) => onNoMiddleNameChanged(v ?? false),
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
            if (v == null || v.trim().length < 4) return 'Minimum 4 characters';
            if (!RegExp(r'^[a-z0-9_]+$').hasMatch(v)) {
              return 'Lowercase letters, numbers, underscore only';
            }
            return null;
          },
          prefix: const Icon(Icons.alternate_email, size: 18,
              color: Colors.black38),
        ),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Email Address *',
          controller: emailCtrl,
          hint: 'juan@example.com',
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
              return 'Enter a valid email address';
            }
            return null;
          },
          prefix: const Icon(Icons.email_outlined, size: 18,
              color: Colors.black38),
        ),
      ],
    );
  }
}

// ─── STEP 3: Security ─────────────────────────────────────────────────────────
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
                color: AppColors.navy)),
        const SizedBox(height: 6),
        const Text('Use a strong password to keep your account secure.',
            style: TextStyle(
                fontFamily: 'Poppins', fontSize: 13, color: Colors.black45)),
        const SizedBox(height: 24),
        AuthTextField(
          label: 'Password *',
          controller: passwordCtrl,
          isPassword: true,
          onChanged: onPasswordChanged,
          validator: (v) {
            if (v == null || v.length < 8) return 'Minimum 8 characters';
            return null;
          },
        ),
        PasswordStrengthMeter(password: passwordValue),
        const SizedBox(height: 16),
        AuthTextField(
          label: 'Confirm Password *',
          controller: confirmCtrl,
          isPassword: true,
          onChanged: onConfirmChanged,
          validator: (v) {
            if (v != passwordCtrl.text) return 'Passwords do not match';
            return null;
          },
          suffix: passwordValue.isNotEmpty
              ? Icon(
                  passwordMatch
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color:
                      passwordMatch ? AppColors.teal : AppColors.crimson,
                  size: 20,
                )
              : null,
        ),
      ],
    );
  }
}

// ─── STEP 4: Contact ──────────────────────────────────────────────────────────
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
                color: AppColors.navy)),
        const SizedBox(height: 6),
        const Text('Your phone number will be used for account verification.',
            style: TextStyle(
                fontFamily: 'Poppins', fontSize: 13, color: Colors.black45)),
        const SizedBox(height: 24),
        const Text('Phone Number *',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.navy)),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.lightGray),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: countryCode,
                underline: const SizedBox(),
                items: ['+63', '+1', '+44', '+61', '+81']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => onCountryCodeChanged(v ?? '+63'),
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
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.sky.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.sky.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.sky, size: 18),
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
        ),
      ],
    );
  }
}

// ─── STEP 5: Identity ─────────────────────────────────────────────────────────
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
                color: AppColors.navy)),
        const SizedBox(height: 6),
        const Text('Upload a valid government-issued ID for KYC verification.',
            style: TextStyle(
                fontFamily: 'Poppins', fontSize: 13, color: Colors.black45)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.golden.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.golden.withOpacity(0.4)),
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
        ),
        const SizedBox(height: 24),
        const _UploadBox(
          label: 'Government-Issued ID',
          sublabel: 'PhilSys, Passport, Driver\'s License, SSS/GSIS, PRC, Voter\'s ID',
          icon: Icons.badge_rounded,
        ),
        const SizedBox(height: 16),
        const _UploadBox(
          label: 'Selfie Holding ID',
          sublabel: 'Clear photo of you holding your ID',
          icon: Icons.face_rounded,
        ),
      ],
    );
  }
}

class _UploadBox extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;

  const _UploadBox({
    required this.label,
    required this.sublabel,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.lightGray, style: BorderStyle.solid, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppColors.lightGray),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.navy)),
            const SizedBox(height: 4),
            Text(sublabel,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: Colors.black38),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.upload_rounded, size: 16),
              label: const Text('Upload File',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.teal,
                side: const BorderSide(color: AppColors.teal),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── STEP 6: Consent ──────────────────────────────────────────────────────────
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
                color: AppColors.navy)),
        const SizedBox(height: 6),
        const Text(
            'Please read and accept the following before creating your account.',
            style: TextStyle(
                fontFamily: 'Poppins', fontSize: 13, color: Colors.black45)),
        const SizedBox(height: 24),
        _ConsentCard(
          title: 'Privacy Policy & Terms of Service',
          description:
              'I have read and agree to HIRAYA\'s Privacy Policy and Terms of Service. I understand how my data will be used and stored.',
          accepted: privacyAccepted,
          onChanged: onPrivacyChanged,
          icon: Icons.policy_rounded,
          color: AppColors.navy,
        ),
        const SizedBox(height: 16),
        _ConsentCard(
          title: 'Data Processing Consent',
          description:
              'I consent to HIRAYA collecting and processing my personal data, including identity documents, for KYC verification purposes under RA 10173 (Data Privacy Act of 2012).',
          accepted: dataConsentAccepted,
          onChanged: onDataConsentChanged,
          icon: Icons.shield_rounded,
          color: AppColors.teal,
        ),
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
        ),
      ],
    );
  }
}

class _ConsentCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accepted ? color.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accepted ? color : AppColors.lightGray,
          width: accepted ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: accepted,
            onChanged: onChanged,
            activeColor: color,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(title,
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: color)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(description,
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

// ─── STEP 7: Review ───────────────────────────────────────────────────────────
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
                color: AppColors.navy)),
        const SizedBox(height: 6),
        const Text(
            'Please confirm everything is correct before submitting.',
            style: TextStyle(
                fontFamily: 'Poppins', fontSize: 13, color: Colors.black45)),
        const SizedBox(height: 24),
        _ReviewSection(title: 'Account Type', items: {
          'Role': data.role.isEmpty ? '—' : data.role.toUpperCase(),
        }),
        _ReviewSection(title: 'Basic Information', items: {
          'Name':
              '${data.firstName} ${data.middleName.isEmpty ? '' : '${data.middleName} '}${data.lastName}${data.suffix.isEmpty ? '' : ', ${data.suffix}'}',
          'Username': data.username.isEmpty ? '—' : '@${data.username}',
          'Email': data.email.isEmpty ? '—' : data.email,
        }),
        _ReviewSection(title: 'Contact', items: {
          'Phone':
              '${data.countryCode} ${data.phone.isEmpty ? '—' : data.phone}',
        }),
        _ReviewSection(title: 'Consent', items: {
          'Privacy Policy': data.privacyAccepted ? '✓ Accepted' : '✗ Not accepted',
          'Data Consent':
              data.dataConsentAccepted ? '✓ Accepted' : '✗ Not accepted',
        }),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.teal.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.teal.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.teal, size: 16),
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
        ),
      ],
    );
  }
}

class _ReviewSection extends StatelessWidget {
  final String title;
  final Map<String, String> items;

  const _ReviewSection({required this.title, required this.items});

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

// Grid painter helper
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