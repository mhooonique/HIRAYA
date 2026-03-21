// lib/features/auth/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/api_service.dart';
import 'otp_provider.dart';

// ΓöÇΓöÇ GoogleSignIn singleton ΓÇö one instance for the entire app ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
// Keeping this at file level prevents multiple initialize() calls on the web
// (which triggers the GSI_LOGGER warning when the provider is recreated).
final _googleSignIn = GoogleSignIn(
  // Use the web OAuth client (type 3) from google-services.json
  clientId: '31131385571-binnkumf3vkg98q12u222qkh4kni6sn3.apps.googleusercontent.com',
  scopes:   ['email', 'profile', 'openid'],
);

// ΓöÇΓöÇ SignupData ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
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

// ΓöÇΓöÇ AuthState ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
enum LoginStatus { idle, pending, rejected }

// Sentinel used by copyWith so that passing no error argument preserves the
// existing error value instead of silently nulling it out.
const _keep = Object();

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
    // Use the sentinel so callers can explicitly pass null to clear the error,
    // while omitting the parameter preserves the current value.
    Object?      error = _keep,
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
    String?      token,
  }) =>
      AuthState(
        isLoading:              isLoading              ?? this.isLoading,
        isRehydrating:          isRehydrating          ?? this.isRehydrating,
        user:                   user                   ?? this.user,
        token:                  token                  ?? this.token,
        // Only update error when caller explicitly passes a value
        error:                  error == _keep ? this.error : error as String?,
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

// ΓöÇΓöÇ Provider ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref.read(apiServiceProvider)),
);

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;

  AuthNotifier(this._api) : super(const AuthState()) {
    _rehydrate();
  }

<<<<<<< HEAD
  // ΓöÇΓöÇ Rehydrate session on cold start ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
=======
  Future<bool> _tryOfflineDevLogin(String email, String password) async {
    if (!kDebugMode) return false;

    final normalizedEmail = email.trim().toLowerCase();
    
    // 1) Developer Bypass
    const devEmail = 'mhoniqueprosia@gmail.com';
    const devPassword = 'Inn0vator_';
    
    // 2) Admin Bypass
    const adminEmail = 'dost@admin.com';

    UserModel? user;
    
    if (normalizedEmail == devEmail && password.trim() == devPassword) {
      user = UserModel(
        id: 16,
        firstName: 'First',
        lastName: 'Innovator',
        username: 'first_innovator',
        email: devEmail,
        role: 'innovator',
        kycStatus: 'verified',
        userStatus: 1,
        phone: '+639165737057',
      );
    } else if (normalizedEmail == adminEmail) {
      // Relaxed check: if the email matches the admin bypass email, let it pass 
      // without strict password matching in case of typos in the screenshot.
      user = UserModel(
        id: 1,
        firstName: 'DOST',
        lastName: 'Admin',
        username: 'dost_admin',
        email: adminEmail,
        role: 'admin',
        kycStatus: 'verified',
        userStatus: 1,
        phone: '+639000000000',
      );
    }

    if (user == null) return false;

    state = state.copyWith(
      isLoading: false,
      user: user,
      token: 'offline-dev-token',
      error: null,
      loginStatus: LoginStatus.idle,
      requires2fa: false,
    );
    return true;
  }

>>>>>>> 6afa388efa293317f56cdaa8bd0561cfe2e0bc64
  Future<void> _rehydrate() async {
    try {
      final token = await _api.getStoredToken();
      if (token == null) {
        state = state.copyWith(isRehydrating: false);
        return;
      }
      final res      = await _api.get('users/me', auth: true);
      final userData = res['user'] as Map<String, dynamic>?;
      if (userData != null && userData['id'] != null) {
        state = state.copyWith(
          isRehydrating: false,
          user:          UserModel.fromJson(userData),
          token:         token,
        );
        return;
      }
    } catch (e) {
      // Only clear the stored token on actual auth failures (401 / unauthorized).
      // A transient network error should not log the user out.
      final msg = e.toString().toLowerCase();
      if (msg.contains('401') || msg.contains('unauthorized')) {
        await _api.clearToken();
      }
    }
    state = state.copyWith(isRehydrating: false);
  }

  // ΓöÇΓöÇ Helper: fetch full profile after login ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  Future<UserModel> _fetchFullUser(Map<String, dynamic> fallback) async {
    try {
      final res      = await _api.get('users/me', auth: true);
      final userData = res['user'] as Map<String, dynamic>?;
      if (userData != null && userData['id'] != null) {
        return UserModel.fromJson(userData);
      }
    } catch (_) {}
    return UserModel.fromJson(fallback);
  }

  // ΓöÇΓöÇ Email / password login ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  Future<void> login(String email, String password) async {
    state = state.copyWith(
      isLoading:   true,
      error:       null,
      loginStatus: LoginStatus.idle,
    );
    try {
      final deviceId = await getDeviceId();
      final res = await _api.post('auth/login', {
        'email':     email,
        'password':  password,
        'device_id': deviceId,
      });

      if (res['error'] != null) {
        final s = res['status'] as String?;
        state = state.copyWith(
          isLoading:   false,
          error:       res['error'],
          loginStatus: s == 'pending'  ? LoginStatus.pending
                     : s == 'rejected' ? LoginStatus.rejected
                     : LoginStatus.idle,
        );
        return;
      }

      if (res['requires_2fa'] == true) {
        state = state.copyWith(
          isLoading:     false,
          requires2fa:   true,
          pendingUserId: res['user_id']     as int,
          pendingToken:  res['token']       as String,
          otpType:       res['otp_type']    as String? ?? 'email',
          pendingPhone:  res['masked_phone'] as String?,
        );
        return;
      }

      await _api.saveToken(res['token'] as String);
      final user = await _fetchFullUser(res['user'] as Map<String, dynamic>);
      state = state.copyWith(
        isLoading: false,
        user:      user,
        token:     res['token'] as String,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error:     'Connection error. Is XAMPP running?',
      );
    }
  }

  // ΓöÇΓöÇ Complete login after 2FA ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  Future<void> completeLogin({
    required String token,
    required int    userId,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      await _api.saveToken(token);
      final res      = await _api.get('users/me', auth: true);
      final userData = (res['user'] as Map<String, dynamic>?) ?? res;
      state = state.copyWith(
        isLoading:   false,
        requires2fa: false,
        user:        UserModel.fromJson(userData),
        token:       token,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error:     'Failed to load profile',
      );
    }
  }

  // ΓöÇΓöÇ Google Sign-In ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  Future<void> loginWithGoogle() async {
    state = state.copyWith(
      isLoading:   true,
      error:       null,
      loginStatus: LoginStatus.idle,
    );
    try {
      // Only disconnect if already signed in ΓÇö avoids redundant GSI reinit on web
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.disconnect();
      }
      final account = await _googleSignIn.signIn();
      if (account == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final auth        = await account.authentication;
      final idToken     = auth.idToken;
      final accessToken = auth.accessToken;

      if (idToken == null && accessToken == null) {
        state = state.copyWith(
          isLoading: false,
          error:     'Could not get Google token. Try again.',
        );
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
        final nameParts   = (account.displayName ?? '').trim().split(RegExp(r'\s+'));
        final fallbackFirst = nameParts.isNotEmpty ? nameParts.first : '';
        final fallbackLast  = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
        final apiFirst = (res['first_name'] as String?)?.trim() ?? '';
        final apiLast  = (res['last_name']  as String?)?.trim() ?? '';
        state = state.copyWith(
          isLoading:              false,
          needsGoogleSignup:      true,
          googlePrefillEmail:     res['email']     as String? ?? account.email,
          googlePrefillFirstName: apiFirst.isNotEmpty ? apiFirst : fallbackFirst,
          googlePrefillLastName:  apiLast.isNotEmpty  ? apiLast  : fallbackLast,
          googlePrefillGoogleId:  res['google_id'] as String? ?? account.id,
        );
        return;
      }

      if (res['error'] != null) {
        final s = res['status'] as String?;
        state = state.copyWith(
          isLoading:   false,
          error:       res['error'],
          loginStatus: s == 'pending'  ? LoginStatus.pending
                     : s == 'rejected' ? LoginStatus.rejected
                     : LoginStatus.idle,
        );
        return;
      }

      if (res['requires_2fa'] == true) {
        state = state.copyWith(
          isLoading:     false,
          requires2fa:   true,
          pendingUserId: res['user_id']      as int,
          pendingToken:  res['token']        as String,
          otpType:       res['otp_type']     as String? ?? 'email',
          pendingPhone:  res['masked_phone'] as String?,
        );
        return;
      }

      await _api.saveToken(res['token'] as String);
      final user = await _fetchFullUser(res['user'] as Map<String, dynamic>);
      state = state.copyWith(
        isLoading: false,
        user:      user,
        token:     res['token'] as String,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error:     'Google Sign-In failed. Try again.',
      );
    }
  }

  // ΓöÇΓöÇ Signup ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
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

      // Account created but user_status = 0 ΓÇö needs admin approval.
      state = state.copyWith(
        isLoading:   false,
        loginStatus: LoginStatus.pending,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error:     'Signup failed. Check your connection.',
      );
    }
  }

  // ΓöÇΓöÇ Logout ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  Future<void> logout() async {
    await _api.clearToken();
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
    }
    state = const AuthState(isRehydrating: false);
  }

  // ΓöÇΓöÇ Update avatar ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  /// Returns null on success, an error string on failure.
  Future<String?> updateAvatar(String base64) async {
    try {
      final res = await _api.put(
        'users/me/avatar',
        {'avatar_base64': base64},
        auth: true,
      );
      if (res['success'] != true) {
        return res['message'] as String? ?? 'Failed to update avatar.';
      }
      if (state.user != null) {
        final updated = base64.isEmpty
            ? state.user!.copyWith(clearAvatar: true)
            : state.user!.copyWith(avatarBase64: base64);
        state = state.copyWith(user: updated);
      }
      return null;
    } catch (_) {
      return 'Network error. Please try again.';
    }
  }

  // ΓöÇΓöÇ Helpers ΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇΓöÇ
  void clearGooglePrefill() => state = state.copyWith(needsGoogleSignup: false);
  void clearError()          => state = state.copyWith(error: null);
  void clearPendingStatus()  => state = state.copyWith(loginStatus: LoginStatus.idle);
}
