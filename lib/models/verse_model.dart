// Fichier: lib/verse_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum VerseStatus { neutral, learning, mastered }

class Verse {
  final String id;
  final String reference;
  final String book;
  final VerseStatus status;
  final int progressLevel;
  final bool isUserAdded;
  final DateTime? updatedAt;
  final Map<String, int> scores;
  final Map<String, int> failedAttempts;

  // ✅ NOUVEAU : Champs pour la Répétition Espacée (SRS)
  final int srsLevel;
  final DateTime? reviewDate;

  Verse({
    required this.id,
    required this.reference,
    required this.book,
    required this.status,
    required this.progressLevel,
    required this.isUserAdded,
    this.updatedAt,
    required this.scores,
    required this.failedAttempts,
    // ✅ NOUVEAU
    required this.srsLevel,
    this.reviewDate,
  });

  factory Verse.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Verse(
      id: doc.id,
      reference: data['reference'] ?? '',
      book: data['book'] ?? '',
      status: VerseStatus.values.firstWhere((e) => e.name == data['status'], orElse: () => VerseStatus.neutral),
      progressLevel: data['progressLevel'] ?? 0,
      isUserAdded: data['isUserAdded'] ?? false,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      scores: Map<String, int>.from(data['scores'] ?? {}),
      failedAttempts: Map<String, int>.from(data['failedAttempts'] ?? {}),
      // ✅ NOUVEAU : Lire les données SRS depuis Firestore
      srsLevel: data['srsLevel'] ?? 0,
      reviewDate: (data['reviewDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reference': reference,
      'book': book,
      'status': status.name,
      'progressLevel': progressLevel,
      'isUserAdded': isUserAdded,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'scores': scores,
      'failedAttempts': failedAttempts,
      // ✅ NOUVEAU : Écrire les données SRS dans Firestore
      'srsLevel': srsLevel,
      'reviewDate': reviewDate != null ? Timestamp.fromDate(reviewDate!) : null,
    };
  }
}