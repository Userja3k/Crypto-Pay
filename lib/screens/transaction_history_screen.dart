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
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        title: const Text('Détails des Transactions', style: TextStyle(fontWeight: FontWeight.bold))
      ),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: ref.read(supabaseServiceProvider).getTransactionHistory(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            
            if (snapshot.hasError) {
              return Center(child: Text('Erreur: ${snapshot.error}', style: const TextStyle(color: LiquidGlassTheme.error)));
            }

            final transactions = snapshot.data ?? [];
            if (transactions.isEmpty) {
              return const Center(child: Text('Aucune transaction', style: TextStyle(color: Colors.white38)));
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
                  padding: const EdgeInsets.all(8),
                  borderRadius: 20,
                  opacity: 0.05,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isIncoming ? LiquidGlassTheme.accent : Colors.white).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isIncoming ? Icons.south_west : Icons.north_east,
                        color: isIncoming ? LiquidGlassTheme.accent : Colors.white70,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      tx['counterparty_name'] ?? (isIncoming ? 'Dépôt Lightning' : 'Envoi Lightning'), 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)
                    ),
                    subtitle: Text(
                      DateFormat('dd MMM yyyy, HH:mm').format(date), 
                      style: const TextStyle(color: Colors.white38, fontSize: 11)
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isIncoming ? "+" : "-"}\$${tx['amount_usd'].toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isIncoming ? LiquidGlassTheme.accent : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tx['status']?.toUpperCase() ?? 'COMPLETED',
                          style: TextStyle(
                            color: _getStatusColor(tx['status']),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5
                          ),
                        ),
                      ],
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

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed': return LiquidGlassTheme.accent;
      case 'pending': return Colors.orange;
      case 'failed': return LiquidGlassTheme.error;
      default: return Colors.white24;
    }
  }
}
