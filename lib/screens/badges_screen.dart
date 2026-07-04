// File: lib/screens/badges_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:memoriz_bible/badges/providers/badge_provider.dart';
import 'package:memoriz_bible/models/badge_model.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final badgeProvider = context.watch<BadgeProvider?>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mes badges')),
      body: badgeProvider == null
          ? const Center(child: Text('Connecte-toi pour voir tes badges.'))
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProgressHeader(totalActiveDays: badgeProvider.totalActiveDays),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: kBadgeDefinitions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final def = kBadgeDefinitions[index];
                  final badge = badgeProvider.badges[def.id] ?? def;
                  final isBetaLocked =
                      def.betaOnly && !badgeProvider.isBetaTester;

                  return _BadgeTile(
                    badge: badge,
                    isBetaLocked: isBetaLocked,
                    currentDays: badgeProvider.totalActiveDays,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int totalActiveDays;
  const _ProgressHeader({required this.totalActiveDays});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department,
              color: Theme.of(context).colorScheme.primary, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$totalActiveDays ${totalActiveDays > 1 ? "jours" : "jour"} d\'engagement',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const Text('Continue comme ça !'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final BadgeModel badge;
  final bool isBetaLocked;
  final int currentDays;

  const _BadgeTile({
    required this.badge,
    required this.isBetaLocked,
    required this.currentDays,
  });

  @override
  Widget build(BuildContext context) {
    final locked = !badge.unlocked;
    final progress = (currentDays / badge.thresholdDays).clamp(0.0, 1.0);

    return Card(
      elevation: locked ? 1 : 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Opacity(
              opacity: locked ? 0.35 : 1.0,
              child: Text(badge.emoji, style: const TextStyle(fontSize: 40)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        badge.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: locked ? Colors.grey : null,
                        ),
                      ),
                      if (badge.betaOnly) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Bêta',
                              style: TextStyle(fontSize: 10, color: Colors.amber)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    badge.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: locked ? Colors.grey : null,
                    ),
                  ),
                  if (locked && !isBetaLocked) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currentDays / ${badge.thresholdDays} jours',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                  if (isBetaLocked)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Réservé aux bêta-testeurs',
                        style: TextStyle(fontSize: 11, color: Colors.amber),
                      ),
                    ),
                ],
              ),
            ),
            if (!locked)
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
          ],
        ),
      ),
    );
  }
}