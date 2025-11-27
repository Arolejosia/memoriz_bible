// File: lib/screens/bible_reference_picker_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:memoriz_bible/services/bible_validation_service.dart';
import 'package:memoriz_bible/models/language_provider.dart';

/// Translations for Bible reference picker
/// Traductions pour le sélecteur de référence biblique
class ReferencePickerTranslations {
  static String t(String key, String lang) {
    final translations = {
      'choose_passage': {'fr': 'Choisir un passage', 'en': 'Choose a passage'},
      'select_passage': {'fr': 'Sélectionnez votre passage biblique', 'en': 'Select your Bible passage'},
      'book': {'fr': 'Livre', 'en': 'Book'},
      'chapter': {'fr': 'Chapitre', 'en': 'Chapter'},
      'verse_start': {'fr': 'Verset début', 'en': 'Start verse'},
      'verse_end': {'fr': 'Verset fin', 'en': 'End verse'},
      'optional': {'fr': 'Optionnel', 'en': 'Optional'},
      'validate_reference': {'fr': 'VALIDER LA RÉFÉRENCE', 'en': 'VALIDATE REFERENCE'},
      'auto_validated': {'fr': 'La référence sera automatiquement validée avant d\'être ajoutée.', 'en': 'The reference will be automatically validated before being added.'},
      'loading_bible': {'fr': 'Chargement de la Bible...', 'en': 'Loading Bible...'},
      'fill_required': {'fr': 'Veuillez remplir tous les champs obligatoires.', 'en': 'Please fill in all required fields.'},
      'reference_invalid': {'fr': 'Référence invalide', 'en': 'Invalid reference'},
      'error_message': {'fr': 'Si vous pensez qu\'il s\'agit d\'une erreur, contactez notre support technique.', 'en': 'If you think this is an error, contact our technical support.'},
      'support': {'fr': 'Support', 'en': 'Support'},
      'cancel': {'fr': 'Annuler', 'en': 'Cancel'},
      'play': {'fr': 'JOUER', 'en': 'PLAY'},
    };
    return translations[key]?[lang] ?? key;
  }
}

class BibleReferencePickerPage extends StatefulWidget {
  final String? initialReference;

  const BibleReferencePickerPage({super.key, this.initialReference});

  @override
  State<BibleReferencePickerPage> createState() => _BibleReferencePickerPageState();
}

class _BibleReferencePickerPageState extends State<BibleReferencePickerPage> {
  bool _isLoadingBooks = true;
  List<String> books = [];
  String? _selectedBook;
  final _chapterController = TextEditingController();
  final _startVerseController = TextEditingController();
  final _endVerseController = TextEditingController();

  // ✅ LIVRES EN FRANÇAIS
  static const List<String> _frenchBooks = [
    // Ancien Testament
    'Genèse', 'Exode', 'Lévitique', 'Nombres', 'Deutéronome',
    'Josué', 'Juges', 'Ruth', '1 Samuel', '2 Samuel',
    '1 Rois', '2 Rois', '1 Chroniques', '2 Chroniques',
    'Esdras', 'Néhémie', 'Esther', 'Job',
    'Psaumes', 'Proverbes', 'Ecclésiaste', 'Cantique',
    'Ésaïe', 'Jérémie', 'Lamentations', 'Ézéchiel', 'Daniel',
    'Osée', 'Joël', 'Amos', 'Abdias', 'Jonas', 'Michée',
    'Nahum', 'Habacuc', 'Sophonie', 'Aggée', 'Zacharie', 'Malachie',
    // Nouveau Testament
    'Matthieu', 'Marc', 'Luc', 'Jean',
    'Actes', 'Romains',
    '1 Corinthiens', '2 Corinthiens',
    'Galates', 'Éphésiens', 'Philippiens', 'Colossiens',
    '1 Thessaloniciens', '2 Thessaloniciens',
    '1 Timothée', '2 Timothée', 'Tite', 'Philémon',
    'Hébreux', 'Jacques',
    '1 Pierre', '2 Pierre',
    '1 Jean', '2 Jean', '3 Jean',
    'Jude', 'Apocalypse',
  ];

  // ✅ LIVRES EN ANGLAIS
  static const List<String> _englishBooks = [
    // Old Testament
    'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy',
    'Joshua', 'Judges', 'Ruth', '1 Samuel', '2 Samuel',
    '1 Kings', '2 Kings', '1 Chronicles', '2 Chronicles',
    'Ezra', 'Nehemiah', 'Esther', 'Job',
    'Psalms', 'Proverbs', 'Ecclesiastes', 'Song of Solomon',
    'Isaiah', 'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel',
    'Hosea', 'Joel', 'Amos', 'Obadiah', 'Jonah', 'Micah',
    'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah', 'Malachi',
    // New Testament
    'Matthew', 'Mark', 'Luke', 'John',
    'Acts', 'Romans',
    '1 Corinthians', '2 Corinthians',
    'Galatians', 'Ephesians', 'Philippians', 'Colossians',
    '1 Thessalonians', '2 Thessalonians',
    '1 Timothy', '2 Timothy', 'Titus', 'Philemon',
    'Hebrews', 'James',
    '1 Peter', '2 Peter',
    '1 John', '2 John', '3 John',
    'Jude', 'Revelation',
  ];

  String? _maxChapterHint;
  String? _maxVerseHint;
  String _currentLanguage = 'fr';

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  // ✅ Obtenir la liste selon la langue
  List<String> _getBooksForLanguage(String lang) {
    return lang == 'en' ? _englishBooks : _frenchBooks;
  }

  // ✅ Obtenir le livre par défaut selon la langue
  String _getDefaultBook(String lang) {
    return lang == 'en' ? 'John' : 'Jean';
  }

  Future<void> _initializeService() async {
    // ✅ Lire la langue actuelle
    final lang = context.read<LanguageProvider>().language;
    _currentLanguage = lang;

    try {
      await BibleValidationService.initialize();
      // ✅ Passer la langue pour obtenir les bons livres
      final availableBooks = BibleValidationService.getAvailableBooks(language: lang);

      setState(() {
        // Utiliser le service ou le fallback selon la langue
        if (availableBooks.isNotEmpty) {
          books = availableBooks;
          print('✅ Chargé ${books.length} livres depuis BibleValidationService');
        } else {
          books = List.from(_getBooksForLanguage(lang));
          print('⚠️ Service vide, utilisation de ${books.length} livres de fallback ($lang)');
        }

        // Sélectionner le livre par défaut selon la langue
        if (books.isNotEmpty) {
          final defaultBook = _getDefaultBook(lang);
          _selectedBook = books.contains(defaultBook) ? defaultBook : books.first;
        } else {
          _selectedBook = null;
        }

        _isLoadingBooks = false;
      });

      if (widget.initialReference != null) {
        _parseAndSetInitialReference(widget.initialReference!);
      }

      _updateHints();

    } catch (e) {
      print('❌ Erreur BibleValidationService: $e');

      setState(() {
        books = List.from(_getBooksForLanguage(lang));
        _selectedBook = books.isNotEmpty ? _getDefaultBook(lang) : null;
        _isLoadingBooks = false;
        print('⚠️ Erreur service, utilisation de ${books.length} livres de fallback ($lang)');
      });

      if (widget.initialReference != null) {
        _parseAndSetInitialReference(widget.initialReference!);
      }

      _updateHints();
    }
  }

  @override
  void dispose() {
    _chapterController.dispose();
    _startVerseController.dispose();
    _endVerseController.dispose();
    super.dispose();
  }

  // ✅ CORRECTION : Utiliser context.read
  String t(String key) {
    final lang = context.read<LanguageProvider>().language;
    return ReferencePickerTranslations.t(key, lang);
  }

  void _parseAndSetInitialReference(String reference) {
    final regExp = RegExp(r"^(\d?\s?[a-zA-ZÀ-ÿ\s]+)\s(\d+):(\d+)(?:-(\d+))?$");
    final match = regExp.firstMatch(reference.trim());

    if (match != null) {
      final bookName = match.group(1)!.trim();
      final chapter = match.group(2)!;
      final verseStart = match.group(3)!;
      final verseEnd = match.group(4);

      setState(() {
        if (books.contains(bookName)) {
          _selectedBook = bookName;
        }
        _chapterController.text = chapter;
        _startVerseController.text = verseStart;
        if (verseEnd != null) {
          _endVerseController.text = verseEnd;
        }
      });
      _updateHints();
    }
  }

  void _updateHints() {
    if (_selectedBook != null) {
      // ✅ Passer la langue actuelle aux méthodes
      final lang = context.read<LanguageProvider>().language;
      final maxChapter = BibleValidationService.getMaxChapter(_selectedBook!, language: lang);
      _maxChapterHint = maxChapter != null ? "Max: $maxChapter" : null;

      final chapter = int.tryParse(_chapterController.text);
      if (chapter != null) {
        final maxVerse = BibleValidationService.getMaxVerse(_selectedBook!, chapter, language: lang);
        _maxVerseHint = maxVerse != null ? "Max: $maxVerse" : null;
      } else {
        _maxVerseHint = null;
      }
    }
  }

  Future<void> _confirmSelection() async {
    if (_selectedBook == null || _chapterController.text.isEmpty || _startVerseController.text.isEmpty) {
      _showErrorDialog(t('fill_required'));
      return;
    } //

    String ref = "$_selectedBook ${_chapterController.text}:${_startVerseController.text}";
    if (_endVerseController.text.isNotEmpty) {
      ref += "-${_endVerseController.text}";
    } //

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    ); //

    // =======================================================
    //  ✅ CORRECTION ICI ✅
    // =======================================================
    // 1. Lire la langue actuelle
    final lang = context.read<LanguageProvider>().language;

    // 2. Appeler le service de validation AVEC la langue
    final validationResult = await BibleValidationService.validateReference(
        ref,
        language: lang // 👈 CETTE LIGNE EST AJOUTÉE
    ); //
    // =======================================================

    if (mounted) Navigator.of(context).pop(); // Ferme le dialogue de chargement

    if (!validationResult.isValid) {
      _showErrorDialog(
        validationResult.errorMessage!,
        showSupportOption: true,
      );
      return;
    } //

    if (mounted) {
      Navigator.pop(context, ref); // Renvoie la référence validée
    }
  }

  void _showErrorDialog(String message, {bool showSupportOption = false}) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[700]),
              const SizedBox(width: 12),
              Expanded(child: Text(t('reference_invalid'))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: const TextStyle(fontSize: 16)),
              if (showSupportOption) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.help_outline, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t('error_message'),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            if (showSupportOption)
              TextButton.icon(
                icon: const Icon(Icons.email),
                label: Text(t('support')),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
      helperText: hint,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Vérifier si la langue a changé
    final currentLang = context.watch<LanguageProvider>().language;
    if (currentLang != _currentLanguage && !_isLoadingBooks) {
      // La langue a changé, recharger la liste des livres
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _currentLanguage = currentLang;
        setState(() {
          books = List.from(_getBooksForLanguage(currentLang));
          final defaultBook = _getDefaultBook(currentLang);
          _selectedBook = books.contains(defaultBook) ? defaultBook : books.first;
        });
      });
    }

    if (_isLoadingBooks) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(t('loading_bible')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t('choose_passage')),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('select_passage'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                value: _selectedBook,
                decoration: _inputDecoration(t('book')),
                isExpanded: true,
                items: books.map((book) => DropdownMenuItem(value: book, child: Text(book))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() {
                    _selectedBook = val;
                    _chapterController.clear();
                    _startVerseController.clear();
                    _endVerseController.clear();
                    _updateHints();
                  });
                },
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _chapterController,
                decoration: _inputDecoration(t('chapter'), hint: _maxChapterHint),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() => _updateHints()),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _startVerseController,
                      decoration: _inputDecoration(t('verse_start'), hint: _maxVerseHint),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _endVerseController,
                      decoration: _inputDecoration(t('verse_end'), hint: t('optional')),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _confirmSelection,
                  icon: const Icon(Icons.check_circle),
                  label: Text(t('validate_reference')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t('auto_validated'),
                        style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}