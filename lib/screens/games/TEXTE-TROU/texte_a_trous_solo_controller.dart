import 'dart:async';
import '../../../models/game_session.dart';
import '../../../models/verse_model.dart';
import 'texte_a_trous_controller_base.dart';
import '../../../services/Bible_service.dart';

class TexteATrousSoloController extends TexteATrousControllerBase {
  final Verse verse;
  final bool isSandbox;
  final Function(bool didWin)? onGameConcluded;


  // === ÉTAT PRIVÉ ===
  bool _isLoading = true;
  String _versetModifie = "";
  List<String> _reponses = [];
  List<int> _indices = [];
  String? _currentReference;
  String _niveauActuel = 'débutant';

  // État de la vérification
  bool _answered = false;
  bool _bonneReponse = false;
  List<bool> _resultatsVerification = [];
  String _errorMessage = '';

  late GameSession session;

  TexteATrousSoloController({
    required this.verse,
    this.isSandbox = false,
    this.onGameConcluded,
  }) {
    session = GameSession(
      isSandbox: isSandbox,
      scoreToWin: 7, // L'objectif pour gagner
      onGameWon: () => onGameConcluded?.call(true),
    );
    _loadQuestion();
  }

  // === GETTERS SURCHARGÉS ===
  @override
  bool get isLoading => _isLoading;

  @override
  String get versetModifie => _versetModifie;

  @override
  List<String> get reponses => _reponses;

  @override
  List<int> get indices => _indices;

  @override
  String? get currentReference => _currentReference;

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
  @override
  bool get answered => _answered;

  @override
  bool get bonneReponse => _bonneReponse;

  @override
  List<bool> get resultatsVerification => _resultatsVerification;

  @override
  bool get canShowNextButton => _answered;

  @override
  String get niveauActuel => _niveauActuel;

  String get errorMessage => _errorMessage;

  // Détecter la langue depuis la référence
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

  // === LOGIQUE MÉTIER ===
  Future<void> _loadQuestion() async {
    _isLoading = true;
    _answered = false;
    _bonneReponse = false;
    _resultatsVerification = [];
    _errorMessage = '';
    notifyListeners();

    try {
      final language = _detectLanguage(verse.reference);
      print('🎮 Chargement de la question - Référence: ${verse.reference}, Niveau: $_niveauActuel, Langue: $language');

      final gameData = await BibleService().generateTexteATrousQuestion(
        reference: verse.reference,
        niveau: _niveauActuel,
        language: language, // ✅ Ajout du paramètre language
      );

      _versetModifie = gameData.versetModifie;
      _reponses = gameData.reponses;
      _indices = gameData.indices;
      _currentReference = gameData.reference;
      _errorMessage = '';

      print('✅ Question chargée - Verset: ${_versetModifie.substring(0, _versetModifie.length < 50 ? _versetModifie.length : 50)}...');
      print('✅ Nombre de réponses: ${_reponses.length}');
      print('✅ Indices: $_indices');
    } catch (e, stackTrace) {
      print('❌ ERREUR lors du chargement: $e');
      print('📍 Stack trace: $stackTrace');
      _errorMessage = "loading_error";
      _versetModifie = _errorMessage;
      _reponses = [];
      _indices = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  @override
  Future<void> verifierReponses(List<String> reponsesUtilisateur) async {
    if (_answered || isGameFinished) return;

    try {
      final language = _detectLanguage(verse.reference);

      final resultats = await BibleService().verifierTexteATrousReponses(
        reponsesUtilisateur: reponsesUtilisateur,
        reponsesCorrectes: _reponses,
        language: language, // ✅ Ajout du paramètre language
      );

      final bool toutBon = resultats.every((res) => res == true);

      _answered = true;
      _bonneReponse = toutBon;
      _resultatsVerification = resultats;

      if (toutBon) {
        session.submitAnswer(isCorrect: true);
      }

      notifyListeners();
    } catch (e) {
      print('❌ ERREUR lors de la vérification: $e');
      _errorMessage = "verification_error";
      notifyListeners();
    }
  }

  void _continuerPartie() {
    // Vérifier si l'objectif final est atteint
    if (session.score >= session.scoreToWin) {
      onGameConcluded?.call(true);
      return;
    }

    // Mettre à jour la difficulté en fonction du score
    _updateDifficulty();

    // Charger la question suivante
    _loadQuestion();
  }

  void _updateDifficulty() {
    if (session.score >= 7 && _niveauActuel != 'expert') {
      _niveauActuel = 'expert';
    } else if (session.score >= 3 && _niveauActuel == 'débutant') {
      _niveauActuel = 'intermédiaire';
    }
  }

  @override
  void loadNextQuestion() {
    if (!isGameFinished) {
      _continuerPartie();
    }
  }

  @override
  void restartGame() {
    session.reset();
    _niveauActuel = 'débutant';
    _loadQuestion();
  }
}