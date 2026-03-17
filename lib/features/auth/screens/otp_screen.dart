// lib/features/auth/screens/otp_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/otp_provider.dart';
import '../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final int     userId;
  final String  token;
  final String  otpType;
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

class _OtpScreenState extends ConsumerState<OtpScreen> {
  // 6 individual controllers + focus nodes
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes   = List.generate(6, (_) => FocusNode());

  int    _resendSeconds = 60;
  Timer? _timer;
  bool   _otpInitiated  = false;  // ← ADD THIS
  bool   _canResend     = false;
  bool   _shaking       = false;

  String get _code =>
      _controllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initOtp();
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes)   f.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() { _resendSeconds = 60; _canResend = false; });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_resendSeconds == 0) {
        t.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _initOtp() async {
    if (_otpInitiated) return;  // ← ADD THIS
    _otpInitiated = true;
    final type = widget.otpType == 'sms' ? OtpType.sms : OtpType.email;
    await ref.read(otpProvider.notifier).initiate(
      userId:      widget.userId,
      token:       widget.token,
      otpType:     type,
      phoneNumber: widget.phone,
    );
  }

  Future<void> _verify() async {
    if (_code.length < 6) return;
    final success = await ref.read(otpProvider.notifier).verify(_code);
    if (!mounted) return;

    if (success) {
      await ref.read(authProvider.notifier).completeLogin(
        token:  widget.token,
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
      // Handle paste — distribute across boxes
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

  void _onKeyPress(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
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
    final otp       = ref.watch(otpProvider);
    final isSms     = widget.otpType == 'sms';
    final contact   = widget.maskedContact ?? (isSms ? 'your phone' : 'your Gmail');
    final typeLabel = isSms ? 'SMS' : 'Email';
    final icon      = isSms ? Icons.sms_outlined : Icons.email_outlined;

    return Scaffold(
      backgroundColor: const Color(0xFF0A2540),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    context.go('/login');
                  },
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 24),

              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF00897B).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF00897B), size: 36),
              ),
              const SizedBox(height: 24),

              const Text(
                'Verification Required',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a 6-digit code via $typeLabel to\n$contact',
                style: const TextStyle(color: Colors.white60, fontSize: 14, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Error banner
              if (otp.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(otp.error!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
                  ]),
                ),

              // ── 6-box OTP input ──────────────────────────────────────────
              AnimatedSlide(
                offset: _shaking ? const Offset(0.03, 0) : Offset.zero,
                duration: const Duration(milliseconds: 80),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) => _OtpBox(
                    controller:  _controllers[i],
                    focusNode:   _focusNodes[i],
                    onChanged:   (v) => _onDigitChanged(i, v),
                    onKey:       (e) => _onKeyPress(i, e),
                    isFilled:    _controllers[i].text.isNotEmpty,
                  )),
                ),
              ),
              const SizedBox(height: 32),

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: otp.isLoading || _code.length < 6 ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:         const Color(0xFF00897B),
                    disabledBackgroundColor: Colors.white12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: otp.isLoading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Verify',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 24),

              // Resend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Didn't receive it? ",
                      style: TextStyle(color: Colors.white54, fontSize: 13)),
                  GestureDetector(
                    onTap: _canResend ? _resend : null,
                    child: Text(
                      _canResend ? 'Resend code' : 'Resend in ${_resendSeconds}s',
                      style: TextStyle(
                        color:      _canResend ? const Color(0xFF00897B) : Colors.white38,
                        fontSize:   13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'This device will be remembered after verification.',
                style: TextStyle(color: Colors.white24, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Single OTP box ─────────────────────────────────────────────────────────────
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode             focusNode;
  final ValueChanged<String>  onChanged;
  final ValueChanged<RawKeyEvent> onKey;
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
    return Container(
      width: 46, height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2E4E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFilled ? const Color(0xFF00897B) : Colors.white24,
          width: isFilled ? 2 : 1,
        ),
      ),
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey:     onKey,
        child: TextField(
          controller:    controller,
          focusNode:     focusNode,
          onChanged:     onChanged,
          textAlign:     TextAlign.center,
          maxLength:     1,
          keyboardType:  TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            color:      Colors.white,
            fontSize:   22,
            fontWeight: FontWeight.bold,
          ),
          decoration: const InputDecoration(
            counterText: '',
            border:      InputBorder.none,
          ),
        ),
      ),
    );
  }
}