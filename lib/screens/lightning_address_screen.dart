import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../providers/user_provider.dart';
import '../services/haptic_service.dart';

class LightningAddressScreen extends ConsumerStatefulWidget {
  const LightningAddressScreen({super.key});

  @override
  ConsumerState<LightningAddressScreen> createState() => _LightningAddressScreenState();
}

class _LightningAddressScreenState extends ConsumerState<LightningAddressScreen> {
  bool _isLoading = false;
  String? _address;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    final authState = ref.read(authProvider);
    final userId = authState.userId;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      final service = ref.read(lightningAddressServiceProvider);
      final address = await service.getLightningAddress(userId);
      if (address != null) {
        setState(() => _address = address);
      }
    } catch (e) {
      debugPrint('Error loading lightning address: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createAddress() async {
    final authState = ref.read(authProvider);
    final userId = authState.userId;
    final fullName = authState.user?['full_name'] as String? ?? 'user';
    
    if (userId == null) return;

    setState(() => _isLoading = true);
    HapticService.selection();

    try {
      final service = ref.read(lightningAddressServiceProvider);
      final username = service.generateUsername(fullName);
      final address = await service.createLightningAddress(
        userId: userId,
        username: username,
      );
      setState(() => _address = address);
      HapticService.success();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adresse Lightning'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
        child: Column(
          children: [
            const SizedBox(height: 20),
            GlassContainer(
              padding: const EdgeInsets.all(24),
              borderRadius: 32,
              child: Column(
                children: [
                  const Icon(Icons.bolt, color: Colors.orange, size: 64),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const CircularProgressIndicator(color: LiquidGlassTheme.accent)
                  else if (_address != null) ...[
                    Text(
                      _address!,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Votre adresse universelle pour recevoir des fonds via le réseau Lightning.',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _actionButton(Icons.copy, 'Copier', () {
                          Clipboard.setData(ClipboardData(text: _address!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Adresse copiée')),
                          );
                        }),
                        const SizedBox(width: 32),
                        _actionButton(Icons.share, 'Partager', () {
                          // Share logic
                        }),
                      ],
                    ),
                  ] else ...[
                    const Text(
                      'Vous n\'avez pas encore d\'adresse Lightning.',
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _createAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LiquidGlassTheme.accent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: const Text('Générer mon adresse', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        HapticService.selection();
        onTap();
      },
      child: Column(
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(12),
            borderRadius: 16,
            opacity: 0.1,
            child: Icon(icon, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}
