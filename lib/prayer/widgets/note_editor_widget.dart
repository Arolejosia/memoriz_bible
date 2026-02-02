// lib/features/prayer/widgets/note_editor_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/prayer_note.dart';
import '../providers/prayer_notes_provider.dart';

class NoteEditorWidget extends StatefulWidget {
  final PrayerNote? note; // null = création, non-null = édition
  final String? sessionId;
  final String language;

  const NoteEditorWidget({
    Key? key,
    this.note,
    this.sessionId,
    this.language = 'fr',
  }) : super(key: key);

  @override
  State<NoteEditorWidget> createState() => _NoteEditorWidgetState();
}

class _NoteEditorWidgetState extends State<NoteEditorWidget> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _verseController = TextEditingController();
  final _tagController = TextEditingController();

  NoteType _selectedType = NoteType.intention;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _contentController.text = widget.note!.content;
      _verseController.text = widget.note!.verseReference ?? '';
      _selectedType = widget.note!.type;
      _tags = List.from(widget.note!.tags);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _verseController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.note == null
              ? (widget.language == 'fr' ? 'Nouvelle note' : 'New note')
              : (widget.language == 'fr' ? 'Modifier la note' : 'Edit note'),
        ),
        actions: [
          if (widget.note != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sélection du type
            Text(
              widget.language == 'fr' ? 'Type de note' : 'Note type',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: NoteType.values.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type.displayName(widget.language)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = type;
                    });
                  },
                  selectedColor: _getTypeColor(type).withOpacity(0.3),
                  backgroundColor: Colors.grey[200],
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Contenu de la note
            TextFormField(
              controller: _contentController,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: widget.language == 'fr' ? 'Votre note' : 'Your note',
                hintText: _getHintText(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return widget.language == 'fr'
                      ? 'Veuillez entrer du contenu'
                      : 'Please enter content';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // Référence biblique (optionnel)
            TextFormField(
              controller: _verseController,
              decoration: InputDecoration(
                labelText: widget.language == 'fr'
                    ? 'Référence biblique (optionnel)'
                    : 'Bible reference (optional)',
                hintText: widget.language == 'fr'
                    ? 'Ex: Jean 3:16'
                    : 'Ex: John 3:16',
                prefixIcon: const Icon(Icons.menu_book),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Tags
            Text(
              widget.language == 'fr' ? 'Étiquettes' : 'Tags',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ..._tags.map((tag) => Chip(
                  label: Text(tag),
                  onDeleted: () {
                    setState(() {
                      _tags.remove(tag);
                    });
                  },
                )),
                ActionChip(
                  label: const Icon(Icons.add, size: 18),
                  onPressed: _addTag,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Bouton de sauvegarde
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saveNote,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.note == null
                      ? (widget.language == 'fr' ? 'Créer la note' : 'Create note')
                      : (widget.language == 'fr' ? 'Sauvegarder' : 'Save'),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getHintText() {
    final fr = widget.language == 'fr';
    switch (_selectedType) {
      case NoteType.intention:
        return fr
            ? 'Décrivez votre intention de prière...'
            : 'Describe your prayer intention...';
      case NoteType.gratitude:
        return fr
            ? 'Pour quoi êtes-vous reconnaissant ?'
            : 'What are you grateful for?';
      case NoteType.revelation:
        return fr
            ? 'Quelle révélation avez-vous reçue ?'
            : 'What revelation did you receive?';
    }
  }

  Color _getTypeColor(NoteType type) {
    switch (type) {
      case NoteType.intention:
        return Colors.blue;
      case NoteType.gratitude:
        return Colors.green;
      case NoteType.revelation:
        return Colors.purple;
    }
  }

  void _addTag() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          widget.language == 'fr' ? 'Ajouter une étiquette' : 'Add a tag',
        ),
        content: TextField(
          controller: _tagController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: widget.language == 'fr' ? 'Nom de l\'étiquette' : 'Tag name',
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty && !_tags.contains(value)) {
              setState(() {
                _tags.add(value);
              });
              _tagController.clear();
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.language == 'fr' ? 'Annuler' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = _tagController.text.trim();
              if (value.isNotEmpty && !_tags.contains(value)) {
                setState(() {
                  _tags.add(value);
                });
                _tagController.clear();
                Navigator.pop(context);
              }
            },
            child: Text(widget.language == 'fr' ? 'Ajouter' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    final notesProvider = context.read<PrayerNotesProvider>();
    final content = _contentController.text.trim();
    final verseRef = _verseController.text.trim();

    bool success;
    if (widget.note == null) {
      // Création
      final noteId = await notesProvider.createNote(
        type: _selectedType,
        content: content,
        verseReference: verseRef.isNotEmpty ? verseRef : null,
        sessionId: widget.sessionId,
        tags: _tags,
      );
      success = noteId != null;
    } else {
      // Mise à jour
      success = await notesProvider.updateNote(
        noteId: widget.note!.id,
        type: _selectedType,
        content: content,
        verseReference: verseRef.isNotEmpty ? verseRef : null,
        tags: _tags,
      );
    }

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.language == 'fr'
                ? 'Note sauvegardée avec succès'
                : 'Note saved successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.language == 'fr'
                ? 'Erreur lors de la sauvegarde'
                : 'Error saving note',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          widget.language == 'fr' ? 'Supprimer la note ?' : 'Delete note?',
        ),
        content: Text(
          widget.language == 'fr'
              ? 'Cette action est irréversible.'
              : 'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(widget.language == 'fr' ? 'Annuler' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Fermer le dialog
              final success = await context
                  .read<PrayerNotesProvider>()
                  .deleteNote(widget.note!.id);
              if (mounted) {
                Navigator.pop(context); // Fermer l'éditeur
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? (widget.language == 'fr'
                          ? 'Note supprimée'
                          : 'Note deleted')
                          : (widget.language == 'fr'
                          ? 'Erreur lors de la suppression'
                          : 'Error deleting note'),
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(widget.language == 'fr' ? 'Supprimer' : 'Delete'),
          ),
        ],
      ),
    );
  }
}