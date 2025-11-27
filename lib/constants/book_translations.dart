// File: lib/constants/book_translations.dart

/// Book name translations (French <-> English)
/// Traductions des noms de livres (Français <-> Anglais)
///
/// Usage:
/// ```dart
/// import 'package:memoriz_bible/constants/book_translations.dart';
///
/// // Translate to English
/// String bookEn = BookTranslations.translate('Jean', 'en'); // "John"
///
/// // Translate to French
/// String bookFr = BookTranslations.translate('John', 'fr'); // "Jean"
///
/// // Convert to French from any language
/// String bookFr = BookTranslations.toFrench('John'); // "Jean"
///
/// // Convert to English from any language
/// String bookEn = BookTranslations.toEnglish('Jean'); // "John"
/// ```
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
  ///
  /// Example:
  /// ```dart
  /// BookTranslations.translate('Jean', 'en'); // Returns "John"
  /// BookTranslations.translate('John', 'fr'); // Returns "Jean"
  /// ```
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
  ///
  /// Example:
  /// ```dart
  /// BookTranslations.toFrench('John'); // Returns "Jean"
  /// BookTranslations.toFrench('Jean'); // Returns "Jean"
  /// ```
  static String toFrench(String bookName) {
    return translate(bookName, 'fr');
  }

  /// Get English name from any language
  /// Obtenir le nom anglais depuis n'importe quelle langue
  ///
  /// Example:
  /// ```dart
  /// BookTranslations.toEnglish('Jean'); // Returns "John"
  /// BookTranslations.toEnglish('John'); // Returns "John"
  /// ```
  static String toEnglish(String bookName) {
    return translate(bookName, 'en');
  }

  /// Get all book names in a specific language
  /// Obtenir tous les noms de livres dans une langue spécifique
  ///
  /// Example:
  /// ```dart
  /// List<String> booksFr = BookTranslations.getAllBooks('fr');
  /// List<String> booksEn = BookTranslations.getAllBooks('en');
  /// ```
  static List<String> getAllBooks(String language) {
    return bookNames.values
        .map((book) => book[language] ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
  }

  /// Check if a book name exists in the translations
  /// Vérifier si un nom de livre existe dans les traductions
  static bool exists(String bookName) {
    return bookNames.values.any(
            (book) => book['fr'] == bookName || book['en'] == bookName
    );
  }
}