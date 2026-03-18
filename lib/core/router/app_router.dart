// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/profile/screens/public_profile_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/pending_approval_screen.dart';
import '../../features/admin/screens/admin_screen.dart';
import '../../features/innovator/screens/innovator_dashboard_screen.dart';
import '../../features/client/screens/client_dashboard_screen.dart';
import '../../features/landing/screens/landing_screen.dart';
import '../../features/marketplace/screens/marketplace_screen.dart';
import '../../features/product/screens/product_detail_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/messaging/screens/messaging_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthStateNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth     = ref.read(authProvider);
      final location = state.uri.toString();

      if (auth.isRehydrating) return null;

      final loggedIn = auth.isLoggedIn;
      final role     = auth.user?.role ?? '';

      // Google new-user → go to signup
      if (auth.needsGoogleSignup && location != '/signup') return '/signup';

      // Signed up but awaiting admin approval → pending screen
      if (auth.loginStatus == LoginStatus.pending && location != '/pending') return '/pending';

      // 2FA pending → go to OTP screen
      if (auth.requires2fa && location != '/otp') return '/otp';

      // '/' is public — anyone can view the landing page
      if (location == '/') {
        // If already logged in, send to their dashboard
        if (loggedIn) return _dashboardFor(role);
        return null;
      }

      final isGuestOnly = location == '/login' ||
          location == '/signup' ||
          location == '/forgot-password' ||
          location == '/pending' ||
          location.startsWith('/reset-password');

      // Public routes — accessible without login
      final isPublic = location == '/marketplace' ||
          location == '/search' ||
          location.startsWith('/product/') ||
          location.startsWith('/profile/');

      // Not logged in trying to access a protected route
      if (!loggedIn && !isGuestOnly && !isPublic && location != '/otp') return '/login';

      // Logged in trying to access guest-only routes → send to dashboard
      if (loggedIn && isGuestOnly) return _dashboardFor(role);

      // Role-based protection
      if (loggedIn && location.startsWith('/admin')     && role != 'admin')     return _dashboardFor(role);
      if (loggedIn && location.startsWith('/innovator') && role != 'innovator') return _dashboardFor(role);
      if (loggedIn && location.startsWith('/client')    && role != 'client')    return _dashboardFor(role);

      return null;
    },
    routes: [
      GoRoute(path: '/',                builder: (_, __) => const LandingScreen()),
      GoRoute(path: '/login',           builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/signup',          builder: (_, __) => const SignupScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/pending',         builder: (_, __) => const PendingApprovalScreen()),

      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ResetPasswordScreen(token: token);
        },
      ),

      GoRoute(
        path: '/otp',
        builder: (context, routeState) {
          final auth = ref.read(authProvider);
          return OtpScreen(
            userId:        auth.pendingUserId,
            token:         auth.pendingToken,
            otpType:       auth.otpType,
            phone:         auth.pendingPhone,
            maskedContact: _maskContact(auth),
          );
        },
      ),

      GoRoute(
        path: '/marketplace',
        builder: (_, state) => MarketplaceScreen(
          initialCategory: state.uri.queryParameters['category'],
        ),
      ),
      GoRoute(path: '/search',      builder: (_, __) => const SearchScreen()),
      GoRoute(path: '/messaging',   builder: (_, __) => const MessagingScreen()),

      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return ProductDetailScreen(productId: id);
        },
      ),

      GoRoute(path: '/admin',               builder: (_, __) => const AdminScreen()),
      GoRoute(path: '/innovator/dashboard', builder: (_, __) => const InnovatorDashboardScreen()),
      GoRoute(path: '/client/dashboard',    builder: (_, __) => const ClientDashboardScreen()),

      GoRoute(
        path: '/profile/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
          return PublicProfileScreen(userId: id);
        },
      ),
    ],
  );
});

String _dashboardFor(String role) => switch (role) {
  'admin'     => '/admin',
  'innovator' => '/innovator/dashboard',
  _           => '/client/dashboard',
};

String _maskContact(AuthState auth) {
  if (auth.otpType == 'sms' && auth.pendingPhone != null) {
    final p = auth.pendingPhone!;
    if (p.length > 4) {
      return '${p.substring(0, p.length - 4).replaceAll(RegExp(r'\d'), '*')}${p.substring(p.length - 4)}';
    }
    return p;
  }
  return 'your Gmail';
}

class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}