import 'package:flutter/material.dart';
import 'package:memoriz_bible/screens/games/QCM/qcm_translations.dart';
import 'qcm_game_controller_base.dart';
import 'qcm_multiplayer_controller.dart';
import 'package:provider/provider.dart';

import '../../../Bibliotheque.dart';
import 'qcm_solo_controller.dart';
import '../../../models/verse_model.dart';
import '../../../services/audio_service.dart';
import '../../../services/feedback_overlay.dart';
import '../../duels/game_results_page.dart';
import '../../../models/game_context.dart';
import '../../../models/language_provider.dart';


// ==============================================================================
// DONNÉES D'ANIMATION DES POINTS (pour le mode solo)
// ==============================================================================
class PointAnimationData {
  final int id;
  final int points;
  PointAnimationData(this.id, this.points);
}

// ==============================================================================
// PAGE PRINCIPALE QCM - GÈRE SOLO ET MULTIJOUEUR
// ==============================================================================
class QcmGamePage extends StatelessWidget {
  final GameContext gameContext;
  final Verse? verse;
  final String? roomCode;

  const QcmGamePage({
    super.key,
    required this.gameContext,
    this.verse,
    this.roomCode,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<QcmGameControllerBase>(
      create: (context) => _createController(context),
      child: const QcmGameView(),
    );
  }

  QcmGameControllerBase _createController(BuildContext context) {
    switch (gameContext) {
      case GameContext.duel:
        if (roomCode == null) throw ArgumentError('roomCode required for duel');
        return QcmMultiplayerController(roomCode: roomCode!);

      case GameContext.progression:
      case GameContext.sandbox:
        if (verse == null) throw ArgumentError('verse required for solo games');
        return QcmSoloController(
          verse: verse!,
          isSandbox: gameContext == GameContext.sandbox,
          onGameConcluded: (didWin) => _handleGameEnd(context, didWin),
        );
    }
  }

  void _handleGameEnd(BuildContext context, bool didWin) {
    final lang = context.read<LanguageProvider>().language;

    if (gameContext == GameContext.sandbox) {
      // Mode sandbox : simple dialogue de félicitations
      if (didWin) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(QcmTranslations.t('congratulations', lang)),
            content: Text(QcmTranslations.t('goal_reached', lang)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(QcmTranslations.t('ok', lang)),
              ),
            ],
          ),
        ).then((_) => Navigator.of(context).pop());
      } else {
        Navigator.of(context).pop();
      }
    } else {
      // Mode progression : sauvegarde + retour
      final score = didWin ? 100 : 0;
      context.read<VerseLibrary>().onGameFinished(
        verse: verse!,
        gameMode: "qcm",
        score: score,
      );
      Navigator.of(context).pop(true);
    }
  }
}

// ==============================================================================
// VUE UNIFIÉE QCM - SUPPORTE SOLO ET MULTIJOUEUR
// ==============================================================================
class QcmGameView extends StatefulWidget {
  const QcmGameView({super.key});

  @override
  State<QcmGameView> createState() => _QcmGameViewState();
}

class _QcmGameViewState extends State<QcmGameView> {
  // === VARIABLES POUR LE MODE SOLO ===
  String? _selectedAnswer;
  bool _answered = false;
  final List<PointAnimationData> _pointAnimations = [];
  int _animationIdCounter = 0;

  // === HELPER: Get translation ===
  String t(String key, {Map<String, String>? params}) {
    final lang = context.read<LanguageProvider>().language;
    return QcmTranslations.t(key, lang, params: params);
  }

  // === SOUMISSION DE RÉPONSE ===
  void _submitAnswer(QcmGameControllerBase controller, String answer) {
    // MULTIJOUEUR : soumission directe
    if (controller is QcmMultiplayerController) {
      controller.submitAnswer(answer);
      return;
    }

    // SOLO : effets audio/visuels puis soumission
    if (controller is QcmSoloController) {
      final isCorrect = answer.toLowerCase() == controller.correctAnswer.toLowerCase();

      // Effets audio et visuels
      if (isCorrect) {
        AudioService.instance.playSound('sound/correct.mp3');
        setState(() {
          _pointAnimations.add(PointAnimationData(_animationIdCounter++, 10));
        });
      } else {
        AudioService.instance.playSound('sound/incorrect.mp3');
      }

      controller.submitAnswer(answer);
    }
  }

  // === GESTION NAVIGATION AUTOMATIQUE (MULTIJOUEUR) ===
  void _handleAutoNavigation(QcmMultiplayerController controller) {
    if (controller.isGameFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => GameResultsPage(
                  players: controller.players,
                  questions: controller.questions,
                )
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QcmGameControllerBase>(
      builder: (context, controller, child) {
        // Navigation automatique pour multijoueur
        if (controller is QcmMultiplayerController) {
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
            // Animations de points (solo uniquement)
            if (controller is QcmSoloController)
              ..._pointAnimations.map((data) => PointsAnimationWidget(
                key: ValueKey(data.id),
                points: data.points,
                onCompleted: () => setState(() {
                  _pointAnimations.removeWhere((anim) => anim.id == data.id);
                }),
              )),

            if (controller is QcmMultiplayerController)
              CorrectAnswerAnimation(
                amITheWinner: controller.currentUserId == controller.correctAnswerWinnerId,
                winnerName: controller.correctAnswerWinnerName ?? t('waiting'),
                isVisible: controller.showCorrectAnswerAnimation,
                onComplete: () {
                  controller.hideAnimation();
                },
              ),
          ],
        );
      },
    );
  }

  // === APP BAR ADAPTATIVE ===
  PreferredSizeWidget _buildAppBar(QcmGameControllerBase controller) {
    String title = t('qcm_game');

    if (controller is QcmMultiplayerController) {
      title = '${t('multiplayer_game')} - ${controller.roomCode}';
    }

    return AppBar(
      title: Text(title),
      actions: [_buildScoreDisplay(controller)],
    );
  }

  // === AFFICHAGE DU SCORE ===
  Widget _buildScoreDisplay(QcmGameControllerBase controller) {
    if (controller is QcmMultiplayerController) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Text(
            '${controller.timeLeft}${t('seconds')}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _getTimerColor(controller.timeLeft),
            ),
          ),
        ),
      );
    }

    // Solo : Score actuel / objectif
    if (controller is QcmSoloController) {
      return Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Center(
          child: Text(
            "${t('score_label')}: ${controller.session.score} / ${controller.session.scoreToWin}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // === COULEUR DU TIMER ===
  Color _getTimerColor(int timeLeft) {
    if (timeLeft <= 3) return Colors.red.shade300;
    if (timeLeft <= 5) return Colors.orange.shade300;
    return Colors.white;
  }

  // === VUE DE CHARGEMENT ===
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

  // === CONTENU PRINCIPAL DU JEU ===
  Widget _buildGameContent(QcmGameControllerBase controller) {
    return Column(
      children: [
        _buildQuestionCard(controller),
        if (controller is QcmMultiplayerController && controller.status == 'answered')
          _buildRoundFeedback(controller),
        // ✅ Ne montrer les options que si on a une vraie question (pas un message de statut)
        if (!_isStatusMessage(controller.questionText))
          _buildOptionsSection(controller),
        _buildBottomSection(controller),
      ],
    );
  }

  // ✅ NOUVELLE MÉTHODE : Vérifie si le texte est un message de statut
  bool _isStatusMessage(String text) {
    final statusKeys = [
      'initializing', 'connecting', 'waiting_questions',
      'waiting_start', 'preparing_question', 'waiting'
    ];
    return statusKeys.contains(text);
  }

  Widget _buildRoundFeedback(QcmMultiplayerController controller) {
    final bool amITheWinner = controller.currentUserId == controller.correctAnswerWinnerId;
    final bool hasWinner = controller.correctAnswerWinnerId != null &&
        controller.correctAnswerWinnerId!.isNotEmpty;
    final String winnerName = controller.correctAnswerWinnerName ?? t('waiting');

    Color feedbackColor;
    IconData feedbackIcon;
    String feedbackText;

    if (hasWinner) {
      if (amITheWinner) {
        feedbackColor = Colors.green.shade100;
        feedbackIcon = Icons.star;
        feedbackText = t('you_found_answer');
      } else {
        feedbackColor = Colors.orange.shade100;
        feedbackIcon = Icons.person;
        feedbackText = t('player_found_answer', params: {'player': winnerName});
      }
    } else {
      feedbackColor = Colors.grey.shade100;
      feedbackIcon = Icons.access_time;
      feedbackText = t('time_expired');
    }

    return Card(
      color: feedbackColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(feedbackIcon, color: Colors.grey.shade700),
        title: Text(
          feedbackText,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // === CARTE QUESTION ===
  Widget _buildQuestionCard(QcmGameControllerBase controller) {
    // ✅ Traduire les clés de statut si nécessaire
    String displayText = controller.questionText;
    bool isStatusMessage = false;

    // Liste des clés de traduction possibles
    final translationKeys = [
      'initializing', 'connecting', 'waiting_questions',
      'waiting_start', 'preparing_question', 'waiting'
    ];

    // Si le texte est une clé de traduction, la traduire
    if (translationKeys.contains(displayText)) {
      displayText = t(displayText);
      isStatusMessage = true;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                isStatusMessage ? Icons.hourglass_empty : Icons.quiz,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 12),
              Text(
                displayText,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: isStatusMessage ? 18 : null, // Plus petit pour les messages de statut
                ),
                textAlign: TextAlign.center,
              ),
              // ✅ Ajouter un indicateur de chargement pour les messages de statut
              if (isStatusMessage) ...[
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // === SECTION OPTIONS ===
  Widget _buildOptionsSection(QcmGameControllerBase controller) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView.separated(
          itemCount: controller.options.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final option = controller.options[index];
            return _buildOptionButton(option, controller, index);
          },
        ),
      ),
    );
  }

  // === BOUTON OPTION ===
  Widget _buildOptionButton(String option, QcmGameControllerBase controller, int index) {
    final isDisabled = !_canSelectOption(controller);
    final buttonColor = _getButtonColor(controller, option);

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: isDisabled ? null : () => _submitAnswer(controller, option),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          disabledBackgroundColor: buttonColor,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: isDisabled ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                option,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isDisabled) _buildStatusIcon(option, controller),
          ],
        ),
      ),
    );
  }

  // === ICÔNE DE STATUT ===
  Widget _buildStatusIcon(String option, QcmGameControllerBase controller) {
    if (controller is QcmMultiplayerController) {
      if (option == controller.correctAnswer && controller.questionAlreadyAnswered) {
        return const Icon(Icons.check_circle, color: Colors.white, size: 24);
      }
      if (controller.iHaveAnswered && option == controller.myLastAnswer &&
          option != controller.correctAnswer && controller.questionAlreadyAnswered) {
        return const Icon(Icons.cancel, color: Colors.white, size: 24);
      }
    }

    if (controller is QcmSoloController) {
      if (option == controller.correctAnswer && controller.lastAnswer != null) {
        return const Icon(Icons.check_circle, color: Colors.white, size: 24);
      }
      if (option == controller.lastAnswer && controller.lastAnswer != null &&
          option != controller.correctAnswer) {
        return const Icon(Icons.cancel, color: Colors.white, size: 24);
      }
    }

    return const SizedBox.shrink();
  }

  // === SECTION INFÉRIEURE ===
  Widget _buildBottomSection(QcmGameControllerBase controller) {
    if (controller is QcmMultiplayerController) {
      return _buildMultiplayerBottomSection(controller);
    } else if (controller is QcmSoloController) {
      return _buildSoloBottomSection(controller);
    }
    return const SizedBox.shrink();
  }

  // === SECTION INFÉRIEURE MULTIJOUEUR ===
  Widget _buildMultiplayerBottomSection(QcmMultiplayerController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildScoreItem(t('score'), '${controller.currentScore}', Icons.stars),
          _buildScoreItem(t('time'), '${controller.timeLeft}${t('seconds')}', Icons.timer),
          if (controller.iHaveAnswered)
            _buildScoreItem(t('status'), t('answered'), Icons.check),
        ],
      ),
    );
  }

  // === SECTION INFÉRIEURE SOLO ===
  Widget _buildSoloBottomSection(QcmSoloController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('${t('score')}: ${controller.session.score}'),
          const SizedBox(height: 8),
          if (controller.canShowNextButton)
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward),
              label: Text(t('next_question')),
              onPressed: controller.loadNextQuestion,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
        ],
      ),
    );
  }

  // === ITEM DE SCORE (MULTIJOUEUR) ===
  Widget _buildScoreItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
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

  // === VÉRIFICATION SI UNE OPTION PEUT ÊTRE SÉLECTIONNÉE ===
  bool _canSelectOption(QcmGameControllerBase controller) {
    if (controller is QcmSoloController) {
      return controller.lastAnswer == null;
    }
    if (controller is QcmMultiplayerController) {
      return !controller.iHaveAnswered && controller.timeLeft > 0;
    }
    return false;
  }

  // === COULEUR DES BOUTONS D'OPTIONS ===
  Color _getButtonColor(QcmGameControllerBase controller, String option) {
    if (controller.isLoading) {
      return Theme.of(context).colorScheme.secondaryContainer;
    }

    // === MODE SOLO ===
    if (controller is QcmSoloController) {
      if (controller.lastAnswer == null) {
        return Theme.of(context).colorScheme.primary;
      }
      if (option == controller.correctAnswer) return Colors.green.shade600;
      if (option == controller.lastAnswer) return Colors.red.shade600;
      return Colors.grey.shade500;
    }

    // === MODE MULTIJOUEUR ===
    if (controller is QcmMultiplayerController) {
      if (controller.questionAlreadyAnswered) {
        if (option == controller.correctAnswer) {
          return Colors.green.shade600;
        }
        if (controller.iHaveAnswered && option == controller.myLastAnswer) {
          return Colors.red.shade600;
        }
        return Colors.grey.shade500;
      }

      if (!controller.iHaveAnswered) {
        return Theme.of(context).colorScheme.primary;
      }

      if (option == controller.myLastAnswer) {
        return Colors.blue.shade600;
      }

      return Colors.grey.shade400;
    }

    return Theme.of(context).colorScheme.secondaryContainer;
  }
}

class CorrectAnswerAnimation extends StatefulWidget {
  final bool amITheWinner;
  final String winnerName;
  final bool isVisible;
  final VoidCallback? onComplete;

  const CorrectAnswerAnimation({
    super.key,
    required this.amITheWinner,
    required this.winnerName,
    required this.isVisible,
    this.onComplete,
  });

  @override
  State<CorrectAnswerAnimation> createState() => _CorrectAnswerAnimationState();
}

class _CorrectAnswerAnimationState extends State<CorrectAnswerAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  String t(String key) {
    final lang = context.read<LanguageProvider>().language;
    return QcmTranslations.t(key, lang);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scale = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    if (widget.isVisible) {
      _controller.forward().whenComplete(() {
        widget.onComplete?.call();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final String title = widget.amITheWinner
        ? t('correct_answer')
        : t('round_finished');
    final String subtitle = widget.amITheWinner
        ? t('well_done')
        : widget.winnerName;

    return Positioned.fill(
      child: FadeTransition(
        opacity: _opacity,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            color: Colors.black54,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      title,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                      )
                  ),
                  const SizedBox(height: 12),
                  Text(
                      subtitle,
                      style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white70
                      )
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}