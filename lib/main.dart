import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase (Using placeholders, user will need to provide real values)
  await Supabase.initialize(
    url: 'https://zfrmcnmvhezninmeacak.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpmcm1jbm12aGV6bmlubWVhY2FrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODExNjQ0ODAsImV4cCI6MjA5Njc0MDQ4MH0.7mN0hq5pMcOemFf3rWSYlrhe9rCppRu93teKNhbYf6A',
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
