import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // 🆕 PROPRIÉTÉS POUR LA VÉRIFICATION DE RÉFÉRENCE
  bool _showReferenceVerification = false;
  bool get showReferenceVerification => _showReferenceVerification;

  int _referenceAttempts = 0;
  final int _maxReferenceAttempts = 3;
  int get referenceAttempts => _referenceAttempts;
  int get maxReferenceAttempts => _maxReferenceAttempts;

  String _referenceInput = '';
  String get referenceInput => _referenceInput;

  bool _referenceIsCorrect = false;
  bool get referenceIsCorrect => _referenceIsCorrect;

  bool _showReferenceResult = false;
  bool get showReferenceResult => _showReferenceResult;

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

        // 🆕 Au lieu d'appeler directement _handleGameEnd,
        // on affiche l'étape de vérification de référence
        print('✅ [RecitationSolo] Récitation correcte ! Affichage vérification référence');
        _showReferenceVerification = true;
        isVerifying = false;
        notifyListeners();
      } else {
        // Échec avec feedback approprié
        _essaisRestants--;

        if (_essaisRestants <= 0) {
          // Échec final - retour au jeu précédent
          HapticFeedback.heavyImpact();
          AudioService.instance.playSound('sound/game_over.mp3');
          isGameOver = true;
          await _showFinalFailure();
          await _handleGameEnd(false);
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
      if (!_showReferenceVerification) {
        isVerifying = false;
        notifyListeners();
      }
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

  // 🆕 FONCTION POUR METTRE À JOUR L'INPUT DE RÉFÉRENCE
  void updateReferenceInput(String value) {
    _referenceInput = value;
    notifyListeners();
  }

  // 🆕 FONCTION DE NORMALISATION DE RÉFÉRENCE
  String _normalizeReference(String ref) {
    String normalized = ref.toLowerCase().trim();

    // Enlever les accents
    const accents = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÀÁÂÃÄÅÇÈÉÊËÌÍÎÏÑÒÓÔÕÖÙÚÛÜÝ';
    const sansAccents = 'aaaaaaceeeeiiiinooooouuuuyAAAAAACEEEEIIIINOOOOOUUUUY';
    for (int i = 0; i < accents.length; i++) {
      normalized = normalized.replaceAll(accents[i], sansAccents[i]);
    }

    // Variations courantes de noms de livres
    final bookVariations = {
      // Français
      'psaumes': 'psaume',
      'psms': 'psaume',
      'ps': 'psaume',
      'esaie': 'esaie',
      'esai': 'esaie',
      'isaie': 'esaie',
      'isai': 'esaie',
      'cantique': 'cantique',
      'cantiques': 'cantique',
      'cant': 'cantique',
      '1chroniques': '1chronique',
      '2chroniques': '2chronique',
      '1corinthiens': '1corinthien',
      '2corinthiens': '2corinthien',
      '1thessaloniciens': '1thessalonicien',
      '2thessaloniciens': '2thessalonicien',
      '1timothee': '1timothee',
      '2timothee': '2timothee',
      '1pierre': '1pierre',
      '2pierre': '2pierre',
      '1jean': '1jean',
      '2jean': '2jean',
      '3jean': '3jean',
      // Anglais
      'psalms': 'psalm',
      'pss': 'psalm',
      'isaiah': 'isaiah',
      'isa': 'isaiah',
      '1chronicles': '1chronicle',
      '2chronicles': '2chronicle',
      '1corinthians': '1corinthian',
      '2corinthians': '2corinthian',
      '1thessalonians': '1thessalonian',
      '2thessalonians': '2thessalonian',
      '1timothy': '1timothy',
      '2timothy': '2timothy',
      '1peter': '1peter',
      '2peter': '2peter',
      '1john': '1john',
      '2john': '2john',
      '3john': '3john',
    };

    // Appliquer les variations
    bookVariations.forEach((variant, canonical) {
      // Remplacer au début de la chaîne (pour ne pas affecter les chiffres)
      if (normalized.startsWith(variant)) {
        normalized = normalized.replaceFirst(variant, canonical);
      }
    });

    // Enlever TOUS les espaces, tirets, points, virgules, deux-points
    normalized = normalized.replaceAll(RegExp(r'[\s\-\.\,:;]+'), '');

    // Ne garder que lettres et chiffres
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9]'), '');

    return normalized;
  }

  // 🆕 FONCTION POUR VALIDER LA RÉFÉRENCE
  Future<void> validateReference() async {
    if (_referenceInput.trim().isEmpty) return;

    _referenceAttempts++;

    final userNormalized = _normalizeReference(_referenceInput);
    final correctNormalized = _normalizeReference(verse.reference);

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔍 [RecitationSolo] Vérification référence:');
    print('   Input: "$_referenceInput"');
    print('   Normalized: "$userNormalized"');
    print('   Correct: "${verse.reference}"');
    print('   Correct normalized: "$correctNormalized"');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    _referenceIsCorrect = userNormalized == correctNormalized;
    _showReferenceResult = true;
    notifyListeners();

    if (_referenceIsCorrect) {
      // ✅ Référence correcte
      print('✅ [RecitationSolo] Référence correcte !');
      HapticFeedback.heavyImpact();
      AudioService.instance.playSound('sound/correct.mp3');
      await Future.delayed(const Duration(seconds: 2));
      await _handleGameEnd(true); // Score 100
    } else if (_referenceAttempts >= _maxReferenceAttempts) {
      // ❌ 3 échecs sur la référence
      print('❌ [RecitationSolo] 3 échecs sur la référence');
      HapticFeedback.heavyImpact();
      AudioService.instance.playSound('sound/game_over.mp3');
      await Future.delayed(const Duration(seconds: 3));
      await _handleGameEnd(false); // Score 0 - doit refaire récitation
    } else {
      // ⚠️ Mauvaise réponse, essais restants
      print('⚠️ [RecitationSolo] Mauvaise référence, essais restants: ${_maxReferenceAttempts - _referenceAttempts}');
      HapticFeedback.mediumImpact();
      AudioService.instance.playSound('sound/incorrect.mp3');
      await Future.delayed(const Duration(seconds: 2));
      _showReferenceResult = false;
      _referenceInput = '';
      notifyListeners();
    }
  }

  // 🆕 FONCTION POUR PASSER LA VÉRIFICATION DE RÉFÉRENCE
  void skipReferenceVerification() {
    print('⏭️ [RecitationSolo] Référence sautée');
    _handleGameEnd(false); // Score 0
  }

  Future<void> _handleGameEnd(bool didWin) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎮 [RecitationSolo] _handleGameEnd');
    print('   didWin: $didWin');
    print('   isSandbox: $isSandbox');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Délai pour permettre à l'UI de montrer le feedback
    if (onGameConcluded != null) {
      await Future.delayed(const Duration(milliseconds: 800));
      onGameConcluded!(didWin);
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

    // 🆕 Réinitialiser aussi la vérification de référence
    _showReferenceVerification = false;
    _referenceAttempts = 0;
    _referenceInput = '';
    _referenceIsCorrect = false;
    _showReferenceResult = false;

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