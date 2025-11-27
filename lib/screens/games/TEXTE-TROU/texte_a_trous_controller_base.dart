import 'package:flutter/foundation.dart';

abstract class TexteATrousControllerBase extends ChangeNotifier {
  // === PROPRIÉTÉS COMMUNES ===
  bool get isLoading;
  String get versetModifie;
  List<String> get reponses;
  List<int> get indices;
  String? get currentReference;
  bool get isGameFinished => false;
  String get status;

  // 👇 AJOUT DE LA PROPRIÉTÉ MANQUANTE
  int get currentQuestionIndex => 0;  // ← C'est ça qui manque !

  // === PROPRIÉTÉS POUR L'UI ===
  int get currentScore => 0;
  int get maxScore => 7;
  String get gameStatus => 'playing';

  // === PROPRIÉTÉS POUR LA VÉRIFICATION ===
  bool get answered => false;
  bool get bonneReponse => false;
  List<bool> get resultatsVerification => [];

  // === PROPRIÉTÉS OPTIONNELLES POUR LE SOLO ===
  bool get canShowNextButton => false;
  String get niveauActuel => 'débutant';

  // === ACTIONS COMMUNES ===
  Future<void> verifierReponses(List<String> reponsesUtilisateur);
  void loadNextQuestion();
  void restartGame();

  @override
  void dispose() {
    super.dispose();
  }
}