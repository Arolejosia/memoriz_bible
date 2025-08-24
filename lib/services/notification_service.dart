// Fichier : lib/services/notification_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {}

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(initSettings);
  }

  /// Programme une notification quotidienne.
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await cancelAll(); // Annule les anciens rappels
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    const android = AndroidNotificationDetails('daily_channel', 'Rappels quotidiens');
    const ios = DarwinNotificationDetails();
    await _plugin.zonedSchedule(
      id, title, body, scheduled,
      const NotificationDetails(android: android, iOS: ios),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Programme une notification hebdomadaire pour des jours spécifiques.
  Future<void> scheduleWeekly({
    required int hour,
    required int minute,
    required List<int> days,
    required String title,
    required String body,
  }) async {
    await cancelAll();
    const android = AndroidNotificationDetails('weekly_channel', 'Rappels hebdomadaires');
    const ios = DarwinNotificationDetails();
    const details = NotificationDetails(android: android, iOS: ios);

    for (final day in days) {
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      while (scheduled.weekday != day || scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        day, title, body, scheduled, details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // priorité au système par défaut

  ThemeMode get themeMode => _themeMode;

  void setTheme(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}

class ThemeSwitcher extends StatelessWidget {
  const ThemeSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("🌞"),
        Switch(
          value: themeProvider.themeMode == ThemeMode.dark,
          onChanged: (bool value) {
            if (value) {
              themeProvider.setTheme(ThemeMode.dark); // forcer sombre
            } else {
              themeProvider.setTheme(ThemeMode.system); // retour au système
            }
          },
        ),
        const Text("🌙"),
      ],
    );
  }
}

