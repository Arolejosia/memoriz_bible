// lib/screens/prayer/providers/prayer_timer_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/prayer_session.dart';
import '../models/daily_prayer_stats.dart';
import '../models/prayer_settings.dart';
import '../../../services/notification_service.dart';

class PrayerTimerProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final String userId;

  Timer? _timer;
  PrayerSession? _currentSession;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  DailyPrayerStats? _todayStats;
  PrayerSettings _settings = PrayerSettings();
  bool _isLoading = true;

  PrayerTimerProvider({required this.userId}) {
    _initialize();
  }

  // Getters
  bool get isRunning => _isRunning;
  int get elapsedSeconds => _elapsedSeconds;
  PrayerSession? get currentSession => _currentSession;
  DailyPrayerStats? get todayStats => _todayStats;
  PrayerSettings get settings => _settings;
  bool get isLoading => _isLoading;

  String get formattedTime {
    final hours = _elapsedSeconds ~/ 3600;
    final minutes = (_elapsedSeconds % 3600) ~/ 60;
    final seconds = _elapsedSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // Initialisation
  Future<void> _initialize() async {
    try {
      await _notificationService.init();  // ⬅️ Corrigé : init() au lieu de initialize()
      await _loadSettings();
      await _loadTodayStats();
      await _checkForUnfinishedSession();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur initialisation PrayerTimerProvider: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Charger les paramètres
  Future<void> _loadSettings() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('prayer')
          .get();

      _settings = PrayerSettings.fromFirestore(doc);

      // Planifier les notifications
      if (_settings.notificationsEnabled && _settings.reminders.isNotEmpty) {
        await _scheduleNotifications();
      }

      debugPrint('✅ Paramètres chargés: objectif ${_settings.dailyGoalMinutes}min');
    } catch (e) {
      debugPrint('❌ Erreur chargement paramètres: $e');
    }
  }

  // Planifier les notifications
  Future<void> _scheduleNotifications() async {
    await _notificationService.cancelAll();  // ⬅️ Corrigé

    for (int i = 0; i < _settings.reminders.length; i++) {
      final reminder = _settings.reminders[i];
      if (reminder.enabled) {
        await _notificationService.scheduleWeekly(  // ⬅️ Corrigé
          hour: reminder.time.hour,
          minute: reminder.time.minute,
          days: reminder.daysOfWeek,
          title: '🙏 Temps de prière',
          body: 'Prenez un moment pour prier (Objectif: ${_settings.dailyGoalMinutes}min)',
        );
      }
    }
  }

  // Vérifier s'il y a une session non terminée
  Future<void> _checkForUnfinishedSession() async {
    try {
      final today = _getTodayString();
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('prayerSessions')
          .where('date', isEqualTo: today)
          .where('isCompleted', isEqualTo: false)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final session = PrayerSession.fromFirestore(snapshot.docs.first);
        _currentSession = session;

        // Calculer le temps écoulé
        final now = DateTime.now();
        _elapsedSeconds = now.difference(session.startTime).inSeconds;

        // Proposer de reprendre
        debugPrint('⚠️ Session non terminée trouvée: ${session.id}');
      }
    } catch (e) {
      debugPrint('❌ Erreur vérification session: $e');
    }
  }

  // Charger les stats du jour
  Future<void> _loadTodayStats() async {
    try {
      final today = _getTodayString();
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('prayerStats')
          .doc('daily')
          .collection('entries')
          .doc(today)
          .get();

      if (doc.exists) {
        _todayStats = DailyPrayerStats.fromFirestore(doc);
      } else {
        // Créer les stats du jour
        final streak = await _calculateStreak();
        _todayStats = DailyPrayerStats(
          date: today,
          totalSeconds: 0,
          goalSeconds: _settings.dailyGoalSeconds,
          sessionsCount: 0,
          goalAchieved: false,
          streak: streak,
        );
        await _saveTodayStats();
      }

      debugPrint('✅ Stats chargées: ${_todayStats!.formattedTotal}/${_todayStats!.formattedGoal}');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur chargement stats: $e');
    }
  }

  // Calculer le streak
  Future<int> _calculateStreak() async {
    try {
      int streak = 0;
      DateTime date = DateTime.now().subtract(const Duration(days: 1));

      // Remonter dans le temps jusqu'à trouver un jour sans objectif atteint
      while (true) {
        final dateStr = _formatDate(date);
        final doc = await _firestore
            .collection('users')
            .doc(userId)
            .collection('prayerStats')
            .doc('daily')
            .collection('entries')
            .doc(dateStr)
            .get();

        if (!doc.exists) break;

        final stats = DailyPrayerStats.fromFirestore(doc);
        if (!stats.goalAchieved) break;

        streak++;
        date = date.subtract(const Duration(days: 1));

        // Limite de sécurité
        if (streak > 365) break;
      }

      return streak;
    } catch (e) {
      debugPrint('❌ Erreur calcul streak: $e');
      return 0;
    }
  }

  // Sauvegarder les stats du jour
  Future<void> _saveTodayStats() async {
    if (_todayStats == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('prayerStats')
          .doc('daily')
          .collection('entries')
          .doc(_todayStats!.date)
          .set(_todayStats!.toFirestore());
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde stats: $e');
    }
  }

  // Démarrer une session
  Future<void> startSession() async {
    if (_isRunning) return;

    try {
      final now = DateTime.now();
      final sessionRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('prayerSessions')
          .doc();

      _currentSession = PrayerSession(
        id: sessionRef.id,
        startTime: now,
        duration: 0,
        date: _getTodayString(),
        isCompleted: false,
      );

      await sessionRef.set(_currentSession!.toFirestore());

      _elapsedSeconds = 0;
      _isRunning = true;
      _startTimer();

      debugPrint('✅ Session démarrée: ${_currentSession!.id}');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur démarrage session: $e');
    }
  }

  // Timer interne
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      notifyListeners();

      // Sauvegarde toutes les 10 secondes
      if (_elapsedSeconds % 10 == 0) {
        _saveSessionProgress();
      }

      // Vérifier si l'objectif est atteint
      if (_todayStats != null && _settings.notificationsEnabled) {
        final newTotal = _todayStats!.totalSeconds + _elapsedSeconds;
        if (newTotal >= _settings.dailyGoalSeconds &&
            _todayStats!.totalSeconds < _settings.dailyGoalSeconds) {
          _notificationService.showInstant(  // ⬅️ Corrigé : showInstant au lieu de showNotification
            title: '🎉 Objectif atteint !',
            body: 'Vous avez prié ${_settings.dailyGoalMinutes} minutes aujourd\'hui !',
          );
        }
      }
    });
  }

  // Sauvegarder la progression
  Future<void> _saveSessionProgress() async {
    if (_currentSession == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('prayerSessions')
          .doc(_currentSession!.id)
          .update({
        'duration': _elapsedSeconds,
      });
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde progression: $e');
    }
  }

  // Arrêter la session
  Future<String?> stopSession() async {
    if (!_isRunning || _currentSession == null) return null;

    try {
      _timer?.cancel();
      _isRunning = false;

      final endTime = DateTime.now();
      final sessionId = _currentSession!.id;

      // Mettre à jour la session
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('prayerSessions')
          .doc(sessionId)
          .update({
        'endTime': Timestamp.fromDate(endTime),
        'duration': _elapsedSeconds,
        'isCompleted': true,
      });

      // Mettre à jour les stats du jour
      if (_todayStats != null) {
        final newTotal = _todayStats!.totalSeconds + _elapsedSeconds;
        final newGoalAchieved = newTotal >= _settings.dailyGoalSeconds;
        final wasGoalAchieved = _todayStats!.goalAchieved;

        _todayStats = DailyPrayerStats(
          date: _todayStats!.date,
          totalSeconds: newTotal,
          goalSeconds: _settings.dailyGoalSeconds,
          sessionsCount: _todayStats!.sessionsCount + 1,
          goalAchieved: newGoalAchieved,
          streak: newGoalAchieved ? _todayStats!.streak + 1 : _todayStats!.streak,
        );

        await _saveTodayStats();

        // Notification de nouveau streak
        if (newGoalAchieved && !wasGoalAchieved && _settings.showStreakReminders) {
          _notificationService.showInstant(  // ⬅️ Corrigé
            title: '🔥 Nouveau streak !',
            body: '${_todayStats!.streak} jour${_todayStats!.streak > 1 ? 's' : ''} consécutifs !',
          );
        }
      }

      debugPrint('✅ Session terminée: ${_elapsedSeconds}s');

      final completedSessionId = sessionId;
      _currentSession = null;
      _elapsedSeconds = 0;
      notifyListeners();

      return completedSessionId;
    } catch (e) {
      debugPrint('❌ Erreur arrêt session: $e');
      return null;
    }
  }

  // Mettre à jour les paramètres
  Future<void> updateSettings(PrayerSettings newSettings) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('prayer')
          .set(newSettings.toFirestore());

      _settings = newSettings;

      // Re-planifier les notifications
      if (newSettings.notificationsEnabled && newSettings.reminders.isNotEmpty) {
        await _scheduleNotifications();
      } else {
        await _notificationService.cancelAll();  // ⬅️ Corrigé
      }

      // Mettre à jour l'objectif des stats du jour
      if (_todayStats != null) {
        _todayStats = DailyPrayerStats(
          date: _todayStats!.date,
          totalSeconds: _todayStats!.totalSeconds,
          goalSeconds: newSettings.dailyGoalSeconds,
          sessionsCount: _todayStats!.sessionsCount,
          goalAchieved: _todayStats!.totalSeconds >= newSettings.dailyGoalSeconds,
          streak: _todayStats!.streak,
        );
        await _saveTodayStats();
      }

      debugPrint('✅ Paramètres mis à jour');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur mise à jour paramètres: $e');
    }
  }

  // Helpers
  String _getTodayString() => _formatDate(DateTime.now());

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}