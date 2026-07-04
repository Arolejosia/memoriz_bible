// File: lib/widgets/badge_unlock_dialog.dart

import 'package:flutter/material.dart';
import 'package:memoriz_bible/models/badge_model.dart';

class BadgeUnlockDialog extends StatelessWidget {
  final BadgeModel badge;
  const BadgeUnlockDialog({super.key, required this.badge});

  static Future<void> show(BuildContext context, BadgeModel badge) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Badge débloqué',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => BadgeUnlockDialog(badge: badge),
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.elasticOut);
        return ScaleTransition(scale: curved, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(badge.emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(
              'Badge débloqué !',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              badge.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continuer'),
            ),
          ],
        ),
      ),
    );
  }
}