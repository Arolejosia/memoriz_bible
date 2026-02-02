// lib/features/prayer/models/prayer_note.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum NoteType {
  intention,
  gratitude,
  revelation;

  String get displayNameFr {
    switch (this) {
      case NoteType.intention:
        return '🙏 Intention';
      case NoteType.gratitude:
        return '🙌 Gratitude';
      case NoteType.revelation:
        return '💡 Révélation';
    }
  }

  String get displayNameEn {
    switch (this) {
      case NoteType.intention:
        return '🙏 Intention';
      case NoteType.gratitude:
        return '🙌 Gratitude';
      case NoteType.revelation:
        return '💡 Revelation';
    }
  }

  String displayName(String language) {
    return language == 'fr' ? displayNameFr : displayNameEn;
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

  PrayerNote copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    NoteType? type,
    String? content,
    String? verseReference,
    List<String>? sessionIds,
    List<String>? tags,
  }) {
    return PrayerNote(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      type: type ?? this.type,
      content: content ?? this.content,
      verseReference: verseReference ?? this.verseReference,
      sessionIds: sessionIds ?? this.sessionIds,
      tags: tags ?? this.tags,
    );
  }
}