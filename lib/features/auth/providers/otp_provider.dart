// lib/features/auth/providers/otp_provider.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/api_service.dart';

// ── Device ID via SharedPreferences ──────────────────────────────────────────
// Generates a random ID on first run and persists it — works on all platforms
Future<String> getDeviceId() async {
  try {
    final prefs  = await SharedPreferences.getInstance();
    const key    = 'hiraya_device_id';
    final stored = prefs.getString(key);
    if (stored != null && stored.isNotEmpty) return stored;
    final newId  = 'device-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999999)}';
    await prefs.setString(key, newId);
    return newId;
  } catch (_) {
    return 'device-${DateTime.now().millisecondsSinceEpoch}';
  }
}

// ── OTP State ─────────────────────────────────────────────────────────────────
class OtpState {
  final bool    isLoading;
  final bool    isVerified;
  final String? error;
  final String? verificationId;
  final int?    resendToken;
  final OtpType otpType;
  final int     userId;
  final String  token;

  const OtpState({
    this.isLoading      = false,
    this.isVerified     = false,
    this.error,
    this.verificationId,
    this.resendToken,
    this.otpType        = OtpType.email,
    this.userId         = 0,
    this.token          = '',
  });

  OtpState copyWith({
    bool?    isLoading,
    bool?    isVerified,
    String?  error,
    String?  verificationId,
    int?     resendToken,
    OtpType? otpType,
    int?     userId,
    String?  token,
  }) => OtpState(
    isLoading:      isLoading      ?? this.isLoading,
    isVerified:     isVerified     ?? this.isVerified,
    error:          error,
    verificationId: verificationId ?? this.verificationId,
    resendToken:    resendToken    ?? this.resendToken,
    otpType:        otpType        ?? this.otpType,
    userId:         userId         ?? this.userId,
    token:          token          ?? this.token,
  );
}

enum OtpType { sms, email }

// ── Provider ──────────────────────────────────────────────────────────────────
final otpProvider = StateNotifierProvider<OtpNotifier, OtpState>(
  (ref) => OtpNotifier(ref.read(apiServiceProvider)),
);

class OtpNotifier extends StateNotifier<OtpState> {
  final ApiService _api;

  OtpNotifier(this._api) : super(const OtpState());

  /// Called right after login returns requires_2fa: true
  Future<void> initiate({
    required int     userId,
    required String  token,
    required OtpType otpType,
    String?          phoneNumber,
  }) async {
    state = state.copyWith(
      isLoading: true,
      userId:    userId,
      token:     token,
      otpType:   otpType,
      error:     null,
    );

    try {
      // Firebase SMS doesn't work on Flutter Web — always use email OTP
      await _sendEmailOtp(userId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to send OTP. Please try again.');
    }
  }

  /// Verify the code the user entered
  Future<bool> verify(String code) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final deviceId = await getDeviceId();

      final res = await _api.post('otp/verify', {
        'user_id':   state.userId,
        'code':      code,
        'device_id': deviceId,
      }, auth: false);
      if (res['success'] != true) {
        state = state.copyWith(
          isLoading: false,
          error:     res['error'] ?? 'Invalid or expired code',
        );
        return false;
      }

      state = state.copyWith(isLoading: false, isVerified: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error:     'Verification failed. Please try again.',
      );
      return false;
    }
  }

  Future<void> resend(String? phoneNumber) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Firebase SMS doesn't work on Flutter Web — always use email OTP
      await _sendEmailOtp(state.userId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to resend OTP. Please try again.');
    }
  }

  void reset() => state = const OtpState();

  // ── Private ──────────────────────────────────────────────────────────────
  Future<void> _sendSmsOtp(String phoneNumber) async {
    final completer = Completer<void>();

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber:      phoneNumber,
      timeout:          const Duration(seconds: 60),
      forceResendingToken: state.resendToken,
      verificationCompleted: (credential) async {
        // Auto-verified on Android
        await FirebaseAuth.instance.signInWithCredential(credential);
        final deviceId = await getDeviceId();
        await _api.post('otp/verify', {
          'user_id':      state.userId,
          'code':         '000000',
          'device_id':    deviceId,
          'sms_verified': true,
        }, auth: false);
        state = state.copyWith(isVerified: true);
        if (!completer.isCompleted) completer.complete();
      },
      verificationFailed: (e) {
        if (!completer.isCompleted) {
          completer.completeError(e.message ?? 'SMS verification failed');
        }
      },
      codeSent: (verificationId, resendToken) {
        state = state.copyWith(
          verificationId: verificationId,
          resendToken:    resendToken,
        );
        if (!completer.isCompleted) completer.complete();
      },
      codeAutoRetrievalTimeout: (_) {},
    );

    return completer.future;
  }

  Future<void> _sendEmailOtp(int userId) async {
    final res = await _api.post('otp/send', {
      'user_id': userId,
      'type':    'email',
    }, auth: false);
    if (res['success'] != true) {
      throw Exception(res['error'] ?? 'Failed to send OTP email');
    }
  }
}