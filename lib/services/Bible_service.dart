// Fichier: services/bible_service.dart

import 'dart:convert';
import 'dart:async'; // Pour la gestion du Timeout
import 'package:http/http.dart' as http;

/// Représente un verset unique avec sa référence et son texte.
/// Utile pour structurer les données reçues de l'API.
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


// Modèle générique pour les jeux de type quiz (QCM, Trouver la Référence)
class QuizQuestion {
  final String questionText;
  final List<String> options;
  final String correctAnswer;

  QuizQuestion({ required this.questionText, required this.options, required this.correctAnswer });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      questionText: json['question'] ?? json['question_text'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['reponse_correcte'] ?? '',
    );
  }
}

// Modèle pour le jeu "Remettre en Ordre"
class MotsMelesData {
  final String reference;
  final List<String> motsMelanges;
  final List<String> motsCorrects;

  MotsMelesData({ required this.reference, required this.motsMelanges, required this.motsCorrects });

  factory MotsMelesData.fromJson(Map<String, dynamic> json) {
    return MotsMelesData(
      reference: json['reference'] ?? '',
      motsMelanges: List<String>.from(json['mots_melanges'] ?? []),
      motsCorrects: List<String>.from(json['mots_corrects'] ?? []),
    );
  }
}
class UnscrambleGameData {
  final List<MotsMelesData> versets;
  UnscrambleGameData({required this.versets});
  factory UnscrambleGameData.fromJson(List<dynamic> jsonList) {
    return UnscrambleGameData(
      versets: jsonList.map((i) => MotsMelesData.fromJson(i)).toList(),
    );
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

class BibleService {
  // --- Singleton Pattern ---
  static final BibleService _instance = BibleService._internal();
  factory BibleService() => _instance;
  BibleService._internal();
  // -------------------------

  // ✅ REMPLACEZ CECI par l'URL de base de votre API
  final String _baseUrl = "https://memoriz-bible-api.onrender.com";

  /// Récupère le texte pour un SEUL verset.
  /// L'ancienne méthode, toujours utile.
  Future<String> getVerseText(String reference) async {
    final url = Uri.parse('$_baseUrl/verser').replace(
      queryParameters: {'ref': reference},
    );
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
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

  /// ✅ NOUVEAU : Récupère le texte pour un passage de plusieurs versets.
  /// Retourne une liste d'objets VerseData.
  Future<List<VerseData>> getPassageText(String reference) async {
    // On appelle la nouvelle route /passage
    final url = Uri.parse('$_baseUrl/passage').replace(
      queryParameters: {'ref': reference},
    );

    print(">> Appel API pour le passage : $url");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decodedBody = json.decode(utf8.decode(response.bodyBytes));
        if (   decodedBody is List) {
        // On transforme la liste de JSON en une liste de VerseData
        final List<VerseData> verses =  decodedBody
            .map((item) => VerseData.fromJson(item as Map<String, dynamic>))
            .toList();

        return verses;
        } else {
          // The response is NOT a list (it's an int, a Map, etc.)
          print("❌ UNEXPECTED RESPONSE in getPassageText: Body is not a List.");
          print("   Received data of type: ${  decodedBody .runtimeType}");
          print("   Response Body: $decodedBody");
          return []; // Return an empty list to prevent the app from crashing
        }
      } else {
        // En cas d'erreur serveur, on retourne une liste vide
        print("Erreur API pour le passage : ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("❌ ERREUR CRITIQUE dans getPassageText : $e");
      // En cas d'erreur de connexion, on retourne aussi une liste vide
      return [];
    }
  }
  Future<int> getVerificationScore(String userAnswer, String correctAnswer) async {
    final url = Uri.parse('$_baseUrl/verifier');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'reponses_utilisateur': [userAnswer],
          'reponses_correctes': [correctAnswer],
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final bool isCorrect = data['resultats'][0];
        // On retourne un score simple : 100 si c'est bon, 30 si c'est faux (score < 70)
        return isCorrect ? 100 : 30;
      } else {
        return 0; // Erreur API
      }
    } catch (e) {
      print("❌ ERREUR dans getVerificationScore : $e");
      return 0; // Erreur de connexion
    }
  }
  // In lib/services/bible_service.dart

  Future<ReferenceQuestion> generateReferenceQuestion({
    required String difficulty,
    String? sourceGroup,
    String? sourceBook,      // ✅ Add this parameter
    List<String>? sourceRefs, // ✅ A, List<String>? sourceRefs, String? sourceBookdd this parameter
  }) async {
    final url = Uri.parse('$_baseUrl/generer-question-reference');
    final Map<String, dynamic> body = {
      'difficulty': difficulty,
      'source_group': sourceGroup,
      'source_book': sourceBook,
      'source_refs': sourceRefs,
    };

    // This line cleverly removes any parameters that are null
    body.removeWhere((key, value) => value == null);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return ReferenceQuestion.fromJson(data);
      } else {
        final errorDetail = json.decode(utf8.decode(response.bodyBytes))['detail'];
        throw Exception("API Error: $errorDetail");
      }
    } catch (e) {
      throw Exception("Connection Error: $e");
    }
  }
  Future<QuizQuestion> generateQcmQuestion({required String reference}) async {
    final url = Uri.parse('$_baseUrl/qcm');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'reference': reference, 'niveau': 'moyen'}),
      );
      if (response.statusCode == 200) {
        return QuizQuestion.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Failed to load QCM question');
      }
    } catch (e) {
      throw Exception("Connection Error for QCM game: $e");
    }
  }

  Future<UnscrambleGameData> generateRemettreEnOrdrePassage({required String reference}) async {
    final url = Uri.parse('$_baseUrl/remettre-en-ordre');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'reference': reference}),
      );
      if (response.statusCode == 200) {
        // API returns a list, so we create UnscrambleGameData from it
        return UnscrambleGameData.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Failed to load Remettre en Ordre data');
      }
    } catch (e) {
      throw Exception("Connection Error for Remettre en Ordre game: $e");
    }
  }

  // ✅ ADD THIS METHOD
  Future<MotsMelesData> generateRemettreEnOrdreQuestion({required String reference}) async {
    // This assumes your API endpoint is at /remettre-en-ordre
    // and takes a 'ref' parameter. Adjust if necessary.
    final url = Uri.parse('$_baseUrl/remettre-en-ordre').replace(queryParameters: {'ref': reference});
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return MotsMelesData.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Failed to load Remettre en Ordre question');
      }
    } catch (e) {
      throw Exception("Connection Error for Remettre en Ordre game: $e");
    }
  }

  // ✅ AJOUT : Nouvelle méthode pour générer une question de "Texte à Trous"
  Future<TexteATrousQuestion> generateTexteATrousQuestion({
    required String reference,
    String niveau = 'intermédiaire',
  }) async {
    final url = Uri.parse('$_baseUrl/jeu');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'reference': reference,
          'niveau': niveau,
        }),
      );
      if (response.statusCode == 200) {
        return TexteATrousQuestion.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception('Failed to load Texte à Trous question');
      }
    } catch (e) {
      throw Exception("Connection Error for Texte à Trous game: $e");
    }
  }

}