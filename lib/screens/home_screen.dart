import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../providers/user_provider.dart';
import '../services/haptic_service.dart';
import 'send_payment_screen.dart';
import 'receive_payment_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';
import 'pay_menu_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _reflectionController;

  @override
  void initState() {
    super.initState();
    _reflectionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background Orbs
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container()),
              ),
            ),

            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: LiquidGlassTheme.marginPage,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, authState),
                  const SizedBox(height: 32),
                  _buildBalanceCard(context, authState),
                  const SizedBox(height: 16),
                  _buildLightningStatus(),
                  const SizedBox(height: 32),
                  _buildQuickActions(context),
                  const SizedBox(height: 32),
                  _buildStatsCard(context),
                  const SizedBox(height: 120), // Bottom nav space
                ],
              ),
            ),

            Positioned(
              bottom: 34,
              left: 24,
              right: 24,
              child: _buildBottomNav(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthState authState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                HapticService.selection();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white12),
                  image: const DecorationImage(
                    image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDwzUbqC4QgFkWcZCWJaw-nVRdq2IySRgc5dSCC2OLP1S7EqhURwsuQIBNOujaG11As66OFxvTBoxhYi-Glg3Z9EQWVFwPLRgCsszmFC7GVbovRwmmRF6fdVAZKaB97wyNTKqrW3jCzw9UH1HurXoYA-DsbqTRfzA71mkED36rW2CGpbnzZDQOb5RRGAkm6GYCZ--rBFD0V-EziDb2Y4Ovu88npZnchalO-5W2-EI8cEoZpmNCUPC8a__cP-S4h4976tNyMS9keyKs'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Bonjour, ${authState.user?['full_name']?.split(' ')[0] ?? 'Jean'} 👋',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 24),
            ),
          ],
        ),
        Stack(
          children: [
            IconButton(
              onPressed: () => HapticService.selection(),
              icon: const Icon(Icons.notifications_outlined, size: 28),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: const Center(
                  child: Text('3', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, AuthState authState) {
    final userId = authState.user?['user_id'] ?? '';
    final balanceAsync = ref.watch(userBalanceProvider(userId));

    return AnimatedBuilder(
      animation: _reflectionController,
      builder: (context, child) {
        return GlassContainer(
          padding: const EdgeInsets.all(28),
          borderRadius: 32,
          opacity: 0.12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('USD Balance', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 12),
              balanceAsync.when(
                data: (data) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${data['balance_usd']?.toStringAsFixed(2) ?? '1,245.85'}',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 48),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '≈ 0.0117 BTC',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white60),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: LiquidGlassTheme.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.trending_up, size: 12, color: LiquidGlassTheme.accent),
                              SizedBox(width: 4),
                              Text('+2.4%', style: TextStyle(color: LiquidGlassTheme.accent, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                loading: () => const CircularProgressIndicator(color: Colors.white),
                error: (e, s) => const Text('Erreur chargement'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLightningStatus() {
    return Center(
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        borderRadius: 20,
        opacity: 0.05,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: LiquidGlassTheme.accent,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: LiquidGlassTheme.accent, blurRadius: 10, spreadRadius: 2)],
              ),
            ),
            const SizedBox(width: 10),
            const Text('Réseau Lightning connecté', style: TextStyle(color: Colors.white60, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _quickActionButton(
            context,
            'Envoyer',
            Icons.north_east,
            Colors.white,
            Colors.black,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SendPaymentScreen())),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _quickActionButton(
            context,
            'Recevoir',
            Icons.south_west,
            Colors.white10,
            Colors.white,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceivePaymentScreen())),
          ),
        ),
      ],
    );
  }

  Widget _quickActionButton(BuildContext context, String label, IconData icon, Color bgColor, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap();
      },
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: bgColor,
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Transactions 30 jours', style: TextStyle(fontWeight: FontWeight.w600)),
              const Icon(Icons.equalizer, size: 20, color: Colors.white60),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(12, (index) {
                final height = [40.0, 60.0, 30.0, 80.0, 100.0, 50.0, 70.0, 40.0, 20.0, 60.0, 45.0, 85.0][index];
                final isHighlight = index == 4;
                return Container(
                  width: 14,
                  height: height,
                  decoration: BoxDecoration(
                    color: isHighlight ? LiquidGlassTheme.accent : Colors.white10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total dépensé', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  Text('\$412.00', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Fréquence', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  Text('Élevée', style: TextStyle(color: LiquidGlassTheme.accent.withValues(alpha: 0.8), fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      borderRadius: 24,
      opacity: 0.15,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.person, isActive: true, onTap: () {}),
          _navItem(Icons.search, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()))),
          _navItem(Icons.payments, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PayMenuScreen()))),
          _navItem(Icons.settings, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, {bool isActive = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isActive ? Colors.black : Colors.white60, size: 28),
      ),
    );
  }
}
