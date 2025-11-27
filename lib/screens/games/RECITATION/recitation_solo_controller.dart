import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'recitation_controller.dart';
import 'recitation_translations.dart';
import '../../../models/verse_model.dart';
import '../../../services/Bible_service.dart';
import '../../../services/audio_service.dart';

class RecitationSoloController extends RecitationController {
  final Verse verse;
  final bool isSandbox;
  final Function(bool didWin)? onGameConcluded;
  final String language; // Langue pour les traductions

  String _correctText = "";
  bool isGameOver = false;

  final int _essaisMax = 3;
  int _essaisRestants = 3;
  List<String> _previousAttempts = [];
  double _lastScore = 0.0;

  RecitationSoloController({
    required this.verse,
    required this.isSandbox,
    this.onGameConcluded,
    this.language = 'fr', // Langue par défaut
  }) {
    _initialize();
  }

  // Getters
  String get correctText => _correctText;
  int get essaisRestants => _essaisRestants;
  int get essaisMax => _essaisMax;
  List<String> get previousAttempts => _previousAttempts;
  double get lastScore => _lastScore;
  bool get isLastAttempt => _essaisRestants == 1;

  @override
  String? get currentReference => verse.reference;

  // Getter pour obtenir un feedback personnalisé basé sur le score (traduit)
  String get encouragementMessage {
    return RecitationTranslations.getEncouragementMessage(_lastScore, language);
  }

  Color get scoreColor {
    if (_lastScore >= 90.0) return Colors.green;
    if (_lastScore >= 70.0) return Colors.lightGreen;
    if (_lastScore >= 50.0) return Colors.orange;
    if (_lastScore >= 30.0) return Colors.deepOrange;
    return Colors.red;
  }

  Future<void> _initialize() async {
    try {
      final verseDataList = await BibleService().getPassageText(verse.reference);
      if (verseDataList.isNotEmpty) {
        _correctText = verseDataList.map((v) => v.text).join(" ");
      }
      isSpeechInitialized = await speech.initialize();
    } catch (e) {
      print('Error initializing recitation: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  Future<void> verifyRecitation() async {
    if (transcribedText.isEmpty || isVerifying || isGameOver) return;

    isVerifying = true;
    notifyListeners();

    try {
      // Ajouter un délai pour l'effet visuel
      await Future.delayed(const Duration(milliseconds: 1500));

      final score = await BibleService().getVerificationScore(transcribedText, _correctText);
      final isCorrect = score >= 70.0;

      _lastScore = score.toDouble();
      _previousAttempts.add(transcribedText);

      if (isCorrect) {
        // Succès avec feedback haptique et sonore
        HapticFeedback.heavyImpact();
        AudioService.instance.playSound('sound/correct.mp3');
        await _celebrateSuccess();
        _handleGameEnd(true);
      } else {
        // Échec avec feedback approprié
        _essaisRestants--;

        if (_essaisRestants <= 0) {
          // Échec final - retour au jeu précédent
          HapticFeedback.heavyImpact();
          AudioService.instance.playSound('sound/game_over.mp3');
          isGameOver = true;
          await _showFinalFailure();
          _handleGameEnd(false);
        } else {
          // Échec partiel - encouragement
          HapticFeedback.mediumImpact();
          AudioService.instance.playSound('sound/incorrect.mp3');
          await _showPartialFailure();
        }
      }
    } catch (e) {
      print('Error verifying recitation: $e');
      // En cas d'erreur, permettre de réessayer
      HapticFeedback.lightImpact();
    } finally {
      isVerifying = false;
      notifyListeners();
    }
  }

  Future<void> _celebrateSuccess() async {
    // Animation de célébration (peut être gérée par l'UI)
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> _showPartialFailure() async {
    // Feedback visuel pour échec partiel (géré par l'UI)
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _showFinalFailure() async {
    // Feedback visuel pour échec final (géré par l'UI)
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _handleGameEnd(bool didWin) {
    if (onGameConcluded != null) {
      // Délai pour permettre à l'UI de montrer le feedback
      Future.delayed(const Duration(milliseconds: 800), () {
        onGameConcluded!(didWin);
      });
    }
  }

  // Méthode pour réinitialiser le jeu (utile pour le mode sandbox)
  void resetGame() {
    _essaisRestants = _essaisMax;
    _previousAttempts.clear();
    _lastScore = 0.0;
    isGameOver = false;
    transcribedText = "";
    isListening = false;
    isVerifying = false;
    notifyListeners();
  }

  // Méthode pour obtenir un indice basé sur la performance précédente (traduit)
  String getHint() {
    return RecitationTranslations.getHintMessage(_lastScore, _previousAttempts.isNotEmpty, language);
  }

  // Calculer le pourcentage de progression
  double get progressPercentage {
    return ((_essaisMax - _essaisRestants) / _essaisMax) * 100;
  }

  // Obtenir la couleur de progression basée sur les essais restants
  Color get progressColor {
    if (_essaisRestants == _essaisMax) return Colors.green;
    if (_essaisRestants == 2) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    // Nettoyer les ressources
    _previousAttempts.clear();
    super.dispose();
  }
}