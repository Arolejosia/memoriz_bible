// lib/features/prayer/providers/prayer_notes_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/prayer_note.dart';

class PrayerNotesProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  List<PrayerNote> _notes = [];
  bool _isLoading = false;
  String? _errorMessage;

  PrayerNotesProvider({required this.userId}) {
    loadNotes();
  }

  // Getters
  List<PrayerNote> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Charger toutes les notes
  Future<void> loadNotes({int limit = 50}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('prayerNotes')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      _notes = snapshot.docs
          .map((doc) => PrayerNote.fromFirestore(doc))
          .toList();

      debugPrint('✅ ${_notes.length} notes chargées');
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des notes';
      debugPrint('❌ Erreur chargement notes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Créer une nouvelle note
  Future<String?> createNote({
    required NoteType type,
    String? customTypeLabel,
    required String content,
    String? verseReference,
    String? sessionId,
    List<String>? tags,
  }) async {
    try {
      final now = DateTime.now();
      final noteRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('prayerNotes')
          .doc();

      final note = PrayerNote(
        id: noteRef.id,
        createdAt: now,
        updatedAt: now,
        type: type,
        customTypeLabel: customTypeLabel,
        content: content,
        verseReference: verseReference,
        sessionIds: sessionId != null ? [sessionId] : [],
        tags: tags ?? [],
      );

      await noteRef.set(note.toFirestore());

      // Ajouter à la liste locale
      _notes.insert(0, note);
      notifyListeners();

      debugPrint('✅ Note créée: ${note.id}');
      return note.id;
    } catch (e) {
      _errorMessage = 'Erreur lors de la création de la note';
      debugPrint('❌ Erreur création note: $e');
      return null;
    }
  }

  // Mettre à jour une note
  Future<bool> updateNote({
    required String noteId,
    String? content,
    NoteType? type,
    String? customTypeLabel,
    String? verseReference,
    List<String>? tags,
  }) async {
    try {
      final noteIndex = _notes.indexWhere((n) => n.id == noteId);
      if (noteIndex == -1) {
        debugPrint('❌ Note non trouvée: $noteId');
        return false;
      }

      final existingNote = _notes[noteIndex];
      final updatedNote = existingNote.copyWith(
        content: content,
        type: type,
        customTypeLabel: customTypeLabel,
        verseReference: verseReference,
        tags: tags,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('prayerNotes')
          .doc(noteId)
          .update({
        if (content != null) 'content': content,
        if (type != null) 'type': type.name,
        'customTypeLabel': customTypeLabel,
        if (verseReference != null) 'verseReference': verseReference,
        if (tags != null) 'tags': tags,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Mettre à jour la liste locale
      _notes[noteIndex] = updatedNote;
      notifyListeners();

      debugPrint('✅ Note mise à jour: $noteId');
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la mise à jour de la note';
      debugPrint('❌ Erreur mise à jour note: $e');
      return false;
    }
  }

  // Supprimer une note
  Future<bool> deleteNote(String noteId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('prayerNotes')
          .doc(noteId)
          .delete();

      // Supprimer de la liste locale
      _notes.removeWhere((n) => n.id == noteId);
      notifyListeners();

      debugPrint('✅ Note supprimée: $noteId');
      return true;
    } catch (e) {
      _errorMessage = 'Erreur lors de la suppression de la note';
      debugPrint('❌ Erreur suppression note: $e');
      return false;
    }
  }

  // Lier une note à une session
  Future<bool> linkNoteToSession(String noteId, String sessionId) async {
    try {
      final noteIndex = _notes.indexWhere((n) => n.id == noteId);
      if (noteIndex == -1) return false;

      final note = _notes[noteIndex];
      if (note.sessionIds.contains(sessionId)) {
        debugPrint('⚠️ Session déjà liée à la note');
        return true;
      }

      final updatedSessionIds = [...note.sessionIds, sessionId];

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('prayerNotes')
          .doc(noteId)
          .update({
        'sessionIds': updatedSessionIds,
      });

      _notes[noteIndex] = note.copyWith(sessionIds: updatedSessionIds);
      notifyListeners();

      debugPrint('✅ Note liée à la session: $sessionId');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur liaison note-session: $e');
      return false;
    }
  }

  // Filtrer les notes par type
  List<PrayerNote> getNotesByType(NoteType type) {
    return _notes.where((note) => note.type == type).toList();
  }

  // Filtrer les notes par session
  List<PrayerNote> getNotesBySession(String sessionId) {
    return _notes.where((note) => note.sessionIds.contains(sessionId)).toList();
  }

  // Rechercher dans les notes
  List<PrayerNote> searchNotes(String query) {
    final lowerQuery = query.toLowerCase();
    return _notes.where((note) {
      return note.content.toLowerCase().contains(lowerQuery) ||
          (note.verseReference?.toLowerCase().contains(lowerQuery) ?? false) ||
          note.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  // Obtenir les tags uniques
  List<String> getAllTags() {
    final allTags = <String>{};
    for (final note in _notes) {
      allTags.addAll(note.tags);
    }
    return allTags.toList()..sort();
  }
}
