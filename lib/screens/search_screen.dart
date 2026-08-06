import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../providers/user_provider.dart';
import 'send_payment_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  void _onSearch(String value) async {
    if (value.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await ref.read(supabaseServiceProvider).searchUsers(value);
      setState(() => _results = results);
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Recherche universelle'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: 20,
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Nom, email, ou ID Crypto-Pay',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: LiquidGlassTheme.accent),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: LiquidGlassTheme.accent))
              : _results.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: LiquidGlassTheme.marginPage),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final user = _results[index];
                      return _buildUserResult(user);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          const Text('Recherchez vos amis ou commerçants', style: TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildUserResult(Map<String, dynamic> user) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: 20,
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SendPaymentScreen(
                    recipientId: user['id'],
                    recipientName: user['full_name'],
                  ),
                ),
              );
            },
            leading: CircleAvatar(
              backgroundColor: LiquidGlassTheme.accent.withValues(alpha: 0.2),
              child: Text(user['full_name'][0], style: const TextStyle(color: LiquidGlassTheme.accent)),
            ),
            title: Text(user['full_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(user['referral_code'] ?? 'CP-XXXX', style: const TextStyle(color: Colors.white38)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white24),
          ),
        ),
      ),
    );
  }
}
