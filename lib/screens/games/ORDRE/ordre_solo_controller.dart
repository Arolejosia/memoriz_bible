import 'dart:async';
import '../../../models/game_session.dart';
import '../../../models/verse_model.dart';
import 'ordre_game_controller_base.dart';
import '../../../services/Bible_service.dart';
import 'ordre_translations.dart';

class OrdreSoloController extends OrdreGameControllerBase {
  final Verse verse;
  final bool isSandbox;
  final Function(bool didWin)? onGameConcluded;
  final String language; // ✅ AJOUTÉ

  // === ÉTAT PRIVÉ ===
  bool _isLoading = true;
  String _questionText = "";
  List<String> _wordBank = [];
  List<String?> _placedWords = [];
  List<String> _correctOrder = [];
  String? _currentReference;
  bool _isAnswered = false;
  List<bool> _wordStates = [];

  // Données de jeu
  UnscrambleGameData? _currentGameData;
  int _currentVerseIndex = 0;
  late GameSession session;

  OrdreSoloController({
    required this.verse,
    this.isSandbox = false,
    this.onGameConcluded,
    this.language = 'fr', // ✅ AJOUTÉ avec valeur par défaut
  }) {
    session = GameSession(
      isSandbox: isSandbox,
      scoreToWin: _getVerseCount(),
      onGameWon: () => onGameConcluded?.call(true),
    );
    _loadGame();
  }

  // === GETTERS SURCHARGÉS ===
  @override
  bool get isLoading => _isLoading;

  @override
  String get questionText => _questionText;

  @override
  List<String> get wordBank => _wordBank;

  @override
  List<String?> get placedWords => _placedWords;

  @override
  List<String> get correctOrder => _correctOrder;

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

  @override
  bool get isAnswered => _isAnswered;

  @override
  List<bool> get wordStates => _wordStates;

  // === GETTERS SPÉCIFIQUES AU SOLO ===
  @override
  String? get currentReference => _currentReference;

  @override
  bool get canShowNextButton => _isAnswered;

  // === MÉTHODES PRIVÉES ===
  int _getVerseCount() {
    final ref = verse.reference;
    if (ref.contains('-')) {
      final parts = ref.split(':').last.split('-');
      return int.parse(parts[1]) - int.parse(parts[0]) + 1;
    }
    return 1;
  }

  Future<void> _loadGame() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Détecter la langue depuis la référence
      final detectedLanguage = detectLanguageFromReference(verse.reference);
      print('🎮 Chargement du jeu Ordre - Référence: ${verse.reference}, Langue: $detectedLanguage');

      final gameData = await BibleService().generateRemettreEnOrdrePassage(
        reference: verse.reference,
        language: detectedLanguage, // ✅ Utilise la langue détectée
      );

      print('✅ Données reçues - Type: ${gameData.runtimeType}');
      print('✅ Nombre de versets: ${gameData.versets.length}');

      // Vérification de la structure
      if (gameData.versets.isNotEmpty) {
        _currentGameData = gameData;
        _setupVerse(gameData.versets[0]);
        print('✅ Premier verset configuré: $_currentReference');
      } else {
        print('❌ Aucun verset dans les données');
        _questionText = "no_verses_found"; // ✅ Clé de traduction
      }
    } catch (e, stackTrace) {
      print('❌ Erreur lors du chargement du jeu: $e');
      print('📋 Stack trace: $stackTrace');
      _questionText = "loading_error"; // ✅ Clé de traduction
    }

    _isLoading = false;
    notifyListeners();
  }

  void _setupVerse(MotsMelesData verseData) {
    _isAnswered = false;
    _wordBank = List.from(verseData.motsMelanges);
    _placedWords = List.filled(verseData.motsCorrects.length, null);
    _correctOrder = verseData.motsCorrects;
    _currentReference = verseData.reference;
    _questionText = "put_words_in_order"; // ✅ Clé de traduction
    _wordStates = [];

    print('✅ Verset configuré:');
    print('   - Référence: $_currentReference');
    print('   - Mots mélangés: ${_wordBank.length}');
    print('   - Ordre correct: ${_correctOrder.length}');

    notifyListeners();
  }

  // === ACTIONS PUBLIQUES ===
  @override
  void placeWord(String word, int targetIndex, {int? sourceIndex}) {
    if (_isAnswered) return;

    final existingWordInSlot = _placedWords[targetIndex];
    _placedWords[targetIndex] = word;

    if (sourceIndex != null) {
      // Mot déplacé depuis une autre position (échange)
      _placedWords[sourceIndex] = existingWordInSlot;
    } else {
      // Mot venant de la banque
      _wordBank.remove(word);
      if (existingWordInSlot != null) {
        _wordBank.add(existingWordInSlot);
      }
    }
    notifyListeners();
  }

  @override
  void returnWordToBank(String word, int sourceIndex) {
    if (_isAnswered) return;

    _placedWords[sourceIndex] = null;
    _wordBank.add(word);
    notifyListeners();
  }

  @override
  void submitAnswer() {
    if (_isAnswered || _placedWords.contains(null)) return;

    final userAnswer = _placedWords.whereType<String>().toList();
    List<bool> newWordStates = [];
    bool isCorrect = true;

    // Vérifier chaque mot individuellement
    for (int i = 0; i < _correctOrder.length; i++) {
      if (i < userAnswer.length && userAnswer[i] == _correctOrder[i]) {
        newWordStates.add(true);
      } else {
        newWordStates.add(false);
        isCorrect = false;
      }
    }

    _wordStates = newWordStates;
    _isAnswered = true;

    print('✅ Réponse soumise - Correcte: $isCorrect');
    print('   - Réponse utilisateur: ${userAnswer.join(" ")}');
    print('   - Ordre correct: ${_correctOrder.join(" ")}');

    session.submitAnswer(isCorrect: isCorrect);
    notifyListeners();

    // Auto-passer à la question suivante si correct
    if (isCorrect && !session.isGameFinished) {
      Timer(const Duration(milliseconds: 1500), _handleNextAction);
    }
  }

  void _handleNextAction() {
    if (!_isAnswered) return;

    final userAnswer = _placedWords.whereType<String>().toList();
    final isCorrect = userAnswer.join(' ') == _correctOrder.join(' ');

    if (!isCorrect) {
      // Permettre de réessayer
      _isAnswered = false;
      _wordStates = [];
      notifyListeners();
      return;
    }

    if (session.isGameFinished) {
      print('🏆 Jeu terminé avec succès!');
      onGameConcluded?.call(true);
      return;
    }

    // Passer au verset suivant
    if (_currentGameData != null &&
        _currentVerseIndex < _currentGameData!.versets.length - 1) {
      _currentVerseIndex++;
      print(
          '➡️ Passage au verset ${_currentVerseIndex + 1}/${_currentGameData!.versets.length}');
      _setupVerse(_currentGameData!.versets[_currentVerseIndex]);
    } else {
      print('🏆 Tous les versets complétés!');
      onGameConcluded?.call(true);
    }
  }

  @override
  void loadNextQuestion() {
    if (!isGameFinished) {
      _handleNextAction();
    }
  }

  @override
  void restartGame() {
    session.reset();
    _currentVerseIndex = 0;
    _loadGame();
  }
}