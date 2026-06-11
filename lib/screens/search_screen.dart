import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
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
      final service = ref.read(supabaseServiceProvider);
      final results = await service.searchUsers(value);
      setState(() => _results = results);
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text('Recherche Universelle', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 12),
              const Text('Envoyez à n\'importe qui, sans connaître son adresse.', style: TextStyle(color: Colors.white38, fontSize: 14)),
              const SizedBox(height: 32),
              GlassContainer(
                borderRadius: 24,
                opacity: 0.1,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearch,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: 'Nom, email, ou CP-ID...',
                    hintStyle: TextStyle(color: Colors.white30),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: LiquidGlassTheme.accent),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: LiquidGlassTheme.accent))
              else
                Expanded(
                  child: _results.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final user = _results[index];
                      return GlassContainer(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(8),
                        borderRadius: 20,
                        opacity: 0.05,
                        child: ListTile(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.push(context, MaterialPageRoute(builder: (_) => SendPaymentScreen(initialDestination: user['email'] ?? user['phone'])));
                          },
                          leading: GlassContainer(
                            shape: BoxShape.circle,
                            padding: const EdgeInsets.all(10),
                            opacity: 0.1,
                            child: const Icon(Icons.person, color: Colors.white70, size: 20),
                          ),
                          title: Text(user['full_name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          subtitle: Text(user['email'] ?? user['phone'], style: const TextStyle(color: Colors.white38, fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('UTILISATEURS RÉCENTS', style: TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 20),
        const Center(
          child: Opacity(
            opacity: 0.3,
            child: Column(
              children: [
                Icon(Icons.history, size: 48, color: Colors.white24),
                SizedBox(height: 12),
                Text('Pas de recherches récentes', style: TextStyle(color: Colors.white38, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
