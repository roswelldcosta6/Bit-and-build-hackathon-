import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/sign_result.dart';

/// Person 2: Sign result card widget
/// Shows the currently recognized sign with English + Hindi text and confidence.
class SignResultCard extends StatelessWidget {
  final SignResult? result;
  final double confidence;

  const SignResultCard({
    super.key,
    this.result,
    this.confidence = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Center(
          child: Text(
            'Waiting for sign...',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        // Haptic feedback on tap
        HapticFeedback.mediumImpact();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.withValues(alpha: 0.2),
              Colors.orange.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gloss label
            Text(
              result!.gloss,
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            // English text
            Text(
              result!.labelEn,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            // Hindi text
            Text(
              result!.labelHi,
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
