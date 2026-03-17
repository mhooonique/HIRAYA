// lib/features/auth/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';
import 'otp_provider.dart';

// ── SignupData ─────────────────────────────────────────────────────────────────
class SignupData {
  String role;
  String firstName;
  String lastName;
  String middleName;
  String suffix;
  String username;
  String email;
  String password;
  String phone;
  String countryCode;
  bool   privacyAccepted;
  bool   dataConsentAccepted;
  String? govIdBase64;
  String? govIdFileName;
  String? selfieBase64;
  String? selfieFileName;
  bool   isGoogleSignup;
  String googleId;
  String dateOfBirth;
  String city;
  String province;

  SignupData({
    this.role                = 'client',
    this.firstName           = '',
    this.lastName            = '',
    this.middleName          = '',
    this.suffix              = '',
    this.username            = '',
    this.email               = '',
    this.password            = '',
    this.phone               = '',
    this.countryCode         = '+63',
    this.privacyAccepted     = false,
    this.dataConsentAccepted = false,
    this.govIdBase64,
    this.govIdFileName,
    this.selfieBase64,
    this.selfieFileName,
    this.isGoogleSignup      = false,
    this.googleId            = '',
    this.dateOfBirth         = '',
    this.city                = '',
    this.province            = '',
  });
}

// ── AuthState ─────────────────────────────────────────────────────────────────
enum LoginStatus { idle, pending, rejected }

class AuthState {
  final bool        isLoading;
  final bool        isRehydrating;
  final UserModel?  user;
  final String?     token;
  final String?     error;
  final LoginStatus loginStatus;

  // 2FA
  final bool    requires2fa;
  final int     pendingUserId;
  final String  pendingToken;
  final String  otpType;
  final String? pendingPhone;

  // Google pre-fill
  final bool   needsGoogleSignup;
  final String googlePrefillEmail;
  final String googlePrefillFirstName;
  final String googlePrefillLastName;
  final String googlePrefillGoogleId;

  const AuthState({
    this.isLoading              = false,
    this.isRehydrating          = true,
    this.user,
    this.token,
    this.error,
    this.loginStatus            = LoginStatus.idle,
    this.requires2fa            = false,
    this.pendingUserId          = 0,
    this.pendingToken           = '',
    this.otpType                = 'email',
    this.pendingPhone,
    this.needsGoogleSignup      = false,
    this.googlePrefillEmail     = '',
    this.googlePrefillFirstName = '',
    this.googlePrefillLastName  = '',
    this.googlePrefillGoogleId  = '',
  });

  bool get isLoggedIn => user != null && token != null;

  AuthState copyWith({
    bool?        isLoading,
    bool?        isRehydrating,
    UserModel?   user,
    String?      token,
    String?      error,
    LoginStatus? loginStatus,
    bool?        requires2fa,
    int?         pendingUserId,
    String?      pendingToken,
    String?      otpType,
    String?      pendingPhone,
    bool?        needsGoogleSignup,
    String?      googlePrefillEmail,
    String?      googlePrefillFirstName,
    String?      googlePrefillLastName,
    String?      googlePrefillGoogleId,
  }) => AuthState(
    isLoading:              isLoading              ?? this.isLoading,
    isRehydrating:          isRehydrating          ?? this.isRehydrating,
    user:                   user                   ?? this.user,
    token:                  token                  ?? this.token,
    error:                  error,
    loginStatus:            loginStatus            ?? this.loginStatus,
    requires2fa:            requires2fa            ?? this.requires2fa,
    pendingUserId:          pendingUserId          ?? this.pendingUserId,
    pendingToken:           pendingToken           ?? this.pendingToken,
    otpType:                otpType                ?? this.otpType,
    pendingPhone:           pendingPhone           ?? this.pendingPhone,
    needsGoogleSignup:      needsGoogleSignup      ?? this.needsGoogleSignup,
    googlePrefillEmail:     googlePrefillEmail     ?? this.googlePrefillEmail,
    googlePrefillFirstName: googlePrefillFirstName ?? this.googlePrefillFirstName,
    googlePrefillLastName:  googlePrefillLastName  ?? this.googlePrefillLastName,
    googlePrefillGoogleId:  googlePrefillGoogleId  ?? this.googlePrefillGoogleId,
  );
}

// ── Provider ──────────────────────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(apiServiceProvider)),
);

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;

  final _googleSignIn = GoogleSignIn(
    clientId: '31131385571-rhrhdr9hk5t2jsrah4gho23k8rj4ctlf.apps.googleusercontent.com',
    scopes:   ['email', 'profile', 'openid'],
  );

  AuthNotifier(this._api) : super(const AuthState()) {
    _rehydrate();
  }

  Future<void> _rehydrate() async {
    try {
      final token = await _api.getStoredToken();
      if (token == null) { state = state.copyWith(isRehydrating: false); return; }
      final res = await _api.get('users/me', auth: true);
      final userData = res['user'] as Map<String, dynamic>?;
      if (userData != null && userData['id'] != null) {
        state = state.copyWith(isRehydrating: false, user: UserModel.fromJson(userData), token: token);
        return;
      }
    } catch (_) { await _api.clearToken(); }
    state = state.copyWith(isRehydrating: false);
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null, loginStatus: LoginStatus.idle);
    try {
      final deviceId = await getDeviceId();
      final res = await _api.post('auth/login', {
        'email': email, 'password': password, 'device_id': deviceId,
      });

      if (res['error'] != null) {
        final s = res['status'] as String?;
        state = state.copyWith(
          isLoading: false, error: res['error'],
          loginStatus: s == 'pending'  ? LoginStatus.pending
                     : s == 'rejected' ? LoginStatus.rejected
                     : LoginStatus.idle,
        );
        return;
      }

      if (res['requires_2fa'] == true) {
        state = state.copyWith(
          isLoading: false, requires2fa: true,
          pendingUserId: res['user_id'] as int,
          pendingToken:  res['token']   as String,
          otpType:       res['otp_type'] as String? ?? 'email',
          pendingPhone:  res['masked_phone'] as String?,
        );
        return;
      }

      await _api.saveToken(res['token'] as String);
      state = state.copyWith(
        isLoading: false,
        user:  UserModel.fromJson(res['user'] as Map<String, dynamic>),
        token: res['token'] as String,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Connection error. Is XAMPP running?');
    }
  }

  Future<void> completeLogin({required String token, required int userId}) async {
    state = state.copyWith(isLoading: true);
    try {
      await _api.saveToken(token);
      final res = await _api.get('users/me', auth: true);
      final userData = (res['user'] as Map<String, dynamic>?) ?? res;
      state = state.copyWith(
        isLoading: false, requires2fa: false,
        user: UserModel.fromJson(userData), token: token,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Failed to load profile');
    }
  }

  Future<void> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null, loginStatus: LoginStatus.idle);
    try {
      // Force account picker every time
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final auth        = await account.authentication;
      final idToken     = auth.idToken;
      final accessToken = auth.accessToken;

      if (idToken == null && accessToken == null) {
        state = state.copyWith(isLoading: false, error: 'Could not get Google token. Try again.');
        return;
      }

      final deviceId = await getDeviceId();
      final res = await _api.post('auth/google', {
        if (idToken     != null) 'id_token':     idToken,
        if (accessToken != null) 'access_token': accessToken,
        'device_id':  deviceId,
        'email':      account.email,
        'first_name': account.displayName?.split(' ').first ?? '',
        'last_name':  account.displayName?.split(' ').skip(1).join(' ') ?? '',
      });

      if (res['needs_signup'] == true) {
        state = state.copyWith(
          isLoading:              false,
          needsGoogleSignup:      true,
          googlePrefillEmail:     res['email']      as String? ?? account.email,
          googlePrefillFirstName: res['first_name'] as String? ?? '',
          googlePrefillLastName:  res['last_name']  as String? ?? '',
          googlePrefillGoogleId:  res['google_id']  as String? ?? account.id,
        );
        return;
      }

      if (res['error'] != null) {
        final s = res['status'] as String?;
        state = state.copyWith(
          isLoading: false, error: res['error'],
          loginStatus: s == 'pending'  ? LoginStatus.pending
                     : s == 'rejected' ? LoginStatus.rejected
                     : LoginStatus.idle,
        );
        return;
      }

      if (res['requires_2fa'] == true) {
        state = state.copyWith(
          isLoading: false, requires2fa: true,
          pendingUserId: res['user_id'] as int,
          pendingToken:  res['token']   as String,
          otpType:       res['otp_type'] as String? ?? 'email',
          pendingPhone:  res['masked_phone'] as String?,
        );
        return;
      }

      await _api.saveToken(res['token'] as String);
      state = state.copyWith(
        isLoading: false,
        user:  UserModel.fromJson(res['user'] as Map<String, dynamic>),
        token: res['token'] as String,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Google Sign-In failed. Try again.');
    }
  }

  Future<void> signup(SignupData data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await _api.post('auth/signup', {
        'email':            data.email,
        'password':         data.password,
        'first_name':       data.firstName,
        'last_name':        data.lastName,
        'middle_name':      data.middleName,
        'suffix':           data.suffix,
        'username':         data.username,
        'role':             data.role,
        'phone':            data.phone,
        'country_code':     data.countryCode,
        'date_of_birth':    data.dateOfBirth,
        'city':             data.city,
        'province':         data.province,
        'gov_id':           data.govIdBase64,
        'gov_id_name':      data.govIdFileName,
        'selfie':           data.selfieBase64,
        'selfie_name':      data.selfieFileName,
        'is_google_signup': data.isGoogleSignup,
        'google_id':        data.googleId,
      });

      if (res['error'] != null) {
        state = state.copyWith(isLoading: false, error: res['error']);
        return;
      }

      // Account created but user_status = 0 — needs admin approval.
      // Do NOT save token or log them in. Just set loginStatus to pending
      // so the router sends them to the pending approval screen.
      state = state.copyWith(
        isLoading:   false,
        loginStatus: LoginStatus.pending,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Signup failed. Check your connection.');
    }
  }

  Future<void> logout() async {
    await _api.clearToken();
    await _googleSignIn.signOut();
    state = const AuthState(isRehydrating: false);
  }

  void clearGooglePrefill()  => state = state.copyWith(needsGoogleSignup: false);
  void clearError()           => state = state.copyWith(error: null);
  void clearPendingStatus()   => state = state.copyWith(loginStatus: LoginStatus.idle);
}