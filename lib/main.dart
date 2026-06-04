import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (Using placeholders, user will need to provide real values)
  await Supabase.initialize(
    url: 'https://placeholder.supabase.co',
    anonKey: 'placeholder-anon-key',
  );

  runApp(
    const ProviderScope(
      child: CryptoPayApp(),
    ),
  );
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
