import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../models/language_provider.dart';
import '../../../models/verse_model.dart';
import '../../../services/feedback_overlay.dart';

import 'DicteeController.dart';
import 'dictee_translations.dart';

class PointAnimationData {
  final int id;
  final int points;
  const PointAnimationData(this.id, this.points);
}

class DicteeSoloPage extends StatefulWidget {
  final Verse verse;
  final bool isSandbox;
  final String language;

  const DicteeSoloPage({
    Key? key,
    required this.verse,
    this.isSandbox = false,
    required this.language,
  }) : super(key: key);

  @override
  State<DicteeSoloPage> createState() => _DicteeSoloPageState();
}

class _DicteeSoloPageState extends State<DicteeSoloPage>
    with TickerProviderStateMixin {
  final List<PointAnimationData> _pointAnimations = [];
  int _animationIdCounter = 0;

  late DicteeController _controller;
  bool _controllerInitialized = false;

  late AnimationController _pageController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pageController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pageController, curve: Curves.easeInOut),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pageController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_controllerInitialized) {
      _controller = DicteeController(
        verse: widget.verse,
        isSandbox: widget.isSandbox,
        onGameConcluded: _onGameConcluded,
        language: widget.language,
      );

      _controllerInitialized = true;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    _controller.dispose();
    super.dispose();
  }

  String t(String key, {Map<String, String>? params}) {
    final lang = context.watch<LanguageProvider>().language;
    return DicteeTranslations.t(key, lang, params: params);
  }

  // ✅ CORRECTION PRINCIPALE : Gestion différente Sandbox vs Progression
  void _onGameConcluded(bool didWin) {
    HapticFeedback.mediumImpact();

    if (didWin) {
      HapticFeedback.heavyImpact();
      int finalScore = 0;
      if (_controller.attemptsRemaining == 3) finalScore = 100;
      else if (_controller.attemptsRemaining == 2) finalScore = 75;
      else if (_controller.attemptsRemaining == 1) finalScore = 50;

      setState(() {
        _pointAnimations.add(PointAnimationData(_animationIdCounter++, finalScore));
      });
    } else {
      HapticFeedback.vibrate();
    }

    if (widget.isSandbox) {
      // Mode Sandbox : Afficher le dialogue complet avec options
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showResultDialog(didWin);
        }
      });
    } else {
      // ✅ Mode Progression : Feedback rapide puis retour automatique
      print('🚀 Mode Progression - Retour automatique avec résultat: $didWin');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showQuickProgressionFeedback(didWin);
        }
      });
    }
  }

  // ✅ AJOUT : Feedback rapide pour le mode Progression
  void _showQuickProgressionFeedback(bool didWin) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: didWin
                  ? [Colors.green.shade50, Colors.green.shade100]
                  : [Colors.orange.shade50, Colors.orange.shade100],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: didWin ? Colors.green.shade400 : Colors.orange.shade400,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  didWin ? Icons.check_circle_rounded : Icons.refresh_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                didWin ? t('excellent') : t('game_over'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: didWin ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                didWin ? t('moving_to_next_game') : t('step_not_completed'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ],
          ),
        ),
      ),
    );

    // Fermer automatiquement après 1.5 secondes
    Future.delayed(const Duration(milliseconds: 1500), () async {
      if (mounted) {
        Navigator.pop(context); // Ferme le dialogue

        // ✅ AJOUT CRUCIAL : Mettre à jour Firebase si victoire
        if (didWin) {
          try {
            final userId = FirebaseAuth.instance.currentUser?.uid;
            if (userId != null) {
              print('📈 [Dictée] Updating progressLevel in Firebase for ${widget.verse.id}');

              await FirebaseFirestore.instance
                  .collection('users/$userId/verses')
                  .doc(widget.verse.id)
                  .update({
                'progressLevel': FieldValue.increment(1),
                'updatedAt': FieldValue.serverTimestamp(),
              });

              print('✅ [Dictée] ProgressLevel incremented successfully');
            }
          } catch (e) {
            print('❌ [Dictée] Error updating progressLevel: $e');
          }
        }

        Navigator.pop(context, didWin); // 👈 RETOURNE LE RÉSULTAT À VerseDetailPage
      }
    });
  }

  // Dialogue complet pour le mode Sandbox
  void _showResultDialog(bool isCorrect) {
    final lang = context.read<LanguageProvider>().language;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 16,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isCorrect
                  ? [Colors.green.shade50, Colors.green.shade100]
                  : [Colors.orange.shade50, Colors.orange.shade100],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green.shade400 : Colors.orange.shade400,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isCorrect ? Colors.green : Colors.orange).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.refresh_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                isCorrect ? DicteeTranslations.t('excellent', lang) :
                (_controller.isGameOver ? DicteeTranslations.t('game_over', lang) : DicteeTranslations.t('almost', lang)),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isCorrect ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.verse.reference,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                isCorrect
                    ? DicteeTranslations.t('success_message', lang)
                    : (_controller.isGameOver
                    ? DicteeTranslations.t('no_attempts_left', lang)
                    : DicteeTranslations.formatAttemptsRemaining(
                    _controller.attemptsRemaining, lang)),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),

              if (!isCorrect) ...[
                const SizedBox(height: 20),
                Text(
                  DicteeTranslations.t('correct_answer_was', lang),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    _controller.correctText,
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCorrect || _controller.isGameOver
                        ? Colors.green.shade400
                        : Colors.orange.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(dialogContext).pop();
                    if (isCorrect || _controller.isGameOver) {
                      Navigator.of(context).pop();
                    } else {
                      _controller.clearText();
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isCorrect || _controller.isGameOver
                            ? Icons.arrow_forward_rounded
                            : Icons.refresh_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCorrect || _controller.isGameOver
                            ? DicteeTranslations.t('continue', lang)
                            : DicteeTranslations.t('retry', lang),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_controllerInitialized) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return ChangeNotifierProvider<DicteeController>.value(
      value: _controller,
      child: Consumer<DicteeController>(
        builder: (context, controller, child) {
          return AnimatedBuilder(
            animation: _fadeAnimation,
            builder: (context, child) => FadeTransition(
              opacity: _fadeAnimation,
              child: Scaffold(
                backgroundColor: Colors.grey.shade50,
                appBar: _buildAppBar(controller),
                body: controller.isLoading
                    ? _buildLoadingView()
                    : _buildGameContent(controller),
                floatingActionButton: Stack(
                  children: _pointAnimations.map((data) {
                    return PointsAnimationWidget(
                      key: ValueKey(data.id),
                      points: data.points,
                      onCompleted: () {
                        if (mounted) {
                          setState(() {
                            _pointAnimations.removeWhere((a) => a.id == data.id);
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(DicteeController controller) {
    final lang = context.watch<LanguageProvider>().language;
    final currentAttempt = (controller.maxAttempts - controller.attemptsRemaining) + 1;

    return AppBar(
      title: Text(
        '${t('dictee')} - ${t('attempt')} ${DicteeTranslations.formatAttempts(currentAttempt, controller.maxAttempts, lang)}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.grey.shade800,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
        },
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getAttemptColor(currentAttempt, controller.maxAttempts),
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
              const Icon(Icons.looks_one_rounded, size: 16, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                DicteeTranslations.formatAttempts(
                  currentAttempt,
                  controller.maxAttempts,
                  lang,
                ),
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

  Color _getAttemptColor(int current, int max) {
    final ratio = current / max;
    if (ratio <= 0.33) return Colors.green.shade400;
    if (ratio <= 0.66) return Colors.orange.shade400;
    return Colors.red.shade400;
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade600],
              ),
            ),
            child: const Icon(Icons.headphones_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 24),
          Text(
            t('preparing_dictation'),
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

  Widget _buildGameContent(DicteeController controller) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildReferenceCard(),
          const SizedBox(height: 20),
          _buildAudioSection(controller),
          const SizedBox(height: 20),
          if (controller.timerActive) _buildTimerDisplay(controller),
          const SizedBox(height: 20),
          _buildTextInputSection(controller),
          const SizedBox(height: 30),
          _buildActionButton(controller),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildReferenceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.menu_book_rounded, color: Colors.blue.shade700, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.verse.reference,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioSection(DicteeController controller) {
    final isDisabled = controller.timerActive || controller.isGameOver || controller.isSpeaking;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: !isDisabled && controller.timerActive == false ? _pulseAnimation.value : 1.0,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDisabled
                    ? [Colors.grey.shade200, Colors.grey.shade300]
                    : [Colors.green.shade400, Colors.green.shade500],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDisabled ? null : [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              onTap: isDisabled ? null : () {
                HapticFeedback.mediumImpact();
                controller.playVerse();
                _pulseController.repeat(reverse: true);
              },
              borderRadius: BorderRadius.circular(16),
              child: controller.isSpeaking
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    t('speaking'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.volume_up_rounded,
                    color: (controller.timerActive || controller.isGameOver)
                        ? Colors.grey.shade500
                        : Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    t('listen_verse'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: (controller.timerActive || controller.isGameOver)
                          ? Colors.grey.shade500
                          : Colors.white,
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

  Widget _buildTimerDisplay(DicteeController controller) {
    final lang = context.watch<LanguageProvider>().language;
    final time = controller.timeRemaining;
    final color = time <= 30 ? Colors.red : (time <= 60 ? Colors.orange : Colors.green);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade300, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_rounded, color: color.shade600, size: 20),
          const SizedBox(width: 8),
          Text(
            DicteeTranslations.formatTimeRemaining(time, lang),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextInputSection(DicteeController controller) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller.textController,
        maxLines: 8,
        readOnly:controller.isGameOver,
        style: const TextStyle(fontSize: 16, height: 1.5),
        decoration: InputDecoration(
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
          ),
          hintText: controller.timerActive ? t('write_here') : t('click_listen_to_start'),
          hintStyle: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
          contentPadding: const EdgeInsets.all(20),
        ),
        onChanged: (text) {
          if (text.isNotEmpty && !_pulseController.isAnimating) {
            _pulseController.stop();
          }
        },
      ),
    );
  }

  Widget _buildActionButton(DicteeController controller) {
    if (controller.isVerifying) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
            Text(t('verifying'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    final canSubmit = controller.timerActive && controller.textController.text.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canSubmit ? () {
          HapticFeedback.mediumImpact();
          controller.stopTimer();
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canSubmit ? Colors.blue.shade500 : Colors.grey.shade300,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: canSubmit ? 4 : 0,
          shadowColor: Colors.blue.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(canSubmit ? Icons.check_circle_outline : Icons.lock_outline, size: 20),
            const SizedBox(width: 8),
            Text(t('verify'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}