// Fichier: lib/screens/games/trouver_reference_session_page.dart
import 'package:flutter/material.dart';
import '../../services/Bible_service.dart';
import '../../widgets/question_widget.dart';
import '../../services/audio_service.dart';

class TrouverReferenceSessionPage extends StatefulWidget {
  final String difficulty;
  final int sessionLength;
  final String? sourceGroup;
  final String? sourceBook;
  final List<String>? sourceRefs;
  const TrouverReferenceSessionPage({
    super.key,
    required this.difficulty,
    required this.sessionLength,
    this.sourceGroup,
    this.sourceBook,
    this.sourceRefs,
  });

  @override
  State<TrouverReferenceSessionPage> createState() => _TrouverReferenceSessionPageState();
}

class _TrouverReferenceSessionPageState extends State<TrouverReferenceSessionPage> {
  int _questionNumber = 1;
  int _score = 0;
  Future<ReferenceQuestion>? _futureQuestion;

  @override
  void initState() {
    super.initState();
    _loadNextQuestion();
  }

  void _loadNextQuestion() {
    if (_questionNumber > widget.sessionLength) {
      // TODO: Naviguer vers une page de résultats
      print("FIN DE LA PARTIE ! Score: $_score / ${widget.sessionLength}");
      Navigator.pop(context); // Pour l'instant, on revient en arrière
      return;
    }
    setState(() {
      _futureQuestion = BibleService().generateReferenceQuestion(
        difficulty: widget.difficulty,
        sourceGroup: widget.sourceGroup,
        sourceBook: widget.sourceBook,
        sourceRefs: widget.sourceRefs,
      );
    });
  }

  void _onAnswered(bool isCorrect) {
    if (isCorrect) {
      _score++;
      AudioService.instance.playSound('sound/correct.mp3');
    }
    setState(() => _questionNumber++);
    Future.delayed(const Duration(milliseconds: 1200), _loadNextQuestion);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Question $_questionNumber / ${widget.sessionLength}")),
      body: FutureBuilder<ReferenceQuestion>(
        future: _futureQuestion,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erreur : ${snapshot.error}"));
          }
          return QuestionWidget(
            question: snapshot.data!,
            onAnswered: _onAnswered,
          );
        },
      ),
    );
  }
}