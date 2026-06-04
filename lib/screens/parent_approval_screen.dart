import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../providers/user_provider.dart';

class ParentApprovalScreen extends ConsumerStatefulWidget {
  const ParentApprovalScreen({super.key});

  @override
  ConsumerState<ParentApprovalScreen> createState() => _ParentApprovalScreenState();
}

class _ParentApprovalScreenState extends ConsumerState<ParentApprovalScreen> {
  bool _isLoading = false;
  late Future<List<Map<String, dynamic>>> _approvalsFuture;

  @override
  void initState() {
    super.initState();
    _refreshApprovals();
  }

  void _refreshApprovals() {
    final authState = ref.read(authProvider);
    _approvalsFuture = ref.read(supabaseServiceProvider).getPendingApprovals(authState.user?['user_id'] ?? '');
  }

  Future<void> _handleApproval(String approvalId, bool approve) async {
    setState(() => _isLoading = true);
    try {
      final authState = ref.read(authProvider);
      await ref.read(supabaseServiceProvider).approveTransaction(
        authState.user?['user_id'] ?? '',
        approvalId,
        approve,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(approve ? 'Approuvé !' : 'Rejeté.')));
        setState(() {
          _refreshApprovals();
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userId = authState.user?['user_id'] ?? '';

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Approbations')),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _approvalsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.white));
            final approvals = snapshot.data ?? [];
            if (approvals.isEmpty) return const Center(child: Text('Aucune demande en attente', style: TextStyle(color: Colors.white54)));

            return ListView.builder(
              padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
              itemCount: approvals.length,
              itemBuilder: (context, index) {
                final app = approvals[index];
                return GlassContainer(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text('Demande de paiement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('\$${app['amount_usd'].toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: GlassButton(onPressed: () => _handleApproval(app['id'], true), child: const Text('Approuver'))),
                          const SizedBox(width: 12),
                          Expanded(child: GlassButton(isPrimary: false, onPressed: () => _handleApproval(app['id'], false), child: const Text('Refuser'))),
                        ],
                      )
                    ],
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
