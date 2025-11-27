import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/language_provider.dart';
import 'DicteeMultiplayerController.dart';
import 'dictee_translations.dart';

class DicteeMultiplayerPage extends StatefulWidget {
  final String roomCode;
  // ✅ Plus de paramètre language

  const DicteeMultiplayerPage({
    Key? key,
    required this.roomCode,
  }) : super(key: key);

  @override
  _DicteeMultiplayerPageState createState() => _DicteeMultiplayerPageState();
}

class _DicteeMultiplayerPageState extends State<DicteeMultiplayerPage> {
  late DicteeMultiplayerController _controller;
  bool _controllerInitialized = false;

  // ✅ COMME RÉCITATION : Helper traduction avec context.read
  String t(String key) {
    final lang = context.read<LanguageProvider>().language;
    return DicteeTranslations.t(key, lang);
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_controllerInitialized) {
      // ✅ COMME RÉCITATION : Lire la langue depuis le Provider
      final lang = context.read<LanguageProvider>().language;

      _controller = DicteeMultiplayerController(
        roomCode: widget.roomCode,
        language: lang, // Passer la langue au contrôleur
      );
      _controllerInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_controllerInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text(t('multiplayer_dictation'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return ChangeNotifierProvider<DicteeMultiplayerController>.value(
      value: _controller,
      child: Consumer<DicteeMultiplayerController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return Scaffold(
              appBar: AppBar(title: Text(t('multiplayer_dictation'))),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (controller.isGameFinished) {
            return _buildGameFinishedScreen(controller);
          }

          return Scaffold(
            appBar: AppBar(
              title: Text("${t('dictee')} - ${t('room')} ${widget.roomCode}"),
              actions: [
                const Icon(Icons.timer),
                Text(" ${controller.globalTimeLeft}s "),
                const SizedBox(width: 16),
              ],
            ),
            body: Column(
              children: [
                _buildPlayersBar(controller),
                Expanded(
                  child: _buildMainContent(controller),
                ),
                _buildStatusBar(controller),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayersBar(DicteeMultiplayerController controller) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: controller.players.entries.map((entry) {
                  final playerId = entry.key;
                  final playerData = entry.value;
                  final playerName = playerData['name'] ?? t('player');
                  final playerScore = controller.players[playerId]?['score'] ?? 0;
                  final isCurrentUser = playerId == controller.currentUserId;

                  return Container(
                    margin: const EdgeInsets.only(right: 8.0),
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: isCurrentUser ? Colors.blue.shade100 : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCurrentUser ? Colors.blue : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: isCurrentUser ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "$playerName: $playerScore",
                          style: TextStyle(
                            fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                            color: isCurrentUser ? Colors.blue : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(DicteeMultiplayerController controller) {
    if (controller.status == 'waiting') {
      return _buildWaitingScreen(controller);
    }

    if (controller.status == 'answered') {
      return _buildAnsweredScreen(controller);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Référence du verset
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    controller.currentReference ?? '',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.volume_up),
                    label: Text(t('listen_verse')),
                    onPressed: controller.hasSubmitted || controller.questionAlreadyAnswered
                        ? null
                        : () => controller.playVerse(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Timer local si actif
          if (controller.timerActive)
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      '${t('input_time_remaining')}: ${controller.timeRemaining}s',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Zone de saisie
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: controller.textController,
                    maxLines: 6,
                    enabled: !controller.hasSubmitted && !controller.questionAlreadyAnswered,
                    decoration: InputDecoration(
                      hintText: t('write_your_answer'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: (controller.hasSubmitted ||
                        controller.questionAlreadyAnswered ||
                        controller.textController.text.isEmpty)
                        ? null
                        : () => controller.submitAnswer(),
                    child: controller.isVerifying
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(t('submitting')),
                      ],
                    )
                        : Text(controller.hasSubmitted ? t('submitted') : t('submit_answer')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingScreen(DicteeMultiplayerController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            t('waiting_for_game'),
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 32),
          Text(
            '${t('players_connected')}: ${controller.players.length}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnsweredScreen(DicteeMultiplayerController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            Text(
              t('question_completed'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (controller.correctAnswerWinnerName != null)
              Text(
                '${t('winner')}: ${controller.correctAnswerWinnerName}',
                style: const TextStyle(fontSize: 18),
              ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${t('correct_answer')}:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      controller.correctText,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              t('next_question_soon'),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameFinishedScreen(DicteeMultiplayerController controller) {
    final ranking = controller.playerRanking;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('game_finished')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(
              Icons.emoji_events,
              size: 64,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              t('game_finished'),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${t('final_ranking')}:',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: ranking.length,
                          itemBuilder: (context, index) {
                            final entry = ranking[index];
                            final playerId = entry.key;
                            final score = entry.value;
                            final playerName = controller.players[playerId]?['name'] ?? t('player');
                            final isCurrentUser = playerId == controller.currentUserId;

                            return Card(
                              color: isCurrentUser ? Colors.blue.shade50 : null,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: index == 0 ? Colors.amber :
                                  index == 1 ? Colors.grey :
                                  index == 2 ? Colors.brown :
                                  Colors.blue.shade100,
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: index < 3 ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  playerName,
                                  style: TextStyle(
                                    fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                trailing: Text(
                                  '$score ${t('pts')}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(t('return_menu')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(DicteeMultiplayerController controller) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${t('question')} ${controller.localCurrentQuestionIndex + 1}/${controller.questions.length}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            '${t('score')}: ${controller.currentScore}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}