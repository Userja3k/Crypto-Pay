// lib/screens/payment_animation_screen.dart
// Écran avec animations pour NFC et Bluetooth

import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/widgets/glass_container.dart';
import '../core/widgets/wave_animation.dart';
import '../core/widgets/animated_icon_badge.dart';

enum PaymentAnimationType {
  sending,
  receiving,
  connecting,
  scanning,
  success,
  failure,
}

class PaymentAnimationScreen extends StatefulWidget {
  final PaymentAnimationType type;
  final PaymentTech tech;
  final String? title;
  final String? subtitle;
  final double? amount;
  final String? counterparty;
  final VoidCallback? onComplete;

  const PaymentAnimationScreen({
    super.key,
    required this.type,
    required this.tech,
    this.title,
    this.subtitle,
    this.amount,
    this.counterparty,
    this.onComplete,
  });

  @override
  State<PaymentAnimationScreen> createState() => _PaymentAnimationScreenState();
}

class _PaymentAnimationScreenState extends State<PaymentAnimationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  bool _showWave = false;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Déclenche la vague après l'apparition
    Future.delayed(const Duration(milliseconds: 400), () {
      setState(() => _showWave = true);
    });

    // Animation de succès
    if (widget.type == PaymentAnimationType.success) {
      Future.delayed(const Duration(milliseconds: 1500), () {
        setState(() => _showSuccess = true);
      });
    }

    // Auto-fermeture après succès
    if (widget.type == PaymentAnimationType.success) {
      Future.delayed(const Duration(milliseconds: 3000), () {
        widget.onComplete?.call();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSending = widget.type == PaymentAnimationType.sending ||
        widget.type == PaymentAnimationType.connecting;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.9),
      body: SafeArea(
        child: Stack(
          children: [
            // Fond avec vague
            if (_showWave)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.6,
                  child: WaveAnimation(
                    direction:
                        isSending ? WaveDirection.up : WaveDirection.down,
                    color: PaymentTechIcon.getColor(widget.tech),
                    amplitude: 50,
                    waveLength: 250,
                  ),
                ),
              ),

            // Contenu principal
            Center(
              child: FadeTransition(
                opacity: _opacity,
                child: ScaleTransition(
                  scale: _scale,
                  child: GlassContainer(
                    padding: const EdgeInsets.all(32),
                    borderRadius: 32,
                    opacity: 0.08,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icône techno avec pulse
                        AnimatedIconBadge(
                          tech: widget.tech,
                          size: 80,
                          showPulse:
                              widget.type != PaymentAnimationType.success,
                        ),
                        const SizedBox(height: 24),

                        // Titre
                        Text(
                          widget.title ?? _getDefaultTitle(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Sous-titre
                        if (widget.subtitle != null) ...[
                          Text(
                            widget.subtitle!,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Montant
                        if (widget.amount != null) ...[
                          Text(
                            '\$${widget.amount!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: LiquidGlassTheme.accent,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Contrepartie
                        if (widget.counterparty != null) ...[
                          Text(
                            '${isSending ? 'Vers' : 'De'} ${widget.counterparty}',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Statut
                        if (widget.type == PaymentAnimationType.success)
                          _buildSuccessStatus()
                        else if (widget.type == PaymentAnimationType.failure)
                          _buildFailureStatus()
                        else
                          _buildLoadingStatus(),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bouton d'annulation (si pas success/failure)
            if (widget.type != PaymentAnimationType.success &&
                widget.type != PaymentAnimationType.failure)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: TextButton(
                    onPressed: widget.onComplete,
                    child: const Text(
                      'Annuler',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingStatus() {
    return Column(
      children: [
        const SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: LiquidGlassTheme.accent,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.type == PaymentAnimationType.connecting
              ? 'Connexion en cours...'
              : 'Envoi en cours...',
          style: const TextStyle(color: Colors.white54),
        ),
      ],
    );
  }

  Widget _buildSuccessStatus() {
    return AnimatedOpacity(
      opacity: _showSuccess ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.black,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Paiement réussi !',
            style: TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailureStatus() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.redAccent,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.close,
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Paiement échoué',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.subtitle ?? 'Une erreur est survenue',
          style: const TextStyle(color: Colors.white54),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: widget.onComplete,
          child: const Text(
            'Réessayer',
            style: TextStyle(color: LiquidGlassTheme.accent),
          ),
        ),
      ],
    );
  }

  String _getDefaultTitle() {
    switch (widget.type) {
      case PaymentAnimationType.sending:
        return 'Envoi en cours...';
      case PaymentAnimationType.receiving:
        return 'Réception en cours...';
      case PaymentAnimationType.connecting:
        return 'Connexion...';
      case PaymentAnimationType.scanning:
        return 'Recherche...';
      case PaymentAnimationType.success:
        return 'Paiement réussi !';
      case PaymentAnimationType.failure:
        return 'Paiement échoué';
    }
  }
}
