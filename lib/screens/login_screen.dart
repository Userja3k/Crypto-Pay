import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../core/utils/security_utils.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'password_recovery_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(supabaseServiceProvider);
      final salt = await service.getUserSalt(_identifierController.text);
      
      final result = await service.verifyLogin(
        identifier: _identifierController.text,
        pinHash: SecurityUtils.hashPin(_pinController.text, salt: salt ?? ''),
      );

      if (result['is_valid'] == true) {
        ref.read(authProvider.notifier).login(result);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Échec de la connexion')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Bon retour,',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              Text(
                'Connectez-vous à votre compte',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 48),
              _buildTextField('Email ou Téléphone', Icons.person_outline, _identifierController),
              const SizedBox(height: 16),
              _buildTextField('PIN (6 chiffres)', Icons.lock_outline, _pinController, isPassword: true),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PasswordRecoveryScreen()));
                  },
                  child: const Text('PIN oublié ?', style: TextStyle(color: LiquidGlassTheme.accent)),
                ),
              ),
              const Spacer(),
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : GlassButton(
                      onPressed: _handleLogin,
                      child: const Text('Se connecter', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text('Pas encore de compte ? S\'inscrire', style: TextStyle(color: Colors.white70)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderRadius: 16,
      opacity: 0.05,
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38),
          icon: Icon(icon, color: Colors.white38),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
