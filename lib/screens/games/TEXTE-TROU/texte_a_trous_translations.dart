// File: lib/l10n/texte_a_trous_translations.dart

class TexteATrousTranslations {
  static String t(String key, String lang, {Map<String, String>? params}) {
    final Map<String, Map<String, String>> translations = {
      // App Bar & Headers
      'fill_blanks_game': {'fr': 'Texte à trous', 'en': 'Fill in the Blanks'},
      'multiplayer_game': {'fr': 'Multijoueur', 'en': 'Multiplayer'},
      'score_label': {'fr': 'Score', 'en': 'Score'},
      'level': {'fr': 'Niveau', 'en': 'Level'},

      // Game Status
      'initializing': {'fr': 'Initialisation...', 'en': 'Initializing...'},
      'connecting': {'fr': 'Connexion à la partie...', 'en': 'Connecting to game...'},
      'waiting_questions': {'fr': 'L\'hôte prépare les questions...', 'en': 'Host is preparing questions...'},
      'waiting_start': {'fr': 'En attente du démarrage...', 'en': 'Waiting to start...'},
      'preparing_question': {'fr': 'Préparation de la question...', 'en': 'Preparing question...'},
      'waiting': {'fr': 'En attente...', 'en': 'Waiting...'},
      'loading_question': {'fr': 'Chargement de la question...', 'en': 'Loading question...'},

      // Levels
      'beginner': {'fr': 'débutant', 'en': 'beginner'},
      'intermediate': {'fr': 'intermédiaire', 'en': 'intermediate'},
      'expert': {'fr': 'expert', 'en': 'expert'},

      // Actions
      'verify': {'fr': 'Vérifier', 'en': 'Verify'},
      'continue': {'fr': 'Continuer', 'en': 'Continue'},
      'restart': {'fr': 'Recommencer', 'en': 'Restart'},
      'finish': {'fr': 'Terminer', 'en': 'Finish'},

      // Feedback Messages
      'well_done': {'fr': '✅ Bien joué !', 'en': '✅ Well done!'},
      'not_quite_right': {'fr': '❌ Ce n\'est pas tout à fait ça...', 'en': '❌ Not quite right...'},
      'all_correct': {'fr': 'Toutes vos réponses sont correctes !', 'en': 'All your answers are correct!'},
      'some_incorrect': {'fr': 'Certaines réponses sont incorrectes', 'en': 'Some answers are incorrect'},
      'score_obtained': {'fr': 'Score obtenu: +{points} points', 'en': 'Score obtained: +{points} points'},
      'all_answers_found': {'fr': 'Toutes les réponses trouvées !', 'en': 'All answers found!'},
      'time_expired': {'fr': 'Temps écoulé', 'en': 'Time expired'},
      'checking': {'fr': 'Vérification...', 'en': 'Checking...'},
      'enter_answers': {'fr': 'Entrez vos réponses', 'en': 'Enter your answers'},
      'verify_answers': {'fr': 'Vérifier mes réponses', 'en': 'Verify my answers'},

      // Congratulations Dialog (Sandbox)
      'congratulations': {'fr': '🎉 Bravo !', 'en': '🎉 Congratulations!'},
      'goal_reached': {'fr': 'Vous avez atteint l\'objectif !', 'en': 'You reached the goal!'},
      'ok': {'fr': 'OK', 'en': 'OK'},

      // Bottom Section Labels
      'score': {'fr': 'Score', 'en': 'Score'},
      'status': {'fr': 'Statut', 'en': 'Status'},
      'answered': {'fr': 'Répondu', 'en': 'Answered'},
      'in_progress': {'fr': 'En cours', 'en': 'In progress'},
      'answers': {'fr': 'Réponses', 'en': 'Answers'},
      'ranking': {'fr': 'Classement', 'en': 'Ranking'},
      'unknown_player': {'fr': 'Joueur inconnu', 'en': 'Unknown player'},
      'you': {'fr': 'Vous', 'en': 'You'},
      'points': {'fr': 'pts', 'en': 'pts'},

      // Timer
      'seconds': {'fr': 's', 'en': 's'},

      // Errors
      'loading_error': {'fr': 'Erreur lors du chargement', 'en': 'Loading error'},
      'verification_error': {'fr': 'Erreur lors de la vérification', 'en': 'Verification error'},
      'connection_error': {'fr': 'Erreur de connexion', 'en': 'Connection error'},

      // Room info
      'room_code': {'fr': 'Code salle', 'en': 'Room code'},

      // Game modes
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