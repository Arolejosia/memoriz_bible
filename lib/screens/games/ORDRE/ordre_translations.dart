// File: lib/l10n/ordre_translations.dart

class OrdreTranslations {
  static String t(String key, String lang, {Map<String, String>? params}) {
    final Map<String, Map<String, String>> translations = {
      // App Bar & Headers
      'word_order_game': {'fr': 'Remettre en Ordre', 'en': 'Put in Order'},
      'multiplayer_order': {'fr': 'Ordre Multijoueur', 'en': 'Multiplayer Order'},
      'score_label': {'fr': 'Score', 'en': 'Score'},

      // Game Status
      'initializing': {'fr': 'Initialisation...', 'en': 'Initializing...'},
      'connecting': {'fr': 'Connexion à la partie...', 'en': 'Connecting to game...'},
      'waiting_questions': {'fr': 'L\'hôte prépare les questions...', 'en': 'Host is preparing questions...'},
      'waiting_start': {'fr': 'En attente du démarrage...', 'en': 'Waiting to start...'},
      'preparing_question': {'fr': 'Préparation de la question...', 'en': 'Preparing question...'},
      'waiting': {'fr': 'En attente...', 'en': 'Waiting...'},
      'loading_game': {'fr': 'Préparation du jeu...', 'en': 'Preparing game...'},

      // Question Interface
      'put_words_in_order': {'fr': 'Remettez les mots dans le bon ordre :', 'en': 'Put the words in the correct order:'},
      'word_bank': {'fr': 'Banque de mots', 'en': 'Word bank'},
      'drag_words_here': {'fr': 'Glissez les mots ici', 'en': 'Drag words here'},

      // Actions
      'verify': {'fr': 'Vérifier', 'en': 'Verify'},
      'continue': {'fr': 'Continuer', 'en': 'Continue'},
      'retry': {'fr': 'Réessayer', 'en': 'Retry'},
      'restart': {'fr': 'Recommencer', 'en': 'Restart'},
      'perfect': {'fr': 'Parfait !', 'en': 'Perfect!'},

      'a_player': {'fr': 'Un Joueur', 'en': 'A Player'},

      // Feedback Messages
      'correct_order_found': {'fr': 'Bon ordre trouvé !', 'en': 'Correct order found!'},
      'well_done': {'fr': 'Bien joué !', 'en': 'Well done!'},
      'round_finished': {'fr': 'Manche terminée !', 'en': 'Round finished!'},
      'you_found_order': {'fr': 'Vous avez trouvé le bon ordre !', 'en': 'You found the correct order!'},
      'player_found_order': {'fr': '{player} a trouvé le bon ordre !', 'en': '{player} found the correct order!'},
      'time_expired_revealed': {'fr': 'Temps écoulé ! Le bon ordre était révélé.', 'en': 'Time expired! The correct order was revealed.'},
      'all_verses_ordered': {'fr': 'Vous avez remis tous les versets dans l\'ordre !', 'en': 'You put all verses in order!'},
      'waiting_other_players': {'fr': 'En attente des autres joueurs...', 'en': 'Waiting for other players...'},

      // Congratulations Dialog
      'congratulations': {'fr': 'Félicitations !', 'en': 'Congratulations!'},
      'goal_reached': {'fr': 'Vous avez atteint l\'objectif !', 'en': 'You reached the goal!'},

      // Bottom Section Labels
      'score': {'fr': 'Score', 'en': 'Score'},
      'time': {'fr': 'Temps', 'en': 'Time'},
      'status': {'fr': 'Statut', 'en': 'Status'},
      'answered': {'fr': 'Répondu', 'en': 'Answered'},
      'in_progress': {'fr': 'En cours', 'en': 'In progress'},

      // Timer
      'seconds': {'fr': 's', 'en': 's'},

      // Errors
      'loading_error': {'fr': 'Erreur lors du chargement', 'en': 'Loading error'},
      'no_verses_found': {'fr': 'Aucun verset trouvé pour ce jeu.', 'en': 'No verses found for this game.'},
      'invalid_data_structure': {'fr': 'Erreur: Structure de données invalide pour les versets.', 'en': 'Error: Invalid data structure for verses.'},
      'connection_error': {'fr': 'Erreur de connexion', 'en': 'Connection error'},

      // Room info
      'room_code': {'fr': 'Code salle', 'en': 'Room code'},
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

// Helper function pour détecter la langue depuis une référence
String detectLanguageFromReference(String reference) {
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
