import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../providers/user_provider.dart';

class ChildManagementScreen extends ConsumerStatefulWidget {
  const ChildManagementScreen({super.key});

  @override
  ConsumerState<ChildManagementScreen> createState() => _ChildManagementScreenState();
}

class _ChildManagementScreenState extends ConsumerState<ChildManagementScreen> {
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleCreateChild() async {
    if (_nameController.text.isEmpty || _birthDateController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final authState = ref.read(authProvider);
      final service = ref.read(supabaseServiceProvider);
      final result = await service.createChildAccount(
        parentUserId: authState.user?['user_id'] ?? '',
        childFullName: _nameController.text,
        childBirthDate: DateTime.parse(_birthDateController.text),
        maxPerTransaction: 50.0,
        maxPerDay: 100.0,
        maxPerMonth: 500.0,
      );

      if (result['invitation_code'] != null) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF131313),
              title: const Text('Compte enfant créé', style: TextStyle(color: Colors.white)),
              content: Text('Donnez ce code à votre enfant : ${result['invitation_code']}', style: const TextStyle(color: Colors.white70)),
              actions: [
                TextButton(onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // back to settings
                }, child: const Text('OK')),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Crypto-Famille')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ajouter un enfant', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              _buildInput('Prénom de l\'enfant', _nameController),
              const SizedBox(height: 16),
              _buildInput('Date de naissance (AAAA-MM-JJ)', _birthDateController),
              const SizedBox(height: 32),
              const Text('Limites par défaut :', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              const Text('• 50\$ / transaction\n• 100\$ / jour\n• Approbation parentale requise', style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 48),
              _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : GlassButton(onPressed: _handleCreateChild, child: const Text('Générer un Code d\'Invitation')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderRadius: 16,
      opacity: 0.05,
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
