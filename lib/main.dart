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
  await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonKey);

  // Initialize Breez SDK
  await BreezService().initialize();

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
