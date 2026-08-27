import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memoriz_bible/screens/games/RECITATION/recitation_controller.dart';
import 'package:provider/provider.dart';

import '../../../Bibliotheque.dart';
import '../../../models/game_context.dart';
import '../../../models/verse_model.dart';
import '../../../models/language_provider.dart';
import '../../duels/game_results_page.dart';
import 'RecitationMultiplayerController.dart';
import 'recitation_solo_controller.dart';
import 'recitation_translations.dart';

// ==============================================================================
// DONNÉES D'ANIMATION DES POINTS AMÉLIORÉES
// ==============================================================================
class PointAnimationData {
  final int id;
  final int points;
  final AnimationController controller;
  const PointAnimationData(this.id, this.points, this.controller);
}

// ==============================================================================
// PAGE PRINCIPALE RÉCITATION - UX PREMIUM MODERNISÉE
// ==============================================================================
class RecitationPage extends StatelessWidget {
  final GameContext gameContext;
  final Verse? verse;
  final String? roomCode;

  const RecitationPage({
    super.key,
    required this.gameContext,
    this.verse,
    this.roomCode,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RecitationController>(
      create: (context) => _createController(context),
      child: const RecitationGameView(),
    );
  }

  RecitationController _createController(BuildContext context) {
    return switch (gameContext) {
      GameContext.duel => RecitationMultiplayerController(
          roomCode: roomCode ?? (throw ArgumentError('roomCode required for duel'))),
      GameContext.progression ||
      GameContext.sandbox =>
          RecitationSoloController(
            verse: verse ?? (throw ArgumentError('verse required for solo games')),
            isSandbox: gameContext == GameContext.sandbox,
            onGameConcluded: (didWin) => _handleGameEnd(context, didWin),
          ),
    };
  }

  void _handleGameEnd(BuildContext context, bool didWin) {
    HapticFeedback.mediumImpact();

    if (gameContext == GameContext.sandbox) {
      if (didWin) {
        _showSuccessDialog(context);
      } else {
        _showFailureDialog(context);
      }
    } else {
      _handleProgressionEnd(context, didWin);
    }
  }

  void _showSuccessDialog(BuildContext context) {
    final lang = context.read<LanguageProvider>().language;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 20,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.green.shade50, Colors.green.shade100],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animation de succès
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 800),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green.shade400,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                RecitationTranslations.t('perfect', lang),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                RecitationTranslations.t('excellent_recitation', lang),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: Colors.green.withOpacity(0.3),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Text(
                    RecitationTranslations.t('finish', lang),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFailureDialog(BuildContext context) {
    final lang = context.read<LanguageProvider>().language;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 20,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.orange.shade50, Colors.orange.shade100],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animation d'échec
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 800),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade400,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                RecitationTranslations.t('no_problem', lang),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                RecitationTranslations.t('practice_makes_perfect', lang),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade400, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: Text(
                          RecitationTranslations.t('back', lang),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade400,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                          shadowColor: Colors.orange.withOpacity(0.3),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecitationPage(
                                gameContext: gameContext,
                                verse: verse,
                                roomCode: roomCode,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          RecitationTranslations.t('retry', lang),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleProgressionEnd(BuildContext context, bool didWin) async {
    print('🎮 [RecitationPage] _handleProgressionEnd called with didWin=$didWin');

    final score = didWin ? 100 : 0;

    // Attendre que onGameFinished termine
    await context.read<VerseLibrary>().onGameFinished(
      verse: verse!,
      gameMode: "recitation",
      score: score,
    );

    // ✅ AJOUT : Délai supplémentaire pour garantir que Firebase est à jour
    await Future.delayed(const Duration(milliseconds: 500));

    print('✅ [RecitationPage] Firebase updated, returning to VerseDetailPage');

    // Retourner seulement après que tout soit terminé
    if (context.mounted) {
      Navigator.of(context).pop(didWin);
    }
  }
}

// ==============================================================================
// VUE PRINCIPALE RÉCITATION MODERNISÉE
// ==============================================================================
class RecitationGameView extends StatefulWidget {
  const RecitationGameView({super.key});

  @override
  State<RecitationGameView> createState() => _RecitationGameViewState();
}

class _RecitationGameViewState extends State<RecitationGameView>
    with TickerProviderStateMixin {
  final List<PointAnimationData> _pointAnimations = [];
  int _animationIdCounter = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // 👈 AJOUT : contrôleur persistant pour le champ "entrer la référence".
  // Créé une seule fois (lazy, dans _buildReferenceVerificationStep) plutôt
  // qu'à chaque reconstruction du widget — avant, un nouveau
  // TextEditingController était recréé à CHAQUE frappe (via le Consumer qui
  // rebuild sur chaque notifyListeners()), ce qui faisait sauter le curseur
  // et perturbait le clavier.
  TextEditingController? _referenceInputController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shakeController.dispose();
    _referenceInputController?.dispose(); // 👈 AJOUT
    super.dispose();
  }

  void _triggerShakeAnimation() {
    _shakeController.forward().then((_) => _shakeController.reset());
  }

  // Helper pour obtenir les traductions
  String t(String key, {Map<String, String>? params}) {
    final lang = context.read<LanguageProvider>().language;
    return RecitationTranslations.t(key, lang, params: params);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RecitationController>(
      builder: (context, controller, child) {
        // Animation de secousse en cas d'échec
        if (controller is RecitationSoloController &&
            controller.essaisRestants < controller.essaisMax) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _triggerShakeAnimation();
          });
        }

        // Navigation automatique pour multijoueur
        if (controller is RecitationMultiplayerController) {
          _handleAutoNavigation(controller);
        }

        return AnimatedBuilder(
          animation: Listenable.merge([_fadeAnimation, _shakeAnimation]),
          builder: (context, child) => FadeTransition(
            opacity: _fadeAnimation,
            child: Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: Scaffold(
                backgroundColor: Colors.grey.shade50,
                appBar: _buildAppBar(controller),
                body: controller.isLoading
                    ? _buildLoadingView()
                    : _buildGameContent(controller),
                floatingActionButton: Stack(
                  children: [
                    if (controller is RecitationSoloController)
                      ..._buildPointAnimations(),
                  ],
                ),
                floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildPointAnimations() {
    return _pointAnimations.map((data) {
      return AnimatedBuilder(
        animation: data.controller,
        builder: (context, child) {
          return Positioned(
            top: MediaQuery.of(context).size.height * 0.3 - (data.controller.value * 100),
            left: MediaQuery.of(context).size.width * 0.5 - 50,
            child: Opacity(
              opacity: 1 - data.controller.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade400,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  "+${data.points} ${t('points')}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          );
        },
      );
    }).toList();
  }

  void _handleAutoNavigation(RecitationMultiplayerController controller) {
    if (controller.isGameFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  GameResultsPage(
                    players: controller.players,
                    questions: controller.questions,
                  ),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOut,
                  )),
                  child: child,
                );
              },
            ),
          );
        }
      });
    }
  }

  PreferredSizeWidget _buildAppBar(RecitationController controller) {
    String title = t('recitation');

    if (controller is RecitationMultiplayerController) {
      title = t('multiplayer_game', params: {'code': controller.roomCode});
    }

    return AppBar(
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.grey.shade800,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back_ios_rounded, size: 20),
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
        },
      ),
      actions: [
        if (controller is RecitationSoloController) ...[
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getAttemptsColor(controller.essaisRestants),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  "${controller.essaisRestants}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (controller is RecitationMultiplayerController)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getTimerBackgroundColor(controller.timeLeft),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  "${controller.timeLeft}${t('seconds')}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Color _getAttemptsColor(int attempts) {
    if (attempts <= 1) return Colors.red.shade400;
    if (attempts == 2) return Colors.orange.shade400;
    return Colors.green.shade400;
  }

  Color _getTimerBackgroundColor(int timeLeft) {
    if (timeLeft <= 10) return Colors.red.shade400;
    if (timeLeft <= 30) return Colors.orange.shade400;
    return Colors.green.shade400;
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder(
            duration: const Duration(seconds: 2),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            t('preparing_recitation'),
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameContent(RecitationController controller) {

    if (controller is RecitationSoloController &&
        controller.showReferenceVerification) {
      return _buildReferenceVerificationStep(controller);
    }
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildReferenceSection(controller),
          const SizedBox(height: 20),
          _buildStatusSection(controller),
          const SizedBox(height: 20),
          _buildTranscriptionArea(controller),
          const SizedBox(height: 30),
          _buildMicrophoneSection(controller),
          const SizedBox(height: 30),
          if (controller is RecitationMultiplayerController)
            _buildMultiplayerInfo(controller),
          if (controller is RecitationSoloController)
            _buildSoloProgressInfo(controller),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildReferenceVerificationStep(RecitationSoloController controller) {
    // 👈 CORRIGÉ : avant, un nouveau TextEditingController était créé ICI à
    // chaque appel de cette méthode — et cette méthode est rappelée à
    // chaque frappe via le Consumer<RecitationController> qui rebuild sur
    // notifyListeners(). Résultat : le champ de texte était détruit et
    // recréé à chaque lettre tapée, faisant sauter le curseur et perturbant
    // le clavier.
    //
    // Maintenant : le contrôleur est créé UNE SEULE FOIS (stocké dans l'état
    // du widget, voir _referenceInputController plus haut) et simplement
    // réutilisé sur tous les rebuilds suivants.
    _referenceInputController ??= TextEditingController(text: controller.referenceInput);
    final textController = _referenceInputController!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // En-tête "Excellente récitation"
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.purple.shade50, Colors.purple.shade100],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 60,
                  color: Colors.purple.shade600,
                ),
                const SizedBox(height: 16),
                Text(
                  t('excellent_recitation'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  t('one_last_step'),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Indicateur de tentatives (coeurs)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              controller.maxReferenceAttempts,
                  (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  index < controller.referenceAttempts
                      ? Icons.favorite_border
                      : Icons.favorite,
                  color: Colors.red,
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${controller.maxReferenceAttempts - controller.referenceAttempts} ${t('tries_left')}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 32),

          // Instruction
          Text(
            t('enter_verse_reference'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Champ de saisie
          TextField(
            controller: textController,
            enabled: !controller.showReferenceResult,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: t('placeholder_reference'),
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.purple.shade200, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.purple.shade200, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.purple, width: 3),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
              ),
            ),
            onChanged: (value) => controller.updateReferenceInput(value),
            onSubmitted: (_) {
              if (!controller.showReferenceResult &&
                  textController.text.trim().isNotEmpty) {
                controller.validateReference();
              }
            },
          ),

          const SizedBox(height: 24),

          // Résultat de la validation
          if (controller.showReferenceResult)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: controller.referenceIsCorrect
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: controller.referenceIsCorrect
                      ? Colors.green
                      : Colors.red,
                  width: 3,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    controller.referenceIsCorrect
                        ? Icons.check_circle
                        : Icons.cancel,
                    size: 64,
                    color: controller.referenceIsCorrect
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    controller.referenceIsCorrect
                        ? t('correct')
                        : t('incorrect'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: controller.referenceIsCorrect
                          ? Colors.green.shade900
                          : Colors.red.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    controller.referenceIsCorrect
                        ? t('reference_correct_message')
                        : controller.referenceAttempts >= controller.maxReferenceAttempts
                        ? t('correct_reference_is')
                        : t('reference_incorrect_try_again'),
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  if (!controller.referenceIsCorrect &&
                      controller.referenceAttempts >= controller.maxReferenceAttempts) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple, width: 2),
                      ),
                      child: Text(
                        controller.verse.reference,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

          const SizedBox(height: 32),

          // Boutons d'action
          if (!controller.showReferenceResult) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: textController.text.trim().isNotEmpty
                    ? () => controller.validateReference()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  t('validate'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => controller.skipReferenceVerification(),
              child: Text(
                t('skip'),
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildReferenceSection(RecitationController controller) {
    final lang = context.read<LanguageProvider>().language;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.menu_book_rounded,
              color: Colors.blue.shade700,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.currentReference ?? '',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                if (controller is RecitationMultiplayerController)
                  Text(
                    t('question_progress', params: {
                      'current': '${controller.localCurrentQuestionIndex + 1}',
                      'total': '${controller.questions.length}'
                    }),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (controller is RecitationSoloController)
                  Text(
                    controller.isSandbox
                        ? RecitationTranslations.t('training_mode', lang)
                        : RecitationTranslations.t('progression_mode', lang),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(RecitationController controller) {
    final lang = context.read<LanguageProvider>().language;

    if (controller is RecitationMultiplayerController) {
      // Afficher si quelqu'un a trouvé la bonne réponse
      if (controller.questionAlreadyAnswered) {
        final winner = controller.correctAnswerWinnerName ?? t('unknown_player');
        final isMe = controller.correctAnswerWinnerId == controller.currentUserId;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isMe ? Colors.green.shade100 : Colors.blue.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isMe ? Colors.green.shade300 : Colors.blue.shade300,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isMe ? Colors.green : Colors.blue).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isMe ? Icons.emoji_events_rounded : Icons.person_rounded,
                  color: isMe ? Colors.green.shade600 : Colors.blue.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  isMe
                      ? RecitationTranslations.t('you_found_answer', lang)
                      : RecitationTranslations.t('player_found_answer', lang,
                      params: {'player': winner}),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // Afficher feedback si le joueur a soumis une mauvaise réponse
      if (controller.hasSubmitted && !controller.questionAlreadyAnswered) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade300, width: 2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.red.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  RecitationTranslations.t('wrong_answer', lang),
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
    }

    if (controller is RecitationSoloController && controller.essaisRestants < controller.essaisMax) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade300, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_rounded,
                color: Colors.orange.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                RecitationTranslations.formatAttemptsRemaining(controller.essaisRestants, lang),
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

    return const SizedBox.shrink();
  }

  Widget _buildTranscriptionArea(RecitationController controller) {
    String displayText = controller.transcribedText.isEmpty
        ? t('press_to_start')
        : controller.transcribedText;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 220),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          displayText,
          style: TextStyle(
            fontSize: 18,
            height: 1.6,
            color: controller.transcribedText.isEmpty
                ? Colors.grey.shade500
                : Colors.grey.shade800,
            fontStyle: controller.transcribedText.isEmpty
                ? FontStyle.italic
                : FontStyle.normal,
            fontWeight: controller.transcribedText.isEmpty
                ? FontWeight.w500
                : FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildMicrophoneSection(RecitationController controller) {
    bool isListening = controller.isListening;
    bool isVerifying = controller.isVerifying;
    bool isDisabled = false;
    VoidCallback? onTap;

    if (controller is RecitationMultiplayerController) {
      isDisabled = controller.hasSubmitted ||
          controller.questionAlreadyAnswered ||
          !controller.isSpeechInitialized;
      onTap = isDisabled
          ? null
          : () {
        HapticFeedback.mediumImpact();
        controller.toggleListening();
      };
    } else {
      isDisabled = (controller is RecitationSoloController && controller.isGameOver);
      onTap = isDisabled
          ? null
          : () {
        HapticFeedback.mediumImpact();
        controller.toggleListening();
      };
    }

    return Column(
      children: [
        if (isVerifying)
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.purple.shade300, Colors.purple.shade500],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 4,
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    Icons.psychology_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),
          )
        else
          AvatarGlow(
            animate: isListening,
            glowColor: isDisabled
                ? Colors.grey
                : (isListening ? Colors.red.shade400 : Colors.blue.shade500),
            duration: const Duration(milliseconds: 2000),
            repeat: true,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDisabled
                        ? [Colors.grey.shade300, Colors.grey.shade400]
                        : isListening
                        ? [Colors.red.shade400, Colors.red.shade600]
                        : [Colors.blue.shade400, Colors.blue.shade600],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDisabled
                          ? Colors.grey
                          : isListening
                          ? Colors.red
                          : Colors.blue)
                          .withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 4,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  isListening ? Icons.stop_rounded : Icons.mic_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
        Text(
          isVerifying
              ? t('analyzing')
              : isDisabled
              ? t('waiting_status')
              : isListening
              ? t('press_to_stop')
              : t('press_to_speak'),
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        if (isVerifying) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Text(
              t('ai_analyzing'),
              style: TextStyle(
                color: Colors.purple.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSoloProgressInfo(RecitationSoloController controller) {
    final lang = context.read<LanguageProvider>().language;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.indigo.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: Colors.indigo.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.isSandbox
                          ? RecitationTranslations.t('training_mode', lang)
                          : RecitationTranslations.t('progression_mode', lang),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                    Text(
                      t('do_your_best'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildProgressItem(
                  t('attempts_remaining'),
                  t('attempts_count', params: {
                    'remaining': '${controller.essaisRestants}',
                    'max': '${controller.essaisMax}'
                  }),
                  Icons.favorite_rounded,
                  _getAttemptsColor(controller.essaisRestants),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressItem(
                  t('accuracy_required'),
                  t('accuracy_70'),
                  Icons.gps_fixed_rounded,
                  Colors.green.shade400,
                ),
              ),
            ],
          ),
          if (controller.essaisRestants < controller.essaisMax) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    color: Colors.orange.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t('speak_clearly'),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMultiplayerInfo(RecitationMultiplayerController controller) {
    final lang = context.read<LanguageProvider>().language;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.purple.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreItem(
                  t('score'), '${controller.currentScore}', Icons.stars_rounded),
              _buildScoreItem(
                t('status'),
                controller.hasSubmitted
                    ? RecitationTranslations.t('submitted', lang)
                    : RecitationTranslations.t('in_progress', lang),
                controller.hasSubmitted
                    ? Icons.check_circle_rounded
                    : Icons.mic_rounded,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              t('live_ranking'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...controller.playerRanking.take(5).map((entry) {
            final playerData = controller.players[entry.key];
            final name = playerData['name'] ?? t('unknown_player');
            final isMe = entry.key == controller.currentUserId;
            final rank = controller.playerRanking.indexOf(entry) + 1;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? Colors.purple.shade100 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: isMe ? Border.all(color: Colors.purple.shade300, width: 2) : null,
                boxShadow: isMe ? [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ] : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getRankColor(rank),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isMe ? '$name ${t("you")}' : name,
                      style: TextStyle(
                        fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                        fontSize: 16,
                        color: isMe ? Colors.purple.shade700 : Colors.grey.shade800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.purple.shade200 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${entry.value} ${t("points")}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isMe ? Colors.purple.shade700 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade400;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.orange.shade600;
      default:
        return Colors.blue.shade400;
    }
  }

  Widget _buildScoreItem(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.shade100,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.purple.shade600,
            size: 28,
          ),
        ),
        const SizedBox(height: 12),
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
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],

    );
  }
}