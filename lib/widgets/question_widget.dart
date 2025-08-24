// Fichier: lib/widgets/question_widget.dart
import 'package:flutter/material.dart';
import '../services/Bible_service.dart';
import '../services/audio_service.dart';

class QuestionWidget extends StatefulWidget {
  final ReferenceQuestion question;
  final Function(bool isCorrect) onAnswered;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.onAnswered,
  });

  @override
  State<QuestionWidget> createState() => _QuestionWidgetState();
}

class _QuestionWidgetState extends State<QuestionWidget> {
  String? _selectedAnswer;
  bool _isAnswered = false;

  void _checkAnswer() {
    setState(() => _isAnswered = true);
    final bool isCorrect = _selectedAnswer == widget.question.correctAnswer;

    if (isCorrect) {
      AudioService.instance.playSound('sounds/correct_answer.mp3');
    }
    widget.onAnswered(isCorrect);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  '"${widget.question.questionText}"',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: ListView(
              children: widget.question.options.map((option) {
                return Card(
                  color: _getOptionColor(option),
                  child: RadioListTile<String>(
                    title: Text(option),
                    value: option,
                    groupValue: _selectedAnswer,
                    onChanged: _isAnswered ? null : (value) => setState(() => _selectedAnswer = value),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _selectedAnswer != null && !_isAnswered ? _checkAnswer : null,
              child: const Text("Vérifier"),
            ),
          ),
        ],
      ),
    );
  }

  Color? _getOptionColor(String option) {
    if (!_isAnswered) return null;
    if (option == widget.question.correctAnswer) return Colors.green.shade200;
    if (option == _selectedAnswer) return Colors.red.shade200;
    return null;
  }
}