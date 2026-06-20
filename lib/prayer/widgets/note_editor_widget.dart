// lib/features/prayer/widgets/note_editor_widget.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/prayer_note.dart';
import '../providers/prayer_notes_provider.dart';
import '../../../services/Bible_service.dart';
import 'package:memoriz_bible/models/language_provider.dart';
import '../../../constants/book_translations.dart';

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
  final _tagController = TextEditingController();
  final _customTypeController = TextEditingController();
  final _chapterController = TextEditingController();
  final _startVerseController = TextEditingController();
  final _endVerseController = TextEditingController();

  NoteType _selectedType = NoteType.gratitude;
  List<String> _tags = [];

  // Référence biblique structurée
  List<String> _books = [];
  bool _isLoadingBooks = true;
  String? _selectedBook;
  bool _includeVerseReference = false;

  List<VerseData>? _previewedVerses;
  bool _isLoadingVerse = false;
  String? _verseError;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _contentController.text = widget.note!.content;
      _selectedType = widget.note!.type;
      _customTypeController.text = widget.note!.customTypeLabel ?? '';
      _tags = List.from(widget.note!.tags);

      if (widget.note!.verseReference != null &&
          widget.note!.verseReference!.isNotEmpty) {
        _includeVerseReference = true;
        _parseExistingReference(widget.note!.verseReference!);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chargerLivresDepuisJson();
    });
  }

  // Tente de découper une référence existante "Livre Chap:Début-Fin"
  // pour pré-remplir les champs en mode édition.
  void _parseExistingReference(String reference) {
    final match = RegExp(r'^(.+?)\s+(\d+):(\d+)(?:-(\d+))?$').firstMatch(reference);
    if (match != null) {
      _selectedBook = match.group(1);
      _chapterController.text = match.group(2) ?? '';
      _startVerseController.text = match.group(3) ?? '';
      _endVerseController.text = match.group(4) ?? '';
    }
  }

  Future<void> _chargerLivresDepuisJson() async {
    final lang = context.read<LanguageProvider>().language;

    try {
      final String jsonString = await rootBundle.loadString('assets/segond_1910.json');
      final corrected = '[' + jsonString.replaceAll('}{', '},{') + ']';
      final List<dynamic> data = json.decode(corrected);

      String normalizeBookName(String bookName) {
        final normalizations = {
          'Psaumes': 'Psaume',
        };
        return normalizations[bookName] ?? bookName;
      }

      final Set<String> livresUniquesFr = data
          .map((item) => normalizeBookName(item['book_name'] as String))
          .toSet();

      if (mounted) {
        final livresTranslated = livresUniquesFr
            .map((bookFr) => BookTranslations.translate(bookFr, lang))
            .toList()
          ..sort();

        setState(() {
          _books = livresTranslated;
          if (_books.isNotEmpty && _selectedBook == null) {
            final defaultBook = BookTranslations.translate("Jean", lang);
            _selectedBook = _books.contains(defaultBook) ? defaultBook : _books[0];
          }
          _isLoadingBooks = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final fallbackBooksFr = [
          'Genèse', 'Exode', 'Lévitique', 'Nombres', 'Deutéronome',
          'Josué', 'Juges', 'Ruth', '1 Samuel', '2 Samuel',
          '1 Rois', '2 Rois', '1 Chroniques', '2 Chroniques',
          'Esdras', 'Néhémie', 'Esther', 'Job', 'Psaume',
          'Proverbes', 'Ecclésiaste', 'Cantique', 'Ésaïe', 'Jérémie',
          'Lamentations', 'Ézéchiel', 'Daniel', 'Osée', 'Joël',
          'Amos', 'Abdias', 'Jonas', 'Michée', 'Nahum',
          'Habacuc', 'Sophonie', 'Aggée', 'Zacharie', 'Malachie',
          'Matthieu', 'Marc', 'Luc', 'Jean', 'Actes',
          'Romains', '1 Corinthiens', '2 Corinthiens', 'Galates',
          'Éphésiens', 'Philippiens', 'Colossiens', '1 Thessaloniciens',
          '2 Thessaloniciens', '1 Timothée', '2 Timothée', 'Tite',
          'Philémon', 'Hébreux', 'Jacques', '1 Pierre', '2 Pierre',
          '1 Jean', '2 Jean', '3 Jean', 'Jude', 'Apocalypse'
        ];

        final livresTranslated = fallbackBooksFr
            .map((bookFr) => BookTranslations.translate(bookFr, lang))
            .toList();

        setState(() {
          _books = livresTranslated;
          _selectedBook ??= _books.isNotEmpty ? _books[0] : null;
          _isLoadingBooks = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _tagController.dispose();
    _customTypeController.dispose();
    _chapterController.dispose();
    _startVerseController.dispose();
    _endVerseController.dispose();
    super.dispose();
  }

  // Construit la référence au format strict attendu par BibleService :
  // "Livre Chapitre:Verset" ou "Livre Chapitre:Début-Fin"
  String? _buildReference() {
    if (!_includeVerseReference) return null;
    if (_selectedBook == null) return null;

    final chapter = _chapterController.text.trim();
    final startVerse = _startVerseController.text.trim();
    final endVerse = _endVerseController.text.trim();

    if (chapter.isEmpty || startVerse.isEmpty) return null;

    return endVerse.isNotEmpty
        ? '$_selectedBook $chapter:$startVerse-$endVerse'
        : '$_selectedBook $chapter:$startVerse';
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
            DropdownButtonFormField<NoteType>(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
              value: _selectedType,
              isExpanded: true,
              items: NoteType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _getTypeColor(type),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(type.displayName(widget.language)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (type) {
                if (type != null) {
                  setState(() {
                    _selectedType = type;
                  });
                }
              },
            ),

            // Champ texte libre, visible seulement si "Autre" est sélectionné
            if (_selectedType == NoteType.autre) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _customTypeController,
                decoration: InputDecoration(
                  labelText: widget.language == 'fr'
                      ? 'Précisez le type'
                      : 'Specify the type',
                  hintText: widget.language == 'fr'
                      ? 'Ex: Adoration silencieuse'
                      : 'Ex: Silent worship',
                  prefixIcon: const Icon(Icons.edit),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (_selectedType == NoteType.autre &&
                      (value == null || value.trim().isEmpty)) {
                    return widget.language == 'fr'
                        ? 'Veuillez préciser le type'
                        : 'Please specify the type';
                  }
                  return null;
                },
              ),
            ],

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

            // Référence biblique — toggle + sélecteurs structurés
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                widget.language == 'fr'
                    ? 'Associer une référence biblique'
                    : 'Attach a Bible reference',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              value: _includeVerseReference,
              onChanged: (value) {
                setState(() {
                  _includeVerseReference = value;
                  if (!value) {
                    _previewedVerses = null;
                    _verseError = null;
                  }
                });
              },
            ),

            if (_includeVerseReference) ...[
              const SizedBox(height: 8),
              if (_isLoadingBooks)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: widget.language == 'fr' ? 'Livre' : 'Book',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  value: _selectedBook,
                  isExpanded: true,
                  menuMaxHeight: 400,
                  items: _books
                      .map((book) => DropdownMenuItem(value: book, child: Text(book)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBook = value;
                      _previewedVerses = null;
                      _verseError = null;
                    });
                  },
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _chapterController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: widget.language == 'fr' ? 'Chapitre' : 'Chapter',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) {
                  setState(() {
                    _previewedVerses = null;
                    _verseError = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startVerseController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: widget.language == 'fr' ? 'Verset début' : 'Start verse',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (_) {
                        setState(() {
                          _previewedVerses = null;
                          _verseError = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _endVerseController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: widget.language == 'fr'
                            ? 'Verset fin (facultatif)'
                            : 'End verse (optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (_) {
                        setState(() {
                          _previewedVerses = null;
                          _verseError = null;
                        });
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _isLoadingVerse ? null : _previewVerse,
                  icon: _isLoadingVerse
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.visibility, size: 18),
                  label: Text(
                    widget.language == 'fr' ? 'Voir le verset' : 'View verse',
                  ),
                ),
              ),

              if (_verseError != null) ...[
                const SizedBox(height: 4),
                Text(
                  _verseError!,
                  style: TextStyle(color: Colors.red[700], fontSize: 13),
                ),
              ],

              if (_previewedVerses != null && _previewedVerses!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.indigo[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.indigo[100]!),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                      children: _previewedVerses!.map((verse) {
                        final verseNumber = verse.reference.split(':').last;
                        return TextSpan(
                          children: [
                            TextSpan(
                              text: ' $verseNumber ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                            TextSpan(text: verse.text),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ],

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
      case NoteType.gratitude:
        return fr ? 'Pour quoi êtes-vous reconnaissant ?' : 'What are you grateful for?';
      case NoteType.demande:
        return fr ? 'Quelle est votre demande ?' : 'What is your request?';
      case NoteType.intercession:
        return fr ? 'Pour qui priez-vous ?' : 'Who are you praying for?';
      case NoteType.revelation:
        return fr ? 'Quelle révélation avez-vous reçue ?' : 'What revelation did you receive?';
      case NoteType.meditation:
        return fr ? 'Sur quel texte méditez-vous ?' : 'What text are you meditating on?';
      case NoteType.confession:
        return fr ? 'Qu\'avez-vous à confesser ?' : 'What do you need to confess?';
      case NoteType.louange:
        return fr ? 'Pourquoi louez-vous Dieu ?' : 'Why are you praising God?';
      case NoteType.engagement:
        return fr ? 'Quel engagement prenez-vous ?' : 'What commitment are you making?';
      case NoteType.combat:
        return fr ? 'Contre quoi combattez-vous ?' : 'What are you fighting against?';
      case NoteType.temoignage:
        return fr ? 'Quelle prière a reçu une réponse ?' : 'What prayer was answered?';
      case NoteType.autre:
        return fr ? 'Décrivez votre note...' : 'Describe your note...';
    }
  }

  Color _getTypeColor(NoteType type) {
    switch (type) {
      case NoteType.gratitude:
        return Colors.green;
      case NoteType.demande:
        return Colors.blue;
      case NoteType.intercession:
        return Colors.pink;
      case NoteType.revelation:
        return Colors.purple;
      case NoteType.meditation:
        return Colors.teal;
      case NoteType.confession:
        return Colors.indigo;
      case NoteType.louange:
        return Colors.amber;
      case NoteType.engagement:
        return Colors.deepOrange;
      case NoteType.combat:
        return Colors.red;
      case NoteType.temoignage:
        return Colors.lightGreen;
      case NoteType.autre:
        return Colors.grey;
    }
  }

  Future<void> _previewVerse() async {
    final reference = _buildReference();
    if (reference == null) {
      setState(() {
        _verseError = widget.language == 'fr'
            ? 'Veuillez choisir un livre, un chapitre et un verset'
            : 'Please choose a book, chapter, and verse';
        _previewedVerses = null;
      });
      return;
    }

    setState(() {
      _isLoadingVerse = true;
      _verseError = null;
      _previewedVerses = null;
    });

    try {
      final lang = context.read<LanguageProvider>().language;
      final verseData = await BibleService().getPassageText(
        reference,
        language: lang,
      );

      if (!mounted) return;

      if (verseData.isEmpty) {
        setState(() {
          _verseError = widget.language == 'fr'
              ? 'Référence introuvable : $reference'
              : 'Reference not found: $reference';
          _isLoadingVerse = false;
        });
        return;
      }

      setState(() {
        _previewedVerses = verseData;
        _isLoadingVerse = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verseError = widget.language == 'fr'
            ? 'Impossible de vérifier cette référence'
            : 'Unable to verify this reference';
        _isLoadingVerse = false;
      });
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
    final verseRef = _buildReference();
    final customLabel = _customTypeController.text.trim();

    bool success;
    if (widget.note == null) {
      // Création
      final noteId = await notesProvider.createNote(
        type: _selectedType,
        customTypeLabel: _selectedType == NoteType.autre && customLabel.isNotEmpty
            ? customLabel
            : null,
        content: content,
        verseReference: verseRef,
        sessionId: widget.sessionId,
        tags: _tags,
      );
      success = noteId != null;
    } else {
      // Mise à jour
      success = await notesProvider.updateNote(
        noteId: widget.note!.id,
        type: _selectedType,
        customTypeLabel: _selectedType == NoteType.autre && customLabel.isNotEmpty
            ? customLabel
            : null,
        content: content,
        verseReference: verseRef,
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
