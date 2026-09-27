// lib/core/localization/prayer_translations.dart
class PrayerTranslations {
  final String locale;

  PrayerTranslations(this.locale);

  static PrayerTranslations of(String locale) {
    return PrayerTranslations(locale);
  }

  bool get _fr => locale == 'fr';

  // Titres
  String get prayer => locale == 'fr' ? 'Prière' : 'Prayer';
  String get prayerJournal => locale == 'fr' ? 'Journal de Prière' : 'Prayer Journal';
  String get history => locale == 'fr' ? 'Historique' : 'History';
  String get settings => locale == 'fr' ? 'Paramètres' : 'Settings';

  // Timer
  String get startPrayer => locale == 'fr' ? 'Démarrer la prière' : 'Start prayer';
  String get stopPrayer => locale == 'fr' ? 'Arrêter la prière' : 'Stop prayer';
  String get prayedToday => locale == 'fr' ? 'Temps prié aujourd\'hui' : 'Time prayed today';
  String get dailyGoal => locale == 'fr' ? 'Objectif quotidien' : 'Daily goal';
  String get progress => locale == 'fr' ? 'Progression' : 'Progress';
  String get sessions => locale == 'fr' ? 'Sessions' : 'Sessions';
  String get streak => locale == 'fr' ? 'Streak' : 'Streak';

  String consecutiveDays(int days) => locale == 'fr'
      ? '$days jour${days > 1 ? 's' : ''} consécutifs !'
      : '$days consecutive day${days > 1 ? 's' : ''} !';

  // Notes
  String get createNote => locale == 'fr' ? 'Créer une note' : 'Create note';
  String get editNote => locale == 'fr' ? 'Modifier la note' : 'Edit note';
  String get deleteNote => locale == 'fr' ? 'Supprimer la note' : 'Delete note';
  String get noteType => locale == 'fr' ? 'Type de note' : 'Note type';
  String get yourNote => locale == 'fr' ? 'Votre note' : 'Your note';
  String get bibleReference => locale == 'fr' ? 'Référence biblique (optionnel)' : 'Bible reference (optional)';
  String get tags => locale == 'fr' ? 'Étiquettes' : 'Tags';
  String get addTag => locale == 'fr' ? 'Ajouter une étiquette' : 'Add a tag';

  // Types de notes
  String get intention => locale == 'fr' ? '🙏 Intention' : '🙏 Intention';
  String get gratitude => locale == 'fr' ? '🙌 Gratitude' : '🙌 Gratitude';
  String get revelation => locale == 'fr' ? '💡 Révélation' : '💡 Revelation';

  // Hints
  String get intentionHint => locale == 'fr'
      ? 'Décrivez votre intention de prière...'
      : 'Describe your prayer intention...';
  String get gratitudeHint => locale == 'fr'
      ? 'Pour quoi êtes-vous reconnaissant ?'
      : 'What are you grateful for?';
  String get revelationHint => locale == 'fr'
      ? 'Quelle révélation avez-vous reçue ?'
      : 'What revelation did you receive?';

  // Paramètres
  String get dailyGoalSetting => locale == 'fr' ? 'Objectif quotidien' : 'Daily goal';
  String get targetDuration => locale == 'fr' ? 'Durée cible' : 'Target duration';
  String get notifications => locale == 'fr' ? 'Notifications' : 'Notifications';
  String get enableNotifications => locale == 'fr' ? 'Activer les notifications' : 'Enable notifications';
  String get prayerReminders => locale == 'fr' ? 'Rappels de prière' : 'Prayer reminders';
  String get streakReminders => locale == 'fr' ? 'Rappels de streak' : 'Streak reminders';
  String get autoSaveNotes => locale == 'fr' ? 'Sauvegarde automatique des notes' : 'Auto-save notes';
  String get customReminders => locale == 'fr' ? 'Rappels personnalisés' : 'Custom reminders';
  String get addReminder => locale == 'fr' ? 'Ajouter' : 'Add';
  String get noReminders => locale == 'fr' ? 'Aucun rappel configuré' : 'No reminders configured';

  // Jours de la semaine
  List<String> get weekDays => locale == 'fr'
      ? ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche']
      : ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  List<String> get weekDaysShort => locale == 'fr'
      ? ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
      : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String get everyday => locale == 'fr' ? 'Tous les jours' : 'Everyday';

  // Messages
  String get goalAchieved => locale == 'fr' ? '🎉 Objectif atteint !' : '🎉 Goal achieved!';
  String goalAchievedMessage(int minutes) => locale == 'fr'
      ? 'Vous avez prié $minutes minutes aujourd\'hui !'
      : 'You prayed $minutes minutes today!';

  String get newStreak => locale == 'fr' ? '🔥 Nouveau streak !' : '🔥 New streak!';
  String newStreakMessage(int days) => locale == 'fr'
      ? '$days jour${days > 1 ? 's' : ''} consécutifs !'
      : '$days consecutive day${days > 1 ? 's' : ''} !';

  String get addNotePrompt => locale == 'fr' ? 'Ajouter une note ?' : 'Add a note?';
  String get addNoteMessage => locale == 'fr'
      ? 'Voulez-vous noter une intention, gratitude ou révélation pour cette session de prière ?'
      : 'Would you like to note an intention, gratitude or revelation for this prayer session?';

  String get noteSaved => locale == 'fr' ? 'Note sauvegardée avec succès' : 'Note saved successfully';
  String get noteDeleted => locale == 'fr' ? 'Note supprimée' : 'Note deleted';
  String get saveError => locale == 'fr' ? 'Erreur lors de la sauvegarde' : 'Error saving';
  String get deleteError => locale == 'fr' ? 'Erreur lors de la suppression' : 'Error deleting';

  // Boutons
  String get save => locale == 'fr' ? 'Enregistrer' : 'Save';
  String get cancel => locale == 'fr' ? 'Annuler' : 'Cancel';
  String get delete => locale == 'fr' ? 'Supprimer' : 'Delete';
  String get edit => locale == 'fr' ? 'Modifier' : 'Edit';
  String get ok => locale == 'fr' ? 'OK' : 'OK';
  String get later => locale == 'fr' ? 'Plus tard' : 'Later';
  String get addNote => locale == 'fr' ? 'Ajouter une note' : 'Add note';
  String get viewAll => locale == 'fr' ? 'Voir tout' : 'View all';

  // Historique
  String get totalTime => locale == 'fr' ? 'Temps total' : 'Total time';
  String get goalsAchieved => locale == 'fr' ? 'Objectifs atteints' : 'Goals achieved';
  String get bestStreak => locale == 'fr' ? 'Meilleur streak' : 'Best streak';
  String get last7Days => locale == 'fr' ? '📈 7 derniers jours' : '📈 Last 7 days';
  String get recentNotes => locale == 'fr' ? '📝 Notes récentes' : '📝 Recent notes';
  String get today => locale == 'fr' ? '📊 Aujourd\'hui' : '📊 Today';
  String get timePrayed => locale == 'fr' ? 'Temps prié' : 'Time prayed';
  String get noPrayerSession => locale == 'fr' ? 'Aucune session de prière' : 'No prayer sessions';
  String get noNotes => locale == 'fr' ? 'Aucune note pour le moment' : 'No notes yet';
  String get noNotesFound => locale == 'fr' ? 'Aucune note trouvée' : 'No notes found';
  String get createFirstNote => locale == 'fr'
      ? 'Appuyez sur + pour créer votre première note'
      : 'Press + to create your first note';

  // Recherche
  String get search => locale == 'fr' ? 'Rechercher' : 'Search';
  String get searchInNotes => locale == 'fr' ? 'Rechercher dans vos notes...' : 'Search in your notes...';
  String get clear => locale == 'fr' ? 'Effacer' : 'Clear';
  String get all => locale == 'fr' ? 'Tout' : 'All';

  // Temps
  String get today2 => locale == 'fr' ? 'Aujourd\'hui' : 'Today';
  String get yesterday => locale == 'fr' ? 'Hier' : 'Yesterday';
  String get justNow => locale == 'fr' ? 'À l\'instant' : 'Just now';
  String minutesAgo(int min) => locale == 'fr' ? 'Il y a ${min}min' : '${min}min ago';
  String hoursAgo(int hours) => locale == 'fr' ? 'Il y a ${hours}h' : '${hours}h ago';
  String daysAgo(int days) => locale == 'fr' ? 'Il y a ${days}j' : '${days}d ago';

  // Mois
  List<String> get months => locale == 'fr'
      ? ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre']
      : ['January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'];

  // Dialogs
  String get unsavedChanges => locale == 'fr' ? 'Modifications non sauvegardées' : 'Unsaved changes';
  String get exitWithoutSaving => locale == 'fr'
      ? 'Voulez-vous quitter sans enregistrer ?'
      : 'Do you want to exit without saving?';
  String get quit => locale == 'fr' ? 'Quitter' : 'Quit';
  String get confirmDelete => locale == 'fr' ? 'Supprimer la note ?' : 'Delete note?';
  String get deleteConfirmation => locale == 'fr'
      ? 'Cette action est irréversible.'
      : 'This action cannot be undone.';
  String get saveChanges => locale == 'fr'
      ? 'Enregistrer les modifications'
      : 'Save changes';
  String get settingsSaved => locale == 'fr'
      ? 'Paramètres enregistrés'
      : 'Settings saved';
  String get enableNotificationsInSettings => locale == 'fr'
      ? 'Veuillez activer les notifications dans les paramètres'
      : 'Please enable notifications in settings';

  // Messages de notification
  String get prayerTimeTitle => locale == 'fr' ? '🙏 Temps de prière' : '🙏 Prayer time';
  String prayerTimeBody(int minutes) => locale == 'fr'
      ? 'Prenez un moment pour prier (Objectif: ${minutes}min)'
      : 'Take a moment to pray (Goal: ${minutes}min)';

  // ===================================================
  // ✅ NOUVEAU : MÉDITATION
  // ===================================================

  // Accueil
  String get meditation => _fr ? 'Méditation' : 'Meditation';
  String get whichPassage => _fr
      ? 'Quel passage veux-tu méditer aujourd\'hui ?'
      : 'Which passage would you like to meditate on today?';
  String get passageSearchHint => _fr ? 'Livre, chapitre ou verset…' : 'Book, chapter or verse…';
  String resumePassage(String ref) => _fr ? 'Reprendre $ref' : 'Resume $ref';
  String get recentMeditations => _fr ? 'Mes méditations récentes' : 'My recent meditations';
  String get noMeditationsYet => _fr
      ? 'Tes méditations apparaîtront ici. Choisis un passage pour commencer.'
      : 'Your meditations will appear here. Choose a passage to begin.';
  String get prayerJournalSubtitle => _fr ? 'Prières et notes libres' : 'Prayers and free notes';
  String get prayerTimeSection => _fr ? 'Temps de prière' : 'Prayer time';
  String get daysInARow => _fr ? 'Jours de suite' : 'Days in a row';

  // Modes
  String get modeGuided => _fr ? 'Guidée' : 'Guided';
  String get modeQuick => _fr ? 'Rapide' : 'Quick';
  String get modeFree => _fr ? 'Libre' : 'Free';
  String get modeNoQuestions => _fr ? 'sans questions' : 'no questions';
  String get tagGuided => _fr ? 'méditation guidée' : 'guided meditation';
  String get tagQuick => _fr ? 'méditation rapide' : 'quick meditation';
  String get tagFree => _fr ? 'méditation libre' : 'free meditation';

  // Choix du passage
  String get choosePassage => _fr ? 'Choisir un passage' : 'Choose a passage';
  String get directSearch => _fr ? 'Recherche directe' : 'Direct search';
  String get directSearchHint =>
      _fr ? 'ex. Jean 14:27 ou Psaumes 23:1-6' : 'e.g. John 14:27 or Psalms 23:1-6';
  String get orBrowseBible => _fr ? 'Ou parcourir la Bible' : 'Or browse the Bible';
  String get oldTestament => _fr ? 'Ancien Testament' : 'Old Testament';
  String get newTestament => _fr ? 'Nouveau Testament' : 'New Testament';
  String get book => _fr ? 'Livre' : 'Book';
  String chapterOf(String book) => _fr ? 'Chapitre de $book' : '$book chapter';
  String get verses => _fr ? 'Versets' : 'Verses';
  String get fromVerse => _fr ? 'Du verset' : 'From verse';
  String get toVerseOptional => _fr ? 'au verset (facultatif)' : 'to verse (optional)';
  String get booksLoadError => _fr
      ? 'Impossible de charger les livres. Vérifie ta connexion.'
      : 'Could not load the books. Check your connection.';
  String get retry => _fr ? 'Réessayer' : 'Retry';
  String viewPassage(String ref) => _fr ? 'Voir $ref' : 'View $ref';
  String meditateOn(String ref) => _fr ? 'Méditer $ref' : 'Meditate on $ref';

  // Méditation guidée
  String stepOf(int i, int n, String title) =>
      _fr ? 'Étape $i sur $n  ·  $title' : 'Step $i of $n  ·  $title';
  String get anotherQuestion => _fr ? 'Une autre question' : 'Another question';
  String get yourAnswerPrivate => _fr ? 'Ta réponse (reste privée)' : 'Your answer (stays private)';
  String get answerHint => _fr
      ? 'Écris ce qui te vient, même en quelques mots…'
      : 'Write whatever comes to mind, even a few words…';
  String get previous => _fr ? 'Précédent' : 'Previous';
  String nextStep(String title) => _fr ? 'Suivant : $title' : 'Next: $title';
  String get finish => _fr ? 'Terminer' : 'Finish';
  String get writeAtLeastOne => _fr
      ? 'Écris au moins une réponse avant de terminer.'
      : 'Write at least one answer before finishing.';
  String get meditationSaveError => _fr
      ? 'La méditation n\'a pas pu être enregistrée. Réessaie.'
      : 'The meditation could not be saved. Please try again.';
  String get quitMeditationTitle => _fr ? 'Quitter la méditation ?' : 'Leave the meditation?';
  String get quitMeditationBody => _fr
      ? 'Ce que tu as écrit ne sera pas enregistré.'
      : 'What you wrote will not be saved.';
  String get continueLabel => _fr ? 'Continuer' : 'Continue';
  String get passageUnavailable => _fr
      ? 'Passage indisponible pour le moment.'
      : 'Passage unavailable at the moment.';

  // Étapes (les titres servent aussi à relire une méditation enregistrée)
  String get stepRead => _fr ? 'Lire' : 'Read';
  String get stepObserve => _fr ? 'Observer' : 'Observe';
  String get stepReflect => _fr ? 'Réfléchir' : 'Reflect';
  String get stepApply => _fr ? 'Appliquer' : 'Apply';
  String get stepPray => _fr ? 'Prier' : 'Pray';
  String get stepMeditate => _fr ? 'Méditer' : 'Meditate';

  /// Tous les titres d'étapes, dans les deux langues
  static const allStepTitles = [
    'Observer', 'Réfléchir', 'Appliquer', 'Prier', 'Méditer',
    'Observe', 'Reflect', 'Apply', 'Pray', 'Meditate',
  ];

  String get readInstruction => _fr
      ? 'Lis le passage lentement, deux fois. Une fois à voix haute si tu peux.'
      : 'Read the passage slowly, twice. Once out loud if you can.';
  String get observeInstruction => _fr
      ? 'Comprendre ce que dit le texte avant ce qu\'il me dit.'
      : 'Understand what the text says before what it says to me.';
  String get reflectInstruction => _fr
      ? 'Laisse le texte te parler personnellement.'
      : 'Let the text speak to you personally.';
  String get applyInstruction => _fr ? 'Passer de la lecture à la vie.' : 'Move from reading to living.';
  String get prayInstruction => _fr
      ? 'Réponds à Dieu avec tes propres mots.'
      : 'Answer God in your own words.';
  String get meditateInstruction => _fr ? 'Écris librement ce qui te vient.' : 'Write freely whatever comes.';

  List<String> get observeQuestions => _fr
      ? [
    'Quel mot ou quelle image te frappe dans ce passage ?',
    'Qui parle, et à qui ?',
    'Quel mot ou quelle idée se répète ?',
    'Qu\'est-ce que ce passage révèle sur Dieu, sur son caractère ?',
    'Y a-t-il une promesse, un commandement ou un avertissement ?',
  ]
      : [
    'Which word or image stands out to you in this passage?',
    'Who is speaking, and to whom?',
    'Which word or idea is repeated?',
    'What does this passage reveal about God and His character?',
    'Is there a promise, a command or a warning?',
  ];

  List<String> get reflectQuestions => _fr
      ? [
    'Pourquoi ce passage te touche-t-il aujourd\'hui ?',
    'Qu\'est-ce qui te résiste ou te dérange dans ce texte ?',
    'Si tu remplaçais « vous » par ton prénom, qu\'est-ce que ça change ?',
    'Quel lien vois-tu avec ce que tu vis cette semaine ?',
    'Quelle vérité as-tu besoin de croire à nouveau ?',
  ]
      : [
    'Why does this passage touch you today?',
    'What in this text challenges or unsettles you?',
    'If you replaced "you" with your own name, what changes?',
    'How does it connect with what you are living this week?',
    'Which truth do you need to believe again?',
  ];

  List<String> get applyQuestions => _fr
      ? [
    'Qu\'est-ce que Dieu t\'invite à faire, arrêter ou croire ?',
    'Quelle est une action concrète pour aujourd\'hui ?',
    'Envers qui ce passage peut-il changer ton attitude ?',
  ]
      : [
    'What is God inviting you to do, stop or believe?',
    'What is one concrete action for today?',
    'Toward whom could this passage change your attitude?',
  ];

  List<String> get prayQuestions => _fr
      ? [
    'Écris une courte prière à partir de ce que tu as reçu.',
    'Qu\'as-tu envie de dire à Dieu après ce passage ?',
    'Transforme ce verset en prière personnelle.',
  ]
      : [
    'Write a short prayer from what you received.',
    'What would you like to say to God after this passage?',
    'Turn this verse into a personal prayer.',
  ];

  List<String> get meditateQuestions => _fr
      ? ['Qu\'est-ce que ce passage te dit aujourd\'hui ?']
      : ['What is this passage saying to you today?'];

  // Lecture d'une note
  String get readMore => _fr ? 'Lire la suite' : 'Read more';
  String get noteNotFound => _fr ? 'Cette note n\'existe plus.' : 'This note no longer exists.';
  String get noteLabel => _fr ? 'Note' : 'Note';
  String dateAt(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return _fr
        ? 'Le ${d.day}/${d.month}/${d.year} à ${two(d.hour)}h${two(d.minute)}'
        : '${months[d.month - 1]} ${d.day}, ${d.year} at ${two(d.hour)}:${two(d.minute)}';
  }

  // Partage
  String get share => _fr ? 'Partager' : 'Share';
  String get shareVerse => _fr ? 'Partager le verset' : 'Share verse';
  String get storyFormat => _fr ? 'Statut / Story' : 'Status / Story';
  String get squareFormat => _fr ? 'Carré' : 'Square';
  String get shareImage => _fr ? 'Partager l\'image' : 'Share image';
  String get textLabel => _fr ? 'Texte' : 'Text';
  String get copy => _fr ? 'Copier' : 'Copy';
  String get copied => _fr ? 'Copié !' : 'Copied!';
  String get textCopied => _fr ? 'Le texte a été copié.' : 'The text has been copied.';
  String get imageShareUnavailable => _fr
      ? 'Le partage d\'image n\'est pas disponible ici. Le texte a été copié.'
      : 'Image sharing is not available here. The text has been copied.';
  String get whatsappStatusHint => _fr
      ? 'Pour ton statut WhatsApp : « Partager l\'image », puis WhatsApp → « Mon statut ».'
      : 'For your WhatsApp status: "Share image", then WhatsApp → "My status".';
  String get sharedFromApp => _fr ? 'Partagé depuis MemorizBible 📖' : 'Shared from MemorizBible 📖';
  String get viaApp => _fr ? 'via MemorizBible' : 'via MemorizBible';
  String get themeTeal => _fr ? 'Sarcelle' : 'Teal';
  String get themeNight => _fr ? 'Nuit' : 'Night';
  String get themeLight => _fr ? 'Clair' : 'Light';
}