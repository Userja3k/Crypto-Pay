import 'package:flutter/material.dart';
import '../theme.dart';

class UIUtils {
  static void showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: const [
            Icon(Icons.error_outline, color: LiquidGlassTheme.error),
            SizedBox(width: 12),
            Text('Erreur', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          error.replaceFirst('Exception: ', '').replaceFirst('PostgrestException(message: ', '').replaceFirst(', code: ', ' CODE: '),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK',
                style: TextStyle(
                    color: LiquidGlassTheme.accent,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
