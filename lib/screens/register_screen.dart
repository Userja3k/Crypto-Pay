import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../core/utils/security_utils.dart';
import '../services/haptic_service.dart';
import '../providers/user_provider.dart';
import 'recovery_phrase_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Personal Info
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  DateTime? _selectedBirthDate;

  // Step 2: Security (PIN)
  String _pin = '';
  String _confirmPin = '';

  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  void _nextStep() {
    HapticService.selection();
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    HapticService.selection();
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitRegistration() async {
    if (_pin != _confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les codes PIN ne correspondent pas')),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticService.medium();

    try {
      final pinSalt = DateTime.now().millisecondsSinceEpoch.toString();
      final pinHash = SecurityUtils.hashPin(_pin, salt: pinSalt);

      final result = await ref.read(supabaseServiceProvider).registerUser(
        email: _emailController.text,
        phone: _phoneController.text,
        fullName: _nameController.text,
        birthDate: _selectedBirthDate!,
        pinHash: pinHash,
        pinSalt: pinSalt,
      );

      if (result['user_id'] != null) {
        HapticService.success();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => RecoveryPhraseScreen(userId: result['user_id']),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${result['message']}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _buildPersonalInfoStep(),
                  _buildSecurityStep(),
                  _buildReviewStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isActive ? LiquidGlassTheme.accent : Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Informations personnelles', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          const Text('Commençons par faire connaissance.', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 32),
          _buildTextField('Nom complet', _nameController, icon: Icons.person_outline),
          const SizedBox(height: 16),
          _buildTextField('Email', _emailController, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _buildTextField('Téléphone (WhatsApp)', _phoneController, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          _buildTextField(
            'Date de naissance',
            _birthDateController,
            icon: Icons.calendar_today_outlined,
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _selectedBirthDate = date;
                  _birthDateController.text = "${date.day}/${date.month}/${date.year}";
                });
              }
            },
          ),
          const SizedBox(height: 48),
          GlassButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty && _emailController.text.isNotEmpty && _selectedBirthDate != null) {
                _nextStep();
              }
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityStep() {
    return Padding(
      padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sécurité du compte', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          const Text('Créez un code PIN pour sécuriser vos transactions.', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 32),
          _buildTextField(
            'Créer un PIN (6 chiffres)',
            TextEditingController(text: _pin),
            icon: Icons.lock_outline,
            obscureText: true,
            keyboardType: TextInputType.number,
            onChanged: (v) => _pin = v,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Confirmer le PIN',
            TextEditingController(text: _confirmPin),
            icon: Icons.lock_outline,
            obscureText: true,
            keyboardType: TextInputType.number,
            onChanged: (v) => _confirmPin = v,
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  isPrimary: false,
                  onPressed: _previousStep,
                  child: const Text('Retour'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GlassButton(
                  onPressed: () {
                    if (_pin.length >= 4 && _pin == _confirmPin) {
                      _nextStep();
                    }
                  },
                  child: const Text('Suivant'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return Padding(
      padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Récapitulatif', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 32),
          _buildInfoRow('Nom', _nameController.text),
          _buildInfoRow('Email', _emailController.text),
          _buildInfoRow('Téléphone', _phoneController.text),
          _buildInfoRow('Date de naissance', _birthDateController.text),
          const Spacer(),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: LiquidGlassTheme.accent))
          else
            Column(
              children: [
                GlassButton(
                  onPressed: _submitRegistration,
                  child: const Text('Confirmer l\'inscription'),
                ),
                const SizedBox(height: 16),
                GlassButton(
                  isPrimary: false,
                  onPressed: _previousStep,
                  child: const Text('Modifier'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {
    IconData? icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    Function(String)? onChanged,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 16,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
          border: InputBorder.none,
          icon: icon != null ? Icon(icon, color: LiquidGlassTheme.accent) : null,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
