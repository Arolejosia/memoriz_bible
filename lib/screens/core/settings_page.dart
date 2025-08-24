// Fichier : lib/settings_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';

enum NotificationFrequency { daily, weekly }

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  TimeOfDay? _selectedTime;
  NotificationFrequency _frequency = NotificationFrequency.daily;
  final Set<int> _selectedDays = {1, 2, 3, 4, 5};

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
      _scheduleNotification();
    }
  }

  /// ✅ CORRECTION : Cette fonction contient maintenant la bonne logique if/else
  Future<void> _scheduleNotification() async {
    if (_selectedTime == null || !_notificationsEnabled) {
      await NotificationService.instance.cancelAll();
      return;
    }

    if (_frequency == NotificationFrequency.daily) {
      // --- Appel pour la notification quotidienne ---
      await NotificationService.instance.scheduleDaily(
        id: 0,
        hour: _selectedTime!.hour,
        minute: _selectedTime!.minute,
        title: '📖 C\'est l\'heure de votre révision !',
        body: 'Quelques versets vous attendent pour être mémorisés.',
      );
    } else { // Si la fréquence est hebdomadaire
      if (_selectedDays.isEmpty) {
        await NotificationService.instance.cancelAll();
        return;
      }
      // --- Appel pour la notification hebdomadaire ---
      await NotificationService.instance.scheduleWeekly(
        hour: _selectedTime!.hour,
        minute: _selectedTime!.minute,
        days: _selectedDays.toList(),
        title: '📖 C\'est l\'heure de votre révision !',
        body: 'Quelques versets vous attendent pour être mémorisés.',
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rappel programmé avec succès !")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    // ... Le reste de votre code build est bon ...
    // ... (Scaffold, ListView, ListTile pour l'heure, Dropdown, ChoiceChip) ...
    // Aucune modification n'est nécessaire dans la partie UI.
    return Scaffold(
      appBar: AppBar(title: const Text("Paramètres")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [ const Text("Apparence", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

      const SizedBox(height: 10),

      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Mode sombre (ou système)", style: TextStyle(fontSize: 16)),

          Switch(
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (bool value) {
              if (value) {
                themeProvider.setTheme(ThemeMode.dark); // forcer dark
              } else {
                themeProvider.setTheme(ThemeMode.system); // retour au system
              }
            },
          ),
        ],
      ),
          SwitchListTile(
            title: const Text("Activer les rappels"),
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() => _notificationsEnabled = value);
              _scheduleNotification();
            },
            secondary: const Icon(Icons.notifications_active_outlined),
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text("Heure du rappel"),
            subtitle: Text(_selectedTime?.format(context) ?? "Choisir une heure"),
            onTap: () => _selectTime(context),
            enabled: _notificationsEnabled,
          ),
          DropdownButtonFormField<NotificationFrequency>(
            value: _frequency,
            decoration: const InputDecoration(
              labelText: "Fréquence",
              border: InputBorder.none,
              prefixIcon: Icon(Icons.update_outlined),
            ),
            items: const [
              DropdownMenuItem(value: NotificationFrequency.daily, child: Text("Chaque jour")),
              DropdownMenuItem(value: NotificationFrequency.weekly, child: Text("Chaque semaine")),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _frequency = value);
                _scheduleNotification();
              }
            },
          ),
          if (_frequency == NotificationFrequency.weekly)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Wrap(
                spacing: 8.0,
                alignment: WrapAlignment.center,
                children: [
                  for (int i = 1; i <= 7; i++)
                    ChoiceChip(
                      label: Text(['L', 'M', 'M', 'J', 'V', 'S', 'D'][i - 1]),
                      selected: _selectedDays.contains(i),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) _selectedDays.add(i);
                          else _selectedDays.remove(i);
                        });
                        _scheduleNotification();
                      },
                    ),
                  ThemeSwitcher(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}