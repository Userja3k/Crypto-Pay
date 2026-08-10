import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:breez_sdk/bridge_generated.dart';
import '../config.dart';
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
  String? _lnAddress;
  String? _btcAddress;
  final _inviteCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses({String? inviteCode}) async {
    final authState = ref.read(authProvider);
    final userId = authState.userId;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      // 1. S'assurer que Breez est connecté
      final breez = ref.read(breezServiceProvider);
      if (!breez.isConnected && kBreezApiKey.isNotEmpty) {
        try {
          await breez.connect(
            apiKey: kBreezApiKey,
            breezServer: kBreezServer,
            chainnotifierUrl: kBreezChainnotifierUrl,
            network: Network.Testnet,
            inviteCode: inviteCode,
          );
          ref.read(breezInitializedProvider.notifier).state = true;
        } catch (e) {
          debugPrint('Erreur connexion Breez dans LightningAddressScreen: $e');
          if (mounted) {
            final errorStr = e.toString();
            if (errorStr.contains('invite code') || errorStr.contains('not authorized')) {
              _showInviteCodeDialog();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Échec de connexion au réseau Lightning: $e'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        }
      }

      // 2. Charger les adresses depuis Supabase
      final service = ref.read(lightningAddressServiceProvider);
      final addresses = await service.getUserAddresses(userId);
      setState(() {
        _lnAddress = addresses['ln'];
        _btcAddress = addresses['btc'];
      });
    } catch (e) {
      debugPrint('Error loading addresses: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateAddresses() async {
    final authState = ref.read(authProvider);
    final userId = authState.userId;
    final fullName = authState.user?['full_name'] as String? ?? 'user';
    
    if (userId == null) return;

    setState(() => _isLoading = true);
    HapticService.selection();

    try {
      final service = ref.read(lightningAddressServiceProvider);
      final breez = ref.read(breezServiceProvider);

      // 1. Generate LN Address if not exists
      String? lnAddr = _lnAddress;
      if (lnAddr == null) {
        final username = service.generateUsername(fullName);
        lnAddr = '$username@crypto-pay.com';
      }

      // 2. Generate BTC Address from Breez
      String? btcAddr;
      try {
        btcAddr = await breez.getOnchainAddress();
      } catch (e) {
        debugPrint('Breez BTC address error: $e');
      }

      // 3. Save to Supabase
      try {
        await service.saveAddresses(
          userId: userId,
          lightningAddress: lnAddr,
          btcAddress: btcAddr,
        );
      } catch (e) {
        debugPrint('Erreur sauvegarde Supabase: $e');
        throw 'Erreur lors de la sauvegarde dans la base de données: $e';
      }

      setState(() {
        _lnAddress = lnAddr;
        _btcAddress = btcAddr;
      });
      
      if (btcAddr == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Adresse Lightning générée, mais adresse BTC impossible (Lightning déconnecté)'),
              backgroundColor: Colors.blueGrey,
            ),
          );
        }
      } else {
        HapticService.success();
      }
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

  void _showInviteCodeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Invite Code requis', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Un code d\'invitation est nécessaire pour enregistrer votre nœud sur Blockstream Greenlight.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _inviteCodeController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Entrez votre Invite Code',
                hintStyle: TextStyle(color: Colors.white38),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadAddresses(inviteCode: _inviteCodeController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: LiquidGlassTheme.accent),
            child: const Text('Connecter', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final breez = ref.watch(breezServiceProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Adresses de Réception'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: breez.isConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  breez.isConnected ? 'Connecté' : 'Déconnecté',
                  style: TextStyle(
                    fontSize: 12,
                    color: breez.isConnected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
        child: Column(
          children: [
            if (!breez.isConnected)
              GlassContainer(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                borderRadius: 12,
                opacity: 0.1,
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Lightning déconnecté. Impossible de générer l\'adresse BTC.',
                        style: TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        HapticService.selection();
                        _loadAddresses(); // Tentera de se reconnecter via le service
                      },
                      child: const Text('Réessayer', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            _buildAddressCard(
              title: 'Adresse Lightning',
              address: _lnAddress,
              icon: Icons.bolt,
              iconColor: Colors.orange,
              description: 'Adresse universelle pour recevoir des fonds instantanément.',
            ),
            const SizedBox(height: 24),
            _buildAddressCard(
              title: 'Adresse Bitcoin (On-chain)',
              address: _btcAddress,
              icon: Icons.currency_bitcoin,
              iconColor: Colors.amber,
              description: 'Adresse Testnet (tb1q...) pour recevoir depuis un faucet ou un wallet on-chain.',
            ),
            const SizedBox(height: 40),
            if (!_isLoading && (_lnAddress == null || _btcAddress == null))
              ElevatedButton(
                onPressed: _generateAddresses,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LiquidGlassTheme.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text('Générer mes adresses', style: TextStyle(fontWeight: FontWeight.bold)),
              )
            else if (!_isLoading)
              TextButton.icon(
                onPressed: _generateAddresses,
                icon: const Icon(Icons.refresh, color: Colors.white70),
                label: const Text('Régénérer les adresses', style: TextStyle(color: Colors.white70)),
              ),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: LiquidGlassTheme.accent)),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard({
    required String title,
    required String? address,
    required IconData icon,
    required Color iconColor,
    required String description,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: 32,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 32),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          if (address != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: SelectableText(
                address,
                style: const TextStyle(fontSize: 15, fontFamily: 'monospace', fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _actionButton(Icons.copy, 'Copier', () {
                  Clipboard.setData(ClipboardData(text: address));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$title copiée')),
                  );
                }),
                const SizedBox(width: 40),
                _actionButton(Icons.share, 'Partager', () {
                  // Share logic
                }),
              ],
            ),
          ] else ...[
            const Text(
              'Non générée',
              style: TextStyle(color: Colors.white38, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: Colors.white24, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ],
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
