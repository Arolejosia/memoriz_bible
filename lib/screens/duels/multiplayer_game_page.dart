import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'game_results_page.dart';

class MultiplayerGamePage extends StatefulWidget {
  final String roomCode;
  const MultiplayerGamePage({super.key, required this.roomCode});

  @override
  State<MultiplayerGamePage> createState() => _MultiplayerGamePageState();
}

class _MultiplayerGamePageState extends State<MultiplayerGamePage> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  Timer? _questionTimer;
  List<String> _sourceWords = [];
  List<String> _targetWords = [];
  List<TextEditingController> _blankControllers = [];
  int _lastBuiltQuestionIndex = -1;

  @override
  void dispose() {
    _questionTimer?.cancel();
    super.dispose();
  }

  void _submitAnswer(dynamic answer, int questionIndex, dynamic correctAnswer, int timeLeft) {
    if (currentUserId == null) return;

    // Simple check for now. Can be made more complex.
    bool isCorrect = answer.toString() == correctAnswer.toString();
    int points = isCorrect ? timeLeft : 0;

    FirebaseFirestore.instance.collection('game_rooms').doc(widget.roomCode).update({
      'players.$currentUserId.answers.$questionIndex': answer,
      'players.$currentUserId.score': FieldValue.increment(points),
    });
  }

  void _startQuestionTimer(int durationInSeconds) {
    _questionTimer?.cancel();
    final questionEndsAt = DateTime.now().add(Duration(seconds: durationInSeconds));
    FirebaseFirestore.instance
        .collection('game_rooms')
        .doc(widget.roomCode)
        .update({'currentQuestionEndsAt': Timestamp.fromDate(questionEndsAt)});
  }

  void _nextQuestion(int currentIndex, int totalQuestions, String hostId) {
    if (currentUserId != hostId) return;
    if (currentIndex < totalQuestions - 1) {
      FirebaseFirestore.instance.collection('game_rooms').doc(widget.roomCode).update({
        'currentQuestionIndex': FieldValue.increment(1),
        'currentQuestionEndsAt': null, // Reset timer
      });
    } else {
      FirebaseFirestore.instance.collection('game_rooms').doc(widget.roomCode).update({'status': 'finished'});
    }
  }


  @override
  Widget build(BuildContext context) {
    final roomStream = FirebaseFirestore.instance.collection('game_rooms').doc(widget.roomCode).snapshots();
    return Scaffold(
      appBar: AppBar(title: const Text("Game In Progress!")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: roomStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final roomData = snapshot.data!.data() as Map<String, dynamic>;
          final questionIndex = roomData['currentQuestionIndex'] as int;

          if (questionIndex != _lastBuiltQuestionIndex) {
            // On réinitialise toutes les variables d'état des jeux
            _sourceWords = [];
            _targetWords = [];
            _blankControllers.forEach((c) => c.dispose());
            _blankControllers = [];

            // Et on met à jour notre variable de suivi
            _lastBuiltQuestionIndex = questionIndex;
          }

          if (roomData['status'] == 'finished') {
            // Navigate to results page...
            return const Center(child: Text("Game Over!"));
          }

          final questions = roomData['questions'] as List<dynamic>;

          final config = roomData['config'] as Map<String, dynamic>;
          final gameType = config['gameType'];
          final currentQuestion = questions[questionIndex];

          // ✅ Main router to display the correct UI for the game type
          switch (gameType) {
            case 'qcm':
            case 'trouverLaReference':
            case 'trouver_reference':
              return _buildQuizUI(context, roomData, currentQuestion, questionIndex);

            case 'remettreEnOrdre':
              return _buildWordScrambleUI(context, roomData, currentQuestion, questionIndex,);

            case 'jeuTrous':
              return _buildFillInTheBlankUI(context, roomData, currentQuestion, questionIndex);

            default:
              return Center(child: Text("Game type '$gameType' not supported yet."));
          }
        },
      ),
    );
  }

  // UI Builder for Quiz-style games (QCM, Find the Reference)
  Widget _buildQuizUI(BuildContext context, Map<String, dynamic> roomData, Map<String, dynamic> question, int questionIndex) {
    final players = roomData['players'] as Map<String, dynamic>;
    final myData = players[currentUserId!];
    final bool iHaveAnswered = myData['answers']?['$questionIndex'] != null;
    final int timeLeft = _calculateTimeLeft(roomData['currentQuestionEndsAt'] as Timestamp?);
    final bool isHost = currentUserId == roomData['hostId'];

    // Host logic to manage the timer for each question
    if (roomData['currentQuestionEndsAt'] == null && isHost) {
      _startQuestionTimer(20);
    }
    if(timeLeft == 0 && isHost) {
      Future.delayed(const Duration(seconds: 3), () => _nextQuestion(questionIndex, (roomData['questions'] as List).length, roomData['hostId']));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text("$timeLeft", style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          Text(question['questionText'], style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: List<String>.from(question['options']).map((option) {
                return Card(
                  child: ListTile(
                    title: Text(option),
                    onTap: iHaveAnswered || timeLeft == 0 ? null : () => _submitAnswer(option, questionIndex, question['correctAnswer'], timeLeft),
                  ),
                );
              }).toList(),
            ),
          ),
          Wrap(
            spacing: 8.0,
            children: players.entries.map((entry) {
              final bool hasAnswered = entry.value['answers']?['$questionIndex'] != null;
              return Chip(
                label: Text(entry.value['name']),
                avatar: hasAnswered ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.hourglass_empty),
              );
            }).toList(),
          ),
          if (isHost)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: ElevatedButton(
                onPressed: () => _nextQuestion(questionIndex, (roomData['questions'] as List).length, roomData['hostId']),
                child: const Text("Next Question"),
              ),
            ),
        ],
      ),
    );
  }

  int _calculateTimeLeft(Timestamp? endsAt) {
    if (endsAt == null) return 0;
    final int secondsLeft = endsAt.toDate().difference(DateTime.now()).inSeconds;
    return secondsLeft > 0 ? secondsLeft : 0;
  }


// UI Builder for Word Scramble game
  Widget _buildWordScrambleUI(BuildContext context, Map<String, dynamic> roomData, Map<String, dynamic> question, int questionIndex) {
    // Initialize the word banks if this is the first build for this question
    if (_sourceWords.isEmpty && _targetWords.isEmpty) {
      _sourceWords = List<String>.from(question['options']);
    }

    // ... (Timer logic and other variables from the Quiz UI)

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // ... (Timer Widget)
          Text(question['questionText'], style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),

          // Target (user's answer)
          Container(
            height: 100,
            decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
            child: Wrap(
              children: _targetWords.map((word) => InkWell(
                onTap: () => setState(() {
                  _targetWords.remove(word);
                  _sourceWords.add(word);
                }),
                child: Chip(label: Text(word)),
              )).toList(),
            ),
          ),

          const SizedBox(height: 20),

          // Source (word bank)
          Wrap(
            children: _sourceWords.map((word) => InkWell(
              onTap: () => setState(() {
                _sourceWords.remove(word);
                _targetWords.add(word);
              }),
              child: Chip(label: Text(word)),
            )).toList(),
          ),

          ElevatedButton(
            onPressed: () {
              _submitAnswer(_targetWords, questionIndex, question['correctAnswer'], 10); // 10 is placeholder for timeLeft
              _sourceWords = [];
              _targetWords = [];
            },
            child: const Text("Verify"),
          )
        ],
      ),
    );
  }

// UI Builder for Fill in the Blank game
  Widget _buildFillInTheBlankUI(BuildContext context, Map<String, dynamic> roomData, Map<String, dynamic> question, int questionIndex) {
    final List<String> correctAnswers = List<String>.from(question['correctAnswer']);

    // Initialize controllers if this is the first build
    if (_blankControllers.isEmpty) {
      _blankControllers = List.generate(correctAnswers.length, (_) => TextEditingController());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // ... (Timer Widget)
          Text(question['questionText'], style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),

          // TextFields for blanks
          ..._blankControllers.map((controller) => TextField(controller: controller)),

          ElevatedButton(
            onPressed: () {
              final userAnswers = _blankControllers.map((c) => c.text.trim()).toList();
              _submitAnswer(userAnswers, questionIndex, correctAnswers, 10);
              _blankControllers = [];
            },
            child: const Text("Verify"),
          )
        ],
      ),
    );
  }
}