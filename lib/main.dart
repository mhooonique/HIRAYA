// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/theme_provider.dart';
import 'core/constants/app_colors.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/messaging/providers/messaging_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey:            'AIzaSyDd2bKF9Diz_PZJL_3FbUTisWPQvECIXOo',
      authDomain:        'hiraya-dev.firebaseapp.com',
      databaseURL:       'https://hiraya-dev-default-rtdb.asia-southeast1.firebasedatabase.app',
      projectId:         'hiraya-dev',
      storageBucket:     'hiraya-dev.firebasestorage.app',
      messagingSenderId: '31131385571',
      appId:             '1:31131385571:android:c4c93e56619ef4d1450fd6',
    ),
  );
  runApp(const ProviderScope(child: HirayaApp()));
}

class HirayaApp extends ConsumerWidget {
  const HirayaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title:                    'Digital Platform',
      theme:                    AppTheme.lightTheme,
      darkTheme:                AppTheme.darkTheme,
      themeMode:                ref.watch(themeProvider),
      routerConfig:             router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => _GlobalCallListener(child: child ?? const SizedBox()),
    );
  }
}

// ─── Global call listener — wraps the entire app ───────────────────────────────
// Starts call polling the moment the user logs in and shows the incoming call
// dialog no matter which screen they're currently on.
class _GlobalCallListener extends ConsumerStatefulWidget {
  final Widget child;
  const _GlobalCallListener({required this.child});

  @override
  ConsumerState<_GlobalCallListener> createState() => _GlobalCallListenerState();
}

class _GlobalCallListenerState extends ConsumerState<_GlobalCallListener> {
  int? _lastUserId;

  @override
  Widget build(BuildContext context) {
    // Start / restart call polling whenever auth changes to a logged-in user
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.user != null && next.user!.id != _lastUserId) {
        _lastUserId = next.user!.id;
        // Admins don't use messaging — skip polling to avoid noisy network calls
        if (next.user!.role != 'admin') {
          ref.read(messagingProvider.notifier).loadConversations(next.user!.id);
        }
      }
      // Stop polling on logout
      if (next.user == null && _lastUserId != null) {
        _lastUserId = null;
      }
    });

    // Show incoming call dialog from anywhere in the app
    ref.listen<IncomingCall?>(
      messagingProvider.select((s) => s.incomingCall),
      (prev, next) {
        if (next != null && prev?.id != next.id) {
          _showIncomingCallDialog(context, next);
        }
      },
    );

    return widget.child;
  }

  void _showIncomingCallDialog(BuildContext context, IncomingCall call) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.sky.withValues(alpha: 0.15),
              child: Icon(
                call.isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                size: 32,
                color: AppColors.sky,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Incoming ${call.isVideo ? "Video" : "Voice"} Call',
              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              call.callerName,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(children: [
                  FloatingActionButton(
                    heroTag: 'global_decline_${call.id}',
                    backgroundColor: Colors.red,
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ref.read(messagingProvider.notifier).declineCall(call.id);
                    },
                    child: const Icon(Icons.call_end_rounded, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text('Decline', style: TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                ]),
                Column(children: [
                  FloatingActionButton(
                    heroTag: 'global_accept_${call.id}',
                    backgroundColor: Colors.green,
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ref.read(messagingProvider.notifier).acceptCall(call.id, call.roomUrl);
                    },
                    child: Icon(
                      call.isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text('Accept', style: TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                ]),
              ],
            ),
          ],
        ),
      ),
    );
  }
}