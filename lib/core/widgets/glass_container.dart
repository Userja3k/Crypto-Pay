import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double opacity;
  final BoxShape shape;
  final BoxBorder? border;
  final bool hasReflection;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 32.0,
    this.blur = 40.0,
    this.padding,
    this.margin,
    this.opacity = 0.08,
    this.shape = BoxShape.rectangle,
    this.border,
    this.hasReflection = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: shape == BoxShape.circle
          ? BorderRadius.circular(1000)
          : BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: opacity),
              shape: shape,
              borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
              border: border ?? Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1.0,
              ),
              gradient: hasReflection ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.05),
                ],
                stops: const [0.0, 0.5, 1.0],
              ) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
