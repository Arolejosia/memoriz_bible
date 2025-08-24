// Fichier : lib/game_session.dart

import 'package:flutter/foundation.dart';

class GameSession {
  // --- Propriétés ---
  final bool isSandbox;
  final int scoreToWin;
  final VoidCallback onGameWon; // Fonction à appeler quand la partie est gagnée en mode progression

  int score = 0;
  int difficulty = 1;

  // --- Constructeur ---
  GameSession({
    required this.isSandbox,
    required this.scoreToWin,
    required this.onGameWon,
  });

  bool isGameFinished = false;
  /// C'est la fonction principale. Elle gère ce qui se passe après une réponse.
  void submitAnswer({required bool isCorrect}) {
    if (isGameFinished) return;
    if (!isCorrect) {
      return;
    }

    score++;

    if (isSandbox) {
      // --- Sandbox Logic ---
      if (score > 0 && score % 5 == 0) {
        difficulty++;
        print("Difficulty increased to level $difficulty!");
      }
    } else {
      // ✅ CORRECTED: --- Progression Logic ---
      if (score >= scoreToWin) {
        isGameFinished = true;
        onGameWon();
      }
    }
  }
}