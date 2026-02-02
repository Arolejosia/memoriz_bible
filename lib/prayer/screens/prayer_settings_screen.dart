// lib/features/prayer/screens/prayer_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import '../providers/prayer_timer_provider.dart';
import '../models/prayer_settings.dart';

class PrayerSettingsScreen extends StatefulWidget {
  const PrayerSettingsScreen({Key? key}) : super(key: key);

  @override
  State<PrayerSettingsScreen> createState() => _PrayerSettingsScreenState();
}

class _PrayerSettingsScreenState extends State<PrayerSettingsScreen> {
  late PrayerSettings _settings;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _settings = context.read<PrayerTimerProvider>().settings;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          return await _confirmExit();
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('⚙️ Paramètres'),
          actions: [
            if (_hasChanges)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveSettings,
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Objectif quotidien
            _SectionHeader(title: 'Objectif quotidien'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Durée cible',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          '${_settings.dailyGoalMinutes} min',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: _settings.dailyGoalMinutes.toDouble(),
                      min: 5,
                      max: 120,
                      divisions: 23, // (120-5)/5
                      label: '${_settings.dailyGoalMinutes} min',
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings.copyWith(
                            dailyGoalMinutes: value.round(),
                          );
                          _hasChanges = true;
                        });
                      },
                    ),
                    Text(
                      'Ajustez votre objectif quotidien de prière',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Notifications
            _SectionHeader(title: 'Notifications'),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Activer les notifications'),
                    subtitle: const Text('Recevoir des rappels de prière'),
                    value: _settings.notificationsEnabled,
                    onChanged: (value) async {
                      if (value) {
                        // Utiliser votre NotificationService existant
                        try {
                          await NotificationService.instance.init();
                          // Les permissions sont déjà demandées dans init()
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Veuillez activer les notifications dans les paramètres',
                                ),
                              ),
                            );
                          }
                          return;
                        }
                      }

                      setState(() {
                        _settings = _settings.copyWith(
                          notificationsEnabled: value,
                        );
                        _hasChanges = true;
                      });
                    },
                  ),
                  if (_settings.notificationsEnabled) ...[
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Rappels de streak'),
                      subtitle: const Text('Être notifié des jours consécutifs'),
                      value: _settings.showStreakReminders,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings.copyWith(
                            showStreakReminders: value,
                          );
                          _hasChanges = true;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Rappels personnalisés
            if (_settings.notificationsEnabled) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Rappels personnalisés',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addReminder,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_settings.reminders.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Aucun rappel configuré',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                )
              else
                ...(_settings.reminders.asMap().entries.map((entry) {
                  final index = entry.key;
                  final reminder = entry.value;
                  return _ReminderCard(
                    reminder: reminder,
                    onEdit: () => _editReminder(index),
                    onDelete: () => _deleteReminder(index),
                    onToggle: (enabled) {
                      setState(() {
                        final updatedReminders = List<PrayerReminder>.from(
                          _settings.reminders,
                        );
                        updatedReminders[index] =
                            reminder.copyWith(enabled: enabled);
                        _settings = _settings.copyWith(
                          reminders: updatedReminders,
                        );
                        _hasChanges = true;
                      });
                    },
                  );
                })),
            ],

            const SizedBox(height: 24),

            // Autres options
            _SectionHeader(title: 'Autres options'),
            Card(
              child: SwitchListTile(
                title: const Text('Sauvegarde automatique des notes'),
                subtitle: const Text('Proposer de créer une note après chaque session'),
                value: _settings.autoSaveNotes,
                onChanged: (value) {
                  setState(() {
                    _settings = _settings.copyWith(autoSaveNotes: value);
                    _hasChanges = true;
                  });
                },
              ),
            ),

            const SizedBox(height: 32),

            // Bouton de sauvegarde
            if (_hasChanges)
              ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Enregistrer les modifications',
                  style: TextStyle(fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _addReminder() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );

    if (time == null) return;

    final List<int>? days = await _showDaySelector();
    if (days == null || days.isEmpty) return;

    setState(() {
      final updatedReminders = List<PrayerReminder>.from(_settings.reminders);
      updatedReminders.add(
        PrayerReminder(time: time, daysOfWeek: days, enabled: true),
      );
      _settings = _settings.copyWith(reminders: updatedReminders);
      _hasChanges = true;
    });
  }

  void _editReminder(int index) async {
    final reminder = _settings.reminders[index];

    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: reminder.time,
    );

    if (time == null) return;

    final List<int>? days = await _showDaySelector(
      initialSelection: reminder.daysOfWeek,
    );
    if (days == null || days.isEmpty) return;

    setState(() {
      final updatedReminders = List<PrayerReminder>.from(_settings.reminders);
      updatedReminders[index] = PrayerReminder(
        time: time,
        daysOfWeek: days,
        enabled: reminder.enabled,
      );
      _settings = _settings.copyWith(reminders: updatedReminders);
      _hasChanges = true;
    });
  }

  void _deleteReminder(int index) {
    setState(() {
      final updatedReminders = List<PrayerReminder>.from(_settings.reminders);
      updatedReminders.removeAt(index);
      _settings = _settings.copyWith(reminders: updatedReminders);
      _hasChanges = true;
    });
  }

  Future<List<int>?> _showDaySelector({List<int>? initialSelection}) async {
    final selectedDays = Set<int>.from(initialSelection ?? [1, 2, 3, 4, 5, 6, 7]);

    return await showDialog<List<int>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Jours de la semaine'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...List.generate(7, (index) {
                final day = index + 1;
                const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
                return CheckboxListTile(
                  title: Text(days[index]),
                  value: selectedDays.contains(day),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        selectedDays.add(day);
                      } else {
                        selectedDays.remove(day);
                      }
                    });
                  },
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selectedDays.toList()..sort()),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    try {
      await context.read<PrayerTimerProvider>().updateSettings(_settings);

      setState(() {
        _hasChanges = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres enregistrés'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la sauvegarde'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifications non sauvegardées'),
        content: const Text('Voulez-vous quitter sans enregistrer ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final PrayerReminder reminder;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(bool) onToggle;

  const _ReminderCard({
    required this.reminder,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          Icons.alarm,
          color: reminder.enabled ? Colors.blue : Colors.grey,
        ),
        title: Text(
          _formatTime(reminder.time),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_formatDays(reminder.daysOfWeek)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: reminder.enabled,
              onChanged: onToggle,
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDays(List<int> days) {
    const dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    if (days.length == 7) return 'Tous les jours';
    return days.map((d) => dayNames[d - 1]).join(', ');
  }
}