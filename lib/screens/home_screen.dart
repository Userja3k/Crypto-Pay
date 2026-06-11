import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
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
import 'pay_menu_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  final PageController _statsPageController = PageController();
  int _currentStatsPage = 0;
  late AnimationController _reflectionController;

  @override
  void initState() {
    super.initState();
    _reflectionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    _statsPageController.dispose();
    super.dispose();
  }

  void _triggerHaptic() {
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, authState),
              const SizedBox(height: 32),
              _buildBalanceCard(context),
              const SizedBox(height: 16),
              _buildLightningStatus(),
              const SizedBox(height: 32),
              _buildQuickActions(context),
              const SizedBox(height: 32),
              _buildSlidingStats(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
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
                _triggerHaptic();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
              child: GlassContainer(
                shape: BoxShape.circle,
                padding: const EdgeInsets.all(2),
                opacity: 0.15,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.transparent,
                  child: ClipOval(
                    child: Image.network(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuDwzUbqC4QgFkWcZCWJaw-nVRdq2IySRgc5dSCC2OLP1S7EqhURwsuQIBNOujaG11As66OFxvTBoxhYi-Glg3Z9EQWVFwPLRgCsszmFC7GVbovRwmmRF6fdVAZKaB97wyNTKqrW3jCzw9UH1HurXoYA-DsbqTRfzA71mkED36rW2CGpbnzZDQOb5RRGAkm6GYCZ--rBFD0V-EziDb2Y4Ovu88npZnchalO-5W2-EI8cEoZpmNCUPC8a__cP-S4h4976tNyMS9keyKs',
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white),
                    ),
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
              onPressed: () {
                _triggerHaptic();
              },
              icon: const Icon(Icons.notifications_outlined, size: 28),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: LiquidGlassTheme.error,
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

  Widget _buildBalanceCard(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userId = authState.user?['user_id'] ?? '';
    final balanceAsync = ref.watch(userBalanceProvider(userId));

    return AnimatedBuilder(
      animation: _reflectionController,
      builder: (context, child) {
        return GlassContainer(
          padding: const EdgeInsets.all(28),
          borderRadius: 32,
          opacity: 0.12,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1 + 0.05 * math.sin(_reflectionController.value * 2 * math.pi))),
          child: balanceAsync.when(
            data: (data) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('USD Balance', style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 0.5)),
                const SizedBox(height: 12),
                Text(
                  '\$${data['balance_usd']?.toStringAsFixed(2) ?? '0.00'}',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 44),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '≈ ${data['balance_sats']?.toString() ?? '0'} sats',
                      style: const TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: LiquidGlassTheme.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.trending_up, size: 14, color: LiquidGlassTheme.accent),
                          SizedBox(width: 4),
                          Text('+2.4%', style: TextStyle(color: LiquidGlassTheme.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (err, stack) => Text('Erreur: $err', style: const TextStyle(color: LiquidGlassTheme.error)),
          ),
        );
      },
    );
  }

  Widget _buildLightningStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: LiquidGlassTheme.accent,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: LiquidGlassTheme.accent, blurRadius: 8, spreadRadius: 1)],
          ),
        ),
        const SizedBox(width: 10),
        const Text('Réseau Lightning connecté', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassButton(
            onPressed: () {
              _triggerHaptic();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SendPaymentScreen()));
            },
            isPrimary: false,
            child: const Column(
              children: [
                CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.north_east, color: Colors.black)),
                SizedBox(height: 12),
                Text('Envoyer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GlassButton(
            onPressed: () {
              _triggerHaptic();
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceivePaymentScreen()));
            },
            isPrimary: false,
            child: const Column(
              children: [
                CircleAvatar(backgroundColor: Colors.white12, child: Icon(Icons.south_west, color: Colors.white)),
                SizedBox(height: 12),
                Text('Recevoir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlidingStats(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 240,
          child: PageView(
            controller: _statsPageController,
            onPageChanged: (i) {
              _triggerHaptic();
              setState(() => _currentStatsPage = i);
            },
            children: [
              _buildStatsCard(context),
              _buildRecentTransactionsCard(context),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _currentStatsPage == index ? 24 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _currentStatsPage == index ? Colors.white : Colors.white24,
            ),
          )),
        ),
      ],
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
              const Text('Transactions 30 jours', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 16)),
              Icon(Icons.equalizer, color: Colors.white.withValues(alpha: 0.5)),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(12, (index) {
                final height = [40.0, 60.0, 30.0, 80.0, 100.0, 50.0, 70.0, 40.0, 20.0, 60.0, 45.0, 85.0][index];
                final isHighlight = index == 4;
                return AnimatedContainer(
                  duration: Duration(milliseconds: 500 + index * 50),
                  curve: Curves.easeOutBack,
                  width: 14,
                  height: height * 0.8,
                  decoration: BoxDecoration(
                    color: isHighlight ? LiquidGlassTheme.accent : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          const Spacer(),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total dépensé', style: TextStyle(color: Colors.white38, fontSize: 14)),
              Text('\$412.00', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsCard(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dernières transactions', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 20),
          _transactionItem('Papa', '+50\$', LiquidGlassTheme.accent, Icons.add_circle_outline),
          _transactionItem('Maman', '+20\$', LiquidGlassTheme.accent, Icons.add_circle_outline),
          _transactionItem('Boutique', '-5\$', Colors.white38, Icons.remove_circle_outline),
          const Spacer(),
          Center(
            child: TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionHistoryScreen())),
              child: const Text('Voir tout l\'historique', style: TextStyle(color: LiquidGlassTheme.accent, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _transactionItem(String name, String amount, Color amountColor, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: amountColor.withValues(alpha: 0.5), size: 20),
          const SizedBox(width: 12),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 16)),
          const Spacer(),
          Text(amount, style: TextStyle(color: amountColor, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 34),
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(context, Icons.person_outline, isActive: true, destination: const HomeScreen()),
          _navItem(context, Icons.search, destination: const SearchScreen()),
          _navItem(context, Icons.credit_card, destination: const PayMenuScreen()),
          _navItem(context, Icons.settings_outlined, destination: const SettingsScreen()),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, {bool isActive = false, required Widget destination}) {
    return GestureDetector(
      onTap: () {
        _triggerHaptic();
        if (!isActive) Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
      },
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(12),
        opacity: isActive ? 0.2 : 0,
        border: isActive ? null : Border.all(color: Colors.transparent),
        child: Icon(icon, color: isActive ? Colors.white : Colors.white38, size: 26),
      ),
    );
  }
}
