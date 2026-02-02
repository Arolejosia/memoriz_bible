// lib/features/prayer/models/prayer_settings.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PrayerReminder {
  final TimeOfDay time;
  final List<int> daysOfWeek; // 1-7 (Lundi-Dimanche)
  final bool enabled;

  PrayerReminder({
    required this.time,
    required this.daysOfWeek,
    this.enabled = true,
  });

  factory PrayerReminder.fromMap(Map<String, dynamic> map) {
    return PrayerReminder(
      time: TimeOfDay(
        hour: map['hour'] ?? 8,
        minute: map['minute'] ?? 0,
      ),
      daysOfWeek: List<int>.from(map['daysOfWeek'] ?? [1, 2, 3, 4, 5, 6, 7]),
      enabled: map['enabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hour': time.hour,
      'minute': time.minute,
      'daysOfWeek': daysOfWeek,
      'enabled': enabled,
    };
  }

  PrayerReminder copyWith({
    TimeOfDay? time,
    List<int>? daysOfWeek,
    bool? enabled,
  }) {
    return PrayerReminder(
      time: time ?? this.time,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      enabled: enabled ?? this.enabled,
    );
  }
}

class PrayerSettings {
  final int dailyGoalMinutes; // en minutes (15 par défaut)
  final List<PrayerReminder> reminders;
  final bool notificationsEnabled;
  final bool showStreakReminders;
  final bool autoSaveNotes;

  PrayerSettings({
    this.dailyGoalMinutes = 15,
    this.reminders = const [],
    this.notificationsEnabled = true,
    this.showStreakReminders = true,
    this.autoSaveNotes = true,
  });

  int get dailyGoalSeconds => dailyGoalMinutes * 60;

  factory PrayerSettings.fromFirestore(DocumentSnapshot? doc) {
    if (doc == null || !doc.exists) {
      return PrayerSettings();
    }

    final data = doc.data() as Map<String, dynamic>;
    return PrayerSettings(
      dailyGoalMinutes: data['dailyGoalMinutes'] ?? 15,
      reminders: (data['reminders'] as List<dynamic>?)
          ?.map((r) => PrayerReminder.fromMap(r as Map<String, dynamic>))
          .toList() ??
          [],
      notificationsEnabled: data['notificationsEnabled'] ?? true,
      showStreakReminders: data['showStreakReminders'] ?? true,
      autoSaveNotes: data['autoSaveNotes'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'dailyGoalMinutes': dailyGoalMinutes,
      'reminders': reminders.map((r) => r.toMap()).toList(),
      'notificationsEnabled': notificationsEnabled,
      'showStreakReminders': showStreakReminders,
      'autoSaveNotes': autoSaveNotes,
    };
  }

  PrayerSettings copyWith({
    int? dailyGoalMinutes,
    List<PrayerReminder>? reminders,
    bool? notificationsEnabled,
    bool? showStreakReminders,
    bool? autoSaveNotes,
  }) {
    return PrayerSettings(
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      reminders: reminders ?? this.reminders,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      showStreakReminders: showStreakReminders ?? this.showStreakReminders,
      autoSaveNotes: autoSaveNotes ?? this.autoSaveNotes,
    );
  }
}