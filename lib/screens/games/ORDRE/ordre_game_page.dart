import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../Bibliotheque.dart';
import 'ordre_solo_controller.dart';
import 'ordre_multiplayer_controller.dart';
import '../../../models/verse_model.dart';
import '../../../models/game_context.dart';
import '../../../models/language_provider.dart';
import 'ordre_game_controller_base.dart';
import '../../../services/audio_service.dart';
import '../../../services/feedback_overlay.dart';
import '../../duels/game_results_page.dart';
import 'ordre_translations.dart';

// ==============================================================================
// DONNÉES D'ANIMATION DES POINTS
// ==============================================================================
class PointAnimationData {
  final int id;
  final int points;
  const PointAnimationData(this.id, this.points);
}

// ==============================================================================
// OBJET POUR TRANSPORTER LES DONNÉES DE MOT
// ==============================================================================
@immutable
class WordData {
  final String word;
  final int? fromIndex;

  const WordData({required this.word, this.fromIndex});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is WordData &&
              runtimeType == other.runtimeType &&
              word == other.word &&
              fromIndex == other.fromIndex;

  @override
  int get hashCode => word.hashCode ^ fromIndex.hashCode;
}

// ==============================================================================
// PAGE PRINCIPALE ORDRE
// ==============================================================================
class OrdreGamePage extends StatelessWidget {
  final GameContext gameContext;
  final Verse? verse;
  final String? roomCode;

  const OrdreGamePage({
    super.key,
    required this.gameContext,
    this.verse,
    this.roomCode,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<OrdreGameControllerBase>(
      create: (context) => _createController(context),
      child: const OrdreGameView(),
    );
  }

  OrdreGameControllerBase _createController(BuildContext context) {
    final lang = context.read<LanguageProvider>().language;

    return switch (gameContext) {
      GameContext.duel => OrdreMultiplayerController(
          roomCode: roomCode ?? (throw ArgumentError('roomCode required for duel'))),
      GameContext.progression ||
      GameContext.sandbox =>
          OrdreSoloController(
            verse: verse ?? (throw ArgumentError('verse required for solo games')),
            isSandbox: gameContext == GameContext.sandbox,
            onGameConcluded: (didWin) => _handleGameEnd(context, didWin),
            language: lang,
          ),
    };
  }

  void _handleGameEnd(BuildContext context, bool didWin) {
    HapticFeedback.mediumImpact();
    final lang = context.read<LanguageProvider>().language;

    if (gameContext == GameContext.sandbox) {
      if (didWin) {
        _showSuccessDialog(context, lang);
      } else {
        Navigator.of(context).pop();
      }
    } else {
      _handleProgressionEnd(context, didWin);
    }
  }

  void _showSuccessDialog(BuildContext context, String lang) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 16,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green.shade50, Colors.green.shade100],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade400,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                OrdreTranslations.t('congratulations', lang),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                OrdreTranslations.t('all_verses_ordered', lang),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    OrdreTranslations.t('perfect', lang),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleProgressionEnd(BuildContext context, bool didWin) {
    final score = didWin ? 100 : 0;
    context.read<VerseLibrary>().onGameFinished(
      verse: verse!,
      gameMode: "ordre",
      score: score,
    );
    Navigator.of(context).pop(true);
  }
}

// ==============================================================================
// VUE PRINCIPALE
// ==============================================================================
class OrdreGameView extends StatefulWidget {
  const OrdreGameView({super.key});

  @override
  State<OrdreGameView> createState() => _OrdreGameViewState();
}

class _OrdreGameViewState extends State<OrdreGameView>
    with TickerProviderStateMixin {
  final List<PointAnimationData> _pointAnimations = [];
  int _animationIdCounter = 0;
  late AnimationController _pageController;
  late Animation<double> _fadeAnimation;

  String t(String key, {Map<String, String>? params}) {
    final lang = context.read<LanguageProvider>().language;
    return OrdreTranslations.t(key, lang, params: params);
  }

  @override
  void initState() {
    super.initState();
    _pageController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeInOut),
    );
    _pageController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrdreGameControllerBase>(
      builder: (context, controller, child) {
        if (controller is OrdreMultiplayerController) {
          _handleAutoNavigation(controller);
        }

        return AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) => FadeTransition(
            opacity: _fadeAnimation,
            child: Scaffold(
              backgroundColor: Colors.grey.shade50,
              appBar: _buildAppBar(controller),
              body: controller.isLoading
                  ? _LoadingView()
                  : _GameContent(
                controller: controller,
                onSubmitAnswer: () => _submitAnswer(controller),
              ),
              floatingActionButton: Stack(
                children: [
                  if (controller is OrdreSoloController)
                    ..._buildPointAnimations(),
                  if (controller is OrdreMultiplayerController)
                    _buildCorrectAnswerAnimation(controller),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: _ActionButton(
                      controller: controller,
                      onSubmit: () => _submitAnswer(controller),
                    ),
                  ),
                ],
              ),
              floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
            ),
          ),
        );
      },
    );
  }

  void _handleAutoNavigation(OrdreMultiplayerController controller) {
    if (controller.isGameFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          final resultDoc = await FirebaseFirestore.instance
              .collection('game_results')
              .doc(controller.roomCode)
              .get();

          final resultData = resultDoc.data();

          if (resultData != null && mounted) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    GameResultsPage(
                      players: resultData['scores'] ?? {},
                      questions: resultData['questionsSummary'] ?? [],
                    ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
              ),
            );
          }
        }
      });
    }
  }

  void _submitAnswer(OrdreGameControllerBase controller) {
    HapticFeedback.mediumImpact();

    if (controller is OrdreSoloController) {
      _handleSoloSubmission(controller);
    }
    controller.submitAnswer();
  }

  void _handleSoloSubmission(OrdreSoloController controller) {
    final userAnswer = controller.placedWords.whereType<String>().toList();
    final isCorrect =
        userAnswer.join(' ') == controller.correctOrder.join(' ');

    if (isCorrect) {
      HapticFeedback.heavyImpact();
      AudioService.instance.playSound('sounds/correct.mp3');
      _addPointAnimation(10);
    } else {
      HapticFeedback.vibrate();
      AudioService.instance.playSound('sounds/incorrect.mp3');
    }
  }

  void _addPointAnimation(int points) {
    if (mounted) {
      setState(() {
        _pointAnimations
            .add(PointAnimationData(_animationIdCounter++, points));
      });
    }
  }

  List<Widget> _buildPointAnimations() {
    return _pointAnimations
        .map((data) => PointsAnimationWidget(
      key: ValueKey(data.id),
      points: data.points,
      onCompleted: () => _removePointAnimation(data.id),
    ))
        .toList();
  }

  void _removePointAnimation(int id) {
    if (mounted) {
      setState(() {
        _pointAnimations.removeWhere((anim) => anim.id == id);
      });
    }
  }

  Widget _buildCorrectAnswerAnimation(OrdreMultiplayerController controller) {
    return CorrectAnswerAnimation(
      amITheWinner:
      controller.currentUserId == controller.correctAnswerWinnerId,
      winnerName: controller.correctAnswerWinnerName ?? t('a_player'),
      isVisible: controller.showCorrectAnswerAnimation,
      onComplete: controller.hideAnimation,
    );
  }

  PreferredSizeWidget _buildAppBar(OrdreGameControllerBase controller) {
    final title = controller is OrdreMultiplayerController
        ? t('multiplayer_order')
        : t('word_order_game');

    return AppBar(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.grey.shade800,
      actions: [_ScoreDisplay(controller: controller)],
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

// ==============================================================================
// LOADING VIEW
// ==============================================================================
class _LoadingView extends StatefulWidget {
  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  String t(String key) {
    final lang = context.read<LanguageProvider>().language;
    return OrdreTranslations.t(key, lang);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _animation.value * 2 * 3.14159,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            t('loading_game'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// SCORE DISPLAY
// ==============================================================================
class _ScoreDisplay extends StatelessWidget {
  final OrdreGameControllerBase controller;

  const _ScoreDisplay({required this.controller});

  String t(BuildContext context, String key) {
    final lang = context.read<LanguageProvider>().language;
    return OrdreTranslations.t(key, lang);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getScoreBackgroundColor(),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildScoreContent(context),
    );
  }

  Widget _buildScoreContent(BuildContext context) {
    return switch (controller) {
      OrdreMultiplayerController multi => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 16,
            color: _getTimerColor(multi.timeLeft),
          ),
          const SizedBox(width: 4),
          Text(
            '${multi.timeLeft}${t(context, 'seconds')}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _getTimerColor(multi.timeLeft),
            ),
          ),
        ],
      ),
      OrdreSoloController solo => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.stars_rounded,
            size: 16,
            color: Colors.amber,
          ),
          const SizedBox(width: 4),
          Text(
            "${solo.session.score}/${solo.session.scoreToWin}",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Color _getScoreBackgroundColor() {
    return switch (controller) {
      OrdreMultiplayerController multi =>
          _getTimerBackgroundColor(multi.timeLeft),
      OrdreSoloController _ => Colors.blue.shade400,
      _ => Colors.grey,
    };
  }

  Color _getTimerBackgroundColor(int timeLeft) => switch (timeLeft) {
    <= 5 => Colors.red.shade400,
    <= 10 => Colors.orange.shade400,
    _ => Colors.green.shade400,
  };

  Color _getTimerColor(int timeLeft) => Colors.white;
}

// ==============================================================================
// GAME CONTENT — 👈 RESTRUCTURÉ : une seule colonne verticale, un seul
// scroll pour toute la page, au lieu de deux colonnes côte à côte avec
// chacune son propre scroll étroit et peu naturel.
// ==============================================================================
class _GameContent extends StatelessWidget {
  final OrdreGameControllerBase controller;
  final VoidCallback onSubmitAnswer;

  const _GameContent({
    required this.controller,
    required this.onSubmitAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxHeight < 600;
        final horizontalPadding = isSmallScreen ? 12.0 : 20.0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            isSmallScreen ? 12.0 : 20.0,
            horizontalPadding,
            100, // espace réservé pour le bouton flottant en bas
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _QuestionCard(controller: controller),
              if (controller is OrdreMultiplayerController &&
                  controller.status == 'answered')
                _RoundFeedback(
                    controller: controller as OrdreMultiplayerController),
              const SizedBox(height: 20),
              // === Banque de mots (en haut, en Wrap) ===
              _WordBankSection(controller: controller),
              const SizedBox(height: 20),
              // === Zone de réponse (en dessous, en Wrap) ===
              _AnswerSection(controller: controller),
            ],
          ),
        );
      },
    );
  }
}

// ==============================================================================
// WORD BANK SECTION — 👈 RENOMMÉ depuis _WordBankColumn.
// Affiche les mots en Wrap (ils reviennent à la ligne naturellement) au
// lieu d'une colonne verticale scrollable indépendante.
// ==============================================================================
class _WordBankSection extends StatelessWidget {
  final OrdreGameControllerBase controller;

  const _WordBankSection({required this.controller});

  String t(BuildContext context, String key) {
    final lang = context.read<LanguageProvider>().language;
    return OrdreTranslations.t(key, lang);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DragTarget<WordData>(
        onWillAcceptWithDetails: (details) => details.data.fromIndex != null,
        onAcceptWithDetails: (details) {
          HapticFeedback.lightImpact();
          controller.returnWordToBank(
            details.data.word,
            details.data.fromIndex!,
          );
        },
        builder: (context, candidateData, rejectedData) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.library_books_rounded,
                      color: Colors.grey.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      t(context, 'word_bank'),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: controller.wordBank
                      .map((word) => _DraggableWord(
                    controller: controller,
                    word: word,
                    fromIndex: null,
                  ))
                      .toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ==============================================================================
// QUESTION CARD
// ==============================================================================
class _QuestionCard extends StatelessWidget {
  final OrdreGameControllerBase controller;

  const _QuestionCard({required this.controller});

  String t(BuildContext context, String key) {
    final lang = context.read<LanguageProvider>().language;
    return OrdreTranslations.t(key, lang);
  }

  @override
  Widget build(BuildContext context) {
    String displayText = controller.questionText;

    final translationKeys = [
      'put_words_in_order',
      'no_verses_found',
      'loading_error',
      'initializing',
      'connecting',
      'waiting_questions',
      'waiting_start',
      'preparing_question',
    ];

    if (translationKeys.contains(displayText)) {
      displayText = t(context, displayText);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (controller.currentReference != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                controller.currentReference!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            displayText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _RoundFeedback extends StatelessWidget {
  final OrdreMultiplayerController controller;

  const _RoundFeedback({required this.controller});

  String t(BuildContext context, String key, {Map<String, String>? params}) {
    final lang = context.read<LanguageProvider>().language;
    return OrdreTranslations.t(key, lang, params: params);
  }

  @override
  Widget build(BuildContext context) {
    final amITheWinner =
        controller.currentUserId == controller.correctAnswerWinnerId;
    final hasWinner = controller.correctAnswerWinnerId?.isNotEmpty ?? false;
    final winnerName = controller.correctAnswerWinnerName ?? t(context, 'a_player');

    final (color, icon, text, iconColor) =
    _getFeedbackData(context, amITheWinner, hasWinner, winnerName);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (Color, IconData, String, Color) _getFeedbackData(
      BuildContext context, bool amITheWinner, bool hasWinner, String winnerName) {
    if (hasWinner) {
      return amITheWinner
          ? (
      Colors.green.shade100,
      Icons.emoji_events_rounded,
      t(context, 'you_found_order'),
      Colors.green.shade600
      )
          : (
      Colors.orange.shade100,
      Icons.person_rounded,
      t(context, 'player_found_order', params: {'player': winnerName}),
      Colors.orange.shade600
      );
    }
    return (
    Colors.grey.shade100,
    Icons.schedule_rounded,
    t(context, 'time_expired_revealed'),
    Colors.grey.shade600
    );
  }
}

// ==============================================================================
// ANSWER SECTION — 👈 RENOMMÉ depuis _AnswerColumn.
// Affiche les slots en Wrap au lieu d'une colonne scrollable indépendante ;
// s'insère maintenant dans le scroll unique de la page.
// ==============================================================================
class _AnswerSection extends StatefulWidget {
  final OrdreGameControllerBase controller;

  const _AnswerSection({required this.controller});

  @override
  State<_AnswerSection> createState() => _AnswerSectionState();
}

class _AnswerSectionState extends State<_AnswerSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String t(BuildContext context, String key) {
    final lang = context.read<LanguageProvider>().language;
    return OrdreTranslations.t(key, lang);
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCorrect = widget.controller.isAnswered &&
        widget.controller.placedWords.whereType<String>().join(' ') ==
            widget.controller.correctOrder.join(' ');

    if (widget.controller.isAnswered) {
      _pulseController.forward().then((_) => _pulseController.reverse());
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.controller.isAnswered ? _pulseAnimation.value : 1.0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.controller.isAnswered
                    ? isCorrect
                    ? [Colors.green.shade100, Colors.green.shade200]
                    : [Colors.red.shade100, Colors.red.shade200]
                    : [Colors.grey.shade100, Colors.grey.shade200],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.controller.isAnswered
                    ? isCorrect
                    ? Colors.green.shade400
                    : Colors.red.shade400
                    : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.reorder_rounded,
                          color: Colors.grey.shade700, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        // ⚠️ Si la clé 'your_answer' n'existe pas encore dans
                        // ordre_translations.dart, ajoute-la (FR: "Ta réponse",
                        // EN: "Your answer").
                        t(context, 'your_answer'),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 👈 Wrap au lieu d'une Column dans un SingleChildScrollView
                  // séparé. Dépose ton mot SUR un mot déjà placé pour l'insérer
                  // juste avant lui — tout le reste se décale automatiquement
                  // (voir placeWord() dans OrdreSoloController).
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                      widget.controller.placedWords.length,
                          (index) => _DropTarget(
                          controller: widget.controller, index: index),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ==============================================================================
// DROP TARGET
// ==============================================================================
class _DropTarget extends StatefulWidget {
  final OrdreGameControllerBase controller;
  final int index;

  const _DropTarget({required this.controller, required this.index});

  @override
  State<_DropTarget> createState() => _DropTargetState();
}

class _DropTargetState extends State<_DropTarget>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  bool _isHighlighted = false;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<WordData>(
      builder: (context, candidateData, rejectedData) {
        final word = widget.controller.placedWords[widget.index];

        if (word != null && word.isNotEmpty) {
          return _DraggableWord(
            controller: widget.controller,
            word: word,
            fromIndex: widget.index,
          );
        }

        return AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _bounceAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                // 👈 RETIRÉ : width: double.infinity — dans un Wrap, chaque
                // slot doit avoir une taille compacte, pas s'étirer sur
                // toute la largeur disponible.
                constraints: const BoxConstraints(minWidth: 56),
                padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: _isHighlighted
                      ? Colors.blue.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isHighlighted
                        ? Colors.blue.shade400
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                  boxShadow: _isHighlighted
                      ? [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                      : null,
                ),
                child: Text(
                  '...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        );
      },
      onWillAcceptWithDetails: (details) {
        setState(() => _isHighlighted = true);
        _bounceController.forward();
        return true;
      },
      onLeave: (data) {
        setState(() => _isHighlighted = false);
        _bounceController.reverse();
      },
      onAcceptWithDetails: (details) {
        setState(() => _isHighlighted = false);
        _bounceController.reverse();
        HapticFeedback.lightImpact();
        widget.controller.placeWord(
          details.data.word,
          widget.index,
          sourceIndex: details.data.fromIndex,
        );
      },
    );
  }
}

// ==============================================================================
// DRAGGABLE WORD
// ==============================================================================
class _DraggableWord extends StatefulWidget {
  final OrdreGameControllerBase controller;
  final String word;
  final int? fromIndex;

  const _DraggableWord({
    required this.controller,
    required this.word,
    this.fromIndex,
  });

  @override
  State<_DraggableWord> createState() => _DraggableWordState();
}

class _DraggableWordState extends State<_DraggableWord>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, fontColor, borderColor) = _getWordColors();

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Draggable<WordData>(
            data: WordData(word: widget.word, fromIndex: widget.fromIndex),
            feedback: Material(
              color: Colors.transparent,
              elevation: 8.0,
              child: Transform.scale(
                scale: 1.1,
                child: _buildWordChip(
                    backgroundColor, fontColor, borderColor, true,
                    constrainWidth: false),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: _buildWordChip(Colors.grey.shade300,
                  Colors.grey.shade500, Colors.grey.shade400, false,
                  constrainWidth: false),
            ),
            onDragStarted: () {
              _scaleController.forward();
              HapticFeedback.mediumImpact();
            },
            onDragEnd: (details) {
              _scaleController.reverse();
            },
            // 👈 constrainWidth: false — dans un Wrap, chaque mot doit
            // s'afficher à sa taille naturelle, pas en pleine largeur.
            child: _buildWordChip(
                backgroundColor, fontColor, borderColor, false,
                constrainWidth: false),
          ),
        );
      },
    );
  }

  Widget _buildWordChip(Color backgroundColor, Color fontColor,
      Color borderColor, bool isFeedback,
      {bool constrainWidth = true}) {
    return Container(
      width: constrainWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isFeedback
              ? [backgroundColor, backgroundColor.withValues(alpha: 0.8)]
              : [backgroundColor, backgroundColor],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: isFeedback
            ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ]
            : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        widget.word,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: fontColor,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
  }

  (Color, Color, Color) _getWordColors() {
    if (!widget.controller.isAnswered ||
        widget.fromIndex == null ||
        widget.fromIndex! >= widget.controller.wordStates.length) {
      return (
      Colors.blue.shade50,
      Colors.blue.shade800,
      Colors.blue.shade200
      );
    }

    final wordState = widget.controller.wordStates[widget.fromIndex!];
    return switch (wordState) {
      true => (Colors.green.shade400, Colors.white, Colors.green.shade600),
      false => (Colors.red.shade400, Colors.white, Colors.red.shade600),
      _ => (Colors.blue.shade50, Colors.blue.shade800, Colors.blue.shade200),
    };
  }
}

// ==============================================================================
// ACTION BUTTON
// ==============================================================================
class _ActionButton extends StatefulWidget {
  final OrdreGameControllerBase controller;
  final VoidCallback onSubmit;

  const _ActionButton({
    required this.controller,
    required this.onSubmit,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String t(String key) {
    final lang = context.read<LanguageProvider>().language;
    return OrdreTranslations.t(key, lang);
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (_canSubmit()) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_ActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final canSubmitNow = _canSubmit();
    final couldSubmitBefore =
        !oldWidget.controller.placedWords.contains(null) &&
            !oldWidget.controller.placedWords.contains('');

    if (canSubmitNow && !couldSubmitBefore) {
      _pulseController.repeat(reverse: true);
    } else if (!_canSubmit()) {
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0.9), Colors.white],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _canSubmit() ? _pulseAnimation.value : 1.0,
            child: SizedBox(
              width: double.infinity,
              child: _buildButton(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildButton() {
    return switch (widget.controller) {
      OrdreMultiplayerController multi => _buildMultiplayerButton(multi),
      OrdreSoloController solo => _buildSoloButton(solo),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildMultiplayerButton(OrdreMultiplayerController controller) {
    if (controller.isAnswered) {
      return ElevatedButton.icon(
        onPressed: null,
        icon: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.grey.shade400,
          ),
        ),
        label: Text(t('waiting_other_players')),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade200,
          foregroundColor: Colors.grey.shade600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      );
    }

    return ElevatedButton(
      onPressed: _canSubmit() ? widget.onSubmit : null,
      style: ElevatedButton.styleFrom(
        backgroundColor:
        _canSubmit() ? Colors.blue.shade500 : Colors.grey.shade300,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: _canSubmit() ? 4 : 0,
        shadowColor: Colors.blue.withValues(alpha: 0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _canSubmit() ? Icons.check_circle_outline : Icons.lock_outline,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            t('verify'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSoloButton(OrdreSoloController controller) {
    final isCorrect = controller.isAnswered &&
        controller.placedWords.whereType<String>().join(' ') ==
            controller.correctOrder.join(' ');

    if (controller.isAnswered) {
      final (buttonText, icon, color) = isCorrect
          ? (t('continue'), Icons.arrow_forward_rounded, Colors.green.shade500)
          : (t('retry'), Icons.refresh_rounded, Colors.orange.shade500);

      return ElevatedButton(
        onPressed: controller.loadNextQuestion,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: color.withValues(alpha: 0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              buttonText,
              style:
              const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: _canSubmit() ? widget.onSubmit : null,
      style: ElevatedButton.styleFrom(
        backgroundColor:
        _canSubmit() ? Colors.blue.shade500 : Colors.grey.shade300,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: _canSubmit() ? 4 : 0,
        shadowColor: Colors.blue.withValues(alpha: 0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _canSubmit() ? Icons.check_circle_outline : Icons.lock_outline,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            t('verify'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  bool _canSubmit() {
    return !widget.controller.placedWords.contains(null) &&
        !widget.controller.placedWords.contains('');
  }
}

// ==============================================================================
// CORRECT ANSWER ANIMATION
// ==============================================================================
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
  State<CorrectAnswerAnimation> createState() =>
      _CorrectAnswerAnimationState();
}

class _CorrectAnswerAnimationState extends State<CorrectAnswerAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _confettiController;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  late Animation<double> _confettiAnimation;

  String t(String key) {
    final lang = context.read<LanguageProvider>().language;
    return OrdreTranslations.t(key, lang);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _scale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _confettiAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _confettiController, curve: Curves.easeOut),
    );

    if (widget.isVisible) {
      _controller.forward();
      if (widget.amITheWinner) {
        _confettiController.forward();
      }
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          widget.onComplete?.call();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final (title, subtitle, backgroundColor) = widget.amITheWinner
        ? (
    t('correct_order_found'),
    t('well_done'),
    Colors.green.shade400
    )
        : (
    t('round_finished'),
    widget.winnerName,
    Colors.blue.shade400
    );

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: Listenable.merge([_controller, _confettiController]),
        builder: (context, child) {
          return FadeTransition(
            opacity: _opacity,
            child: Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Stack(
                children: [
                  if (widget.amITheWinner) ..._buildConfetti(),
                  Center(
                    child: ScaleTransition(
                      scale: _scale,
                      child: Container(
                        margin: const EdgeInsets.all(32),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              backgroundColor.withValues(alpha: 0.1)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: backgroundColor.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.amITheWinner
                                    ? Icons.emoji_events
                                    : Icons.info_outline,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildConfetti() {
    return List.generate(20, (index) {
      final random = (index * 17) % 360;
      final color = [
        Colors.red.shade300,
        Colors.blue.shade300,
        Colors.green.shade300,
        Colors.yellow.shade300,
        Colors.purple.shade300,
      ][index % 5];

      return Positioned(
        left: (index % 5) * (MediaQuery.of(context).size.width / 5),
        top: -50 +
            (_confettiAnimation.value *
                MediaQuery.of(context).size.height *
                1.2),
        child: Transform.rotate(
          angle: random * _confettiAnimation.value,
          child: Container(
            width: 8 + (index % 3) * 4,
            height: 8 + (index % 3) * 4,
            decoration: BoxDecoration(
              color: color,
              shape: index % 2 == 0 ? BoxShape.circle : BoxShape.rectangle,
            ),
          ),
        ),
      );
    });
  }
}