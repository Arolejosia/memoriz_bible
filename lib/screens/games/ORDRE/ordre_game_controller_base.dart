import 'package:flutter/foundation.dart';

abstract class OrdreGameControllerBase extends ChangeNotifier {
  // === PROPRIÉTÉS COMMUNES ===
  bool get isLoading;
  String get questionText;
  List<String> get wordBank;
  List<String?> get placedWords;
  List<String> get correctOrder;
  bool get isGameFinished => false;
  String get status;

  // === PROPRIÉTÉS POUR L'UI ===
  int get currentScore => 0;
  int get maxScore => 10;
  String get gameStatus => 'playing';
  bool get isAnswered => false;
  List<bool> get wordStates => [];

  // Propriétés optionnelles pour le solo
  String? get currentReference => null;
  bool get canShowNextButton => false;

  // === ACTIONS COMMUNES ===
  void placeWord(String word, int targetIndex, {int? sourceIndex});
  void returnWordToBank(String word, int sourceIndex);
  void submitAnswer();

  @override
  void dispose() {
    super.dispose();
  }

  // === MÉTHODES OPTIONNELLES POUR LES SOUS-CLASSES ===
  void loadNextQuestion() {}
  void restartGame() {}
}