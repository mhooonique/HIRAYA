import 'dart:convert';
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

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool  _obscurePass = true;
  bool  _obscureConf = true;
  bool  _loading     = false;
  bool  _done        = false;
  String? _error;

  @override
  void dispose() {
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
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService().post('auth/reset-password', {
        'token':    widget.token,
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
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: _done ? _buildSuccess() : _buildForm(),
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
          TextButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.arrow_back, size: 16, color: AppColors.navy),
            label: const Text('Back to Login',
                style: TextStyle(fontFamily: 'Poppins', color: AppColors.navy, fontSize: 13)),
          ),
          const SizedBox(height: 24),
          const Icon(Icons.lock_reset_rounded, size: 56, color: AppColors.teal),
          const SizedBox(height: 16),
          const Text('Set New Password',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 28,
                  fontWeight: FontWeight.w800, color: AppColors.navy))
              .animate().fadeIn(duration: 500.ms),
          const SizedBox(height: 8),
          const Text('Choose a strong password for your account.',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black45)),
          const SizedBox(height: 32),

          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!, style: const TextStyle(
                    fontFamily: 'Poppins', fontSize: 13, color: Colors.red))),
              ]),
            ),
          ],

          TextFormField(
            controller: _passCtrl,
            obscureText: _obscurePass,
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: const Icon(Icons.lock_outline, size: 18, color: Colors.black38),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility,
                    color: Colors.black38, size: 18),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.teal, width: 1.5)),
            ),
            validator: (v) {
              if (v == null || v.length < 8) return 'At least 8 characters required';
              if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Include at least one uppercase letter';
              if (!RegExp(r'[0-9]').hasMatch(v)) return 'Include at least one number';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _confirmCtrl,
            obscureText: _obscureConf,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline, size: 18, color: Colors.black38),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureConf = !_obscureConf),
                icon: Icon(_obscureConf ? Icons.visibility_off : Icons.visibility,
                    color: Colors.black38, size: 18),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.teal, width: 1.5)),
            ),
            validator: (v) {
              if (v != _passCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.teal.withOpacity(0.2)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Password requirements:', style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 12,
                    fontWeight: FontWeight.w600, color: AppColors.teal)),
                SizedBox(height: 6),
                _ReqRow(text: 'At least 8 characters'),
                _ReqRow(text: 'One uppercase letter (A-Z)'),
                _ReqRow(text: 'One number (0-9)'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Reset Password', style: TextStyle(
                      fontFamily: 'Poppins', fontWeight: FontWeight.w700,
                      fontSize: 15, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_rounded, size: 80, color: AppColors.teal)
            .animate().scale(duration: 500.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        const Text('Password Reset!', style: TextStyle(
            fontFamily: 'Poppins', fontSize: 26,
            fontWeight: FontWeight.w800, color: AppColors.navy),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        const Text('Your password has been updated successfully.\nYou can now log in with your new password.',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 14,
                color: Colors.black54, height: 1.6),
            textAlign: TextAlign.center),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Go to Login', style: TextStyle(
                fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ],
    );
  }
}

class _ReqRow extends StatelessWidget {
  final String text;
  const _ReqRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(children: [
        const Icon(Icons.check_circle_outline, size: 13, color: AppColors.teal),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(
            fontFamily: 'Poppins', fontSize: 12, color: Colors.black54)),
      ]),
    );
  }
}