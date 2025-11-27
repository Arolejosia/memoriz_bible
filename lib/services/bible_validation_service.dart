// Fichier: lib/services/bible_validation_service.dart

import 'package:memoriz_bible/services/Bible_service.dart';

class BibleValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? suggestion;

  BibleValidationResult({
    required this.isValid,
    this.errorMessage,
    this.suggestion,
  });

  BibleValidationResult.success() : isValid = true, errorMessage = null, suggestion = null;

  BibleValidationResult.error(this.errorMessage, {this.suggestion}) : isValid = false;
}

/// 🎯 VERSION SIMPLIFIÉE : Utilise BibleService API au lieu de fichiers JSON
class BibleValidationService {
  static bool _isInitialized = false;

  /// Initialise le service (ne fait rien car on utilise l'API)
  static Future<void> initialize() async {
    _isInitialized = true;
    print("✅ BibleValidationService initialisé (mode API)");
  }

  /// Valide une référence biblique en appelant l'API
  static Future<BibleValidationResult> validateReference(
      String reference,
      {String language = 'fr'}
      ) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      print("🔍 Validation de '$reference' en langue '$language'");

      // ✅ Appeler l'API pour valider (comme dans le code de bibliothèque)
      final verseData = await BibleService().getPassageText(reference, language: language);

      // Si l'API retourne des données, la référence est valide
      if (verseData.isNotEmpty) {
        print("✅ Référence valide: ${verseData.length} verset(s)");
        return BibleValidationResult.success();
      } else {
        // L'API n'a pas trouvé de verset
        final errorMsg = language == 'fr'
            ? "La référence '$reference' n'existe pas."
            : "The reference '$reference' does not exist.";
        print("❌ Référence invalide: $errorMsg");
        return BibleValidationResult(
          isValid: false,
          errorMessage: errorMsg,
        );
      }
    } catch (e) {
      // Erreur lors de l'appel API
      print("❌ Erreur de validation: $e");

      final errorMsg = language == 'fr'
          ? "Impossible de valider la référence '$reference'.\nVérifiez votre connexion internet."
          : "Unable to validate the reference '$reference'.\nCheck your internet connection.";

      return BibleValidationResult(
        isValid: false,
        errorMessage: errorMsg,
      );
    }
  }

  /// ⚠️ Ces méthodes ne sont plus utilisées avec la validation API
  /// mais on les garde pour la compatibilité

  static int? getMaxChapter(String book, {String language = 'fr'}) {
    // Retourne null car on ne connaît pas les limites sans appeler l'API
    return null;
  }

  static int? getMaxVerse(String book, int chapter, {String language = 'fr'}) {
    // Retourne null car on ne connaît pas les limites sans appeler l'API
    return null;
  }

  static List<String> getAvailableBooks({String language = 'fr'}) {
    // ✅ Livres en dur selon la langue
    if (language == 'en') {
      return _englishBooks;
    }
    return _frenchBooks;
  }

  static bool get isInitialized => _isInitialized;

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
}