import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../services/haptic_service.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';

class RecoveryPhraseScreen extends StatefulWidget {
  final String userId;
  const RecoveryPhraseScreen({super.key, required this.userId});

  @override
  State<RecoveryPhraseScreen> createState() => _RecoveryPhraseScreenState();
}

class _RecoveryPhraseScreenState extends State<RecoveryPhraseScreen> {
  final List<String> _words = [
    'ocean', 'winter', 'guitar', 'mountain', 'legacy', 'future',
    'crypto', 'liquid', 'assets', 'africa', 'secure', 'freedom'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Phrase de récupération', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              const Text(
                'Écrivez ces 12 mots sur un papier. C\'est le seul moyen de récupérer votre compte.',
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 3,
                  ),
                  itemCount: _words.length,
                  itemBuilder: (context, index) {
                    return GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      borderRadius: 12,
                      child: Row(
                        children: [
                          Text('${index + 1}.', style: const TextStyle(color: Colors.white24, fontSize: 12)),
                          const SizedBox(width: 8),
                          Text(_words[index], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              GlassButton(
                onPressed: () {
                  HapticService.medium();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
                child: const Text('J\'ai bien noté les mots'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
