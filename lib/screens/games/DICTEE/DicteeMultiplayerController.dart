import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../services/Bible_service.dart';
import '../../../services/tts_service.dart';
import '../../../models/language_provider.dart';
import 'package:provider/provider.dart';

class DicteeMultiplayerController extends ChangeNotifier {
  final String roomCode;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final String language;

  StreamSubscription? _roomSubscription;
  Timer? _questionTimer;
  Timer? _countdownTimer;
  Map<String, dynamic> _roomData = {};
  bool _isInitialized = false;

  // Données locales
  List<Map<String, dynamic>> _localQuestions = [];
  int _localCurrentQuestionIndex = 0;
  Map<String, int> _localScores = {};

  // État de dictée
  final TtsService _ttsService = TtsService();
  final TextEditingController _textController = TextEditingController();
  bool _isVerifying = false;
  bool _hasSubmitted = false;

  // ❌ CHRONOMÈTRE LOCAL RETIRÉ - Variables supprimées

  // Getters
  String get _hostId => _roomData['hostId'] ?? '';
  bool get _isHost => currentUserId == _hostId;
  Map<String, dynamic> get _players => _roomData['players'] as Map<String, dynamic>? ?? {};
  int get localCurrentQuestionIndex => _localCurrentQuestionIndex;
  Map<String, dynamic> get _currentQuestion {
    if (_localQuestions.isEmpty || _localCurrentQuestionIndex >= _localQuestions.length) return {};
    return _localQuestions[_localCurrentQuestionIndex];
  }

  // Getters publics
  bool get isLoading => !_isInitialized || _localQuestions.isEmpty;
  bool get isGameFinished => _roomData['status'] == 'finished';
  int get currentScore => _localScores[currentUserId] ?? 0;
  String get status => _roomData['status'] ?? 'loading';
  String? get currentReference => _currentQuestion['reference'];
  String get correctText => _currentQuestion['text'] ?? '';
  bool get isVerifying => _isVerifying;
  bool get hasSubmitted => _hasSubmitted;
  TextEditingController get textController => _textController;

  // ❌ CHRONOMÈTRE LOCAL RETIRÉ - Getters supprimés

  // Propriétés multijoueur
  Map<String, dynamic> get players => _players;
  List<dynamic> get questions => _localQuestions;
  bool get questionAlreadyAnswered => _roomData['status'] == 'answered' || _roomData['correctAnswerFound'] == true;
  String? get correctAnswerWinnerId => _roomData['correctAnswerBy'];
  String? get correctAnswerWinnerName {
    final winnerId = correctAnswerWinnerId;
    if (winnerId != null && _players.containsKey(winnerId)) {
      return _players[winnerId]['name'] ?? 'Joueur inconnu';
    }
    return null;
  }

  int get globalTimeLeft {
    final endsAt = _roomData['currentQuestionEndsAt'] as Timestamp?;
    if (endsAt == null) return 120;

    final now = DateTime.now();
    final endTime = endsAt.toDate();
    final secondsLeft = endTime.difference(now).inSeconds;

    return secondsLeft.clamp(0, 120);
  }

  List<MapEntry<String, int>> get playerRanking {
    return _localScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  DicteeMultiplayerController({
    required this.roomCode,
    required this.language,
  }) {
    _initializeAndListenToRoom();
  }

  Future<void> _initializeAndListenToRoom() async {
    try {
      _ttsService.setCompletionHandler(() {
        if (mounted) {
          print('🔊 Lecture terminée');
          notifyListeners();
        }
      });

      final roomSnapshot = await FirebaseFirestore.instance
          .collection('game_rooms')
          .doc(roomCode)
          .get();

      if (!roomSnapshot.exists) {
        print('Room $roomCode does not exist');
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
      notifyListeners();
    } catch (e) {
      print('ERROR initializing room: $e');
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
        }

        _syncScores();

        if (_roomData['status'] == 'playing' || _roomData['status'] == 'started') {
          if ((previousStatus != 'playing' && previousStatus != 'started') && _roomData['currentQuestionEndsAt'] != null) {
            _startGlobalCountdown();
          }
          _manageGameLogic();
        }

        final correctAnswerFound = newRoomData['correctAnswerFound'] ?? false;
        if (correctAnswerFound && _roomData['status'] == 'playing') {
          final correctAnswerBy = _roomData['correctAnswerBy'] ?? 'unknown';
          if (correctAnswerBy != currentUserId) {
            _endCurrentQuestion();
          }
        }

        if (_roomData['status'] == 'finished') {
          _handleGameFinished();
        }

        notifyListeners();
      }
    }, onError: (error) {
      print('ERROR listening to room: $error');
    });
  }

  void _resetForNewQuestion() {
    _textController.clear();
    _hasSubmitted = false;
    _isVerifying = false;
    _questionTimer?.cancel();
    _countdownTimer?.cancel();
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

    if ((status == 'playing' || status == 'started') && globalTimeLeft <= 0 && currentQuestionEndsAt != null && !correctAnswerFound) {
      _endCurrentQuestion();
    }
  }

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    _countdownTimer?.cancel();

    final endsAt = DateTime.now().add(const Duration(seconds: 120));

    FirebaseFirestore.instance.runTransaction((transaction) async {
      final roomRef = FirebaseFirestore.instance.collection('game_rooms').doc(roomCode);
      final roomSnapshot = await transaction.get(roomRef);

      if (!roomSnapshot.exists) {
        throw Exception('Room does not exist');
      }

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
        _startGlobalCountdown();
        _questionTimer = Timer(const Duration(seconds: 121), () {
          if (!isGameFinished && (_roomData['status'] == 'playing' || _roomData['status'] == 'started')) {
            _endCurrentQuestion();
          }
        });
      } else {
        _startGlobalCountdown();
      }
    }).catchError((error) {
      print('Error updating timer: $error');
    });
  }

  void _startGlobalCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentTimeLeft = globalTimeLeft;
      if (currentTimeLeft <= 0) {
        timer.cancel();
      }
      notifyListeners();
    });
  }

  Future<void> playVerse() async {
    if (_hasSubmitted || questionAlreadyAnswered || correctText.isEmpty) return;
    print('🔊 Lecture du verset (sans chronomètre local)');
    await _ttsService.speak(correctText);
  }

  // ❌ MÉTHODE _startLocalTimer COMPLÈTEMENT SUPPRIMÉE

  Future<void> submitAnswer() async {
    if (_textController.text.isEmpty || _hasSubmitted || questionAlreadyAnswered) return;
    await _verifyDictation();
  }

  Future<void> _verifyDictation() async {
    if (_textController.text.isEmpty || _hasSubmitted || questionAlreadyAnswered) return;

    _isVerifying = true;
    _hasSubmitted = true;
    notifyListeners();

    try {
      final score = await BibleService().getVerificationScore(
        _textController.text,
        correctText,
        language: language,
      );

      final isCorrect = score >= 70;

      int pointsEarned = 0;
      if (isCorrect) {
        pointsEarned = globalTimeLeft + 50;

        await FirebaseFirestore.instance.collection('game_rooms').doc(roomCode).update({
          'correctAnswerFound': true,
          'correctAnswerBy': currentUserId,
          'players.$currentUserId.answers.$_localCurrentQuestionIndex': _textController.text,
          'players.$currentUserId.score': FieldValue.increment(pointsEarned),
        });

        _endCurrentQuestion();
      } else {
        await FirebaseFirestore.instance.collection('game_rooms').doc(roomCode).update({
          'players.$currentUserId.answers.$_localCurrentQuestionIndex': _textController.text,
        });
      }

      _localScores[currentUserId] = (_localScores[currentUserId] ?? 0) + pointsEarned;

    } catch (e) {
      print('Error verifying dictation: $e');
    } finally {
      _isVerifying = false;
      notifyListeners();
    }
  }

  Future<void> _endCurrentQuestion() async {
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

        if (roomData['status'] != 'answered') {
          transaction.update(roomRef, {
            'status': 'answered',
            'revealedAnswer': correctText,
          });
          return true;
        }
        return false;
      });

      Timer(const Duration(seconds: 3), () {
        _attemptNextQuestion();
      });
    } catch (e) {
      print('Error ending question: $e');
    }
  }

  void _attemptNextQuestion() {
    if (isGameFinished) return;

    if (_localCurrentQuestionIndex < _localQuestions.length - 1) {
      final newIndex = _localCurrentQuestionIndex + 1;

      FirebaseFirestore.instance.runTransaction((transaction) async {
        final roomRef = FirebaseFirestore.instance.collection('game_rooms').doc(roomCode);
        final roomSnapshot = await transaction.get(roomRef);

        if (!roomSnapshot.exists) {
          throw Exception('Room does not exist');
        }

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
      });
    } else {
      _attemptEndGame();
    }
  }

  Future<void> _attemptEndGame() async {
    if (isGameFinished) return;

    try {
      _questionTimer?.cancel();
      _countdownTimer?.cancel();

      final success = await FirebaseFirestore.instance.runTransaction((transaction) async {
        final roomRef = FirebaseFirestore.instance.collection('game_rooms').doc(roomCode);
        final roomSnapshot = await transaction.get(roomRef);

        if (!roomSnapshot.exists) {
          throw Exception('Room does not exist');
        }

        final roomData = roomSnapshot.data()!;

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
              "question": q["reference"] ?? "Dictée",
              "answer": q["text"] ?? "",
              "reference": q["reference"],
            };
          }).toList();

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
        final playersInRoom = _roomData['players'] as Map<String, dynamic>? ?? {};
        for (final playerId in playersInRoom.keys) {
          await FirebaseFirestore.instance
              .collection("users")
              .doc(playerId)
              .collection("rooms")
              .doc(roomCode)
              .update({"status": "finished"});
        }
      }

    } catch (e) {
      print("ERROR in _attemptEndGame: $e");
    }
  }

  void _handleGameFinished() {
    if (isGameFinished) {
      _questionTimer?.cancel();
      _countdownTimer?.cancel();
      notifyListeners();
    }
  }

  Future<void> startGame() async {
    if (!_isHost) return;
    if (_localQuestions.isEmpty) {
      print('Cannot start game: no questions generated');
      return;
    }

    await FirebaseFirestore.instance.collection('game_rooms').doc(roomCode).update({
      'status': 'playing',
      'currentQuestionIndex': 0,
      'currentQuestionEndsAt': null,
    });

    _localCurrentQuestionIndex = 0;
    notifyListeners();
  }

  bool get mounted => true;

  @override
  void dispose() {
    print('Disposing DicteeMultiplayerController');
    _roomSubscription?.cancel();
    _questionTimer?.cancel();
    _countdownTimer?.cancel();
    _ttsService.stop();
    _textController.dispose();
    super.dispose();
  }
}