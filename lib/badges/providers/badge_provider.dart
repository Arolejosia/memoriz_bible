// File: lib/badges/providers/badge_provider.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:memoriz_bible/models/badge_model.dart';
import 'package:memoriz_bible/services/notification_service.dart';

class BadgeProvider extends ChangeNotifier with WidgetsBindingObserver {
  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int totalActiveDays = 0;
  int todayEngagedMinutes = 0;
  DateTime? _lastCountedDate;
  DateTime? _lastTickDate;
  bool isBetaTester = false;

  Map<String, BadgeModel> badges = {
    for (final b in kBadgeDefinitions) b.id: b,
  };

  Timer? _ticker;
  bool _isLoaded = false;

  final StreamController<BadgeModel> _unlockController =
  StreamController<BadgeModel>.broadcast();
  Stream<BadgeModel> get onBadgeUnlocked => _unlockController.stream;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _firestore.collection('users').doc(userId);

  BadgeProvider({required this.userId}) {
    WidgetsBinding.instance.addObserver(this);
    _loadFromFirestore();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _loadFromFirestore() async {
    try {
      final snap = await _userDoc.get();
      final data = snap.data();
      if (data != null) {
        totalActiveDays = data['totalActiveDays'] ?? 0;
        isBetaTester = data['isBetaTester'] ?? false;
        final lastCounted = data['lastCountedDate'];
        _lastCountedDate =
        lastCounted != null ? DateTime.tryParse(lastCounted) : null;

        // Reset des minutes du jour si on a changé de journée depuis le dernier enregistrement
        final lastMinutesDate = data['todayEngagedMinutesDate'];
        final lastMinutesDateTime =
        lastMinutesDate != null ? DateTime.tryParse(lastMinutesDate) : null;
        final today = DateTime.now();
        if (lastMinutesDateTime != null && _isSameDay(lastMinutesDateTime, today)) {
          todayEngagedMinutes = data['todayEngagedMinutes'] ?? 0;
        } else {
          todayEngagedMinutes = 0;
        }

        final badgesData = data['badges'] as Map<String, dynamic>?;
        if (badgesData != null) {
          badges = {
            for (final b in kBadgeDefinitions)
              b.id: b.mergeFromFirestore(badgesData[b.id]),
          };
        }
      }
    } catch (e) {
      debugPrint('BadgeProvider: erreur de chargement Firestore -> $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _syncToFirestore() async {
    try {
      await _userDoc.set({
        'totalActiveDays': totalActiveDays,
        'lastCountedDate': _lastCountedDate?.toIso8601String(),
        'todayEngagedMinutes': todayEngagedMinutes,
        'todayEngagedMinutesDate': DateTime.now().toIso8601String(),
        'badges': {
          for (final entry in badges.entries) entry.key: entry.value.toMap(),
        },
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('BadgeProvider: erreur de sync Firestore -> $e');
    }
  }

  /// À appeler quand l'utilisateur entre dans l'app / un écran actif
  /// Call when the user enters the app / an active screen
  void startSession() {
    if (!_isLoaded) return;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) => _tick());
  }

  /// À appeler quand l'app passe en arrière-plan
  /// Call when the app goes to background
  void pauseSession() {
    _ticker?.cancel();
    _syncToFirestore();
  }

  Future<void> _tick() async {
    final now = DateTime.now();

    // Reset si on a changé de jour pendant que l'app tourne
    if (_lastTickDate != null && !_isSameDay(_lastTickDate!, now)) {
      todayEngagedMinutes = 0;
    }
    _lastTickDate = now;

    todayEngagedMinutes += 1;
    await _checkAndMaybeCountDay();
    notifyListeners();
    await _syncToFirestore();
  }

  Future<void> _checkAndMaybeCountDay() async {
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final alreadyCounted =
        _lastCountedDate != null && _isSameDay(_lastCountedDate!, todayDateOnly);

    if (todayEngagedMinutes >= 15 && !alreadyCounted) {
      totalActiveDays += 1;
      _lastCountedDate = todayDateOnly;
      await _checkBadgeThresholds();
    }
  }

  Future<void> _checkBadgeThresholds() async {
    for (final def in kBadgeDefinitions) {
      if (def.betaOnly && !isBetaTester) continue;
      if (totalActiveDays < def.thresholdDays) continue;

      final current = badges[def.id];
      if (current != null && !current.unlocked) {
        final unlockedBadge =
        current.copyWith(unlocked: true, unlockedAt: DateTime.now());
        badges[def.id] = unlockedBadge;
        _unlockController.add(unlockedBadge);

        if (!kIsWeb) {
          await NotificationService.instance.showInstant(
            title: '${unlockedBadge.emoji} Nouveau badge débloqué !',
            body: unlockedBadge.name,
          );
        }
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      startSession();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      pauseSession();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _unlockController.close();
    super.dispose();
  }
}