// File: lib/l10n/qcm_translations.dart

class QcmTranslations {
  static String t(String key, String lang, {Map<String, String>? params}) {
    final Map<String, Map<String, String>> translations = {
      // App Bar & Headers
      'qcm_game': {'fr': 'Jeu QCM', 'en': 'Quiz Game'},
      'quiz_game': {'fr': 'Jeu QCM', 'en': 'Quiz Game'},
      'multiplayer_game': {'fr': 'Jeu Multijoueur', 'en': 'Multiplayer Game'},
      'score_label': {'fr': 'Score', 'en': 'Score'},

      // Game Status
      'initializing': {'fr': 'Initialisation...', 'en': 'Initializing...'},
      'connecting': {'fr': 'Connexion à la partie...', 'en': 'Connecting to game...'},
      'waiting_questions': {'fr': 'L\'hôte prépare les questions...', 'en': 'Host is preparing questions...'},
      'waiting_start': {'fr': 'En attente du démarrage...', 'en': 'Waiting to start...'},
      'preparing_question': {'fr': 'Préparation de la question...', 'en': 'Preparing question...'},
      'waiting': {'fr': 'En attente...', 'en': 'Waiting...'},
      'loading_question': {'fr': 'Chargement de la question...', 'en': 'Loading question...'},

      // Question Interface
      'complete_verse': {'fr': 'Complétez le verset :', 'en': 'Complete the verse:'},
      'next_question': {'fr': 'Question suivante', 'en': 'Next question'},

      // Feedback Messages
      'correct_answer': {'fr': '🎉 Bonne réponse ! 🎉', 'en': '🎉 Correct answer! 🎉'},
      'well_done': {'fr': 'Bien joué !', 'en': 'Well done!'},
      'round_finished': {'fr': 'Manche terminée !', 'en': 'Round finished!'},
      'you_found_answer': {'fr': 'Vous avez trouvé la bonne réponse !', 'en': 'You found the correct answer!'},
      'player_found_answer': {'fr': '{player} a trouvé la bonne réponse !', 'en': '{player} found the correct answer!'},
      'time_expired': {'fr': 'Temps écoulé ! La bonne réponse était révélée.', 'en': 'Time expired! The correct answer was revealed.'},

      // Congratulations Dialog (Sandbox)
      'congratulations': {'fr': 'Félicitations !', 'en': 'Congratulations!'},
      'goal_reached': {'fr': 'Vous avez atteint l\'objectif !', 'en': 'You reached the goal!'},
      'goal_reached_points': {'fr': 'Vous avez atteint l\'objectif de {points} points !', 'en': 'You reached the goal of {points} points!'},
      'ok': {'fr': 'OK', 'en': 'OK'},

      // Bottom Section Labels
      'score': {'fr': 'Score', 'en': 'Score'},
      'time': {'fr': 'Temps', 'en': 'Time'},
      'status': {'fr': 'Statut', 'en': 'Status'},
      'answered': {'fr': 'Répondu', 'en': 'Answered'},

      // Timer
      'seconds': {'fr': 's', 'en': 's'},

      // Errors
      'loading_error': {'fr': 'Erreur lors du chargement', 'en': 'Loading error'},
      'connection_error': {'fr': 'Erreur de connexion', 'en': 'Connection error'},

      // Room info
      'room_code': {'fr': 'Code salle', 'en': 'Room code'},

      // Game modes (for progression/sandbox)
      'solo_game': {'fr': 'Jeu Solo', 'en': 'Solo Game'},
      'practice_mode': {'fr': 'Mode Entraînement', 'en': 'Practice Mode'},
      'progression_mode': {'fr': 'Mode Progression', 'en': 'Progression Mode'},
    };

    String text = translations[key]?[lang] ?? key;
    if (params != null) {
      params.forEach((paramKey, value) {
        text = text.replaceAll('{$paramKey}', value);
      });
    }
    return text;
  }
}

// ==============================================================================
// TRADUCTIONS POUR LES RÉSULTATS DE JEU (MULTIJOUEUR)
// ==============================================================================
class GameResultsTranslations {
  static String t(String key, String lang, {Map<String, String>? params}) {
    final Map<String, Map<String, String>> translations = {
      // Page Title
      'game_results': {'fr': 'Résultats de la Partie', 'en': 'Game Results'},
      'final_results': {'fr': 'Résultats Finaux', 'en': 'Final Results'},

      // Winner Section
      'winner': {'fr': '🏆 Gagnant', 'en': '🏆 Winner'},
      'congratulations': {'fr': 'Félicitations !', 'en': 'Congratulations!'},
      'victory': {'fr': 'Victoire !', 'en': 'Victory!'},

      // Rankings
      'final_ranking': {'fr': 'Classement Final', 'en': 'Final Ranking'},
      'your_rank': {'fr': 'Votre Classement', 'en': 'Your Rank'},
      'points': {'fr': 'points', 'en': 'points'},
      'position': {'fr': '{position}ème place', 'en': '{position}{suffix} place'},

      // Stats
      'total_questions': {'fr': 'Questions Totales', 'en': 'Total Questions'},
      'correct_answers': {'fr': 'Réponses Correctes', 'en': 'Correct Answers'},
      'accuracy': {'fr': 'Précision', 'en': 'Accuracy'},
      'average_time': {'fr': 'Temps Moyen', 'en': 'Average Time'},

      // Questions Review
      'questions_review': {'fr': 'Révision des Questions', 'en': 'Questions Review'},
      'question_number': {'fr': 'Question {number}', 'en': 'Question {number}'},
      'correct_answer': {'fr': 'Réponse Correcte', 'en': 'Correct Answer'},
      'your_answer': {'fr': 'Votre Réponse', 'en': 'Your Answer'},

      // Buttons
      'back_to_lobby': {'fr': 'Retour au Lobby', 'en': 'Back to Lobby'},
      'play_again': {'fr': 'Rejouer', 'en': 'Play Again'},
      'share_results': {'fr': 'Partager les Résultats', 'en': 'Share Results'},
      'close': {'fr': 'Fermer', 'en': 'Close'},
      'home': {'fr': 'Accueil', 'en': 'Home'},

      // End reasons
      'game_completed': {'fr': 'Partie Terminée', 'en': 'Game Completed'},
      'time_expired': {'fr': 'Temps Écoulé', 'en': 'Time Expired'},
      'all_answered': {'fr': 'Toutes les Questions Répondues', 'en': 'All Questions Answered'},
    };

    String text = translations[key]?[lang] ?? key;
    if (params != null) {
      params.forEach((paramKey, value) {
        text = text.replaceAll('{$paramKey}', value);
      });
    }
    return text;
  }

  // Helper pour les suffixes ordinaux en anglais
  static String getOrdinalSuffix(int position, String lang) {
    if (lang == 'fr') return 'ème';

    // Anglais
    if (position % 100 >= 11 && position % 100 <= 13) return 'th';
    switch (position % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }
}