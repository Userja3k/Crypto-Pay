import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';

class RecoveryPhraseScreen extends StatelessWidget {
  const RecoveryPhraseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Note: In a production app, use a package like 'bip39' to generate these words.
    final words = [
      'apple', 'bridge', 'castle', 'denim', 'eagle', 'forest',
      'grape', 'helmet', 'island', 'jacket', 'knight', 'lemon'
    ];

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Sécurité')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Phrase de récupération', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              const Text(
                'Écrivez ces 12 mots sur un papier et conservez-les en lieu sûr. C\'est le seul moyen de récupérer votre compte.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 32),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.5,
                ),
                itemCount: words.length,
                itemBuilder: (context, index) {
                  return GlassContainer(
                    borderRadius: 8,
                    opacity: 0.1,
                    child: Center(
                      child: Text(
                        '${index + 1}. ${words[index]}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                },
              ),
              const Spacer(),
              GlassButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('J\'ai bien noté la phrase', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
