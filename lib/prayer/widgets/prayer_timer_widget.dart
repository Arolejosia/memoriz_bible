// lib/features/prayer/widgets/prayer_timer_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/prayer_timer_provider.dart';
import 'dart:math' as math;

class PrayerTimerWidget extends StatelessWidget {
  const PrayerTimerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerTimerProvider>(
      builder: (context, timerProvider, child) {
        if (timerProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = timerProvider.todayStats;

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Cercle de progression animé
                SizedBox(
                  height: 250,
                  width: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Cercle de progression
                      if (stats != null)
                        CustomPaint(
                          size: const Size(250, 250),
                          painter: CircularProgressPainter(
                            progress: stats.progressPercentage / 100,
                            isRunning: timerProvider.isRunning,
                          ),
                        ),

                      // Temps au centre
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            timerProvider.formattedTime,
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (stats != null)
                            Text(
                              '${stats.formattedTotal} / ${stats.formattedGoal}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Pourcentage et streak
                if (stats != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Pourcentage
                      _StatCard(
                        icon: Icons.flag,
                        label: 'Progression',
                        value: '${stats.progressPercentage.toStringAsFixed(0)}%',
                        color: stats.goalAchieved ? Colors.green : Colors.blue,
                      ),

                      // Sessions
                      _StatCard(
                        icon: Icons.timer,
                        label: 'Sessions',
                        value: '${stats.sessionsCount}',
                        color: Colors.orange,
                      ),

                      // Streak
                      if (stats.streak > 0)
                        _StatCard(
                          icon: Icons.local_fire_department,
                          label: 'Streak',
                          value: '${stats.streak}j',
                          color: Colors.deepOrange,
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],

                // Bouton Start/Stop
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: timerProvider.isRunning
                        ? () async {
                      final sessionId = await timerProvider.stopSession();
                      if (sessionId != null && context.mounted) {
                        _showNotePrompt(context, sessionId);
                      }
                    }
                        : () => timerProvider.startSession(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: timerProvider.isRunning
                          ? Colors.red[400]
                          : Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          timerProvider.isRunning ? Icons.stop : Icons.play_arrow,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          timerProvider.isRunning
                              ? 'Arrêter la prière'
                              : 'Démarrer la prière',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotePrompt(BuildContext context, String sessionId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: Colors.blue),
            SizedBox(width: 12),
            Text('Ajouter une note ?'),
          ],
        ),
        content: const Text(
          'Voulez-vous noter une intention, gratitude ou révélation pour cette session de prière ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/prayer/note/create',
                arguments: sessionId,
              );
            },
            child: const Text('Ajouter une note'),
          ),
        ],
      ),
    );
  }
}

// Widget pour les stats individuelles
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// Painter pour le cercle de progression
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final bool isRunning;

  CircularProgressPainter({
    required this.progress,
    required this.isRunning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 15;

    // Cercle de fond
    final backgroundPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Cercle de progression
    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: isRunning
            ? [Colors.blue, Colors.purple]
            : progress >= 1.0
            ? [Colors.green, Colors.lightGreen]
            : [Colors.blue, Colors.cyan],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Point animé si en cours
    if (isRunning) {
      final pointAngle = -math.pi / 2 + sweepAngle;
      final pointX = center.dx + radius * math.cos(pointAngle);
      final pointY = center.dy + radius * math.sin(pointAngle);

      final pointPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(pointX, pointY), 8, pointPaint);

      final pointBorderPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawCircle(Offset(pointX, pointY), 8, pointBorderPaint);
    }
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isRunning != isRunning;
  }
}