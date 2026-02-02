import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/language_provider.dart';
import '../screens/duels/game_results_page.dart';

import 'custom_questions_multiplayer_controller.dart';
import 'custom_questions_translations.dart';


class CustomQuestionsGamePage extends StatelessWidget {
  final String roomCode;

  const CustomQuestionsGamePage({
    Key? key,
    required this.roomCode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CustomQuestionsMultiplayerController(roomCode: roomCode),
      child: const _CustomQuestionsGameView(),
    );
  }
}

class _CustomQuestionsGameView extends StatelessWidget {
  const _CustomQuestionsGameView();

  String t(BuildContext context, String key) {
    final lang = context.read<LanguageProvider>().language;
    return CustomQuestionsTranslations.t(key, lang);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CustomQuestionsMultiplayerController>();

    // ✅ Navigation automatique vers les résultats
    if (controller.isGameFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;

        // ✅ Utiliser la méthode du contrôleur pour extraire les bonnes réponses
        final questionsSummary = controller.questions.map((q) {
          return {
            'question': q['question'],
            'answer': controller.getAnswerForSummary(Map<String, dynamic>.from(q)),
            'reference': q['reference'] ?? '',
            'type': q['type'],
          };
        }).toList();

        final scores = Map<String, dynamic>.from(controller.players).map((key, value) {
          return MapEntry(key, {
            'name': value['name'] ?? 'Unknown',
            'score': value['score'] ?? 0,
          });
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => GameResultsPage(
              players: scores,
              questions: questionsSummary,
            ),
          ),
        );
      });

      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(t(context, 'custom_game'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t(context, 'custom_game')),
          automaticallyImplyLeading: false,
        ),
        body: Stack(
          children: [
            Column(
              children: [
                _buildHeader(context, controller),
                _buildScoreboard(context, controller),
                Expanded(
                  child: _buildQuestionWidget(context, controller),
                ),
              ],
            ),
            // ✅ Animation du gagnant
            if (controller.showCorrectAnswerAnimation)
              _buildWinnerAnimation(context, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, CustomQuestionsMultiplayerController controller) {
    final totalQuestions = controller.questions.length;
    final currentIndex = controller.questions.indexOf(
      controller.questions.firstWhere(
            (q) => q['question'] == controller.questionText,
        orElse: () => controller.questions.isNotEmpty ? controller.questions.first : {},
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            '${t(context, 'question_number')} ${currentIndex + 1} ${t(context, 'of')} $totalQuestions',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: totalQuestions > 0 ? (currentIndex + 1) / totalQuestions : 0,
            backgroundColor: Colors.grey[300],
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          Text(
            '${controller.timeLeft} s',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: controller.timeLeft <= 5 ? Colors.red : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreboard(BuildContext context, CustomQuestionsMultiplayerController controller) {
    final sorted = controller.players.entries.toList()
      ..sort((a, b) => (b.value['score'] ?? 0).compareTo(a.value['score'] ?? 0));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: sorted.take(3).map((entry) {
          final isMe = entry.key == controller.currentUserId;
          return Column(
            children: [
              Text(
                entry.value['name'] ?? 'Unknown',
                style: TextStyle(
                  fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                  color: isMe ? Colors.blue : Colors.black,
                ),
              ),
              Text(
                '${entry.value['score'] ?? 0} ${t(context, 'points')}',
                style: TextStyle(
                  fontSize: 16,
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

  Widget _buildWinnerAnimation(BuildContext context, CustomQuestionsMultiplayerController controller) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars, size: 64, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                '${controller.correctAnswerWinnerName} ${t(context, 'found_correct_answer')}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionWidget(BuildContext context, CustomQuestionsMultiplayerController controller) {
    final type = controller.currentQuestionType;

    // ✅ Créer une clé unique basée sur l'index de la question actuelle
    final currentQuestionIndex = controller.questions.indexOf(
      controller.questions.firstWhere(
            (q) => q['question'] == controller.questionText,
        orElse: () => controller.questions.isNotEmpty ? controller.questions.first : {},
      ),
    );

    switch (type) {
      case 'qcm':
      case 'vraiFaux':
        return _buildQCMOrVraiFaux(context, controller);
      case 'texteTrous':
        return _TexteTrousWidget(
          key: ValueKey('texte_trous_$currentQuestionIndex'), // ✅ CLÉ UNIQUE
          controller: controller,
        );
      case 'ouverte':
        return _OpenQuestionWidget(
          key: ValueKey('open_question_$currentQuestionIndex'), // ✅ CLÉ UNIQUE
          controller: controller,
        );
      default:
        return Center(child: Text('${t(context, 'unknown_question_type')}: $type'));
    }
  }

  Widget _buildQCMOrVraiFaux(BuildContext context, CustomQuestionsMultiplayerController controller) {
    final options = controller.options;

    if (options.isEmpty) {
      return Center(child: Text(t(context, 'no_options_available')));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            controller.questionText,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ...options.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                onPressed: controller.iHaveAnswered
                    ? null
                    : () => controller.submitAnswer(entry.value),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                  minimumSize: const Size(double.infinity, 60),
                ),
                child: Text(entry.value),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ✅ NOUVEAU WIDGET STATEFUL POUR TEXTE À TROUS
class _TexteTrousWidget extends StatefulWidget {
  final CustomQuestionsMultiplayerController controller;

  const _TexteTrousWidget({Key? key, required this.controller}) : super(key: key);

  @override
  State<_TexteTrousWidget> createState() => _TexteTrousWidgetState();
}

class _TexteTrousWidgetState extends State<_TexteTrousWidget> {
  late Map<int, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    for (var i in widget.controller.blankIndices) {
      _controllers[i] = TextEditingController();
    }
    print('🔵 TextEditingControllers créés pour texte à trous (${_controllers.length} champs)');
  }

  @override
  void dispose() {
    print('🔴 TextEditingControllers détruits pour texte à trous');
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String t(String key) {
    final lang = context.read<LanguageProvider>().language;
    return CustomQuestionsTranslations.t(key, lang);
  }

  @override
  Widget build(BuildContext context) {
    print('🟢 _TexteTrousWidget rebuild');

    final questionText = widget.controller.questionText;
    final words = questionText.split(' ');
    final blankIndices = widget.controller.blankIndices;

    return SingleChildScrollView(
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
                    controller: _controllers[entry.key],
                    enabled: !widget.controller.iHaveAnswered,
                    decoration: const InputDecoration(
                      hintText: '____',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onChanged: (value) {
                      print('📝 Texte à trous [${entry.key}]: $value');
                    },
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
            onPressed: widget.controller.iHaveAnswered
                ? null
                : () {
              final userAnswers = <int, String>{};
              for (var i in blankIndices) {
                userAnswers[i] = _controllers[i]!.text;
              }
              print('✅ Soumission texte à trous: $userAnswers');
              widget.controller.submitTexteTrousAnswer(userAnswers);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text(t('validate'), style: const TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}

// ✅ NOUVEAU WIDGET STATEFUL POUR LES QUESTIONS OUVERTES
class _OpenQuestionWidget extends StatefulWidget {
  final CustomQuestionsMultiplayerController controller;

  const _OpenQuestionWidget({Key? key, required this.controller}) : super(key: key);

  @override
  State<_OpenQuestionWidget> createState() => _OpenQuestionWidgetState();
}

class _OpenQuestionWidgetState extends State<_OpenQuestionWidget> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    print('🔵 TextEditingController créé pour question ouverte');
  }

  @override
  void dispose() {
    print('🔴 TextEditingController détruit pour question ouverte');
    _textController.dispose();
    super.dispose();
  }

  String t(String key) {
    final lang = context.read<LanguageProvider>().language;
    return CustomQuestionsTranslations.t(key, lang);
  }

  @override
  Widget build(BuildContext context) {
    print('🟢 _OpenQuestionWidget rebuild');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.controller.questionText,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _textController,
            maxLines: 3,
            enabled: !widget.controller.iHaveAnswered,
            decoration: InputDecoration(
              hintText: t('your_answer_placeholder'),
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              print('📝 Question ouverte: $value');
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.controller.iHaveAnswered
                ? null
                : () {
              print('✅ Soumission question ouverte: ${_textController.text}');
              widget.controller.submitOpenAnswer(_textController.text);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: Text(t('validate'), style: const TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}