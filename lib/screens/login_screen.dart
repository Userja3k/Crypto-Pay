import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../core/utils/security_utils.dart';
import '../services/haptic_service.dart';
import '../providers/user_provider.dart';
import '../core/utils/ui_utils.dart';
import 'home_screen.dart';
import 'password_recovery_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _biometricsEnabled = false;
  String _biometricType = 'face_id'; // 'face_id' or 'fingerprint'

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometricsEnabled = prefs.getBool('biometrics_enabled') ?? false;
      _biometricType = prefs.getString('biometric_type') ?? 'face_id';
      
      // Seed default email for ease of test if biometrics is enabled
      if (_biometricsEnabled) {
        _emailController.text = prefs.getString('biometric_email') ?? '';
      }
    });
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      UIUtils.showErrorDialog(context, 'Veuillez remplir tous les champs');
      return;
    }

    setState(() => _isLoading = true);
    HapticService.selection();

    try {
      // 1. Get Salt
      final salt = await ref.read(supabaseServiceProvider).getUserSalt(email);
      
      if (salt == null) {
        if (mounted) {
          UIUtils.showErrorDialog(context, 'Utilisateur non trouvé');
        }
        return;
      }

      // 2. Hash Password (stored in pinHash)
      final passwordHash = SecurityUtils.hashPin(password, salt: salt);

      // 3. Verify Login
      final result = await ref.read(supabaseServiceProvider).verifyLogin(
        identifier: email,
        pinHash: passwordHash,
      );

      if (result['is_valid'] == true) {
        HapticService.success();
        
        // Save for biometrics if enabled
        if (_biometricsEnabled) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('biometric_email', email);
          await prefs.setString('biometric_password', password);
        }

        ref.read(authProvider.notifier).login(result);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        if (mounted) {
          UIUtils.showErrorDialog(context, result['message'] ?? "Identifiants incorrects");
        }
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showErrorDialog(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleBiometricLogin() async {
    HapticService.medium();
    
    // Show a beautiful biometric scan dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: Colors.black.withValues(alpha: 0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Colors.white12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  Icon(
                    _biometricType == 'face_id' ? Icons.face_retouching_natural : Icons.fingerprint,
                    size: 72,
                    color: LiquidGlassTheme.accent,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _biometricType == 'face_id' ? 'Vérification Face ID' : 'Vérification de l\'empreinte',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Veuillez scanner pour vous connecter',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60),
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(color: LiquidGlassTheme.accent),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Simulate authenticating
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    Navigator.pop(context); // Close dialog

    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('biometric_email') ?? '';
    final savedPassword = prefs.getString('biometric_password') ?? '';

    _emailController.text = savedEmail;
    _passwordController.text = savedPassword;
    
    _handleLogin();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('Connexion', style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 40)),
              const SizedBox(height: 8),
              const Text('Connectez-vous pour accéder à vos fonds.', style: TextStyle(color: Colors.white60, fontSize: 16)),
              const SizedBox(height: 36),
              
              if (_biometricsEnabled) ...[
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _handleBiometricLogin,
                        child: GlassContainer(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          borderRadius: 20,
                          opacity: 0.1,
                          border: Border.all(color: LiquidGlassTheme.accent.withValues(alpha: 0.3)),
                          child: Row(
                            children: [
                              Icon(
                                _biometricType == 'face_id' ? Icons.face_retouching_natural : Icons.fingerprint,
                                color: LiquidGlassTheme.accent,
                              ),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  _biometricType == 'face_id'
                                      ? '🔒 Se connecter avec Face ID'
                                      : '🔒 Se connecter avec l\'empreinte digitale',
                                  style: const TextStyle(
                                    color: LiquidGlassTheme.accent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Row(
                        children: [
                          Expanded(child: Divider(color: Colors.white10)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('ou par email', style: TextStyle(color: Colors.white24, fontSize: 12)),
                          ),
                          Expanded(child: Divider(color: Colors.white10)),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
              
              _buildTextField('Email', _emailController, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField(
                'Mot de passe', 
                _passwordController, 
                icon: Icons.lock_outline, 
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white38,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 12),
              
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    HapticService.selection();
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PasswordRecoveryScreen()));
                  },
                  child: const Text(
                    'Mot de passe oublié ?', 
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: LiquidGlassTheme.accent))
              else
                GlassButton(
                  onPressed: _handleLogin,
                  child: const Text('Connexion'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {IconData? icon, bool obscureText = false, TextInputType? keyboardType, Widget? suffixIcon}) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 16,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white60),
          border: InputBorder.none,
          icon: icon != null ? Icon(icon, color: LiquidGlassTheme.accent) : null,
          suffixIcon: suffixIcon,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
