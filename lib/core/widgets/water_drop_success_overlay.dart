import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../../services/haptic_service.dart';

class WaterDropSuccessOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const WaterDropSuccessOverlay({
    super.key,
    required this.onComplete,
  });

  /// Helper to show the overlay on any context
  static void show(BuildContext context, VoidCallback onComplete) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (context, _, __) => WaterDropSuccessOverlay(
          onComplete: () {
            Navigator.of(context).pop();
            onComplete();
          },
        ),
      ),
    );
  }

  @override
  State<WaterDropSuccessOverlay> createState() => _WaterDropSuccessOverlayState();
}

class _WaterDropSuccessOverlayState extends State<WaterDropSuccessOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<SplashParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );

    // Generate random splash particles
    for (int i = 0; i < 12; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 100.0 + _random.nextDouble() * 150.0;
      final radius = 3.0 + _random.nextDouble() * 4.0;
      _particles.add(SplashParticle(
        angle: angle,
        speed: speed,
        radius: radius,
      ));
    }

    _controller.addListener(() {
      // Trigger haptics when droplet hits center (around 30% of the animation progress)
      if (_controller.value >= 0.28 && _controller.value <= 0.32) {
        HapticService.success();
      }
    });

    _controller.forward().then((_) {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.8),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: WaterDropPainter(
              progress: _controller.value,
              particles: _particles,
            ),
            child: Container(),
          );
        },
      ),
    );
  }
}

class SplashParticle {
  final double angle;
  final double speed;
  final double radius;

  SplashParticle({
    required this.angle,
    required this.speed,
    required this.radius,
  });
}

class WaterDropPainter extends CustomPainter {
  final double progress;
  final List<SplashParticle> particles;

  WaterDropPainter({
    required this.progress,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = LiquidGlassTheme.accent
      ..style = PaintingStyle.fill;

    // Timeline configuration
    // 0.0 -> 0.3: Droplet falling
    // 0.3 -> 0.7: Splash particles and ripples expanding
    // 0.5 -> 0.9: Checkmark appearing
    // 0.9 -> 1.0: Full fade out

    if (progress < 0.3) {
      // ════════════════════════════════════════════════════════
      // PHASE 1 : FALLING DROPLET
      // ════════════════════════════════════════════════════════
      final t = progress / 0.3; // Normalized 0.0 -> 1.0
      final y = center.dy * t;
      
      // Draw droplet shape
      final r = 16.0 - (t * 4.0); // Droplet slightly thins as it falls
      _drawDroplet(canvas, Offset(center.dx, y), r, paint);
    } else if (progress < 0.9) {
      // ════════════════════════════════════════════════════════
      // PHASE 2 : SPLASH & RIPPLE
      // ════════════════════════════════════════════════════════
      final tSplash = (progress - 0.3) / 0.6; // Normalized 0.0 -> 1.0

      // 1. Concentric ripples on impact
      final ripplePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      // Ripple 1
      final r1 = tSplash * 150.0;
      final opacity1 = (1.0 - tSplash).clamp(0.0, 1.0);
      ripplePaint.color = LiquidGlassTheme.accent.withValues(alpha: opacity1 * 0.4);
      canvas.drawCircle(center, r1, ripplePaint);

      // Ripple 2 (delayed and smaller)
      if (tSplash > 0.2) {
        final tSplash2 = (tSplash - 0.2) / 0.8;
        final r2 = tSplash2 * 100.0;
        final opacity2 = (1.0 - tSplash2).clamp(0.0, 1.0);
        ripplePaint.color = LiquidGlassTheme.accent.withValues(alpha: opacity2 * 0.25);
        canvas.drawCircle(center, r2, ripplePaint);
      }

      // 2. Flying splash particles
      for (final particle in particles) {
        // Calculate offset with gravity and deceleration
        final distance = particle.speed * tSplash * (1.0 - tSplash * 0.5);
        final dx = cos(particle.angle) * distance;
        // Gravity pulls particles downwards over time
        final dy = sin(particle.angle) * distance + (180.0 * tSplash * tSplash);
        
        final particleOpacity = (1.0 - tSplash).clamp(0.0, 1.0);
        final particlePaint = Paint()
          ..color = LiquidGlassTheme.accent.withValues(alpha: particleOpacity)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          center + Offset(dx, dy),
          particle.radius * (1.0 - tSplash * 0.6),
          particlePaint,
        );
      }

      // 3. Draw Checkmark inside a nice glass circle at center
      if (progress > 0.45) {
        final tCheck = (progress - 0.45) / 0.45; // 0.0 -> 1.0
        final checkOpacity = tCheck.clamp(0.0, 1.0);

        // Glass background circle
        final bgPaint = Paint()
          ..color = Colors.white.withValues(alpha: checkOpacity * 0.08)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, 48, bgPaint);

        // Green outline
        final borderPaint = Paint()
          ..color = LiquidGlassTheme.accent.withValues(alpha: checkOpacity * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(center, 48, borderPaint);

        // Checkmark paths
        final checkPaint = Paint()
          ..color = LiquidGlassTheme.accent.withValues(alpha: checkOpacity)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 6.0;

        final path = Path();
        // Draw animatable checkmark
        path.moveTo(center.dx - 18, center.dy + 2);
        
        if (tCheck < 0.4) {
          // Draw first segment only
          final segmentProgress = tCheck / 0.4;
          path.lineTo(
            center.dx - 18 + (12 * segmentProgress),
            center.dy + 2 + (12 * segmentProgress),
          );
        } else {
          // Draw full checkmark
          path.lineTo(center.dx - 6, center.dy + 14);
          final segmentProgress2 = (tCheck - 0.4) / 0.6;
          path.lineTo(
            center.dx - 6 + (24 * segmentProgress2),
            center.dy + 14 - (28 * segmentProgress2),
          );
        }
        canvas.drawPath(path, checkPaint);
      }
    } else {
      // ════════════════════════════════════════════════════════
      // PHASE 3 : FADE OUT ENTIRE OVERLAY
      // ════════════════════════════════════════════════════════
      final tFade = (progress - 0.9) / 0.1; // 0.0 -> 1.0
      final opacity = (1.0 - tFade).clamp(0.0, 1.0);

      final bgPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.08)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 48, bgPaint);

      final borderPaint = Paint()
        ..color = LiquidGlassTheme.accent.withValues(alpha: opacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, 48, borderPaint);

      final checkPaint = Paint()
        ..color = LiquidGlassTheme.accent.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 6.0;

      final path = Path();
      path.moveTo(center.dx - 18, center.dy + 2);
      path.lineTo(center.dx - 6, center.dy + 14);
      path.lineTo(center.dx + 18, center.dy - 14);
      canvas.drawPath(path, checkPaint);
    }
  }

  /// Draws a droplet path pointed at the top and rounded at the bottom
  void _drawDroplet(Canvas canvas, Offset position, double r, Paint paint) {
    final path = Path();
    final x = position.dx;
    final y = position.dy;

    path.moveTo(x, y - r * 1.8); // Pointy top
    // Curve down to bottom-right
    path.cubicTo(x + r * 0.8, y - r * 1.2, x + r, y - r * 0.5, x + r, y);
    // Round bottom
    path.arcToPoint(Offset(x - r, y), radius: Radius.circular(r), clockwise: true);
    // Curve back up to top
    path.cubicTo(x - r, y - r * 0.5, x - r * 0.8, y - r * 1.2, x, y - r * 1.8);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
