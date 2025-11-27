import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Bibliotheque.dart';
import '../../../models/verse_model.dart';
import '../../../models/game_context.dart';
import '../../../models/language_provider.dart';
import '../../../services/audio_service.dart';
import '../../../services/feedback_overlay.dart';
import 'texte_a_trous_controller_base.dart';
import 'texte_a_trous_solo_controller.dart';
import 'texte_a_trous_multiplayer_controller.dart';
import 'texte_a_trous_translations.dart';
import '../../duels/game_results_page.dart';

// ==============================================================================
// DONNÉES D'ANIMATION DES POINTS
// ==============================================================================
class PointAnimationData {
  final int id;
  final int points;
  PointAnimationData(this.id, this.points);
}

// ==============================================================================
// PAGE PRINCIPALE TEXTE À TROUS
// ==============================================================================
class TexteATrousPage extends StatelessWidget {
  final GameContext gameContext;
  final Verse? verse;
  final String? roomCode;

  const TexteATrousPage({
    super.key,
    required this.gameContext,
    this.verse,
    this.roomCode,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TexteATrousControllerBase>(
      create: (context) => _createController(context),
      child: const TexteATrousGameView(),
    );
  }

  TexteATrousControllerBase _createController(BuildContext context) {
    switch (gameContext) {
      case GameContext.duel:
        if (roomCode == null) throw ArgumentError('Code de salle requis pour un duel');
        return TexteATrousMultiplayerController(roomCode: roomCode!);

      case GameContext.progression:
      case GameContext.sandbox:
        if (verse == null) throw ArgumentError('Verset requis pour les jeux solo');
        return TexteATrousSoloController(
          verse: verse!,
          isSandbox: gameContext == GameContext.sandbox,
          onGameConcluded: (didWin) => _handleGameEnd(context, didWin),
        );
    }
  }

  void _handleGameEnd(BuildContext context, bool didWin) {
    final lang = context.read<LanguageProvider>().language;

    if (gameContext == GameContext.sandbox) {
      if (didWin) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(TexteATrousTranslations.t('congratulations', lang)),
            content: Text(TexteATrousTranslations.t('goal_reached', lang)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text(TexteATrousTranslations.t('finish', lang)),
              ),
            ],
          ),
        );
      } else {
        Navigator.of(context).pop();
      }
    } else {
      final score = didWin ? 100 : 0;
      context.read<VerseLibrary>().onGameFinished(
        verse: verse!,
        gameMode: "texte_a_trous",
        score: score,
      ).then((_) {
        Navigator.of(context).pop(true);
      });
    }
  }
}

// ==============================================================================
// VUE UNIFIÉE TEXTE À TROUS
// ==============================================================================
class TexteATrousGameView extends StatefulWidget {
  const TexteATrousGameView({super.key});

  @override
  State<TexteATrousGameView> createState() => _TexteATrousGameViewState();
}

class _TexteATrousGameViewState extends State<TexteATrousGameView> {
  List<TextEditingController> _controllers = [];
  final List<PointAnimationData> _pointAnimations = [];
  int _animationIdCounter = 0;
  int _lastQuestionIndex = -1;

  // === HELPER: Get translation ===
  String t(String key, {Map<String, String>? params}) {
    final lang = context.read<LanguageProvider>().language;
    return TexteATrousTranslations.t(key, lang, params: params);
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (var c in _controllers) {
      c.dispose();
    }
    _controllers.clear();
  }

  void _verifierReponses(TexteATrousSoloController controller) {
    final reponsesUtilisateur = _controllers.map((c) => c.text.trim()).toList();

    controller.verifierReponses(reponsesUtilisateur).then((_) {
      if (controller.bonneReponse) {
        AudioService.instance.playSound('sound/correct.mp3');
        setState(() {
          _pointAnimations.add(PointAnimationData(_animationIdCounter++, 10));
        });
      } else {
        AudioService.instance.playSound('sound/incorrect.mp3');

        final resultats = controller.resultatsVerification;
        for (int i = 0; i < controller.reponses.length &&
            i < _controllers.length; i++) {
          if (i < resultats.length && !resultats[i]) {
            _controllers[i].text = controller.reponses[i];
          }
        }
      }
    });
  }

  void _verifierReponsesMultiplayer(
      TexteATrousMultiplayerController controller) {
    final reponsesUtilisateur = _controllers.map((c) => c.text.trim()).toList();

    controller.verifierReponses(reponsesUtilisateur).then((_) {
      if (!mounted) return;

      final resultats = controller.resultatsVerification;

      for (int i = 0; i < resultats.length && i < _controllers.length; i++) {
        if (!resultats[i] && _controllers[i].text.isNotEmpty) {
          _controllers[i].clear();
        }
      }

      if (controller.bonneReponse) {
        AudioService.instance.playSound('sound/correct.mp3');
      } else {
        final aDesNouvellesBonnes = resultats.any((r) => r);
        AudioService.instance.playSound(
            aDesNouvellesBonnes ? 'sound/correct.mp3' : 'sound/incorrect.mp3'
        );
      }

      setState(() {});
    });
  }

  void _initializeControllers(int count) {
    // Ne rien faire si le nombre est déjà correct
    if (_controllers.length == count) return;

    _disposeControllers();
    _controllers = List.generate(count, (_) => TextEditingController());
    print('DEBUG: Initialized $count fresh controllers');

    if (mounted) {
      setState(() {});
    }
  }

  void _clearAllControllers() {
    for (var controller in _controllers) {
      controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TexteATrousControllerBase>(
      builder: (context, controller, child) {
        if (controller.currentQuestionIndex != _lastQuestionIndex) {
          print(
              'DEBUG: Question changée de $_lastQuestionIndex à ${controller.currentQuestionIndex}');
          _lastQuestionIndex = controller.currentQuestionIndex;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _controllers.length != controller.reponses.length) {
              _initializeControllers(controller.reponses.length);
            }
          });
        }

        if (_controllers.length != controller.reponses.length) {
          if (_controllers.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _initializeControllers(controller.reponses.length);
              }
            });
          }
        }

        if (controller is TexteATrousMultiplayerController) {
          _handleAutoNavigation(controller);
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            Scaffold(
              appBar: _buildAppBar(controller),
              body: controller.isLoading
                  ? _buildLoadingView()
                  : _buildGameContent(controller),
            ),
            if (controller is TexteATrousSoloController)
              ..._pointAnimations.map((data) =>
                  PointsAnimationWidget(
                    key: ValueKey(data.id),
                    points: data.points,
                    onCompleted: () =>
                        setState(() {
                          _pointAnimations.removeWhere((anim) =>
                          anim.id == data.id);
                        }),
                  )),
          ],
        );
      },
    );
  }

  bool _hasTextInControllers() {
    return _controllers.any((controller) => controller.text.isNotEmpty);
  }

  void _handleAutoNavigation(TexteATrousMultiplayerController controller) {
    if (controller.isGameFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    GameResultsPage(
                      players: controller.players,
                      questions: controller.questions,
                    )
            ),
          );
        }
      });
    }
  }

  PreferredSizeWidget _buildAppBar(TexteATrousControllerBase controller) {
    String title = t('fill_blanks_game');

    if (controller is TexteATrousMultiplayerController) {
      title = '${t('multiplayer_game')} - ${controller.roomCode}';
    }

    return AppBar(
      title: Text(title),
      actions: [
        if (controller is TexteATrousSoloController && !controller.isLoading)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                "${t('score_label')}: ${controller.currentScore} / ${controller.maxScore}",
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(t('loading_question')),
        ],
      ),
    );
  }

  Widget _buildGameContent(TexteATrousControllerBase controller) {
    if (controller.indices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _translateIfNeeded(controller.versetModifie),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 18),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => controller.restartGame(),
                child: Text(t('restart')),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildReferenceSection(controller),
            _buildProgressBar(controller),
            const SizedBox(height: 24),

            _buildTextWithBlanks(controller),

            const SizedBox(height: 32),
            _buildActionButtons(controller),
          ],
        ),
      ),
    );
  }

  String _translateIfNeeded(String text) {
    final statusKeys = [
      'initializing', 'connecting', 'waiting_questions',
      'waiting_start', 'preparing_question', 'waiting',
      'loading_error', 'verification_error' // ✅ Ajout des erreurs
    ];

    if (statusKeys.contains(text)) {
      return t(text);
    }
    return text;
  }

  Widget _buildReferenceSection(TexteATrousControllerBase controller) {
    if (controller.currentReference == null) return const SizedBox.shrink();

    return Column(
      children: [
        Text(
          controller.currentReference!,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildProgressBar(TexteATrousControllerBase controller) {
    if (controller is! TexteATrousSoloController)
      return const SizedBox.shrink();

    final soloController = controller as TexteATrousSoloController;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: soloController.currentScore / soloController.maxScore,
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                color: Colors.green[600],
              ),
            ),
            const SizedBox(width: 12),
            Text("${soloController.currentScore} / ${soloController.maxScore}"),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "${t('level')}: ${soloController.niveauActuel}",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }


  Widget _buildActionButtons(TexteATrousControllerBase controller) {
    if (controller is TexteATrousMultiplayerController) {
      return Column(
        children: [
          if (controller.status == 'answered')
            _buildRoundFeedback(controller),

          _buildTimerAndActionButton(controller),

          _buildMultiplayerBottomSection(controller),
        ],
      );
    }

    final soloController = controller as TexteATrousSoloController;

    if (!soloController.answered) {
      return ElevatedButton(
        onPressed: () => _verifierReponses(soloController),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(t('verify'), style: const TextStyle(fontSize: 18)),
      );
    }

    return Column(
      children: [
        soloController.bonneReponse
            ? Text(
          t('well_done'),
          style: const TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        )
            : Text(
          t('not_quite_right'),
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.arrow_forward),
          label: Text(t('continue')),
          onPressed: () {
            _clearAllControllers();
            soloController.loadNextQuestion();
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildRoundFeedback(TexteATrousMultiplayerController controller) {
    if (!controller.answered) return const SizedBox.shrink();

    Color feedbackColor = controller.bonneReponse
        ? Colors.green.shade100
        : Colors.red.shade100;

    IconData feedbackIcon = controller.bonneReponse
        ? Icons.check_circle
        : Icons.cancel;

    String feedbackText = controller.bonneReponse
        ? t('all_correct')
        : t('some_incorrect');

    return Card(
      color: feedbackColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(feedbackIcon, color: Colors.grey.shade700),
        title: Text(
          feedbackText,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
            t('score_obtained', params: {
              'points': '${controller.answered ? (controller.bonneReponse ? 10 : 0) : 0}'
            })),
      ),
    );
  }

  Widget _buildTimerAndActionButton(
      TexteATrousMultiplayerController controller) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (controller.timeLeft > 0 && !controller.answered)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: _getTimerColor(controller.timeLeft),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${controller.timeLeft}s",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _getButtonAction(controller),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getButtonColor(controller),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _getButtonText(controller),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiplayerBottomSection(
      TexteATrousMultiplayerController controller) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreItem(
                  t('score'), '${controller.currentScore}', Icons.stars),
              _buildScoreItem(
                  t('status'),
                  controller.iHaveAnswered ? t('answered') : t('in_progress'),
                  controller.iHaveAnswered ? Icons.check : Icons.edit
              ),
              _buildScoreItem(
                  t('answers'),
                  '${controller.reponses.length}',
                  Icons.quiz
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (controller.players.isNotEmpty) ...[
            Text(
              t('ranking'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: controller.playerRanking.length,
                itemBuilder: (context, index) {
                  final entry = controller.playerRanking[index];
                  final playerData = controller.players[entry.key];
                  final name = playerData['name'] ?? t('unknown_player');
                  final isMe = entry.key == controller.currentUserId;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMe ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                      borderRadius: BorderRadius.circular(8),
                      border: isMe ? Border.all(color: Theme.of(context).primaryColor, width: 1) : null,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _getRankColor(index),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isMe ? '$name (${t('you')})' : name,
                            style: TextStyle(
                              fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value} ${t('points')}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScoreItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Color _getTimerColor(int timeLeft) {
    if (timeLeft <= 5) return Colors.red.shade400;
    if (timeLeft <= 10) return Colors.orange.shade400;
    return Colors.blue.shade400;
  }

  Color _getButtonColor(TexteATrousMultiplayerController controller) {
    if (controller.bonneReponse) return Colors.green.shade600;
    if (controller.timeLeft <= 0) return Colors.grey.shade400;
    if (controller.answered) return Colors.orange.shade400;
    return Theme.of(context).primaryColor;
  }

  String _getButtonText(TexteATrousMultiplayerController controller) {
    if (controller.bonneReponse) return t('all_answers_found');
    if (controller.timeLeft <= 0) return t('time_expired');
    if (controller.answered) return t('checking');
    if (!_hasTextInControllers()) return t('enter_answers');
    return t('verify_answers');
  }

  VoidCallback? _getButtonAction(TexteATrousMultiplayerController controller) {
    if (controller.timeLeft <= 0 || controller.bonneReponse) {
      return null;
    }

    if (!_hasTextInControllers()) {
      return null;
    }

    return () => _verifierReponsesMultiplayer(controller);
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 0:
        return Colors.amber.shade600;
      case 1:
        return Colors.grey.shade500;
      case 2:
        return Colors.brown.shade400;
      default:
        return Colors.blue.shade400;
    }
  }

  Widget _buildTextWithBlanks(TexteATrousControllerBase controller) {
    final displayText = _translateIfNeeded(controller.versetModifie);

    final statusKeys = [
      'initializing', 'connecting', 'waiting_questions',
      'waiting_start', 'preparing_question', 'waiting',
      'loading_error', 'verification_error'
    ];

    final errorKeys = ['loading_error', 'verification_error'];

    if (statusKeys.contains(controller.versetModifie)) {
      final isError = errorKeys.contains(controller.versetModifie);

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.hourglass_empty,
                size: 48,
                color: isError ? Colors.red : Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                displayText,
                style: TextStyle(
                  fontSize: 18,
                  color: isError ? Colors.red : Colors.grey[700],
                  fontWeight: isError ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
              if (!isError) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      );
    }

    if (_controllers.isEmpty && controller.reponses.isNotEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final mots = displayText.split(" ");
    int champIndex = 0;

    return Wrap(
      key: ValueKey(controller.currentQuestionIndex),
      spacing: 8,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: List.generate(mots.length, (i) {
        if (controller.indices.contains(i)) {
          if (champIndex >= _controllers.length) {
            champIndex++;
            return const SizedBox.shrink();
          }

          final controllerIndex = champIndex;
          final textController = _controllers[controllerIndex];

          bool estCorrectParMoi = false;
          bool estCorrectParAutre = false;

          if (controller is TexteATrousMultiplayerController) {
            final reponsesGlobales = controller.globalCorrectAnswers;
            final mesReponses = controller.myLastAnswers ?? [];

            if (controllerIndex < reponsesGlobales.length &&
                reponsesGlobales[controllerIndex].isNotEmpty) {
              if (controllerIndex < mesReponses.length &&
                  mesReponses[controllerIndex].isNotEmpty &&
                  controller.fuzzyMatch(mesReponses[controllerIndex],
                      controller.reponses[controllerIndex])) {
                estCorrectParMoi = true;
              } else {
                estCorrectParAutre = true;
              }

              textController.text = reponsesGlobales[controllerIndex];
            }
          } else {
            if (controller.answered &&
                controllerIndex < controller.resultatsVerification.length) {
              estCorrectParMoi =
              controller.resultatsVerification[controllerIndex];
            }
          }

          final champ = SizedBox(
            width: 100,
            child: TextField(
              controller: textController,
              enabled: !estCorrectParMoi && !estCorrectParAutre,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                filled: estCorrectParMoi || estCorrectParAutre,
                fillColor: estCorrectParMoi
                    ? Colors.green[100]
                    : (estCorrectParAutre ? Colors.blue[100] : null),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: estCorrectParMoi
                        ? Colors.green
                        : (estCorrectParAutre ? Colors.blue : Colors.grey),
                    width: (estCorrectParMoi || estCorrectParAutre) ? 2 : 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: estCorrectParMoi
                        ? Colors.green
                        : (estCorrectParAutre ? Colors.blue : Colors.grey),
                    width: (estCorrectParMoi || estCorrectParAutre) ? 2 : 1,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: estCorrectParMoi ? Colors.green : Colors.blue,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(8),
                suffixIcon: (estCorrectParMoi || estCorrectParAutre)
                    ? Icon(
                  estCorrectParMoi ? Icons.check_circle : Icons.visibility,
                  color: estCorrectParMoi ? Colors.green : Colors.blue,
                  size: 20,
                )
                    : null,
              ),
              style: TextStyle(
                fontSize: 16,
                fontWeight: (estCorrectParMoi || estCorrectParAutre)
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: estCorrectParMoi
                    ? Colors.green[900]
                    : (estCorrectParAutre ? Colors.blue[900] : Colors.black),
              ),
            ),
          );
          champIndex++;
          return champ;
        } else {
          return Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              mots[i],
              style: const TextStyle(fontSize: 18, height: 1.5),
            ),
          );
        }
      }),
    );
  }
}