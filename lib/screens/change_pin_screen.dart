import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../services/haptic_service.dart';
import '../providers/user_provider.dart';

class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  Future<void> _changePin() async {
    final currentPin = _currentPinController.text.trim();
    final newPin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();

    if (currentPin.length < 4 || newPin.length < 4 || newPin != confirmPin) {
      _showError('Vérifiez les codes PIN');
      return;
    }

    setState(() => _isLoading = true);
    HapticService.medium();

    await Future.delayed(const Duration(seconds: 1));

    HapticService.success();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Code PIN modifié')));
      Navigator.pop(context);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $message'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Modifier le code PIN')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildPinInput(controller: _currentPinController, label: 'Code PIN actuel', obscure: _obscureCurrent, onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent)),
              const SizedBox(height: 20),
              _buildPinInput(controller: _newPinController, label: 'Nouveau code PIN', obscure: _obscureNew, onToggle: () => setState(() => _obscureNew = !_obscureNew)),
              const SizedBox(height: 20),
              _buildPinInput(controller: _confirmPinController, label: 'Confirmer le nouveau code', obscure: _obscureConfirm, onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm)),
              const SizedBox(height: 32),
              GlassButton(onPressed: _changePin, child: const Text('Modifier le code PIN')),
              const Spacer(),
              Text('⚠️ Ne partagez jamais votre code PIN', style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinInput({required TextEditingController controller, required String label, required bool obscure, required VoidCallback onToggle}) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      borderRadius: 16,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: TextInputType.number,
        maxLength: 6,
        style: const TextStyle(color: Colors.white, fontSize: 18),
        decoration: InputDecoration(labelText: label, border: InputBorder.none, counterText: '', suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white38), onPressed: onToggle)),
      ),
    );
  }
}
