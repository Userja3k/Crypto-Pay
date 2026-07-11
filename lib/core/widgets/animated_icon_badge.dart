// lib/core/widgets/animated_icon_badge.dart
// Badge avec icône pour les notifications

import 'package:flutter/material.dart';
import '../theme.dart';

enum PaymentTech {
  bluetooth,
  nfc,
  lightning,
  qrCode,
  internal,
  mobileMoney,
}

class PaymentTechIcon {
  static IconData getIcon(PaymentTech tech) {
    switch (tech) {
      case PaymentTech.bluetooth:
        return Icons.bluetooth;
      case PaymentTech.nfc:
        return Icons.nfc;
      case PaymentTech.lightning:
        return Icons.flash_on;
      case PaymentTech.qrCode:
        return Icons.qr_code_scanner;
      case PaymentTech.internal:
        return Icons.people;
      case PaymentTech.mobileMoney:
        return Icons.phone_android;
    }
  }

  static Color getColor(PaymentTech tech) {
    switch (tech) {
      case PaymentTech.bluetooth:
        return Colors.blue;
      case PaymentTech.nfc:
        return const Color(0xFF00D4FF);
      case PaymentTech.lightning:
        return Colors.orange;
      case PaymentTech.qrCode:
        return Colors.purple;
      case PaymentTech.internal:
        return Colors.green;
      case PaymentTech.mobileMoney:
        return Colors.amber;
    }
  }

  static String getLabel(PaymentTech tech) {
    switch (tech) {
      case PaymentTech.bluetooth:
        return 'Bluetooth';
      case PaymentTech.nfc:
        return 'NFC';
      case PaymentTech.lightning:
        return 'Lightning';
      case PaymentTech.qrCode:
        return 'QR Code';
      case PaymentTech.internal:
        return 'Interne';
      case PaymentTech.mobileMoney:
        return 'Mobile Money';
    }
  }
}

class AnimatedIconBadge extends StatelessWidget {
  final PaymentTech tech;
  final double size;
  final bool showPulse;
  final VoidCallback? onTap;

  const AnimatedIconBadge({
    super.key,
    required this.tech,
    this.size = 40,
    this.showPulse = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = PaymentTechIcon.getIcon(tech);
    final color = PaymentTechIcon.getColor(tech);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: showPulse
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: size * 0.5,
            ),
            if (showPulse)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.8, end: 1.2),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color.withValues(
                                  alpha: 0.1 * (1 - (value - 0.8) / 0.4)),
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
