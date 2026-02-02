// lib/features/prayer/models/prayer_session.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PrayerSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final int duration; // en secondes
  final String date; // YYYY-MM-DD
  final String? noteId;
  final bool isCompleted;

  PrayerSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.date,
    this.noteId,
    required this.isCompleted,
  });

  factory PrayerSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PrayerSession(
      id: doc.id,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null
          ? (data['endTime'] as Timestamp).toDate()
          : null,
      duration: data['duration'] ?? 0,
      date: data['date'] ?? '',
      noteId: data['noteId'],
      isCompleted: data['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'duration': duration,
      'date': date,
      'noteId': noteId,
      'isCompleted': isCompleted,
    };
  }

  String get formattedDuration {
    final hours = duration ~/ 3600;
    final minutes = (duration % 3600) ~/ 60;
    final seconds = duration % 60;

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}min';
    } else if (minutes > 0) {
      return '${minutes}min ${seconds.toString().padLeft(2, '0')}s';
    } else {
      return '${seconds}s';
    }
  }
}

// lib/features/prayer/models/prayer_note.dart
enum NoteType {
  intention,
  gratitude,
  revelation;

  String get displayName {
    switch (this) {
      case NoteType.intention:
        return '🙏 Intention';
      case NoteType.gratitude:
        return '🙌 Gratitude';
      case NoteType.revelation:
        return '💡 Révélation';
    }
  }
}

class PrayerNote {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final NoteType type;
  final String content;
  final String? verseReference;
  final List<String> sessionIds;
  final List<String> tags;

  PrayerNote({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.type,
    required this.content,
    this.verseReference,
    required this.sessionIds,
    required this.tags,
  });

  factory PrayerNote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PrayerNote(
      id: doc.id,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      type: NoteType.values.firstWhere(
            (e) => e.name == data['type'],
        orElse: () => NoteType.intention,
      ),
      content: data['content'] ?? '',
      verseReference: data['verseReference'],
      sessionIds: List<String>.from(data['sessionIds'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'type': type.name,
      'content': content,
      'verseReference': verseReference,
      'sessionIds': sessionIds,
      'tags': tags,
    };
  }
}

// lib/features/prayer/models/daily_prayer_stats.dart
class DailyPrayerStats {
  final String date; // YYYY-MM-DD
  final int totalSeconds;
  final int goalSeconds;
  final int sessionsCount;
  final bool goalAchieved;
  final int streak;

  DailyPrayerStats({
    required this.date,
    required this.totalSeconds,
    required this.goalSeconds,
    required this.sessionsCount,
    required this.goalAchieved,
    required this.streak,
  });

  factory DailyPrayerStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyPrayerStats(
      date: doc.id,
      totalSeconds: data['totalSeconds'] ?? 0,
      goalSeconds: data['goalSeconds'] ?? 3600,
      sessionsCount: data['sessionsCount'] ?? 0,
      goalAchieved: data['goalAchieved'] ?? false,
      streak: data['streak'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'totalSeconds': totalSeconds,
      'goalSeconds': goalSeconds,
      'sessionsCount': sessionsCount,
      'goalAchieved': goalAchieved,
      'streak': streak,
    };
  }

  double get progressPercentage {
    return (totalSeconds / goalSeconds * 100).clamp(0, 100);
  }

  String get formattedTotal {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    return hours > 0 ? '${hours}h ${minutes}min' : '${minutes}min';
  }

  String get formattedGoal {
    final hours = goalSeconds ~/ 3600;
    final minutes = (goalSeconds % 3600) ~/ 60;
    return hours > 0 ? '${hours}h ${minutes}min' : '${minutes}min';
  }
}