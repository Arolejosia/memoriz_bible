class DicteeTranslations {
  static String t(String key, String lang, {Map<String, String>? params}) {
    final Map<String, Map<String, String>> translations = {
      // Titres et labels
      'dictee': {'fr': 'Dictée', 'en': 'Dictation'},
      'attempt': {'fr': 'Essai', 'en': 'Attempt'},
      'preparing_dictation': {'fr': 'Préparation de la dictée...', 'en': 'Preparing dictation...'},

      // Actions audio
      'listen_verse': {'fr': 'Écouter le verset', 'en': 'Listen to verse'},
      'speaking': {'fr': 'Lecture en cours...', 'en': 'Speaking...'},

      // Champ de texte
      'write_here': {'fr': 'Écrivez ici...', 'en': 'Write here...'},
      'click_listen_to_start': {
        'fr': 'Cliquez sur "Écouter" pour commencer',
        'en': 'Click "Listen" to start'
      },

      // Boutons
      'verify': {'fr': 'Vérifier', 'en': 'Verify'},
      'verifying': {'fr': 'Vérification...', 'en': 'Verifying...'},
      'retry': {'fr': 'Réessayer', 'en': 'Retry'},
      'continue': {'fr': 'Continuer', 'en': 'Continue'},

      // Résultats
      'excellent': {'fr': 'Excellent !', 'en': 'Excellent!'},
      'game_over': {'fr': 'Partie Terminée', 'en': 'Game Over'},
      'almost': {'fr': 'Presque !', 'en': 'Almost!'},

      // Messages de succès/échec
      'success_message': {
        'fr': 'Félicitations ! Vous avez correctement écrit le verset.',
        'en': 'Congratulations! You correctly wrote the verse.',
      },
      'no_attempts_left': {
        'fr': 'Vous avez utilisé toutes vos tentatives.',
        'en': 'You have used all your attempts.',
      },
      'correct_answer_was': {
        'fr': 'La réponse correcte était :',
        'en': 'The correct answer was:',
      },

      // Progression
      'moving_to_next_game': {
        'fr': 'Passage au jeu suivant...',
        'en': 'Moving to next game...',
      },
      'step_not_completed': {
        'fr': 'Étape non complétée',
        'en': 'Step not completed',
      },

      // Erreurs
      'error': {'fr': 'Erreur', 'en': 'Error'},
      'verse_missing': {
        'fr': 'Aucun verset n\'a été fourni pour la dictée.',
        'en': 'No verse was provided for dictation.',
      },
      'room_code_missing': {
        'fr': 'Code de salle manquant pour le mode multijoueur.',
        'en': 'Room code missing for multiplayer mode.',
      },
      'back': {'fr': 'Retour', 'en': 'Back'},
    };

    String text = translations[key]?[lang] ?? key;
    if (params != null) {
      params.forEach((paramKey, value) {
        text = text.replaceAll('{$paramKey}', value);
      });
    }
    return text;
  }

  // Helper pour formater les tentatives
  static String formatAttempts(int current, int max, String lang) {
    return '$current/$max';
  }

  // Helper pour formater les tentatives restantes
  static String formatAttemptsRemaining(int remaining, String lang) {
    if (lang == 'fr') {
      return remaining == 1
          ? 'Il vous reste 1 tentative.'
          : 'Il vous reste $remaining tentatives.';
    } else {
      return remaining == 1
          ? 'You have 1 attempt remaining.'
          : 'You have $remaining attempts remaining.';
    }
  }

  // Helper pour formater le temps restant
  static String formatTimeRemaining(int seconds, String lang) {
    if (lang == 'fr') {
      return '$seconds secondes restantes';
    } else {
      return seconds == 1 ? '$seconds second remaining' : '$seconds seconds remaining';
    }
  }
}