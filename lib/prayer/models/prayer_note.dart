// lib/features/prayer/models/prayer_note.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum NoteType {
  gratitude,
  demande,
  intercession,
  revelation,
  meditation,
  confession,
  louange,
  engagement,
  combat,
  temoignage,
  autre;

  String get displayNameFr {
    switch (this) {
      case NoteType.gratitude:
        return '🙌 Gratitude';
      case NoteType.demande:
        return '🤲 Demande';
      case NoteType.intercession:
        return '❤️ Intercession';
      case NoteType.revelation:
        return '💡 Révélation';
      case NoteType.meditation:
        return '📖 Méditation';
      case NoteType.confession:
        return '🕊️ Confession';
      case NoteType.louange:
        return '🎶 Louange';
      case NoteType.engagement:
        return '🎯 Engagement';
      case NoteType.combat:
        return '⚔️ Combat';
      case NoteType.temoignage:
        return '✅ Témoignage';
      case NoteType.autre:
        return '✏️ Autre';
    }
  }

  String get displayNameEn {
    switch (this) {
      case NoteType.gratitude:
        return '🙌 Gratitude';
      case NoteType.demande:
        return '🤲 Request';
      case NoteType.intercession:
        return '❤️ Intercession';
      case NoteType.revelation:
        return '💡 Revelation';
      case NoteType.meditation:
        return '📖 Meditation';
      case NoteType.confession:
        return '🕊️ Confession';
      case NoteType.louange:
        return '🎶 Praise';
      case NoteType.engagement:
        return '🎯 Commitment';
      case NoteType.combat:
        return '⚔️ Spiritual battle';
      case NoteType.temoignage:
        return '✅ Testimony';
      case NoteType.autre:
        return '✏️ Other';
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
  final String? customTypeLabel;
  final String content;
  final String? verseReference;
  final List<String> sessionIds;
  final List<String> tags;

  PrayerNote({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.type,
    this.customTypeLabel,
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
        orElse: () => NoteType.gratitude,
      ),
      customTypeLabel: data['customTypeLabel'],
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
      'customTypeLabel': customTypeLabel,
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
    String? customTypeLabel,
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
      customTypeLabel: customTypeLabel ?? this.customTypeLabel,
      content: content ?? this.content,
      verseReference: verseReference ?? this.verseReference,
      sessionIds: sessionIds ?? this.sessionIds,
      tags: tags ?? this.tags,
    );
  }
}
