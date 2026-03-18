// lib/features/auth/screens/otp_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/otp_provider.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final int userId;
  final String token;
  final String otpType;
  final String? phone;
  final String? maskedContact;

  const OtpScreen({
    super.key,
    required this.userId,
    required this.token,
    required this.otpType,
    this.phone,
    this.maskedContact,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen>
    with SingleTickerProviderStateMixin {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendSeconds = 60;
  Timer? _timer;
  bool _otpInitiated = false;
  bool _canResend = false;
  bool _shaking = false;
  late AnimationController _orbCtrl;

  String get _code => _controllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _orbCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initOtp();
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _orbCtrl.dispose();
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendSeconds = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_resendSeconds == 0) {
        t.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _initOtp() async {
    if (_otpInitiated) return;
    _otpInitiated = true;
    final type = widget.otpType == 'sms' ? OtpType.sms : OtpType.email;
    await ref.read(otpProvider.notifier).initiate(
          userId: widget.userId,
          token: widget.token,
          otpType: type,
          phoneNumber: widget.phone,
        );
  }

  Future<void> _verify() async {
    if (_code.length < 6) return;
    final success = await ref.read(otpProvider.notifier).verify(_code);
    if (!mounted) return;

    if (success) {
      await ref.read(authProvider.notifier).completeLogin(
            token: widget.token,
            userId: widget.userId,
          );
      ref.read(otpProvider.notifier).reset();
    } else {
      _shake();
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
    }
  }

  void _shake() async {
    setState(() => _shaking = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _shaking = false);
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '').split('');
      for (int i = 0; i < 6 && i < digits.length; i++) {
        _controllers[i].text = digits[i];
      }
      final next = digits.length < 6 ? digits.length : 5;
      _focusNodes[next].requestFocus();
      setState(() {});
      if (_code.length == 6) _verify();
      return;
    }
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verify();
      }
    }
    setState(() {});
  }

  void _onKeyPress(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      setState(() {});
    }
  }

  Future<void> _resend() async {
    if (!_canResend) return;
    _startResendTimer();
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
    await ref.read(otpProvider.notifier).resend(widget.phone);
  }

  @override
  Widget build(BuildContext context) {
    final otp = ref.watch(otpProvider);
    final isSms = widget.otpType == 'sms';
    final contact =
        widget.maskedContact ?? (isSms ? 'your phone' : 'your Gmail');
    final typeLabel = isSms ? 'SMS' : 'Email';
    final icon = isSms ? Icons.sms_outlined : Icons.email_outlined;

    return Scaffold(
      backgroundColor: AppColors.deepVoid,
      body: AnimatedBuilder(
        animation: _orbCtrl,
        builder: (_, child) {
          final t = _orbCtrl.value;
          return Stack(
            children: [
              // Background gradient
              Positioned.fill(
                child: Container(
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
                ),
              ),
              // Teal orb top-right
              Positioned(
                right: -60 + t * 20,
                top: -40 + t * 30,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: 0.14),
                        blurRadius: 160,
                        spreadRadius: 20,
                      ),
                    ],
                  ),
                ),
              ),
              // Golden orb bottom-left
              Positioned(
                left: -40 + t * 15,
                bottom: 60 + t * 25,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.golden.withValues(alpha: 0.10),
                        blurRadius: 130,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
              // Content
              child!,
            ],
          );
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () {
                          ref.read(authProvider.notifier).logout();
                          context.go('/login');
                        },
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
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Icon badge
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
                      child: Icon(icon, color: AppColors.teal, size: 36),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          duration: 500.ms,
                          curve: Curves.easeOutBack,
                        )
                        .fadeIn(duration: 400.ms),

                    const SizedBox(height: 28),

                    const Text(
                      'Verification Required',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 80.ms)
                        .slideY(begin: 0.15, end: 0),

                    const SizedBox(height: 10),

                    Text(
                      'We sent a 6-digit code via $typeLabel to\n$contact',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white.withValues(alpha: 0.50),
                        fontSize: 14,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate(delay: 150.ms)
                        .fadeIn(duration: 500.ms),

                    const SizedBox(height: 40),

                    // Error banner
                    if (otp.error != null)
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
                                otp.error!,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: AppColors.crimson.withValues(alpha: 0.80),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0),

                    // OTP boxes
                    AnimatedSlide(
                      offset: _shaking ? const Offset(0.03, 0) : Offset.zero,
                      duration: const Duration(milliseconds: 80),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          6,
                          (i) => _OtpBox(
                            controller: _controllers[i],
                            focusNode: _focusNodes[i],
                            onChanged: (v) => _onDigitChanged(i, v),
                            onKey: (e) => _onKeyPress(i, e),
                            isFilled: _controllers[i].text.isNotEmpty,
                          ),
                        ),
                      ),
                    )
                        .animate(delay: 200.ms)
                        .fadeIn(duration: 500.ms),

                    const SizedBox(height: 32),

                    // Verify button
                    _VerifyButton(
                      loading: otp.isLoading,
                      enabled: _code.length == 6,
                      onTap: _verify,
                    )
                        .animate(delay: 280.ms)
                        .fadeIn(duration: 500.ms)
                        .slideY(begin: 0.15, end: 0),

                    const SizedBox(height: 24),

                    // Resend row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive it? ",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 13,
                          ),
                        ),
                        GestureDetector(
                          onTap: _canResend ? _resend : null,
                          child: Text(
                            _canResend
                                ? 'Resend code'
                                : 'Resend in ${_resendSeconds}s',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: _canResend
                                  ? AppColors.teal
                                  : Colors.white.withValues(alpha: 0.25),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    )
                        .animate(delay: 350.ms)
                        .fadeIn(duration: 500.ms),

                    const SizedBox(height: 16),

                    Text(
                      'This device will be remembered after verification.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white.withValues(alpha: 0.25),
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    )
                        .animate(delay: 400.ms)
                        .fadeIn(duration: 500.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Verify Button ───────────────────────────────────────────
class _VerifyButton extends StatefulWidget {
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;
  const _VerifyButton({
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_VerifyButton> createState() => _VerifyButtonState();
}

class _VerifyButtonState extends State<_VerifyButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && !widget.loading;
    return MouseRegion(
      cursor:
          active ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: active ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: active
                ? LinearGradient(
                    colors: [
                      AppColors.teal,
                      const Color(0xFF0E5A50),
                    ],
                  )
                : null,
            color: active ? null : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(13),
            boxShadow: active && _hovered
                ? [
                    BoxShadow(
                      color: AppColors.teal.withValues(alpha: 0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
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
                : Text(
                    'Verify Code',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.30),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Single OTP box ──────────────────────────────────────────
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKey;
  final bool isFilled;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKey,
    required this.isFilled,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 46,
      height: 58,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: isFilled
            ? AppColors.golden.withValues(alpha: 0.10)
            : const Color(0xFF0D2035),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFilled
              ? AppColors.golden.withValues(alpha: 0.60)
              : Colors.white.withValues(alpha: 0.15),
          width: isFilled ? 2.0 : 1.0,
        ),
        boxShadow: isFilled
            ? [
                BoxShadow(
                  color: AppColors.golden.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: onKey,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          textAlign: TextAlign.center,
          maxLength: 1,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            fontFamily: 'Poppins',
            color: isFilled ? AppColors.golden : Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
