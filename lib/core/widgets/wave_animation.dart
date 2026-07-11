// lib/core/widgets/wave_animation.dart
// Effet de vague pour NFC (envoi/reception)

import 'dart:math';
import 'package:flutter/material.dart';

enum WaveDirection { up, down, left, right }

class WaveAnimation extends StatefulWidget {
  final WaveDirection direction;
  final Color color;
  final Duration duration;
  final double amplitude;
  final double waveLength;
  final VoidCallback? onComplete;

  const WaveAnimation({
    super.key,
    this.direction = WaveDirection.up,
    this.color = const Color(0xFF00D4FF),
    this.duration = const Duration(milliseconds: 1500),
    this.amplitude = 30.0,
    this.waveLength = 200.0,
    this.onComplete,
  });

  @override
  State<WaveAnimation> createState() => _WaveAnimationState();
}

class _WaveAnimationState extends State<WaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final progress = _progress.value;
        final isVertical = widget.direction == WaveDirection.up ||
            widget.direction == WaveDirection.down;

        return CustomPaint(
          size: Size(
            isVertical ? 200 : 400,
            isVertical ? 400 : 200,
          ),
          painter: _WavePainter(
            progress: progress,
            direction: widget.direction,
            color: widget.color,
            amplitude: widget.amplitude,
            waveLength: widget.waveLength,
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final WaveDirection direction;
  final Color color;
  final double amplitude;
  final double waveLength;

  _WavePainter({
    required this.progress,
    required this.direction,
    required this.color,
    required this.amplitude,
    required this.waveLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.3 * (1 - progress))
      ..style = PaintingStyle.fill;

    final path = Path();

    final isVertical =
        direction == WaveDirection.up || direction == WaveDirection.down;
    final isUp =
        direction == WaveDirection.up || direction == WaveDirection.left;
    final sign = isUp ? -1 : 1;

    if (isVertical) {
      // Vague verticale
      final startY = isUp
          ? size.height * (1 - progress * 0.8)
          : size.height * (progress * 0.8);

      path.moveTo(0, startY);

      for (double x = 0; x <= size.width; x += 1) {
        final wave =
            sin(x / waveLength * 2 * pi + progress * 4) * amplitude * progress;
        path.lineTo(x, startY + wave * sign);
      }

      path.lineTo(size.width, isUp ? size.height : 0);
      path.lineTo(0, isUp ? size.height : 0);
      path.close();
    } else {
      // Vague horizontale
      final startX = isUp
          ? size.width * (1 - progress * 0.8)
          : size.width * (progress * 0.8);

      path.moveTo(startX, 0);

      for (double y = 0; y <= size.height; y += 1) {
        final wave =
            sin(y / waveLength * 2 * pi + progress * 4) * amplitude * progress;
        path.lineTo(startX + wave * sign, y);
      }

      path.lineTo(isUp ? 0 : size.width, size.height);
      path.lineTo(isUp ? 0 : size.width, 0);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
