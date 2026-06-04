import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../providers/user_provider.dart';

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userId = authState.user?['user_id'] ?? '';

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Historique')),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: ref.read(supabaseServiceProvider).getTransactionHistory(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            if (snapshot.hasError) {
              return Center(child: Text('Erreur: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
            }

            final transactions = snapshot.data ?? [];
            if (transactions.isEmpty) {
              return const Center(child: Text('Aucune transaction', style: TextStyle(color: Colors.white54)));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final isIncoming = tx['is_incoming'] == true;
                final date = DateTime.parse(tx['created_at']);

                return GlassContainer(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  borderRadius: 16,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isIncoming ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                      child: Icon(
                        isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isIncoming ? Colors.green : Colors.red,
                        size: 20,
                      ),
                    ),
                    title: Text(tx['counterparty_name'] ?? 'Inconnu', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(DateFormat('dd MMM, HH:mm').format(date), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    trailing: Text(
                      '${isIncoming ? "+" : "-"}\$${tx['amount_usd'].toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isIncoming ? Colors.green : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
