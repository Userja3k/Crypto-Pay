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
              Text('Recherche Universelle', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 24),
              GlassContainer(
                borderRadius: 24,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearch,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Nom, email, ou CP-ID...',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: Colors.white))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final user = _results[index];
                      return GlassContainer(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(8),
                        borderRadius: 16,
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: Colors.white12, child: Icon(Icons.person, color: Colors.white)),
                          title: Text(user['full_name'], style: const TextStyle(color: Colors.white)),
                          subtitle: Text(user['email'] ?? user['phone'], style: const TextStyle(color: Colors.white54)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white24),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => SendPaymentScreen(initialDestination: user['email'] ?? user['phone'])));
                          },
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
}
