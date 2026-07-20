import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';
import 'services/breez_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(url: kSupabaseUrl, publishableKey: kSupabaseAnonKey);

  // Initialize Breez SDK (not supported on Windows)
  // BreezService uses native binaries; on Windows the SDK currently crashes
  // with "UnsupportedPlatform". We skip Breez initialization on Windows and
  // let the UI start without Lightning functionality.
  // On Android/iOS/macOS/Linux this can be enabled later.
  // For Windows we keep Breez disabled so the app doesn't crash on startup.
  if (!Platform.isWindows) {
    // TODO: optionally initialize Breez on platforms that support it.
  }

  runApp(const ProviderScope(child: CryptoPayApp()));
}

class CryptoPayApp extends StatelessWidget {
  const CryptoPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto-Pay',
      debugShowCheckedModeBanner: false,
      theme: LiquidGlassTheme.darkTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const SplashScreen();
  }
}
