import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/landing/screens/landing_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/marketplace/screens/marketplace_screen.dart';
import '../../features/product/screens/product_detail_screen.dart';
import '../../features/admin/screens/admin_screen.dart';
import '../../features/innovator/screens/innovator_dashboard_screen.dart';
import '../../features/client/screens/client_dashboard_screen.dart';
import '../../features/messaging/screens/messaging_screen.dart';


final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
          path: '/',
          builder: (ctx, state) => const LandingScreen()),
      GoRoute(
          path: '/login',
          builder: (ctx, state) => const LoginScreen()),
      GoRoute(
          path: '/signup',
          builder: (ctx, state) => const SignupScreen()),
      GoRoute(
          path: '/forgot-password',
          builder: (ctx, state) => const ForgotPasswordScreen()),
      GoRoute(
          path: '/marketplace',
          builder: (ctx, state) => const MarketplaceScreen()),
      GoRoute(
          path: '/product/:id',
          builder: (ctx, state) {
            final id =
                int.tryParse(state.pathParameters['id'] ?? '0') ?? 0;
            return ProductDetailScreen(productId: id);
          }),
      GoRoute(
        path: '/admin',
        builder: (ctx, state) => const AdminScreen()),
      GoRoute(
          path: '/innovator/dashboard',
          builder: (ctx, state) => const InnovatorDashboardScreen()),
      GoRoute(
          path: '/client/dashboard',
          builder: (ctx, state) => const ClientDashboardScreen()),
      GoRoute(
          path: '/messages',
          builder: (ctx, state) => const MessagingScreen()),
    ],
  );
});