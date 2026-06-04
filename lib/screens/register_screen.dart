import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../core/utils/security_utils.dart';
import '../providers/user_provider.dart';
import 'recovery_phrase_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(supabaseServiceProvider);
      final salt = DateTime.now().millisecondsSinceEpoch.toString();
      final result = await service.registerUser(
        email: _emailController.text,
        phone: _phoneController.text,
        fullName: _nameController.text,
        birthDate: DateTime.parse(_birthDateController.text),
        pinHash: SecurityUtils.hashPin(_pinController.text, salt: salt),
        pinSalt: salt,
      );

      if (result['user_id'] != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RecoveryPhraseScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Échec de l\'inscription')),
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
              const SizedBox(height: 20),
              Text(
                'Créer un compte',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              Text(
                'Rejoignez l\'élite du Bitcoin en Afrique',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 32),
              _buildTextField('Nom complet', Icons.person_outline, _nameController),
              const SizedBox(height: 16),
              _buildTextField('Email', Icons.email_outlined, _emailController),
              const SizedBox(height: 16),
              _buildTextField('Téléphone', Icons.phone_outlined, _phoneController),
              const SizedBox(height: 16),
              _buildTextField('Date de naissance (AAAA-MM-JJ)', Icons.calendar_today_outlined, _birthDateController),
              const SizedBox(height: 16),
              _buildTextField('PIN (6 chiffres)', Icons.lock_outline, _pinController, isPassword: true),
              const SizedBox(height: 48),
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : GlassButton(
                      onPressed: _handleRegister,
                      child: const Text('S\'inscrire', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Déjà un compte ? Se connecter', style: TextStyle(color: Colors.white70)),
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
