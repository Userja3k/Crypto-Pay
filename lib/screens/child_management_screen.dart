import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../providers/user_provider.dart';
import '../services/haptic_service.dart';

class ChildManagementScreen extends ConsumerStatefulWidget {
  const ChildManagementScreen({super.key});

  @override
  ConsumerState<ChildManagementScreen> createState() => _ChildManagementScreenState();
}

class _ChildManagementScreenState extends ConsumerState<ChildManagementScreen> {
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  DateTime? _selectedBirthDate;

  double _maxTx = 50.0;
  double _maxDay = 100.0;
  bool _requiresApproval = true;
  bool _isLoading = false;

  Future<void> _createChild() async {
    if (_selectedBirthDate == null || _nameController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final authState = ref.read(authProvider);
      final result = await ref.read(supabaseServiceProvider).createChildAccount(
        parentUserId: authState.user!['user_id'],
        childFullName: _nameController.text,
        childBirthDate: _selectedBirthDate!,
        maxPerTransaction: _maxTx,
        maxPerDay: _maxDay,
        maxPerMonth: 500,
      );

      if (result['child_user_id'] != null) {
        HapticService.success();
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: LiquidGlassTheme.surface,
              title: const Text('Compte enfant créé'),
              content: Text('Code d\'invitation: ${result['invitation_code']}'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error creating child: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Crypto-Famille'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ajouter un enfant', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            _buildTextField('Prénom de l\'enfant', _nameController, icon: Icons.child_care),
            const SizedBox(height: 16),
            _buildTextField(
              'Date de naissance',
              _birthDateController,
              icon: Icons.calendar_today,
              readOnly: true,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _selectedBirthDate = date;
                    _birthDateController.text = "${date.day}/${date.month}/${date.year}";
                  });
                }
              }
            ),
            const SizedBox(height: 32),
            const Text('Limites de dépenses', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildLimitSlider('Max par transaction', _maxTx, 10, 200, (v) => setState(() => _maxTx = v)),
            _buildLimitSlider('Max par jour', _maxDay, 20, 500, (v) => setState(() => _maxDay = v)),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Approbation parentale'),
              subtitle: const Text('Nécessaire pour chaque transaction'),
              value: _requiresApproval,
              onChanged: (v) => setState(() => _requiresApproval = v),
              activeThumbColor: LiquidGlassTheme.accent,
            ),
            const SizedBox(height: 48),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: LiquidGlassTheme.accent))
            else
              GlassButton(onPressed: _createChild, child: const Text('Créer le compte enfant')),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {IconData? icon, bool readOnly = false, VoidCallback? onTap}) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderRadius: 16,
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          icon: icon != null ? Icon(icon, color: LiquidGlassTheme.accent) : null,
        ),
      ),
    );
  }

  Widget _buildLimitSlider(String label, double value, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60)),
            Text('\$${value.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: LiquidGlassTheme.accent)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: LiquidGlassTheme.accent,
          inactiveColor: Colors.white10,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
