// Fichier: lib/screens/progression_dashboard_page.dart

import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// --- Imports pour la traduction ---
import '../../constants/book_translations.dart';
import 'package:memoriz_bible/models/language_provider.dart';

// --- Autres imports de votre projet ---
import '../../services/url_launcher_service.dart';
import '../../models/game_context.dart';
import '../../widgets/review_list_widget.dart';
import '../../widgets/stats_card_widget.dart';
import '../../models/verse_model.dart';
import '../verse/verse_detail_page.dart';
import '../../Bibliotheque.dart';
import '../games/QCM/QcmPage.dart';
import '../../services/Bible_service.dart';

class ProgressionDashboardPage extends StatefulWidget {
  const ProgressionDashboardPage({super.key});

  @override
  State<ProgressionDashboardPage> createState() => _ProgressionDashboardPageState();
}

class _ProgressionDashboardPageState extends State<ProgressionDashboardPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  Verse? _lastVerseInProgress;
  List<String> books = [];
  bool _isLoadingBooks = true;
  String? _newSelectedBook;
  final _newChapterController = TextEditingController();
  final _newStartVerseController = TextEditingController();
  final _newEndVerseController = TextEditingController();

  // ✅ AJOUT : Variable pour tracer la langue précédente
  String? _previousLang;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chargerLivresDepuisJson();
    });
    _fetchDashboardData();
  }

  // ✅ CORRECTION : Utiliser read() au lieu de watch() pour éviter les rebuilds en boucle
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLang = context.read<LanguageProvider>().language;

    // Recharger les livres uniquement si la langue a changé
    if (_previousLang != null && _previousLang != currentLang) {
      _chargerLivresDepuisJson();
    }
    _previousLang = currentLang;
  }

  @override
  void dispose() {
    _newChapterController.dispose();
    _newStartVerseController.dispose();
    _newEndVerseController.dispose();
    super.dispose();
  }

  String t(String key, {Map<String, String>? params}) {
    final lang = context.read<LanguageProvider>().language;
    return ProgressionDashboardTranslations.t(key, lang, params: params);
  }

  Future<void> _chargerLivresDepuisJson() async {
    final lang = context.read<LanguageProvider>().language;

    try {
      final String jsonString = await rootBundle.loadString('assets/segond_1910.json');
      final corrected = '[' + jsonString.replaceAll('}{', '},{') + ']';
      final List<dynamic> data = json.decode(corrected);

      // 🆕 Fonction de normalisation
      String normalizeBookName(String bookName) {
        final normalizations = {
          'Psaumes': 'Psaume',
          // Ajoutez d'autres normalisations si besoin
        };
        return normalizations[bookName] ?? bookName;
      }

      // ✅ Normaliser puis créer le Set
      final Set<String> livresUniquesFr = data
          .map((item) => normalizeBookName(item['book_name'] as String))
          .toSet();

      if (mounted) {
        // ✅ Traduire tous les livres dans la langue actuelle
        final livresTranslated = livresUniquesFr
            .map((bookFr) => BookTranslations.translate(bookFr, lang))
            .toList()
          ..sort();

        final defaultBook = BookTranslations.translate("Jean", lang);

        setState(() {
          books = livresTranslated;

          // ✅ CORRECTION : Logique simplifiée et robuste
          if (books.isNotEmpty) {
            if (_newSelectedBook == null || !books.contains(_newSelectedBook)) {
              // Si aucun livre sélectionné ou livre invalide, choisir Jean par défaut
              _newSelectedBook = books.contains(defaultBook) ? defaultBook : books[0];
            } else {
              // ✅ Si un livre est déjà sélectionné, le retraduite dans la nouvelle langue
              // D'abord convertir en français (format canonique)
              String? bookInFrench;
              for (var entry in BookTranslations.bookNames.entries) {
                if (entry.value['fr'] == _newSelectedBook || entry.value['en'] == _newSelectedBook) {
                  bookInFrench = entry.value['fr'];
                  break;
                }
              }

              // Ensuite traduire vers la langue actuelle
              if (bookInFrench != null) {
                _newSelectedBook = BookTranslations.translate(bookInFrench, lang);
              }
            }
          }

          _isLoadingBooks = false;
        });
      }
    } catch (e) {
      print("${t('error_loading_books')}: $e");

      // ✅ AJOUT : Fallback avec liste hardcodée (comme dans pageDeConfiguration)
      if (mounted) {
        final fallbackBooksFr = [
          'Genèse', 'Exode', 'Lévitique', 'Nombres', 'Deutéronome',
          'Josué', 'Juges', 'Ruth', '1 Samuel', '2 Samuel',
          '1 Rois', '2 Rois', '1 Chroniques', '2 Chroniques',
          'Esdras', 'Néhémie', 'Esther', 'Job', 'Psaume',  // ✅ Changé ici
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

        final defaultBook = BookTranslations.translate("Jean", lang);

        setState(() {
          books = livresTranslated;
          _newSelectedBook = books.contains(defaultBook) ? defaultBook : (books.isNotEmpty ? books[0] : null);
          _isLoadingBooks = false;
        });
      }
    }
  }

  Future<void> _fetchDashboardData() async {
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final lastVerseQuery = await FirebaseFirestore.instance
          .collection('users/${user!.uid}/verses')
          .where('status', isEqualTo: 'learning')
          .orderBy('updatedAt', descending: true)
          .limit(1)
          .get();
      if (lastVerseQuery.docs.isNotEmpty) {
        _lastVerseInProgress = Verse.fromFirestore(lastVerseQuery.docs.first);
      } else {
        _lastVerseInProgress = null;
      }
    } catch (e) {
      print("${t('error_loading_data')}: $e");
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _startNewVerse() async {
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('error_no_user'))));
      return;
    }
    if (_newSelectedBook == null || _newChapterController.text.isEmpty || _newStartVerseController.text.isEmpty) {
      _showErrorDialog(t('error_fill_fields'), showSupportOption: false);
      return;
    }

    final endVerse = _newEndVerseController.text.trim();
    final bookNameForApi = _newSelectedBook!;

    final reference = endVerse.isNotEmpty
        ? "$bookNameForApi ${_newChapterController.text}:${_newStartVerseController.text}-$endVerse"
        : "$bookNameForApi ${_newChapterController.text}:${_newStartVerseController.text}";

    showDialog(
        context: context,
        builder: (context) => const Center(child: CircularProgressIndicator()),
        barrierDismissible: false
    );

    try {
      final lang = context.read<LanguageProvider>().language;
      // 1. Obtenir le provider de la bibliothèque
      final library = context.read<VerseLibrary>();

      print('🚀 Calling API with reference: $reference (language: $lang)');

      final verseData = await BibleService().getPassageText(
        reference,
        language: lang,
      ); //

      if (mounted) Navigator.of(context).pop(); // Fermer le dialogue de chargement

      if (verseData.isEmpty) {
        _showErrorDialog(t('error_ref_not_found', params: {'ref': reference}), showSupportOption: true);
        return;
      }

      final shouldContinue = await _showVersePreview(reference, verseData); //
      if (!shouldContinue) return;

      // 2. Convertir le nom du livre en français (format de stockage)
      final bookInFrench = BookTranslations.toFrench(_newSelectedBook!); //

      // 3. Utiliser la fonction de la bibliothèque pour ajouter le verset
      //    Ceci utilise la version corrigée de "addVerse" de la bibliothèque
      await library.addVerse(reference, bookInFrench, ""); // Catégorie vide pour l'instant

      // 4. Retrouver le verset qui est maintenant DANS le provider
      Verse? verseToPlay = library.myVerseCategories
          .expand((category) => category.verses)
          .firstWhereOrNull((v) => v.id == reference);

      if (verseToPlay == null) {
        // Ne devrait jamais arriver, mais par sécurité
        throw Exception("Le verset n'a pas été trouvé dans la bibliothèque après l'ajout.");
      }

      // 5. Mettre à jour son statut en 'learning' s'il était 'neutral'
      if (verseToPlay.status == VerseStatus.neutral) {
        final verseRef = FirebaseFirestore.instance.collection('users/${user!.uid}/verses').doc(reference);
        await verseRef.update({
          'status': 'learning',
          'updatedAt': FieldValue.serverTimestamp()
        });
        // Recharger le provider pour que l'objet verseToPlay ait le bon statut
        await library.reloadAllData();
      }

      // 6. Récupérer l'objet verset final (avec le bon statut) depuis le provider
      final finalVerseToPlay = library.myVerseCategories
          .expand((category) => category.verses)
          .firstWhere((v) => v.id == reference);

      // =======================================================
      //  ICI EST LA MODIFICATION
      // =======================================================
      if (mounted) {
        // Naviguer vers la page de détail du verset
        final gamePage = VerseDetailPage(
          verse: finalVerseToPlay,
        );

        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => gamePage)
        ).then((_) => _fetchDashboardData()); //
      }
      // =======================================================

    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showErrorDialog(
          t('error_verify_ref', params: {'ref': reference, 'error': e.toString()}),
          showSupportOption: true
      ); //
    }
  }

  Future<bool> _showVersePreview(String reference, List<VerseData> verseData) async {
    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
            children: [
              const Icon(Icons.visibility, color: Colors.indigo),
              const SizedBox(width: 12),
              Expanded(child: Text(reference, style: const TextStyle(fontSize: 18)))
            ]
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Card(
              elevation: 0,
              color: Colors.indigo[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                    children: verseData.map((verse) {
                      final verseNumber = verse.reference.split(':').last;
                      return TextSpan(
                          children: [
                            TextSpan(
                                text: " $verseNumber ",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)
                            ),
                            TextSpan(text: verse.text)
                          ]
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t('cancel'))
          ),
          ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: Text(t('start')),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true)
          ),
        ],
      ),
    ) ?? false;
  }

  void _showErrorDialog(String message, {required bool showSupportOption}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[700]),
              const SizedBox(width: 12),
              Expanded(child: Text(t('invalid_reference_title')))
            ]
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
                          t('error_contact_support'),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600])
                      )
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
                final Uri emailLaunchUri = Uri(scheme: 'mailto', path: 'aroletella@gmail.com');
                Navigator.of(dialogContext).pop();
                UrlLauncherService.launchUri(context, emailLaunchUri);
              },
            ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white
            ),
            child: Text(t('ok')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().language;
    String t(String key, {Map<String, String>? params}) =>
        ProgressionDashboardTranslations.t(key, lang, params: params);

    return Scaffold(
      appBar: AppBar(title: Text(t('my_learning_title'))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          if (_lastVerseInProgress != null)
            _buildResumeCard(_lastVerseInProgress!, t),
          if (_lastVerseInProgress != null) const SizedBox(height: 24),
          const ReviewListWidget(),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(
              t('my_library_title'),
              style: Theme.of(context).textTheme.headlineSmall
          ),
          const SizedBox(height: 16),
          const StatsCardWidget(),
          const SizedBox(height: 24),
          _buildNewVerseCard(t),
        ],
      ),
    );
  }

  Widget _buildResumeCard(
      Verse verse,
      String Function(String, {Map<String, String>? params}) t
      ) {
    return Card(
      color: Colors.indigo[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
                t('resume_card_title'),
                style: Theme.of(context).textTheme.titleLarge
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.bookmark, color: Colors.indigo, size: 40),
              title: Text(
                  verse.reference,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
              ),
              subtitle: Text(
                  t('progress_label', params: {'progress': verse.progressLevel.toString()})
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: Text(t('continue_button')),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VerseDetailPage(verse: verse))
              ).then((_) => _fetchDashboardData()),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewVerseCard(String Function(String, {Map<String, String>? params}) t) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
                t('new_verse_card_title'),
                style: Theme.of(context).textTheme.titleLarge
            ),
            const SizedBox(height: 16),
            if (_isLoadingBooks)
              const Center(child: CircularProgressIndicator())
            else
              Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: _inputDecoration(t('book_label')),
                    value: _newSelectedBook,
                    isExpanded: true,
                    menuMaxHeight: 400,
                    items: books.map((book) => DropdownMenuItem(
                        value: book,
                        child: Text(book)
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _newSelectedBook = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                      controller: _newChapterController,
                      decoration: _inputDecoration(t('chapter_label')),
                      keyboardType: TextInputType.number
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: TextField(
                              controller: _newStartVerseController,
                              decoration: _inputDecoration(t('start_verse_label')),
                              keyboardType: TextInputType.number
                          )
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                          child: TextField(
                              controller: _newEndVerseController,
                              decoration: _inputDecoration(t('end_verse_label')),
                              keyboardType: TextInputType.number
                          )
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: Text(t('start')),
                onPressed: _startNewVerse
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))
    );
  }
}

// File: lib/l10n/progression_dashboard_translations.dart

class ProgressionDashboardTranslations {
  static String t(String key, String lang, {Map<String, String>? params}) {
    final Map<String, Map<String, String>> translations = {
      // General
      'my_learning_title': {'fr': 'Mon Apprentissage', 'en': 'My Learning'},
      'my_library_title': {'fr': 'Ma Bibliothèque', 'en': 'My Library'},
      'cancel': {'fr': 'Annuler', 'en': 'Cancel'},
      'start': {'fr': 'COMMENCER', 'en': 'START'},
      'continue_button': {'fr': 'CONTINUER', 'en': 'CONTINUE'},
      'ok': {'fr': 'OK', 'en': 'OK'},
      'support': {'fr': 'Support', 'en': 'Support'},
      'error': {'fr': 'Erreur', 'en': 'Error'},

      // Error Messages
      'error_loading_books': {'fr': 'Erreur chargement livres JSON', 'en': 'Error loading books JSON'},
      'error_loading_data': {'fr': 'Erreur lors du chargement des données', 'en': 'Error loading data'},
      'error_no_user': {'fr': "Erreur : Aucun utilisateur n'est connecté.", 'en': 'Error: No user is logged in.'},
      'error_fill_fields': {'fr': 'Veuillez choisir un livre, un chapitre et un verset.', 'en': 'Please choose a book, chapter, and verse.'},
      'error_ref_not_found': {'fr': "La référence '{ref}' n'existe pas ou n'a pas pu être trouvée dans la Bible.", 'en': "The reference '{ref}' does not exist or could not be found in the Bible."},
      'error_verify_ref': {'fr': "Impossible de vérifier la référence '{ref}'.\n\nErreur: {error}", 'en': "Unable to verify reference '{ref}'.\n\nError: {error}"},

      // Dialogs
      'invalid_reference_title': {'fr': 'Référence invalide', 'en': 'Invalid Reference'},
      'error_contact_support': {'fr': "Si vous pensez qu'il s'agit d'une erreur, contactez notre support technique.", 'en': 'If you believe this is an error, please contact our technical support.'},

      // Resume Card
      'resume_card_title': {'fr': 'Reprendre où vous en étiez', 'en': 'Pick up where you left off'},
      'progress_label': {'fr': 'Progression : {progress}/5', 'en': 'Progress: {progress}/5'},

      // New Verse Card
      'new_verse_card_title': {'fr': 'Commencer un nouveau verset', 'en': 'Start a new verse'},
      'book_label': {'fr': 'Livre', 'en': 'Book'},
      'chapter_label': {'fr': 'Chapitre', 'en': 'Chapter'},
      'start_verse_label': {'fr': 'Début', 'en': 'Start'},
      'end_verse_label': {'fr': 'Fin (facultatif)', 'en': 'End (optional)'},
    };

    String text = translations[key]?[lang] ?? key;
    if (params != null) {
      params.forEach((paramKey, value) {
        text = text.replaceAll('{$paramKey}', value);
      });
    }
    return text;
  }
}