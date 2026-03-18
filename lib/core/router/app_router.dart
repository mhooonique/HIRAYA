// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
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
import '../../features/marketplace/data/dummy_products.dart';
import '../../features/product/screens/product_detail_screen.dart';
import '../../features/product/screens/demo_product_screen.dart';
import '../../features/profile/screens/public_profile_screen.dart';
import '../../features/messaging/screens/messaging_screen.dart';
import '../../features/search/screens/search_screen.dart';

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

      // On OTP page but no active 2FA flow → back to login
      if (location == '/otp' && !auth.requires2fa) return '/login';

      // Public routes — anyone can view
      final isPublic = location == '/' ||
          location == '/marketplace' ||
          location.startsWith('/product/') ||
          location.startsWith('/profile/') ||
          location == '/search';

      if (isPublic) {
        if (loggedIn && location == '/') return _dashboardFor(role);
        return null;
      }

      final isGuestOnly = location == '/login' ||
          location == '/signup' ||
          location == '/forgot-password' ||
          location == '/pending' ||
          location.startsWith('/reset-password');

      // Not logged in trying to access a protected route
      if (!loggedIn && !isGuestOnly && location != '/otp') return '/login';

      // Logged in trying to access guest-only routes → send to dashboard
      if (loggedIn && isGuestOnly) return _dashboardFor(role);

      // Role-based protection
      if (loggedIn && location.startsWith('/admin')     && role != 'admin')     return _dashboardFor(role);
      if (loggedIn && location.startsWith('/innovator') && role != 'innovator') return _dashboardFor(role);
      if (loggedIn && location.startsWith('/client')    && role != 'client')    return _dashboardFor(role);

      return null;
    },
    routes: [
      // ── Public ──────────────────────────────────────────────────────────────
      GoRoute(path: '/',            builder: (_, __) => const LandingScreen()),
      GoRoute(path: '/marketplace', builder: (_, __) => const MarketplaceScreen()),
      GoRoute(path: '/search',      builder: (_, __) => const SearchScreen()),

      GoRoute(
        path: '/product/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          // Negative IDs = dummy/demo products
          if (id < 0) {
            final dummy = dummyProducts.firstWhere(
              (p) => p.id == id,
              orElse: () => dummyProducts.first,
            );
            return DemoProductScreen(product: dummy);
          }
          return ProductDetailScreen(productId: id);
        },
      ),

      GoRoute(
        path: '/profile/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return PublicProfileScreen(userId: id);
        },
      ),

      // ── Auth ────────────────────────────────────────────────────────────────
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

<<<<<<< HEAD
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

=======
      // ── Protected ───────────────────────────────────────────────────────────
>>>>>>> origin/master
      GoRoute(path: '/admin',               builder: (_, __) => const AdminScreen()),
      GoRoute(path: '/innovator/dashboard', builder: (_, __) => const InnovatorDashboardScreen()),
      GoRoute(path: '/client/dashboard',    builder: (_, __) => const ClientDashboardScreen()),
      GoRoute(path: '/messaging',           builder: (_, __) => const MessagingScreen()),
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