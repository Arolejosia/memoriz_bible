import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:memoriz_bible/screens/games/RECITATION/recitation_controller.dart';
import 'package:memoriz_bible/screens/games/RECITATION/recitation_translations.dart';
import '../../../services/Bible_service.dart';

class RecitationMultiplayerController extends RecitationController {
  final String roomCode;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final ValueNotifier<bool> recitationFailed = ValueNotifier(false);
  final String language; // Langue pour les logs/messages

  StreamSubscription? _roomSubscription;
  Timer? _questionTimer;
  Timer? _countdownTimer;
  Map<String, dynamic> _roomData = {};

  // Données locales
  List<Map<String, dynamic>> _localQuestions = [];
  int _localCurrentQuestionIndex = 0;
  Map<String, int> _localScores = {};

  // État de récitation
  bool _hasSubmitted = false;

  // Getters privés
  String get _hostId => _roomData['hostId'] ?? '';
  bool get _isHost => currentUserId == _hostId;
  Map<String, dynamic> get _players => _roomData['players'] as Map<String, dynamic>? ?? {};
  Map<String, dynamic> get _currentQuestion {
    if (_localQuestions.isEmpty || _localCurrentQuestionIndex >= _localQuestions.length) {
      return {};
    }
    return _localQuestions[_localCurrentQuestionIndex];
  }

  // Getters publics
  @override
  String? get currentReference => _currentQuestion['reference'];
  int get localCurrentQuestionIndex => _localCurrentQuestionIndex;
  List<dynamic> get questions => _localQuestions;

  int get timeLeft {
    final endsAt = _roomData['currentQuestionEndsAt'] as Timestamp?;
    if (endsAt == null) return 60;
    final now = DateTime.now();
    final endTime = endsAt.toDate();
    final secondsLeft = endTime.difference(now).inSeconds;
    return secondsLeft.clamp(0, 60);
  }

  bool get questionAlreadyAnswered => _roomData['status'] == 'answered' || _roomData['correctAnswerFound'] == true;
  String? get correctAnswerWinnerId => _roomData['correctAnswerBy'];
  String? get correctAnswerWinnerName {
    final winnerId = correctAnswerWinnerId;
    if (winnerId != null && _players.containsKey(winnerId)) {
      return _players[winnerId]['name'] ?? RecitationTranslations.t('unknown_player', language);
    }
    return null;
  }

  // Autres getters spécifiques
  bool get isGameFinished => _roomData['status'] == 'finished';
  int get currentScore => _localScores[currentUserId] ?? 0;
  String get status => _roomData['status'] ?? 'loading';
  String get correctText => _currentQuestion['text'] ?? '';
  bool get hasSubmitted => _hasSubmitted;
  Map<String, dynamic> get players => _players;

  List<MapEntry<String, int>> get playerRanking {
    return _localScores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  RecitationMultiplayerController({
    required this.roomCode,
    this.language = 'fr', // Langue par défaut
  }) {
    _initializeAndListenToRoom();
  }

  Future<void> _initializeAndListenToRoom() async {
    try {
      isSpeechInitialized = await speech.initialize();

      final roomSnapshot = await FirebaseFirestore.instance.collection('game_rooms').doc(roomCode).get();
      if (!roomSnapshot.exists) {
        print('❌ ${RecitationTranslations.t('error', language)}: Room $roomCode does not exist');
        return;
      }

      _roomData = roomSnapshot.data()!;
      isLoading = false;

      final List<dynamic> qList = _roomData['questions'] ?? [];
      _localQuestions = qList.map((q) => Map<String, dynamic>.from(q)).toList();

      final players = _roomData['players'] as Map<String, dynamic>? ?? {};
      for (String playerId in players.keys) {
        _localScores[playerId] = players[playerId]['score'] ?? 0;
      }
      _localCurrentQuestionIndex = _roomData['currentQuestionIndex'] ?? 0;

      _listenToRoom();
      notifyListeners();

      print('✅ Récitation multijoueur initialisée - Room: $roomCode');
    } catch (e) {
      print('❌ ${RecitationTranslations.t('initialization_error', language)}: $e');
    }
  }

  @override
  Future<void> verifyRecitation() async {
    if (transcribedText.isEmpty || _hasSubmitted || questionAlreadyAnswered) {
      print('🚫 ${RecitationTranslations.t('error', language)}: Cannot verify - Empty: ${transcribedText.isEmpty}, Submitted: $_hasSubmitted, Answered: $questionAlreadyAnswered');
      return;
    }

    isVerifying = true;
    _hasSubmitted = true;
    notifyListeners();

    try {
      final score = await BibleService().getVerificationScore(transcribedText, correctText);
      final isCorrect = score >= 70;
      int pointsEarned = 0;

      if (isCorrect) {
        pointsEarned = timeLeft + 50;
        await FirebaseFirestore.instance.collection('game_rooms').doc(roomCode).update({
          'correctAnswerFound': true,
          'correctAnswerBy': currentUserId,
          'players.$currentUserId.answers.$_localCurrentQuestionIndex': transcribedText,
          'players.$currentUserId.score': FieldValue.increment(pointsEarned),
        });
        _localScores[currentUserId] = (_localScores[currentUserId] ?? 0) + pointsEarned;
        _endCurrentQuestion();

        print('✅ ${RecitationTranslations.t('correct_answer', language)} +$pointsEarned ${RecitationTranslations.t('points', language)}');
      } else {
        await FirebaseFirestore.instance.collection('game_rooms').doc(roomCode).update({
          'players.$currentUserId.answers.$_localCurrentQuestionIndex': transcribedText,
        });

        print('❌ ${RecitationTranslations.t('wrong_answer', language)} (score: $score/100)');

        // Réinitialiser pour permettre une nouvelle tentative
        _hasSubmitted = false;
        transcribedText = "";
      }
    } catch (e) {
      print('❌ ${RecitationTranslations.t('verification_error', language)}: $e');
    } finally {
      isVerifying = false;
      notifyListeners();
    }
  }

  void _listenToRoom() {
    _roomSubscription = FirebaseFirestore.instance
        .collection('game_rooms')
        .doc(roomCode)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final newRoomData = snapshot.data()!;
        final previousStatus = _roomData['status'];

        _roomData = newRoomData;

        final newQuestionIndex = newRoomData['currentQuestionIndex'] ?? 0;
        if (newQuestionIndex != _localCurrentQuestionIndex) {
          _localCurrentQuestionIndex = newQuestionIndex;
          _resetForNewQuestion();
          print('🔄 ${RecitationTranslations.t('question_progress', language, params: {
            'current': '${_localCurrentQuestionIndex + 1}',
            'total': '${_localQuestions.length}'
          })}');
        }

        _syncScores();

        if (_roomData['status'] == 'playing' || _roomData['status'] == 'started') {
          if ((previousStatus != 'playing' && previousStatus != 'started') && _roomData['currentQuestionEndsAt'] != null) {
            _startLocalCountdown();
          }
          _manageGameLogic();
        }

        final correctAnswerFound = newRoomData['correctAnswerFound'] ?? false;
        if (correctAnswerFound && _roomData['status'] == 'playing') {
          final correctAnswerBy = _roomData['correctAnswerBy'] ?? 'unknown';
          if (correctAnswerBy != currentUserId) {
            final winnerName = _players[correctAnswerBy]?['name'] ?? RecitationTranslations.t('unknown_player', language);
            print('🎯 ${RecitationTranslations.t('player_found_answer', language, params: {'player': winnerName})}');
            _endCurrentQuestion();
          }
        }

        if (_roomData['status'] == 'finished') {
          _handleGameFinished();
        }

        notifyListeners();
      }
    }, onError: (error) {
      print('❌ ${RecitationTranslations.t('connection_error', language)}: $error');
    });
  }

  void _resetForNewQuestion() {
    _stopListening();
    transcribedText = "";
    _hasSubmitted = false;
    isVerifying = false;
    _questionTimer?.cancel();
    _countdownTimer?.cancel();
    print('🔄 Nouvelle question - État réinitialisé');
  }

  void _syncScores() {
    final players = _roomData['players'] as Map<String, dynamic>? ?? {};
    for (String playerId in players.keys) {
      _localScores[playerId] = players[playerId]['score'] ?? 0;
    }
  }

  void _manageGameLogic() {
    if (_localQuestions.isEmpty || isGameFinished) return;

    final status = _roomData['status'];
    final currentQuestionEndsAt = _roomData['currentQuestionEndsAt'];
    final correctAnswerFound = _roomData['correctAnswerFound'] ?? false;

    if (status == 'playing' && currentQuestionEndsAt == null && !correctAnswerFound) {
      print('🚀 ${RecitationTranslations.t('timer', language)} - Démarrage pour la question');
      _startQuestionTimer();
    }

    if (status == 'playing' && timeLeft <= 0 && currentQuestionEndsAt != null && !correctAnswerFound) {
      print('⏰ ${RecitationTranslations.t('time', language)} écoulé - Fin de la question');
      _endCurrentQuestion();
    }
  }

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    _countdownTimer?.cancel();

    final endsAt = DateTime.now().add(const Duration(seconds: 60));

    FirebaseFirestore.instance.runTransaction((transaction) async {
      final roomRef = FirebaseFirestore.instance.collection('game_rooms').doc(roomCode);
      final roomSnapshot = await transaction.get(roomRef);

      if (!roomSnapshot.exists) throw Exception('Room does not exist');

      final roomData = roomSnapshot.data()!;
      if (roomData['currentQuestionEndsAt'] == null) {
        transaction.update(roomRef, {
          'currentQuestionEndsAt': Timestamp.fromDate(endsAt),
          'status': 'playing',
        });
        return true;
      }
      return false;
    }).then((timerCreated) {
      if (timerCreated) {
        _startLocalCountdown();
        _questionTimer = Timer(const Duration(seconds: 61), () {
          if (!isGameFinished && (_roomData['status'] == 'playing' || _roomData['status'] == 'started')) {
            _endCurrentQuestion();
          }
        });
        print('✅ Timer créé avec succès - 60 secondes');
      } else {
        _startLocalCountdown();
        print('ℹ️ Timer déjà existant - Démarrage du countdown local');
      }
    }).catchError((error) {
      print('❌ ${RecitationTranslations.t('error', language)} timer: $error');
    });
  }

  void _startLocalCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentTimeLeft = timeLeft;
      if (currentTimeLeft <= 0) {
        timer.cancel();
      }
      notifyListeners();
    });
    print('⏱️ Countdown local démarré');
  }

  void _stopListening() async {
    if (isListening) {
      await speech.stop();
      isListening = false;
      print('🎤 Écoute arrêtée');
    }
  }

  Future<void> _endCurrentQuestion() async {
    _questionTimer?.cancel();
    _countdownTimer?.cancel();
    _stopListening();

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final roomRef = FirebaseFirestore.instance.collection('game_rooms').doc(roomCode);
        final roomSnapshot = await transaction.get(roomRef);
        if (!roomSnapshot.exists) throw Exception('Room does not exist');

        final roomData = roomSnapshot.data()!;
        if (roomData['status'] != 'answered') {
          transaction.update(roomRef, {
            'status': 'answered',
            'revealedAnswer': correctText,
          });
          return true;
        }
        return false;
      });

      print('📚 Question terminée - Passage à la suivante dans 3s');

      Timer(const Duration(seconds: 3), () {
        _attemptNextQuestion();
      });
    } catch (e) {
      print('❌ ${RecitationTranslations.t('error', language)} fin de question: $e');
    }
  }

  void _attemptNextQuestion() {
    if (isGameFinished) return;

    if (_localCurrentQuestionIndex < _localQuestions.length - 1) {
      final newIndex = _localCurrentQuestionIndex + 1;

      FirebaseFirestore.instance.runTransaction((transaction) async {
        final roomRef = FirebaseFirestore.instance.collection('game_rooms').doc(roomCode);
        final roomSnapshot = await transaction.get(roomRef);
        if (!roomSnapshot.exists) throw Exception('Room does not exist');

        final roomData = roomSnapshot.data()!;
        final currentIndex = roomData['currentQuestionIndex'] ?? 0;

        if (currentIndex == _localCurrentQuestionIndex && roomData['status'] == 'answered') {
          transaction.update(roomRef, {
            'currentQuestionIndex': newIndex,
            'status': 'playing',
            'currentQuestionEndsAt': FieldValue.delete(),
            'revealedAnswer': FieldValue.delete(),
            'correctAnswerFound': FieldValue.delete(),
            'correctAnswerBy': FieldValue.delete(),
          });
          return true;
        }
        return false;
      }).then((success) {
        if (success) {
          print('✅ Passage à la question ${newIndex + 1}/${_localQuestions.length}');
        }
      });
    } else {
      print('🏁 Dernière question terminée - Fin du jeu');
      _attemptEndGame();
    }
  }

  Future<void> _attemptEndGame() async {
    if (isGameFinished) return;

    try {
      _questionTimer?.cancel();
      _countdownTimer?.cancel();
      _stopListening();

      final success = await FirebaseFirestore.instance.runTransaction((transaction) async {
        final roomRef = FirebaseFirestore.instance.collection('game_rooms').doc(roomCode);
        final roomSnapshot = await transaction.get(roomRef);
        if (!roomSnapshot.exists) throw Exception('Room does not exist');

        final roomData = roomSnapshot.data()!;
        if (roomData['status'] != 'finished') {
          // Préparer les scores finaux
          final Map<String, dynamic> finalScores = {};
          for (String playerId in _localScores.keys) {
            finalScores[playerId] = {
              "name": _players[playerId]?['name'] ?? "???",
              "score": _localScores[playerId] ?? 0,
            };
          }

          // Créer le résumé des questions pour la récitation
          final List<Map<String, dynamic>> minimalSummary = _localQuestions.map((q) {
            return {
              "question": q["reference"] ?? RecitationTranslations.t('recitation', language),
              "answer": q["text"] ?? "",
              "reference": q["reference"],
            };
          }).toList();

          // Sauvegarder dans game_results
          transaction.set(
              FirebaseFirestore.instance.collection("game_results").doc(roomCode),
              {
                "roomCode": roomCode,
                "scores": finalScores,
                "questionsSummary": minimalSummary,
                "finishedAt": FieldValue.serverTimestamp(),
              }
          );

          transaction.update(roomRef, {
            "status": "finished",
            "currentQuestionEndsAt": FieldValue.delete(),
            "revealedAnswer": FieldValue.delete(),
            "correctAnswerFound": FieldValue.delete(),
            "correctAnswerBy": FieldValue.delete(),
          });
          return true;
        }
        return false;
      });

      if (success) {
        print('✅ ${RecitationTranslations.t('game_over', language)} - Scores sauvegardés');

        final playersInRoom = _roomData['players'] as Map<String, dynamic>? ?? {};
        for (final playerId in playersInRoom.keys) {
          await FirebaseFirestore.instance
              .collection("users")
              .doc(playerId)
              .collection("rooms")
              .doc(roomCode)
              .update({"status": "finished"});
        }
      } else {
        print('ℹ️ Jeu déjà terminé par un autre joueur');
      }
    } catch (e) {
      print("❌ ${RecitationTranslations.t('error', language)} fin de jeu: $e");
    }
  }

  void _handleGameFinished() {
    if (isGameFinished) {
      _questionTimer?.cancel();
      _countdownTimer?.cancel();
      _stopListening();
      notifyListeners();
      print('🏁 ${RecitationTranslations.t('game_over', language)} - Navigation vers les résultats');
    }
  }

  Future<void> startGame() async {
    if (!_isHost) {
      print('⚠️ Seul l\'hôte peut démarrer le jeu');
      return;
    }
    if (_localQuestions.isEmpty) {
      print('❌ ${RecitationTranslations.t('error', language)}: Aucune question générée');
      return;
    }

    await FirebaseFirestore.instance.collection('game_rooms').doc(roomCode).update({
      'status': 'playing',
      'currentQuestionIndex': 0,
      'currentQuestionEndsAt': null,
    });

    _localCurrentQuestionIndex = 0;
    notifyListeners();
    print('🎮 ${RecitationTranslations.t('recitation_game', language)} démarrée');
  }

  @override
  void dispose() {
    print('🗑️ Nettoyage du controller multijoueur');
    _roomSubscription?.cancel();
    _questionTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}