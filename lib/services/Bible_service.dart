// Fichier: services/bible_service.dart
// ✅ VERSION CORRIGÉE - Support multilingue complet

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

/// Représente un verset unique avec sa référence et son texte.
class VerseData {
  final String reference;
  final String text;

  VerseData({required this.reference, required this.text});

  factory VerseData.fromJson(Map<String, dynamic> json) {
    return VerseData(
      reference: json['reference'] ?? 'Ref?',
      text: json['text'] ?? 'Texte non trouvé.',
    );
  }
}

class ReferenceQuestion {
  final String questionText;
  final List<String> options;
  final String correctAnswer;

  ReferenceQuestion({
    required this.questionText,
    required this.options,
    required this.correctAnswer,
  });

  factory ReferenceQuestion.fromJson(Map<String, dynamic> json) {
    return ReferenceQuestion(
      questionText: json['question_text'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['reponse_correcte'] ?? '',
    );
  }
}

class QuizQuestion {
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final bool cycleRecommence;

  QuizQuestion({
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.cycleRecommence,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      questionText: json['question'] ?? json['question_text'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['reponse_correcte'] ?? '',
      cycleRecommence: json['cycle_recommence'] ?? false,
    );
  }
}

class UnscrambleGameData {
  final List<MotsMelesData> versets;

  UnscrambleGameData({required this.versets});

  factory UnscrambleGameData.fromJson(Map<String, dynamic> json) {
    try {
      return UnscrambleGameData(
        versets: (json['versets'] as List<dynamic>)
            .map((verse) => MotsMelesData.fromJson(verse as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      throw Exception('Error parsing UnscrambleGameData: $e');
    }
  }
}

class MotsMelesData {
  final String reference;
  final List<String> motsMelanges;
  final List<String> motsCorrects;
  final String? texteOriginal;

  MotsMelesData({
    required this.reference,
    required this.motsMelanges,
    required this.motsCorrects,
    this.texteOriginal,
  });

  factory MotsMelesData.fromJson(Map<String, dynamic> json) {
    try {
      return MotsMelesData(
        reference: json['reference']?.toString() ?? '',
        motsMelanges: _parseStringList(json['mots_melanges']),
        motsCorrects: _parseStringList(json['ordre_correct']),
        texteOriginal: json['texte_original']?.toString(),
      );
    } catch (e) {
      throw Exception('Error parsing MotsMelesData: $e');
    }
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    } else if (value is String) {
      return [value];
    } else {
      return [];
    }
  }
}

class TexteATrousQuestion {
  final String versetModifie;
  final List<String> reponses;

  TexteATrousQuestion({required this.versetModifie, required this.reponses});

  factory TexteATrousQuestion.fromJson(Map<String, dynamic> json) {
    return TexteATrousQuestion(
      versetModifie: json['verset_modifie'] ?? '',
      reponses: List<String>.from(json['reponses'] ?? []),
    );
  }
}

class TexteATrousBatchData {
  final List<TexteATrousData> jeux;

  TexteATrousBatchData({required this.jeux});

  factory TexteATrousBatchData.fromJson(Map<String, dynamic> json) {
    return TexteATrousBatchData(
      jeux: (json['jeux'] as List<dynamic>)
          .map((item) => TexteATrousData.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class TexteATrousData {
  final String versetModifie;
  final List<String> reponses;
  final List<int> indices;
  final String reference;
  final String? texteOriginal;

  TexteATrousData({
    required this.versetModifie,
    required this.reponses,
    required this.indices,
    required this.reference,
    this.texteOriginal,
  });

  factory TexteATrousData.fromJson(Map<String, dynamic> json) {
    return TexteATrousData(
      versetModifie: json['verset_modifie'] ?? '',
      reponses: List<String>.from(json['reponses'] ?? []),
      indices: List<int>.from(json['indices'] ?? []),
      reference: json['reference'] ?? '',
      texteOriginal: json['texte_original'],
    );
  }
}

class BibleService {
  static final BibleService _instance = BibleService._internal();
  factory BibleService() => _instance;
  BibleService._internal();

  final String _baseUrl = "https://memoriz-bible-api.onrender.com";
  final Map<String, List<VerseData>> _passageCache = {};
  final Map<String, double> _scoreCache = {};

  // Créer les headers avec la langue
  Map<String, String> _getHeaders(String language) {
    return {
      'Content-Type': 'application/json',
      'Accept-Language': language,
    };
  }

  /// Récupère le texte d'un verset unique
  /// ✅ CORRIGÉ : Pas de traduction, l'API gère tout
  Future<String> getVerseText(String reference, {String language = 'fr'}) async {
    final url = Uri.parse('$_baseUrl/verser').replace(
      queryParameters: {'ref': reference},
    );

    try {
      final response = await http
          .get(url, headers: _getHeaders(language))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['text'] ?? "Texte non trouvé.";
      } else {
        return "Erreur API : ${response.statusCode}";
      }
    } catch (e) {
      print("❌ ERREUR dans getVerseText : $e");
      return "Erreur de connexion.";
    }
  }

  /// Récupère un passage (plusieurs versets)
  /// ✅ CORRIGÉ : Pas de traduction, l'API gère tout
  Future<List<VerseData>> getPassageText(String reference, {String language = 'fr'}) async {
    // Cache par langue et référence
    final cacheKey = '${language}_$reference';
    if (_passageCache.containsKey(cacheKey)) {
      print("✅ Cache hit pour: $cacheKey");
      return _passageCache[cacheKey]!;
    }

    final url = Uri.parse('$_baseUrl/passage').replace(
      queryParameters: {'ref': reference},
    );

    print(">> Appel API pour le passage : $url (langue: $language)");

    for (int tentative = 1; tentative <= 2; tentative++) {
      try {
        print("🔄 Tentative $tentative/2 pour: $reference");

        final response = await http
            .get(url, headers: _getHeaders(language))
            .timeout(
          const Duration(seconds: 90),
          onTimeout: () {
            throw TimeoutException('Timeout après 90 secondes');
          },
        );

        if (response.statusCode == 200) {
          final decodedBody = json.decode(utf8.decode(response.bodyBytes));
          if (decodedBody is List) {
            final List<VerseData> verses = decodedBody
                .map((item) => VerseData.fromJson(item as Map<String, dynamic>))
                .toList();

            _passageCache[cacheKey] = verses;
            print("✅ Succès API pour: $reference (${verses.length} versets, $language)");
            return verses;
          } else {
            return _getFallbackVerses(reference, language);
          }
        } else {
          print("❌ Erreur HTTP ${response.statusCode}");
          if (tentative == 2) {
            return _getFallbackVerses(reference, language);
          }
        }
      } on TimeoutException catch (e) {
        print("⏰ TIMEOUT tentative $tentative");
        if (tentative == 2) {
          return _getFallbackVerses(reference, language);
        }
        await Future.delayed(const Duration(seconds: 5));
      } catch (e) {
        print("❌ ERREUR tentative $tentative : $e");
        if (tentative == 2) {
          return _getFallbackVerses(reference, language);
        }
        await Future.delayed(const Duration(seconds: 3));
      }
    }

    return _getFallbackVerses(reference, language);
  }

  /// Textes de secours bilingues
  List<VerseData> _getFallbackVerses(String reference, String language) {
    print("🔄 Utilisation du texte de secours pour: $reference ($language)");

    final Map<String, Map<String, String>> textesDeSecours = {
      // Références françaises
      'Jean 14:27': {
        'fr': 'Je vous laisse la paix, je vous donne ma paix.',
        'en': 'Peace I leave with you; my peace I give you.',
      },
      'Jean 3:16': {
        'fr': 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique.',
        'en': 'For God so loved the world that he gave his one and only Son.',
      },
      'Jean 1:1': {
        'fr': 'Au commencement était la Parole, et la Parole était avec Dieu.',
        'en': 'In the beginning was the Word, and the Word was with God.',
      },
      'Proverbes 3:5': {
        'fr': 'Confie-toi en l\'Éternel de tout ton cœur.',
        'en': 'Trust in the LORD with all your heart.',
      },
      'Philippiens 4:13': {
        'fr': 'Je puis tout par celui qui me fortifie.',
        'en': 'I can do all things through Christ who strengthens me.',
      },
      'Psaumes 23:1': {
        'fr': 'L\'Éternel est mon berger: je ne manquerai de rien.',
        'en': 'The LORD is my shepherd, I lack nothing.',
      },

      // Références anglaises (pour compatibilité)
      'John 14:27': {
        'fr': 'Je vous laisse la paix, je vous donne ma paix.',
        'en': 'Peace I leave with you; my peace I give you.',
      },
      'John 3:16': {
        'fr': 'Car Dieu a tant aimé le monde qu\'il a donné son Fils unique.',
        'en': 'For God so loved the world that he gave his one and only Son.',
      },
      'John 1:1': {
        'fr': 'Au commencement était la Parole, et la Parole était avec Dieu.',
        'en': 'In the beginning was the Word, and the Word was with God.',
      },
      'Proverbs 3:5': {
        'fr': 'Confie-toi en l\'Éternel de tout ton cœur.',
        'en': 'Trust in the LORD with all your heart.',
      },
      'Philippians 4:13': {
        'fr': 'Je puis tout par celui qui me fortifie.',
        'en': 'I can do all things through Christ who strengthens me.',
      },
      'Psalms 23:1': {
        'fr': 'L\'Éternel est mon berger: je ne manquerai de rien.',
        'en': 'The LORD is my shepherd, I lack nothing.',
      },
    };

    String texteSecours = textesDeSecours[reference]?[language] ??
        (language == 'en'
            ? 'Text temporarily unavailable. Please try again.'
            : 'Texte temporairement indisponible. Veuillez réessayer.');

    return [VerseData(reference: reference, text: texteSecours)];
  }

  /// Vérifie la similarité entre réponse utilisateur et réponse correcte
  Future<double> getVerificationScore(
      String userAnswer,
      String correctAnswer, {
        String language = 'fr',
      }) async {
    if (userAnswer.trim().isEmpty || correctAnswer.trim().isEmpty) {
      return 0.0;
    }

    final cacheKey = '${userAnswer.toLowerCase()}:${correctAnswer.toLowerCase()}';
    if (_scoreCache.containsKey(cacheKey)) {
      return _scoreCache[cacheKey]!;
    }

    final url = Uri.parse('$_baseUrl/verifier');
    try {
      final response = await http
          .post(
        url,
        headers: _getHeaders(language),
        body: json.encode({
          'reponses_utilisateur': [userAnswer],
          'reponses_correctes': [correctAnswer],
        }),
      )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final bool isCorrect = data['resultats'][0];
        double score = isCorrect ? 100.0 : _calculateSimilarityScore(userAnswer, correctAnswer);
        _scoreCache[cacheKey] = score;
        return score;
      } else {
        return _calculateSimilarityScore(userAnswer, correctAnswer);
      }
    } catch (e) {
      print("❌ ERREUR dans getVerificationScore : $e");
      return _calculateSimilarityScore(userAnswer, correctAnswer);
    }
  }

  double _calculateSimilarityScore(String userText, String correctText) {
    if (userText.trim().isEmpty) return 0.0;

    String normalizeText(String text) {
      return text
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    final userNormalized = normalizeText(userText);
    final correctNormalized = normalizeText(correctText);
    final userWords = userNormalized.split(' ');
    final correctWords = correctNormalized.split(' ');

    if (correctWords.isEmpty) return 0.0;

    int motsCorrects = 0;
    for (String mot in userWords) {
      if (correctWords.contains(mot)) motsCorrects++;
    }

    final double scoreBase = (motsCorrects / correctWords.length) * 100;
    final double ratioLongueur = userWords.length / correctWords.length;
    double bonusLongueur = 0.0;
    if (ratioLongueur >= 0.7 && ratioLongueur <= 1.3) bonusLongueur = 10.0;

    return (scoreBase + bonusLongueur).clamp(0.0, 100.0);
  }

  Future<bool> checkApiHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/'), headers: {'User-Agent': 'MemoriseBible/1.0'})
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void clearCache() {
    _passageCache.clear();
    _scoreCache.clear();
  }

  // ===================================================
  // MÉTHODES DE JEU AVEC SUPPORT MULTILINGUE
  // ===================================================

  Future<ReferenceQuestion> generateReferenceQuestion({
    required String difficulty,
    String? sourceGroup,
    String? sourceBook,
    List<String>? sourceRefs,
    String language = 'fr',
  }) async {
    final url = Uri.parse('$_baseUrl/generer-question-reference');
    final Map<String, dynamic> body = {
      'difficulty': difficulty,
      'source_group': sourceGroup,
      'source_book': sourceBook,
      'source_refs': sourceRefs,
    };
    body.removeWhere((key, value) => value == null);

    try {
      final response = await http
          .post(url, headers: _getHeaders(language), body: json.encode(body))
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        return ReferenceQuestion.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception("API Error");
      }
    } catch (e) {
      throw Exception("Connection Error: $e");
    }
  }

  /// Génère une question QCM
  /// ✅ CORRIGÉ : Pas de traduction, l'API gère tout
  Future<QuizQuestion> generateQcmQuestion({
    required String reference,
    required String niveau,
    required List<String> mots_deja_utilises,
    String language = 'fr',
  }) async {
    final url = Uri.parse('$_baseUrl/qcm');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(language),
        body: json.encode({
          'reference': reference,
          'niveau': niveau,
          'mots_deja_utilises': mots_deja_utilises,
        }),
      );

      if (response.statusCode == 200) {
        return QuizQuestion.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Failed to load QCM question');
      }
    } catch (e) {
      throw Exception("Connection Error: $e");
    }
  }

  /// Génère un jeu de remise en ordre (passage complet)
  /// ✅ CORRIGÉ : Pas de traduction, l'API gère tout
  Future<UnscrambleGameData> generateRemettreEnOrdrePassage({
    required String reference,
    String language = 'fr',
  }) async {
    final url = Uri.parse('$_baseUrl/remettre-en-ordre');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(language),
        body: json.encode({'reference': reference}),
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(utf8.decode(response.bodyBytes));
        if (decodedData.containsKey('error')) {
          throw Exception('API Error: ${decodedData['error']}');
        }
        return UnscrambleGameData.fromJson(decodedData);
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception("Connection Error: $e");
    }
  }

  /// Génère une question de remise en ordre (un seul verset)
  Future<MotsMelesData> generateRemettreEnOrdreQuestion({
    required String reference,
    String language = 'fr',
  }) async {
    final gameData = await generateRemettreEnOrdrePassage(
      reference: reference,
      language: language,
    );
    if (gameData.versets.isNotEmpty) {
      return gameData.versets.first;
    } else {
      throw Exception('No verses found');
    }
  }

  /// Génère une question de texte à trous
  /// ✅ CORRIGÉ : Pas de traduction, l'API gère tout
  Future<TexteATrousData> generateTexteATrousQuestion({
    required String reference,
    required String niveau,
    String language = 'fr',
  }) async {
    final url = Uri.parse('$_baseUrl/jeu');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(language),
        body: json.encode({
          'reference': reference,
          'niveau': niveau
        }),
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(utf8.decode(response.bodyBytes));
        if (decodedData.containsKey('error')) {
          throw Exception('API Error');
        }
        return TexteATrousData.fromJson(decodedData);
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception("Connection Error: $e");
    }
  }

  /// Vérifie les réponses du texte à trous
  Future<List<bool>> verifierTexteATrousReponses({
    required List<String> reponsesUtilisateur,
    required List<String> reponsesCorrectes,
    String language = 'fr',
  }) async {
    final url = Uri.parse('$_baseUrl/verifier');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(language),
        body: json.encode({
          'reponses_utilisateur': reponsesUtilisateur,
          'reponses_correctes': reponsesCorrectes,
        }),
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(utf8.decode(response.bodyBytes));
        return List<bool>.from(decodedData['resultats'] ?? []);
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception("Connection Error: $e");
    }
  }

  /// Génère un batch de texte à trous
  /// ✅ CORRIGÉ : Pas de traduction, l'API gère tout
  Future<TexteATrousBatchData> generateTexteATrousBatch({
    required String reference,
    required String niveau,
    required int nombre,
    String language = 'fr',
  }) async {
    final url = Uri.parse('$_baseUrl/duel/texte-a-trous/batch');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(language),
        body: json.encode({
          'reference': reference,
          'niveau': niveau,
          'nombre': nombre,
        }),
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(utf8.decode(response.bodyBytes));
        if (decodedData.containsKey('error')) {
          throw Exception('API Error');
        }
        return TexteATrousBatchData.fromJson(decodedData);
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception("Connection Error: $e");
    }
  }

  // ===================================================
  // 🌟 NOUVELLES MÉTHODES DE BATCH AJOUTÉES 🌟
  // ===================================================

  /// Génère un batch de QCM (pour les duels)
  /// Appelle l'endpoint: /qcm/batch
  Future<List<Map<String, dynamic>>> generateQcmBatch({
    required String reference,
    required String niveau,
    required int nombre,
    String language = 'fr',
  }) async {
    final url = Uri.parse('$_baseUrl/qcm/batch');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(language), // Envoie la langue !
        body: json.encode({
          'reference': reference,
          'niveau': niveau,
          'nombre': nombre,
        }),
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(utf8.decode(response.bodyBytes));
        // HubPage s'attend à une clé "questions"
        if (decodedData.containsKey('questions')) {
          final questions = List<Map<String, dynamic>>.from(decodedData["questions"]);
          return questions;
        } else {
          throw Exception('La réponse API ne contient pas la clé "questions"');
        }
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception("Erreur de connexion dans generateQcmBatch: $e");
    }
  }


  /// Génère un batch de Remise en Ordre (pour les duels)
  /// Appelle l'endpoint: /duel/ordre/batch
  Future<List<Map<String, dynamic>>> generateOrdreBatch({
    required String reference,
    required String niveau,
    required int nombre,
    String language = 'fr',
  }) async {
    final url = Uri.parse('$_baseUrl/duel/ordre/batch');
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(language), // Envoie la langue !
        body: json.encode({
          'reference': reference,
          'niveau': niveau,
          'nombre': nombre,
        }),
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(utf8.decode(response.bodyBytes));
        // HubPage s'attend à une clé "jeux"
        if (decodedData.containsKey('jeux')) {
          final jeux = List<Map<String, dynamic>>.from(decodedData["jeux"]);
          return jeux;
        } else {
          throw Exception('La réponse API ne contient pas la clé "jeux"');
        }
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception("Erreur de connexion dans generateOrdreBatch: $e");
    }
  }
}

