import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/games/QCM/qcm_game_controller_base.dart';


class CustomQuestionsMultiplayerController extends QcmGameControllerBase {
  final String roomCode;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  StreamSubscription? _roomSubscription;
  Timer? _questionTimer;
  Timer? _countdownTimer;
  Map<String, dynamic> _roomData = {};
  bool _isInitialized = false;

  // Données locales
  List<Map<String, dynamic>> _localQuestions = [];
  int _localCurrentQuestionIndex = 0;
  Map<String, int> _localScores = {};
  Map<String, String> _localAnswers = {};

  // Getters
  Map<String, dynamic> get players => _roomData['players'] as Map<String, dynamic>? ?? {};
  List<dynamic> get questions => _roomData['questions'] as List<dynamic>? ?? [];
  String get hostId => _roomData['hostId'] ?? '';
  bool get _isHost => currentUserId == hostId;

  String? _correctAnswerWinnerId;
  String? _correctAnswerWinnerName;
  bool _showCorrectAnswerAnimation = false;

  String? get correctAnswerWinnerId => _correctAnswerWinnerId;
  String? get correctAnswerWinnerName => _correctAnswerWinnerName;
  bool get showCorrectAnswerAnimation => _showCorrectAnswerAnimation;

  CustomQuestionsMultiplayerController({required this.roomCode}) {
    _initializeAndListenToRoom();
  }

  Map<String, dynamic> get _currentQuestion {
    if (_localQuestions.isEmpty || _localCurrentQuestionIndex >= _localQuestions.length) {
      return {};
    }
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
    if (_localQuestions.isEmpty) return "Chargement des questions...";
    if (_roomData['status'] == 'waiting') return "En attente du démarrage...";
    if (_currentQuestion.isEmpty) return "Préparation de la question...";
    return _currentQuestion['question'] ?? "En attente...";
  }

  @override
  List<String> get options {
    final type = _currentQuestion['type'];

    if (type == 'qcm') {
      return List<String>.from(_currentQuestion['options'] ?? []);
    } else if (type == 'vraiFaux') {
      return ['Vrai', 'Faux'];
    }

    return [];
  }

  @override
  String get correctAnswer {
    final type = _currentQuestion['type'];

    switch (type) {
      case 'qcm':
        final options = List<String>.from(_currentQuestion['options'] ?? []);
        final correctIndex = _currentQuestion['correctAnswerIndex'] as int?;
        return (correctIndex != null && correctIndex < options.length)
            ? options[correctIndex]
            : '';

      case 'vraiFaux':
        final correctIndex = _currentQuestion['correctAnswerIndex'] as int?;
        return correctIndex == 1 ? 'Vrai' : 'Faux';

      case 'texteTrous':
        final text = _currentQuestion['question'].toString();
        final blankIndices = List<int>.from(_currentQuestion['blankIndices'] ?? []);
        final words = text.split(' ');
        return blankIndices.map((i) => words[i]).join(', ');

      case 'ouverte':
        return _currentQuestion['openAnswer']?.toString() ?? '';

      default:
        return _currentQuestion['answer'] ?? '';
    }
  }

  @override
  bool get isGameFinished => _roomData['status'] == 'finished';

  @override
  int get currentScore => _localScores[currentUserId] ?? 0;

  int get timeLeft {
    final endsAt = _roomData['currentQuestionEndsAt'] as Timestamp?;
    if (endsAt == null) return 30;

    final now = DateTime.now();
    final endTime = endsAt.toDate();
    final secondsLeft = endTime.difference(now).inSeconds;

    return secondsLeft.clamp(0, 30);
  }

  bool get iHaveAnswered => _localAnswers.containsKey('$_localCurrentQuestionIndex');

  // Type de question actuelle
  String get currentQuestionType => _currentQuestion['type'] ?? 'qcm';

  // Pour texte à trous
  List<int> get blankIndices => List<int>.from(_currentQuestion['blankIndices'] ?? []);

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

      if (_roomData['status'] == 'playing' || _roomData['status'] == 'started') {
        Future.delayed(const Duration(milliseconds: 800), () {
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

        _roomData = newRoomData;

        final newQuestionIndex = newRoomData['currentQuestionIndex'] ?? 0;
        if (newQuestionIndex != _localCurrentQuestionIndex) {
          _localCurrentQuestionIndex = newQuestionIndex;
          _questionTimer?.cancel();
          _countdownTimer?.cancel();

          if (newRoomData['currentQuestionEndsAt'] != null) {
            _startLocalCountdown();
          }
        }

        _syncScores();

        if (_roomData['status'] == 'playing') {
          if (previousStatus != 'playing' && _roomData['currentQuestionEndsAt'] != null) {
            _startLocalCountdown();
          }
          _manageGameLogic();
        }

        final currentCorrectAnswerFound = newRoomData['correctAnswerFound'] ?? false;
        if (!previousCorrectAnswerFound && currentCorrectAnswerFound && _roomData['status'] == 'playing') {
          final correctAnswerBy = _roomData['correctAnswerBy'] ?? 'unknown';
          final winnerName = players[correctAnswerBy]?['name'] ?? 'Joueur inconnu';

          setCorrectAnswerWinner(correctAnswerBy, winnerName);

          if (correctAnswerBy != currentUserId) {
            _endCurrentQuestion(forceTimeout: false);
          }
        }

        if (_roomData['status'] == 'finished') {
          _handleGameFinished();
        }

        notifyListeners();
      }
    });
  }

  void setCorrectAnswerWinner(String winnerId, String winnerName) {
    _correctAnswerWinnerId = winnerId;
    _correctAnswerWinnerName = winnerName;
    _showCorrectAnswerAnimation = true;
    notifyListeners();

    Future.delayed(const Duration(seconds: 2), () {
      _showCorrectAnswerAnimation = false;
      notifyListeners();
    });
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

    if ((status == 'playing' || status == 'started') && currentQuestionEndsAt == null && !correctAnswerFound) {
      _startQuestionTimer();
    }

    if ((status == 'playing' || status == 'started') && timeLeft <= 0 && currentQuestionEndsAt != null && !correctAnswerFound) {
      _endCurrentQuestion(forceTimeout: true);
    }
  }

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    _countdownTimer?.cancel();

    final endsAt = DateTime.now().add(const Duration(seconds: 30));

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
      if (timerCreated == true) {
        _startLocalCountdown();

        _questionTimer = Timer(const Duration(seconds: 31), () {
          if (!isGameFinished && _roomData['status'] != 'answered') {
            _endCurrentQuestion(forceTimeout: true);
          }
        });
      } else if (timerCreated == false) {
        _startLocalCountdown();
      }
    }).catchError((error) {
      print('❌ Error in transaction: $error');
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
  }

  Future<void> _endCurrentQuestion({bool forceTimeout = false}) async {
    _questionTimer?.cancel();
    _countdownTimer?.cancel();

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final roomRef = FirebaseFirestore.instance.collection('game_rooms').doc(roomCode);
        final roomSnapshot = await transaction.get(roomRef);

        if (!roomSnapshot.exists) throw Exception('Room does not exist');

        final roomData = roomSnapshot.data()!;

        if (roomData['status'] != 'answered') {
          final correctAnswerBy = roomData['correctAnswerBy'];
          final winnerName = correctAnswerBy != null
              ? (players[correctAnswerBy]?['name'] ?? 'Joueur inconnu')
              : null;

          transaction.update(roomRef, {
            'status': 'answered',
            'revealedAnswer': correctAnswer,
            'timeout': forceTimeout,
            'endReason': forceTimeout ? 'timeout' : 'correct_answer',
            if (winnerName != null) 'winnerName': winnerName,
          });

          return true;
        }
        return false;
      });

      Timer(const Duration(seconds: 3), () {
        _attemptNextQuestion();
      });
    } catch (e) {
      print('❌ Error ending question: $e');
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
            'timeout': FieldValue.delete(),
            'correctAnswerFound': FieldValue.delete(),
            'correctAnswerBy': FieldValue.delete(),
          });
          return true;
        }
        return false;
      });
    } else {
      _attemptEndGame();
    }
  }

  // ✅ MÉTHODE SPÉCIALE POUR TEXTE À TROUS
  Future<void> submitTexteTrousAnswer(Map<int, String> userAnswers) async {
    if (isLoading || iHaveAnswered || isGameFinished) return;
    if (_roomData['status'] == 'answered') return;

    _localAnswers['$_localCurrentQuestionIndex'] = 'answered';

    final text = _currentQuestion['question'].toString();
    final words = text.split(' ');
    final blankIndices = this.blankIndices;

    bool allCorrect = true;
    for (var index in blankIndices) {
      if (userAnswers[index]?.trim().toLowerCase() != words[index].toLowerCase()) {
        allCorrect = false;
        break;
      }
    }

    final points = allCorrect ? timeLeft : 0;
    _localScores[currentUserId] = (_localScores[currentUserId] ?? 0) + points;

    await FirebaseFirestore.instance.collection('game_rooms').doc(roomCode).update({
      'players.$currentUserId.score': FieldValue.increment(points),
    });

    if (allCorrect) {
      await FirebaseFirestore.instance.collection('game_rooms').doc(roomCode).update({
        'correctAnswerFound': true,
        'correctAnswerBy': currentUserId,
      });
      _endCurrentQuestion(forceTimeout: false);
    }

    notifyListeners();
  }

  // ✅ MÉTHODE SPÉCIALE POUR QUESTIONS OUVERTES
  Future<void> submitOpenAnswer(String userAnswer) async {
    if (isLoading || iHaveAnswered || isGameFinished) return;
    if (_roomData['status'] == 'answered') return;

    _localAnswers['$_localCurrentQuestionIndex'] = userAnswer;

    final isCorrect = userAnswer.trim().toLowerCase() == correctAnswer.toLowerCase();
    final points = isCorrect ? timeLeft : 0;

    _localScores[currentUserId] = (_localScores[currentUserId] ?? 0) + points;

    await FirebaseFirestore.instance.collection('game_rooms').doc(roomCode).update({
      'players.$currentUserId.score': FieldValue.increment(points),
    });

    if (isCorrect) {
      await FirebaseFirestore.instance.collection('game_rooms').doc(roomCode).update({
        'correctAnswerFound': true,
        'correctAnswerBy': currentUserId,
      });
      _endCurrentQuestion(forceTimeout: false);
    }

    notifyListeners();
  }

  @override
  void submitAnswer(String answer) {
    if (isLoading || iHaveAnswered || isGameFinished) return;
    if (_roomData['status'] == 'answered') return;

    _localAnswers['$_localCurrentQuestionIndex'] = answer;

    final isCorrect = answer.toLowerCase().trim() == correctAnswer.toLowerCase().trim();
    final points = isCorrect ? timeLeft : 0;

    _localScores[currentUserId] = (_localScores[currentUserId] ?? 0) + points;

    FirebaseFirestore.instance.collection('game_rooms').doc(roomCode).update({
      'players.$currentUserId.score': FieldValue.increment(points),
    });

    if (isCorrect) {
      FirebaseFirestore.instance.collection('game_rooms').doc(roomCode).update({
        'correctAnswerFound': true,
        'correctAnswerBy': currentUserId,
      }).then((_) {
        _endCurrentQuestion(forceTimeout: false);
      });
    }

    notifyListeners();
  }

  Future<void> _attemptEndGame() async {
    if (isGameFinished) return;

    _questionTimer?.cancel();
    _countdownTimer?.cancel();

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final roomRef = FirebaseFirestore.instance.collection('game_rooms').doc(roomCode);
      final roomSnapshot = await transaction.get(roomRef);

      if (!roomSnapshot.exists) throw Exception('Room does not exist');

      final roomData = roomSnapshot.data()!;

      if (roomData['status'] != 'finished') {
        final Map<String, dynamic> finalScores = {};
        for (String playerId in _localScores.keys) {
          finalScores[playerId] = {
            "name": players[playerId]?['name'] ?? "???",
            "score": _localScores[playerId] ?? 0,
          };
        }

        final List<Map<String, dynamic>> minimalSummary = _localQuestions.map((q) {
          return {
            "question": q["question"],
            "answer": _getAnswerForSummary(q),
            "type": q["type"],
            "reference": q["reference"] ?? "",
          };
        }).toList();

        transaction.set(
          FirebaseFirestore.instance.collection("game_results").doc(roomCode),
          {
            "roomCode": roomCode,
            "scores": finalScores,
            "questionsSummary": minimalSummary,
            "finishedAt": FieldValue.serverTimestamp(),
          },
        );

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
  }

  String _getAnswerForSummary(Map<String, dynamic> question) {
    final type = question['type'];

    switch (type) {
      case 'qcm':
        final options = List<String>.from(question['options'] ?? []);
        final correctIndex = question['correctAnswerIndex'] as int?;
        return (correctIndex != null && correctIndex < options.length)
            ? options[correctIndex]
            : '';

      case 'vraiFaux':
        final correctIndex = question['correctAnswerIndex'] as int?;
        return correctIndex == 1 ? 'Vrai' : 'Faux';

      case 'texteTrous':
        final text = question['question'].toString();
        final blankIndices = List<int>.from(question['blankIndices'] ?? []);
        final words = text.split(' ');
        return blankIndices.map((i) => words[i]).join(', ');

      case 'ouverte':
        return question['openAnswer']?.toString() ?? '';

      default:
        return question['answer'] ?? '';
    }
  }

  void _handleGameFinished() {
    if (isGameFinished) {
      _questionTimer?.cancel();
      _countdownTimer?.cancel();
      notifyListeners();
    }
  }

  @override
  void loadNextQuestion() {
    _attemptNextQuestion();
  }

  @override
  int get maxScore => 100;

  @override
  void restartGame() {
    // Non implémenté pour les questions personnalisées
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _questionTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}