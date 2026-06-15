import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../providers/user_provider.dart';

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final historyAsync = ref.watch(transactionHistoryProvider(authState.user?['user_id'] ?? ''));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Historique'),
      ),
      body: historyAsync.when(
        data: (transactions) => transactions.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return _buildTransactionItem(context, tx);
              },
            ),
        loading: () => const Center(child: CircularProgressIndicator(color: LiquidGlassTheme.accent)),
        error: (e, s) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.white12),
          SizedBox(height: 16),
          Text('Aucune transaction trouvée', style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, Map<String, dynamic> tx) {
    final isIncoming = tx['is_incoming'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isIncoming ? LiquidGlassTheme.accent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIncoming ? Icons.south_west : Icons.north_east,
                color: isIncoming ? LiquidGlassTheme.accent : Colors.white70,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx['counterparty_name'] ?? (isIncoming ? 'Dépôt' : 'Paiement'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(tx['created_at'].toString().split(' ')[0], style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncoming ? '+' : '-'}\$${tx['amount_usd']}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isIncoming ? LiquidGlassTheme.accent : Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tx['status'] == 'completed' ? 'Confirmé' : 'En attente',
                  style: TextStyle(
                    color: tx['status'] == 'completed' ? Colors.white24 : Colors.orange,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
