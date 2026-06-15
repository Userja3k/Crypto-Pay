import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../providers/user_provider.dart';
import '../services/haptic_service.dart';

class ParentApprovalScreen extends ConsumerStatefulWidget {
  const ParentApprovalScreen({super.key});

  @override
  ConsumerState<ParentApprovalScreen> createState() => _ParentApprovalScreenState();
}

class _ParentApprovalScreenState extends ConsumerState<ParentApprovalScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final approvalsAsync = ref.watch(pendingApprovalsProvider(authState.user?['user_id'] ?? ''));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Approbations en attente'),
      ),
      body: approvalsAsync.when(
        data: (approvals) => approvals.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
              itemCount: approvals.length,
              itemBuilder: (context, index) {
                final app = approvals[index];
                return _buildApprovalCard(app);
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
          Icon(Icons.check_circle_outline, size: 64, color: Colors.white12),
          SizedBox(height: 16),
          Text('Aucune demande en attente', style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(Map<String, dynamic> app) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Jean (Enfant)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('\$${app['amount_usd']}', style: const TextStyle(color: LiquidGlassTheme.accent, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Note: ${app['note'] ?? 'Paiement'}', style: const TextStyle(color: Colors.white60)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    isPrimary: false,
                    onPressed: () => _handleApproval(app['id'], false),
                    child: const Text('Refuser', style: TextStyle(color: LiquidGlassTheme.error)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassButton(
                    onPressed: () => _handleApproval(app['id'], true),
                    child: const Text('Approuver'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleApproval(String approvalId, bool approve) async {
    HapticService.selection();
    final authState = ref.read(authProvider);
    await ref.read(supabaseServiceProvider).approveTransaction(
      authState.user!['user_id'],
      approvalId,
      approve,
    );
    // Refresh
    ref.invalidate(pendingApprovalsProvider);
  }
}
