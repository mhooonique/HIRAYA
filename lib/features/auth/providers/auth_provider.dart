import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import '../../../core/models/user_model.dart';

class SignupData {
  String role = '';
  String firstName = '';
  String lastName = '';
  String middleName = '';
  String suffix = '';
  String username = '';
  String email = '';
  String password = '';
  String phone = '';
  String countryCode = '+63';
  bool privacyAccepted = false;
  bool dataConsentAccepted = false;
}

class AuthState {
  final bool isLoading;
  final String? error;
  final UserModel? user;
  final bool isAuthenticated;

  AuthState({
    this.isLoading = false,
    this.error,
    this.user,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    UserModel? user,
    bool? isAuthenticated,
  }) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        user: user ?? this.user,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    // ── TEMP BYPASS ──────────────────────────────────────────────
    await Future.delayed(const Duration(milliseconds: 300));
    if (email == 'admin@hiraya.com' && password == 'Admin@1234') {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: UserModel(
          id: 1, firstName: 'Admin', lastName: 'Hiraya',
          email: 'admin@hiraya.com', username: 'admin_hiraya',
          role: 'admin', kycStatus: 'verified', userStatus: 1,
        ),
      );
      return true;
    }
    if (email == 'juan@example.com' && password == 'Juan@1234') {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: UserModel(
          id: 2, firstName: 'Juan', lastName: 'dela Cruz',
          email: 'juan@example.com', username: 'juan_dc',
          role: 'innovator', kycStatus: 'pending', userStatus: 1,
        ),
      );
      return true;
    }
    if (email == 'client@hiraya.com' && password == 'Client@1234') {
      state = state.copyWith(
        user: UserModel(
          id: 3,
          firstName: 'Maria',
          lastName: 'Santos',
          email: email,
          username: 'mariasantos',
          role: 'client',
          kycStatus: 'verified',
          userStatus: 1,
        ),
        isAuthenticated: true,
        isLoading: false,
      );
      return true;
    }
    // ── END BYPASS ───────────────────────────────────────────────

    try {
      final res = await ApiService.post('/auth/login', {
        'email': email,
        'password': password,
      });
      if (res.data['success'] == true) {
        await ApiService.saveToken(res.data['token']);
        final user = UserModel.fromJson(res.data['user']);
        state = state.copyWith(
          isLoading: false,
          user: user,
          isAuthenticated: true,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: res.data['message'] ?? 'Login failed.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Cannot connect to server.',
      );
      return false;
    }
  }

  Future<bool> signup(SignupData data) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ApiService.post('/auth/signup', {
        'role': data.role,
        'first_name': data.firstName,
        'last_name': data.lastName,
        'middle_name': data.middleName,
        'suffix': data.suffix,
        'username': data.username,
        'email': data.email,
        'password': data.password,
        'phone': '${data.countryCode}${data.phone}',
        'privacy_accepted': data.privacyAccepted,
        'data_consent': data.dataConsentAccepted,
      });
      if (res.data['success'] == true) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: res.data['message'] ?? 'Signup failed.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Cannot connect to server.',
      );
      return false;
    }
  }

  void logout() {
    ApiService.clearToken();
    state = AuthState();
  }

  void clearError() => state = state.copyWith(error: null);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);