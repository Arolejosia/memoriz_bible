import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'ordre_game_controller_base.dart';

class OrdreMultiplayerController extends OrdreGameControllerBase {
  final String roomCode;
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  StreamSubscription? _roomSubscription;
  Timer? _questionTimer;
  Timer? _countdownTimer;
  Map<String, dynamic> _roomData = {};
  bool _isInitialized = false;

  // === DONNÉES LOCALES ===
  List<Map<String, dynamic>> _localQuestions = [];
  int _localCurrentQuestionIndex = 0;
  Map<String, int> _localScores = {};
  List<String> _myAnswer = [];
  bool _hasSubmitted = false;

  // Animation pour réponse correcte
  String? _correctAnswerWinnerId;
  String? _correctAnswerWinnerName;
  bool _showCorrectAnswerAnimation = false;

  // === GETTERS PUBLICS ===
  Map<String, dynamic> get players =>
      _roomData['players'] as Map<String, dynamic>? ?? {};

  List<dynamic> get questions => _roomData['questions'] as List<dynamic>? ?? [];

  String? get correctAnswerWinnerId => _correctAnswerWinnerId;

  String? get correctAnswerWinnerName => _correctAnswerWinnerName;

  bool get showCorrectAnswerAnimation => _showCorrectAnswerAnimation;

  OrdreMultiplayerController({required this.roomCode}) {
    _initializeAndListenToRoom();
  }

  // === GETTERS SURCHARGÉS ===
  String get _hostId => _roomData['hostId'] ?? '';

  bool get _isHost => currentUserId == _hostId;

  String get hostId => _roomData['hostId'] ?? '';

  Map<String, dynamic> get _players =>
      _roomData['players'] as Map<String, dynamic>? ?? {};

  bool get questionAlreadyAnswered =>
      _roomData['status'] == 'answered' || _roomData['revealedAnswer'] != null;

  Map<String, dynamic> get _currentQuestion {
    if (_localQuestions.isEmpty ||
        _localCurrentQuestionIndex >= _localQuestions.length) return {};
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
    return "Remettez les mots dans le bon ordre :";
  }

  @override
  List<String> get wordBank {
    if (_currentQuestion.isEmpty) return [];
    final motsMelanges = _currentQuestion['mots_melanges'] as List<dynamic>? ??
        [];
    final result = List<String>.from(motsMelanges);

    // Retirer les mots déjà placés
    for (String word in _myAnswer) {
      result.remove(word);
    }
    return result;
  }

  @override
  List<String?> get placedWords {
    if (_currentQuestion.isEmpty) return [];
    final ordreCorrect = _currentQuestion['ordre_correct'] as List<dynamic>? ??
        [];
    final List<String?> result = List.filled(ordreCorrect.length, null);

    // Placer les mots de ma réponse
    for (int i = 0; i < _myAnswer.length && i < result.length; i++) {
      result[i] = _myAnswer[i];
    }
    return result;
  }

  @override
  List<String> get correctOrder {
    if (_currentQuestion.isEmpty) return [];
    return List<String>.from(_currentQuestion['ordre_correct'] ?? []);
  }

  @override
  bool get isGameFinished => _roomData['status'] == 'finished';

  @override
  int get currentScore => _localScores[currentUserId] ?? 0;

  @override
  bool get isAnswered => _hasSubmitted;

  @override
  List<bool> get wordStates {
    if (!questionAlreadyAnswered || _myAnswer.isEmpty) return [];

    List<bool> states = [];
    for (int i = 0; i < _myAnswer.length && i < correctOrder.length; i++) {
      states.add(_myAnswer[i] == correctOrder[i]);
    }
    return states;
  }

  int get timeLeft {
    final endsAt = _roomData['currentQuestionEndsAt'] as Timestamp?;
    if (endsAt == null) return _calculateAdaptiveTime(); // ✅ Temps adaptatif

    final now = DateTime.now();
    final endTime = endsAt.toDate();
    final secondsLeft = endTime
        .difference(now)
        .inSeconds;

    return secondsLeft.clamp(0, _calculateAdaptiveTime());
  }

  // ✅ NOUVELLE MÉTHODE : Calcul du temps adaptatif
  int _calculateAdaptiveTime() {
    if (_currentQuestion.isEmpty) return 30;

    final ordreCorrect = _currentQuestion['ordre_correct'] as List<dynamic>? ?? [];
    final nombreDeMots = ordreCorrect.length;

    // Formule : (nombre_de_mots × 4) + 15 secondes
    final tempsCalcule = (nombreDeMots * 4) + 15;

    print('⏱️ Temps adaptatif calculé : $tempsCalcule secondes pour $nombreDeMots mots');

    return tempsCalcule;
  }

  List<MapEntry<String, int>> get playerRanking {
    return _localScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  // === MÉTHODES D'ANIMATION ===
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

  void hideAnimation() {
    _showCorrectAnswerAnimation = false;
    notifyListeners();
  }

  // === INITIALISATION FIRESTORE ===
  // Fichier: ordre_multiplayer_controller.dart

  Future<void> _initializeAndListenToRoom() async {
    print("🕵️ Initializing controller for room: $roomCode");

    try {
      final roomSnapshot = await FirebaseFirestore.instance
          .collection('game_rooms')
          .doc(roomCode)
          .get();

      if (!roomSnapshot.exists) {
        print('❌ Room $roomCode does not exist');
        return;
      }

      print("✅ Room found!");
      _roomData = roomSnapshot.data()!;

      // 👇 LOGS DÉTAILLÉS
      print("📦 Room keys: ${_roomData.keys.toList()}");
      print("📝 Status: ${_roomData['status']}");
      print("📊 Questions exists: ${_roomData.containsKey('questions')}");
      print("📊 Questions type: ${_roomData['questions']?.runtimeType}");
      print("📊 Questions length: ${(_roomData['questions'] as List?)?.length ?? 0}");

      _isInitialized = true;

      final List<dynamic> qList = _roomData['questions'] ?? [];
      _localQuestions = qList.map((q) => Map<String, dynamic>.from(q)).toList();

      print("✅ Questions loaded: ${_localQuestions.length} items found.");

      if (_localQuestions.isNotEmpty) {
        print("🔍 First question keys: ${_localQuestions[0].keys.toList()}");
        print("🔍 First question: ${_localQuestions[0]}");
      } else {
        print("⚠️ WARNING: No questions in _localQuestions!");
      }

      _listenToRoom();

      if (_roomData['status'] == 'playing' || _roomData['status'] == 'started') {
        Future.delayed(const Duration(milliseconds: 800), () {
          print('🎮 Calling initial _manageGameLogic for Ordre...');
          _manageGameLogic();
        });
      }

      notifyListeners();

    } catch (e, stackTrace) {
      print('❌ CRITICAL ERROR initializing room: $e');
      print('Stack trace: $stackTrace');
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
        final previousCorrectAnswerFound = _roomData['correctAnswerFound'] ??
            false;

        _roomData = newRoomData;

        // Vérifier si l'index de question a changé
        final newQuestionIndex = newRoomData['currentQuestionIndex'] ?? 0;
        if (newQuestionIndex != _localCurrentQuestionIndex) {
          _localCurrentQuestionIndex = newQuestionIndex;
          _resetForNewQuestion();

          if (newRoomData['currentQuestionEndsAt'] != null) {
            _startLocalCountdown();
          }
        }

        _syncScores();

        if (_roomData['status'] == 'playing' || _roomData['status'] == 'started') {
          if (previousStatus != 'playing' &&
              _roomData['currentQuestionEndsAt'] != null) {
            _startLocalCountdown();
          }
          _manageGameLogic();
        }

        // Détecter si une bonne réponse a été trouvée
        final currentCorrectAnswerFound = newRoomData['correctAnswerFound'] ??
            false;
        if (!previousCorrectAnswerFound && currentCorrectAnswerFound &&
            _roomData['status'] == 'playing') {
          final correctAnswerBy = _roomData['correctAnswerBy'] ?? 'unknown';
          if (correctAnswerBy != currentUserId) {
            _endCurrentQuestion(forceTimeout: false);
          }
        }

        if (_roomData['status'] == 'finished') {
          _handleGameFinished();
        }

        notifyListeners();
      }
    }, onError: (error) {
      print('❌ ERROR listening to room: $error');
    });
  }

  void _resetForNewQuestion() {
    _myAnswer.clear();
    _hasSubmitted = false;
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

    // AJOUTE 'started'
    if ((status == 'playing' || status == 'started') && currentQuestionEndsAt == null && !correctAnswerFound) {
      _startQuestionTimer();
    }

    if ((status == 'playing' || status == 'started') && timeLeft <= 0 && currentQuestionEndsAt != null && !correctAnswerFound) {
      _endCurrentQuestion(forceTimeout: true);
    }
  }

  // === DÉMARRAGE DU JEU ===
  Future<void> startGame() async {
    if (!_isHost) return;
    if (_localQuestions.isEmpty) {
      print('❌ Cannot start game: no questions generated');
      return;
    }

    await FirebaseFirestore.instance
        .collection('game_rooms')
        .doc(roomCode)
        .update({
      'status': 'playing',
      'currentQuestionIndex': 0,
      'currentQuestionEndsAt': null,
    });

    _localCurrentQuestionIndex = 0;
    notifyListeners();
  }

  void _startQuestionTimer() {
    _questionTimer?.cancel();
    _countdownTimer?.cancel();

    final adaptiveTime = _calculateAdaptiveTime();
    final endsAt = DateTime.now().add(Duration(seconds: adaptiveTime));
    print('⏱️ Démarrage du chronomètre avec $adaptiveTime secondes');

    FirebaseFirestore.instance.runTransaction((transaction) async {
      final roomRef = FirebaseFirestore.instance.collection('game_rooms').doc(
          roomCode);
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
      } else {
        return false;
      }
    }).then((timerCreated) {
      if (timerCreated) {
        _startLocalCountdown();
        _questionTimer = Timer(Duration(seconds: adaptiveTime + 1), () {
          if (!isGameFinished && _roomData['status'] != 'answered') {
            _endCurrentQuestion(forceTimeout: true);
          }
        });
      } else {
        _startLocalCountdown();
      }
    }).catchError((error) {
      print('❌ Error updating timer in Firestore: $error');
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

  // === ACTIONS PUBLIQUES ===
  @override
  void placeWord(String word, int targetIndex, {int? sourceIndex}) {
    if (_hasSubmitted || questionAlreadyAnswered) return;

    // Créer une copie de la réponse actuelle
    List<String> newAnswer = List.from(_myAnswer);

    // Ajuster la taille si nécessaire
    while (newAnswer.length <= targetIndex) {
      newAnswer.add('');
    }

    if (sourceIndex != null && sourceIndex < newAnswer.length) {
      // Échange de positions
      final temp = newAnswer[sourceIndex];
      newAnswer[sourceIndex] = newAnswer[targetIndex];
      newAnswer[targetIndex] = word;
    } else {
      // Placement depuis la banque
      newAnswer[targetIndex] = word;
    }

    _myAnswer = newAnswer;
    notifyListeners();
  }

  @override
  void returnWordToBank(String word, int sourceIndex) {
    if (_hasSubmitted || questionAlreadyAnswered) return;

    if (sourceIndex < _myAnswer.length) {
      _myAnswer[sourceIndex] = '';
    }
    notifyListeners();
  }

  @override
  void submitAnswer() {
    if (_hasSubmitted || isGameFinished || questionAlreadyAnswered) return;

    // Nettoyer la réponse (enlever les chaînes vides)
    final cleanAnswer = _myAnswer.where((w) => w.isNotEmpty).toList();

    if (cleanAnswer.length != correctOrder.length) {
      return; // Réponse incomplète
    }

    _hasSubmitted = true;

    final isCorrect = cleanAnswer.join(' ') == correctOrder.join(' ');
    final points = isCorrect ? timeLeft : 0;

    // Mettre à jour le score local
    _localScores[currentUserId] = (_localScores[currentUserId] ?? 0) + points;

    // Sauvegarder dans Firestore
    FirebaseFirestore.instance.collection('game_rooms').doc(roomCode).update({
      'players.$currentUserId.answers.$_localCurrentQuestionIndex': cleanAnswer,
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

  // === FIN DE QUESTION ===
  Future<void> _endCurrentQuestion({bool forceTimeout = false}) async {
    _questionTimer?.cancel();
    _countdownTimer?.cancel();

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final roomRef = FirebaseFirestore.instance.collection('game_rooms').doc(
            roomCode);
        final roomSnapshot = await transaction.get(roomRef);

        if (!roomSnapshot.exists) {
          throw Exception('Room does not exist');
        }

        final roomData = roomSnapshot.data()!;

        if (roomData['status'] != 'answered') {
          transaction.update(roomRef, {
            'status': 'answered',
            'revealedAnswer': correctOrder,
            'timeout': forceTimeout,
          });
          return true;
        } else {
          return false;
        }
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
        final roomRef = FirebaseFirestore.instance.collection('game_rooms').doc(
            roomCode);
        final roomSnapshot = await transaction.get(roomRef);

        if (!roomSnapshot.exists) {
          throw Exception('Room does not exist');
        }

        final roomData = roomSnapshot.data()!;
        final currentIndex = roomData['currentQuestionIndex'] ?? 0;

        if (currentIndex == _localCurrentQuestionIndex &&
            roomData['status'] == 'answered') {
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

  Future<void> _attemptEndGame() async {
    if (isGameFinished) return;

    try {
      _questionTimer?.cancel();
      _countdownTimer?.cancel();

      final success = await FirebaseFirestore.instance.runTransaction((
          transaction) async {
        final roomRef = FirebaseFirestore.instance.collection('game_rooms').doc(
            roomCode);
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
          // On prépare les données du résumé
          final List<Map<String, dynamic>> minimalSummary = _localQuestions.map((q) {
            return {
              "question": q["reference"] ?? "Question",  // ← Juste la référence
              "answer": q["texte_original"] ?? (q["ordre_correct"] as List).join(' '),  // ← Le verset complet
              "reference": q["reference"],
            };
          }).toList();

          // 👇👇👇 LOG N°1 : VÉRIFIEZ CE QUI EST SUR LE POINT D'ÊTRE ENVOYÉ 👇👇👇
          print('📊 DONNÉES PRÉPARÉES POUR LE RÉSUMÉ FINAL : $minimalSummary');

          transaction.set(
              FirebaseFirestore.instance.collection("game_results").doc(
                  roomCode),
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
            "timeout": FieldValue.delete(),
            "correctAnswerFound": FieldValue.delete(),
            "correctAnswerBy": FieldValue.delete(),
          });

          return true;
        }
        return false;
      });

      if (success) {
        final playersInRoom = _roomData['players'] as Map<String, dynamic>? ??
            {};
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
      }
    } catch (e) {
      print("❌ ERROR in _attemptEndGame: $e");
    }
  }

  void _handleGameFinished() {
    if (isGameFinished) {
      _questionTimer?.cancel();
      _countdownTimer?.cancel();
      notifyListeners();
    }
  }

  Future<void> endGame() async {
    await _attemptEndGame();
  }

  @override
  void loadNextQuestion() {
    _attemptNextQuestion();
  }

  @override
  void restartGame() {
    _localCurrentQuestionIndex = 0;
    _myAnswer.clear();
    _hasSubmitted = false;
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
    _roomSubscription?.cancel();
    _questionTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}