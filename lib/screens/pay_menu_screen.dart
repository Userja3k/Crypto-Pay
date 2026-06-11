import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import 'send_payment_screen.dart';

class PayMenuScreen extends StatelessWidget {
  const PayMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Payer', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildLargeMenuItem(
                context,
                icon: Icons.qr_code_scanner,
                title: 'Scanner QR Code',
                subtitle: 'Caméra plein écran, détection auto',
                onTap: () {},
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSmallMenuItem(
                      context,
                      icon: Icons.nfc,
                      title: 'Paiement NFC',
                      subtitle: 'Approchez les appareils',
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSmallMenuItem(
                      context,
                      icon: Icons.bluetooth,
                      title: 'Bluetooth',
                      subtitle: 'Recherche d\'appareils...',
                      onTap: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildLargeMenuItem(
                context,
                icon: Icons.alternate_email,
                title: 'Adresse externe',
                subtitle: 'Binance, WoS, Phoenix, etc.',
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SendPaymentScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeMenuItem(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        borderRadius: 24,
        opacity: 0.1,
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: LiquidGlassTheme.accent.withValues(alpha: 0.1),
              child: Icon(icon, color: LiquidGlassTheme.accent, size: 30),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white12, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallMenuItem(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: 24,
        opacity: 0.1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: LiquidGlassTheme.accent, size: 28),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
