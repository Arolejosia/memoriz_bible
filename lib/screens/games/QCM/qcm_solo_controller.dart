import 'dart:async';
import '../../../models/game_session.dart';
import '../../../models/verse_model.dart';
import 'qcm_game_controller_base.dart';
import '../../../services/Bible_service.dart';

class QcmSoloController extends QcmGameControllerBase {
  final Verse verse;
  final bool isSandbox;
  final Function(bool didWin)? onGameConcluded;

  // === STATE PRIVÉ ===
  bool _isLoading = true;
  String _question = "";
  List<String> _options = [];
  String _correctAnswer = "";
  String? _lastAnswer;
  bool _wasLastAnswerCorrect = false;
  final Set<String> _motsApprisDansLaSession = {};
  late GameSession session;

  QcmSoloController({
    required this.verse,
    this.isSandbox = false,
    this.onGameConcluded,
  }) {
    session = GameSession(
      isSandbox: isSandbox,
      scoreToWin: 10,
      onGameWon: () => onGameConcluded?.call(true),
    );
    _loadQuestion();
  }

  // === GETTERS SURCHARGÉS ===
  @override
  bool get isLoading => _isLoading;

  @override
  String get questionText => _question;

  @override
  List<String> get options => _options;

  @override
  String get correctAnswer => _correctAnswer;

  @override
  bool get isGameFinished => session.isGameFinished;

  @override
  int get currentScore => session.score;

  @override
  int get maxScore => session.scoreToWin;

  @override
  String get status {
    if (isLoading) return 'loading';
    if (isGameFinished) return 'finished';
    return 'playing';
  }

  // === GETTERS SPÉCIFIQUES AU SOLO ===
  String? get lastAnswer => _lastAnswer;
  bool get wasLastAnswerCorrect => _wasLastAnswerCorrect;
  bool get canShowNextButton => _lastAnswer != null && !_wasLastAnswerCorrect;

  // === LOGIQUE MÉTIER ===
  Future<void> _loadQuestion() async {
    _isLoading = true;
    _lastAnswer = null;
    _wasLastAnswerCorrect = false;
    notifyListeners();

    try {
      String niveauApi = _getDifficultyLevel();

      print('🎮 QCM: Chargement de la question');
      print('📖 Référence: ${verse.reference}');
      print('📊 Niveau: $niveauApi');
      print('🔤 Mots utilisés: ${_motsApprisDansLaSession.length}');

      String language = _detectLanguage(verse.reference);
      print('🌍 Langue détectée: $language');

      final qData = await BibleService()
          .generateQcmQuestion(
        reference: verse.reference,
        niveau: niveauApi,
        mots_deja_utilises: _motsApprisDansLaSession.toList(),
        language: language,
      )
          .timeout(const Duration(seconds: 30), onTimeout: () {
        throw TimeoutException('Timeout QCM après 30 secondes');
      });

      if (qData.cycleRecommence) {
        _motsApprisDansLaSession.clear();
      }

      _question = qData.questionText;
      _options = qData.options;
      _correctAnswer = qData.correctAnswer;
    } catch (e, stackTrace) {
      print('❌ Erreur QCM: $e\n$stackTrace');
      _question = "Erreur lors du chargement: $e";
      _options = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  String _getDifficultyLevel() {
    switch (session.difficulty) {
      case 1:
        return 'facile';
      case 2:
        return 'moyen';
      default:
        return 'difficile';
    }
  }

  // ✅ AJOUTEZ ICI
  String _detectLanguage(String reference) {
    final englishBooks = [
      'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy',
      'Joshua', 'Judges', 'Ruth', 'Samuel', 'Kings', 'Chronicles',
      'Ezra', 'Nehemiah', 'Esther', 'Job', 'Psalms', 'Proverbs',
      'Ecclesiastes', 'Song', 'Isaiah', 'Jeremiah',
      'Lamentations', 'Ezekiel', 'Daniel', 'Hosea', 'Joel', 'Amos',
      'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk', 'Zephaniah',
      'Haggai', 'Zechariah', 'Malachi', 'Matthew', 'Mark', 'Luke',
      'John', 'Acts', 'Romans', 'Corinthians', 'Galatians',
      'Ephesians', 'Philippians', 'Colossians', 'Thessalonians',
      'Timothy', 'Titus', 'Philemon', 'Hebrews', 'James', 'Peter',
      'Jude', 'Revelation'
    ];

    for (final book in englishBooks) {
      if (reference.startsWith(book)) {
        return 'en';
      }
    }

    return 'fr';
  }



  @override
  void submitAnswer(String answer) {
    if (isGameFinished || _lastAnswer != null) return;

    print('📝 Réponse: $answer (correcte: $_correctAnswer)');
    _lastAnswer = answer;
    _wasLastAnswerCorrect =
        answer.toLowerCase() == _correctAnswer.toLowerCase();

    if (_wasLastAnswerCorrect) {
      _motsApprisDansLaSession.add(_correctAnswer.toLowerCase());
      print('✅ Bonne réponse ! Score: ${session.score + 1}');
    } else {
      print('❌ Mauvaise réponse.');
    }

    session.submitAnswer(isCorrect: _wasLastAnswerCorrect);
    notifyListeners();

    if (_wasLastAnswerCorrect && !session.isGameFinished) {
      Timer(const Duration(milliseconds: 1500), _loadQuestion);
    }
  }

  @override
  void loadNextQuestion() {
    if (!isGameFinished) _loadQuestion();
  }

  @override
  void restartGame() {
    session.reset();
    _motsApprisDansLaSession.clear();
    _loadQuestion();
  }
}
