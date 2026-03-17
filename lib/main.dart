// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

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
      title:                    'HIRAYA',
      theme:                    AppTheme.lightTheme,
      darkTheme:                AppTheme.darkTheme,
      themeMode:                ThemeMode.light,
      routerConfig:             router,
      debugShowCheckedModeBanner: false,
    );
  }
}