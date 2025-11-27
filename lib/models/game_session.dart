// File: lib/game_session.dart

import 'package:flutter/foundation.dart';

class GameSession {
  // --- Properties / Propriétés ---
  final bool isSandbox;
  final int scoreToWin;
  final VoidCallback onGameWon; // Function to call when the game is won in progression mode / Fonction à appeler quand la partie est gagnée en mode progression

  int score = 0;
  int difficulty = 1;

  // --- Constructor / Constructeur ---
  GameSession({
    required this.isSandbox,
    required this.scoreToWin,
    required this.onGameWon,
  });

  bool isGameFinished = false;

  /// This is the main function. It manages what happens after an answer.
  /// C'est la fonction principale. Elle gère ce qui se passe après une réponse.
  void submitAnswer({required bool isCorrect}) {
    if (isGameFinished) return;
    if (!isCorrect) {
      return;
    }

    score++;
    print("Score: $score, ScoreToWin: $scoreToWin, isSandbox: $isSandbox");

    // First check if we've reached the score to win (for all modes)
    // Vérifier d'abord si on a atteint le score pour gagner (pour tous les modes)
    if (score >= scoreToWin) {
      isGameFinished = true;
      onGameWon(); // Call onGameWon() for both modes / Appeler onGameWon() pour les deux modes
      return; // Important: exit here to avoid other processing / Important: sortir ici pour éviter d'autres traitements
    }

    if (isSandbox) {
      // --- Sandbox Logic / Logique Sandbox ---
      if (score > 0 && score % 5 == 0) {
        difficulty++;
        print("Difficulty increased to level $difficulty!");
      }
    }
  }

  void reset() {
    score = 0;
    difficulty = 1;
    isGameFinished = false;
  }
}