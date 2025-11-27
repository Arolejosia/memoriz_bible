import 'package:flutter/foundation.dart';

abstract class QcmGameControllerBase extends ChangeNotifier {
  // === PROPRIÉTÉS COMMUNES ===
  bool get isLoading;
  String get questionText;
  List<String> get options;
  String get correctAnswer;
  bool get isGameFinished => false;
  String get status;

  // === PROPRIÉTÉS POUR L'UI ===
  int get currentScore => 0;
  int get maxScore => 10;
  String get gameStatus => 'playing';
  //Propriétés optionnelles pour le solo
  String? get lastAnswer => null;
  bool get canShowNextButton => false;

  // === ACTIONS COMMUNES ===
  void submitAnswer(String answer);
  void dispose() {
    super.dispose();
  }

  // === MÉTHODES OPTIONNELLES POUR LES SOUS-CLASSES ===
  void loadNextQuestion() {}
  void restartGame() {}
}