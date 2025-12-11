// File: lib/l10n/recitation_translations.dart

/// Système de traduction pour le jeu de Récitation
/// Utilisation: RecitationTranslations.t('key', lang, params: {'player': 'John'})
class RecitationTranslations {
  static String t(String key, String lang, {Map<String, String>? params}) {
    final Map<String, Map<String, String>> translations = {
      // =========================================================================
      // HEADERS & NAVIGATION
      // =========================================================================
      'recitation': {'fr': 'Récitation', 'en': 'Recitation'},
      'recitation_game': {'fr': 'Jeu de Récitation', 'en': 'Recitation Game'},
      'multiplayer_game': {'fr': 'Multijoueur - {code}', 'en': 'Multiplayer - {code}'},
      'back': {'fr': 'Retour', 'en': 'Back'},
      'close': {'fr': 'Fermer', 'en': 'Close'},
      'finish': {'fr': 'Terminer', 'en': 'Finish'},

      // =========================================================================
      // GAME STATUS & LOADING
      // =========================================================================
      'loading': {'fr': 'Chargement...', 'en': 'Loading...'},
      'initializing': {'fr': 'Initialisation...', 'en': 'Initializing...'},
      'preparing_recitation': {'fr': 'Préparation de la récitation...', 'en': 'Preparing recitation...'},
      'waiting': {'fr': 'En attente...', 'en': 'Waiting...'},
      'analyzing': {'fr': 'Analyse de votre récitation...', 'en': 'Analyzing your recitation...'},
      'ai_analyzing': {'fr': 'IA en cours d\'analyse...', 'en': 'AI analyzing...'},

      // =========================================================================
      // GAME MODE
      // =========================================================================
      'training_mode': {'fr': 'Mode Entraînement', 'en': 'Training Mode'},
      'progression_mode': {'fr': 'Mode Progression', 'en': 'Progression Mode'},
      'sandbox_mode': {'fr': 'Mode Entraînement', 'en': 'Training Mode'},
      'question_progress': {'fr': 'Question {current}/{total}', 'en': 'Question {current}/{total}'},

      // =========================================================================
      // ATTEMPTS & SCORE
      // =========================================================================
      'attempts_remaining': {'fr': 'Essais restants', 'en': 'Attempts remaining'},
      'attempts_count': {'fr': '{remaining}/{max}', 'en': '{remaining}/{max}'},
      'last_attempt': {'fr': 'Dernier essai !', 'en': 'Last attempt!'},
      'attempts_label': {'fr': 'Tentatives', 'en': 'Attempts'},
      'score': {'fr': 'Score', 'en': 'Score'},
      'points': {'fr': 'pts', 'en': 'pts'},
      'accuracy_required': {'fr': 'Précision requise', 'en': 'Accuracy required'},
      'accuracy_70': {'fr': '70%', 'en': '70%'},

      // =========================================================================
      // TIME
      // =========================================================================
      'time': {'fr': 'Temps', 'en': 'Time'},
      'time_left': {'fr': 'Temps restant', 'en': 'Time left'},
      'seconds': {'fr': 's', 'en': 's'},
      'timer': {'fr': 'Chronomètre', 'en': 'Timer'},

      // =========================================================================
      // MICROPHONE & RECORDING
      // =========================================================================
      'press_to_start': {'fr': 'Appuyez sur le micro pour commencer à réciter.', 'en': 'Press the microphone to start reciting.'},
      'press_to_speak': {'fr': 'Appuyez pour commencer à parler', 'en': 'Press to start speaking'},
      'press_to_stop': {'fr': 'Appuyez pour arrêter l\'enregistrement', 'en': 'Press to stop recording'},
      'waiting_status': {'fr': 'En attente...', 'en': 'Waiting...'},
      'recording': {'fr': 'Enregistrement en cours...', 'en': 'Recording...'},
      'listening': {'fr': 'Écoute en cours...', 'en': 'Listening...'},

      // =========================================================================
      // FEEDBACK MESSAGES
      // =========================================================================
      'correct_answer': {'fr': 'Bonne réponse !', 'en': 'Correct answer!'},
      'wrong_answer': {'fr': 'Mauvaise réponse, réessayez !', 'en': 'Wrong answer, try again!'},
      'you_found_answer': {'fr': 'Vous avez trouvé la bonne réponse !', 'en': 'You found the correct answer!'},
      'player_found_answer': {'fr': '{player} a trouvé la bonne réponse !', 'en': '{player} found the correct answer!'},
      'remaining_attempts': {'fr': 'Il vous reste {count} essai{s}', 'en': 'You have {count} attempt{s} left'},
      'do_your_best': {'fr': 'Donnez le meilleur de vous-même', 'en': 'Do your best'},

      // =========================================================================
      // ENCOURAGEMENT MESSAGES (Based on score)
      // =========================================================================
      'excellent_progress': {'fr': 'Excellent ! Vous y êtes presque !', 'en': 'Excellent! You\'re almost there!'},
      'very_good': {'fr': 'Très bien ! Continuez comme ça !', 'en': 'Very good! Keep it up!'},
      'good_work': {'fr': 'Bon travail ! Vous progressez !', 'en': 'Good work! You\'re improving!'},
      'good_start': {'fr': 'C\'est un bon début ! Persévérez !', 'en': 'Good start! Keep going!'},
      'dont_give_up': {'fr': 'Ne vous découragez pas ! Réessayez calmement.', 'en': 'Don\'t give up! Try again calmly.'},

      // =========================================================================
      // SCORE LABELS
      // =========================================================================
      'excellent': {'fr': 'Excellent', 'en': 'Excellent'},
      'passed': {'fr': 'Réussi', 'en': 'Passed'},
      'good': {'fr': 'Bien', 'en': 'Good'},
      'average': {'fr': 'Moyen', 'en': 'Average'},
      'to_improve': {'fr': 'À améliorer', 'en': 'To improve'},

      // =========================================================================
      // SUCCESS DIALOG
      // =========================================================================
      'perfect': {'fr': 'Parfait !', 'en': 'Perfect!'},
      'well_done': {'fr': 'Bien joué !', 'en': 'Well done!'},
      'congratulations': {'fr': 'Félicitations !', 'en': 'Congratulations!'},
      'excellent_recitation': {'fr': 'Votre récitation est excellente.\nContinuez comme ça !', 'en': 'Your recitation is excellent.\nKeep it up!'},
      'victory': {'fr': 'Victoire !', 'en': 'Victory!'},

      // =========================================================================
      // FAILURE DIALOG
      // =========================================================================
      'no_problem': {'fr': 'Pas de souci !', 'en': 'No problem!'},
      'practice_makes_perfect': {'fr': 'La pratique rend parfait.\nVoulez-vous réessayer ?', 'en': 'Practice makes perfect.\nWould you like to try again?'},
      'try_again_question': {'fr': 'Voulez-vous voir le texte correct et réessayer ?', 'en': 'Would you like to see the correct text and try again?'},
      'retry': {'fr': 'Réessayer', 'en': 'Retry'},
      'continue': {'fr': 'Continuer', 'en': 'Continue'},
      'game_over': {'fr': 'Partie Terminée', 'en': 'Game Over'},

      // =========================================================================
      // HINTS & TIPS
      // =========================================================================
      'hint': {'fr': 'Conseil', 'en': 'Hint'},
      'tip': {'fr': 'Astuce', 'en': 'Tip'},
      'speak_clearly': {'fr': 'Parlez clairement et distinctement pour améliorer la reconnaissance vocale.', 'en': 'Speak clearly and distinctly to improve voice recognition.'},
      'speak_slowly': {'fr': 'Parlez clairement et distinctement. Prenez votre temps.', 'en': 'Speak clearly and distinctly. Take your time.'},
      'check_text': {'fr': 'Essayez de vous rapprocher du texte original. Relisez la référence.', 'en': 'Try to get closer to the original text. Reread the reference.'},
      'check_word_order': {'fr': 'Vous êtes sur la bonne voie ! Vérifiez l\'ordre des mots.', 'en': 'You\'re on the right track! Check the word order.'},
      'attention_details': {'fr': 'Presque parfait ! Attention aux petits détails.', 'en': 'Almost perfect! Watch the small details.'},
      'excellent_work': {'fr': 'Excellent travail ! Continuez comme ça !', 'en': 'Excellent work! Keep it up!'},

      // =========================================================================
      // MULTIPLAYER SPECIFIC
      // =========================================================================
      'status': {'fr': 'Statut', 'en': 'Status'},
      'submitted': {'fr': 'Soumis', 'en': 'Submitted'},
      'in_progress': {'fr': 'En cours', 'en': 'In progress'},
      'live_ranking': {'fr': 'Classement en direct', 'en': 'Live ranking'},
      'you': {'fr': '(Vous)', 'en': '(You)'},
      'unknown_player': {'fr': 'Joueur inconnu', 'en': 'Unknown player'},
      'position_1st': {'fr': '1er', 'en': '1st'},
      'position_2nd': {'fr': '2ème', 'en': '2nd'},
      'position_3rd': {'fr': '3ème', 'en': '3rd'},
      'position_nth': {'fr': '{n}ème', 'en': '{n}th'},

      // =========================================================================
      // COMPARISON & ANALYSIS
      // =========================================================================
      'comparison': {'fr': 'Comparaison', 'en': 'Comparison'},
      'expected_text': {'fr': 'Texte attendu:', 'en': 'Expected text:'},
      'your_recitation': {'fr': 'Votre récitation:', 'en': 'Your recitation:'},
      'no_text_detected': {'fr': 'Aucun texte détecté', 'en': 'No text detected'},
      'similarity': {'fr': 'Similitude', 'en': 'Similarity'},
      'analysis': {'fr': 'Analyse', 'en': 'Analysis'},

      // =========================================================================
      // PROGRESS INFO
      // =========================================================================
      'progress': {'fr': 'Progression', 'en': 'Progress'},
      'your_progress': {'fr': 'Votre progression', 'en': 'Your progress'},
      'attempts_used': {'fr': 'Tentatives utilisées', 'en': 'Attempts used'},
      'remaining': {'fr': 'Restant', 'en': 'Remaining'},

      // =========================================================================
      // REFERENCE & VERSE INFO
      // =========================================================================
      'reference': {'fr': 'Référence', 'en': 'Reference'},
      'verse_reference': {'fr': 'Référence du verset', 'en': 'Verse reference'},
      'biblical_reference': {'fr': 'Référence biblique', 'en': 'Biblical reference'},

      // 🆕 =========================================================================
      // 🆕 REFERENCE VERIFICATION (NEW)
      // 🆕 =========================================================================
      'one_last_step': {'fr': 'Une dernière étape !', 'en': 'One last step!'},
      'final_challenge': {'fr': 'Défi final', 'en': 'Final challenge'},
      'enter_verse_reference': {
        'fr': 'Entrez la référence du verset que vous venez de réciter :',
        'en': 'Enter the reference of the verse you just recited:'
      },
      'placeholder_reference': {'fr': 'Ex: Jean 3:16', 'en': 'Ex: John 3:16'},
      'tries_left': {'fr': 'essais restants', 'en': 'tries left'},
      'correct': {'fr': '✅ Parfait !', 'en': '✅ Perfect!'},
      'incorrect': {'fr': '❌ Incorrect', 'en': '❌ Incorrect'},
      'correct_reference_is': {'fr': 'La référence correcte est :', 'en': 'The correct reference is:'},
      'validate': {'fr': 'Valider', 'en': 'Validate'},
      'reference_correct_message': {
        'fr': 'Félicitations ! Vous maîtrisez ce verset !',
        'en': 'Congratulations! You master this verse!'
      },
      'reference_incorrect_try_again': {
        'fr': 'Réessayez. Vérifiez l\'orthographe et le format.',
        'en': 'Try again. Check spelling and format.'
      },

      // =========================================================================
      // ERRORS
      // =========================================================================
      'error': {'fr': 'Erreur', 'en': 'Error'},
      'initialization_error': {'fr': 'Erreur lors de l\'initialisation', 'en': 'Initialization error'},
      'recording_error': {'fr': 'Erreur d\'enregistrement', 'en': 'Recording error'},
      'verification_error': {'fr': 'Erreur de vérification', 'en': 'Verification error'},
      'connection_error': {'fr': 'Erreur de connexion', 'en': 'Connection error'},

      // =========================================================================
      // ACTIONS
      // =========================================================================
      'start': {'fr': 'Démarrer', 'en': 'Start'},
      'stop': {'fr': 'Arrêter', 'en': 'Stop'},
      'submit': {'fr': 'Valider', 'en': 'Submit'},
      'verify': {'fr': 'Vérifier', 'en': 'Verify'},
      'next': {'fr': 'Suivant', 'en': 'Next'},
      'previous': {'fr': 'Précédent', 'en': 'Previous'},
      'skip': {'fr': 'Passer', 'en': 'Skip'},
      'ok': {'fr': 'OK', 'en': 'OK'},
      'cancel': {'fr': 'Annuler', 'en': 'Cancel'},
      'yes': {'fr': 'Oui', 'en': 'Yes'},
      'no': {'fr': 'Non', 'en': 'No'},
    };

    String text = translations[key]?[lang] ?? key;

    // Remplacer les paramètres
    if (params != null) {
      params.forEach((paramKey, value) {
        text = text.replaceAll('{$paramKey}', value);
      });
    }

    return text;
  }

  // =========================================================================
  // HELPER METHODS (Unchanged)
  // =========================================================================

  /// Renvoie un message d'encouragement basé sur le score
  static String getEncouragementMessage(double score, String lang) {
    if (score >= 90.0) return t('excellent_progress', lang);
    if (score >= 70.0) return t('very_good', lang);
    if (score >= 50.0) return t('good_work', lang);
    if (score >= 30.0) return t('good_start', lang);
    return t('dont_give_up', lang);
  }

  /// Renvoie un conseil basé sur le score et la tentative
  static String getHintMessage(double score, bool hasPreviousAttempt, String lang) {
    if (!hasPreviousAttempt) {
      return t('speak_slowly', lang);
    }
    if (score >= 80.0) return t('attention_details', lang);
    if (score >= 60.0) return t('check_word_order', lang);
    if (score >= 40.0) return t('check_text', lang);
    return t('speak_clearly', lang);
  }

  /// Formatte le nombre d'essais restants avec pluriel approprié
  static String formatAttemptsRemaining(int remaining, String lang) {
    if (remaining == 0) {
      return lang == 'fr' ? 'Plus d\'essais' : 'No attempts left';
    }
    if (remaining == 1) {
      return lang == 'fr' ? '1 essai restant' : '1 attempt left';
    }
    return lang == 'fr' ? '$remaining essais restants' : '$remaining attempts left';
  }

  /// Retourne un label de score approprié
  static String getScoreLabel(double score, String lang) {
    if (score >= 90.0) return t('excellent', lang);
    if (score >= 70.0) return t('passed', lang);
    if (score >= 50.0) return t('good', lang);
    if (score >= 30.0) return t('average', lang);
    return t('to_improve', lang);
  }
}