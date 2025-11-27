// Fichier: lib/translations/multiplayer_translations.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Assurez-vous que ce chemin est correct pour votre projet
import '../../models/language_provider.dart';


class MPTranslations {
  static const Map<String, Map<String, String>> _translations = {
    // === Common / Errors ===
    'please_connect': {
      'fr': 'Veuillez vous connecter.',
      'en': 'Please log in.',
    },

    'verset_par_defaut':{
      'fr': 'Jean 3:16',
      'en': 'John 3:16',

    },
    'cancel': {
      'fr': 'Annuler',
      'en': 'Cancel',
    },
    'confirm': {
      'fr': 'Confirmer',
      'en': 'Confirm',
    },
    'error': {
      'fr': 'Erreur',
      'en': 'Error',
    },
    'unknown_player': {
      'fr': 'Joueur inconnu',
      'en': 'Unknown player',
    },
    'unknown': {
      'fr': 'Inconnu',
      'en': 'Unknown',
    },
    'difficulty': {
      'fr': 'Difficulté',
      'en': 'Difficulty',
    },
    'difficulty_easy': {
      'fr': 'Facile',
      'en': 'Easy',
    },
    'difficulty_medium': {
      'fr': 'Moyen',
      'en': 'Medium',
    },
    'difficulty_hard': {
      'fr': 'Difficile',
      'en': 'Hard',
    },
    'game_type': {
      'fr': 'Type de jeu',
      'en': 'Game type',
    },
    'reference': {
      'fr': 'Référence',
      'en': 'Reference',
    },
    'questions': {
      'fr': 'Questions',
      'en': 'Questions',
    },
    'pts': {
      'fr': 'pts',
      'en': 'pts',
    },

    // === Hub Page (multiplayer_hub_page.dart) ===
    'hub_title': {
      'fr': 'Duel',
      'en': 'Duel',
    },
    'my_questions': {
      'fr': 'Mes questions',
      'en': 'My questions',
    },
    'my_rooms': {
      'fr': 'Mes Salles',
      'en': 'My Rooms',
    },
    'create_party': {
      'fr': 'Créer une nouvelle partie',
      'en': 'Create a new game',
    },
    'game_type_qcm': {
      'fr': 'QCM',
      'en': 'MCQ',
    },
    'game_type_texteATrous': {
      'fr': 'Texte à Trous',
      'en': 'Fill in the Blanks',
    },
    'game_type_remettreEnOrdre': {
      'fr': 'Remettre en Ordre',
      'en': 'Put in Order',
    },
    'game_type_dictee': {
      'fr': 'Dictée',
      'en': 'Dictation',
    },
    'game_type_recitation': {
      'fr': 'Récitation',
      'en': 'Recitation',
    },
    'game_type_questionsPersonnalisees': {
      'fr': 'Questions Personnalisées',
      'en': 'Custom Questions',
    },
    'custom_questions': {
      'fr': 'Questions personnalisées',
      'en': 'Custom questions',
    },
    'choose_a_list': {
      'fr': 'Choisir une liste',
      'en': 'Choose a list',
    },
    'list_selected': {
      'fr': 'Liste sélectionnée',
      'en': 'List selected',
    },
    'list_ready': {
      'fr': 'Liste prête pour le jeu',
      'en': 'List ready for the game',
    },
    'change': {
      'fr': 'Changer',
      'en': 'Change',
    },
    'biblical_reference': {
      'fr': 'Référence biblique',
      'en': 'Biblical reference',
    },
    'choose_a_reference': {
      'fr': 'Choisir une référence',
      'en': 'Choose a reference',
    },
    'number_of_questions': {
      'fr': 'Nombre de questions',
      'en': 'Number of questions',
    },
    'scheduled_time_optional': {
      'fr': 'Heure prévue (optionnel)',
      'en': 'Scheduled time (optional)',
    },
    'choose_date_time': {
      'fr': 'Choisir une date & heure',
      'en': 'Choose a date & time',
    },
    'creating': {
      'fr': 'Création...',
      'en': 'Creating...',
    },
    'create_game': {
      'fr': 'Créer la partie',
      'en': 'Create game',
    },
    'join_party': {
      'fr': 'Rejoindre une partie',
      'en': 'Join a game',
    },
    'room_code': {
      'fr': 'Code de la salle',
      'en': 'Room code',
    },
    'enter_6_char_code': {
      'fr': 'Entrez le code à 6 caractères',
      'en': 'Enter the 6-character code',
    },
    'joining': {
      'fr': 'Connexion...',
      'en': 'Joining...',
    },
    'join': {
      'fr': 'Rejoindre',
      'en': 'Join',
    },
    'choose_nickname_title': {
      'fr': 'Choisissez votre pseudo',
      'en': 'Choose your nickname',
    },
    'enter_nickname_hint': {
      'fr': 'Entrez un nom pour cette partie',
      'en': 'Enter a name for this game',
    },
    'nickname_required': {
      'fr': 'Veuillez entrer un pseudo',
      'en': 'Please enter a nickname',
    },
    'nickname_min_length': {
      'fr': 'Au moins 3 caractères',
      'en': 'At least 3 characters',
    },
    'custom_list_info_title': {
      'fr': 'Questions personnalisées',
      'en': 'Custom questions',
    },
    'custom_list_info_count': {
      'fr': 'Vous avez {count} liste{plural} prête{plural}',
      'en': 'You have {count} list{plural} ready',
    },
    'custom_list_info_steps_title': {
      'fr': 'Pour créer un jeu avec vos propres questions, suivez ces étapes :',
      'en': 'To create a game with your own questions, follow these steps:',
    },
    'custom_list_info_step1': {
      'fr': 'Créez vos questions personnalisées',
      'en': 'Create your custom questions',
    },
    'custom_list_info_step2': {
      'fr': 'Créez une liste pour organiser vos questions',
      'en': 'Create a list to organize your questions',
    },
    'custom_list_info_step3': {
      'fr': 'Ajoutez vos questions à la liste',
      'en': 'Add your questions to the list',
    },
    'what_to_do': {
      'fr': 'Que voulez-vous faire ?',
      'en': 'What would you like to do?',
    },
    'no_list_available': {
      'fr': 'Aucune liste disponible',
      'en': 'No list available',
    },
    'choose_existing_list': {
      'fr': 'Choisir une liste existante',
      'en': 'Choose an existing list',
    },
    'create_questions': {
      'fr': 'Créer des questions',
      'en': 'Create questions',
    },
    'create_list': {
      'fr': 'Créer une liste',
      'en': 'Create a list',
    },
    'questions_created_title': {
      'fr': 'Questions créées',
      'en': 'Questions created',
    },
    'questions_created_body': {
      'fr': 'Vos questions ont été créées. Voulez-vous maintenant créer une liste pour les organiser ?',
      'en': 'Your questions have been created. Do you want to create a list to organize them now?',
    },
    'later': {
      'fr': 'Plus tard',
      'en': 'Later',
    },
    'select_list_title': {
      'fr': 'Sélectionner une liste',
      'en': 'Select a list',
    },
    'question_count_singular': {
      'fr': 'question',
      'en': 'question',
    },
    'question_count_plural': {
      'fr': 'questions',
      'en': 'questions',
    },
    'error_no_list_available': {
      'fr': 'Aucune liste disponible. Créez-en une d\'abord.',
      'en': 'No list available. Create one first.',
    },
    'error_no_list_with_questions': {
      'fr': 'Aucune liste avec des questions. Ajoutez des questions à vos listes.',
      'en': 'No list with questions. Add questions to your lists.',
    },
    'error_missing_reference': {
      'fr': 'Veuillez entrer une référence biblique.',
      'en': 'Please enter a biblical reference.',
    },
    'error_missing_custom_list': {
      'fr': 'Veuillez sélectionner ou créer une liste de questions personnalisées.',
      'en': 'Please select or create a custom question list.',
    },
    'error_unique_code': {
      'fr': 'Impossible de générer un code unique. Réessayez.',
      'en': 'Could not generate a unique code. Please try again.',
    },
    'error_create_failed': {
      'fr': 'Erreur lors de la création: {error}',
      'en': 'Error creating game: {error}',
    },
    'error_missing_room_code': {
      'fr': 'Veuillez entrer un code de salle.',
      'en': 'Please enter a room code.',
    },
    'error_room_not_found': {
      'fr': 'Aucune salle trouvée avec ce code.',
      'en': 'No room found with this code.',
    },
    'error_room_full': {
      'fr': 'Cette salle est pleine ({count} joueurs max).',
      'en': 'This room is full ({count} players max).',
    },
    'error_game_started': {
      'fr': 'Cette partie a déjà commencé.',
      'en': 'This game has already started.',
    },
    'error_already_in_room': {
      'fr': 'Vous êtes déjà dans cette salle.',
      'en': 'You are already in this room.',
    },
    'error_join_failed': {
      'fr': 'Erreur: {error}',
      'en': 'Error: {error}',
    },

    // === My Rooms Page (dans multiplayer_hub_page.dart) ===
    'my_rooms_title': {
      'fr': 'Mes Salles',
      'en': 'My Rooms',
    },
    'no_rooms_yet': {
      'fr': 'Aucune salle pour le moment.',
      'en': 'No rooms yet.',
    },
    'room_status_waiting': {
      'fr': 'En attente',
      'en': 'Waiting',
    },
    'room_status_started': {
      'fr': 'En cours',
      'en': 'In progress',
    },
    'room_status_finished': {
      'fr': 'Terminé',
      'en': 'Finished',
    },
    'room_card_title': {
      'fr': 'Salle {roomCode}',
      'en': 'Room {roomCode}',
    },
    'room_card_subtitle': {
      'fr': 'Jeu: {gameType} • Réf: {reference} • Diff: {difficulty} • {status}',
      'en': 'Game: {gameType} • Ref: {reference} • Diff: {difficulty} • {status}',
    },
    'end_room_title': {
      'fr': 'Terminer la salle ?',
      'en': 'End the room?',
    },
    'end_room_body': {
      'fr': 'Cela arrêtera la partie pour tous les joueurs.',
      'en': 'This will stop the game for all players.',
    },
    'end': {
      'fr': 'Terminer',
      'en': 'End',
    },
    'game_label': {
      'fr': 'Jeu',
      'en': 'Game',
    },
    'ref_label': {
      'fr': 'Réf',
      'en': 'Ref',
    },
    'diff_label': {
      'fr': 'Diff',
      'en': 'Diff',
    },

    // === Waiting Room (waiting_room_page.dart) ===
    'room_title': {
      'fr': 'Salle {roomCode}',
      'en': 'Room {roomCode}',
    },
    'share_invite_message': {
      'fr': '🔥 Rejoins ma partie Memoriz Bible avec le code: {roomCode}',
      'en': '🔥 Join my Memoriz Bible game with code: {roomCode}',
    },
    'share_invite_subject': {
      'fr': 'Invitation à une partie Memoriz Bible',
      'en': 'Invitation to a Memoriz Bible game',
    },
    'room_not_exist': {
      'fr': 'Cette salle n\'existe plus.',
      'en': 'This room no longer exists.',
    },
    'error_min_2_players': {
      'fr': 'Il faut au moins 2 joueurs pour commencer',
      'en': 'At least 2 players are needed to start',
    },
    'scheduled_for': {
      'fr': 'Prévue le {day}/{month} à {hour}h{minute}',
      'en': 'Scheduled for {month}/{day} at {hour}:{minute}',
    },
    'players_count': {
      'fr': 'Joueurs ({count}/{max}):',
      'en': 'Players ({count}/{max}):',
    },
    'host': {
      'fr': 'Hôte',
      'en': 'Host',
    },
    'player': {
      'fr': 'Joueur',
      'en': 'Player',
    },
    'leave': {
      'fr': 'Quitter',
      'en': 'Leave',
    },
    'start_game': {
      'fr': 'Lancer le jeu',
      'en': 'Start game',
    },
    'waiting_for_player': {
      'fr': 'En attente d un 2e joueur ({count}/2)',
      'en': 'Waiting for a 2nd player ({count}/2)',
    },

    // === Multiplayer Game Page (multiplayer_game_page.dart) ===
    'duel_in_progress': {
      'fr': 'Duel en Cours !',
      'en': 'Duel in Progress!',
    },
    'next_question': {
      'fr': 'Question Suivante',
      'en': 'Next Question',
    },

    // === Results Page (game_results_page.dart) ===
    'results_title': {
      'fr': 'Résultats',
      'en': 'Results',
    },
    'final_ranking': {
      'fr': 'Classement Final',
      'en': 'Final Ranking',
    },
    'questions_summary': {
      'fr': 'Résumé des Questions',
      'en': 'Questions Summary',
    },
    'question_number': {
      'fr': 'Question {number}',
      'en': 'Question {number}',
    },
    'answers_label': {
      'fr': '✅ Réponse(s): {answers}',
      'en': '✅ Answer(s): {answers}',
    },
    'back_to_home': {
      'fr': 'Retour à l accueil',
      'en': 'Back to Home',
    },
  };

  /// Get translation for a key in the specified language
  static String t(String key, String language, {Map<String, String>? params}) {
    String translation = _translations[key]?[language] ?? key;

    // Replace parameters if provided
    if (params != null) {
      params.forEach((paramKey, paramValue) {
        translation = translation.replaceAll('{$paramKey}', paramValue);
      });
    }

    return translation;
  }

  /// Helper pour obtenir la langue depuis le Contexte
  static String getLang(BuildContext context) {
    // Utiliser 'watch' si vous êtes dans un 'build'
    // Utiliser 'read' si vous êtes dans un callback (initState, onPressed, etc.)
    return context.watch<LanguageProvider>().language;
  }
}