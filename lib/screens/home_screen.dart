import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../providers/user_provider.dart';
import '../services/haptic_service.dart';
import 'notification_screen.dart';
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

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final userName = user?['full_name']?.split(' ')[0] ?? 'Jean';

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background Orbs for premium visual feel
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
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(),
                ),
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
                  _buildHeader(context, userName),
                  const SizedBox(height: 28),
                  _buildBalanceCard(context, authState),
                  const SizedBox(height: 28),
                  _buildQuickActions(context),
                  const SizedBox(height: 36),
                  _buildSlidableStats(context, authState),
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

  Widget _buildHeader(BuildContext context, String userName) {
    final notifications = ref.watch(notificationsProvider);
    final unreadCount =
        notifications.where((n) => n['is_read'] == false).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  'Bonjour $userName',
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('👋', style: TextStyle(fontSize: 24)),
            ],
          ),
        ),
        Row(
          children: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded,
                      color: Colors.white, size: 28),
                  onPressed: () {
                    HapticService.selection();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationScreen()));
                  },
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                HapticService.selection();
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white12),
                  image: const DecorationImage(
                    image: NetworkImage(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuDwzUbqC4QgFkWcZCWJaw-nVRdq2IySRgc5dSCC2OLP1S7EqhURwsuQIBNOujaG11As66OFxvTBoxhYi-Glg3Z9EQWVFwPLRgCsszmFC7GVbovRwmmRF6fdVAZKaB97wyNTKqrW3jCzw9UH1HurXoYA-DsbqTRfzA71mkED36rW2CGpbnzZDQOb5RRGAkm6GYCZ--rBFD0V-EziDb2Y4Ovu88npZnchalO-5W2-EI8cEoZpmNCUPC8a__cP-S4h4976tNyMS9keyKs'),
                    fit: BoxFit.cover,
                  ),
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
    if (userId.isEmpty) {
      return _buildBalanceUI(context, 0.0, 0.0);
    }

    final balanceAsync = ref.watch(userBalanceProvider(userId));
    return balanceAsync.when(
      data: (data) {
        final double usd = (data['balance_usd'] as num?)?.toDouble() ?? 0.0;
        final double btc = usd / 70000.0;
        return _buildBalanceUI(context, usd, btc);
      },
      loading: () => const GlassContainer(
        padding: EdgeInsets.all(28),
        borderRadius: 24,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      error: (e, s) => _buildBalanceUI(context, 0.0, 0.0),
    );
  }

  Widget _buildBalanceUI(BuildContext context, double usd, double btc) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      opacity: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solde principal',
            style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Text(
            '\$${usd.toStringAsFixed(2)} USD',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '≈ ${btc.toStringAsFixed(4)} BTC',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
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
            Icons.arrow_upward_rounded,
            Colors.white,
            Colors.black,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SendPaymentScreen())),
            subtitle: 'Bluetooth / NFC',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _quickActionButton(
            context,
            'Recevoir',
            Icons.arrow_downward_rounded,
            Colors.white.withValues(alpha: 0.05),
            Colors.white,
            () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ReceivePaymentScreen())),
            subtitle: 'NFC / QR',
          ),
        ),
      ],
    );
  }

  Widget _quickActionButton(BuildContext context, String label, IconData icon,
      Color bgColor, Color iconColor, VoidCallback onTap,
      {String? subtitle}) {
    return GestureDetector(
      onTap: () {
        HapticService.light();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: iconColor.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSlidableStats(BuildContext context, AuthState authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 300,
          child: PageView(
            physics: const BouncingScrollPhysics(),
            children: [
              _buildStatsCard(context, authState),
              _buildRecentTransactions(context, authState),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: LiquidGlassTheme.accent, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context, AuthState authState) {
    final userId = authState.user?['user_id'] ?? '';
    final historyAsync = ref.watch(transactionHistoryProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transactions 7 jours',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        GlassContainer(
          padding: const EdgeInsets.all(20),
          borderRadius: 24,
          opacity: 0.05,
          child: SizedBox(
            height: 180,
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => const Center(
                  child: Text('Impossible de charger les statistiques',
                      style: TextStyle(color: Colors.white70))),
              data: (list) {
                // compute last 7 days counts
                final now = DateTime.now();
                final counts = List<int>.generate(7, (_) => 0);
                for (final tx in list) {
                  try {
                    final created = DateTime.parse(tx['created_at']);
                    final diff = now.difference(created).inDays;
                    if (diff >= 0 && diff < 7) counts[6 - diff] += 1;
                  } catch (_) {}
                }

                final maxCount = counts.reduce((a, b) => a > b ? a : b);
                final scale = maxCount > 0 ? (150 / maxCount) : 1.0;
                final stats = counts.map((c) => c * scale).toList();

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(stats.length, (index) {
                    return _buildBar(stats[index], false);
                  }),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBar(double targetHeight, bool isSelected) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: targetHeight),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutBack,
      builder: (context, height, child) {
        return Container(
          width: 30,
          height: height,
          decoration: BoxDecoration(
            color: isSelected
                ? LiquidGlassTheme.accent
                : LiquidGlassTheme.accent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: LiquidGlassTheme.accent.withValues(alpha: 0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
        );
      },
    );
  }

  Widget _buildRecentTransactions(BuildContext context, AuthState authState) {
    final userId = authState.user?['user_id'] ?? '';
    if (userId.isEmpty) {
      return _buildEmptyTransactionsUI();
    }

    final historyAsync = ref.watch(transactionHistoryProvider(userId));
    return historyAsync.when(
      data: (txList) {
        if (txList.isEmpty) {
          return _buildEmptyTransactionsUI();
        }
        final formattedTxs = txList.map((tx) {
          final isIncoming = tx['is_incoming'] == true;
          final double amount = (tx['amount_usd'] as num?)?.toDouble() ?? 0.0;
          return {
            'name': tx['counterparty_name'] ?? (isIncoming ? 'Reçu' : 'Envoyé'),
            'amount': isIncoming ? amount : -amount,
            'is_incoming': isIncoming,
          };
        }).toList();
        return _buildTransactionsListUI(formattedTxs);
      },
      loading: () => const Center(
          child: CircularProgressIndicator(color: LiquidGlassTheme.accent)),
      error: (e, s) => _buildEmptyTransactionsUI(),
    );
  }

  Widget _buildTransactionsListUI(List<Map<String, dynamic>> txs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transactions récentes',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        GlassContainer(
          padding: const EdgeInsets.symmetric(vertical: 8),
          borderRadius: 20,
          opacity: 0.05,
          child: Column(
            children: txs.map((tx) {
              final String name = tx['name'] as String;
              final double amount = tx['amount'] as double;
              final bool isIncoming = tx['is_incoming'] as bool;

              final sign = isIncoming ? '+' : '';
              final amountStr = '$sign${amount.toStringAsFixed(0)}\$';

              return Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isIncoming
                          ? LiquidGlassTheme.accent.withValues(alpha: 0.1)
                          : Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        isIncoming ? '←' : '→',
                        style: TextStyle(
                          color: isIncoming
                              ? LiquidGlassTheme.accent
                              : Colors.white70,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  trailing: Text(
                    amountStr,
                    style: TextStyle(
                      color:
                          isIncoming ? LiquidGlassTheme.accent : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTransactionsUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transactions récentes',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        GlassContainer(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          borderRadius: 20,
          opacity: 0.05,
          child: const Center(
            child: Text(
              'Aucune transaction disponible',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        ),
      ],
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
          _navItem(Icons.person_outline,
              isActive: true,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()))),
          _navItem(Icons.search,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()))),
          _navItem(Icons.credit_card,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PayMenuScreen()))),
          _navItem(Icons.settings_outlined,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon,
      {bool isActive = false, required VoidCallback onTap}) {
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
        child: Icon(icon,
            color: isActive ? Colors.black : Colors.white60, size: 28),
      ),
    );
  }
}
