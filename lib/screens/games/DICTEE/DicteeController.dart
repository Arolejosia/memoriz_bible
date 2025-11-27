import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/verse_model.dart';
import '../../../services/Bible_service.dart';
import '../../../services/audio_service.dart';
import '../../../services/tts_service.dart';

class DicteeController extends ChangeNotifier {
  final Verse verse;
  final bool isSandbox;
  final Function(bool didWin)? onGameConcluded;

  String language;
  final TtsService _ttsService = TtsService();
  final TextEditingController _textController = TextEditingController();

  String _correctText = "";
  bool _isLoading = true;
  bool _isVerifying = false;
  bool _isGameOver = false;
  bool _timerActive = false;
  bool _isSpeaking = false;

  Timer? _timer;
  int _timeRemaining = 0;

  final int _maxAttempts = 3;
  int _attemptsRemaining = 3;

  DicteeController({
    required this.verse,
    required this.isSandbox,
    this.onGameConcluded,
    required this.language,
  }) {
    _initialize();
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get isVerifying => _isVerifying;
  bool get isGameOver => _isGameOver;
  bool get timerActive => _timerActive;
  bool get isSpeaking => _isSpeaking;
  String get correctText => _correctText;
  String get userText => _textController.text;
  TextEditingController get textController => _textController;
  int get attemptsRemaining => _attemptsRemaining;
  int get maxAttempts => _maxAttempts;
  int get timeRemaining => _timeRemaining;
  String? get currentReference => verse.reference;

  Future<void> _initialize() async {
    try {
      print('🔄 Initializing Dictee with language: $language');

      // Charger le texte du verset
      final verseDataList = await BibleService().getPassageText(
        verse.reference,
        language: language,
      );

      if (verseDataList.isNotEmpty) {
        _correctText = verseDataList.map((v) => v.text).join(" ");
        print('✅ Loaded verse text: ${_correctText.substring(0, _correctText.length > 50 ? 50 : _correctText.length)}...');
      } else {
        print('⚠️ No verse text loaded');
      }

      // ✅ CORRECTION : Initialiser TTS avec la langue
      await _ttsService.initialize(language);
      print('✅ TTS initialized with language: $language');

      // Configurer le callback TTS
      _ttsService.setCompletionHandler(() {
        if (!_isDisposed) {
          print('🔊 TTS completed, starting timer');
          _isSpeaking = false;
          notifyListeners();
          _startTimer();
        }
      });

    } catch (e) {
      print('❌ Error initializing dictee: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Met à jour la langue et recharge les données
  Future<void> updateLanguage(String newLang) async {
    if (language != newLang) {
      language = newLang;
      print('🔄 Language updated to: $newLang, reloading...');
      _isLoading = true;
      notifyListeners();
      await _initialize();
    }
  }

  Future<void> playVerse() async {
    // ✅ CORRECTION : Vérifications plus strictes
    if (_timerActive) {
      print('🚫 Cannot play audio - Timer is already active');
      return;
    }

    if (_isGameOver) {
      print('🚫 Cannot play audio - Game is over');
      return;
    }

    if (_isLoading) {
      print('🚫 Cannot play audio - Still loading');
      return;
    }

    if (_isSpeaking) {
      print('🚫 Cannot play audio - Already speaking');
      return;
    }

    if (_correctText.isEmpty) {
      print('❌ Cannot play audio - No text loaded');
      return;
    }

    try {
      print('🔊 Starting to play verse in language: $language');
      print('🔊 Text to speak: ${_correctText.substring(0, _correctText.length > 50 ? 50 : _correctText.length)}...');

      _isSpeaking = true;
      notifyListeners();

      // ✅ CORRECTION : Passer la langue explicitement au TTS
      await _ttsService.setLanguage(language);
      await _ttsService.speak(_correctText);

      print('✅ TTS speak command sent');

    } catch (e) {
      print('❌ Error playing verse: $e');
      _isSpeaking = false;
      notifyListeners();

      // ✅ FALLBACK : Si TTS échoue, démarrer quand même le timer
      _startTimer();
    }
  }

  void _startTimer() {
    if (_timerActive) {
      print('⚠️ Timer already active, skipping');
      return;
    }

    _timer?.cancel();

    // Calculer le temps basé sur le nombre de mots
    final wordCount = _correctText.split(' ').length;
    final initialTime = 15 + (wordCount * 1.5).round();

    _timeRemaining = initialTime;
    _timerActive = true;
    _isSpeaking = false; // ✅ S'assurer que speaking est false
    notifyListeners();

    print('⏱️ Timer started: $_timeRemaining seconds for $wordCount words');

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        _timeRemaining--;
        notifyListeners();
      } else {
        print('⏰ Timer expired - Auto-verifying');
        timer.cancel();
        _timerActive = false;
        notifyListeners();
        _verifyDictation();
      }
    });
  }

  Future<void> stopTimer() async {
    if (!_timerActive) {
      print('⚠️ Timer not active, cannot stop');
      return;
    }

    print('⏸️ Timer stopped by user');
    _timer?.cancel();
    _timerActive = false;
    notifyListeners();

    await _verifyDictation();
  }

  Future<void> _verifyDictation() async {
    if (_textController.text.isEmpty) {
      print('🚫 Cannot verify - Empty text');
      return;
    }

    if (_isVerifying) {
      print('🚫 Cannot verify - Already verifying');
      return;
    }

    _isVerifying = true;
    notifyListeners();

    print('🔍 Verifying answer in language: $language');
    print('   User: ${_textController.text}');
    print('   Correct: $_correctText');

    try {
      final score = await BibleService().getVerificationScore(
        _textController.text,
        _correctText,
        language: language,
      );

      final isCorrect = score >= 70;

      print('📊 Verification score: $score/100 - Correct: $isCorrect');

      if (isCorrect) {
        // Calcul du score basé sur les essais
        int finalScore = 0;
        if (_attemptsRemaining == 3) finalScore = 100;
        else if (_attemptsRemaining == 2) finalScore = 75;
        else if (_attemptsRemaining == 1) finalScore = 50;

        print('✅ Correct! Final score: $finalScore');

        if (!isSandbox) {
          AudioService.instance.playSound('sound/correct.mp3');
        }

        _handleGameEnd(true);
      } else {
        print('❌ Incorrect - Score: $score/100');
        AudioService.instance.playSound('sound/incorrect.mp3');
        _attemptsRemaining--;

        if (_attemptsRemaining <= 0) {
          print('🎮 Game Over - No attempts left');
          _isGameOver = true;
          _handleGameEnd(false);
        } else {
          print('🔄 Attempts remaining: $_attemptsRemaining');
          await _resetForNextTry();
        }
      }
    } catch (e) {
      print('❌ Error verifying dictation: $e');
    } finally {
      _isVerifying = false;
      notifyListeners();
    }
  }

  void _handleGameEnd(bool didWin) {
    print('🏁 Game ended - Win: $didWin, Sandbox: $isSandbox');
    if (onGameConcluded != null) {
      onGameConcluded!(didWin);
    }
  }

  Future<void> _resetForNextTry() async {
    _timer?.cancel();

    _textController.clear();
    _timerActive = false;
    _isVerifying = false;
    _isSpeaking = false;
    _timeRemaining = 0;
    notifyListeners();

    print('🔄 Reset for next attempt');
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void clearText() {
    _textController.clear();
    notifyListeners();
    print('🗑️ Text cleared');
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    _ttsService.stop();
    _textController.dispose();
    print('🗑️ DicteeController disposed');
    super.dispose();
  }
}