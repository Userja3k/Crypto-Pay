import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../providers/user_provider.dart';
import '../services/haptic_service.dart';

int usdToSats(double amountUsd) {
  return ((amountUsd / 70000.0) * 100000000).round();
}

class DepositScreen extends ConsumerStatefulWidget {
  const DepositScreen({super.key});

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;
  String? _lnurlUrl;
  String? _expiresAt;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitDeposit() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un montant valide.')),
      );
      return;
    }

    final authState = ref.read(authProvider);
    final userId = authState.user?['user_id'] as String?;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur non authentifié.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticService.medium();

    try {
      final result = await ref.read(supabaseServiceProvider).createLnurlPay(
        userId: userId,
        fixedAmountSats: usdToSats(amount),
        description: _noteController.text.isNotEmpty ? _noteController.text : 'Recharge Crypto-Pay',
        requiresComment: false,
        expiresInDays: 30,
      );

      final lnurlUrl = result['lnurl_url'] as String?;
      if (lnurlUrl != null && lnurlUrl.isNotEmpty) {
        HapticService.success();
        if (mounted) {
          setState(() {
            _lnurlUrl = lnurlUrl;
            _expiresAt = result['expires_at']?.toString();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lien de dépôt Lightning prêt à partager.')),
          );
        }
      } else {
        throw Exception(result['message'] ?? 'Impossible de générer le lien de dépôt.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de génération du lien : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _copyLink() async {
    if (_lnurlUrl == null) return;
    await Clipboard.setData(ClipboardData(text: _lnurlUrl!));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lien copié.')),
      );
    }
  }

  Future<void> _shareLink() async {
    if (_lnurlUrl == null) return;
    await Share.share(_lnurlUrl!);
  }

  Future<void> _openLink() async {
    if (_lnurlUrl == null) return;
    await launchUrl(Uri.parse(_lnurlUrl!), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Alimenter le compte'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
        child: _lnurlUrl == null
            ? _buildForm()
            : _buildGeneratedCard(),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Générez un lien de dépôt Lightning et partagez-le avec un payeur.',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 24),
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          borderRadius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Montant en USD', style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  prefixText: '\$ ',
                  prefixStyle: TextStyle(color: Colors.white54, fontSize: 22),
                  border: InputBorder.none,
                  hintText: '0.00',
                  hintStyle: TextStyle(color: Colors.white24),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          borderRadius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Description', style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Ex: Recharge via partenaire',
                  hintStyle: TextStyle(color: Colors.white24),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        _buildInfoCard(),
        const SizedBox(height: 32),
        GlassButton(
          onPressed: _isLoading ? null : _submitDeposit,
          child: Text(_isLoading ? 'Génération...' : 'Générer un lien de dépôt'),
        ),
      ],
    );
  }

  Widget _buildGeneratedCard() {
    final qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&margin=10&data=${Uri.encodeComponent(_lnurlUrl!)}';
    return Column(
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(20),
          borderRadius: 24,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  qrUrl,
                  width: 240,
                  height: 240,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.qr_code_2, size: 220, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Scannez ce QR ou partagez le lien pour déposer des fonds.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
              const SizedBox(height: 16),
              SelectableText(
                _lnurlUrl!,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              if (_expiresAt != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Valable jusqu’au $_expiresAt',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: GlassButton(
                onPressed: _copyLink,
                child: const Text('Copier'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassButton(
                onPressed: _shareLink,
                child: const Text('Partager'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassButton(
          onPressed: _openLink,
          child: const Text('Ouvrir le lien'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => setState(() {
            _lnurlUrl = null;
            _expiresAt = null;
          }),
          child: const Text('Créer un autre lien', style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderRadius: 24,
      opacity: 0.08,
      child: const Text(
        'Ce flux génère un lien LNURL/QR pour recevoir un paiement Lightning et créditer votre compte Crypto-Pay.',
        style: TextStyle(color: Colors.white54, height: 1.5),
      ),
    );
  }
}
