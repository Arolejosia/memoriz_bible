import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'recitation_translations.dart';
import '../../../models/language_provider.dart';

// ==============================================================================
// WIDGET DE FEEDBACK SCORE - AFFICHAGE MODERNE DU SCORE APRÈS CHAQUE TENTATIVE
// ==============================================================================
class ScoreFeedbackWidget extends StatelessWidget {
  final double score;
  final String encouragementMessage;
  final bool isLastAttempt;
  final VoidCallback? onContinue;

  const ScoreFeedbackWidget({
    super.key,
    required this.score,
    required this.encouragementMessage,
    this.isLastAttempt = false,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>().language;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getGradientColors(),
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _getScoreColor().withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animation du score circulaire
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 1500),
            tween: Tween<double>(begin: 0, end: score / 100),
            builder: (context, double value, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${(score).toInt()}%",
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        RecitationTranslations.getScoreLabel(score, lang),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Message d'encouragement
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              encouragementMessage,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          if (isLastAttempt && score < 70) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    RecitationTranslations.t('last_attempt', lang),
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Bouton de continuation
          if (onContinue != null)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _getScoreColor(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onContinue!();
                },
                child: Text(
                  score >= 70
                      ? RecitationTranslations.t('continue', lang)
                      : RecitationTranslations.t('retry', lang),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Color> _getGradientColors() {
    if (score >= 90.0) return [Colors.green.shade400, Colors.green.shade600];
    if (score >= 70.0) return [Colors.lightGreen.shade400, Colors.lightGreen.shade600];
    if (score >= 50.0) return [Colors.orange.shade400, Colors.orange.shade600];
    if (score >= 30.0) return [Colors.deepOrange.shade400, Colors.deepOrange.shade600];
    return [Colors.red.shade400, Colors.red.shade600];
  }

  Color _getScoreColor() {
    if (score >= 90.0) return Colors.green;
    if (score >= 70.0) return Colors.lightGreen;
    if (score >= 50.0) return Colors.orange;
    if (score >= 30.0) return Colors.deepOrange;
    return Colors.red;
  }
}

// ==============================================================================
// WIDGET D'ANIMATION DES POINTS - POUR LES SUCCÈS
// ==============================================================================
class PointsAnimationWidget extends StatefulWidget {
  final int points;
  final VoidCallback? onComplete;

  const PointsAnimationWidget({
    super.key,
    required this.points,
    this.onComplete,
  });

  @override
  State<PointsAnimationWidget> createState() => _PointsAnimationWidgetState();
}

class _PointsAnimationWidgetState extends State<PointsAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -2),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>().language;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.translate(
            offset: _slideAnimation.value * 50,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber.shade400, Colors.orange.shade500],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 3,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "+${widget.points} ${RecitationTranslations.t('points', lang)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ==============================================================================
// WIDGET DE PROGRESSION DES TENTATIVES - BARRE DE PROGRESSION MODERNE
// ==============================================================================
class AttemptsProgressWidget extends StatelessWidget {
  final int attemptsRemaining;
  final int maxAttempts;
  final String hintMessage;

  const AttemptsProgressWidget({
    super.key,
    required this.attemptsRemaining,
    required this.maxAttempts,
    required this.hintMessage,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>().language;
    final attemptsUsed = maxAttempts - attemptsRemaining;
    final progressValue = attemptsUsed / maxAttempts;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                RecitationTranslations.t('attempts_label', lang),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                "$attemptsRemaining/$maxAttempts",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getProgressColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Barre de progression animée
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 800),
            tween: Tween<double>(begin: 0, end: progressValue),
            builder: (context, double value, child) {
              return Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Indicateurs visuels des tentatives
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(maxAttempts, (index) {
              final isUsed = index < attemptsUsed;
              final isCurrent = index == attemptsUsed && attemptsRemaining > 0;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isUsed
                      ? _getProgressColor()
                      : isCurrent
                      ? _getProgressColor().withOpacity(0.3)
                      : Colors.grey.shade300,
                  shape: BoxShape.circle,
                  border: isCurrent
                      ? Border.all(color: _getProgressColor(), width: 2)
                      : null,
                ),
                child: Center(
                  child: Icon(
                    isUsed
                        ? Icons.close_rounded
                        : isCurrent
                        ? Icons.mic_rounded
                        : Icons.favorite_rounded,
                    color: isUsed || isCurrent ? Colors.white : Colors.grey.shade600,
                    size: 20,
                  ),
                ),
              );
            }),
          ),

          if (hintMessage.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hintMessage,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
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

  Color _getProgressColor() {
    if (attemptsRemaining <= 1) return Colors.red.shade400;
    if (attemptsRemaining == 2) return Colors.orange.shade400;
    return Colors.green.shade400;
  }
}

// ==============================================================================
// WIDGET DE COMPARAISON TEXTE - MONTRE LES DIFFÉRENCES ENTRE ATTENDU ET RÉCITÉ
// ==============================================================================
class TextComparisonWidget extends StatelessWidget {
  final String expectedText;
  final String spokenText;
  final double similarity;

  const TextComparisonWidget({
    super.key,
    required this.expectedText,
    required this.spokenText,
    required this.similarity,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>().language;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.compare_arrows_rounded,
                color: Colors.blue.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                RecitationTranslations.t('comparison', lang),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getSimilarityColor(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${(similarity).toInt()}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Texte attendu
          _buildTextSection(
            RecitationTranslations.t('expected_text', lang),
            expectedText,
            Colors.green.shade50,
            Colors.green.shade700,
            lang,
          ),

          const SizedBox(height: 12),

          // Texte récité
          _buildTextSection(
            RecitationTranslations.t('your_recitation', lang),
            spokenText,
            Colors.blue.shade50,
            Colors.blue.shade700,
            lang,
          ),
        ],
      ),
    );
  }

  Widget _buildTextSection(String title, String text, Color backgroundColor, Color textColor, String lang) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text.isEmpty
                ? RecitationTranslations.t('no_text_detected', lang)
                : text,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              height: 1.4,
              fontStyle: text.isEmpty ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSimilarityColor() {
    if (similarity >= 90.0) return Colors.green.shade400;
    if (similarity >= 70.0) return Colors.lightGreen.shade400;
    if (similarity >= 50.0) return Colors.orange.shade400;
    if (similarity >= 30.0) return Colors.deepOrange.shade400;
    return Colors.red.shade400;
  }
}

// ==============================================================================
// WIDGET DE GAME OVER MODERNE - POUR LES ÉCHECS FINAUX
// ==============================================================================
class GameOverWidget extends StatelessWidget {
  final List<String> attempts;
  final String correctText;
  final VoidCallback onRetry;
  final VoidCallback onGoBack;

  const GameOverWidget({
    super.key,
    required this.attempts,
    required this.correctText,
    required this.onRetry,
    required this.onGoBack,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>().language;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey.shade100, Colors.grey.shade200],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icône et titre
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.refresh_rounded,
              color: Colors.orange.shade600,
              size: 48,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            RecitationTranslations.t('no_problem', lang),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            RecitationTranslations.t('try_again_question', lang),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 24),

          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade400, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onGoBack();
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(
                    RecitationTranslations.t('back', lang),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onRetry();
                  },
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(
                    RecitationTranslations.t('retry', lang),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
// EXEMPLES D'UTILISATION
// ==============================================================================
/*
// Dans votre page de récitation:

// 1. Score Feedback
ScoreFeedbackWidget(
  score: 85.5,
  encouragementMessage: RecitationTranslations.getEncouragementMessage(85.5, lang),
  isLastAttempt: false,
  onContinue: () {
    // Action de continuation
  },
)

// 2. Points Animation
PointsAnimationWidget(
  points: 50,
  onComplete: () {
    // Animation terminée
  },
)

// 3. Attempts Progress
AttemptsProgressWidget(
  attemptsRemaining: 2,
  maxAttempts: 3,
  hintMessage: RecitationTranslations.getHintMessage(45.0, true, lang),
)

// 4. Text Comparison
TextComparisonWidget(
  expectedText: "Le texte biblique attendu",
  spokenText: "Le texte que l'utilisateur a récité",
  similarity: 75.5,
)

// 5. Game Over
GameOverWidget(
  attempts: ["tentative 1", "tentative 2", "tentative 3"],
  correctText: "Le texte correct",
  onRetry: () {
    // Réessayer
  },
  onGoBack: () {
    // Retour
  },
)
*/