import 'package:flutter/material.dart';
import 'dart:math' as math;

class CryptoPayLogo extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Color iconColor;

  const CryptoPayLogo({
    super.key,
    this.size = 100,
    this.backgroundColor = Colors.white,
    this.iconColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.8,
            height: size * 0.8,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
          ),
          // The "B" opening the circle
          Transform.translate(
            offset: Offset(-size * 0.1, 0),
            child: Transform.rotate(
              angle: -80 * (math.pi / 180),
              child: Text(
                '₿',
                style: TextStyle(
                  color: iconColor,
                  fontSize: size * 0.85,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
