// File: lib/screens/core/pageDeConfiguration.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../models/game_context.dart';
import '../../models/language_provider.dart';
import '../../services/Bible_service.dart';
import '../../services/url_launcher_service.dart';
import '../duels/multiplayer_hub_page.dart';
import '../games/DICTEE/DicteePage.dart';
import '../games/ORDRE/ordre_game_page.dart';

import '../../widgets/main_drawer.dart';
import '../games/RECITATION/recitation_page.dart';
import '../../models/verse_model.dart';
import '../../Bibliotheque.dart';
import '../games/TEXTE-TROU/jeu_trous.dart';
import '../games/QCM/QcmPage.dart';
import '../games/trouver_reference_config_page.dart';

enum GameMode { texteATrous, qcm, remettreEnOrdre, dictee, recitation, reference, multiplayer }

/// Translations for free game page
/// Traductions pour la page de jeu libre
class FreeGameTranslations {
  static String t(String key, String lang) {
    final translations = {
      'free_game': {'fr': 'Jeu Libre', 'en': 'Free Game'},
      'choose_game_mode': {'fr': '1. Choisissez un mode de jeu', 'en': '1. Choose a game mode'},
      'text_gaps': {'fr': 'Texte à trous', 'en': 'Fill in the blanks'},
      'qcm': {'fr': 'QCM', 'en': 'Quiz'},
      'order': {'fr': 'Ordre', 'en': 'Order'},
      'dictation': {'fr': 'Dictée', 'en': 'Dictation'},
      'find_reference': {'fr': 'Trouver la Référence', 'en': 'Find Reference'},
      'multiplayer': {'fr': 'Multiplayer / Duels', 'en': 'Multiplayer / Duels'},
      'recitation': {'fr': 'Récitation', 'en': 'Recitation'},
      'choose_passage': {'fr': '2. Choisissez votre passage', 'en': '2. Choose your passage'},
      'book': {'fr': 'Livre', 'en': 'Book'},
      'chapter': {'fr': 'Chapitre', 'en': 'Chapter'},
      'verse_start': {'fr': 'Verset de début', 'en': 'Start verse'},
      'verse_end': {'fr': 'Fin (facultatif)', 'en': 'End (optional)'},
      'play': {'fr': 'JOUER', 'en': 'PLAY'},
      'fill_required': {'fr': 'Pour ce jeu, le livre et le chapitre sont requis.', 'en': 'For this game, book and chapter are required.'},
      'specify_verse': {'fr': 'Veuillez spécifier au moins un verset de début.', 'en': 'Please specify at least a start verse.'},
      'reference_not_found': {'fr': 'n\'existe pas ou n\'a pas pu être trouvée dans la Bible.', 'en': 'does not exist or could not be found in the Bible.'},
      'cannot_verify': {'fr': 'Impossible de vérifier la référence', 'en': 'Unable to verify reference'},
      'reference_invalid': {'fr': 'Référence invalide', 'en': 'Invalid reference'},
      'error_contact': {'fr': 'Si vous pensez qu\'il s\'agit d\'une erreur, contactez notre support technique.', 'en': 'If you think this is an error, contact our technical support.'},
      'support': {'fr': 'Support', 'en': 'Support'},
      'cancel': {'fr': 'Annuler', 'en': 'Cancel'},
      'game_not_connected': {'fr': 'Ce mode de jeu n\'est pas encore connecté.', 'en': 'This game mode is not yet connected.'},
      'the_reference': {'fr': 'La référence', 'en': 'The reference'},
      'error': {'fr': 'Erreur', 'en': 'Error'},
      'ok': {'fr': 'OK', 'en': 'OK'},
      'bible_reference_problem': {'fr': 'Problème avec la référence biblique', 'en': 'Bible reference problem'},
      'reference_label': {'fr': 'Référence', 'en': 'Reference'},
      'problem_label': {'fr': 'Problème', 'en': 'Problem'},
      'all_books': {'fr': 'Tous les livres', 'en': 'All books'},
    };
    return translations[key]?[lang] ?? key;
  }
}

/// Book name translations (French <-> English)
/// Traductions des noms de livres (Français <-> Anglais)
class BookTranslations {
  static final Map<String, Map<String, String>> bookNames = {
    // Old Testament / Ancien Testament
    'Genèse': {'fr': 'Genèse', 'en': 'Genesis'},
    'Exode': {'fr': 'Exode', 'en': 'Exodus'},
    'Lévitique': {'fr': 'Lévitique', 'en': 'Leviticus'},
    'Nombres': {'fr': 'Nombres', 'en': 'Numbers'},
    'Deutéronome': {'fr': 'Deutéronome', 'en': 'Deuteronomy'},
    'Josué': {'fr': 'Josué', 'en': 'Joshua'},
    'Juges': {'fr': 'Juges', 'en': 'Judges'},
    'Ruth': {'fr': 'Ruth', 'en': 'Ruth'},
    '1 Samuel': {'fr': '1 Samuel', 'en': '1 Samuel'},
    '2 Samuel': {'fr': '2 Samuel', 'en': '2 Samuel'},
    '1 Rois': {'fr': '1 Rois', 'en': '1 Kings'},
    '2 Rois': {'fr': '2 Rois', 'en': '2 Kings'},
    '1 Chroniques': {'fr': '1 Chroniques', 'en': '1 Chronicles'},
    '2 Chroniques': {'fr': '2 Chroniques', 'en': '2 Chronicles'},
    'Esdras': {'fr': 'Esdras', 'en': 'Ezra'},
    'Néhémie': {'fr': 'Néhémie', 'en': 'Nehemiah'},
    'Esther': {'fr': 'Esther', 'en': 'Esther'},
    'Job': {'fr': 'Job', 'en': 'Job'},
    'Psaumes': {'fr': 'Psaumes', 'en': 'Psalms'},
    'Proverbes': {'fr': 'Proverbes', 'en': 'Proverbs'},
    'Ecclésiaste': {'fr': 'Ecclésiaste', 'en': 'Ecclesiastes'},
    'Cantique': {'fr': 'Cantique', 'en': 'Song of Solomon'},
    'Ésaïe': {'fr': 'Ésaïe', 'en': 'Isaiah'},
    'Jérémie': {'fr': 'Jérémie', 'en': 'Jeremiah'},
    'Lamentations': {'fr': 'Lamentations', 'en': 'Lamentations'},
    'Ézéchiel': {'fr': 'Ézéchiel', 'en': 'Ezekiel'},
    'Daniel': {'fr': 'Daniel', 'en': 'Daniel'},
    'Osée': {'fr': 'Osée', 'en': 'Hosea'},
    'Joël': {'fr': 'Joël', 'en': 'Joel'},
    'Amos': {'fr': 'Amos', 'en': 'Amos'},
    'Abdias': {'fr': 'Abdias', 'en': 'Obadiah'},
    'Jonas': {'fr': 'Jonas', 'en': 'Jonah'},
    'Michée': {'fr': 'Michée', 'en': 'Micah'},
    'Nahum': {'fr': 'Nahum', 'en': 'Nahum'},
    'Habacuc': {'fr': 'Habacuc', 'en': 'Habakkuk'},
    'Sophonie': {'fr': 'Sophonie', 'en': 'Zephaniah'},
    'Aggée': {'fr': 'Aggée', 'en': 'Haggai'},
    'Zacharie': {'fr': 'Zacharie', 'en': 'Zechariah'},
    'Malachie': {'fr': 'Malachie', 'en': 'Malachi'},

    // New Testament / Nouveau Testament
    'Matthieu': {'fr': 'Matthieu', 'en': 'Matthew'},
    'Marc': {'fr': 'Marc', 'en': 'Mark'},
    'Luc': {'fr': 'Luc', 'en': 'Luke'},
    'Jean': {'fr': 'Jean', 'en': 'John'},
    'Actes': {'fr': 'Actes', 'en': 'Acts'},
    'Romains': {'fr': 'Romains', 'en': 'Romans'},
    '1 Corinthiens': {'fr': '1 Corinthiens', 'en': '1 Corinthians'},
    '2 Corinthiens': {'fr': '2 Corinthiens', 'en': '2 Corinthians'},
    'Galates': {'fr': 'Galates', 'en': 'Galatians'},
    'Éphésiens': {'fr': 'Éphésiens', 'en': 'Ephesians'},
    'Philippiens': {'fr': 'Philippiens', 'en': 'Philippians'},
    'Colossiens': {'fr': 'Colossiens', 'en': 'Colossians'},
    '1 Thessaloniciens': {'fr': '1 Thessaloniciens', 'en': '1 Thessalonians'},
    '2 Thessaloniciens': {'fr': '2 Thessaloniciens', 'en': '2 Thessalonians'},
    '1 Timothée': {'fr': '1 Timothée', 'en': '1 Timothy'},
    '2 Timothée': {'fr': '2 Timothée', 'en': '2 Timothy'},
    'Tite': {'fr': 'Tite', 'en': 'Titus'},
    'Philémon': {'fr': 'Philémon', 'en': 'Philemon'},
    'Hébreux': {'fr': 'Hébreux', 'en': 'Hebrews'},
    'Jacques': {'fr': 'Jacques', 'en': 'James'},
    '1 Pierre': {'fr': '1 Pierre', 'en': '1 Peter'},
    '2 Pierre': {'fr': '2 Pierre', 'en': '2 Peter'},
    '1 Jean': {'fr': '1 Jean', 'en': '1 John'},
    '2 Jean': {'fr': '2 Jean', 'en': '2 John'},
    '3 Jean': {'fr': '3 Jean', 'en': '3 John'},
    'Jude': {'fr': 'Jude', 'en': 'Jude'},
    'Apocalypse': {'fr': 'Apocalypse', 'en': 'Revelation'},
  };

  /// Translate book name to target language
  /// Traduire le nom du livre vers la langue cible
  static String translate(String bookName, String targetLang) {
    // Search in all entries for a match
    for (var entry in bookNames.entries) {
      if (entry.value['fr'] == bookName || entry.value['en'] == bookName) {
        return entry.value[targetLang] ?? bookName;
      }
    }
    return bookName; // Return original if not found
  }

  /// Get French name from any language
  /// Obtenir le nom français depuis n'importe quelle langue
  static String toFrench(String bookName) {
    return translate(bookName, 'fr');
  }

  /// Get English name from any language
  /// Obtenir le nom anglais depuis n'importe quelle langue
  static String toEnglish(String bookName) {
    return translate(bookName, 'en');
  }
}

class PageDeJeuPrincipale extends StatefulWidget {
  final String? initialReference;
  const PageDeJeuPrincipale({Key? key, this.initialReference}) : super(key: key);

  @override
  _PageDeJeuPrincipaleState createState() => _PageDeJeuPrincipaleState();
}

class _PageDeJeuPrincipaleState extends State<PageDeJeuPrincipale> {
  List<String> books = [];
  String? selectedBook;
  final TextEditingController chapitreController = TextEditingController();
  final TextEditingController versetController = TextEditingController();
  int versetFin = 0;
  GameMode selectedGameMode = GameMode.texteATrous;
  bool _isLoadingBooks = true;

  @override
  void initState() {
    super.initState();
    _chargerLivresDepuisJson().then((_) {
      if (widget.initialReference != null) {
        _parseAndSetInitialReference(widget.initialReference!);
      }
    });
  }

  /// Get translation - FIXED: Use read() instead of watch()
  /// Obtenir la traduction - CORRIGÉ : Utilise read() au lieu de watch()
  String t(String key) {
    final lang = context.read<LanguageProvider>().language;
    return FreeGameTranslations.t(key, lang);
  }

  void _parseAndSetInitialReference(String reference) {
    final regExp = RegExp(r"^(\d?\s?[a-zA-ZÀ-ÿ\s]+)\s(\d+):(\d+)(?:-(\d+))?$");
    final match = regExp.firstMatch(reference.trim());

    if (match != null) {
      final bookName = match.group(1)!.trim();
      final chapter = match.group(2)!;
      final verse = match.group(3)!;
      final endVerse = match.group(4);

      setState(() {
        if (books.contains(bookName)) {
          selectedBook = bookName;
        }
        chapitreController.text = chapter;
        versetController.text = verse;
        if (endVerse != null) {
          versetFin = int.tryParse(endVerse) ?? 0;
        }
      });
    }
  }

  Future<void> _chargerLivresDepuisJson() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/segond_1910.json');
      final corrected = '[' + jsonString.replaceAll('}{', '},{') + ']';
      final List<dynamic> data = json.decode(corrected);
      final Set<String> livresUniquesFr = data.map((item) => item['book_name'] as String).toSet();

      if (mounted) {
        final lang = context.read<LanguageProvider>().language;
        final allBooksLabel = FreeGameTranslations.t('all_books', lang);

        // Translate book names to current language
        final livresTranslated = livresUniquesFr.map((bookFr) {
          return BookTranslations.translate(bookFr, lang);
        }).toList()..sort();

        // Set default book (John/Jean)
        final defaultBook = BookTranslations.translate("Jean", lang);

        setState(() {
          books = [allBooksLabel, ...livresTranslated];
          // Make sure selectedBook is in the list
          selectedBook = books.contains(defaultBook) ? defaultBook : (books.length > 1 ? books[1] : null);
          _isLoadingBooks = false;
        });
      }
    } catch (e) {
      print('❌ Error loading books: $e');

      // Fallback: Use hardcoded book list if JSON fails
      if (mounted) {
        final lang = context.read<LanguageProvider>().language;
        final allBooksLabel = FreeGameTranslations.t('all_books', lang);

        // Hardcoded French book names as fallback
        final fallbackBooksFr = [
          'Genèse', 'Exode', 'Lévitique', 'Nombres', 'Deutéronome',
          'Josué', 'Juges', 'Ruth', '1 Samuel', '2 Samuel',
          '1 Rois', '2 Rois', '1 Chroniques', '2 Chroniques',
          'Esdras', 'Néhémie', 'Esther', 'Job', 'Psaumes',
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

        final livresTranslated = fallbackBooksFr.map((bookFr) {
          return BookTranslations.translate(bookFr, lang);
        }).toList();

        final defaultBook = BookTranslations.translate("Jean", lang);

        setState(() {
          books = [allBooksLabel, ...livresTranslated];
          selectedBook = books.contains(defaultBook) ? defaultBook : (books.length > 1 ? books[1] : null);
          _isLoadingBooks = false;
        });
      }
    }
  }

  Future<void> _lancerPartie() async {
    final lang = context.read<LanguageProvider>().language;

    if (selectedGameMode == GameMode.reference) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TrouverReferenceConfigPage()),
      );
      return;
    }

    int? chapitre = int.tryParse(chapitreController.text.trim());
    final allBooksLabel = FreeGameTranslations.t('all_books', lang);

    if (selectedBook == null || selectedBook == allBooksLabel || chapitre == null) {
      _afficherMessageErreur(t('fill_required'));
      return;
    }

    int? versetDebut = int.tryParse(versetController.text.trim());

    if (versetDebut == null) {
      _afficherMessageErreur(t('specify_verse'));
      return;
    }

    // IMPORTANT: Send book name in the USER'S language to API
    // The API will use the correct Bible version based on language header
    final bookNameForApi = selectedBook!; // Keep user's language

    String referenceActuelle;
    if (versetFin > 0 && versetFin != versetDebut) {
      referenceActuelle = "$bookNameForApi $chapitre:$versetDebut-$versetFin";
    } else {
      referenceActuelle = "$bookNameForApi $chapitre:$versetDebut";
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // ✅ LOGS DE DEBUG
      print('═══════════════════════════════════════');
      print('🔍 DEBUG API CALL');
      print('📖 Reference: $referenceActuelle');
      print('🌍 Language: $lang');
      print('📚 Book (UI): $selectedBook');
      print('📤 Book (API): $bookNameForApi');
      print('═══════════════════════════════════════');

      final verseData = await BibleService().getPassageText(
        referenceActuelle,
        language: lang, // ← IMPORTANT: Pass user's language!
      );

      // ✅ LOGS APRÈS L'APPEL
      print('═══════════════════════════════════════');
      print('✅ API RESPONSE');
      print('📊 Verses returned: ${verseData.length}');
      if (verseData.isNotEmpty) {
        print('📝 First verse: ${verseData[0].text}');
      }
      print('═══════════════════════════════════════');

      if (mounted) Navigator.of(context).pop();

      if (verseData.isEmpty) {
        _showValidationError(
          "${t('the_reference')} '$referenceActuelle' ${t('reference_not_found')}",
          referenceActuelle,
        );
        return;
      }

      final shouldContinue = await _showVersePreview(referenceActuelle, verseData);

      if (!shouldContinue) return;

      // ✅ Stocker le nom du livre dans la langue de l'utilisateur
      // L'API backend gère maintenant les deux langues
      final temporaryVerse = Verse(
        id: referenceActuelle, // ✅ Garder la référence originale
        reference: referenceActuelle, // ✅ Garder la référence originale (John ou Jean)
        book: selectedBook!, // ✅ Garder le livre dans la langue de l'utilisateur
        status: VerseStatus.neutral,
        progressLevel: 0,
        scores: {},
        isUserAdded: false,
        updatedAt: null,
        failedAttempts: {},
        srsLevel: 0,
        reviewDate: null,
      );

      switch (selectedGameMode) {
        case GameMode.qcm:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => QcmGamePage(
                      gameContext: GameContext.sandbox,
                      verse: temporaryVerse
                  )
              )
          );
          break;
        case GameMode.texteATrous:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => TexteATrousPage(
                      verse: temporaryVerse,
                      gameContext: GameContext.sandbox
                  )
              )
          );
          break;
        case GameMode.remettreEnOrdre:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => OrdreGamePage(
                      verse: temporaryVerse,
                      gameContext: GameContext.sandbox
                  )
              )
          );
          break;
        case GameMode.dictee:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => DicteePage(
                      verse: temporaryVerse,
                      isSandbox: true
                  )
              )
          );
          break;
        case GameMode.recitation:
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => RecitationPage(
                      verse: temporaryVerse,
                      gameContext: GameContext.sandbox
                  )
              )
          );
          break;
        case GameMode.multiplayer:
          Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HubPage())
          );
          break;
        default:
          _afficherMessageErreur(t('game_not_connected'));
      }

    } catch (e) {
      if (mounted) Navigator.of(context).pop();

      _showValidationError(
        "${t('cannot_verify')} '$referenceActuelle'.\n\n${t('error')}: ${e.toString()}",
        referenceActuelle,
      );
    }
  }

  void _showValidationError(String message, String reference) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final lang = context.read<LanguageProvider>().language;

        return AlertDialog(
        title: Row(
        children: [
        Icon(Icons.error_outline, color: Colors.red[700], size: 28),
        const SizedBox(width: 12),
        Expanded(child: Text(FreeGameTranslations.t('reference_invalid', lang))),
        ],
        ),
        content: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
        ),
        child: Text(
        reference,
        style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.red[900],
        fontSize: 16,
        ),
        ),
        ),
        const SizedBox(height: 16),
        Text(message, style: const TextStyle(fontSize: 16, height: 1.5)),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 12),
        Row(
        children: [
        Icon(Icons.help_outline, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
        child: Text(
        FreeGameTranslations.t('error_contact', lang),
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        ),
        ],
        ),
        ],
        ),
        ),
        actions: [
        TextButton.icon(
        icon: const Icon(Icons.email),
        label: Text(FreeGameTranslations.t('support', lang)),
        onPressed: () {
        Navigator.of(dialogContext).pop();
        UrlLauncherService.contactSupport(
        context,
        subject: FreeGameTranslations.t('bible_reference_problem', lang),
        body: '${FreeGameTranslations.t('reference_label', lang)}: $reference\n\n${FreeGameTranslations.t('problem_label', lang)}: $message',
        );
        },
        ),
        ElevatedButton(
        onPressed: () => Navigator.of(dialogContext).pop(),
        style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        ),
        child: Text(FreeGameTranslations.t('ok', lang)),
        ),
        ],
        );
      },
    );
  }

  Future<bool> _showVersePreview(String reference, List<VerseData> verseData) async {
    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final lang = context.read<LanguageProvider>().language;
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.visibility, color: Colors.indigo),
              const SizedBox(width: 12),
              Expanded(
                child: Text(reference, style: const TextStyle(fontSize: 18)),
              ),
            ],
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
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                      children: verseData.map((verse) {
                        final verseNumber = verse.reference.split(':').last;
                        return TextSpan(
                          children: [
                            TextSpan(
                              text: " $verseNumber ",
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
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(FreeGameTranslations.t('cancel', lang)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: Text(FreeGameTranslations.t('play', lang)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _afficherMessageErreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    chapitreController.dispose();
    versetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().language;

    return Scaffold(
      appBar: AppBar(
        title: Text(FreeGameTranslations.t('free_game', lang)),
        elevation: 0,
      ),
      drawer: const MainDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildVueConfiguration(lang),
        ),
      ),
    );
  }

  Widget _buildVueConfiguration(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          FreeGameTranslations.t('choose_game_mode', lang),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.indigo),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          children: GameMode.values.map((gameMode) {
            String label;
            IconData icon;

            switch (gameMode) {
              case GameMode.texteATrous:
                label = FreeGameTranslations.t('text_gaps', lang);
                icon = Icons.edit;
                break;
              case GameMode.qcm:
                label = FreeGameTranslations.t('qcm', lang);
                icon = Icons.check_circle_outline;
                break;
              case GameMode.remettreEnOrdre:
                label = FreeGameTranslations.t('order', lang);
                icon = Icons.swap_horiz;
                break;
              case GameMode.dictee:
                label = FreeGameTranslations.t('dictation', lang);
                icon = Icons.hearing;
                break;
              case GameMode.reference:
                label = FreeGameTranslations.t('find_reference', lang);
                icon = Icons.quiz_outlined;
                break;
              case GameMode.multiplayer:
                label = FreeGameTranslations.t('multiplayer', lang);
                icon = Icons.people_alt_outlined;
                break;
              case GameMode.recitation:
                label = FreeGameTranslations.t('recitation', lang);
                icon = Icons.mic;
                break;
            }

            return ChoiceChip(
              avatar: Icon(
                icon,
                color: selectedGameMode == gameMode ? Colors.white : Colors.black54,
              ),
              label: Text(
                label,
                style: TextStyle(
                  color: selectedGameMode == gameMode ? Colors.white : Colors.black,
                ),
              ),
              selected: selectedGameMode == gameMode,
              selectedColor: Theme.of(context).primaryColor,
              onSelected: (isSelected) {
                if (isSelected) setState(() => selectedGameMode = gameMode);
              },
            );
          }).toList(),
        ),

        const Divider(height: 32),

        Text(
          FreeGameTranslations.t('choose_passage', lang),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.indigo),
        ),
        const SizedBox(height: 16),

        if (_isLoadingBooks)
          const Center(child: CircularProgressIndicator())
        else if (books.isEmpty)
          Text(
            'Error loading books / Erreur de chargement des livres',
            style: TextStyle(color: Colors.red),
          )
        else
          DropdownButtonFormField<String>(
            decoration: _inputDecoration(FreeGameTranslations.t('book', lang)),
            value: selectedBook,
            isExpanded: true,
            items: books.map((book) => DropdownMenuItem(
              value: book,
              child: Text(book, overflow: TextOverflow.ellipsis),
            )).toList(),
            onChanged: (value) {
              if (value != null) setState(() => selectedBook = value);
            },
          ),
        const SizedBox(height: 16),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: chapitreController,
              decoration: _inputDecoration(FreeGameTranslations.t('chapter', lang), hint: 'Ex: 23'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: versetController,
                    decoration: _inputDecoration(FreeGameTranslations.t('verse_start', lang)),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: _inputDecoration(FreeGameTranslations.t('verse_end', lang)),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        versetFin = int.tryParse(value) ?? 0;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 32),

        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: Text(FreeGameTranslations.t('play', lang)),
            onPressed: _lancerPartie,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.indigo, width: 2.0),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}