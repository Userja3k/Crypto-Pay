import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../providers/user_provider.dart';
import 'send_payment_screen.dart';
import 'receive_payment_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'transaction_history_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              _buildBalanceCard(context, ref),
              const SizedBox(height: 24),
              _buildLightningStatus(),
              const SizedBox(height: 32),
              _buildQuickActions(context),
              const SizedBox(height: 32),
              _buildStatsCard(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white24,
                child: ClipOval(
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDwzUbqC4QgFkWcZCWJaw-nVRdq2IySRgc5dSCC2OLP1S7EqhURwsuQIBNOujaG11As66OFxvTBoxhYi-Glg3Z9EQWVFwPLRgCsszmFC7GVbovRwmmRF6fdVAZKaB97wyNTKqrW3jCzw9UH1HurXoYA-DsbqTRfzA71mkED36rW2CGpbnzZDQOb5RRGAkm6GYCZ--rBFD0V-EziDb2Y4Ovu88npZnchalO-5W2-EI8cEoZpmNCUPC8a__cP-S4h4976tNyMS9keyKs',
                    errorBuilder: (context, error, stackTrace) => const Text('J'),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Bonjour, ${authState.user?['full_name']?.split(' ')[0] ?? 'Utilisateur'} 👋',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 24),
            ),
          ],
        ),
        Stack(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_outlined, size: 28),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: const Text(
                  '3',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userId = authState.user?['user_id'] ?? '';
    final balanceAsync = ref.watch(userBalanceProvider(userId));

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: balanceAsync.when(
        data: (data) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('USD Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            Text(
              '\$${data['balance_usd']?.toStringAsFixed(2) ?? '0.00'}',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '≈ ${data['balance_sats']?.toString() ?? '0'} sats',
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: LiquidGlassTheme.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.trending_up, size: 12, color: LiquidGlassTheme.accent),
                      SizedBox(width: 4),
                      Text('+2.4%', style: TextStyle(color: LiquidGlassTheme.accent, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (err, stack) => Text('Erreur: $err', style: const TextStyle(color: Colors.red)),
      ),
    );
  }

  Widget _buildLightningStatus() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: LiquidGlassTheme.accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            const Text('🟢 Réseau Lightning connecté', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SendPaymentScreen())),
            isPrimary: false,
            child: const Column(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.north_east, color: Colors.black),
                ),
                SizedBox(height: 8),
                Text('Envoyer', style: TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GlassButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceivePaymentScreen())),
            isPrimary: false,
            child: const Column(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white12,
                  child: Icon(Icons.south_west, color: Colors.white),
                ),
                SizedBox(height: 8),
                Text('Recevoir', style: TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionHistoryScreen())),
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Transactions 30 jours', style: TextStyle(color: Colors.white, fontSize: 13)),
                Icon(Icons.equalizer, color: Colors.white.withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 100,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(12, (index) {
                  final height = [40.0, 60.0, 30.0, 80.0, 100.0, 50.0, 70.0, 40.0, 20.0, 60.0, 45.0, 85.0][index];
                  final isHighlight = index == 4;
                  return Container(
                    width: 12,
                    height: height,
                    decoration: BoxDecoration(
                      color: isHighlight ? LiquidGlassTheme.accent : Colors.white12,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total dépensé', style: TextStyle(color: Colors.white54, fontSize: 13)),
                    Text('\$412.00', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Fréquence', style: TextStyle(color: Colors.white54, fontSize: 13)),
                    Text('Élevée', style: TextStyle(color: LiquidGlassTheme.accent, fontSize: 16)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 34),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(context, Icons.person, isActive: true, destination: const HomeScreen()),
          _navItem(context, Icons.search, destination: const SearchScreen()),
          _navItem(context, Icons.payments, destination: const SendPaymentScreen()),
          _navItem(context, Icons.settings, destination: const SettingsScreen()),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, {bool isActive = false, required Widget destination}) {
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
        }
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isActive ? Colors.black : Colors.white54),
      ),
    );
  }
}
