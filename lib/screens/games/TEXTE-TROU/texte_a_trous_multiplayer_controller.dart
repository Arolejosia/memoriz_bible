import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../models/verse_model.dart';
import 'texte_a_trous_controller_base.dart';

class TexteATrousMultiplayerController extends TexteATrousControllerBase {
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
  Map<String, List<String>> _localAnswers = {}; // Stocke les réponses pour chaque question

  // État de la question actuelle
  bool _answered = false;
  bool _bonneReponse = false;
  List<bool> _resultatsVerification = [];

  TexteATrousMultiplayerController({
    required this.roomCode,
  }) {
    _initializeAndListenToRoom();
  }

  // === GETTERS ===
  String get _hostId => _roomData['hostId'] ?? '';
  bool get _isHost => currentUserId == _hostId;
  Map<String, dynamic> get _players => _roomData['players'] as Map<String, dynamic>? ?? {};

  List<dynamic> get _questions => _localQuestions;
  @override
  int get currentQuestionIndex => _localCurrentQuestionIndex;

  Map<String, dynamic> get _currentQuestion {
    if (_localQuestions.isEmpty || _localCurrentQuestionIndex >= _localQuestions.length) return {};
    return _localQuestions[_localCurrentQuestionIndex];
  }

  // === GETTERS SURCHARGÉS ===
  @override
  bool get isLoading => !_isInitialized || _localQuestions.isEmpty;

  @override
  String get versetModifie {
    if (!_isInitialized) return "initializing";
    if (_roomData.isEmpty) return "connecting";
    if (_localQuestions.isEmpty) return "waiting_questions";
    if (_roomData['status'] == 'waiting') return "waiting_start";
    if (_currentQuestion.isEmpty) return "preparing_question";
    return _currentQuestion['verset_modifie'] ?? "waiting";
  }

  @override
  List<String> get reponses => List<String>.from(_currentQuestion['reponses'] ?? []);

  @override
  List<int> get indices => List<int>.from(_currentQuestion['indices'] ?? []);

  @override
  String? get currentReference => _currentQuestion['reference'];

  @override
  bool get isGameFinished => _roomData['status'] == 'finished';

  @override
  int get currentScore => _localScores[currentUserId] ?? 0;

  @override
  String get status => _roomData['status'] ?? 'loading';

  // === GETTERS SPÉCIFIQUES AU MULTIJOUEUR ===
  @override
  bool get answered => _answered;

  @override
  bool get bonneReponse => _bonneReponse;

  @override
  List<bool> get resultatsVerification => _resultatsVerification;

  bool get iHaveAnswered => _localAnswers.containsKey('$_localCurrentQuestionIndex');

  List<String>? get myLastAnswers => _localAnswers['$_localCurrentQuestionIndex'];

  int get timeLeft {
    final endsAt = _roomData['currentQuestionEndsAt'] as Timestamp?;
    if (endsAt == null) return 60; // Temps par défaut pour texte à trous (plus long que QCM)

    final now = DateTime.now();
    final endTime = endsAt.toDate();
    final secondsLeft = endTime.difference(now).inSeconds;

    return secondsLeft.clamp(0, 60);
  }

  // Obtenir les réponses globales (trouvées par n'importe qui)
  List<String> get globalCorrectAnswers {
    final Map<String, dynamic> globalAnswersMap = _roomData['globalCorrectAnswers'] as Map<String, dynamic>? ?? {};
    final dynamic questionAnswers = globalAnswersMap['$_localCurrentQuestionIndex'];

    if (questionAnswers == null) {
      return List.filled(reponses.length, '');
    }

    if (questionAnswers is List) {
      return List<String>.from(questionAnswers);
    }

    if (questionAnswers is Map) {
      List<String> result = List.filled(reponses.length, '');
      questionAnswers.forEach((key, value) {
        int index = int.tryParse(key.toString()) ?? -1;
        if (index >= 0 && index < result.length) {
          result[index] = value.toString();
        }
      });
      return result;
    }

    return List.filled(reponses.length, '');
  }

  // === PROPRIÉTÉS POUR L'INTERFACE UTILISATEUR ===
  Map<String, dynamic> get players => _players;
  List<dynamic> get questions => _localQuestions;

  List<MapEntry<String, int>> get playerRanking {
    return _localScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  // === INITIALISATION FIRESTORE ===
  Future<void> _initializeAndListenToRoom() async {
    try {
      final roomSnapshot = await FirebaseFirestore.instance
          .collection('game_rooms')
          .doc(roomCode)
          .get();

      if (!roomSnapshot.exists) {
        print('❌ La salle $roomCode n\'existe pas');
        return;
      }

      _roomData = roomSnapshot.data()!;
      _isInitialized = true;

      // Charger les questions déjà générées
      final List<dynamic> qList = _roomData['questions'] ?? [];
      _localQuestions = qList.map((q) => Map<String, dynamic>.from(q)).toList();

      // Initialiser les scores locaux
      final players = _roomData['players'] as Map<String, dynamic>? ?? {};
      for (String playerId in players.keys) {
        _localScores[playerId] = players[playerId]['score'] ?? 0;
      }

      // Synchroniser l'index de question
      _localCurrentQuestionIndex = _roomData['currentQuestionIndex'] ?? 0;

      _listenToRoom();

      // Vérifier l'état initial et démarrer la logique
      print('🎮 Statut initial de la salle: ${_roomData['status']}');
      print('🎮 Minuteur initial: ${_roomData['currentQuestionEndsAt']}');

      if (_roomData['status'] == 'playing' || _roomData['status'] == 'started') {
        // Attendre que _listenToRoom s'initialise
        Future.delayed(const Duration(milliseconds: 800), () {
          print('🎮 Appel initial de _manageGameLogic...');
          _manageGameLogic();
        });
      }

      notifyListeners();
    } catch (e) {
      print('❌ ERREUR lors de l\'initialisation de la salle: $e');
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

        // Vérifier si l'index de question a changé
        final newQuestionIndex = newRoomData['currentQuestionIndex'] ?? 0;
        if (newQuestionIndex != _localCurrentQuestionIndex) {
          _localCurrentQuestionIndex = newQuestionIndex;
          print('🔄 Index de question mis à jour à: $_localCurrentQuestionIndex');

          // Réinitialiser l'état pour la nouvelle question
          _answered = false;
          _bonneReponse = false;
          _resultatsVerification = [];

          // Réinitialiser les minuteurs
          _questionTimer?.cancel();
          _countdownTimer?.cancel();

          if (newRoomData['currentQuestionEndsAt'] != null) {
            _startLocalCountdown();
          }
        }

        // Synchroniser les scores
        _syncScores();

        // Gérer la logique du jeu
        if (_roomData['status'] == 'playing' || _roomData['status'] == 'started') {
          if ((previousStatus != 'playing' && previousStatus != 'started') && _roomData['currentQuestionEndsAt'] != null) {
            print('🎮 Statut changé en playing, démarrage du compte à rebours local pour tous les joueurs');
            _startLocalCountdown();
          }
          _manageGameLogic();
        }
        if (_roomData['status'] == 'finished') {
          _handleGameFinished();
        }

        notifyListeners();
      }
    }, onError: (error) {
      print('ERREUR lors de l\'écoute de la salle: $error');
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

    print('🎯 Logique de jeu - Statut: $status, EndsAt: $currentQuestionEndsAt, TimeLeft: $timeLeft, Joueur: $currentUserId, IsHost: $_isHost');

    // Accepter "started" ET "playing"
    if ((status == 'playing' || status == 'started') && currentQuestionEndsAt == null) {
      print('⏰ Aucun minuteur trouvé, tentative de démarrage d\'un nouveau minuteur... (Joueur: $currentUserId)');
      _startQuestionTimer();
    }

    if ((status == 'playing' || status == 'started') && timeLeft <= 0 && currentQuestionEndsAt != null) {
      print('⏰ Temps expiré! Fin de la question... (détecté par $currentUserId)');
      _endCurrentQuestion(forceTimeout: true);
    }
  }

  Future<void> startGame() async {
    if (!_isHost) return;
    if (_localQuestions.isEmpty) {
      print('Impossible de démarrer la partie : aucune question générée');
      return;
    }

    // Vérifier le nombre de joueurs
    if (_players.length < 2) {
      print('Impossible de démarrer la partie : besoin d\'au moins 2 joueurs');
      return;
    }

    print('🎮 Démarrage de la partie...');

    await FirebaseFirestore.instance.collection('game_rooms').doc(roomCode).update({
      'status': 'playing',
      'currentQuestionIndex': 0,
      'currentQuestionEndsAt': null,
    });

    _localCurrentQuestionIndex = 0;
    notifyListeners();

    // Démarrer le minuteur après que le statut soit mis à jour
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_roomData['status'] == 'playing' && _roomData['currentQuestionEndsAt'] == null) {
        print('🎮 Démarrage du minuteur après le début de la partie...');
        _startQuestionTimer();
      }
    });
  }

  void _startQuestionTimer() {
    print('⏰ Tentative de démarrage du minuteur de question pour la question $_localCurrentQuestionIndex (Joueur: $currentUserId)');

    _questionTimer?.cancel();
    _countdownTimer?.cancel();

    final endsAt = DateTime.now().add(const Duration(seconds: 60));

    FirebaseFirestore.instance.runTransaction((transaction) async {
      final roomRef = FirebaseFirestore.instance.collection('game_rooms').doc(roomCode);
      final roomSnapshot = await transaction.get(roomRef);

      if (!roomSnapshot.exists) {
        throw Exception('La salle n\'existe pas');
      }

      final roomData = roomSnapshot.data()!;

      // Vérifier si un minuteur n'existe pas déjà
      if (roomData['currentQuestionEndsAt'] == null) {
        transaction.update(roomRef, {
          'currentQuestionEndsAt': Timestamp.fromDate(endsAt),
          'status': 'playing',
        });
        print('✅ Transaction: Le minuteur sera créé par $currentUserId');
        return true;
      } else {
        print('ℹ️ Transaction: Le minuteur existe déjà');
        return false;
      }
    }).then((timerCreated) {
      print('🔍 Résultat de la transaction: timerCreated = $timerCreated (Joueur: $currentUserId)');

      if (timerCreated == true) {
        print('✅ Minuteur créé avec succès par le joueur $currentUserId');
        _startLocalCountdown();

        _questionTimer = Timer(const Duration(seconds: 61), () {
          print('⏰ Minuteur expiré pour la question $_localCurrentQuestionIndex (Joueur: $currentUserId)');
          if (!isGameFinished && _roomData['status'] != 'answered') {
            _endCurrentQuestion(forceTimeout: true);
          }
        });
      } else if (timerCreated == false) {
        print('ℹ️ Le minuteur existe déjà, démarrage du compte à rebours local uniquement (Joueur: $currentUserId)');
        _startLocalCountdown();
      }
    }).catchError((error) {
      print('❌ Erreur dans la transaction (Joueur: $currentUserId): $error');
      // En cas d'erreur, réessayer après 1 seconde
      Future.delayed(const Duration(seconds: 1), () {
        if (_roomData['currentQuestionEndsAt'] == null && _roomData['status'] == 'playing') {
          print('🔄 Nouvelle tentative de création du minuteur après erreur...');
          _startQuestionTimer();
        }
      });
    });
  }

  void _startLocalCountdown() {
    print('⏱️ Démarrage du compte à rebours local (Joueur: $currentUserId)');
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentTimeLeft = timeLeft;
      print('⏱️ Tick du compte à rebours local - Temps restant: $currentTimeLeft (Joueur: $currentUserId)');

      // Si le temps est écoulé, arrêter le minuteur
      if (currentTimeLeft <= 0) {
        timer.cancel();
        print('⏱️ Compte à rebours local terminé (Joueur: $currentUserId)');
      }

      notifyListeners(); // Force l'interface à se mettre à jour
    });
  }

  Future<void> _endCurrentQuestion({bool forceTimeout = false}) async {
    print('📚 Tentative de fin de la question actuelle $_localCurrentQuestionIndex (timeout: $forceTimeout, Joueur: $currentUserId)');

    _questionTimer?.cancel();
    _countdownTimer?.cancel();

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final roomRef = FirebaseFirestore.instance.collection('game_rooms').doc(roomCode);
        final roomSnapshot = await transaction.get(roomRef);

        if (!roomSnapshot.exists) {
          throw Exception('La salle n\'existe pas');
        }

        final roomData = roomSnapshot.data()!;

        // Vérifier si la question n'est pas déjà terminée
        if (roomData['status'] != 'answered') {
          transaction.update(roomRef, {
            'status': 'answered',
            'revealedAnswers': reponses,
            'timeout': forceTimeout,
            'endReason': forceTimeout ? 'timeout' : 'all_completed',
          });

          print('✅ Question terminée avec succès par le joueur $currentUserId (raison: ${forceTimeout ? "timeout" : "all_completed"})');
          return true;
        } else {
          print('ℹ️ Question déjà terminée par un autre joueur');
          return false;
        }
      });

      // Attendre quelques secondes pour montrer les réponses, puis passer à la suivante
      Timer(const Duration(seconds: 4), () {
        attemptNextQuestion();
      });
    } catch (e) {
      print('❌ Erreur lors de la fin de la question (Joueur: $currentUserId): $e');
    }
  }

  // Passer à la question suivante
  void attemptNextQuestion() {
    if (isGameFinished) return;

    // Vérifier si l'index actuel N'EST PAS le dernier index
    // Tant que ce n'est pas la dernière question, on continue
    if (_localCurrentQuestionIndex < _localQuestions.length - 1) {
      final newIndex = _localCurrentQuestionIndex + 1;

      FirebaseFirestore.instance.runTransaction((transaction) async {
        final roomRef = FirebaseFirestore.instance.collection('game_rooms').doc(roomCode);
        final roomSnapshot = await transaction.get(roomRef);

        if (!roomSnapshot.exists) {
          throw Exception('La salle n\'existe pas');
        }

        final roomData = roomSnapshot.data()!;
        final currentIndex = roomData['currentQuestionIndex'] ?? 0;

        if (currentIndex == _localCurrentQuestionIndex && roomData['status'] == 'answered') {
          transaction.update(roomRef, {
            'currentQuestionIndex': newIndex,
            'status': 'playing',
            'currentQuestionEndsAt': FieldValue.delete(),
            'revealedAnswers': FieldValue.delete(),
          });
          return true;
        }
        return false;
      });
    } else {
      // Si on a fini la dernière question, on termine la partie
      _attemptEndGame();
    }
  }

  bool fuzzyMatch(String userAnswer, String correctAnswer) {
    final normalized1 = userAnswer.toLowerCase().trim().replaceAll(RegExp(r'[^\w]'), '');
    final normalized2 = correctAnswer.toLowerCase().trim().replaceAll(RegExp(r'[^\w]'), '');
    return normalized1 == normalized2;
  }

  @override
  Future<void> verifierReponses(List<String> reponsesUtilisateur) async {
    if (isLoading || isGameFinished) return;
    if (_roomData['status'] == 'answered') return;

    // Récupérer les réponses globales (trouvées par n'importe quel joueur)
    final Map<String, dynamic> globalAnswersMap = _roomData['globalCorrectAnswers'] as Map<String, dynamic>? ?? {};
    List<String> reponsesGlobales = List<String>.from(
        globalAnswersMap['$_localCurrentQuestionIndex'] ?? List.filled(reponses.length, '')
    );

    // Récupérer mes propres réponses validées
    List<String> mesReponses = _localAnswers['$_localCurrentQuestionIndex'] ??
        List.filled(reponses.length, '');

    final List<bool> resultats = [];
    int pointsEarned = 0;
    Map<int, String> nouvellesReponsesGlobales = {};

    for (int i = 0; i < reponses.length && i < reponsesUtilisateur.length; i++) {
      final dejaCorrectGlobalement = reponsesGlobales[i].isNotEmpty;
      final dejaCorrectParMoi = mesReponses[i].isNotEmpty && fuzzyMatch(mesReponses[i], reponses[i]);
      final maintenantCorrect = fuzzyMatch(reponsesUtilisateur[i], reponses[i]);

      resultats.add(maintenantCorrect || dejaCorrectGlobalement);

      // Points seulement si JE trouve une nouvelle bonne réponse
      if (maintenantCorrect && !dejaCorrectParMoi && !dejaCorrectGlobalement) {
        pointsEarned += 2;
        mesReponses[i] = reponses[i];
        nouvellesReponsesGlobales[i] = reponses[i];
      } else if (maintenantCorrect) {
        mesReponses[i] = reponses[i];
      } else if (dejaCorrectGlobalement) {
        mesReponses[i] = reponsesGlobales[i];
      }
    }

    final toutesCorrectes = resultats.every((r) => r);

    // Bonus si je termine toutes les réponses en premier
    if (toutesCorrectes && nouvellesReponsesGlobales.isNotEmpty && timeLeft > 15) {
      pointsEarned += (timeLeft - 15);
    }

    _answered = true;
    _bonneReponse = toutesCorrectes;
    _resultatsVerification = resultats;
    _localAnswers['$_localCurrentQuestionIndex'] = mesReponses;

    if (pointsEarned > 0) {
      _localScores[currentUserId] = (_localScores[currentUserId] ?? 0) + pointsEarned;
    }

    Map<String, dynamic> updateData = {
      'players.$currentUserId.answers.$_localCurrentQuestionIndex': mesReponses,
    };

    if (pointsEarned > 0) {
      updateData['players.$currentUserId.score'] = FieldValue.increment(pointsEarned);
    }

    // Ajouter les nouvelles bonnes réponses globales
    for (var entry in nouvellesReponsesGlobales.entries) {
      updateData['globalCorrectAnswers.$_localCurrentQuestionIndex.${entry.key}'] = entry.value;
    }

    await FirebaseFirestore.instance.collection('game_rooms').doc(roomCode).update(updateData);

    notifyListeners();

    if (toutesCorrectes) {
      _endCurrentQuestion();
    } else {
      Future.delayed(const Duration(seconds: 1), () {
        if (!isGameFinished && _roomData['status'] != 'answered') {
          _answered = false;
          notifyListeners();
        }
      });
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
          throw Exception('La salle n\'existe pas');
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
              "question": q["verset_modifie"],
              "answers": q["reponses"],
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
            "revealedAnswers": FieldValue.delete(),
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
              .update({"status": "finished"})
              .catchError((error) {
            print('Erreur lors de la mise à jour du statut de la salle pour $playerId: $error');
          });
        }
        print('✅ Statut mis à jour à "finished" pour ${playersInRoom.length} joueurs');
      }
    } catch (e) {
      print("ERREUR dans _attemptEndGame: $e");
    }
  }

  void _handleGameFinished() {
    if (isGameFinished) {
      print('🏁 Partie terminée - nettoyage des minuteurs et notification de l\'interface (Joueur: $currentUserId)');
      _questionTimer?.cancel();
      _countdownTimer?.cancel();

      // Appeler _attemptEndGame si ce n'est pas déjà fait
      if (_roomData['status'] != 'finished') {
        print('Statut pas encore "finished", appel de _attemptEndGame()');
        _attemptEndGame();
      }

      notifyListeners();

      // L'interface devrait automatiquement naviguer vers la page de résultats
      // en détectant que isGameFinished est true
    }
  }

  @override
  void loadNextQuestion() {
    attemptNextQuestion();
  }

  @override
  void restartGame() {
    _localCurrentQuestionIndex = 0;
    _localAnswers.clear();
    _localScores.clear();
    _answered = false;
    _bonneReponse = false;
    _resultatsVerification = [];

    final players = _roomData['players'] as Map<String, dynamic>? ?? {};
    for (String playerId in players.keys) {
      _localScores[playerId] = 0;
    }

    if (_isHost) {
      FirebaseFirestore.instance.collection('game_rooms').doc(roomCode).update({
        'status': 'waiting',
        'currentQuestionIndex': 0,
        'currentQuestionEndsAt': null,
        'revealedAnswers': FieldValue.delete(),
        'timeout': FieldValue.delete(),
      });
    }

    notifyListeners();
  }

  @override
  void dispose() {
    print('🗑️ Libération du TexteATrousMultiplayerController (Joueur: $currentUserId)');

    _roomSubscription?.cancel();
    _questionTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}