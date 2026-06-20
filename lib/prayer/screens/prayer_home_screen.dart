// lib/features/prayer/screens/prayer_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/prayer_timer_provider.dart';
import '../providers/prayer_notes_provider.dart';
import '../widgets/prayer_timer_widget.dart';
import '../models/prayer_note.dart';
import 'prayer_journal_screen.dart';
import 'prayer_settings_screen.dart';
import 'prayer_history_screen.dart';

class PrayerHomeScreen extends StatelessWidget {
  const PrayerHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🙏 Prière'),
        actions: [
          // Bouton historique
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrayerHistoryScreen(),
                ),
              );
            },
            tooltip: 'Historique',
          ),
          // Bouton paramètres
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrayerSettingsScreen(),
                ),
              );
            },
            tooltip: 'Paramètres',
          ),
        ],
      ),
      body: Consumer<PrayerTimerProvider?>(
        builder: (context, timerProvider, child) {
          if (timerProvider == null || timerProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await timerProvider.todayStats;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Widget du timer principal
                const PrayerTimerWidget(),

                const SizedBox(height: 24),

                // Section "Notes récentes"
                _RecentNotesSection(),

                const SizedBox(height: 24),

                // Section "Statistiques"
                _QuickStatsSection(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PrayerJournalScreen(),
            ),
          );
        },
        icon: const Icon(Icons.book),
        label: const Text('Journal'),
      ),
    );
  }
}

// Section des notes récentes
class _RecentNotesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerNotesProvider>(
      builder: (context, notesProvider, child) {
        final recentNotes = notesProvider.notes.take(3).toList();

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '📝 Notes récentes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrayerJournalScreen(),
                          ),
                        );
                      },
                      child: const Text('Voir tout'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                if (recentNotes.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.edit_note,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aucune note pour le moment',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...recentNotes.map((note) => _NotePreviewCard(note: note)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Carte de prévisualisation de note
class _NotePreviewCard extends StatelessWidget {
  final PrayerNote note;

  const _NotePreviewCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getTypeColor(note.type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getTypeColor(note.type).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                note.type == NoteType.autre && note.customTypeLabel != null
                    ? '✏️ ${note.customTypeLabel}'
                    : note.type.displayNameFr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getTypeColor(note.type),
                ),
              ),
              const Spacer(),
              Text(
                _formatDate(note.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
          if (note.verseReference != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.menu_book,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  note.verseReference!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _getTypeColor(NoteType type) {
    switch (type) {
      case NoteType.gratitude:
        return Colors.green;
      case NoteType.demande:
        return Colors.blue;
      case NoteType.intercession:
        return Colors.pink;
      case NoteType.revelation:
        return Colors.purple;
      case NoteType.meditation:
        return Colors.teal;
      case NoteType.confession:
        return Colors.indigo;
      case NoteType.louange:
        return Colors.amber;
      case NoteType.engagement:
        return Colors.deepOrange;
      case NoteType.combat:
        return Colors.red;
      case NoteType.temoignage:
        return Colors.lightGreen;
      case NoteType.autre:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes}min';
    } else if (diff.inHours < 24) {
      return 'Il y a ${diff.inHours}h';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays}j';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Section des statistiques rapides
class _QuickStatsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<PrayerTimerProvider?>(
      builder: (context, timerProvider, child) {
        if (timerProvider == null) return const SizedBox.shrink();
        final stats = timerProvider.todayStats;
        if (stats == null) return const SizedBox.shrink();

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📊 Aujourd\'hui',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatItem(
                        icon: Icons.access_time,
                        label: 'Temps prié',
                        value: stats.formattedTotal,
                        color: Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _StatItem(
                        icon: Icons.repeat,
                        label: 'Sessions',
                        value: '${stats.sessionsCount}',
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                if (stats.streak > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.orange, Colors.deepOrange],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${stats.streak} jour${stats.streak > 1 ? 's' : ''} consécutifs !',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
