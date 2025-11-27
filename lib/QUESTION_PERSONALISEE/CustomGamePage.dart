import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../models/language_provider.dart';
import '../screens/duels/game_results_page.dart';
import 'custom_questions_translations.dart';

class CustomQuestionsGamePage extends StatefulWidget {
  final String roomCode;

  const CustomQuestionsGamePage({
    Key? key,
    required this.roomCode,
  }) : super(key: key);

  @override
  State<CustomQuestionsGamePage> createState() => _CustomQuestionsGamePageState();
}

class _CustomQuestionsGamePageState extends State<CustomQuestionsGamePage> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  Timer? _timer;
  bool _hasAnswered = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String t(String key) {
    final lang = context.read<LanguageProvider>().language;
    return CustomQuestionsTranslations.t(key, lang);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t('custom_game')),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('game_rooms')
            .doc(widget.roomCode)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final roomData = snapshot.data!.data() as Map<String, dynamic>;
          final winnerMessage = roomData['lastWinnerMessage'] as String?;
          final winnerTimestamp = roomData['lastWinnerTimestamp'] as Timestamp?;

          if (winnerMessage != null && winnerTimestamp != null) {
            final winnerName = winnerMessage.split(' ')[0];
            final isMe = roomData['players'][currentUserId]['name'] == winnerName;

            if (!isMe) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(winnerMessage),
                      backgroundColor: Colors.blue,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              });
            }
          }

          final questions = List<Map<String, dynamic>>.from(roomData['questions']);
          final currentIndex = roomData['currentQuestionIndex'] as int;
          final players = roomData['players'] as Map<String, dynamic>;
          final timeRemaining = roomData['timeRemaining'] as int? ?? 30;
          final timerStarted = roomData['timerStarted'] as bool? ?? false;

          // Fin du jeu
          if (currentIndex >= questions.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (mounted) {
                final questionsSummary = questions.map((q) {
                  String answer;

                  switch (q['type']) {
                    case 'qcm':
                      final options = q['options'] as List?;
                      final correctIndex = q['correctAnswerIndex'] as int?;
                      answer = (options != null && correctIndex != null)
                          ? options[correctIndex]
                          : t('no_answer');
                      break;

                    case 'texteTrous':
                      final fullText = q['question'] as String;
                      final blankIndices = List<int>.from(q['blankIndices'] ?? []);
                      final words = fullText.split(' ');
                      final correctWords = blankIndices.map((i) => words[i]).join(', ');
                      answer = correctWords;
                      break;

                    case 'vraiFaux':
                      final correctIndex = q['correctAnswerIndex'] as int?;
                      answer = correctIndex == 1 ? t('true') : t('false');
                      break;

                    case 'ouverte':
                      answer = q['openAnswer'] ?? t('no_answer');
                      break;

                    default:
                      answer = t('unknown_type');
                  }

                  return {
                    'question': q['question'],
                    'answer': answer,
                    'type': q['type'],
                  };
                }).toList();

                final scores = Map<String, dynamic>.from(players).map((key, value) {
                  return MapEntry(key, {
                    'name': value['name'],
                    'score': value['score'] ?? 0,
                  });
                });

                await FirebaseFirestore.instance
                    .collection('game_results')
                    .doc(widget.roomCode)
                    .set({
                  'roomCode': widget.roomCode,
                  'scores': scores,
                  'questionsSummary': questionsSummary,
                  'finishedAt': FieldValue.serverTimestamp(),
                });

                await FirebaseFirestore.instance
                    .collection('game_rooms')
                    .doc(widget.roomCode)
                    .update({'status': 'finished'});

                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GameResultsPage(
                        players: scores,
                        questions: questionsSummary,
                      ),
                    ),
                  );
                }
              }
            });
            return Center(child: CircularProgressIndicator());
          }

          final currentQuestion = questions[currentIndex];
          final questionType = currentQuestion['type'];

          if (!timerStarted) {
            _startTimer();
          }

          return Column(
            children: [
              _buildProgressIndicator(currentIndex, questions.length),
              _buildTimer(timeRemaining, timerStarted),
              _buildScoreBoard(players),
              Expanded(
                child: _buildQuestionWidget(
                    currentQuestion, questionType, timeRemaining > 0),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressIndicator(int current, int total) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            '${t('question_number')} ${current + 1} ${t('of')} $total',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (current + 1) / total,
            backgroundColor: Colors.grey[300],
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildTimer(int timeRemaining, bool isActive) {
    if (!isActive) return const SizedBox.shrink();

    final isUrgent = timeRemaining <= 5;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isUrgent ? Colors.red : Colors.blue).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timer,
            color: isUrgent ? Colors.red : Colors.blue,
            size: 32,
          ),
          const SizedBox(width: 12),
          Text(
            '$timeRemaining s',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isUrgent ? Colors.red : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBoard(Map<String, dynamic> players) {
    final sortedPlayers = players.entries.toList()
      ..sort((a, b) => (b.value['score'] ?? 0).compareTo(a.value['score'] ?? 0));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: sortedPlayers.take(3).map((entry) {
          final player = entry.value;
          final isMe = entry.key == currentUserId;

          return Column(
            children: [
              Text(
                player['name'],
                style: TextStyle(
                  fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                  color: isMe ? Colors.blue : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${player['score'] ?? 0} ${t('points')}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isMe ? Colors.blue : Colors.black87,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _startTimer() async {
    final roomRef = FirebaseFirestore.instance.collection('game_rooms').doc(widget.roomCode);
    final roomDoc = await roomRef.get();

    if (!roomDoc.exists) return;

    final roomData = roomDoc.data()!;
    final players = roomData['players'] as Map<String, dynamic>;
    final hostId = roomData['hostId'] as String;

    if (currentUserId != hostId) return;

    await roomRef.update({'timerStarted': true, 'timeRemaining': 30});

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final doc = await roomRef.get();
      if (!doc.exists) {
        timer.cancel();
        return;
      }

      final data = doc.data()!;
      final timeRemaining = data['timeRemaining'] as int? ?? 0;

      if (timeRemaining <= 0) {
        timer.cancel();
        final currentIndex = data['currentQuestionIndex'] as int;
        final questions = List<Map<String, dynamic>>.from(data['questions']);

        if (currentIndex + 1 < questions.length) {
          await roomRef.update({
            'currentQuestionIndex': currentIndex + 1,
            'timerStarted': false,
            'timeRemaining': 30,
            'lastWinnerMessage': FieldValue.delete(),
          });
        } else {
          await roomRef.update({'status': 'finished'});
        }
      } else {
        await roomRef.update({'timeRemaining': timeRemaining - 1});
      }
    });
  }

  Widget _buildQuestionWidget(Map<String, dynamic> question, String type, bool timeRemaining) {
    switch (type) {
      case 'qcm':
        return _buildQCMQuestion(question);
      case 'texteTrous':
        return _buildTexteTrousQuestion(question);
      case 'vraiFaux':
        return _buildVraiFauxQuestion(question);
      case 'ouverte':
        return _buildOuverteQuestion(question);
      default:
        return Center(child: Text(t('unknown_question_type')));
    }
  }

  Widget _buildQCMQuestion(Map<String, dynamic> question) {
    final options = question['options'] as List<dynamic>?;

    if (options == null || options.isEmpty) {
      return Center(child: Text(t('no_options_available')));
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              question['question'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ...options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  onPressed: _hasAnswered
                      ? null
                      : () => _submitAnswer(
                    question['correctAnswerIndex'] == index,
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.centerLeft,
                  ),
                  child: Text(option),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTexteTrousQuestion(Map<String, dynamic> question) {
    final words = question['question'].split(' ');
    final blankIndices = List<int>.from(question['blankIndices'] ?? []);
    final controllers = <int, TextEditingController>{};

    for (var index in blankIndices) {
      controllers[index] = TextEditingController();
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t('complete_text'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: words.asMap().entries.map((entry) {
                if (blankIndices.contains(entry.key)) {
                  return SizedBox(
                    width: 100,
                    child: TextField(
                      controller: controllers[entry.key],
                      enabled: !_hasAnswered,
                      decoration: const InputDecoration(
                        hintText: '____',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(entry.value, style: const TextStyle(fontSize: 16)),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _hasAnswered
                  ? null
                  : () {
                bool allCorrect = true;
                for (var index in blankIndices) {
                  if (controllers[index]!.text.trim().toLowerCase() !=
                      words[index].toLowerCase()) {
                    allCorrect = false;
                    break;
                  }
                }
                _submitAnswer(allCorrect);
              },
              child: Text(t('validate')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVraiFauxQuestion(Map<String, dynamic> question) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            question['question'],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _hasAnswered
                      ? null
                      : () => _submitAnswer(question['correctAnswerIndex'] == 1),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(24),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, size: 48),
                      const SizedBox(height: 8),
                      Text(t('true'), style: const TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _hasAnswered
                      ? null
                      : () => _submitAnswer(question['correctAnswerIndex'] == 0),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(24),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.cancel, size: 48),
                      const SizedBox(height: 8),
                      Text(t('false'), style: const TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOuverteQuestion(Map<String, dynamic> question) {
    final controller = TextEditingController();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              question['question'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              maxLines: 3,
              enabled: !_hasAnswered,
              decoration: InputDecoration(
                hintText: t('your_answer_placeholder'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _hasAnswered
                  ? null
                  : () {
                final isCorrect = controller.text.trim().toLowerCase() ==
                    question['openAnswer'].toString().toLowerCase();
                _submitAnswer(isCorrect);
              },
              child: Text(t('validate')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitAnswer(bool isCorrect) async {
    if (_hasAnswered) return;
    setState(() => _hasAnswered = true);

    final roomRef = FirebaseFirestore.instance
        .collection('game_rooms')
        .doc(widget.roomCode);
    final roomDoc = await roomRef.get();
    final roomData = roomDoc.data()!;
    final currentIndex = roomData['currentQuestionIndex'];
    final timeRemaining = roomData['timeRemaining'] as int? ?? 30;
    final players = roomData['players'] as Map<String, dynamic>;
    final myName = players[currentUserId]['name'] as String;

    if (isCorrect) {
      final pointsEarned = timeRemaining;
      await roomRef.update({
        'players.$currentUserId.score': FieldValue.increment(pointsEarned),
        'lastWinnerMessage': '$myName ${t('found_correct_answer')}',
        'lastWinnerTimestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t('correct_answer')} +$pointsEarned ${t('points')}'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _timer?.cancel();
      await Future.delayed(const Duration(seconds: 2));

      final questions = List<Map<String, dynamic>>.from(roomData['questions']);

      if (currentIndex + 1 < questions.length) {
        await roomRef.update({
          'currentQuestionIndex': currentIndex + 1,
          'timerStarted': false,
          'timeRemaining': 30,
          'lastWinnerMessage': FieldValue.delete(),
        });
      } else {
        await roomRef.update({'status': 'finished'});
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('wrong_answer')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) setState(() => _hasAnswered = false);
  }
}