// lib/core/localization/prayer_translations.dart
class PrayerTranslations {
  final String locale;

  PrayerTranslations(this.locale);

  static PrayerTranslations of(String locale) {
    return PrayerTranslations(locale);
  }

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
}