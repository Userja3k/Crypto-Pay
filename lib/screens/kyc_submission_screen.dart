import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';

class KycSubmissionScreen extends StatefulWidget {
  const KycSubmissionScreen({super.key});

  @override
  State<KycSubmissionScreen> createState() => _KycSubmissionScreenState();
}

class _KycSubmissionScreenState extends State<KycSubmissionScreen> {
  String _selectedType = 'Carte d\'identité';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Vérification')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vérifiez votre identité', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              const Text('Pour augmenter vos limites à 2 000\$, veuillez soumettre une pièce d\'identité.', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 32),
              const Text('Type de document', style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 12),
              _buildTypeSelector(),
              const SizedBox(height: 32),
              _buildUploadPlaceholder(),
              const Spacer(),
              GlassButton(onPressed: () => Navigator.pop(context), child: const Text('Soumettre pour vérification')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      borderRadius: 16,
      child: DropdownButton<String>(
        value: _selectedType,
        dropdownColor: const Color(0xFF131313),
        underline: const SizedBox(),
        isExpanded: true,
        style: const TextStyle(color: Colors.white),
        items: ['Carte d\'identité', 'Passeport', 'Permis de conduire'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) => setState(() => _selectedType = v!),
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return GlassContainer(
      padding: const EdgeInsets.all(48),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.cloud_upload_outlined, size: 48, color: Colors.white54),
            SizedBox(height: 16),
            Text('Cliquez pour prendre une photo', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
