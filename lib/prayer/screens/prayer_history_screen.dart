// lib/features/prayer/screens/prayer_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/prayer_timer_provider.dart';
import '../models/daily_prayer_stats.dart';
import '../models/prayer_session.dart';
import 'package:fl_chart/fl_chart.dart';

class PrayerHistoryScreen extends StatefulWidget {
  const PrayerHistoryScreen({Key? key}) : super(key: key);

  @override
  State<PrayerHistoryScreen> createState() => _PrayerHistoryScreenState();
}

class _PrayerHistoryScreenState extends State<PrayerHistoryScreen> {
  DateTime _selectedMonth = DateTime.now();
  bool _showSessions = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Historique'),
        actions: [
          IconButton(
            icon: Icon(_showSessions ? Icons.calendar_month : Icons.list),
            onPressed: () {
              setState(() {
                _showSessions = !_showSessions;
              });
            },
            tooltip: _showSessions ? 'Vue calendrier' : 'Vue sessions',
          ),
        ],
      ),
      body: _showSessions
          ? _SessionsListView()
          : Column(
        children: [
          // Sélecteur de mois
          _MonthSelector(
            selectedMonth: _selectedMonth,
            onMonthChanged: (month) {
              setState(() {
                _selectedMonth = month;
              });
            },
          ),

          // Statistiques du mois
          _MonthlyStatsCard(month: _selectedMonth),

          const SizedBox(height: 16),

          // Graphique de la semaine
          Expanded(
            child: _WeeklyChart(month: _selectedMonth),
          ),
        ],
      ),
    );
  }
}

// Sélecteur de mois
class _MonthSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final Function(DateTime) onMonthChanged;

  const _MonthSelector({
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              onMonthChanged(
                DateTime(selectedMonth.year, selectedMonth.month - 1),
              );
            },
          ),
          Text(
            _formatMonth(selectedMonth),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              final nextMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
              if (nextMonth.isBefore(DateTime.now().add(const Duration(days: 1)))) {
                onMonthChanged(nextMonth);
              }
            },
          ),
        ],
      ),
    );
  }

  String _formatMonth(DateTime date) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

// Statistiques mensuelles
class _MonthlyStatsCard extends StatelessWidget {
  final DateTime month;

  const _MonthlyStatsCard({required this.month});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<PrayerTimerProvider>().userId;

    return FutureBuilder<Map<String, dynamic>>(
      future: _getMonthlyStats(userId, month),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            margin: EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final stats = snapshot.data!;
        final totalMinutes = (stats['totalSeconds'] as int) ~/ 60;
        final totalHours = totalMinutes ~/ 60;
        final remainingMinutes = totalMinutes % 60;
        final daysWithGoal = stats['daysWithGoal'] as int;
        final totalDays = stats['totalDays'] as int;
        final longestStreak = stats['longestStreak'] as int;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Temps total
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time, size: 32, color: Colors.blue),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Temps total',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          totalHours > 0
                              ? '${totalHours}h ${remainingMinutes}min'
                              : '${totalMinutes}min',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),

                // Autres stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MiniStat(
                      icon: Icons.check_circle,
                      label: 'Objectifs atteints',
                      value: '$daysWithGoal/$totalDays',
                      color: Colors.green,
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey[300],
                    ),
                    _MiniStat(
                      icon: Icons.local_fire_department,
                      label: 'Meilleur streak',
                      value: '${longestStreak}j',
                      color: Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getMonthlyStats(
      String userId, DateTime month) async {
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0);

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('prayerStats')
          .doc('daily')
          .collection('entries')
          .where(FieldPath.documentId,
          isGreaterThanOrEqualTo: _formatDate(startOfMonth))
          .where(FieldPath.documentId,
          isLessThanOrEqualTo: _formatDate(endOfMonth))
          .get();

      int totalSeconds = 0;
      int daysWithGoal = 0;
      int currentStreak = 0;
      int longestStreak = 0;

      for (final doc in snapshot.docs) {
        final stats = DailyPrayerStats.fromFirestore(doc);
        totalSeconds += stats.totalSeconds;
        if (stats.goalAchieved) {
          daysWithGoal++;
          currentStreak++;
          if (currentStreak > longestStreak) {
            longestStreak = currentStreak;
          }
        } else {
          currentStreak = 0;
        }
      }

      return {
        'totalSeconds': totalSeconds,
        'daysWithGoal': daysWithGoal,
        'totalDays': snapshot.docs.length,
        'longestStreak': longestStreak,
      };
    } catch (e) {
      debugPrint('❌ Erreur récupération stats mensuelles: $e');
      return {
        'totalSeconds': 0,
        'daysWithGoal': 0,
        'totalDays': 0,
        'longestStreak': 0,
      };
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
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
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

// Graphique hebdomadaire
class _WeeklyChart extends StatelessWidget {
  final DateTime month;

  const _WeeklyChart({required this.month});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<PrayerTimerProvider>().userId;

    return FutureBuilder<List<DailyPrayerStats>>(
      future: _getLast7DaysStats(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data!;

        return Card(
          margin: const EdgeInsets.all(16),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📈 7 derniers jours',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _getMaxY(stats),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final stat = stats[groupIndex];
                            return BarTooltipItem(
                              '${stat.formattedTotal}\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                TextSpan(
                                  text: _getDayName(stat.date),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < stats.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _getDayAbbr(stats[value.toInt()].date),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}min',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 15,
                      ),
                      barGroups: stats.asMap().entries.map((entry) {
                        final index = entry.key;
                        final stat = entry.value;
                        final minutes = stat.totalSeconds / 60;
                        final goalMinutes = stat.goalSeconds / 60;

                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: minutes,
                              color: stat.goalAchieved
                                  ? Colors.green
                                  : Colors.blue,
                              width: 20,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: goalMinutes,
                                color: Colors.grey[200],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Légende
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendItem(color: Colors.green, label: 'Objectif atteint'),
                    const SizedBox(width: 16),
                    _LegendItem(color: Colors.blue, label: 'En cours'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<DailyPrayerStats>> _getLast7DaysStats(String userId) async {
    final List<DailyPrayerStats> stats = [];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateStr = _formatDate(date);

      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('prayerStats')
            .doc('daily')
            .collection('entries')
            .doc(dateStr)
            .get();

        if (doc.exists) {
          stats.add(DailyPrayerStats.fromFirestore(doc));
        } else {
          // Jour sans données
          stats.add(DailyPrayerStats(
            date: dateStr,
            totalSeconds: 0,
            goalSeconds: 900, // 15 min par défaut
            sessionsCount: 0,
            goalAchieved: false,
            streak: 0,
          ));
        }
      } catch (e) {
        debugPrint('❌ Erreur récupération stats jour $dateStr: $e');
        stats.add(DailyPrayerStats(
          date: dateStr,
          totalSeconds: 0,
          goalSeconds: 900,
          sessionsCount: 0,
          goalAchieved: false,
          streak: 0,
        ));
      }
    }

    return stats;
  }

  double _getMaxY(List<DailyPrayerStats> stats) {
    double max = 15; // 15 min minimum
    for (final stat in stats) {
      final minutes = stat.totalSeconds / 60;
      final goalMinutes = stat.goalSeconds / 60;
      if (minutes > max) max = minutes;
      if (goalMinutes > max) max = goalMinutes;
    }
    return (max * 1.2).ceilToDouble(); // 20% de marge
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _getDayName(String dateStr) {
    final parts = dateStr.split('-');
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    const days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];
    return days[date.weekday - 1];
  }

  String _getDayAbbr(String dateStr) {
    final parts = dateStr.split('-');
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return days[date.weekday - 1];
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

// Vue liste des sessions
class _SessionsListView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = context.read<PrayerTimerProvider>().userId;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('prayerSessions')
          .where('isCompleted', isEqualTo: true)
          .orderBy('startTime', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Aucune session de prière'),
          );
        }

        final sessions = snapshot.data!.docs
            .map((doc) => PrayerSession.fromFirestore(doc))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return _SessionCard(session: session);
          },
        );
      },
    );
  }
}

class _SessionCard extends StatelessWidget {
  final PrayerSession session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: const Icon(Icons.access_time, color: Colors.blue),
        ),
        title: Text(
          session.formattedDuration,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          _formatSessionDate(session.startTime),
        ),
        trailing: Icon(
          Icons.check_circle,
          color: Colors.green[400],
        ),
      ),
    );
  }

  String _formatSessionDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Aujourd\'hui à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Hier à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}