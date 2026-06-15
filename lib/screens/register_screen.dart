import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/glass_button.dart';
import '../core/utils/security_utils.dart';
import '../services/haptic_service.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isMinor = false;
  bool _isLoading = false;

  // Step 1: Personal Info
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  DateTime? _selectedBirthDate;
  String? _selectedSex;
  final _countryController = TextEditingController(text: 'RDC');
  final _cityController = TextEditingController();

  // Step 2: Identity Verification
  String _selectedDocumentType = 'Carte nationale';
  bool _rectoUploaded = false;
  bool _rectoUploading = false;
  bool _versoUploaded = false;
  bool _versoUploading = false;
  bool _selfieUploaded = false;
  bool _selfieUploading = false;

  // Step 3A: Parent approval (Minors only)
  final _parentEmailController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  bool _approvalRequestSent = false;
  bool _approvalApprovedByParent = false;
  final _approvalCodeController = TextEditingController();
  final String _correctApprovalCode = '729381';

  // Step 3 (Adult) / 4 (Minor): Security
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _useBiometrics = true;

  // Step 4 (Adult) / 5 (Minor): Finalisation
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptTerms = false;
  bool _acceptPrivacy = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _birthDateController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _parentEmailController.dispose();
    _parentPhoneController.dispose();
    _approvalCodeController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  int get _totalSteps => _isMinor ? 5 : 4;

  void _nextStep() {
    HapticService.selection();
    if (_currentStep < _totalSteps - 1) {
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

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _simulateUpload(String type) async {
    HapticService.light();
    setState(() {
      if (type == 'recto') _rectoUploading = true;
      if (type == 'verso') _versoUploading = true;
      if (type == 'selfie') _selfieUploading = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        if (type == 'recto') {
          _rectoUploading = false;
          _rectoUploaded = true;
        }
        if (type == 'verso') {
          _versoUploading = false;
          _versoUploaded = true;
        }
        if (type == 'selfie') {
          _selfieUploading = false;
          _selfieUploaded = true;
        }
      });
      HapticService.success();
    }
  }

  Future<void> _submitRegistration() async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
      );
      return;
    }
    if (!_acceptTerms || !_acceptPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez accepter les conditions et politiques')),
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticService.medium();

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final fullName = _nameController.text.trim();
      
      // Auto-generate unique mock phone number
      final randomSuffix = (math.Random().nextInt(900000000) + 100000000).toString();
      final mockPhone = '+243$randomSuffix';

      final pinSalt = DateTime.now().millisecondsSinceEpoch.toString();
      final passwordHash = SecurityUtils.hashPin(password, salt: pinSalt);

      // Register via database (using the password hash as pinHash so verifyLogin works)
      final result = await ref.read(supabaseServiceProvider).registerUser(
        email: email,
        phone: mockPhone,
        fullName: fullName,
        birthDate: _selectedBirthDate!,
        pinHash: passwordHash,
        pinSalt: pinSalt,
        userRole: _isMinor ? 'child' : 'adult',
      );

      if (result['user_id'] != null) {
        // Save biometrics choice
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('biometrics_enabled', _useBiometrics);
        await prefs.setString('biometric_type', isIOS ? 'face_id' : 'fingerprint');
        if (_useBiometrics) {
          await prefs.setString('biometric_email', email);
          await prefs.setString('biometric_password', password);
        }

        HapticService.success();

        // Perform login
        final loggedUser = {
          'user_id': result['user_id'],
          'full_name': fullName,
          'email': email,
          'user_role': _isMinor ? 'child' : 'adult',
          'kyc_level': 'basic',
        };
        await ref.read(authProvider.notifier).login(loggedUser);

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: ${result['message'] ?? "Inscription échouée"}')),
          );
        }
      }
    } catch (e) {
      // Offline fallback for testing
      HapticService.success();
      final email = _emailController.text.trim();
      final fullName = _nameController.text.trim();
      
      // Save biometrics choice
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometrics_enabled', _useBiometrics);
      await prefs.setString('biometric_type', isIOS ? 'face_id' : 'fingerprint');
      if (_useBiometrics) {
        await prefs.setString('biometric_email', email);
        await prefs.setString('biometric_password', _passwordController.text.trim());
      }

      final mockUser = {
        'user_id': 'mock-id-${DateTime.now().millisecondsSinceEpoch}',
        'full_name': fullName,
        'email': email,
        'user_role': _isMinor ? 'child' : 'adult',
        'kyc_level': 'basic',
      };
      await ref.read(authProvider.notifier).login(mockUser);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: _currentStep > 0 ? _previousStep : () => Navigator.pop(context),
        ),
        title: Text(
          'Étape ${_currentStep + 1} de $_totalSteps',
          style: const TextStyle(fontSize: 16, color: Colors.white54),
        ),
        centerTitle: true,
      ),
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
                  _buildIdentityVerificationStep(),
                  if (_isMinor) _buildParentalApprovalStep(),
                  _buildSecurityStep(),
                  _buildFinalisationStep(),
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
      padding: const EdgeInsets.symmetric(horizontal: LiquidGlassTheme.marginPage, vertical: 8),
      child: Row(
        children: List.generate(_totalSteps, (index) {
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
                  _isMinor = _calculateAge(date) < 18;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          
          _buildSexDropdown(),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(child: _buildTextField('Pays', _countryController, icon: Icons.public)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField('Ville', _cityController, icon: Icons.location_city)),
            ],
          ),
          const SizedBox(height: 48),
          
          GlassButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty && 
                  _selectedBirthDate != null && 
                  _countryController.text.isNotEmpty && 
                  _cityController.text.isNotEmpty) {
                _nextStep();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez remplir les informations requises')),
                );
              }
            },
            child: const Text('Suivant'),
          ),
        ],
      ),
    );
  }

  Widget _buildSexDropdown() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderRadius: 16,
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          initialValue: _selectedSex,
          hint: const Text('Sexe (optionnel)', style: TextStyle(color: Colors.white60)),
          dropdownColor: const Color(0xFF131313),
          decoration: const InputDecoration(
            border: InputBorder.none,
            icon: Icon(Icons.wc, color: LiquidGlassTheme.accent),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 16),
          items: ['Homme', 'Femme', 'Autre']
              .map((label) => DropdownMenuItem(
                    value: label,
                    child: Text(label),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedSex = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildIdentityVerificationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vérification d\'identité', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          const Text('Choisissez une pièce et importez les photos.', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 24),
          
          _buildDocumentTypeSelector(),
          const SizedBox(height: 28),
          
          _buildUploadBox('Recto du document', _rectoUploaded, _rectoUploading, () => _simulateUpload('recto')),
          const SizedBox(height: 16),
          _buildUploadBox('Verso du document', _versoUploaded, _versoUploading, () => _simulateUpload('verso')),
          const SizedBox(height: 16),
          _buildUploadBox('Prendre un Selfie', _selfieUploaded, _selfieUploading, () => _simulateUpload('selfie')),
          
          const SizedBox(height: 40),
          
          GlassButton(
            onPressed: () {
              if (_rectoUploaded && _versoUploaded && _selfieUploaded) {
                _nextStep();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez importer tous les documents requis')),
                );
              }
            },
            child: const Text('Vérifier'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTypeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: ['Carte nationale', 'Passeport', 'Permis'].map((type) {
        final isSelected = _selectedDocumentType == type || 
            (type == 'Permis' && _selectedDocumentType == 'Permis de conduire');
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedDocumentType = type == 'Permis' ? 'Permis de conduire' : type;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? LiquidGlassTheme.accent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? LiquidGlassTheme.accent : Colors.white10,
                ),
              ),
              child: Text(
                type,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? LiquidGlassTheme.accent : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUploadBox(String label, bool isUploaded, bool isUploading, VoidCallback onTap) {
    return GestureDetector(
      onTap: isUploaded || isUploading ? null : onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        opacity: 0.05,
        child: Row(
          children: [
            Icon(
              isUploaded 
                  ? Icons.check_circle 
                  : (isUploading ? Icons.hourglass_empty : Icons.cloud_upload_outlined),
              color: isUploaded ? LiquidGlassTheme.accent : Colors.white54,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(
                    isUploaded 
                        ? 'Document importé avec succès ✓' 
                        : (isUploading ? 'Chargement en cours...' : 'Cliquez pour sélectionner un fichier'),
                    style: TextStyle(
                      color: isUploaded ? LiquidGlassTheme.accent : Colors.white38, 
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isUploading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: LiquidGlassTheme.accent),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentalApprovalStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Autorisation parentale', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          const Text('Un compte mineur doit être approuvé par un parent.', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 28),
          
          _buildTextField('Email du parent', _parentEmailController, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _buildTextField('Numéro Crypto-Pay du parent', _parentPhoneController, icon: Icons.phone, keyboardType: TextInputType.phone),
          const SizedBox(height: 24),
          
          if (!_approvalRequestSent)
            GlassButton(
              onPressed: () {
                if (_parentEmailController.text.isNotEmpty && _parentPhoneController.text.isNotEmpty) {
                  setState(() {
                    _approvalRequestSent = true;
                  });
                  HapticService.medium();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez remplir les coordonnées du parent')),
                  );
                }
              },
              child: const Text('Envoyer la demande'),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.phone_iphone, color: LiquidGlassTheme.accent, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Simulation : Téléphone du parent',
                        style: TextStyle(fontWeight: FontWeight.bold, color: LiquidGlassTheme.accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Demande de parrainage reçue !\nNom : ${_nameController.text}\nÂge : ${_selectedBirthDate != null ? _calculateAge(_selectedBirthDate!) : 15} ans',
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  if (!_approvalApprovedByParent)
                    Row(
                      children: [
                        Expanded(
                          child: GlassButton(
                            isPrimary: false,
                            onPressed: () {
                              HapticService.light();
                              setState(() {
                                _approvalRequestSent = false;
                              });
                            },
                            child: const Text('Refuser', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GlassButton(
                            onPressed: () {
                              HapticService.success();
                              setState(() {
                                _approvalApprovedByParent = true;
                              });
                            },
                            child: const Text('Accepter'),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    const Text(
                      'Demande acceptée par le parent !',
                      style: TextStyle(color: LiquidGlassTheme.accent, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Code généré : $_correctApprovalCode',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 4, color: LiquidGlassTheme.accent),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
            _buildTextField(
              'Code d\'autorisation parentale',
              _approvalCodeController,
              icon: Icons.vpn_key_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            GlassButton(
              onPressed: () {
                if (_approvalCodeController.text.trim() == _correctApprovalCode) {
                  _nextStep();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code incorrect. Entrez le code 729381 généré par le parent.')),
                  );
                }
              },
              child: const Text('Suivant'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecurityStep() {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final biometricLabel = isIOS ? 'Utiliser Face ID' : 'Utiliser l\'empreinte digitale';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sécurisez votre compte', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          const Text('Créez un PIN à 6 chiffres pour les validations.', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 32),
          
          _buildTextField(
            'PIN à 6 chiffres',
            _pinController,
            icon: Icons.lock_outline,
            obscureText: true,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Confirmation PIN',
            _confirmPinController,
            icon: Icons.lock_outline,
            obscureText: true,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 32),
          
          CheckboxListTile(
            value: _useBiometrics,
            title: Text(biometricLabel, style: const TextStyle(color: Colors.white70)),
            activeColor: LiquidGlassTheme.accent,
            checkColor: Colors.black,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(() {
                _useBiometrics = val ?? false;
              });
            },
          ),
          const SizedBox(height: 48),
          
          GlassButton(
            onPressed: () {
              final pin = _pinController.text.trim();
              final cpin = _confirmPinController.text.trim();
              if (pin.length == 6 && pin == cpin) {
                _nextStep();
              } else if (pin.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Le code PIN doit comporter 6 chiffres')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Les codes PIN ne correspondent pas')),
                );
              }
            },
            child: const Text('Suivant'),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalisationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(LiquidGlassTheme.marginPage),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Finalisation', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          const Text('Terminez la création de votre compte sécurisé.', style: TextStyle(color: Colors.white60)),
          const SizedBox(height: 32),
          
          _buildTextField('Email', _emailController, icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _buildTextField('Mot de passe', _passwordController, icon: Icons.lock_outline, obscureText: true),
          const SizedBox(height: 16),
          _buildTextField('Confirmation du mot de passe', _confirmPasswordController, icon: Icons.lock_outline, obscureText: true),
          
          const SizedBox(height: 24),
          
          CheckboxListTile(
            value: _acceptTerms,
            title: const Text('J\'accepte les conditions d\'utilisation', style: TextStyle(color: Colors.white60, fontSize: 13)),
            activeColor: LiquidGlassTheme.accent,
            checkColor: Colors.black,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(() {
                _acceptTerms = val ?? false;
              });
            },
          ),
          CheckboxListTile(
            value: _acceptPrivacy,
            title: const Text('J\'accepte la politique de confidentialité', style: TextStyle(color: Colors.white60, fontSize: 13)),
            activeColor: LiquidGlassTheme.accent,
            checkColor: Colors.black,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              setState(() {
                _acceptPrivacy = val ?? false;
              });
            },
          ),
          
          const SizedBox(height: 36),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: LiquidGlassTheme.accent))
          else
            GlassButton(
              onPressed: _submitRegistration,
              child: const Text('Créer mon compte'),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    IconData? icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      borderRadius: 16,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
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
}
