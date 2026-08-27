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
  final String language;

  bool _isLoading = true;
  String _questionText = "";
  List<String> _wordBank = [];
  List<String?> _placedWords = [];
  List<String> _correctOrder = [];
  String? _currentReference;
  bool _isAnswered = false;
  List<bool> _wordStates = [];

  UnscrambleGameData? _currentGameData;
  int _currentVerseIndex = 0;
  late GameSession session;

  OrdreSoloController({
    required this.verse,
    this.isSandbox = false,
    this.onGameConcluded,
    this.language = 'fr',
  }) {
    session = GameSession(
      isSandbox: isSandbox,
      scoreToWin: _getVerseCount(),
      onGameWon: () => onGameConcluded?.call(true),
    );
    _loadGame();
  }

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

  @override
  String? get currentReference => _currentReference;

  @override
  bool get canShowNextButton => _isAnswered;

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
      final detectedLanguage = detectLanguageFromReference(verse.reference);
      print('🎮 Chargement du jeu Ordre - Référence: ${verse.reference}, Langue: $detectedLanguage');

      final gameData = await BibleService().generateRemettreEnOrdrePassage(
        reference: verse.reference,
        language: detectedLanguage,
      );

      print('✅ Données reçues - Type: ${gameData.runtimeType}');
      print('✅ Nombre de versets: ${gameData.versets.length}');

      if (gameData.versets.isNotEmpty) {
        _currentGameData = gameData;
        _setupVerse(gameData.versets[0]);
        print('✅ Premier verset configuré: $_currentReference');
      } else {
        print('❌ Aucun verset dans les données');
        _questionText = "no_verses_found";
      }
    } catch (e, stackTrace) {
      print('❌ Erreur lors du chargement du jeu: $e');
      print('📋 Stack trace: $stackTrace');
      _questionText = "loading_error";
    }

    _isLoading = false;
    notifyListeners();
  }

  void _setupVerse(MotsMelesData verseData) {
    _isAnswered = false;
    _wordBank = List.from(verseData.motsMelanges);
    // 👈 AVANT : List.filled(verseData.motsCorrects.length, null)
    //    → liste à taille FIXE, insert()/removeLast() lèvent une exception.
    _placedWords = List<String?>.filled(
      verseData.motsCorrects.length,
      null,
      growable: true,
    );
    _correctOrder = verseData.motsCorrects;
    _currentReference = verseData.reference;
    _questionText = "put_words_in_order";
    _wordStates = [];

    print('✅ Verset configuré:');
    print('   - Référence: $_currentReference');
    print('   - Mots mélangés: ${_wordBank.length}');
    print('   - Ordre correct: ${_correctOrder.length}');

    notifyListeners();
  }

  // === ACTIONS PUBLIQUES ===

  // 👈 RÉÉCRIT : avant, déposer un mot sur un slot occupé faisait un simple
  // échange (swap) des deux mots — impossible d'insérer "entre" deux mots
  // déjà placés sans tout réorganiser manuellement.
  //
  // Maintenant : _placedWords maintient un invariant strict — tous les mots
  // placés sont toujours groupés en bloc contigu au début de la liste, tous
  // les emplacements vides (null) sont toujours à la fin. Grâce à ça,
  // déposer un mot sur un mot déjà placé l'INSÈRE juste avant lui et décale
  // tout le reste d'une position vers la droite (comme dans un vrai éditeur
  // de texte), au lieu de l'échanger.
  @override
  void placeWord(String word, int targetIndex, {int? sourceIndex}) {
    if (_isAnswered) return;

    // Nombre de mots actuellement placés, calculé AVANT toute modification.
    final nonNullCount = _placedWords.where((w) => w != null).length;

    if (sourceIndex != null) {
      // Le mot vient d'un autre slot déjà rempli : on le réorganise.
      // 1. On l'extrait de sa position actuelle (la liste se contracte
      //    naturellement, aucun trou ne reste au milieu).
      _placedWords.removeAt(sourceIndex);

      // 2. Si le mot venait d'AVANT la cible, l'extraction a déjà décalé
      //    tout ce qui suit d'un cran vers la gauche — donc la position
      //    cible doit être ajustée d'un cran en arrière.
      int adjustedTarget = sourceIndex < targetIndex ? targetIndex - 1 : targetIndex;

      // 3. On ne peut pas insérer au-delà du nombre de mots réellement
      //    placés après extraction (nonNullCount - 1, puisqu'on vient
      //    d'en retirer un).
      final maxInsertIndex = nonNullCount - 1;
      adjustedTarget = adjustedTarget.clamp(0, maxInsertIndex);

      // 4. On insère à la nouvelle position — tout ce qui était à partir
      //    de cette position est automatiquement décalé d'un cran à droite.
      _placedWords.insert(adjustedTarget, word);
    } else {
      // Le mot vient de la banque de mots.
      _wordBank.remove(word);

      // On ne peut pas insérer au-delà du bloc de mots déjà placés
      // (au-delà, ce ne sont que des emplacements vides équivalents).
      final clampedTarget = targetIndex.clamp(0, nonNullCount);

      _placedWords.insert(clampedTarget, word);
      // L'insertion a fait grandir la liste d'un élément — on retire le
      // null excédentaire en fin de liste pour garder une taille fixe.
      _placedWords.removeLast();
    }

    notifyListeners();
  }

  // 👈 CORRIGÉ : avant, remettre un mot dans la banque le mettait à `null`
  // sur place, créant un TROU au milieu de la liste et cassant l'invariant
  // "mots placés toujours contigus au début". Maintenant on l'extrait
  // proprement (la liste se contracte) puis on rajoute un null à la fin.
  @override
  void returnWordToBank(String word, int sourceIndex) {
    if (_isAnswered) return;

    _placedWords.removeAt(sourceIndex);
    _placedWords.add(null);
    _wordBank.add(word);

    notifyListeners();
  }

  @override
  void submitAnswer() {
    if (_isAnswered || _placedWords.contains(null)) return;

    final userAnswer = _placedWords.whereType<String>().toList();
    List<bool> newWordStates = [];
    bool isCorrect = true;

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

    if (isCorrect && !session.isGameFinished) {
      Timer(const Duration(milliseconds: 1500), _handleNextAction);
    }
  }

  void _handleNextAction() {
    if (!_isAnswered) return;

    final userAnswer = _placedWords.whereType<String>().toList();
    final isCorrect = userAnswer.join(' ') == _correctOrder.join(' ');

    if (!isCorrect) {
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

    if (_currentGameData != null &&
        _currentVerseIndex < _currentGameData!.versets.length - 1) {
      _currentVerseIndex++;
      print('➡️ Passage au verset ${_currentVerseIndex + 1}/${_currentGameData!.versets.length}');
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