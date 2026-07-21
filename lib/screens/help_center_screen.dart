import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../services/help_service.dart';

class HelpCenterScreen extends ConsumerStatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  ConsumerState<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends ConsumerState<HelpCenterScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  List<FaqItem> _faqs = [];

  @override
  void initState() {
    super.initState();
    _faqs = HelpService().getFaqs();
  }

  void _filter(String q) {
    setState(() {
      _query = q;
      if (q.isEmpty) {
        _faqs = HelpService().getFaqs();
      } else {
        _faqs = HelpService().getFaqs().where((f) => f.question.toLowerCase().contains(q.toLowerCase()) || f.answer.toLowerCase().contains(q.toLowerCase())).toList();
      }
    });
  }

  Future<void> _openHelpLink(String url) async {
    try {
      await HelpService().openHelpLink(url);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur ouverture lien : $error'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('Centre d\'aide')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: 16,
              child: TextField(controller: _searchController, onChanged: _filter, decoration: const InputDecoration(border: InputBorder.none, hintText: 'Rechercher...')),
            ),
          ),
          Expanded(
            child: _faqs.isEmpty ? const Center(child: Text('Aucune question', style: TextStyle(color: Colors.white38))) : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: LiquidGlassTheme.marginPage), itemCount: _faqs.length, itemBuilder: (c, i) => _faqItem(_faqs[i])),
          ),
          Padding(
            padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
            child: Row(
              children: [
                Expanded(
                  child: GlassButton(
                    onPressed: () async => await _openHelpLink(HelpService().getSupportUrl()),
                    child: const Text('Support'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassButton(
                    onPressed: () async => await _openHelpLink(HelpService().getDocumentationUrl()),
                    child: const Text('Doc.'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _faqItem(FaqItem faq) {
    return GlassContainer(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), borderRadius: 16, child: ExpansionTile(title: Text(faq.question, style: const TextStyle(color: Colors.white)), children: [Padding(padding: const EdgeInsets.all(12), child: Text(faq.answer, style: const TextStyle(color: Colors.white70)))]));
  }
}
