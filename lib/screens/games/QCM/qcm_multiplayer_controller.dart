import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:memoriz_bible/screens/games/QCM/qcm_game_controller_base.dart';
import '../../../models/verse_model.dart';
import 'package:flutter/material.dart';

class QcmMultiplayerController extends QcmGameControllerBase {
  final String roomCode;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  StreamSubscription? _roomSubscription;
  Timer? _questionTimer;
  Timer? _countdownTimer;
  Map<String, dynamic> _roomData = {};
  bool _isInitialized = false;

  // ✅ PASTE THE NEW GETTERS HERE
  Map<String, dynamic> get players => _roomData['players'] as Map<String, dynamic>? ?? {};
  List<dynamic> get questions => _roomData['questions'] as List<dynamic>? ?? [];
  // === DONNÉES LOCALES ===
  List<Map<String, dynamic>> _localQuestions = [];
  int _localCurrentQuestionIndex = 0;
  Map<String, int> _localScores = {};
  Map<String, String> _localAnswers = {};

  String get endReason => _roomData['endReason'] ?? 'unknown';
  String? get winnerName => _roomData['winnerName'];
  bool get endedByTimeout => endReason == 'timeout';
  bool get endedByCorrectAnswer => endReason == 'correct_answer';


  // Add these missing properties:
  String? _correctAnswerWinnerId;
  String? _correctAnswerWinnerName;
  bool _showCorrectAnswerAnimation = false;

  // Getters for the properties
  String? get correctAnswerWinnerId => _correctAnswerWinnerId;
  String? get correctAnswerWinnerName => _correctAnswerWinnerName;
  bool get showCorrectAnswerAnimation => _showCorrectAnswerAnimation;

  // Method to set the winner information (call this when you receive the correct answer data)
  void setCorrectAnswerWinner(String winnerId, String winnerName) {
    _correctAnswerWinnerId = winnerId;
    _correctAnswerWinnerName = winnerName;
    _showCorrectAnswerAnimation = true;
    notifyListeners();

    // Hide animation after some delay
    Future.delayed(const Duration(seconds: 2), () {
      _showCorrectAnswerAnimation = false;
      notifyListeners();
    });
  }

  // Method to hide animation manually if needed
  void hideAnimation() {
    _showCorrectAnswerAnimation = false;
    notifyListeners();
  }


  QcmMultiplayerController({
    required this.roomCode,
  }) {
    _initializeAndListenToRoom();
  }

  // === GETTERS ===
  String get _hostId => _roomData['hostId'] ?? '';
  bool get _isHost => currentUserId == _hostId;
  String get hostId => _roomData['hostId'] ?? '';
  Map<String, dynamic> get _players => _roomData['players'] as Map<String, dynamic>? ?? {};
  bool get questionAlreadyAnswered => _roomData['status'] == 'answered' || _roomData['revealedAnswer'] != null;

  List<dynamic> get _questions => _localQuestions;
  int get _currentQuestionIndex => _localCurrentQuestionIndex;

  Map<String, dynamic> get _currentQuestion {
    if (_localQuestions.isEmpty || _localCurrentQuestionIndex >= _localQuestions.length) return {};
    return _localQuestions[_localCurrentQuestionIndex];
  }
  @override
  String get status => _roomData['status'] ?? 'loading';
  @override
  bool get isLoading => !_isInitialized || _localQuestions.isEmpty;

  @override
  String get questionText {
    if (!_isInitialized) return "Initialisation...";
    if (_roomData.isEmpty) return "Connexion à la partie...";
    if (_localQuestions.isEmpty) return "L'hôte prépare les questions...";
    if (_roomData['status'] == 'waiting') return "En attente du démarrage...";
    if (_currentQuestion.isEmpty) return "Préparation de la question...";
    return _currentQuestion['question'] ?? "En attente...";
  }

  @override
  List<String> get options => List<String>.from(_currentQuestion['options'] ?? []);

  @override
  String get correctAnswer => _currentQuestion['answer'] ?? "";

  @override
  bool get isGameFinished => _roomData['status'] == 'finished';

  @override
  int get currentScore => _localScores[currentUserId] ?? 0;

  int get timeLeft {
    final endsAt = _roomData['currentQuestionEndsAt'] as Timestamp?;
    if (endsAt == null) return 20; // Temps par défaut

    final now = DateTime.now();
    final endTime = endsAt.toDate();
    final secondsLeft = endTime.difference(now).inSeconds;

    return secondsLeft.clamp(0, 20);
  }

  bool get iHaveAnswered => _localAnswers.containsKey('$_localCurrentQuestionIndex');

  String? get myLastAnswer => _localAnswers['$_localCurrentQuestionIndex'];

  List<MapEntry<String, int>> get playerRanking {
    return _localScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  // === FIRESTORE INIT ===
  Future<void> _initializeAndListenToRoom() async {
    try {
      final roomSnapshot = await FirebaseFirestore.instance
          .collection('game_rooms')
          .doc(roomCode)
          .get();

      if (!roomSnapshot.exists) {
        print('❌ Room $roomCode does not exist');
        return;
      }

      _roomData = roomSnapshot.data()!;
      _isInitialized = true;

      final List<dynamic> qList = _roomData['questions'] ?? [];
      _localQuestions = qList.map((q) => Map<String, dynamic>.from(q)).toList();

      final players = _roomData['players'] as Map<String, dynamic>? ?? {};
      for (String playerId in players.keys) {
        _localScores[playerId] = players[playerId]['score'] ?? 0;
      }

      _localCurrentQuestionIndex = _roomData['currentQuestionIndex'] ?? 0;

      _listenToRoom();

      // Vérifier l'état initial et démarrer la logique
      print('🎮 Initial room status: ${_roomData['status']}');
      print('🎮 Initial timer: ${_roomData['currentQuestionEndsAt']}');

      if (_roomData['status'] == 'playing' || _roomData['status'] == 'started') {
        // Attendre que _listenToRoom s'initialise
        Future.delayed(const Duration(milliseconds: 800), () {
          print('🎮 Calling initial _manageGameLogic...');
          _manageGameLogic();
        });
      }

      notifyListeners();
    } catch (e) {
      print('❌ ERROR initializing room: $e');
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
        final previousCorrectAnswerFound = _roomData['correctAnswerFound'] ?? false;

        // Debug: Log des changements importants
        if (newRoomData['correctAnswerFound'] != _roomData['correctAnswerFound']) {
          print('🔍 DEBUG: correctAnswerFound changed from ${_roomData['correctAnswerFound']} to ${newRoomData['correctAnswerFound']}');
        }

        if (newRoomData['status'] != _roomData['status']) {
          print('🔍 DEBUG: status changed from ${_roomData['status']} to ${newRoomData['status']}');
        }

        _roomData = newRoomData;

        // Vérifier si l'index de question a changé
        final newQuestionIndex = newRoomData['currentQuestionIndex'] ?? 0;
        if (newQuestionIndex != _localCurrentQuestionIndex) {
          _localCurrentQuestionIndex = newQuestionIndex;
          print('🔄 Question index updated to: $_localCurrentQuestionIndex');

          // Réinitialiser les timers pour la nouvelle question
          _questionTimer?.cancel();
          _countdownTimer?.cancel();

          // Si on a un timer dans les nouvelles données, démarrer le countdown local
          if (newRoomData['currentQuestionEndsAt'] != null) {
            _startLocalCountdown();
          }
        }

        // Synchroniser les scores
        _syncScores();

        // Gérer la logique du jeu pour TOUS les joueurs à chaque changement
        if (_roomData['status'] == 'playing') {
          // Si on vient de passer en "playing" et qu'il y a un timer, démarrer le countdown pour tous
          if (previousStatus != 'playing' && _roomData['currentQuestionEndsAt'] != null) {
            print('🎮 Status changed to playing, starting local countdown for all players');
            _startLocalCountdown();
          }

          // Appeler la logique du jeu à chaque changement
          _manageGameLogic();
        }

        // Détecter immédiatement si une bonne réponse a été trouvée
        final currentCorrectAnswerFound = newRoomData['correctAnswerFound'] ?? false;
        if (!previousCorrectAnswerFound && currentCorrectAnswerFound && _roomData['status'] == 'playing') {
          final correctAnswerBy = _roomData['correctAnswerBy'] ?? 'unknown';
          final winnerName = _players[correctAnswerBy]?['name'] ?? 'Joueur inconnu';

          print('🎯 IMMEDIATE: Correct answer detected by $correctAnswerBy ($winnerName) - ending question now! (Player: $currentUserId)');

          // Afficher l'animation du gagnant pour tous les joueurs
          setCorrectAnswerWinner(correctAnswerBy, winnerName);

          // Vérifier que ce n'est pas le joueur qui a trouvé la réponse pour éviter les doublons
          if (correctAnswerBy != currentUserId) {
            _endCurrentQuestion(forceTimeout: false);
          } else {
            print('ℹ️ This player already triggered end question, skipping duplicate');
          }
        }

        // Pour tous les joueurs : vérifier si le jeu est terminé
        if (_roomData['status'] == 'finished') {
          _handleGameFinished();
        }

        notifyListeners();
      }
    }, onError: (error) {
      print('❌ ERROR listening to room: $error');
    });
  }
  void _syncScores() {
    final players = _roomData['players'] as Map<String, dynamic>? ?? {};
    for (String playerId in players.keys) {
      _localScores[playerId] = players[playerId]['score'] ?? 0;
    }
  }

  // 🔄 CHANGEMENT : Renommé de _manageHostLogic à _manageGameLogic
  // et maintenant accessible à tous les joueurs
  void _manageGameLogic() {
    if (_localQuestions.isEmpty || isGameFinished) return;

    final status = _roomData['status'];
    final currentQuestionEndsAt = _roomData['currentQuestionEndsAt'];
    final correctAnswerFound = _roomData['correctAnswerFound'] ?? false;

    print('🎯 Game logic - Status: $status, EndsAt: $currentQuestionEndsAt, TimeLeft: $timeLeft, CorrectFound: $correctAnswerFound, Player: $currentUserId, IsHost: $_isHost');

    // CHANGE CETTE LIGNE ⬇️
    if ((status == 'playing' || status == 'started') && currentQuestionEndsAt == null && !correctAnswerFound) {
      print('⏰ No timer found, attempting to start new timer... (Player: $currentUserId)');
      _startQuestionTimer();
    }

    // CHANGE AUSSI CETTE LIGNE ⬇️
    if ((status == 'playing' || status == 'started') && timeLeft <= 0 && currentQuestionEndsAt != null && !correctAnswerFound) {
      print('⏰ Time expired! Ending question... (detected by $currentUserId)');
      _endCurrentQuestion(forceTimeout: true);
    }
  }

  Future<void> startGame() async {
    if (!_isHost) return;
    if (_localQuestions.isEmpty) {
      print('❌ Cannot start game: no questions generated');
      return;
    }

    print('🎮 Starting game...');

    await FirebaseFirestore.instance.collection('game_rooms').doc(roomCode).update({
      'status': 'playing',
      'currentQuestionIndex': 0,
      'currentQuestionEndsAt': null,
    });

    _localCurrentQuestionIndex = 0;
    notifyListeners();

    // Démarrer le timer après que le statut soit mis à jour
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_roomData['status'] == 'playing' && _roomData['currentQuestionEndsAt'] == null) {
        print('🎮 Starting timer after game start...');
        _startQuestionTimer();
      }
    });
  }
  void _startQuestionTimer() {
    print('⏰ Attempting to start question timer for question $_localCurrentQuestionIndex (Player: $currentUserId)');

    _questionTimer?.cancel();
    _countdownTimer?.cancel();

    final endsAt = DateTime.now().add(const Duration(seconds: 20));

    FirebaseFirestore.instance.runTransaction((transaction) async {
      final roomRef = FirebaseFirestore.instance.collection('game_rooms').doc(roomCode);
      final roomSnapshot = await transaction.get(roomRef);

      if (!roomSnapshot.exists) {
        throw Exception('Room does not exist');
      }

      final roomData = roomSnapshot.data()!;

      // Vérifier si un timer n'existe pas déjà
      if (roomData['currentQuestionEndsAt'] == null) {
        transaction.update(roomRef, {
          'currentQuestionEndsAt': Timestamp.fromDate(endsAt),
          'status': 'playing',
        });
        print('✅ Transaction: Timer will be created by $currentUserId');
        return true;
      } else {
        print('ℹ️ Transaction: Timer already exists');
        return false;
      }
    }).then((timerCreated) {
      print('🔍 Transaction result: timerCreated = $timerCreated (Player: $currentUserId)');

      if (timerCreated == true) {
        print('✅ Timer created successfully by player $currentUserId');
        _startLocalCountdown();

        _questionTimer = Timer(const Duration(seconds: 21), () {
          print('⏰ Timer expired for question $_localCurrentQuestionIndex (Player: $currentUserId)');
          if (!isGameFinished && _roomData['status'] != 'answered') {
            _endCurrentQuestion(forceTimeout: true);
          }
        });
      } else if (timerCreated == false) {
        print('ℹ️ Timer already exists, starting local countdown only (Player: $currentUserId)');
        _startLocalCountdown();
      }
    }).catchError((error) {
      print('❌ Error in transaction (Player: $currentUserId): $error');
      // En cas d'erreur, réessayer après 1 seconde
      Future.delayed(const Duration(seconds: 1), () {
        if (_roomData['currentQuestionEndsAt'] == null && _roomData['status'] == 'playing') {
          print('🔄 Retrying timer creation after error...');
          _startQuestionTimer();
        }
      });
    });
  }

  void _startLocalCountdown() {
    print('⏱️ Starting local countdown timer (Player: $currentUserId)');
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentTimeLeft = timeLeft;
      print('⏱️ Local countdown tick - Time left: $currentTimeLeft (Player: $currentUserId)');

      // Si le temps est écoulé, arrêter le timer
      if (currentTimeLeft <= 0) {
        timer.cancel();
        print('⏱️ Local countdown finished (Player: $currentUserId)');
      }

      notifyListeners(); // Force l'UI à se mettre à jour
    });
  }

  Future<void> _endCurrentQuestion({bool forceTimeout = false}) async {
    print('🔚 Attempting to end current question $_localCurrentQuestionIndex (timeout: $forceTimeout, Player: $currentUserId)');

    _questionTimer?.cancel();
    _countdownTimer?.cancel();

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final roomRef = FirebaseFirestore.instance.collection('game_rooms').doc(roomCode);
        final roomSnapshot = await transaction.get(roomRef);

        if (!roomSnapshot.exists) {
          throw Exception('Room does not exist');
        }

        final roomData = roomSnapshot.data()!;

        // Vérifier si la question n'est pas déjà terminée
        if (roomData['status'] != 'answered') {
          // Récupérer le nom du gagnant si c'est une bonne réponse
          final correctAnswerBy = roomData['correctAnswerBy'];
          final winnerName = correctAnswerBy != null
              ? (_players[correctAnswerBy]?['name'] ?? 'Joueur inconnu')
              : null;

          // Mettre à jour avec toutes les infos nécessaires
          transaction.update(roomRef, {
            'status': 'answered',
            'revealedAnswer': correctAnswer,
            'timeout': forceTimeout,
            'endReason': forceTimeout ? 'timeout' : 'correct_answer',
            if (winnerName != null) 'winnerName': winnerName,
          });

          print('✅ Question ended successfully by player $currentUserId (reason: ${forceTimeout ? "timeout" : "correct_answer"})');
          return true;
        } else {
          print('ℹ️ Question already ended by another player');
          return false;
        }
      });

      // Attendre quelques secondes pour montrer la réponse, puis passer à la suivante
      Timer(const Duration(seconds: 3), () {
        _attemptNextQuestion();
      });
    } catch (e) {
      print('❌ Error ending question (Player: $currentUserId): $e');
    }
  }

// Dans le fichier QcmMultiplayerController.dart

// CORRECT 👍
  void _attemptNextQuestion() {
    if (isGameFinished) return;

    print('➡️ Attempting to move to next question from $_localCurrentQuestionIndex (Player: $currentUserId)');

    // ✅ CORRECTION : On vérifie si l'index actuel EST le dernier index possible.
    // Si ce n'est pas le cas, on passe au suivant.
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
            'timeout': FieldValue.delete(),
            'correctAnswerFound': FieldValue.delete(),
            'correctAnswerBy': FieldValue.delete(),
          });
          return true;
        }
        return false;
      }).then((success) {
        if (success) {
          print('✅ Successfully moved to question $newIndex (Player: $currentUserId)');
        } else {
          print('ℹ️ Another player already moved to next question (Player: $currentUserId)');
        }
      }).catchError((error) {
        print('❌ Error moving to next question (Player: $currentUserId): $error');
      });
    } else {
      // Si on a fini la dernière question (index 2 pour 3 questions), on termine le jeu.
      print('🏁 Last question finished - attempting to end game (Player: $currentUserId)');
      _attemptEndGame();
    }
  }

  @override
  void submitAnswer(String answer) {
    if (isLoading || iHaveAnswered || isGameFinished) {
      print('🚫 Cannot submit answer - Loading: $isLoading, Already answered: $iHaveAnswered, Game finished: $isGameFinished');
      return;
    }

    // Vérifier si la question n'est pas déjà terminée
    if (_roomData['status'] == 'answered') {
      print('🚫 Cannot submit answer - Question already answered');
      return;
    }

    print('📝 Submitting answer: $answer for question $_localCurrentQuestionIndex by user: $currentUserId');

    _localAnswers['$_localCurrentQuestionIndex'] = answer;

    final isCorrect = answer.toLowerCase().trim() == correctAnswer.toLowerCase().trim();
    final points = isCorrect ? timeLeft : 0;

    print('✅ Answer correct: $isCorrect, Points: $points, Time left: $timeLeft');

    // Mettre à jour le score local immédiatement
    _localScores[currentUserId] = (_localScores[currentUserId] ?? 0) + points;

    // Sauvegarder dans Firestore
    FirebaseFirestore.instance.collection('game_rooms').doc(roomCode).update({
      'players.$currentUserId.answers.$_localCurrentQuestionIndex': answer,
      'players.$currentUserId.score': FieldValue.increment(points),
    }).then((_) {
      print('✅ Answer saved to Firestore for user: $currentUserId');
    }).catchError((error) {
      print('❌ Error saving answer to Firestore: $error');
    });

    // 🔄 CHANGEMENT : Tous les joueurs peuvent signaler une bonne réponse
    if (isCorrect) {
      print('🎯 Correct answer found by $currentUserId - signaling to all players');
      FirebaseFirestore.instance.collection('game_rooms').doc(roomCode).update({
        'correctAnswerFound': true,
        'correctAnswerBy': currentUserId,
      }).then((_) {
        print('✅ Signal sent about correct answer by $currentUserId');
        // 🔄 NOUVEAU : Appeler directement la fin de question après avoir envoyé le signal
        // pour éviter d'attendre le snapshot Firestore
        _endCurrentQuestion(forceTimeout: false);
      }).catchError((error) {
        print('❌ Error signaling correct answer: $error');
      });
    }

    notifyListeners();
  }

  Future<void> goToNextQuestion() async {
    // 🔄 CHANGEMENT : Tous les joueurs peuvent tenter de passer à la question suivante
    if (isGameFinished) return;
    _attemptNextQuestion();
  }

  void _handleGameFinished() {
    if (isGameFinished) {
      print('🏁 Game finished - cleaning up timers and notifying UI (Player: $currentUserId)');
      _questionTimer?.cancel();
      _countdownTimer?.cancel();

      // Forcer une notification pour que l'UI détecte le changement
      notifyListeners();

      // L'UI devrait automatiquement naviguer vers la page de résultats
      // en détectant que isGameFinished est true
    }
  }

  // 🔄 CHANGEMENT : Nouvelle méthode pour que tous les joueurs puissent tenter de terminer le jeu
  Future<void> _attemptEndGame() async {
    if (isGameFinished) return;

    try {
      print('🏁 Attempting to end game... (Player: $currentUserId)');

      _questionTimer?.cancel();
      _countdownTimer?.cancel();

      // Utiliser une transaction pour éviter les doublons
      final success = await FirebaseFirestore.instance.runTransaction((transaction) async {
        final roomRef = FirebaseFirestore.instance.collection('game_rooms').doc(roomCode);
        final roomSnapshot = await transaction.get(roomRef);

        if (!roomSnapshot.exists) {
          throw Exception('Room does not exist');
        }

        final roomData = roomSnapshot.data()!;

        // Vérifier si le jeu n'est pas déjà terminé
        if (roomData['status'] != 'finished') {
          final Map<String, dynamic> finalScores = {};
          for (String playerId in _localScores.keys) {
            finalScores[playerId] = {
              "name": _players[playerId]?['name'] ?? "???",
              "score": _localScores[playerId] ?? 0,
            };
          }

          final List<Map<String, dynamic>> minimalSummary = _localQuestions.map((q) {
            return {
              "question": q["question"],
              "answer": q["answer"],
            };
          }).toList();

          // Sauvegarder les résultats
          transaction.set(
              FirebaseFirestore.instance.collection("game_results").doc(roomCode),
              {
                "roomCode": roomCode,
                "scores": finalScores,
                "questionsSummary": minimalSummary,
                "finishedAt": FieldValue.serverTimestamp(),
              }
          );

          // Marquer la room comme terminée
          transaction.update(roomRef, {
            "status": "finished",
            "currentQuestionEndsAt": FieldValue.delete(),
            "revealedAnswer": FieldValue.delete(),
            "timeout": FieldValue.delete(),
            "correctAnswerFound": FieldValue.delete(),
            "correctAnswerBy": FieldValue.delete(),
          });

          return true;
        }
        return false;
      });

      if (success) {
        print("✅ Game ended successfully by player $currentUserId");

        // Mettre à jour le statut pour tous les joueurs
        final playersInRoom = _roomData['players'] as Map<String, dynamic>? ?? {};
        for (final playerId in playersInRoom.keys) {
          FirebaseFirestore.instance
              .collection("users")
              .doc(playerId)
              .collection("rooms")
              .doc(roomCode)
              .update({"status": "finished"})
              .catchError((error) {
            print('❌ Error updating user room status for $playerId: $error');
          });
        }
      } else {
        print("ℹ️ Game already ended by another player");
      }
    } catch (e) {
      print("❌ ERROR in _attemptEndGame (Player: $currentUserId): $e");
    }
  }

  Future<void> endGame() async {
    // 🔄 CHANGEMENT : Tous les joueurs peuvent tenter de terminer le jeu
    await _attemptEndGame();
  }

  @override
  void loadNextQuestion() {
    // 🔄 CHANGEMENT : Tous les joueurs peuvent charger la question suivante
    goToNextQuestion();
  }

  @override
  int get maxScore => 100;



  @override
  void restartGame() {
    _localCurrentQuestionIndex = 0;
    _localAnswers.clear();
    _localScores.clear();

    final players = _roomData['players'] as Map<String, dynamic>? ?? {};
    for (String playerId in players.keys) {
      _localScores[playerId] = 0;
    }

    if (_isHost) {
      FirebaseFirestore.instance.collection('game_rooms').doc(roomCode).update({
        'status': 'waiting',
        'currentQuestionIndex': 0,
        'currentQuestionEndsAt': null,
        'revealedAnswer': FieldValue.delete(),
        'timeout': FieldValue.delete(),
      });
    }

    notifyListeners();
  }

  @override
  void dispose() {
    print('🗑️ Disposing QcmMultiplayerController (Player: $currentUserId)');
    _roomSubscription?.cancel();
    _questionTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}



