import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../core/utils/security_utils.dart';
import '../services/haptic_service.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';

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
    HapticService.selection();

    try {
      final identifier = _identifierController.text.trim();
      final pin = _pinController.text.trim();

      // 1. Get Salt
      final salt = await ref.read(supabaseServiceProvider).getUserSalt(identifier);
      if (salt == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Utilisateur non trouvé')),
          );
        }
        return;
      }

      // 2. Hash PIN
      final pinHash = SecurityUtils.hashPin(pin, salt: salt);

      // 3. Verify Login
      final result = await ref.read(supabaseServiceProvider).verifyLogin(
        identifier: identifier,
        pinHash: pinHash,
      );

      if (result['is_valid'] == true) {
        HapticService.success();
        // Update Auth State
        ref.read(authProvider.notifier).login(result);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${result['message']}')),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 64),
              Text('Bon retour', style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 8),
              const Text('Connectez-vous pour accéder à vos fonds.', style: TextStyle(color: Colors.white60)),
              const SizedBox(height: 48),
              _buildTextField('Email ou Téléphone', _identifierController, icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField('Code PIN', _pinController, icon: Icons.lock_outline, obscureText: true, keyboardType: TextInputType.number),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: LiquidGlassTheme.accent))
              else
                GlassButton(
                  onPressed: _handleLogin,
                  child: const Text('Se connecter'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {IconData? icon, bool obscureText = false, TextInputType? keyboardType}) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 16,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
          border: InputBorder.none,
          icon: icon != null ? Icon(icon, color: LiquidGlassTheme.accent) : null,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
